set -eu

# Script de backups automáticos: ejecuta un pg_dump periódico mientras el stack está activo para conservar dumps recientes.

BACKUP_DIR="${BACKUP_DIR:-/backups}"
PGHOST="${PGHOST:-postgres}"
PGPORT="${PGPORT:-5432}"
PGDATABASE="${PGDATABASE:-payments}"
PGUSER="${PGUSER:-admin}"
PGPASSWORD="${PGPASSWORD:-admin}"
INTERVAL_SECONDS="${BACKUP_INTERVAL_SECONDS:-3600}"

mkdir -p "${BACKUP_DIR}"

echo "[BACKUP-JOB] starting; interval=${INTERVAL_SECONDS}s"

while true; do
  ts="$(date -u +%Y%m%dT%H%M%SZ)"
  out="${BACKUP_DIR}/payments_${ts}.sql.gz"
  echo "[BACKUP-JOB] creating ${out}"

  # pg_dump ya está instalado en la imagen oficial de Postgres, por eso se ejecuta directamente aquí.
  PGPASSWORD="${PGPASSWORD}" pg_dump \
    -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -d "${PGDATABASE}" \
    --no-owner --no-privileges | gzip -c > "${out}"

  echo "${out}" > "${BACKUP_DIR}/LATEST"
  echo "[BACKUP-JOB] done"

  sleep "${INTERVAL_SECONDS}"
done
