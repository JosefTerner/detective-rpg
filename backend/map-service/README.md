# Map Service

## Description
The Map Service manages the town's locations and geography in the Detective RPG application. It's responsible for:
- Managing all locations, including crime scenes and suspect residences
- Determining travel time based on distance and traffic conditions
- Tracking player locations in real-time
- Providing a navigable map interface for the game world

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET`  | `/locations` | Retrieve a list of all locations |
| `GET`  | `/travel-time?from={A}&to={B}` | Calculate estimated travel time |
| `POST` | `/player-location` | Update a player's location |

## Technical Stack
- Java 17
- Spring Boot
- Spring Data JPA
- Spring Cloud (for microservice integration)
- Maven
- PostgreSQL with PostGIS extension (for geospatial data)
- Redis (for real-time location tracking)

## Setup and Running

### Prerequisites
- JDK 17+
- Maven
- Docker (optional, for containerization)
- PostgreSQL with PostGIS extension

### Running Locally
```bash
# Build the service
mvn clean install

# Run the service
java -jar target/map-service.jar
```

### Running with Docker
```bash
# Build the Docker image
docker build -t detective-rpg/map-service .

# Run the container
docker run -p 8084:8084 detective-rpg/map-service
```

## Integration with Other Services
- **Player Service**: For associating players with locations
- **Time & Points Service**: For calculating travel times and delays
- **Case Service**: For identifying crime scene locations
