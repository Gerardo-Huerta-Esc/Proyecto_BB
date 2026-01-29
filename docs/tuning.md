# Mantenimiento y tuning (mínimo)

Este documento cumple el punto 5 con:
- parámetros de Postgres configurados (y su valor actual)
- una prueba de carga simple con `pgbench` y salida capturada

## 1) Parámetros configurados

En `compose/docker-compose.yml` el contenedor de Postgres se inicia con:
- `shared_buffers=256MB`
- `work_mem=16MB`
- `wal_compression=on`

Valores capturados desde `SHOW`:

```
 shared_buffers 
----------------
 256MB
(1 row)

 work_mem 
----------
 16MB
(1 row)

 wal_compression 
-----------------
 pglz
(1 row)
```

## 2) Prueba de carga (pgbench)

Se ejecutó un benchmark simple en una base separada `bench`:

```bash
docker exec payments-postgres pgbench -U admin -i -s 5 bench
docker exec payments-postgres pgbench -U admin -c 10 -j 2 -T 15 bench
```

Salida capturada:

```
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 5
query mode: simple
number of clients: 10
number of threads: 2
duration: 15 s
number of transactions actually processed: 41955
number of failed transactions: 0 (0.000%)
latency average = 3.575 ms
initial connection time = 16.273 ms
tps = 2797.099950 (without initial connection time)
```
