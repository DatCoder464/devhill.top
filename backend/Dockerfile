FROM ubuntu:latest
LABEL authors="dacodia"
WORKDIR /src
COPY . .
RUN ./mvnw clean package -DskipTests

FROM eclipse-temurin:21-jre-alpine
WORKDIR /src
COPY --from=build /target/*.jar app.jar
EXPOSE 8080

ENTRYPOINT ["java", "-jar","app.jar"]