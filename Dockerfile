# Beide Stages nutzen dasselbe Tag: Der AOT-Cache verlangt exakt denselben JVM-Build.
ARG UBI_TAG=latest

# ============================
# 1. Build Stage
# ============================
FROM registry.access.redhat.com/ubi10/openjdk-25:${UBI_TAG} AS build

USER root
RUN mkdir /build /app && chown 185:0 /build /app
USER 185
WORKDIR /build

# Erst nur die pom.xml: Der Dependency-Layer bleibt gecacht, solange sich nur der Code ändert.
COPY pom.xml .
RUN --mount=type=cache,target=/home/default/.m2,uid=185 mvn -q dependency:go-offline

COPY src ./src
# Kein spring-boot:process-aot: Mit Spring Cloud Bootstrap erfasst Spring AOT nur den
# Bootstrap-Kontext, der PropertyGenerator fehlt dann zur Laufzeit.
RUN --mount=type=cache,target=/home/default/.m2,uid=185 \
    mvn -q -Dmaven.test.skip=true package

# Thin-JAR: application/app.jar verweist per Class-Path auf lib/*.jar.
RUN JAR=$(ls target/*.jar | grep -v original) && \
    java -Djarmode=tools -jar "$JAR" extract --layers --application-filename app.jar --destination extracted

WORKDIR /app
RUN for layer in dependencies spring-boot-loader snapshot-dependencies application; do \
      [ -d /build/extracted/$layer ] && cp -a /build/extracted/$layer/. /app/; \
    done

# JDK-AOT-Cache trainieren: kompletter Lauf ohne Config-Server, die ConfigMap landet in /tmp.
# GC- und Header-Flags müssen wortgleich im ENTRYPOINT stehen.
RUN java -XX:AOTCacheOutput=/app/app.aot \
         -XX:+UseSerialGC -XX:+UseCompactObjectHeaders \
         -Dspring.cloud.config.enabled=false -Dspring.application.name=aot-training \
         -DCONFIGMAP_FILE_TO_WRITE=/tmp/aot-training.yaml \
         -jar /app/app.jar

# ============================
# 2. Runtime Stage
# ============================
FROM registry.access.redhat.com/ubi10/openjdk-25-runtime:${UBI_TAG}

LABEL org.opencontainers.image.title="cloudconfigpropertygenerator" \
      org.opencontainers.image.description="Generates a Kubernetes ConfigMap from Spring Cloud Config Server profiles" \
      org.opencontainers.image.version="0.0.1-SNAPSHOT" \
      org.opencontainers.image.vendor="wlanboy" \
      org.opencontainers.image.source="https://github.com/wlanboy/CloudConfigPropertyGenerator" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.base.name="registry.access.redhat.com/ubi10/openjdk-25-runtime"

USER 185
WORKDIR /app

# Seltenste Änderung zuerst.
COPY --from=build --chown=185:185 /build/extracted/dependencies/ ./
COPY --from=build --chown=185:185 /build/extracted/spring-boot-loader/ ./
COPY --from=build --chown=185:185 /build/extracted/snapshot-dependencies/ ./
COPY --from=build --chown=185:185 /build/extracted/application/ ./
COPY --from=build --chown=185:185 /app/app.aot ./app.aot

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
