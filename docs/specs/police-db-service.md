# Spec: Police DB Service

| Field | Value |
|-------|-------|
| **Status** | Approved |
| **Author** | *← fill in* |
| **Created** | 2026-03-14 |
| **Last updated** | 2026-03-14 |
| **Target milestone** | TBD |
| **Related ADRs** | [ADR-001](../adr/ADR-001-microservices-architecture.md), [ADR-002](../adr/ADR-002-polyglot-persistence.md) |

---

## 1. Problem statement

Detectives need access to police records during an investigation: suspect criminal history, coroner reports, security footage metadata, and the ability to search across all of these. This data has three distinct access patterns — structured records, unstructured documents, and full-text keyword search — that cannot be efficiently served by a single data store.

---

## 2. Responsibilities

### In scope — this service owns:
- Structured suspect records (personal details, criminal history) in PostgreSQL
- Unstructured investigation documents (coroner reports, forensic notes) in MongoDB
- Security footage metadata (timestamps, locations, file references) in PostgreSQL
- Full-text search across suspects and evidence via Elasticsearch
- Access control: only detectives (and their assigned officers) can query sensitive records

### Out of scope — this service does NOT own:
- Case evidence collected by the detective during the investigation — owned by **Case Service**
- Player identity and roles — owned by **Player Service**
- Physical evidence photographs or video files — this service stores *metadata*; actual binary files are out of scope for v1

---

## 3. Non-goals

- This service will not store actual video files — metadata only (file path, duration, timestamp)
- This service will not authenticate requests — that is the API Gateway's responsibility
- This service will not perform real-time footage analysis or AI inference

---

## 4. Domain concepts

| Term | Definition |
|------|-----------|
| `Suspect` | A game character (non-detective player) with a known identity, address, and optional criminal history |
| `Coroner report` | An unstructured document describing the cause and time of death; written by the Coroner player |
| `Security footage` | Metadata about a surveillance recording from a location: timestamp, location ID, what it shows |
| `Criminal record` | Past offences associated with a suspect, stored as structured rows linked to a suspect |
| `Search index` | Elasticsearch index over suspect names, addresses, criminal history, and evidence descriptions |

---

## 5. Proposed design

### High-level approach

Three data stores serving three access patterns:
- **PostgreSQL:** suspect records, criminal records, footage metadata — structured, relational, FK-linked
- **MongoDB:** coroner reports and forensic investigation documents — variable-length, semi-structured
- **Elasticsearch:** search index populated from both PostgreSQL and MongoDB data via index synchronisation on write

When a new suspect or document is created, the service immediately indexes it in Elasticsearch. Searches go to Elasticsearch; record retrieval by ID goes to the primary store.

### Module structure (proposed)

```
com.detectiverpg.policedbservice/
├── controller/
│   ├── SuspectController.java
│   ├── ReportController.java
│   ├── FootageController.java
│   └── SearchController.java
├── service/
│   ├── SuspectService.java
│   ├── ReportService.java
│   ├── FootageService.java
│   ├── SearchService.java
│   └── IndexSyncService.java          ← syncs writes to Elasticsearch
├── repository/
│   ├── SuspectRepository.java         ← JPA
│   ├── CriminalRecordRepository.java  ← JPA
│   ├── FootageRepository.java         ← JPA
│   ├── ReportMongoRepository.java     ← Spring Data MongoDB
│   └── SearchRepository.java         ← Spring Data Elasticsearch
├── entity/
│   ├── Suspect.java                   ← JPA
│   ├── CriminalRecord.java            ← JPA
│   ├── FootageMetadata.java           ← JPA
│   └── CornerReport.java              ← MongoDB document
├── dto/
└── config/
    ├── MongoConfig.java
    └── ElasticsearchConfig.java
```

---

## 6. Proposed API contracts

### REST endpoints

