# Backups & Restore (simple)

Este proyecto incluye un mecanismo **simple** (pero verificable) para:

- **Backups automáticos** (mientras el stack está levantado) vía un servicio `backup` en Docker Compose.
- **Backups manuales** bajo demanda.
- **Restore** desde un dump y verificación posterior.

## 1) Backups automáticos

Al levantar el stack con:

```bash
docker compose -f compose/docker-compose.yml up -d
```

se levanta el servicio `payments-backup` que ejecuta `pg_dump` cada `BACKUP_INTERVAL_SECONDS` (por defecto 3600s) y escribe archivos en la carpeta `./backups/` del host.

Archivos:
- `backups/payments_<timestamp>.sql.gz`
- `backups/LATEST` (contiene la ruta del último backup generado)

## 2) Backup manual (on-demand)

```bash
./scripts/backup.sh
```

Esto genera un backup comprimido en `./backups/` y actualiza `./backups/LATEST`.

## 3) Restore desde backup

### Opción A: usar el último backup (`backups/LATEST`)

```bash
./scripts/restore.sh
```

### Opción B: especificar archivo

```bash
./scripts/restore.sh /home/geralt/payments-platform/backups/payments_<timestamp>.sql.gz
```

El restore hace:
- `DROP DATABASE payments WITH (FORCE);`
- `CREATE DATABASE payments;`
- restaura el dump con `psql`

## 4) Verificación post-restore (evidencia)

Después del restore, corre:

```bash
./scripts/verify_restore.sh
```

Salida esperada (ejemplo):
- `account_count` ≈ 100000
- `merchant_count` ≈ 5000
- `terminal_count` ≈ 20000
- `txn_count` ≈ 1000000 (si ya corriste el ETL antes del backup)

Si necesitas “evidencia” en un archivo, puedes redirigir:

```bash
./scripts/verify_restore.sh | tee docs/restore_evidence.txt
```

