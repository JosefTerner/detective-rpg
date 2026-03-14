# Detective RPG — Documentation Index

This directory contains the full documentation suite for the Detective RPG project, following the C4 model and a structured module lifecycle (spec → module doc).

---

## Structure

```
docs/
├── ARCHITECTURE.md              ← C4 levels 1–3: system context, containers, components
├── JAVADOC_CONVENTIONS.md       ← Code comment rules for Java/Spring Boot services
├── game-rules.md                ← Game mechanics and rules (player-facing)
├── example-game-session.md      ← Full walkthrough with API call examples
├── adr/
│   ├── ADR-001-microservices-architecture.md
│   ├── ADR-002-polyglot-persistence.md
│   └── ADR-003-api-gateway-jwt.md
├── specs/                       ← Pre-implementation design specs (one per service)
│   ├── api-gateway.md
│   ├── case-service.md
│   ├── player-service.md
│   ├── time-points-service.md
│   ├── map-service.md
│   ├── police-db-service.md
│   ├── service-registry.md
│   └── detective-rpg-ui.md
├── modules/                     ← Post-implementation docs (populated as services ship)
└── api-specs/                   ← OpenAPI specifications (TBD)
```

`specs/` and `modules/` are sister folders. A spec graduates to a module doc once the service is fully implemented.

---

## Key docs

| Document | Purpose |
|----------|---------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | C4 diagrams, data stores, security model, integration map |
| [JAVADOC_CONVENTIONS.md](JAVADOC_CONVENTIONS.md) | How to write doc comments in Java services |
| [game-rules.md](game-rules.md) | Game mechanics — roles, scoring, time rules |
| [example-game-session.md](example-game-session.md) | End-to-end example with real API calls |

---

## Service specs

| Service | Port | Spec |
|---------|------|------|
| API Gateway | 8080 | [specs/api-gateway.md](specs/api-gateway.md) |
| Service Registry | 8761 | [specs/service-registry.md](specs/service-registry.md) |
| Case Service | 8081 | [specs/case-service.md](specs/case-service.md) |
| Player Service | 8082 | [specs/player-service.md](specs/player-service.md) |
| Time & Points | 8083 | [specs/time-points-service.md](specs/time-points-service.md) |
| Map Service | 8084 | [specs/map-service.md](specs/map-service.md) |
| Police DB | 8085 | [specs/police-db-service.md](specs/police-db-service.md) |
| Detective RPG UI | 3000 | [specs/detective-rpg-ui.md](specs/detective-rpg-ui.md) |

---

## ADR log

| ADR | Decision |
|-----|----------|
| [ADR-001](adr/ADR-001-microservices-architecture.md) | Microservices over monolith |
| [ADR-002](adr/ADR-002-polyglot-persistence.md) | Polyglot persistence (PG + MongoDB + ES + Redis) |
| [ADR-003](adr/ADR-003-api-gateway-jwt.md) | API Gateway as single entry point with JWT auth |

---

## Design principles

- **Domain isolation:** Each service owns its data; no cross-service DB access
- **Loose coupling:** Services communicate via well-defined REST contracts
- **Right tool per pattern:** PostGIS for geospatial, MongoDB for documents, Elasticsearch for search
- **Security at the edge:** JWT validated once at the Gateway; downstream services are stateless

---

## Contribution guidelines

- Update `ARCHITECTURE.md` when adding, removing, or significantly changing a service
- When implementing a service from a spec: graduate the spec to `docs/modules/{name}.md`
- For significant architectural decisions: create a new ADR before implementing
- Keep ADR status fields current (`Proposed` → `Accepted` → `Deprecated`)
- Update API specs in `api-specs/` when endpoint contracts change
