FROM maven:4.0.0-rc-5-eclipse-temurin-21-alpine AS deps
WORKDIR /src
COPY pom.xml .
RUN --mount=type=bind,source=pom.xml,target=pom.xml \
    --mount=type=cache,target=/root/.m2 mvn dependency:go-offline -DskipTests


FROM deps AS build
WORKDIR /src
COPY . .
RUN --mount=type=cache,target=/root/.m2 mvn package -DskipTests

FROM eclipse-temurin:21-jre-alpine AS final

COPY ./target/app.jar app.jar

EXPOSE 8080

ENTRYPOINT [ "java", "-jar", "/app.jar" ]