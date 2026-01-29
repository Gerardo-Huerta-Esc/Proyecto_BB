#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load .env if present (optional)
if [[ -f "${ROOT_DIR}/.env" ]]; then
  set -a
  # shellcheck disable=SC1090
  . "${ROOT_DIR}/.env"
  set +a
fi

RABBIT_HOST="${RABBITMQ_HOST:-${RABBIT_HOST:-rabbitmq}}"
RABBIT_USER="${RABBITMQ_USER:-${RABBIT_USER:-admin}}"
RABBIT_PASS="${RABBITMQ_PASSWORD:-${RABBIT_PASS:-admin}}"
QUEUE_NAME="etl_queue"

echo "Iniciando pipeline ETL..."
docker exec -i payments-rabbitmq     rabbitmqadmin     --host="${RABBIT_HOST}"     --username="${RABBIT_USER}"     --password="${RABBIT_PASS}"     publish routing_key="${QUEUE_NAME}" payload="stage"

echo "Mensaje enviado a la cola."
