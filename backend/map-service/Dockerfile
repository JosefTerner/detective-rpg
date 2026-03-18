# Build stage — context must be the backend/ root directory
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /workspace

COPY pom.xml ./pom.xml
COPY map-service/pom.xml map-service/pom.xml
COPY map-service/src map-service/src

RUN --mount=type=cache,target=/root/.m2 \
    mvn -pl map-service -am clean package -DskipTests -q

FROM eclipse-temurin:21-jre-alpine
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app

COPY --from=build /workspace/map-service/target/*.jar app.jar

USER app
EXPOSE 8084
ENTRYPOINT ["java", "-jar", "app.jar"]
