# ADR-001: Microservices architecture over monolith

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-03-14 |
| **Deciders** | *← fill in: project team* |
| **Related ADRs** | [ADR-003](ADR-003-api-gateway-jwt.md) |

---

## Context

Detective RPG has five distinct game domains: case management, player identity, in-game time and scoring, map and travel, and police records. Each domain has different data storage requirements, scaling characteristics, and rate of change. A monolith would couple these concerns together, making it harder to develop, test, and scale them independently.

The game supports 4–20 simultaneous players, and real-time operations (live player location, in-game clock) have different latency requirements than batch operations (scoring history, case archive).

---

## Decision

We will build the backend as seven independently deployable Spring Boot microservices, each owning its own database. Services communicate via synchronous HTTP/REST resolved through Eureka service discovery.

---

## Alternatives considered

| Option | Pros | Cons | Why rejected |
|--------|------|------|-------------|
| Microservices (chosen) | Independent scaling and deployment; domain isolation; teams can work in parallel | Operational complexity; distributed tracing needed; synchronous calls create coupling | — (chosen) |
| Monolith | Simple deployment; easy local development; no network calls between domains | All domains scale together; DB schema conflicts; harder to isolate failures | Rejected: domains have incompatible DB needs (PostGIS, MongoDB, Elasticsearch) |
| Modular monolith | Simpler than microservices; still enforces boundaries | Shared DB still present; deployment is all-or-nothing | Rejected: Police DB's polyglot requirements can't be solved without a separate process |

---

## Consequences

**Positive:**
- Each service can be scaled, deployed, and tested independently
- Failures in one service (e.g. Police DB Elasticsearch down) don't prevent other game actions
- Teams can work on different services in parallel

**Negative / trade-offs:**
- Local development requires Docker Compose to spin up all dependencies
- Inter-service calls add latency and failure surface (synchronous HTTP)
- Distributed tracing and correlation IDs are needed to debug cross-service flows

**Neutral / follow-up actions:**
- Add correlation ID propagation via HTTP request headers before the first integration tests
- Add Testcontainers for per-service integration tests to avoid dependency on running sibling services
