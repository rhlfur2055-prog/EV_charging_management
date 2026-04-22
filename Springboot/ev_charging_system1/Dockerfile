FROM eclipse-temurin:17-jdk-alpine AS build
WORKDIR /app
COPY . .
RUN chmod +x gradlew && ./gradlew clean build -x test --no-daemon

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=build /app/build/libs/*.jar app.jar

# Render free 512MB 친화 JVM
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75 -XX:+UseSerialGC -XX:+ExitOnOutOfMemoryError"

EXPOSE 8080

# Render 가 주입하는 $PORT 와 PG* envs 로 런타임에 server.port + JDBC URL 조립
ENTRYPOINT ["sh","-c","exec java -jar app.jar \
  --server.port=${PORT:-8080} \
  --spring.datasource.url=jdbc:postgresql://${PGHOST}:${PGPORT}/${PGDATABASE} \
  --spring.datasource.username=${PGUSER} \
  --spring.datasource.password=${PGPASSWORD}"]
