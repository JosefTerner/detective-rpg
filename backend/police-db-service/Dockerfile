# Build stage — context must be the backend/ root directory
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /workspace

COPY pom.xml ./pom.xml
COPY police-db-service/pom.xml police-db-service/pom.xml
COPY police-db-service/src police-db-service/src

RUN --mount=type=cache,target=/root/.m2 \
    mvn -pl police-db-service -am clean package -DskipTests -q

FROM eclipse-temurin:21-jre-alpine
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app

COPY --from=build /workspace/police-db-service/target/*.jar app.jar

USER app
EXPOSE 8085
ENTRYPOINT ["java", "-jar", "app.jar"]
