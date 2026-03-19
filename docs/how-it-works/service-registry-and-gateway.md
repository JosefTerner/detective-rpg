# How It Works: Service Registry & API Gateway

## 1. Service Discovery with Eureka

### The problem it solves

In a microservices setup each service runs in its own container, possibly on its own host, and its IP address can change at any time (restart, reschedule, scale-out). Hard-coding hostnames like `case-service:8081` is fragile — you need a way for services to *find each other dynamically*.

### How Eureka works

Eureka is a **service registry**: a shared address book that every service writes its address into and reads from.

```
┌─────────────────────────────────────────────────────────────────┐
│                    Eureka Server :8761                          │
│                                                                 │
│  Registry:                                                      │
│    case-service      → 172.20.0.5:8081  (healthy)               │
│    player-service    → 172.20.0.6:8082  (healthy)               │
│    map-service       → 172.20.0.7:8084  (healthy)               │
│    ...                                                          │
└─────────────────────────────────────────────────────────────────┘
        ▲ register / heartbeat             ▲ register / heartbeat
        │                                  │
┌───────┴──────┐                  ┌────────┴─────┐
│ case-service │                  │ player-svc   │
│   :8081      │                  │   :8082      │
└──────────────┘                  └──────────────┘
```

**Key concepts:**

| Concept | What it means |
|---------|---------------|
| **Registration** | On startup each service (`@EnableEurekaClient` / auto-configured) POSTs its hostname, IP, port, and health-check URL to the server |
| **Heartbeat** | Every 10 s (configurable) the client sends a `PUT /eureka/apps/<name>/<id>/` renewal. If the server receives no renewal for 30 s, the instance is marked *DOWN* |
| **Eviction** | Every 5 s the server evicts instances that have missed their renewal deadline |
| **Self-preservation** | In production, Eureka refuses to evict many instances at once (guards against network partitions). Disabled here for faster dev feedback |
| **Fetch** | Clients download and cache the full registry locally, so they can still resolve names if the server is briefly unreachable |

### Our configuration choices

```yaml
eureka:
  client:
    register-with-eureka: false   # server does not register itself as a client
    fetch-registry: false         # server does not cache its own registry
  server:
    eviction-interval-timer-in-ms: 5000   # evict dead instances every 5 s (fast in dev)
    enable-self-preservation: false       # don't suppress evictions during mass failures
```

---

## 2. API Gateway

### The problem it solves

Without a gateway the browser (or mobile app) would need to:
- Know the address of every service
- Manage its own JWT validation logic
- Handle CORS headers per service
- Deal with partial failures (one service down ≠ whole app down)

The **API Gateway is the single front door**: all traffic enters on `:8080`, and the gateway fans it out to the correct downstream service.

```
Browser / App
     │
     ▼  :8080
┌─────────────────────────────────────────────────────┐
│                   API Gateway                        │
│                                                      │
│  1. Validate JWT                                     │
│  2. Inject X-User-Id / X-User-Role headers           │
│  3. Apply rate limiting (Redis)                      │
│  4. Route to downstream service (via Eureka lb://)   │
│  5. Circuit-break if service is unavailable          │
└──────────┬────────────┬────────────┬─────────────────┘
           │            │            │
           ▼            ▼            ▼
      case-service  player-svc  map-service  …
```

### Routing

Routes are defined in `application.yml` using Spring Cloud Gateway predicates:

```yaml
routes:
  - id: case-service
    uri: lb://case-service    # lb:// tells the gateway to use Eureka for lookup
    predicates:
      - Path=/cases/**        # all /cases/* requests go here
```

`lb://case-service` triggers the **Eureka-backed load balancer**: the gateway asks Eureka "what IP:port instances does `case-service` have?" and round-robins across them.

---

## 3. JWT Authentication at the Gateway

### What is a JWT?

A **JSON Web Token** is a compact, signed string that proves who the user is without a database lookup:

