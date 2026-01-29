# Alertas (Prometheus)

Este proyecto implementa alertas activas en Prometheus para monitorear el estado del servicio de base de datos.

## Configuración

Las reglas de alerta están definidas en `prometheus/alerts.yml` y se cargan automáticamente al levantar Prometheus.

## Alertas implementadas

### 1. PostgresDown (severity: critical)

**Condición**: `pg_up == 0`  
**Duración**: 30 segundos  
**Descripción**: Se dispara cuando el postgres-exporter no puede conectarse a PostgreSQL por más de 30 segundos.

```yaml
- alert: PostgresDown
  expr: pg_up==0
  for: 30s
  labels:
    severity: critical
  annotations:
    summary: "Postgres is down"
    description: "pg_up ==0 for 30s on {{ $labels.instance }}"
```

### 2. PostgresExporterDown (severity: warning)

**Condición**: `up{job="postgres-exporter"} == 0`  
**Duración**: 30 segundos  
**Descripción**: Se dispara cuando Prometheus no puede scrapear métricas del postgres-exporter por más de 30 segundos.

```yaml
- alert: PostgresExporterDown
  expr: up{job="postgres-exporter"} == 0
  for: 30s
  labels:
    severity: warning
  annotations:
    summary: "Postgres exporter is down"
    description: "Prometheus cannot scrape postgres-exporter for 30s."
```

## Verificacinó

### ver estado de alertas

Accede a Prometheus en `http://localhost:9090/alerts` para ver el estado actual de todas las alertas.

- **inactive**: La condición no se cumple, todo normal.
- **pending**: La condición se cumple pero aún no pasa el tiempo mínimo (30s).
- **firing**: La alerta está activa (la condición se cumplió por más de 30s).

### Probar manualmente

Para simular la caída de Postgre y verificar que la alerta se dispara:

```bash
# Detener Postgres
docker stop payments-postgres

# Esperar ~30-45 segundos y verificar en http://localhost:9090/alerts
# que PostgresDown pasa a "firing"

# Restaurar
docker start payments-postgres
```

## API de consulta

También puedes consultar alertas activas via API:

```bash
curl -s http://localhost:9090/api/v1/alerts
```

Si hay alertas activas, verás objetos en `data.alerts[]` con `state: "firing"`.
