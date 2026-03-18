# Build stage — context must be the backend/ root directory
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /workspace

COPY pom.xml ./pom.xml
COPY time-points-service/pom.xml time-points-service/pom.xml
COPY time-points-service/src time-points-service/src

RUN --mount=type=cache,target=/root/.m2 \
    mvn -pl time-points-service -am clean package -DskipTests -q

FROM eclipse-temurin:21-jre-alpine
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app

COPY --from=build /workspace/time-points-service/target/*.jar app.jar

USER app
EXPOSE 8083
ENTRYPOINT ["java", "-jar", "app.jar"]