| Method | Path | Auth | Request | Response | Notes |
|--------|------|------|---------|----------|-------|
| `GET` | `/police/suspects/{id}` | Required | — | Suspect details + criminal records | |
| `GET` | `/police/reports/{id}` | Required | — | Coroner report document | From MongoDB |
| `POST` | `/police/reports` | Required (CORONER) | `{ caseId, body, authorId }` | Created report ID | Only coroner player can create |
| `POST` | `/police/footage` | Required | `{ locationId, timestamp, durationSeconds, description }` | Created footage ID | |
| `GET` | `/police/footage/{id}` | Required | — | Footage metadata | |
| `GET` | `/police/records` | Required | `?query={term}` | List of matching suspects/evidence | Elasticsearch full-text search |
| `GET` | `/police/evidence/{id}` | Required | — | Evidence detail (from any store) | Routing TBD — see open questions |

---

## 7. Data model (proposed)

### `Suspect` → table `suspects` (PostgreSQL)

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID PK | |
| `full_name` | varchar(200) | |
| `address` | varchar(300) | |
| `occupation` | varchar(100) | |
| `player_id` | UUID | Links to Player Service player; no FK (cross-service) |
| `case_id` | UUID | The game case this suspect belongs to |

### `CriminalRecord` → table `criminal_records` (PostgreSQL)

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID PK | |
| `suspect_id` | UUID FK → suspects | |
| `offence` | varchar(300) | |
| `date` | date | In-game date of past offence |
| `notes` | text | |

### `CoroneReport` → MongoDB collection `coroner_reports`

```json
{
  "_id": "uuid",
  "caseId": "uuid",
  "authorId": "uuid",
  "causeOfDeath": "string",
  "timeOfDeath": "ISO timestamp (in-game)",
  "additionalFindings": "free text",
  "submittedAt": "ISO timestamp"
}
```

### `FootageMetadata` → table `footage_metadata` (PostgreSQL)

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID PK | |
| `case_id` | UUID | |
| `location_id` | UUID | Where the footage was recorded |
| `timestamp` | timestamp | In-game time the footage was captured |
| `duration_seconds` | int | |
| `description` | text | What the footage shows |
| `file_path` | varchar | Out of scope for v1 — placeholder |

---

## 8. Dependencies

### External services

| Service | Used for | Notes |
|---------|---------|-------|
| PostgreSQL | Structured suspects, records, footage metadata | Flyway migrations |
| MongoDB | Coroner reports and documents | Schema-less |
| Elasticsearch | Full-text search index | Index mappings versioned in code |

---

## 9. Open questions

| # | Question | Owner | Status |
|---|----------|-------|--------|
| 1 | How is the Elasticsearch index kept in sync? Synchronous on-write vs. async CDC? | TBD | Open |
| 2 | Should `GET /police/evidence/{id}` be a unified endpoint routing to PG or MongoDB, or separate endpoints? | TBD | Open |
| 3 | Are suspects pre-seeded for each scenario, or created dynamically by the game master? | TBD | Open |
| 4 | Should non-detective players be able to see suspect records, or is access detective-only? | TBD | Open |

---

## 10. Risks and concerns

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Elasticsearch index out of sync with primary stores | Med | Med | Implement `IndexSyncService` that writes to ES on every create/update; add periodic reindex job |
| Three-database service complexity for v1 | High | Med | Acceptable — this is the most complex service by design; document clearly in the module doc once implemented |
| MongoDB + Elasticsearch both optional for basic gameplay | Low | Low | Ensure the service degrades gracefully: if ES is down, fall back to PostgreSQL ILIKE search |

---

## 11. Acceptance criteria

- [ ] `GET /police/suspects/{id}` returns suspect details with criminal records nested
- [ ] `POST /police/reports` by a non-CORONER player returns HTTP 403
- [ ] `GET /police/records?query=smith` returns suspects and evidence matching "smith" via Elasticsearch
- [ ] Creating a suspect immediately makes them searchable via `/police/records`
- [ ] `GET /police/reports/{id}` returns the MongoDB document in full

---

## 12. Out of scope for v1

- Actual video/image file storage (metadata only)
- Elasticsearch aggregations / faceted search UI
- Elasticsearch index replication or cluster setup
- MongoDB replica set
