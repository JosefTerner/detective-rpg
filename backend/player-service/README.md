# Player Service

## Description
The Player Service manages player profiles and roles in the Detective RPG application. It's responsible for:
- Managing player profiles (detectives, witnesses, suspects)
- Tracking player interactions (interrogations, movements)
- Assigning detectives to cases
- Recording player actions within the game

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/players` | Register a new player |
| `GET`  | `/players/{id}` | Retrieve player details |
| `POST` | `/players/{id}/assign-role` | Assign a role to a player |
| `POST` | `/players/{id}/action` | Log a player's in-game action |

## Technical Stack
- Java 17
- Spring Boot
- Spring Data JPA
- Spring Cloud (for microservice integration)
- Maven
- PostgreSQL (for data persistence)

## Setup and Running

### Prerequisites
- JDK 17+
- Maven
- Docker (optional, for containerization)

### Running Locally
```bash
# Build the service
mvn clean install

# Run the service
java -jar target/player-service.jar
```

### Running with Docker
```bash
# Build the Docker image
docker build -t detective-rpg/player-service .

# Run the container
docker run -p 8082:8082 detective-rpg/player-service
```

## Integration with Other Services
- **Case Service**: For case assignment and investigation records
- **Map Service**: For tracking player locations
- **Time & Points Service**: For recording activity time and awarding points
