# Police Database Service

## Description
The Police Database Service manages all law enforcement data in the Detective RPG application. It's responsible for:
- Storing suspect records, criminal history, and investigation data
- Managing coroner reports, security footage, and witness testimonies
- Providing a searchable database for detectives
- Authenticating police access to sensitive information

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET`  | `/suspects/{id}` | Retrieve suspect details |
| `GET`  | `/reports/{id}` | Retrieve a coroner report |
| `POST` | `/security-footage` | Store security footage metadata |
| `GET`  | `/criminal-records?query={term}` | Search criminal records |
| `GET`  | `/evidence/{id}` | Retrieve evidence details |

## Technical Stack
- Java 17
- Spring Boot
- Spring Data JPA
- Spring Cloud (for microservice integration)
- Maven
- PostgreSQL (for structured data)
- MongoDB (for unstructured data like reports)
- Elasticsearch (for full-text search capabilities)

## Setup and Running

### Prerequisites
- JDK 17+
- Maven
- Docker (optional, for containerization)
- PostgreSQL
- MongoDB
- Elasticsearch (optional, for advanced search)

### Running Locally
```bash
# Build the service
mvn clean install

# Run the service
java -jar target/police-db-service.jar
```

### Running with Docker
```bash
# Build the Docker image
docker build -t detective-rpg/police-db-service .

# Run the container
docker run -p 8085:8085 detective-rpg/police-db-service
```

## Integration with Other Services
- **Case Service**: For sharing case evidence and reports
- **Player Service**: For authenticating detective access
- **Map Service**: For associating evidence with locations
