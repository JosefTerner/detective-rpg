#!/usr/bin/env bash
# Detective RPG — deployment helper
# Usage:
#   ./scripts/deploy.sh [up|down|restart|logs|status|build]
#   Default action: up

set -euo pipefail

COMPOSE_DIR="$(cd "$(dirname "$0")/../backend" && pwd)"
COMPOSE_FILE="$COMPOSE_DIR/docker-compose.yml"

ACTION="${1:-up}"

case "$ACTION" in
  up)
    echo "==> Building and starting all services..."
    docker compose -f "$COMPOSE_FILE" up --build -d
    echo "==> Services started. Eureka dashboard: http://localhost:8761"
    echo "    API Gateway:                         http://localhost:8080"
    ;;
  down)
    echo "==> Stopping and removing containers..."
    docker compose -f "$COMPOSE_FILE" down
    ;;
  restart)
    echo "==> Restarting all services..."
    docker compose -f "$COMPOSE_FILE" down
    docker compose -f "$COMPOSE_FILE" up --build -d
    ;;
  logs)
    SERVICE="${2:-}"
    if [ -n "$SERVICE" ]; then
      docker compose -f "$COMPOSE_FILE" logs -f "$SERVICE"
    else
      docker compose -f "$COMPOSE_FILE" logs -f
    fi
    ;;
  status)
    docker compose -f "$COMPOSE_FILE" ps
    ;;
  build)
    echo "==> Building all service images..."
    docker compose -f "$COMPOSE_FILE" build
    ;;
  *)
    echo "Unknown action: $ACTION"
    echo "Usage: $0 [up|down|restart|logs [service]|status|build]"
    exit 1
    ;;
esac
