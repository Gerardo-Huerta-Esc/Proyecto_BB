import os
import random
from datetime import datetime

import psycopg2
from psycopg2.extras import execute_values


def _get_int_env(name: str, default: int) -> int:
    raw = os.getenv(name)
    if raw is None or raw == "":
        return default
    try:
        return int(raw)
    except ValueError:
        return default


def generate_txn():
    """
    Inserta transacciones sintéticas hasta llegar a un objetivo.

    Variables de entorno:
    - POSTGRES_HOST/PORT/DB/USER/PASSWORD
    - STAGE_TARGET_TXN: total deseado en txn (default: 1_000_000)
    - STAGE_CHUNK_SIZE: inserts por commit (default: 5_000)
    """
    db_user = os.getenv("POSTGRES_USER", "admin")
    db_pass = os.getenv("POSTGRES_PASSWORD", "admin")
    db_name = os.getenv("POSTGRES_DB", "payments")
    db_host = os.getenv("POSTGRES_HOST", "postgres")
    db_port = _get_int_env("POSTGRES_PORT", 5432)

    target_total = _get_int_env("STAGE_TARGET_TXN", 1_000_000)
    chunk_size = _get_int_env("STAGE_CHUNK_SIZE", 5_000)
    if chunk_size <= 0:
        chunk_size = 5_000

    conn = psycopg2.connect(
        dbname=db_name,
        user=db_user,
        password=db_pass,
        host=db_host,
        port=db_port,
    )
    cur = conn.cursor()

    # Cuántas transacciones ya existen (idempotente).
    cur.execute("SELECT count(*) FROM txn;")
    existing = int(cur.fetchone()[0])
    remaining = max(0, target_total - existing)
    if remaining == 0:
        print(f"[STAGE] Ya existen {existing} transacciones (objetivo={target_total}). No hay nada que insertar.")
        cur.close()
        conn.close()
        return

    # Traer IDs existentes 
    cur.execute("SELECT id FROM account;")
    accounts = [row[0] for row in cur.fetchall()]

    cur.execute("SELECT id FROM terminal;")
    terminals = [row[0] for row in cur.fetchall()]

    if not accounts or not terminals:
        raise RuntimeError("No hay accounts o terminals para generar transacciones (seed incompleto).")

    insert_sql = "INSERT INTO txn (account_id, terminal_id, amount, created_at) VALUES %s"

    inserted_total = 0
    while inserted_total < remaining:
        n = min(chunk_size, remaining - inserted_total)
        rows = []
        for _ in range(n):
            account_id = random.choice(accounts)
            terminal_id = random.choice(terminals)
            amount = round(random.uniform(10, 1000), 2)

            # Fecha aleatoria en 2025 (día 1..28 para evitar edge cases).
            month = random.randint(1, 12)
            day = random.randint(1, 28)
            created_at = datetime(
                2025,
                month,
                day,
                random.randint(0, 23),
                random.randint(0, 59),
                random.randint(0, 59),
            )
            rows.append((account_id, terminal_id, amount, created_at))

        execute_values(cur, insert_sql, rows, page_size=min(1000, n))
        conn.commit()

        inserted_total += n
        if inserted_total % (chunk_size * 5) == 0 or inserted_total == remaining:
            print(
                f"[STAGE] Insertadas {inserted_total}/{remaining} (existentes={existing}, objetivo={target_total})."
            )

    cur.close()
    conn.close()


if __name__ == "__main__":
    generate_txn()
