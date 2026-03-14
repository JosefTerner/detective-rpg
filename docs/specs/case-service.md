# Spec: Case Service

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

The game needs a central store for everything the detective discovers during an investigation: the case itself, collected evidence, witness testimonies, and the final verdict. Without this service there is no persistent record of investigation progress, and the scoring system cannot resolve win/loss conditions.

---

## 2. Responsibilities

### In scope — this service owns:
- Creating and storing crime cases (scenario metadata + killer assignment)
- Recording evidence collected during an investigation
- Recording witness testimonies submitted by supporting players
- Accepting and resolving final verdicts (correct / wrong accusation)
- Enforcing that only the assigned detective can modify a case

### Out of scope — this service does NOT own:
- Player profiles and role assignments — owned by **Player Service**
- In-game clock and score calculations — owned by **Time & Points Service**
- Raw police records, coroner reports, suspect criminal history — owned by **Police DB Service**
- Geolocation and travel time — owned by **Map Service**

---

## 3. Non-goals

- This service will not store unstructured documents (coroner reports, footage) — that is Police DB's domain
- This service will not generate the crime scenario (who the killer is) — scenario setup is a pre-game configuration step
- This service will not push real-time notifications — the client polls for state updates

---

## 4. Domain concepts

| Term | Definition |
|------|-----------|
| `Case` | A single game instance tied to a crime scenario; has one assigned detective |
| `Evidence` | A piece of physical or digital information collected at a location during the investigation |
| `Testimony` | A statement made by a witness or suspect during an interrogation, recorded verbatim |
| `Verdict` | The detective's final accusation naming one suspect as the killer |
| `Case status` | `OPEN` — investigation active; `CLOSED` — verdict submitted (terminal) |
| `Accusation result` | `CORRECT` if the accused matches the killer; `WRONG` otherwise — determines scoring |

---

## 5. Proposed design

### High-level approach

Standard Spring Boot REST service backed by PostgreSQL via Spring Data JPA. Cases are identified by UUID. The killer player ID is stored at case creation but never returned in API responses — it is used only at verdict resolution. Verdict submission triggers a synchronous call to Time & Points Service to finalise scores.

### Module structure (proposed)

```
com.detectiverpg.caseservice/
├── controller/
│   ├── CaseController.java
│   ├── EvidenceController.java
│   ├── TestimonyController.java
│   └── VerdictController.java
├── service/
│   ├── CaseService.java
│   ├── EvidenceService.java
│   ├── TestimonyService.java
│   └── VerdictService.java
├── repository/
│   ├── CaseRepository.java
│   ├── EvidenceRepository.java
│   └── TestimonyRepository.java
├── entity/
│   ├── Case.java
│   ├── Evidence.java
│   ├── Testimony.java
│   └── Verdict.java
├── dto/
├── exception/
│   ├── CaseNotFoundException.java
│   ├── CaseAlreadyClosedException.java
│   └── UnauthorisedAccessException.java
└── config/
    └── SecurityConfig.java
```

---

## 6. Proposed API contracts

### REST endpoints

| Method | Path | Auth | Request | Response | Notes |
|--------|------|------|---------|----------|-------|
| `POST` | `/cases` | Required | `{ scenarioId, detectiveId, killerPlayerId }` | `{ caseId, status }` | `killerPlayerId` stored, never returned |
| `GET` | `/cases/{id}` | Required | — | Case details + evidence + testimonies | Detective-only access |
| `POST` | `/cases/{id}/evidence` | Required | `{ type, description, locationId, collectedAt }` | Created evidence | Case must be OPEN |
| `POST` | `/cases/{id}/testimonies` | Required | `{ witnessId, statement, givenAt }` | Created testimony | Any player can submit for their own character |
| `POST` | `/cases/{id}/verdict` | Required (DETECTIVE) | `{ suspectId }` | `{ correct, message, points }` | Closes the case; triggers scoring |
| `GET` | `/cases/{id}/evidence` | Required | — | List of evidence | |
| `GET` | `/cases/{id}/testimonies` | Required | — | List of testimonies | |

---

## 7. Data model (proposed)

### `Case` → table `cases`

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID PK | |
| `scenario_id` | UUID | References the game scenario configuration |
| `detective_id` | UUID | The assigned detective's player ID |
| `killer_player_id` | UUID | Actual killer — never returned via API |
| `status` | enum | `OPEN`, `CLOSED` |
| `started_at` | timestamp | In-game clock start time |
| `closed_at` | timestamp | Set when verdict submitted; null while OPEN |

### `Evidence` → table `evidence`

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID PK | |
| `case_id` | UUID FK → cases | |
| `type` | varchar | `PHYSICAL`, `DOCUMENT`, `DIGITAL`, `TESTIMONY_REFERENCE` |
| `description` | text | What the detective observed |
| `location_id` | UUID | Where it was found (from Map Service) |
| `collected_at` | timestamp | In-game time of collection |

### `Testimony` → table `testimonies`

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID PK | |
| `case_id` | UUID FK → cases | |
| `witness_id` | UUID | Player ID of the person who gave the testimony |
| `statement` | text | Verbatim statement — may be true or false depending on role |
| `given_at` | timestamp | In-game time |

### `Verdict` → table `verdicts`

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID PK | |
| `case_id` | UUID FK → cases | One-to-one; only one verdict per case |
| `accused_player_id` | UUID | Who the detective accused |
| `correct` | boolean | Whether the accusation matched `killer_player_id` |
| `submitted_at` | timestamp | Wall-clock time |

---

## 8. Dependencies

### Modules this spec depends on

| Module | What it needs |
|--------|---------------|
| Player Service | Verify the requesting player is the assigned detective (`X-Player-Id` header) |
| Time & Points Service | Trigger score finalisation when a verdict is submitted |

### External services

| Service | Used for | Notes |
|---------|---------|-------|
| PostgreSQL | All persistent storage | Flyway migrations |

---

## 9. Open questions

| # | Question | Owner | Status |
|---|----------|-------|--------|
| 1 | Should evidence have a maximum count per case (to limit game complexity)? | TBD | Open |
| 2 | Can a detective amend or retract evidence, or is it append-only? | TBD | Open |
| 3 | Should testimonies be visible to all players in the game, or only to the detective? | TBD | Open |

---

## 10. Risks and concerns

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Verdict scoring call to Time & Points fails | Med | High | Consider retry or compensating transaction; for v1 fail the verdict request and let detective retry |
| Detective ID spoofing if Gateway header is bypassed | Low | High | Internal network trust + Gateway enforcement is sufficient for v1 |

---

## 11. Acceptance criteria

- [ ] `POST /cases` creates a case with status `OPEN`; `killerPlayerId` is stored but not returned
- [ ] `POST /cases/{id}/evidence` on a `CLOSED` case returns HTTP 409
- [ ] `POST /cases/{id}/verdict` with the correct killer returns `correct: true` and closes the case
- [ ] `POST /cases/{id}/verdict` with a wrong suspect returns `correct: false`, closes the case, and awards a point penalty
- [ ] A second verdict on a closed case returns HTTP 409
- [ ] A non-detective player cannot submit a verdict (HTTP 403)

---

## 12. Out of scope for v1

- Case search / listing across multiple cases (detective case history) — add when needed
- Real-time case updates via WebSocket — client polls for now
- Soft-delete or archiving of old cases
