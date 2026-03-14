# Detective RPG Backend

This directory contains all the microservices that power the Detective RPG game.

## Microservices Architecture

The backend is composed of the following microservices:

### Core Game Services
- **Case Service** (`case-service/`): Manages crime cases and investigations
- **Player Service** (`player-service/`): Handles player profiles and roles
- **Time & Points Service** (`time-points-service/`): Tracks game time and player scores
- **Map Service** (`map-service/`): Manages locations and travel
- **Police DB Service** (`police-db-service/`): Provides access to police records and evidence

### Infrastructure Services
- **API Gateway** (`api-gateway/`): Routes client requests to appropriate services
- **Service Registry** (`service-registry/`): Enables service discovery

## Technology Stack
- Java 17
- Spring Boot
- Spring Cloud (Netflix Eureka, Gateway)
- Maven
- Docker and Docker Compose
- Various databases (PostgreSQL, MongoDB, Redis)

## Getting Started

### Prerequisites
- JDK 17+
- Maven
- Docker and Docker Compose

### Running with Docker Compose
The easiest way to run all services is with Docker Compose:

```bash
# Build and start all services
docker-compose up --build
```

### Running Individual Services
See the README.md in each service directory for instructions on running services individually.

## Service Ports

| Service | Port |
|---------|------|
| API Gateway | 8080 |
| Service Registry | 8761 |
| Case Service | 8081 |
| Player Service | 8082 |
| Time & Points Service | 8083 |
| Map Service | 8084 |
| Police DB Service | 8085 |

## Development Workflow
1. Make changes to a service
2. Build and test locally
3. Rebuild with Docker Compose to test integration with other services

## API Documentation
Each service has its own API documentation in its respective README.md file.

## Monitoring
Service health and metrics can be accessed via Spring Boot Actuator endpoints.
