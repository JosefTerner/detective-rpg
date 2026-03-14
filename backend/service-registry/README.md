# Service Registry (Eureka Server)

## Description
The Service Registry is a crucial infrastructure component in the Detective RPG application's microservice architecture. It's responsible for:
- Service discovery - allowing services to find and communicate with each other
- Load balancing - distributing traffic across multiple instances
- Fault tolerance - detecting service failures and rerouting traffic
- Dynamic scaling - supporting the addition and removal of service instances

## Features
- Self-registration of service instances
- Heartbeat mechanism for service health monitoring
- Service instance replication
- Dashboard UI for service status monitoring

## Technical Stack
- Java 17
- Spring Boot
- Spring Cloud Netflix Eureka Server
- Maven

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
java -jar target/service-registry.jar
```

### Running with Docker
```bash
# Build the Docker image
docker build -t detective-rpg/service-registry .

# Run the container
docker run -p 8761:8761 detective-rpg/service-registry
```

## Client Services
The following services register with this Service Registry:
- Case Service
- Player Service
- Time & Points Service
- Map Service
- Police Database Service
- API Gateway

## Dashboard
The Eureka dashboard is available at:
```
http://localhost:8761
```

This provides a visual overview of all registered services and their health status.
