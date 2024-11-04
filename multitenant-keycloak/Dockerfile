ARG APP_SOURCE_REPO=quay.io/keycloak/keycloak
ARG APP_VERSION=26.0.2
ARG MAVEN_IMAGE=3.9.9-eclipse-temurin-17-alpine

FROM maven:${MAVEN_IMAGE} AS dependency-builder
COPY dependencies/pom.xml pom.xml
RUN mvn dependency:copy-dependencies -DoutputDirectory=/tmp/dependencies

FROM ${APP_SOURCE_REPO}:${APP_VERSION} AS builder
COPY --from=dependency-builder /tmp/dependencies/* /opt/keycloak/providers/

WORKDIR /opt/keycloak

ENV KC_DB=mssql
ENV KC_TRANSACTION_XA_ENABLED=false
ENV KC_METRICS_ENABLED=true
ENV KC_HEALTH_ENABLED=true

COPY --chown=keycloak:keycloak --chmod=644 plugins/ /opt/keycloak/providers/
# COPY --chown=keycloak:keycloak --chmod=644 themes/ /opt/keycloak/themes/

RUN /opt/keycloak/bin/kc.sh build

FROM ${APP_SOURCE_REPO}:${APP_VERSION}
COPY --from=builder /opt/keycloak/ /opt/keycloak/

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]