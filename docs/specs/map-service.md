# Spec: Map Service

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

The game takes place across a small town with named locations. Travel between locations costs in-game time, which affects the detective's score. The detective and police officers need to be tracked in real time so the UI can reflect their current position. Without this service there is no canonical source for location data, travel times, or live player positions.

---

## 2. Responsibilities

### In scope — this service owns:
- The canonical list of town locations (name, coordinates, type)
- Travel time calculation between any two locations (geospatial distance + base speed)
- Providing the peak-hour travel time adjustment factor (delegated to Time & Points Service)
- Real-time player position tracking (current location per player per case)
- Identifying which players are at a given location (for on-site interrogations)

### Out of scope — this service does NOT own:
- Applying the peak-hour time modifier — **Time & Points Service** owns peak-hour logic; Map Service provides base travel minutes
- Player profiles — owned by **Player Service**
- Case location associations (where the crime scene is) — owned by **Case Service**

---

## 3. Non-goals

- This service will not render the map — the React UI renders tiles via Leaflet directly from a tile provider
- This service will not track NPC positions (killer's movements are game master controlled, not real-time)
- This service will not enforce whether a player is allowed to travel to a location — that is a game rule enforced in Case Service

---

## 4. Domain concepts

| Term | Definition |
|------|-----------|
| `Location` | A named point of interest in the town: address, coordinates, and type (residence, workplace, landmark, police HQ, etc.) |
| `Travel time` | Base minutes to travel between two locations, calculated from geospatial distance assuming a fixed average speed |
| `Peak-hour modifier` | +15 minutes added to all travel during peak windows — owned by Time & Points Service; Map Service returns base time only |
| `Player position` | A player's current location during a game session, stored in Redis for real-time queries |

---

## 5. Proposed design

### High-level approach

Locations are stored in PostgreSQL with PostGIS geometry column for geospatial distance queries. Base travel time is computed as `ST_Distance(a.coords, b.coords) / AVERAGE_SPEED_M_PER_MIN`. Player positions are stored in Redis as `player-position:{caseId}:{playerId}` with no expiry (cleared when a case closes). Location data is relatively static — seeded at startup, infrequently updated.

### Module structure (proposed)

```
com.detectiverpg.mapservice/
├── controller/
│   ├── LocationController.java        ← GET /locations
│   ├── TravelController.java          ← GET /travel-time
│   └── PlayerLocationController.java  ← POST /player-location, GET /players-at-location
├── service/
│   ├── LocationService.java
│   ├── TravelTimeService.java         ← PostGIS distance query + speed calc
│   └── PlayerPositionService.java     ← Redis read/write
├── repository/
│   ├── LocationRepository.java        ← JPA + @Query with PostGIS functions
│   └── PlayerPositionRedisRepository.java
├── entity/
│   └── Location.java                  ← includes Point geometry column
├── dto/
└── config/
    └── RedisConfig.java
```

### Key algorithms

**Base travel time:**
```
baseTravelMinutes = ST_Distance(fromCoords, toCoords, true) / AVERAGE_WALKING_SPEED_M_PER_MIN
```
*`AVERAGE_WALKING_SPEED_M_PER_MIN` = TBD — see open questions.*

The caller (Time & Points) applies the peak-hour modifier on top of this base value.

---

## 6. Proposed API contracts

### REST endpoints

| Method | Path | Auth | Request | Response | Notes |
|--------|------|------|---------|----------|-------|
| `GET` | `/locations` | Required | — | List of all locations | Includes id, name, type, coordinates |
| `GET` | `/locations/{id}` | Required | — | Single location detail | |
| `GET` | `/travel-time` | Required | `?from={id}&to={id}` | `{ baseTravelMinutes }` | Peak-hour modifier NOT applied here |
| `POST` | `/player-location` | Required | `{ playerId, caseId, locationId }` | Updated position | Overwrites current position |
| `GET` | `/player-location/{playerId}` | Required | `?caseId=` | `{ locationId, locationName }` | Current position |
| `GET` | `/players-at-location/{locationId}` | Required | `?caseId=` | List of player IDs at this location | Used to enable on-site group interrogations |

---

## 7. Data model (proposed)

### `Location` → table `locations`

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID PK | |
| `name` | varchar(200) | Display name (e.g. "Baker's Shop") |
| `type` | enum | `POLICE_HQ`, `RESIDENCE`, `WORKPLACE`, `LANDMARK`, `CRIME_SCENE` |
| `address` | varchar(300) | Human-readable address |
| `coords` | geometry(Point, 4326) | PostGIS WGS84 point |
| `description` | text | Optional flavour text shown in the UI |

**Player positions in Redis:**
```
Key:   player-position:{caseId}:{playerId}
Value: { locationId: "uuid", arrivedAt: "ISO timestamp" }
TTL:   none (cleared on case close)
```

---

## 8. Dependencies

### External services

| Service | Used for | Notes |
|---------|---------|-------|
| PostgreSQL + PostGIS | Location storage + geospatial distance queries | PostGIS extension must be enabled |
| Redis | Real-time player position cache | |

---

## 9. Open questions

| # | Question | Owner | Status |
|---|----------|-------|--------|
| 1 | What is the average travel speed constant? (Walk? Drive? Mixed?) | TBD | Open |
| 2 | Are location coordinates real-world or fictional? If fictional, how is the town map generated? | TBD | Open |
| 3 | Can new locations be added during a game session (e.g. a player discovers a hidden location)? | TBD | Open |
| 4 | Should the travel time API call Time & Points automatically, or does the client make two calls? | TBD | Open |

---

## 10. Risks and concerns

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| PostGIS not available in deployed PostgreSQL image | Low | High | Use `postgis/postgis` Docker image explicitly in Compose |
| Player position Redis key not cleaned up after case ends | Med | Low | Case Service calls Map Service on case close to clear position keys |

---

## 11. Acceptance criteria

- [ ] `GET /travel-time?from=A&to=B` returns a positive integer in minutes
- [ ] Returned `baseTravelMinutes` does not include peak-hour modifier
- [ ] `POST /player-location` updates the player's position; a subsequent `GET /player-location/{id}` returns the new location
- [ ] `GET /players-at-location/{id}` returns all players who have their current position set to that location for the given case

---

## 12. Out of scope for v1

- Route optimisation (shortest path through multiple locations)
- Real-time position broadcast (client polls)
- Traffic simulation beyond the fixed peak-hour rule
