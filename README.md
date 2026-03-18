# Detective RPG

> A multiplayer card-based mystery game (4–20 players) — players investigate crimes in real time through a React UI backed by seven Spring Boot microservices.

[![Build](https://img.shields.io/badge/build-in%20progress-yellow)]()
[![Java](https://img.shields.io/badge/Java-21-blue)]()
[![React](https://img.shields.io/badge/React-18-blue)]()

---

## Table of contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick start](#quick-start)
- [Configuration](#configuration)
- [Running tests](#running-tests)
- [Deployment](#deployment)
- [Key modules](#key-modules)
- [API reference](#api-reference)
- [Contributing](#contributing)

---

## Overview

Detective RPG is a real-time multiplayer mystery game for 4–20 players. One player acts as the detective and investigates a crime by gathering evidence, interrogating suspects, and reconstructing a timeline — all enforced by in-game time, travel delays, and a scoring engine. The rest of the players take supporting or opposing roles with their own win conditions.

The backend is a set of seven Spring Boot microservices behind a single API Gateway. The frontend is a React SPA with an interactive town map.

→ Game rules and mechanics: [`docs/game-rules.md`](docs/game-rules.md)
→ Example game session with API calls: [`docs/example-game-session.md`](docs/example-game-session.md)

---

## Architecture

```
[Browser / React UI :3000]
          │  HTTPS
          ▼
   [API Gateway :8080]  ← JWT auth, rate limiting (Redis)
    │     │     │    │      │
    ▼     ▼     ▼    ▼      ▼
 [Case] [Player] [Time] [Map] [PoliceDB]
 :8081   :8082   :8083  :8084  :8085

All services register with [Service Registry :8761] (Eureka)
```

→ Full C4 architecture: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
→ Service specs: [`docs/specs/`](docs/specs/)

---

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| JDK | 21+     | |
| Maven | 3.8+    | |
| Node.js | 16+     | Frontend only |
| Docker | 24+     | Required for full-stack startup |
| Docker Compose | 2+      | |

---

## Quick start

```bash
# 1. Clone
git clone <repo-url>
cd detective-rpg

# 2. Start all backend services
cd backend && docker-compose up --build

# 3. Start the frontend (separate terminal)
cd frontend/detective-rpg-ui
npm install
npm start

# App:              http://localhost:3000
# API Gateway:      http://localhost:8080
# Eureka Dashboard: http://localhost:8761
```

---

## Configuration

### Required environment variables

| Variable | Description | Example |
|----------|-------------|---------|
| `POSTGRES_URL` | PostgreSQL JDBC connection string | `jdbc:postgresql://localhost:5432/detectiverpg` |
| `POSTGRES_USER` | DB username | `detective` |
| `POSTGRES_PASSWORD` | DB password | *secret* |
| `REDIS_HOST` | Redis hostname | `localhost` |
| `JWT_SECRET` | Secret used to sign JWT tokens | *secret* |
| `MONGODB_URI` | MongoDB connection string (Police DB) | `mongodb://localhost:27017/policedb` |

### Optional variables

| Variable | Default | Description |
|----------|---------|-------------|
| `REACT_APP_API_URL` | `http://localhost:8080` | Backend API base URL for the UI |
| `EUREKA_HOST` | `localhost` | Service registry hostname |
| `ELASTICSEARCH_HOST` | `localhost:9200` | Elasticsearch for Police DB full-text search |

---

## Running tests

```bash
# Backend — per service
cd backend/<service-name> && mvn test

# Frontend — unit tests
cd frontend/detective-rpg-ui && npm test

# Frontend — end-to-end
cd frontend/detective-rpg-ui && npm run e2e
```

Integration tests require Docker (PostgreSQL, MongoDB, Redis via Testcontainers).

---

## Deployment

### Docker Compose (full stack)

```bash
cd backend && docker-compose up --build
```

### Individual service

```bash
cd backend/<service-name>
mvn clean install
java -jar target/<service-name>.jar
```

---

## Key modules

| Module | Path | Responsibility |
|--------|------|----------------|
| API Gateway | `backend/api-gateway/` | Routing, JWT auth, rate limiting |
| Service Registry | `backend/service-registry/` | Eureka service discovery |
| Case Service | `backend/case-service/` | Crime cases, evidence, verdicts |
| Player Service | `backend/player-service/` | Player profiles, roles, assignments |
| Time & Points | `backend/time-points-service/` | In-game time, travel delays, scoring |
| Map Service | `backend/map-service/` | Locations, travel times, player tracking |
| Police DB | `backend/police-db-service/` | Suspect records, forensics, full-text search |
| Detective RPG UI | `frontend/detective-rpg-ui/` | React SPA — game interface |

→ Each service has a spec in [`docs/specs/`](docs/specs/).

---

## API reference

All endpoints are accessed through the API Gateway at `http://localhost:8080`:

| Prefix | Routes to |
|--------|-----------|
| `/cases/**` | Case Service |
| `/players/**` | Player Service |
| `/time/**` | Time & Points Service |
| `/locations/**` | Map Service |
| `/police/**` | Police DB Service |

Swagger UI: *coming once services are implemented.*

---

## Contributing

1. Branch naming: `feat/{ticket}-description` or `fix/{ticket}-description`
2. Write or update tests for all changed behaviour
3. Update the relevant spec in `docs/specs/` if design changes
4. Graduate a spec to `docs/modules/` once the service is fully implemented
5. For architectural changes, write an [ADR](docs/adr/) first
6. Update [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) if the container or component diagram changes

---

## Useful links

| Resource | Path |
|----------|------|
| Game rules | [docs/game-rules.md](docs/game-rules.md) |
| Architecture doc | [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) |
| Javadoc conventions | [docs/JAVADOC_CONVENTIONS.md](docs/JAVADOC_CONVENTIONS.md) |
| ADR log | [docs/adr/](docs/adr/) |
| Service specs | [docs/specs/](docs/specs/) |
| Module docs | [docs/modules/](docs/modules/) |
| Example game session | [docs/example-game-session.md](docs/example-game-session.md) |
