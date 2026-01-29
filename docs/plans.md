# Consultas y análisis 

Este documento incluye **consultas de integridad** y **planes de ejecución** (PostgreSQL `EXPLAIN (ANALYZE, BUFFERS)`) para cumplir el punto 4.

## 1) Integridad

Salida capturada:

```
          captured_at          | txn_count 
-------------------------------+-----------
 2026-01-29 09:22:33.884908+00 |   1000000
(1 row)

 orphan_txn_accounts 
---------------------
                   0
(1 row)

 orphan_txn_terminals 
----------------------
                    0
(1 row)

 negative_amount_txn 
---------------------
                   0
(1 row)
```

Interpretación mínima:
- No hay transacciones con `account_id`/`terminal_id` huérfanos.
- No hay montos negativos.

## 2) Plan de ejecución: agregación mensual

Consulta:

```sql
SELECT date_trunc('month', created_at) AS month, count(*) AS total_txn, sum(amount) AS total_amount
FROM txn
WHERE created_at >= '2025-01-01' AND created_at < '2026-01-01'
GROUP BY 1
ORDER BY 1;
```

Salida capturada:

```
 Finalize GroupAggregate  (cost=24853.14..24906.81 rows=200 width=48) (actual time=236.329..238.439 rows=12 loops=1)
   Group Key: (date_trunc('month'::text, txn.created_at))
   Buffers: shared hit=8354
   ->  Gather Merge  (cost=24853.14..24899.81 rows=400 width=48) (actual time=236.311..238.410 rows=15 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Parallel Append  (cost=0.00..20717.46 rows=416668 width=14) (actual time=0.242..145.250 rows=333333 loops=3)
               ->  Parallel Seq Scan on txn_2025_01 ...
               ->  Parallel Seq Scan on txn_2025_02 ...
               ... (particiones 2025_03..2025_12)
 Planning Time: 7.944 ms
 Execution Time: 239.238 ms
```

Interpretación:
- Se observa `Parallel Append` sobre particiones (`txn_2025_MM`), lo que confirma el uso de particionamiento por rango mensual.

## 3) Plan de ejecución: filtro por cuenta + rango (pruning)

Consulta:

```sql
SELECT count(*), sum(amount)
FROM txn
WHERE account_id = 1
  AND created_at >= '2025-05-01'
  AND created_at <  '2025-06-01';
```

Salida capturada:

```
 Aggregate  (cost=12.03..12.04 rows=1 width=40) (actual time=0.231..0.232 rows=1 loops=1)
   ->  Bitmap Heap Scan on txn_2025_05 txn  (cost=4.31..12.02 rows=2 width=6) (actual time=0.229..0.229 rows=0 loops=1)
         ->  Bitmap Index Scan on txn_2025_05_account_id_idx  (cost=0.00..4.31 rows=2 width=0) (actual time=0.227..0.228 rows=0 loops=1)
 Planning Time: 0.915 ms
 Execution Time: 0.381 ms
```

Interpretación mínima:
- Se ejecuta contra **una sola partición** (`txn_2025_05`), mostrando pruning por rango de fechas.
