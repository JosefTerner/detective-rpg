# API Gateway

## Description
The API Gateway serves as the single entry point for all client requests in the Detective RPG application. It's responsible for:
- Routing requests to the appropriate microservices
- Handling authentication and authorization
- Load balancing across service instances
- Request logging and monitoring
- Rate limiting and circuit breaking

## Routing Configuration

| Route Pattern | Destination Service |
|---------------|---------------------|
| `/cases/**` | Case Service |
| `/players/**` | Player Service |
| `/time/**` | Time & Points Service |
| `/locations/**` | Map Service |
| `/police/**` | Police Database Service |

## Technical Stack
- Java 17
- Spring Boot
- Spring Cloud Gateway
- Spring Security
- Spring Cloud Netflix (Eureka Client)
- Maven
- Redis (for rate limiting)

## Setup and Running

### Prerequisites
- JDK 17+
- Maven
- Docker (optional, for containerization)
- Service Registry running

### Running Locally
```bash
# Build the service
mvn clean install

# Run the service
java -jar target/api-gateway.jar
```

### Running with Docker
```bash
# Build the Docker image
docker build -t detective-rpg/api-gateway .

# Run the container
docker run -p 8080:8080 detective-rpg/api-gateway
```

## Security Configuration
The API Gateway handles authentication using JWT tokens:
- All requests to protected endpoints require a valid JWT token
- JWT tokens are validated against the User Service
- Role-based access control is enforced for different API endpoints

## Monitoring
The gateway provides the following monitoring endpoints:
- `/actuator/health` - Service health information
- `/actuator/metrics` - Performance metrics
- `/actuator/routes` - Current route configuration
