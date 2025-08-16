# Use the official Zipkin image
FROM openzipkin/zipkin:latest

# Zipkin listens on 9411 by default
EXPOSE 9411

# No extra CMD needed; the base image starts Zipkin
# Environment options can be injected via Railway variables at deploy time.
