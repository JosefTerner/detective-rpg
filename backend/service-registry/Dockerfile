# Build stage — context must be the backend/ root directory
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /workspace

COPY pom.xml ./pom.xml
COPY service-registry/pom.xml service-registry/pom.xml
COPY service-registry/src service-registry/src

RUN --mount=type=cache,target=/root/.m2 \
    mvn -pl service-registry -am clean package -DskipTests -q

FROM eclipse-temurin:21-jre-alpine
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app

COPY --from=build /workspace/service-registry/target/*.jar app.jar

USER app
EXPOSE 8761
ENTRYPOINT ["java", "-jar", "app.jar"]
