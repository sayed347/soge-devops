# --- Build stage ---
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /build
COPY pom.xml .
RUN mvn -B dependency:go-offline
COPY src ./src
RUN mvn -B -DskipTests package

# --- Run stage ---
FROM eclipse-temurin:21-jre-alpine
RUN apk add --no-cache python3 py3-pip \
    && pip install --no-cache-dir --break-system-packages awscli \
    && addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=build /build/target/payment-orders.jar app.jar
COPY docker/setup.sh ./setup.sh
RUN mkdir -p /app/config && chmod +x ./setup.sh && chown -R app:app /app
USER app

EXPOSE 8081
HEALTHCHECK --interval=15s --timeout=3s --start-period=30s --retries=3 \
    CMD wget -q --spider http://localhost:8081/actuator/health || exit 1

ENTRYPOINT ["./setup.sh"]
