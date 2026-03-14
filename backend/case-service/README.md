# Case Service

## Description
The Case Service manages crime cases and investigation progress in the Detective RPG application. It provides endpoints for:
- Storing and retrieving case information
- Managing collected evidence
- Recording witness testimonies
- Storing detective notes
- Submitting final accusations

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/cases` | Create a new case |
| `GET`  | `/cases/{id}` | Retrieve case details |
| `POST` | `/cases/{id}/evidence` | Add evidence to a case |
| `POST` | `/cases/{id}/testimonies` | Add a witness testimony |
| `POST` | `/cases/{id}/verdict` | Submit a final accusation |

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
java -jar target/case-service.jar
```

### Running with Docker
```bash
# Build the Docker image
docker build -t detective-rpg/case-service .

# Run the container
docker run -p 8081:8081 detective-rpg/case-service
```

## Integration with Other Services
- **Player Service**: For detective assignments and authorization
- **Police DB Service**: For accessing criminal records and evidence database
- **Time & Points Service**: For tracking investigation time
