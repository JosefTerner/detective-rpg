# Architecture — Detective RPG

> **Status:** Living document — update when significant structural changes occur.
> **Last reviewed:** 2026-03-14
> **Owner:** *← fill in: team or lead dev name*

---

## Table of contents

- [1. Purpose and scope](#1-purpose-and-scope)
- [2. C4 Level 1 — System context](#2-c4-level-1--system-context)
- [3. C4 Level 2 — Container diagram](#3-c4-level-2--container-diagram)
- [4. C4 Level 3 — Component overview](#4-c4-level-3--component-overview)
- [5. Data architecture](#5-data-architecture)
- [6. Security architecture](#6-security-architecture)
- [7. Integration map](#7-integration-map)
- [8. Deployment architecture](#8-deployment-architecture)
- [9. Key architectural decisions](#9-key-architectural-decisions)
- [10. Non-functional requirements](#10-non-functional-requirements)
- [11. Known constraints and trade-offs](#11-known-constraints-and-trade-offs)

---

## 1. Purpose and scope

**In scope:**
- Structural design of the Detective RPG backend and frontend
- How the seven microservices interact
- Rationale behind key architectural choices
- Data stores owned by each service

**Out of scope (see linked docs):**
- Step-by-step API usage → service specs in `docs/specs/`
- Service business logic → `docs/modules/` (once implemented)
- Deployment procedures → `docs/RUNBOOK.md`

---

## 2. C4 Level 1 — System context

*Who and what interacts with this system from the outside.*

```
                    ┌─────────────────────────────────────────┐
                    │           Detective RPG System           │
                    │  (microservices + React SPA)             │
                    └─────────────────────────────────────────┘
                         ▲               ▲              ▲
                         │               │              │
               ┌─────────┴──┐   ┌────────┴──┐   ┌──────┴──────┐
               │  Detective  │   │Supporting  │   │  Opposing   │
               │  Player     │   │Players     │   │  Players    │
               │(1 per game) │   │(police,    │   │(killer,     │
               └────────────┘   │ coroner,   │   │ accomplices)│
                                │ witnesses) │   └─────────────┘
                                └───────────┘
```

**External actors:**

| Actor | How they interact |
|-------|------------------|
| Detective Player | Uses the React UI to investigate: gather evidence, interrogate suspects, submit verdict |
| Supporting Players | Use the React UI to respond to interrogations and provide truthful testimony |
| Opposing Players | Use the React UI to respond to interrogations; may provide misleading information |

---

## 3. C4 Level 2 — Container diagram

*Deployable units and how they communicate.*

```
[Browser]
    │ HTTPS
    ▼
┌──────────────────────────────────────────────────────────────┐
│  React SPA  (React 18 / TypeScript / Redux / Leaflet)        │
│  http://localhost:3000                                       │
└───────────────────────┬──────────────────────────────────────┘
                        │ HTTPS/REST
                        ▼
┌──────────────────────────────────────────────────────────────┐
│  API Gateway  (Spring Cloud Gateway / Java 21)               │
│  :8080  — JWT validation, rate limiting, routing             │
└──┬──────┬──────┬──────┬──────┬───────────────────────────────┘
   │      │      │      │      │  HTTP (internal, Eureka-resolved)
   ▼      ▼      ▼      ▼      ▼
┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────────┐
│Case  │ │Player│ │Time  │ │Map   │ │Police DB │
│Svc   │ │Svc   │ │&Pts  │ │Svc   │ │Svc       │
│:8081 │ │:8082 │ │:8083 │ │:8084 │ │:8085     │
└──┬───┘ └──┬───┘ └──┬───┘ └──┬───┘ └────┬─────┘
   │        │        │  │     │  │        │  │  │
   ▼        ▼        ▼  ▼     ▼  ▼        ▼  ▼  ▼
[PG-case][PG-player][PG-t][Redis][PG-map][PG-p][Mongo][ES]
                                 [Redis]

                  ┌───────────────────────┐
                  │  Service Registry     │
                  │  (Eureka) :8761       │
                  │  ← all services       │
                  │    register here      │
                  └───────────────────────┘

PG = PostgreSQL  ES = Elasticsearch
```

**Technology summary:**

| Container | Technology | Port | Notes |
|-----------|-----------|------|-------|
| React SPA | React 18, TypeScript, Redux, Leaflet | 3000 | Served via nginx in Docker |
| API Gateway | Spring Cloud Gateway, Spring Security | 8080 | Redis for rate limiting |
| Service Registry | Spring Cloud Netflix Eureka Server | 8761 | |
| Case Service | Spring Boot, JPA, PostgreSQL | 8081 | |
| Player Service | Spring Boot, JPA, PostgreSQL | 8082 | |
| Time & Points | Spring Boot, JPA, PostgreSQL, Redis | 8083 | Redis for real-time time tracking |
| Map Service | Spring Boot, JPA, PostGIS, Redis | 8084 | PostGIS for geospatial queries; Redis for live location |
| Police DB | Spring Boot, JPA, PostgreSQL, MongoDB, Elasticsearch | 8085 | Polyglot: structured + documents + full-text search |

---

## 4. C4 Level 3 — Component overview

*Internal structure of the Spring Boot services.*

### Package / module layout (per service)

```
com.detectiverpg.<service>/
├── controller/     ← REST controllers; thin, delegates to service layer
├── service/        ← Business logic; transaction boundaries live here
├── repository/     ← Spring Data JPA repositories + custom @Query methods
├── entity/         ← JPA entities / domain objects
├── dto/            ← Request/response DTOs; never expose entities directly
├── exception/      ← Custom exception classes + GlobalExceptionHandler
└── config/         ← Spring configuration (Security, Redis, etc.)
```

### Request lifecycle

```
HTTPS Request (from React UI or service-to-service)
    │
    ▼
API Gateway             ← validates JWT, enforces rate limit, routes to service
    │
    ▼
Controller layer        ← deserialises request body, validates with @Valid, delegates
    │
    ▼
Service layer           ← business logic, orchestration, transaction management
    │
    ▼
Repository layer        ← data access (JPA / Redis / MongoDB / Elasticsearch)
    │
    ▼
Database / cache
```

**Cross-cutting concerns:**
- **Logging** — SLF4J with structured JSON logging; correlation IDs propagated via HTTP headers
- **Error handling** — centralised `GlobalExceptionHandler` per service maps domain exceptions to HTTP status codes
- **Auth** — JWT validated at the API Gateway; downstream services receive a pre-validated user context header
- **Service discovery** — all services register with Eureka; inter-service calls use Eureka-resolved names via Spring Cloud LoadBalancer

---

## 5. Data architecture

### Ownership — one database per service

Each service owns its own database schema. No service accesses another service's database directly.

| Service | Store | Purpose |
|---------|-------|---------|
| Case Service | PostgreSQL | Cases, evidence, testimonies, verdicts |
| Player Service | PostgreSQL | Players, roles, case assignments, action log |
| Time & Points | PostgreSQL | Score history, time event log |
| Time & Points | Redis | Live in-game clock; active time tracking |
| Map Service | PostgreSQL + PostGIS | Locations, geospatial travel data |
| Map Service | Redis | Real-time player position cache |
| Police DB | PostgreSQL | Structured suspect records, footage metadata |
| Police DB | MongoDB | Unstructured coroner reports, investigation documents |
| Police DB | Elasticsearch | Full-text search index over suspect and evidence records |
| API Gateway | Redis | Rate-limiting counters, token blacklist |

### Schema migrations

- **Tool:** Flyway (per service)
- **Naming convention:** `V{n}__{description}.sql` (e.g. `V1__create_cases_table.sql`)

### Core entity relationships (high level)

```
Case ──< Evidence
Case ──< Testimony
Case ──< Verdict
Player >── Case  (assignment)
Player ──< ActionLog
Location ── Location  (travel_time matrix)
Player >── Location  (current position)
Suspect (PoliceDB) .. Case (via case_id reference, not FK across services)
```

---

## 6. Security architecture

### Authentication

JWT bearer tokens. All requests through the API Gateway must include a valid `Authorization: Bearer <token>` header. The Gateway validates the token signature and expiry using `JWT_SECRET` before forwarding. Downstream services trust the user context passed in request headers — they do not re-validate JWTs.

### Authorisation

Role-based. Player roles (`DETECTIVE`, `PARTNER_DETECTIVE`, `POLICEMAN`, `CORONER`, `WITNESS`, `KILLER`, `ACCOMPLICE`, `RESIDENT`) are embedded in the JWT claims. The API Gateway enforces coarse-grained access (e.g. verdict endpoints require `DETECTIVE` role). Service-layer checks enforce fine-grained rules (e.g. a detective can only access cases they are assigned to).

### Transport and data protection

- HTTPS: enforced in production; HTTP acceptable in local development only
- Sensitive config: environment variables injected at container startup; never committed to source control
- No PII beyond player display names — no compliance requirements currently

---

## 7. Integration map

| Integration | Direction | Protocol | Caller | Notes |
|-------------|-----------|----------|--------|-------|
| React UI → API Gateway | Outbound | HTTPS/REST | Browser | JWT in Authorization header |
| API Gateway → Core services | Outbound | HTTP/REST | API Gateway | Eureka-resolved; JWT forwarded as header |
| Case Svc → Player Svc | Outbound | HTTP/REST | Case Svc | Verify detective assignment |
| Case Svc → Time & Points | Outbound | HTTP/REST | Case Svc | Record investigation time events |
| Case Svc → Police DB | Outbound | HTTP/REST | Case Svc | Fetch suspect records for a case |
| Player Svc → Map Svc | Outbound | HTTP/REST | Player Svc | Update player location on move |
| Player Svc → Time & Points | Outbound | HTTP/REST | Player Svc | Award points for actions |
| Map Svc → Time & Points | Outbound | HTTP/REST | Map Svc | Get peak-hour modifier for travel calculation |
| All services → Service Registry | Outbound | HTTP | Each service | Heartbeat + registration (Eureka) |

---

## 8. Deployment architecture

### Local development

```
Docker Compose
├── service-registry  :8761
├── api-gateway       :8080  (depends on: service-registry, redis)
├── case-service      :8081  (depends on: postgres-case, service-registry)
├── player-service    :8082  (depends on: postgres-player, service-registry)
├── time-points       :8083  (depends on: postgres-time, redis, service-registry)
├── map-service       :8084  (depends on: postgres-map, redis, service-registry)
├── police-db         :8085  (depends on: postgres-police, mongodb, elasticsearch, service-registry)
├── postgres-*        (one container per service)
├── mongodb
├── elasticsearch
└── redis
```

### Environments

| Environment | Trigger | Notes |
|-------------|---------|-------|
| Local | Any | `docker-compose up --build` in `backend/` |
| Dev | `develop` branch | *← fill in: CI/CD pipeline TBD* |
| Staging | `release/*` | *← fill in: TBD* |
| Production | `main` | *← fill in: TBD* |

---

## 9. Key architectural decisions

Full records in [`docs/adr/`](docs/adr/).

| ADR | Decision | Rationale |
|-----|----------|-----------|
| [ADR-001](docs/adr/ADR-001-microservices-architecture.md) | Microservices over monolith | Independent scalability and deployment per game domain |
| [ADR-002](docs/adr/ADR-002-polyglot-persistence.md) | Polyglot persistence (PG + Mongo + ES + Redis) | Each data access pattern uses the optimal store |
| [ADR-003](docs/adr/ADR-003-api-gateway-jwt.md) | API Gateway with JWT auth | Single security enforcement point; downstream services stay stateless |

---

## 10. Non-functional requirements

| Attribute | Target | How achieved |
|-----------|--------|-------------|
| Availability | Best-effort for v1 | Services are independently deployable; partial failure doesn't down the whole game |
| Response time | p95 < 300ms for game actions | Redis caching for real-time state (location, clock); DB indexing |
| Scalability | Horizontal, stateless services | No in-process state; JWT-based auth; Eureka enables multi-instance |
| Security | Auth on all write endpoints | JWT validated at Gateway; role checks in service layer |
| Observability | Health + metrics per service | Spring Boot Actuator: `/actuator/health`, `/actuator/metrics` |

---

## 11. Known constraints and trade-offs

| Constraint | Impact | Status |
|------------|--------|--------|
| All services are in scaffold stage — no implementation yet | Architecture may evolve as code is written | Expected; ADRs capture decisions as they firm up |
| No distributed tracing yet | Hard to correlate logs across services | Planned: add `X-Correlation-ID` propagation in API Gateway + MDC in all services |
| No event bus / message queue | Inter-service calls are synchronous; cascading failures possible | Mitigated by Transactional Outbox pattern for scoring events; v1 keeps all other calls synchronous |
| Single Eureka server (no replica) | Service discovery is a single point of failure | Acceptable for v1; Eureka peer replication available when needed |
| Polyglot persistence adds operational complexity | Multiple DB engines to run, backup, and migrate | Mitigated by Docker Compose; each service owns its own store |
| Public path list duplicated in `JwtAuthenticationFilter` and `SecurityConfig` | DRY violation; paths can diverge silently | Planned: extract to a single shared config class |
| `/actuator` public path allows all actuator endpoints | Sensitive actuator endpoints (env, beans) exposed without auth in dev | Acceptable for dev; restrict to `/actuator/health` before any staging deployment |
| Verdict submission calls Time & Points Service synchronously | If scoring service is down, verdict submission fails | Planned: Transactional Outbox pattern in Case Service decouples verdict from scoring |
| `is_planted` evidence flag exists in Police DB Service PostgreSQL | Must never appear in API responses to detectives — enforced only by DTO discipline today | Planned: test assertion that verifies the field is absent from all `/police/evidence/**` responses |
