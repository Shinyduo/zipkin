#!/bin/sh
set -e

echo "ZIPKIN_LOG_LEVEL=${ZIPKIN_LOG_LEVEL:-INFO}"
echo "STORAGE_TYPE=${STORAGE_TYPE:-mem}"

if [ "$STORAGE_TYPE" = "mysql" ]; then
  : "${MYSQL_HOST:?MYSQL_HOST is required}"
  : "${MYSQL_TCP_PORT:?MYSQL_TCP_PORT is required}"
  : "${MYSQL_DB:?MYSQL_DB is required}"
  : "${MYSQL_USER:?MYSQL_USER is required}"
  : "${MYSQL_PASS:?MYSQL_PASS is required}"

  echo "==> Checking MySQL availability at $MYSQL_HOST:$MYSQL_TCP_PORT ..."
  tries=30
  until mariadb-admin ping -h "$MYSQL_HOST" -P "$MYSQL_TCP_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" --silent || [ $tries -le 0 ]; do
    tries=$((tries-1))
    echo "   waiting for MySQL... ($tries)"
    sleep 2
  done

  echo "==> Ensuring database '$MYSQL_DB' exists ..."
  mariadb -h "$MYSQL_HOST" -P "$MYSQL_TCP_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" \
    -e "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DB\`;"

  echo "==> Applying Zipkin schema (idempotent) ..."
  curl -sSL https://raw.githubusercontent.com/openzipkin/zipkin/develop/storage/mysql-v1/mysql.sql \
    | mariadb -h "$MYSQL_HOST" -P "$MYSQL_TCP_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" || true
fi

echo "==> Starting Zipkin ..."
exec java ${JAVA_OPTS} -Dzipkin.logging.level=${ZIPKIN_LOG_LEVEL:-INFO} -jar /zipkin.jar