```
eyJhbGciOiJIUzI1NiJ9          ← header  (algorithm)
.eyJzdWIiOiJ1c2VyLTQyIiw...   ← payload (claims: sub, role, exp, …)
.SflKxwRJSMeKKF2QT4fwpMeJ…    ← signature (HMAC-SHA256 of header+payload)
```

The gateway holds the **same secret key** used to sign tokens. Verifying the signature takes microseconds and needs no network call.

### JwtAuthenticationFilter (GlobalFilter, order -1)

```
Incoming request
       │
       ▼
  Is path public?  ──yes──▶  pass through
       │ no
       ▼
  Authorization: Bearer <token>  present?
       │ no ──▶ 401 {"error":"Missing or malformed Authorization header"}
       │ yes
       ▼
  Parse & verify JWT signature + expiry
       │ invalid ──▶ 401 {"error":"Invalid or expired token"}
       │ valid
       ▼
  Mutate request:
    add X-User-Id:   <sub claim>
    add X-User-Role: <role claim>
       │
       ▼
  Continue to routing filters → downstream service
```

Downstream services (case-service, player-service, …) **trust these headers** — they never re-validate the JWT. The gateway is the single choke point.

### Public paths

```java
private static final List<String> PUBLIC_PATHS = List.of(
    "/players/register",
    "/players/login",
    "/actuator"
);
```

---

## 4. Rate Limiting

Redis-backed `RequestRateLimiter` (token-bucket algorithm):

| Parameter | Value | Meaning |
|-----------|-------|---------|
| `replenishRate` | 20 | Refill 20 tokens/second into the bucket |
| `burstCapacity` | 40 | Bucket can hold up to 40 tokens (absorbs short spikes) |
| Key | `X-User-Id` | Each user gets their own bucket |

The `userKeyResolver` bean extracts `X-User-Id` from the request headers. For unauthenticated requests (public paths) it falls back to remote IP.

---

## 5. Circuit Breaker

Wraps each route with Resilience4j. If a downstream service starts failing:

1. First 10 requests are sampled (sliding window)
2. If ≥ 50% fail → circuit **opens** (fast-fail for 10 s)
3. After 10 s → circuit moves to **half-open** (5 probe requests)
4. If probes succeed → circuit **closes** again

While open, all requests are immediately redirected to `GET /fallback` → `503 Service temporarily unavailable`.

---

## 6. Full Request Sequence Diagram

A typical authenticated request from the browser to `GET /cases/42`:

```
Browser          API Gateway           Eureka           case-service
   │                   │                  │                   │
   │ GET /cases/42     │                  │                   │
   │ Authorization:    │                  │                   │
   │  Bearer <jwt>     │                  │                   │
   │──────────────────▶│                  │                   │
   │                   │                  │                   │
   │                   │ validate JWT     │                   │
   │                   │ extract userId,  │                   │
   │                   │ role             │                   │
   │                   │                  │                   │
   │                   │ lookup lb://case-service             │
   │                   │─────────────────▶│                   │
   │                   │ [172.20.0.5:8081]│                   │
   │                   │◀─────────────────│                   │
   │                   │                  │                   │
   │                   │ GET /cases/42    │                   │
   │                   │ X-User-Id: 42    │                   │
   │                   │ X-User-Role: DETECTIVE               │
   │                   │──────────────────────────────────────▶
   │                   │                  │                   │
   │                   │                  │   200 OK + body   │
   │                   │◀──────────────────────────────────────
   │                   │                  │                   │
   │     200 OK + body │                  │                   │
   │◀──────────────────│                  │                   │
```

---

## 7. Verification Checklist

```bash
# 1. Start just the registry
cd backend && docker-compose up service-registry

# 2. Open http://localhost:8761 — Eureka dashboard should appear

# 3. Start the gateway (registry must be healthy first)
docker-compose up api-gateway

# 4. Check gateway health
curl http://localhost:8080/actuator/health
# → {"status":"UP"}

# 5. Inspect registered routes
curl http://localhost:8080/actuator/gateway/routes

# 6. Compile both services
mvn clean install -pl service-registry
mvn clean install -pl api-gateway
```
