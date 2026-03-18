# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Detective RPG is a multiplayer card-based role-playing game (4-20 players) set in a small town. A detective investigates crimes by gathering evidence, interrogating suspects, and making deductions. The game tracks time, travel, and scoring.

## Architecture

Microservices backend with a React SPA frontend. All client traffic flows through the API Gateway, and services discover each other via Eureka Service Registry.

### Backend Services (Java 21 / Spring Boot 3.4.3 / Spring Cloud 2024.0.1 / Maven)

| Service | Port | Responsibility | Databases |
|---------|------|---------------|-----------|
| API Gateway | 8080 | Routing, JWT auth, rate limiting (Redis) | - |
| Service Registry | 8761 | Eureka service discovery | - |
| Case Service | 8081 | Crime cases, evidence, witness testimonies, accusations | PostgreSQL |
| Player Service | 8082 | Player profiles, roles, detective-case assignments | PostgreSQL |
| Time & Points Service | 8083 | In-game time, travel delays, scoring | PostgreSQL, Redis |
| Map Service | 8084 | Locations, travel times, player tracking | PostgreSQL (PostGIS), Redis |
| Police DB Service | 8085 | Suspect records, coroner reports, footage, full-text search | PostgreSQL, MongoDB, Elasticsearch |

**API Gateway routing:** `/cases/**` → Case Service, `/players/**` → Player Service, `/time/**` → Time & Points, `/locations/**` → Map Service, `/police/**` → Police DB Service.

### Frontend (React 18 / TypeScript / Redux)

Located in `frontend/detective-rpg-ui/`. Uses Leaflet for the interactive town map, Styled Components for styling, Axios for API calls. Connects to backend via `REACT_APP_API_URL` (defaults to `http://localhost:8080`).

## Build & Run Commands

### Backend

```bash
# Run all services via Docker Compose
cd backend && docker-compose up --build

# Build individual service
cd backend/<service-name> && mvn clean install

# Run individual service
java -jar target/<service-name>.jar
```

### Frontend

```bash
cd frontend/detective-rpg-ui
npm install
npm start          # Dev server
npm run build      # Production build
npm run serve      # Serve production build
```

### Testing

```bash
# Backend (per service)
cd backend/<service-name> && mvn test

# Frontend
cd frontend/detective-rpg-ui
npm test           # Unit tests (Jest + React Testing Library)
npm run e2e        # End-to-end tests
```

## Project Status

This project is in early scaffold stage. The pom.xml files, Dockerfiles, and docker-compose.yml are populated with Java 21 / Spring Boot 3.4.3 / Spring Cloud 2024.0.1 configuration. Java sources and application properties files are still empty placeholders.
