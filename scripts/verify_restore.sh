#!/bin/bash
set -euo pipefail

CONTAINER="${POSTGRES_CONTAINER_NAME:-payments-postgres}"
DB="${POSTGRES_DB:-payments}"
USER="${POSTGRES_USER:-admin}"

echo "[VERIFY] $(date -u +%Y-%m-%dT%H:%M:%SZ)"
docker exec "${CONTAINER}" psql -U "${USER}" -d "${DB}" -v ON_ERROR_STOP=1 -c "SELECT count(*) AS account_count FROM account;"
docker exec "${CONTAINER}" psql -U "${USER}" -d "${DB}" -v ON_ERROR_STOP=1 -c "SELECT count(*) AS merchant_count FROM merchant;"
docker exec "${CONTAINER}" psql -U "${USER}" -d "${DB}" -v ON_ERROR_STOP=1 -c "SELECT count(*) AS terminal_count FROM terminal;"
docker exec "${CONTAINER}" psql -U "${USER}" -d "${DB}" -v ON_ERROR_STOP=1 -c "SELECT count(*) AS txn_count FROM txn;"
