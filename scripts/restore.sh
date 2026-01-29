set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${ROOT_DIR}/backups"
COMPOSE_FILE="${ROOT_DIR}/compose/docker-compose.yml"

DB="${POSTGRES_DB:-payments}"
USER="${POSTGRES_USER:-admin}"

backup_file="${1:-}"
if [[ -z "${backup_file}" ]]; then
  if [[ -f "${BACKUP_DIR}/LATEST" ]]; then
    backup_file="$(cat "${BACKUP_DIR}/LATEST")"
  fi
fi

if [[ -z "${backup_file}" || ! -f "${backup_file}" ]]; then
  echo "[RESTORE] Archivo de respaldo no encontrado. Uso: ./scripts/restore.sh /ruta/absoluta/backup.sql.gz"
  echo "[RESTORE] Si ejecutas `./scripts/backup.sh` se generará un dump nuevo y se actualizará backups/LATEST."
  exit 1
fi

echo "[RESTORE] Restoring from: ${backup_file}"

# Elimina y recrea la base de datos usando la opción FORCE disponible en Postgres 15.
docker compose -f "${COMPOSE_FILE}" exec -T postgres psql -U "${USER}" -d postgres -v ON_ERROR_STOP=1 -c "DROP DATABASE IF EXISTS ${DB} WITH (FORCE);"
docker compose -f "${COMPOSE_FILE}" exec -T postgres psql -U "${USER}" -d postgres -v ON_ERROR_STOP=1 -c "CREATE DATABASE ${DB};"

echo "[RESTORE] Inicia la restauración del dump."
gzip -dc "${backup_file}" | docker compose -f "${COMPOSE_FILE}" exec -T postgres psql -U "${USER}" -d "${DB}" -v ON_ERROR_STOP=1

echo "[RESTORE] Done."
