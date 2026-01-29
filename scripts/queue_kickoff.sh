
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${ROOT_DIR}/compose/docker-compose.yml"

# Carga las variables definidas en .env (si está disponible) para personalizar credenciales.
if [[ -f "${ROOT_DIR}/.env" ]]; then
  set -a
  # shellcheck disable=SC1090
  . "${ROOT_DIR}/.env"
  set +a
fi

RABBIT_HOST="${RABBITMQ_HOST:-${RABBIT_HOST:-localhost}}"
RABBIT_USER="${RABBITMQ_USER:-${RABBIT_USER:-admin}}"
RABBIT_PASS="${RABBITMQ_PASSWORD:-${RABBIT_PASS:-admin}}"
QUEUE_NAME="etl_queue"

echo "Iniciando pipeline ETL..."
docker compose -f "${COMPOSE_FILE}" exec -T rabbitmq rabbitmqadmin \
  --host="${RABBIT_HOST}" \
  --username="${RABBIT_USER}" \
  --password="${RABBIT_PASS}" \
  publish routing_key="${QUEUE_NAME}" payload="stage"

echo "Mensaje enviado a la cola."
