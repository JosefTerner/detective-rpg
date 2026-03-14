# Spec: Time & Points Service

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

The game uses an in-game clock that advances as the detective takes actions and travels between locations. The scoring system uses the elapsed in-game time, action quality, and accusation accuracy to calculate the final score. Without a dedicated service to own the game clock and scoring logic, this logic would be scattered across Case Service, Player Service, and the frontend — making it impossible to enforce consistently.

---

## 2. Responsibilities

### In scope — this service owns:
- Maintaining the in-game clock for each active case
- Starting and stopping time tracking around detective actions
- Applying travel time delays including peak-hour modifiers
- Computing and updating player scores based on game events
- Persisting score history for post-game review

### Out of scope — this service does NOT own:
- Travel distance or route calculation — owned by **Map Service** (this service only applies the time delta it receives)
- Action recording / audit log — owned by **Player Service**
- Case outcome / verdict correctness — owned by **Case Service** (which calls this service to trigger scoring)

---

## 3. Non-goals

- This service will not calculate route distances or determine peak hours independently — it receives `travelMinutes` from Map Service and applies peak-hour offsets based on the current in-game time
- This service will not push real-time clock updates to the client — the client polls `/time/status`

---

## 4. Domain concepts

| Term | Definition |
|------|-----------|
| `In-game clock` | A per-case timestamp that advances each time a timed action is completed; does not track wall time |
| `Time event` | A start/end pair recording an action's duration against the in-game clock |
| `Peak hour` | In-game time windows (7–9 AM, 1–2 PM, 6–7 PM) that add 15 minutes to any travel time |
| `Score` | A numeric value per player, per case; computed from time taken, correct deductions, wrong accusations, and false leads |
| `Point delta` | A signed integer applied to a player's score for a specific event type |

---

## 5. Proposed design

### High-level approach

The in-game clock for each case is stored in Redis as a timestamp (fast reads, TTL auto-cleanup when a case closes). Time events are persisted to PostgreSQL for history. Score state is kept in PostgreSQL; Redis is not used for score caching in v1 (low read volume). Peak-hour detection is a pure function of the current in-game clock value.

### Module structure (proposed)

```
com.detectiverpg.timepointsservice/
├── controller/
│   ├── TimeController.java        ← /time/** endpoints
│   └── PointsController.java      ← /points/** endpoints
├── service/
│   ├── GameClockService.java      ← manages Redis-backed in-game clock
│   ├── TimeTrackingService.java   ← start/stop time events
│   ├── PeakHourService.java       ← pure logic: is a given in-game time peak?
│   └── ScoringService.java        ← applies point deltas, persists score
├── repository/
│   ├── TimeEventRepository.java
│   └── PlayerScoreRepository.java
├── entity/
│   ├── TimeEvent.java
│   └── PlayerScore.java
├── dto/
└── config/
    └── RedisConfig.java
```

### Key algorithms

**Peak hour check:**
```
isPeakHour(inGameTime):
  hour = inGameTime.hour
  return (7 <= hour < 9) OR (13 <= hour < 14) OR (18 <= hour < 19)
```

**Scoring:**
```
baseScore = MAX_SCORE - (elapsedInGameMinutes * TIME_PENALTY_PER_MINUTE)
correctVerdictBonus = +200
wrongAccusationPenalty = -100
falseLead = -25 per false lead followed
solvedWithin3Days bonus = +100
finalScore = max(0, baseScore + bonuses - penalties)
```

*Exact constants TBD — see open questions.*

---

## 6. Proposed API contracts

### REST endpoints

| Method | Path | Auth | Request | Response | Notes |
|--------|------|------|---------|----------|-------|
| `POST` | `/time/start` | Required | `{ caseId, actionType }` | `{ eventId, gameTimeStart }` | Starts a time event against the in-game clock |
| `POST` | `/time/end` | Required | `{ eventId }` | `{ gameTimeEnd, durationMinutes }` | Stops a time event; advances the clock |
| `GET` | `/time/status` | Required | `?caseId=` | `{ currentGameTime, elapsedMinutes, isPeakHour }` | Current in-game clock state |
| `POST` | `/time/travel` | Required | `{ caseId, baseTravelMinutes }` | `{ adjustedMinutes, isPeakHour }` | Applies peak-hour modifier and advances clock |
| `POST` | `/points/update` | Required | `{ caseId, playerId, eventType, delta }` | `{ newTotal }` | Applies a point delta |
| `GET` | `/points/{playerId}` | Required | `?caseId=` | `{ score, breakdown }` | Current score with event breakdown |

---

## 7. Data model (proposed)

### `TimeEvent` → table `time_events`

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID PK | |
| `case_id` | UUID | |
| `player_id` | UUID | |
| `action_type` | varchar | E.g. `TRAVEL`, `INTERROGATION`, `EVIDENCE_SEARCH` |
| `game_time_start` | timestamp | In-game clock at start |
| `game_time_end` | timestamp | In-game clock at end; null while in progress |
| `duration_minutes` | int | Computed on end; null while in progress |

### `PlayerScore` → table `player_scores`

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID PK | |
| `player_id` | UUID | |
| `case_id` | UUID | |
| `total_score` | int | Running total; updated on each delta |
| `event_log` | jsonb | Array of `{ eventType, delta, gameTime }` for score breakdown |

---

## 8. Dependencies

### Modules this spec depends on

| Module | What it needs |
|--------|---------------|
| Map Service | Calls this service to get peak-hour modifier for travel calculations |

### External services

| Service | Used for | Notes |
|---------|---------|-------|
| Redis | In-game clock per case | Key: `game-clock:{caseId}` |
| PostgreSQL | Time event history + score persistence | Flyway migrations |

---

## 9. Open questions

| # | Question | Owner | Status |
|---|----------|-------|--------|
| 1 | What are the exact scoring constants (max score, time penalty per minute, bonuses)? | TBD | Open |
| 2 | Does the in-game clock pause when no actions are in progress, or does it always advance in real time? | TBD | Open |
| 3 | Are peak hour windows fixed game-wide, or configurable per scenario? | TBD | Open |
| 4 | Can a time event be open (started) for multiple actions simultaneously (e.g. detective travels while officer does something)? | TBD | Open |

---

## 10. Risks and concerns

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Redis key lost (restart) causes in-game clock reset | Low | High | Persist clock value to PostgreSQL on each advance; Redis is primary, PG is fallback |
| Clock drift if `time/end` is never called after `time/start` | Med | Med | Add a stale-event cleanup job or TTL on the Redis key |

---

## 11. Acceptance criteria

- [ ] `POST /time/start` followed by `POST /time/end` returns correct `durationMinutes` and advances the case in-game clock
- [ ] `GET /time/status` for a case reflects the latest advanced game time
- [ ] `POST /time/travel` during a peak-hour window adds 15 minutes to the provided `baseTravelMinutes`
- [ ] `POST /points/update` with a negative delta correctly reduces the player's score (minimum 0)
- [ ] Clock survives a service restart (Redis value falls back to PostgreSQL last-known)

---

## 12. Out of scope for v1

- Real-time clock broadcast via WebSocket
- Configurable scoring parameters per scenario (hardcoded constants for v1)
- Multi-detective scoring (v1 supports one detective per case)
