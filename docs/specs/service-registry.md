# Spec: Service Registry

| Field | Value |
|-------|-------|
| **Status** | Approved |
| **Author** | *← fill in* |
| **Created** | 2026-03-14 |
| **Last updated** | 2026-03-14 |
| **Target milestone** | TBD |
| **Related ADRs** | [ADR-001](../adr/ADR-001-microservices-architecture.md) |

---

## 1. Problem statement

With seven services running on different ports, the API Gateway and inter-service HTTP clients need a way to resolve service addresses without hardcoding host/port values. A service registry allows services to register themselves at startup and discover each other by logical name, enabling horizontal scaling and dynamic deployment.

---

## 2. Responsibilities

### In scope — this service owns:
- Accepting self-registration from all other services at startup
- Responding to service discovery queries (resolve logical name → instance list)
- Monitoring service health via heartbeat and evicting failed instances
- Providing a dashboard UI showing all registered services and their health

### Out of scope — this service does NOT own:
- Any game logic
- Routing decisions — the API Gateway uses discovery results to route, but routing logic lives in the Gateway
- Load balancing algorithm — client-side load balancing via Spring Cloud LoadBalancer in each service

---

## 3. Non-goals

- This service will not store any game data
- This service will not authenticate service registrations (internal network trust for v1)

---

## 4. Domain concepts

| Term | Definition |
|------|-----------|
| `Service instance` | A single running process that has registered with Eureka, identified by app name + host + port |
| `Heartbeat` | A periodic HTTP request from a registered instance to Eureka confirming it is still alive (default: every 30s) |
| `Eviction` | Removal of a service instance that has missed enough heartbeats (default: 90s timeout) |
| `Self-preservation mode` | Eureka's behaviour under network partition: it stops evicting instances to avoid mass de-registration on false positives |

---

## 5. Proposed design

### High-level approach

Standard Spring Cloud Netflix Eureka Server with no customisation beyond configuration. All core services and the API Gateway are Eureka clients — they register on startup and renew heartbeats automatically. No persistent storage is needed: the registry is rebuilt from client registrations on restart.

### Module structure (proposed)

```
com.detectiverpg.serviceregistry/
└── ServiceRegistryApplication.java   ← @SpringBootApplication + @EnableEurekaServer
resources/
└── application.yml                   ← register-with-eureka: false, fetch-registry: false
```

This is intentionally minimal — Eureka Server needs no business logic.

---

## 6. Proposed API contracts

The registry exposes standard Eureka REST APIs (used internally by Spring Cloud clients). These are not called directly by the game frontend or game services beyond the auto-wired Spring Cloud abstractions.

| Endpoint | Purpose |
|----------|---------|
| `GET /eureka/apps` | List all registered applications |
| `GET /eureka/apps/{appName}` | Get instances for a specific service |
| `PUT /eureka/apps/{appName}/{instanceId}` | Heartbeat renewal |
| Dashboard: `http://localhost:8761` | Visual health overview |

---

## 7. Data model (proposed)

No persistent data model. All registry state is in-memory and rebuilt from client registrations.

---

## 8. Dependencies

No upstream service dependencies.

---

## 9. Open questions

| # | Question | Owner | Status |
|---|----------|-------|--------|
| 1 | Should self-preservation mode be disabled in local dev to avoid stale registrations? | TBD | Open |
| 2 | Does the production deployment need Eureka peer replication (two registry instances)? | TBD | Open |

---

## 10. Risks and concerns

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Service Registry is single point of failure for all inter-service discovery | Low (for v1) | High | Run other services with static fallback URLs for critical paths; add peer replication before production |
| Services start before Registry is ready in Docker Compose | Med | Med | Use `depends_on` + health check in Compose; Spring Cloud Eureka clients retry registration automatically |

---

## 11. Acceptance criteria

- [ ] All six client services appear as `UP` in the Eureka dashboard after `docker-compose up`
- [ ] API Gateway resolves `lb://case-service` to a running Case Service instance
- [ ] A service that stops sending heartbeats is evicted within 90 seconds
- [ ] Eureka dashboard is reachable at `http://localhost:8761` without authentication

---

## 12. Out of scope for v1

- Eureka peer replication for HA
- Securing the Eureka registration endpoint
- Replacing Eureka with a cloud-native registry (Kubernetes service discovery, Consul) — future migration path
