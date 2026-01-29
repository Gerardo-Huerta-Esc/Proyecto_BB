set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${ROOT_DIR}/backups"
COMPOSE_FILE="${ROOT_DIR}/compose/docker-compose.yml"

DB="${POSTGRES_DB:-payments}"
USER="${POSTGRES_USER:-admin}"

mkdir -p "${BACKUP_DIR}"

ts="$(date -u +%Y%m%dT%H%M%SZ)"
out="${BACKUP_DIR}/payments_${ts}.sql.gz"

echo "[BACKUP] Creating dump: ${out}"
docker compose -f "${COMPOSE_FILE}" exec -T postgres pg_dump -U "${USER}" -d "${DB}" --no-owner --no-privileges | gzip -c > "${out}"

echo "${out}" > "${BACKUP_DIR}/LATEST"
echo "[BACKUP] Done."
