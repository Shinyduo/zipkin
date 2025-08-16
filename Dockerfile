# Small JRE base with apk
FROM eclipse-temurin:17-jre-alpine

# Install curl + MySQL client (mariadb-client works with MySQL)
RUN apk add --no-cache curl mariadb-client

# Zipkin version (change if you want)
ENV ZIPKIN_VERSION=3.5.1
# Download Zipkin server fat JAR
RUN curl -sSL -o /zipkin.jar \
  https://repo1.maven.org/maven2/io/zipkin/zipkin-server/${ZIPKIN_VERSION}/zipkin-server-${ZIPKIN_VERSION}-exec.jar

# Entry script to init schema (if STORAGE_TYPE=mysql) then start Zipkin
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 9411
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
