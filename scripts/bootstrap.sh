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

POSTGRES_USER="${POSTGRES_USER:-admin}"
POSTGRES_DB="${POSTGRES_DB:-payments}"

echo "DESDE BOOTSTRAP Esperando a que PostgreSQL esté listo..."
until docker exec payments-postgres pg_isready -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" > /dev/null 2>&1; do
  sleep 2
done

# Run seed.sql only on a fresh DB (avoid duplication on repeated bootstrap runs).
# IMPORTANT: don't reference 'account' unless it exists (fresh DB would error).
has_account="$(docker exec payments-postgres psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -tAc "SELECT to_regclass('public.account') IS NOT NULL;" | tr -d '[:space:]')"

seed_count=0
if [[ "${has_account}" == "t" ]]; then
  seed_count="$(docker exec payments-postgres psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -tAc "SELECT count(*) FROM account;" | tr -d '[:space:]')"
fi

if [[ "${seed_count:-0}" != "0" ]]; then
  echo "DESDE BOOTSTRAP: Seed detectado (account_count=${seed_count}). Saltando seed.sql para evitar duplicación."
else
  echo "DESDE BOOTSTRAP: Ejecutando seed.sql (esquema + datos base)..."
  docker exec -i payments-postgres psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" < "${ROOT_DIR}/db/seed.sql"
fi

echo "DESDE BOOTSTRAP Esperando a que RabbitMQ esté listo..."
until docker exec payments-rabbitmq rabbitmqctl status > /dev/null 2>&1; do
  sleep 2
done

echo "DESDE BOOTSTRAP: Disparando pipeline ETL (kickoff)..."
bash "${ROOT_DIR}/scripts/queue_kickoff.sh"

echo "DESDE BOOTSTRAP: Bootstrap finalizado correctamente"
