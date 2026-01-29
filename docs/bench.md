# Benchmark

Este documento contiene resultados de pruebas de carga con `pgbench`.

## Configuración del benchmark

Se ejecutó `pgbench` en una base de datos separada (`bench`) con:
- Scaling factor: 5 (500,000 filas en pgbench_accounts)
- Clientes concurrentes: 10
- Threads: 2
- Duración: 15 segundos

## Comando ejecutado

```bash
docker exec payments-postgres pgbench -U admin -i -s 5 bench
docker exec payments-postgres pgbench -U admin -c 10 -j 2 -T 15 bench
```

## Resultados

```
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 5
query mode: simple
number of clients: 10
number of threads: 2
maximum number of tries: 1
duration: 15 s
number of transactions actually processed: 41955
number of failed transactions: 0 (0.000%)
latency average = 3.575 ms
initial connection time = 16.273 ms
tps = 2797.099950 (without initial connection time)
```

## Interpretación

- **TPS (transacciones por segundo)**: ~2797
- **Latencia promedio**: 3.575 ms
- **0 transacciones fallidas**: sistema estable bajo carga moderada

Estos resultados son con los parámetros tuneados:
- `shared_buffers=256MB`
- `work_mem=16MB`
- `wal_compression=on`
