#!/usr/bin/env bash
set -euo pipefail
readonly APP_DIR=/opt/pullit/backend
readonly COMPOSE_FILE="$APP_DIR/docker-compose.prod.yml"
readonly ENV_FILE="$APP_DIR/pullit-production.env"
if [[ ! -r "$ENV_FILE" || ! -r "$COMPOSE_FILE" ]]; then
  echo "검증된 Pull-it Pi runtime contract가 없습니다." >&2
  exit 1
fi
cd "$APP_DIR"
chmod 600 "$ENV_FILE"
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" config --quiet
backend_image="$(sed -n 's/^PULLIT_BACKEND_IMAGE=//p' "$ENV_FILE" | tail -n 1)"
if [ -z "$backend_image" ]; then
  echo "PULLIT_BACKEND_IMAGE가 비어 있습니다." >&2
  exit 1
fi
if ! docker image inspect "$backend_image" >/dev/null 2>&1; then
  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" pull pullit-prod-app pullit-prod-worker
fi
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d pullit-prod-db pullit-prod-redis pullit-prod-rabbitmq pullit-prod-storage
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up --no-recreate pullit-prod-storage-init
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d --no-deps pullit-prod-app pullit-prod-worker
for attempt in {1..45}; do
  if docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" exec -T pullit-prod-app wget --quiet --spider http://localhost:8080/actuator/health \
    && [ "$(docker inspect --format '{{.State.Health.Status}}' pullit-prod-worker 2>/dev/null || true)" = healthy ]; then
    echo "Pull-it backend and worker health checks passed."
    exit 0
  fi
  sleep 2
done
echo "Pull-it backend health check failed; named volumes were preserved." >&2
exit 1
