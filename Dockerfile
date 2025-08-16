FROM openzipkin/zipkin:latest

# Install MySQL client
USER root
RUN apt-get update && apt-get install -y mysql-client curl && rm -rf /var/lib/apt/lists/*

# Script to init schema if needed, then run Zipkin
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

USER zipkin

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
