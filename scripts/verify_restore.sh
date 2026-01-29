#!/bin/bash
set -euo pipefail

DB="${POSTGRES_DB:-payments}"
USER="${POSTGRES_USER:-admin}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${ROOT_DIR}/compose/docker-compose.yml"

echo "[VERIFY] $(date -u +%Y-%m-%dT%H:%M:%SZ)"
docker compose -f "${COMPOSE_FILE}" exec -T postgres psql -U "${USER}" -d "${DB}" -v ON_ERROR_STOP=1 -c "SELECT count(*) AS account_count FROM account;"
docker compose -f "${COMPOSE_FILE}" exec -T postgres psql -U "${USER}" -d "${DB}" -v ON_ERROR_STOP=1 -c "SELECT count(*) AS merchant_count FROM merchant;"
docker compose -f "${COMPOSE_FILE}" exec -T postgres psql -U "${USER}" -d "${DB}" -v ON_ERROR_STOP=1 -c "SELECT count(*) AS terminal_count FROM terminal;"
docker compose -f "${COMPOSE_FILE}" exec -T postgres psql -U "${USER}" -d "${DB}" -v ON_ERROR_STOP=1 -c "SELECT count(*) AS txn_count FROM txn;"
