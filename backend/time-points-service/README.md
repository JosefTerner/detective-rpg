# Time & Points Service

## Description
The Time & Points Service manages the in-game time and point system in the Detective RPG application. It's responsible for:
- Tracking in-game time for detective actions
- Enforcing travel time delays based on traffic conditions
- Calculating and updating player scores based on performance
- Managing the game's time progression and synchronization

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/time/start` | Start tracking time for an action |
| `POST` | `/time/end` | Stop tracking time for an action |
| `GET`  | `/time/status` | Retrieve the current game time |
| `POST` | `/points/update` | Update a player's score |

## Technical Stack
- Java 17
- Spring Boot
- Spring Data JPA
- Spring Cloud (for microservice integration)
- Maven
- Redis (for time-based operations)
- PostgreSQL (for data persistence)

## Setup and Running

### Prerequisites
- JDK 17+
- Maven
- Docker (optional, for containerization)
- Redis

### Running Locally
```bash
# Build the service
mvn clean install

# Run the service
java -jar target/time-points-service.jar
```

### Running with Docker
```bash
# Build the Docker image
docker build -t detective-rpg/time-points-service .

# Run the container
docker run -p 8083:8083 detective-rpg/time-points-service
```

## Integration with Other Services
- **Player Service**: For updating player scores and tracking activity time
- **Map Service**: For calculating travel times between locations
- **Case Service**: For tracking investigation time constraints
