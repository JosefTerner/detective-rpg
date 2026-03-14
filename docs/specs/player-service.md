# Spec: Player Service

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

The game requires a persistent record of every player: who they are, what role they've been assigned in a game session, and what actions they've taken. Without this service there is no way to enforce role-based access, assign detectives to cases, or build an action audit trail for scoring.

---

## 2. Responsibilities

### In scope — this service owns:
- Player profile registration and retrieval
- Role assignment for a game session (detective, witness, killer, etc.)
- Detective-to-case assignment
- Logging in-game player actions (movements, interrogations, evidence collections)

### Out of scope — this service does NOT own:
- JWT issuance and authentication — owned by **API Gateway** (pending auth service)
- Case content (evidence, testimonies, verdicts) — owned by **Case Service**
- Scoring calculations — owned by **Time & Points Service**
- Live player location cache — owned by **Map Service**

---

## 3. Non-goals

- This service will not store game scenario configuration or killer assignments — those are set up pre-game and stored in Case Service
- This service will not calculate or store points — it logs actions, Time & Points Service scores them

---

## 4. Domain concepts

| Term | Definition |
|------|-----------|
| `Player` | A registered user with a display name; persistent across game sessions |
| `Role` | The character a player plays in a specific game session — determines what they can do and whether they must tell the truth |
| `Action` | A discrete game event initiated by a player: `MOVED`, `INTERROGATED`, `COLLECTED_EVIDENCE`, `SUBMITTED_VERDICT`, etc. |
| `Assignment` | The link between a detective player and a specific case |

---

## 5. Proposed design

### High-level approach

Spring Boot REST service backed by PostgreSQL. Player profiles are simple and persistent. Role assignments are per game-session scoped by `caseId`. The action log is append-only — actions are never updated or deleted, only added. Other services (Case, Time & Points) call this service to look up player details or log actions.

### Module structure (proposed)

```
com.detectiverpg.playerservice/
├── controller/
│   ├── PlayerController.java
│   ├── RoleController.java
│   └── ActionController.java
├── service/
│   ├── PlayerService.java
│   ├── RoleAssignmentService.java
│   └── ActionLogService.java
├── repository/
│   ├── PlayerRepository.java
│   ├── RoleAssignmentRepository.java
│   └── ActionLogRepository.java
├── entity/
│   ├── Player.java
│   ├── RoleAssignment.java
│   └── ActionLog.java
├── dto/
├── exception/
│   ├── PlayerNotFoundException.java
│   └── RoleAlreadyAssignedException.java
└── config/
```

---

## 6. Proposed API contracts

### REST endpoints

| Method | Path | Auth | Request | Response | Notes |
|--------|------|------|---------|----------|-------|
| `POST` | `/players` | No (registration) | `{ displayName }` | `{ playerId, displayName }` | Creates player profile |
| `GET` | `/players/{id}` | Required | — | Player profile + current role | |
| `POST` | `/players/{id}/assign-role` | Required | `{ caseId, role }` | Updated assignment | Role is validated against enum |
| `POST` | `/players/{id}/action` | Required | `{ caseId, actionType, metadata }` | Logged action | Append-only |
| `GET` | `/players/{id}/actions` | Required | `?caseId=` | List of actions for a case | Used by Time & Points for scoring |

---

## 7. Data model (proposed)

### `Player` → table `players`

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID PK | |
| `display_name` | varchar(100) | Unique per player |
| `created_at` | timestamp | |

### `RoleAssignment` → table `role_assignments`

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID PK | |
| `player_id` | UUID FK → players | |
| `case_id` | UUID | Reference to Case Service case; no FK (cross-service) |
| `role` | enum | See below |
| `assigned_at` | timestamp | |

**Role values:**

| Value | Tells the truth? | Win condition |
|-------|-----------------|---------------|
| `DETECTIVE` | Yes | Correctly names the killer |
| `PARTNER_DETECTIVE` | Yes | Case is solved correctly |
| `POLICEMAN` | Yes | Case is solved correctly |
| `CORONER` | Yes | Case is solved correctly |
| `WITNESS` | Yes | Case is solved correctly |
| `KILLER` | No | Detective fails or accuses wrong person |
| `ACCOMPLICE` | No | Detective fails or accuses wrong person |
| `RESIDENT` | Neutral | Role-card dependent |

### `ActionLog` → table `action_logs`

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID PK | |
| `player_id` | UUID FK → players | |
| `case_id` | UUID | |
| `action_type` | enum | `MOVED`, `INTERROGATED`, `COLLECTED_EVIDENCE`, `SUBMITTED_VERDICT`, `DREW_HINT`, `DEPLOYED_OFFICER` |
| `metadata` | jsonb | Action-specific data (e.g. `{ "toLocationId": "...", "travelMinutes": 15 }`) |
| `game_time` | timestamp | In-game timestamp (from Time & Points) |
| `wall_time` | timestamp | Real wall-clock time |

---

## 8. Dependencies

### External services

| Service | Used for | Notes |
|---------|---------|-------|
| PostgreSQL | All persistent storage | Flyway migrations |

---

## 9. Open questions

| # | Question | Owner | Status |
|---|----------|-------|--------|
| 1 | Can a player have multiple active role assignments across different concurrent games? | TBD | Open |
| 2 | Should player registration require any form of auth (email, session), or is display name sufficient for v1? | TBD | Open |
| 3 | Should the action log be queryable by action type for scoring, or does Time & Points need a dedicated scoring event endpoint? | TBD | Open |

---

## 10. Risks and concerns

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Display name collisions if multiple players choose the same name | Med | Low | Enforce uniqueness at DB level; return 409 on conflict |

---

## 11. Acceptance criteria

- [ ] `POST /players` creates a profile; duplicate display names return HTTP 409
- [ ] `POST /players/{id}/assign-role` with an invalid role enum value returns HTTP 400
- [ ] `POST /players/{id}/action` appends to the action log and returns the created entry
- [ ] `GET /players/{id}/actions?caseId=...` returns only actions for that case

---

## 12. Out of scope for v1

- Player authentication (password, OAuth2) — display name only for v1
- Player statistics across games
- Player blocking or moderation features
