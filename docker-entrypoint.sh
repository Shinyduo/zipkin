#!/bin/sh
set -e

# Only run schema load if using MySQL storage
if [ "$STORAGE_TYPE" = "mysql" ]; then
  echo "==> Ensuring Zipkin MySQL schema exists in DB: $MYSQL_DB"

  mysql -h "$MYSQL_HOST" -P "$MYSQL_TCP_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" -e "SELECT 1;" >/dev/null 2>&1 || {
    echo "Database $MYSQL_DB not found, creating..."
    mysql -h "$MYSQL_HOST" -P "$MYSQL_TCP_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" -e "CREATE DATABASE IF NOT EXISTS $MYSQL_DB;"
  }

  echo "==> Applying schema..."
  curl -sSL https://raw.githubusercontent.com/openzipkin/zipkin/develop/storage/mysql-v1/mysql.sql \
    | mysql -h "$MYSQL_HOST" -P "$MYSQL_TCP_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" || true
fi

echo "==> Starting Zipkin..."
exec java ${JAVA_OPTS} -jar /zipkin.jar
