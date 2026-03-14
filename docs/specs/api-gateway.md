# Spec: API Gateway

| Field | Value |
|-------|-------|
| **Status** | Approved |
| **Author** | *← fill in* |
| **Created** | 2026-03-14 |
| **Last updated** | 2026-03-14 |
| **Target milestone** | TBD |
| **Related ADRs** | [ADR-001](../adr/ADR-001-microservices-architecture.md), [ADR-003](../adr/ADR-003-api-gateway-jwt.md) |

---

## 1. Problem statement

All seven backend services need to be accessible to the React UI through a single URL. Without a Gateway, the client would need to know the address and port of every service, and each service would need to implement its own auth and rate-limiting logic. This creates duplication and makes the system harder to secure and evolve.

---

## 2. Responsibilities

### In scope — this service owns:
- Routing inbound HTTP requests to the correct backend service based on URL prefix
- Validating JWT tokens on all protected routes
- Enforcing rate limits per player using Redis
- Propagating the authenticated user context to downstream services via headers
- Providing health, metrics, and route inspection via Spring Boot Actuator

### Out of scope — this service does NOT own:
- Player authentication / token issuance — *no auth service yet; JWT_SECRET is shared*
- Business logic of any kind — it routes and enforces, never transforms payloads
- Service-to-service calls — internal traffic does not flow through the Gateway

---

## 3. Non-goals

- This service will not generate JWT tokens — that belongs to an auth service (future work)
- This service will not transform request/response bodies
- This service will not perform load balancing beyond what Spring Cloud LoadBalancer provides via Eureka

---

## 4. Domain concepts

| Term | Definition |
|------|-----------|
| `Route` | A mapping from a URL prefix to a downstream service name (resolved via Eureka) |
| `JWT` | Signed bearer token issued at login; carries player ID and role claims |
| `Rate limit` | Maximum number of requests per player per time window; enforced via Redis counters |
| `User context header` | HTTP header added by the Gateway after JWT validation; carries player ID and role so downstream services don't re-parse the token |

---

## 5. Proposed design

### High-level approach

Spring Cloud Gateway routes requests based on URL prefix predicates. JWT validation is implemented as a `GatewayFilter`. On successful validation the filter adds `X-Player-Id` and `X-Player-Role` headers before forwarding. Rate limiting uses Spring Cloud Gateway's built-in `RequestRateLimiter` filter backed by Redis. Service names are resolved via Eureka using `lb://service-name` URIs.

### Module structure (proposed)

```
com.detectiverpg.gateway/
├── filter/
│   ├── JwtAuthenticationFilter.java    ← validates JWT, adds user context headers
│   └── RequestLoggingFilter.java       ← logs method, path, player ID, latency
├── config/
│   ├── RouteConfig.java                ← defines route predicates and filters
│   ├── SecurityConfig.java             ← Spring Security — permit public routes
│   └── RedisRateLimiterConfig.java     ← rate limiter key resolver and limits
└── exception/
    └── GatewayExceptionHandler.java    ← maps auth failures to 401/403 JSON responses
```

### Key logic

JWT validation flow:
1. Extract `Authorization: Bearer <token>` header
2. Verify signature using `JWT_SECRET`
3. Check expiry (`exp` claim)
4. Extract `playerId` and `role` claims
5. Add `X-Player-Id` and `X-Player-Role` headers to the forwarded request
6. On any failure: return `401 Unauthorized` with JSON error body

---

## 6. Proposed API contracts

### Route table

| URL prefix | Routes to | Auth required |
|------------|-----------|---------------|
| `/cases/**` | `case-service` | Yes |
| `/players/**` | `player-service` | Yes |
| `/time/**` | `time-points-service` | Yes |
| `/locations/**` | `map-service` | Yes |
| `/police/**` | `police-db-service` | Yes |
| `/actuator/**` | Gateway itself | No (local/ops only) |

### User context headers (added by Gateway, consumed by downstream services)

| Header | Value |
|--------|-------|
| `X-Player-Id` | Player's UUID from JWT `sub` claim |
| `X-Player-Role` | Player's role from JWT `role` claim |

---

## 7. Data model (proposed)

The Gateway itself has no persistent data model. Redis is used for rate-limiting counters only (TTL-based, no schema).

---

## 8. Dependencies

### External services

| Service | Used for | Notes |
|---------|---------|-------|
| Redis | Rate-limiting counters, optional token blacklist | Must be running before Gateway starts |
| Service Registry (Eureka) | Resolving downstream service addresses | Gateway registers itself and resolves `lb://` URIs |

---

## 9. Open questions

| # | Question | Owner | Status |
|---|----------|-------|--------|
| 1 | Where are JWT tokens issued? No auth service exists yet. | TBD | Open |
| 2 | Should rate limits differ by player role (e.g. detective vs witness)? | TBD | Open |
| 3 | Should the Gateway blacklist invalidated tokens on logout, or use short-lived JWTs only? | TBD | Open |

---

## 10. Risks and concerns

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Gateway becomes availability bottleneck | Low (for v1 player counts) | High | Design stateless — can run multiple instances behind a load balancer when needed |
| JWT_SECRET leaked | Low | High | Inject via env var, never commit; rotate procedure TBD |

---

## 11. Acceptance criteria

- [ ] A request with a valid JWT to `/cases/**` is forwarded to Case Service with `X-Player-Id` and `X-Player-Role` headers set
- [ ] A request with an expired or invalid JWT returns HTTP 401 with a JSON error body
- [ ] After exceeding the configured rate limit, further requests return HTTP 429
- [ ] A request to an unmapped path returns HTTP 404
- [ ] `/actuator/health` responds without a JWT token

---

## 12. Out of scope for v1

- Token issuance (login endpoint) — requires a dedicated auth service
- mTLS for internal service-to-service traffic
- Circuit breaker / fallback responses per route
