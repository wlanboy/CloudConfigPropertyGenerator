# AOT-Training und Runtime nutzen dasselbe Image: Der AOT-Cache verlangt exakt denselben JVM-Build.
ARG TEMURIN_TAG=25-jre

# ============================
# 1. Build Stage
# ============================
FROM maven:3-eclipse-temurin-25 AS build

WORKDIR /build

# Erst nur die pom.xml: Der Dependency-Layer bleibt gecacht, solange sich nur der Code ändert.
COPY pom.xml .
RUN --mount=type=cache,target=/root/.m2 mvn -q dependency:go-offline

COPY src ./src
# Kein spring-boot:process-aot: Mit Spring Cloud Bootstrap erfasst Spring AOT nur den
# Bootstrap-Kontext, der PropertyGenerator fehlt dann zur Laufzeit.
RUN --mount=type=cache,target=/root/.m2 \
    mvn -q -Dmaven.test.skip=true package

# Thin-JAR: application/app.jar verweist per Class-Path auf lib/*.jar.
RUN JAR=$(ls target/*.jar | grep -v original) && \
    java -Djarmode=tools -jar "$JAR" extract --layers --application-filename app.jar --destination extracted

# ============================
# 2. AOT-Training (gleiches Image wie die Runtime)
# ============================
FROM eclipse-temurin:${TEMURIN_TAG} AS aot

WORKDIR /app
# Gleiche Reihenfolge und Quellen wie in der Runtime-Stage, damit Pfade, Größen und mtimes übereinstimmen.
COPY --from=build /build/extracted/dependencies/ ./
COPY --from=build /build/extracted/spring-boot-loader/ ./
COPY --from=build /build/extracted/snapshot-dependencies/ ./
COPY --from=build /build/extracted/application/ ./

# JDK-AOT-Cache trainieren: kompletter Lauf ohne Config-Server, die ConfigMap landet in /tmp.
# GC- und Header-Flags müssen wortgleich im ENTRYPOINT stehen.
RUN java -XX:AOTCacheOutput=/app/app.aot \
         -XX:+UseSerialGC -XX:+UseCompactObjectHeaders \
         -Dspring.cloud.config.enabled=false -Dspring.application.name=aot-training \
         -DCONFIGMAP_FILE_TO_WRITE=/tmp/aot-training.yaml \
         -jar /app/app.jar

# ============================
# 3. Runtime Stage
# ============================
FROM eclipse-temurin:${TEMURIN_TAG}

LABEL org.opencontainers.image.title="cloudconfigpropertygenerator" \
      org.opencontainers.image.description="Generates a Kubernetes ConfigMap from Spring Cloud Config Server profiles" \
      org.opencontainers.image.version="0.0.1-SNAPSHOT" \
      org.opencontainers.image.vendor="wlanboy" \
      org.opencontainers.image.source="https://github.com/wlanboy/CloudConfigPropertyGenerator" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.base.name="docker.io/library/eclipse-temurin:25-jre"

# Das Temurin-Image kennt UID 185 nicht; GID 0 wie bei UBI, damit OpenShift-UIDs schreiben können.
USER 185:0
WORKDIR /app

# Seltenste Änderung zuerst.
COPY --from=build --chown=185:185 /build/extracted/dependencies/ ./
COPY --from=build --chown=185:185 /build/extracted/spring-boot-loader/ ./
COPY --from=build --chown=185:185 /build/extracted/snapshot-dependencies/ ./
COPY --from=build --chown=185:185 /build/extracted/application/ ./
COPY --from=aot --chown=185:185 /app/app.aot ./app.aot

# Spring lädt ./config/application.properties relativ zum WORKDIR automatisch.
COPY --chown=185:0 application.properties /app/config/application.properties

ENV JAVA_TOOL_OPTIONS="-Xms64m -Xmx192m -Xss512k \
  -XX:MaxMetaspaceSize=64m -XX:ReservedCodeCacheSize=48m -XX:TieredStopAtLevel=1 \
  -XX:ActiveProcessorCount=2 -XX:+ExitOnOutOfMemoryError"

ENTRYPOINT ["java", \
  "-XX:AOTCache=/app/app.aot", \
  "-XX:+UseSerialGC", \
  "-XX:+UseCompactObjectHeaders", \
  "-jar", "/app/app.jar"]
