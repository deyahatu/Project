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

docker compose -p "$APP" down --remove-orphans || true

docker compose -p "$APP" up -d --build

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

echo "Check if table '$DB_TABLE' exists"
if docker exec "$DB_CONT" mysql -uroot -p"$DB_ROOT_PASS" -e "USE $DB_NAME; SHOW TABLES LIKE '$DB_TABLE';" | grep -q "$DB_TABLE"; then
  echo "Table '$DB_TABLE' exists"
else
  echo "Table '$DB_TABLE' missing"
  if [ -f "$DUMP_FILE" ]; then
    echo "Importing dump: $DUMP_FILE"
    docker exec -i "$DB_CONT" mysql -uroot -p"$DB_ROOT_PASS" "$DB_NAME" < "$DUMP_FILE"
    echo "Import done."
  else
    echo "Dump file not found: $DUMP_FILE"
    exit 1
  fi
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
