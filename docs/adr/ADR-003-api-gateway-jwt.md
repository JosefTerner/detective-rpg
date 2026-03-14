# ADR-003: API Gateway as single entry point with JWT authentication

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-03-14 |
| **Deciders** | *← fill in: project team* |
| **Related ADRs** | [ADR-001](ADR-001-microservices-architecture.md) |

---

## Context

With seven services, there are two options for handling authentication: each service validates tokens independently, or a single Gateway validates once and forwards a trusted user context. Duplicating security logic across services risks divergence and makes it harder to change auth strategy later.

The game also needs rate limiting (to prevent players from spamming interrogation endpoints) which fits naturally at the edge, not per service.

---

## Decision

We will use Spring Cloud Gateway as the single entry point for all client traffic. The Gateway validates JWT tokens, enforces rate limits via Redis, and routes to the appropriate service. Downstream services receive a pre-validated user context via request headers and do not re-validate tokens.

---

## Alternatives considered

| Option | Pros | Cons | Why rejected |
|--------|------|------|-------------|
| API Gateway with JWT (chosen) | Single security enforcement point; rate limiting at edge; services stay stateless | Gateway is a potential bottleneck and single point of failure | — (chosen) |
| Each service validates JWT | No single point of failure for auth | Duplicated security logic; harder to rotate signing keys; rate limiting per service is complex | Rejected: 7x duplication of security logic with no benefit |
| Session cookies via shared session store | Familiar pattern; easy logout | Requires shared Redis session store accessible by all services; stateful | Rejected: stateless JWT better fits independent service scaling |

---

## Consequences

**Positive:**
- Auth logic is implemented and maintained in one place
- Downstream services are simpler — they trust the header rather than parsing JWTs
- Rate limiting and monitoring are centralised at the Gateway
- Changing from JWT to another token scheme requires updating only the Gateway

**Negative / trade-offs:**
- The API Gateway becomes a critical dependency — if it goes down, all client access stops
- Downstream services must trust the user context header, meaning internal traffic bypassing the Gateway could be spoofed (acceptable for v1 assuming internal network is trusted)

**Neutral / follow-up actions:**
- Document the user-context header contract so downstream services consume it consistently
- Add Gateway health checks and consider a fallback/HA deployment path before production
- Token blacklisting on logout: store invalidated JTIs in Redis with TTL = token expiry
