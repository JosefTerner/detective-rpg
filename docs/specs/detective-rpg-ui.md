# Spec: Detective RPG UI

| Field | Value |
|-------|-------|
| **Status** | Approved |
| **Author** | *← fill in* |
| **Created** | 2026-03-14 |
| **Last updated** | 2026-03-14 |
| **Target milestone** | TBD |
| **Related ADRs** | [ADR-001](../adr/ADR-001-microservices-architecture.md), [ADR-003](../adr/ADR-003-api-gateway-jwt.md) |

---

## 1. Problem statement

Players need a web interface to participate in the game. Without a UI, all actions would require raw API calls. The interface must support the detective's investigation workflow (map navigation, evidence collection, interrogation, verdict submission) as well as the role-play interactions of supporting and opposing players.

---

## 2. Responsibilities

### In scope — this UI owns:
- Interactive town map (Leaflet) for navigating between locations
- Case dashboard: active cases, investigation progress, score
- Evidence and testimony views: listing what has been collected
- Character interaction: initiating and responding to interrogations
- Police DB access: searching suspect records, viewing coroner reports
- Verdict submission form
- All API communication with backend via the API Gateway

### Out of scope — this UI does NOT own:
- Game state persistence — all state lives in backend services
- Business rule enforcement — all rules are enforced server-side
- Map tile hosting — Leaflet connects to an external tile provider

---

## 3. Non-goals

- This UI will not implement a chat system — player communication is via the game's interrogation/testimony mechanics
- This UI will not have an admin panel for game setup in v1 — pre-game scenario configuration is out of scope
- This UI will not render video footage — footage metadata only

---

## 4. Domain concepts

| Term | Definition |
|------|-----------|
| `Session` | A player's active game connection, identified by their JWT stored in browser memory |
| `Case dashboard` | The main view for the detective: case timeline, evidence list, suspect list, score |
| `Map view` | An interactive Leaflet map of the town showing all locations; clicking a location initiates travel |
| `Interrogation view` | A structured Q&A interface where the detective asks questions and the suspect player responds |
| `Evidence panel` | A list of all collected evidence linked to their collection locations on the map |

---

## 5. Proposed design

### High-level approach

React 18 SPA with TypeScript. Redux manages global game state (current case, player identity, case data). React Router handles navigation between pages. Axios instance is pre-configured with base URL from `REACT_APP_API_URL` and attaches the JWT from Redux state to every request. Leaflet renders the interactive map using custom markers for each location type. All backend calls go through the API Gateway at port 8080.

The UI polls the backend for updates (no WebSocket in v1). Poll interval TBD — see open questions.

### Module structure (proposed)

```
src/
├── components/
│   ├── Map/              ← Leaflet map + location markers + travel control
│   ├── Evidence/         ← evidence list, evidence card
│   ├── Testimony/        ← testimony list, submission form
│   ├── Interrogation/    ← Q&A interface for detective and suspect
│   ├── Score/            ← score display + time elapsed
│   └── common/           ← Button, Modal, LoadingSpinner, ErrorBoundary
├── pages/
│   ├── LoginPage.tsx
│   ├── CaseDashboardPage.tsx
│   ├── MapPage.tsx
│   ├── EvidencePage.tsx
│   ├── PoliceDatabasePage.tsx
│   └── VerdictPage.tsx
├── store/
│   ├── index.ts          ← Redux store setup
│   ├── caseSlice.ts
│   ├── playerSlice.ts
│   └── gameClockSlice.ts
├── services/
│   ├── api.ts            ← Axios instance + interceptors
│   ├── caseService.ts
│   ├── playerService.ts
│   ├── mapService.ts
│   ├── policeDbService.ts
│   └── timeService.ts
├── utils/
│   ├── formatGameTime.ts
│   └── travelTime.ts
├── assets/
└── tests/
```

---

## 6. Proposed API contracts

The UI consumes the following API Gateway routes:

| Page / feature | API calls |
|----------------|-----------|
| Case dashboard | `GET /cases/{id}` |
| Map view — load locations | `GET /locations` |
| Map view — travel | `GET /travel-time?from=&to=`, `POST /player-location`, `POST /time/travel` |
| Evidence | `GET /cases/{id}/evidence`, `POST /cases/{id}/evidence` |
| Testimonies | `GET /cases/{id}/testimonies`, `POST /cases/{id}/testimonies` |
| Police DB search | `GET /police/records?query=` |
| Suspect detail | `GET /police/suspects/{id}` |
| Coroner report | `GET /police/reports/{id}` |
| Score / clock | `GET /time/status?caseId=`, `GET /points/{playerId}?caseId=` |
| Verdict | `POST /cases/{id}/verdict` |

---

## 7. Data model (proposed)

No persistent client-side storage beyond Redux in-memory state. JWT is stored in memory (not localStorage) to reduce XSS risk.

### Key Redux slices

| Slice | State |
|-------|-------|
| `playerSlice` | `{ playerId, displayName, role, caseId }` |
| `caseSlice` | `{ caseId, status, evidence[], testimonies[], suspectList[] }` |
| `gameClockSlice` | `{ currentGameTime, elapsedMinutes, isPeakHour }` |

---

## 8. Dependencies

### External services

| Service | Used for | Notes |
|---------|---------|-------|
| API Gateway | All backend calls | `REACT_APP_API_URL` env var |
| Leaflet tile provider | Map tile rendering | Default: OpenStreetMap tiles |

---

## 9. Open questions

| # | Question | Owner | Status |
|---|----------|-------|--------|
| 1 | What is the polling interval for case state updates? (5s? 10s?) | TBD | Open |
| 2 | Should JWT be stored in memory (Redux) or sessionStorage? Memory avoids XSS risk but loses state on refresh. | TBD | Open |
| 3 | How does the detective know when a supporting player has submitted a testimony (real-time notification vs. poll)? | TBD | Open |
| 4 | Are all player roles on the same UI, or do killer/accomplice have a different view? | TBD | Open |

---

## 10. Risks and concerns

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Polling for updates creates excessive load at 20 players | Med | Med | Implement exponential backoff on unchanged responses; cache-busting headers |
| Leaflet tile provider rate limits or goes down | Low | Med | Can switch tile providers via config; no game-critical functionality depends on tiles |

---

## 11. Acceptance criteria

- [ ] A logged-in detective can view the town map with all locations marked
- [ ] Clicking a location and confirming travel calls `GET /travel-time` and `POST /player-location`
- [ ] The evidence panel lists all evidence for the detective's active case
- [ ] The verdict form is only shown to the player with `DETECTIVE` role
- [ ] Submitting a verdict shows whether it was correct and displays the final score

---

## 12. Out of scope for v1

- Real-time updates via WebSocket (polling only)
- Mobile-responsive layout
- Dark mode / theme support
- Offline / PWA support
- Game setup / scenario creation UI
