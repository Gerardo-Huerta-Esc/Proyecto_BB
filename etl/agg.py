# /etl/agg.py
import psycopg2
import os

DB_USER = os.getenv("POSTGRES_USER", "admin")
DB_PASS = os.getenv("POSTGRES_PASSWORD", "admin")
DB_NAME = os.getenv("POSTGRES_DB", "payments")
DB_HOST = os.getenv("POSTGRES_HOST", "postgres")

def aggregate_metrics():
    conn = psycopg2.connect(
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASS,
        host=DB_HOST
    )
    cur = conn.cursor()
    
    # Ejemplo de agregación: total por mes
    cur.execute("""
        CREATE TABLE IF NOT EXISTS txn_monthly AS
        SELECT
            date_trunc('month', created_at) AS month,
            count(*) AS total_txn,
            sum(amount) AS total_amount,
            avg(amount) AS avg_amount
        FROM txn
        GROUP BY month
        ORDER BY month;
    """)
    
    conn.commit()
    cur.close()
    conn.close()
    print("[AGG] Métricas agregadas por mes.")

if __name__ == "__main__":
    aggregate_metrics()
