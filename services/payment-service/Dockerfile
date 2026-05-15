FROM maven:3.9-eclipse-temurin-21 AS builder

WORKDIR /app

COPY pom.xml .
RUN mvn -q dependency:go-offline

COPY src ./src
RUN mvn -q package -DskipTests

FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

COPY --from=builder /app/target/quarkus-app/lib/ ./lib/
COPY --from=builder /app/target/quarkus-app/app/ ./app/
COPY --from=builder /app/target/quarkus-app/quarkus/ ./quarkus/
COPY --from=builder /app/target/quarkus-app/quarkus-run.jar ./quarkus-run.jar

EXPOSE 8007

ENTRYPOINT ["java", "-jar", "/app/quarkus-run.jar"]