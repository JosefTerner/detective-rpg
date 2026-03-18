# Build stage — context must be the backend/ root directory
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /workspace

COPY pom.xml ./pom.xml
COPY player-service/pom.xml player-service/pom.xml
COPY player-service/src player-service/src

RUN --mount=type=cache,target=/root/.m2 \
    mvn -pl player-service -am clean package -DskipTests -q

FROM eclipse-temurin:21-jre-alpine
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app

COPY --from=build /workspace/player-service/target/*.jar app.jar

USER app
EXPOSE 8082
ENTRYPOINT ["java", "-jar", "app.jar"]
