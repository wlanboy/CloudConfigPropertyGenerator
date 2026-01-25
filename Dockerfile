# ============================
# 1. Build Stage (Java 25)
# ============================
FROM registry.access.redhat.com/ubi9/openjdk-25:latest AS build
# Eclipse Temurin bietet aktuelle Java-Versionen inkl. Java 25

WORKDIR /app

COPY pom.xml .
# → Nur die pom.xml wird kopiert, damit Maven bereits alle Dependencies auflösen kann,
#   ohne dass sich der Sourcecode ändert. Das verbessert das Layer-Caching.

RUN --mount=type=cache,target=/root/.m2 mvn -q -DskipTests dependency:go-offline
# → Lädt alle Maven-Dependencies vorab herunter.
# → --mount=type=cache sorgt dafür, dass das lokale Maven-Repository zwischen Builds gecached wird.

COPY src ./src
# → Jetzt erst der Sourcecode, damit Änderungen am Code nicht das Dependency-Layer invalidieren.

RUN --mount=type=cache,target=/root/.m2 mvn -q -DskipTests compile package
# → Baut das eigentliche JAR mit AOT (Ahead-of-Time) Processing.
# → compile: Kompiliert die Klassen (notwendig für process-aot).
# → package: Baut das finale JAR inkl. AOT-Klassen.
# → Wieder mit Maven-Cache, um Build-Zeit zu sparen.

RUN cp target/cloudconfigpropertygenerator-0.0.1-SNAPSHOT.jar app.jar && \
    java -Djarmode=tools -jar app.jar extract --layers --launcher --destination extracted
# → Spring Boot 4.x Layertools: --launcher ist erforderlich um den Loader zu extrahieren
# → Extrahierte Layer:
#     - dependencies (BOOT-INF/lib)
#     - spring-boot-loader (org/springframework/boot/loader/*)
#     - snapshot-dependencies
#     - application (BOOT-INF/classes)
# → Vorteil: Docker kann diese Layer getrennt cachen → schnellere Deployments.

# ============================
# 2. Runtime Stage (Java 25)
# ============================
FROM registry.access.redhat.com/ubi9/openjdk-25-runtime:latest

# OCI-konforme Labels
LABEL org.opencontainers.image.title="Cloud Config Generator" \
      org.opencontainers.image.description="Spring based generator to switch from Spring Cloud Config Server to Configmaps" \
      org.opencontainers.image.version="0.0.1-SNAPSHOT" \
      org.opencontainers.image.vendor="wlanboy" \
      org.opencontainers.image.source="CloudConfigPropertyGenerator" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.base.name="ubi9/openjdk-25-runtime"

WORKDIR /app

USER root
# → Temporär root, um Verzeichnisse anzulegen und Berechtigungen zu setzen.

RUN mkdir -p /app/config /app/data && \
    chown -R 185:0 /app && \
    chmod -R g+w /app
# → /app/config: für externe Konfigurationen
# → /app/data: für persistente Daten
# → Non-root User für sicheren Betrieb

USER 185
# → Zurück zum nicht-privilegierten User.

COPY --from=build --chown=185:185 /app/extracted/dependencies/ ./
# → Kopiert nur die Dependency-Layer. Ändern sich selten.

COPY --from=build --chown=185:185 /app/extracted/spring-boot-loader/ ./
# → Enthält den Spring Boot Launcher (Main-Class Loader). Ändern sich selten.

COPY --from=build --chown=185:185 /app/extracted/snapshot-dependencies/ ./
# → Snapshot-Dependencies (z. B. lokale libs), ändern sich häufiger.

COPY --from=build --chown=185:185 /app/extracted/application/ ./
# → Der eigentliche Applikationscode (Kompilat). Ändert sich.

COPY --chown=185:185 application.properties /app/config/application.properties
# → Externe Konfiguration ins Config-Verzeichnis für die Referenz für ENV Vars

COPY --chown=185:185 entrypoint.sh /app/entrypoint.sh
# → Custom Entrypoint für Java OPTS.

ENTRYPOINT ["/app/entrypoint.sh"]
# → Startet die App über das Entry-Skript.
# → Vorteil: Skript kann Umgebungsvariablen verarbeiten, ENTRYPOINT nicht.