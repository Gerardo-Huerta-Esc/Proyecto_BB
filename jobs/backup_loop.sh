#!/bin/sh
set -eu

# Simple "automatic backups" job:
# runs pg_dump periodically while the stack is up.

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

  # pg_dump is available in postgres image.
  PGPASSWORD="${PGPASSWORD}" pg_dump \
    -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}" -d "${PGDATABASE}" \
    --no-owner --no-privileges | gzip -c > "${out}"

  echo "${out}" > "${BACKUP_DIR}/LATEST"
  echo "[BACKUP-JOB] done"

  sleep "${INTERVAL_SECONDS}"
done
