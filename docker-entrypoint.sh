#!/bin/sh
set -e

echo "ZIPKIN_LOG_LEVEL=${ZIPKIN_LOG_LEVEL:-INFO}"
echo "STORAGE_TYPE=${STORAGE_TYPE:-mem}"

mysql_flags="-h $MYSQL_HOST -P $MYSQL_TCP_PORT -u $MYSQL_USER -p$MYSQL_PASS --connect-timeout=3"
# Require SSL if env says so, or if using Railway proxy host
case "${MYSQL_SSL:-}" in
  required|REQUIRED|1|true|TRUE) mysql_flags="$mysql_flags --ssl";;
esac
case "$MYSQL_HOST" in
  *.proxy.rlwy.net) mysql_flags="$mysql_flags --ssl";;
esac

if [ "$STORAGE_TYPE" = "mysql" ]; then
  : "${MYSQL_HOST:?MYSQL_HOST is required}"
  : "${MYSQL_TCP_PORT:?MYSQL_TCP_PORT is required}"
  : "${MYSQL_DB:?MYSQL_DB is required}"
  : "${MYSQL_USER:?MYSQL_USER is required}"
  : "${MYSQL_PASS:?MYSQL_PASS is required}"

  echo "==> Target DB: ${MYSQL_HOST}:${MYSQL_TCP_PORT} (db=${MYSQL_DB}) SSL=$(echo "$mysql_flags" | grep -q -- '--ssl' && echo yes || echo no)"

  # quick TCP probe (optional)
  if command -v nc >/dev/null 2>&1; then
    if ! nc -z -w 2 "$MYSQL_HOST" "$MYSQL_TCP_PORT"; then
      echo "   TCP not open yet, waiting for MySQL..."
    fi
  fi

  tries=60
  until mariadb $mysql_flags -e "SELECT 1" >/dev/null 2>&1; do
    tries=$((tries-1))
    if [ $tries -le 0 ]; then
      echo "ERROR: MySQL unreachable at ${MYSQL_HOST}:${MYSQL_TCP_PORT}"
      exit 1
    fi
    echo "   waiting for MySQL... ($tries)"
    sleep 2
  done

  echo "==> Ensuring database '$MYSQL_DB' exists ..."
  mariadb $mysql_flags -e "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DB\`;"

  echo "==> Applying Zipkin schema (idempotent) ..."
  curl -sSL https://raw.githubusercontent.com/openzipkin/zipkin/develop/storage/mysql-v1/mysql.sql \
    | mariadb $mysql_flags "$MYSQL_DB" || true
fi

echo "==> Starting Zipkin ..."
exec java ${JAVA_OPTS} -Dzipkin.logging.level=${ZIPKIN_LOG_LEVEL:-INFO} -jar /zipkin.jar
