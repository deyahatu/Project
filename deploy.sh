#!/bin/bash
set -euo pipefail

APP="recommendation-app"
PORT="8081"
DB_CONT="${APP}-db-1"
WEB_CONT="${APP}-web-1"
DB_NAME="recommendations"
DB_TABLE="items"
DB_ROOT_PASS="rootpass"

echo "Jenkins"
whoami || true
hostname || true
uname -a || true
echo "WORKSPACE=${WORKSPACE:-$(pwd)}"
echo "PWD=$(pwd)"

cd "${WORKSPACE:-$(pwd)}"

echo "Repo files"
ls -la
test -f docker-compose.yml || { echo "docker-compose not found in workspace"; exit 1; }
test -f Dockerfile || { echo "Dockerfile not found in workspace"; exit 1; }

docker version
docker compose version

if ! docker ps --format '{{.Names}}' | grep -q "^${DB_CONT}$"; then
  echo "DB container not running — starting it"
  docker compose -p "$APP" up -d db
else
  echo "DB container already running — reusing (faster build)"
fi

echo "Building and recreating web only"
docker compose -p "$APP" up -d --build --no-deps --force-recreate web

echo "Containers status"
docker compose -p "$APP" ps

echo "Wait for MySQL"
for i in {1..60}; do
  if ! docker ps --format '{{.Names}}' | grep -q "^${DB_CONT}$"; then
    echo "DB container not running"
    sleep 2
    continue
  fi

  if docker exec "$DB_CONT" mysqladmin ping -h 127.0.0.1 -uroot -p"$DB_ROOT_PASS" --silent >/dev/null 2>&1; then
    echo "MySQL is ready"
    break
  fi

  sleep 2
  if [ "$i" -eq 60 ]; then
    echo "MySQL not ready in time"
    docker compose -p "$APP" logs --tail 200 db || true
    exit 1
  fi
done

DUMP_FILE="dumps/dump.sql"

if [ ! -f "$DUMP_FILE" ]; then
  echo "Dump file not found: $DUMP_FILE"
  exit 1
fi

echo "Importing dump: $DUMP_FILE (always, to keep DB seed in sync with repo)"
docker exec -i "$DB_CONT" mysql -uroot -p"$DB_ROOT_PASS" "$DB_NAME" < "$DUMP_FILE"
echo "Import done."

echo "Verifying table '$DB_TABLE' has rows"
ROW_COUNT=$(docker exec "$DB_CONT" mysql -uroot -p"$DB_ROOT_PASS" -N -B -e "USE $DB_NAME; SELECT COUNT(*) FROM $DB_TABLE;" 2>/dev/null || echo 0)
echo "Rows in $DB_TABLE: $ROW_COUNT"
if [ "$ROW_COUNT" -lt 1 ]; then
  echo "Import failed: no rows in $DB_TABLE"
  exit 1
fi

echo "Smoke test"
for i in {1..30}; do
  if curl -fsS "http://127.0.0.1:${PORT}/" >/dev/null; then
    echo "Web is UP"
    echo "Deployment completed"
    exit 0
  fi
  sleep 2
done

echo "Web did not become ready"
docker compose -p "$APP" ps || true
docker compose -p "$APP" logs --tail 200 || true
exit 1
