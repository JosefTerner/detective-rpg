# ADR-002: Polyglot persistence — PostgreSQL, MongoDB, Elasticsearch, Redis

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-03-14 |
| **Deciders** | *← fill in: project team* |
| **Related ADRs** | [ADR-001](ADR-001-microservices-architecture.md) |

---

## Context

The five core game services have materially different data access patterns:

- **Case, Player, Time & Points** — structured relational data with well-defined schemas; standard CRUD plus reporting queries.
- **Map Service** — geospatial queries (travel time between coordinates); requires PostGIS extensions not available in standard RDBMS setups.
- **Police DB Service** — three distinct needs: structured suspect records (relational), unstructured coroner reports and footage metadata (document store), and full-text keyword search across all records (inverted index).

Forcing all services onto a single PostgreSQL instance would require shoehorning document data into JSONB columns and building a custom full-text search layer — both are significant engineering overhead compared to using the right tool per access pattern.

---

## Decision

We will use polyglot persistence: each service uses the store(s) best suited to its access patterns.

| Service | Stores |
|---------|--------|
| Case, Player, Time & Points | PostgreSQL |
| Map Service | PostgreSQL + PostGIS, Redis (live player positions) |
| Police DB | PostgreSQL (structured records), MongoDB (documents), Elasticsearch (full-text search) |
| API Gateway | Redis (rate limiting, token blacklist) |
| Time & Points | Redis (live in-game clock) |

---

## Alternatives considered

| Option | Pros | Cons | Why rejected |
|--------|------|------|-------------|
| Polyglot persistence (chosen) | Best tool per pattern; no workarounds needed | More services to operate; Devs need familiarity with multiple stores | — (chosen) |
| PostgreSQL only | Single engine; simpler ops; team expertise | JSONB for documents is workable but verbose; full-text search via `pg_trgm` is limited vs Elasticsearch | Rejected: Elasticsearch's relevance ranking and faceted search are significantly better for detective search use case |
| MongoDB only | Flexible schema; good for documents | No geospatial support matching PostGIS; weak relational query support | Rejected: relational integrity matters for case-player-evidence relationships |

---

## Consequences

**Positive:**
- Map Service geospatial queries use native PostGIS operators — no workarounds
- Police DB full-text search uses Elasticsearch's relevance ranking out of the box
- Document flexibility in MongoDB handles variable-length coroner reports without schema migrations

**Negative / trade-offs:**
- Docker Compose must start and manage 4+ database services for local dev
- Developers need working knowledge of three DB paradigms
- Backup and migration strategies differ per store

**Neutral / follow-up actions:**
- Document per-service connection config in the relevant service spec
- Each service owns its own Flyway migrations (PostgreSQL services); MongoDB uses schema-less; Elasticsearch index mappings versioned in code
