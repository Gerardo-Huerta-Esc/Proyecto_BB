# /etl/clean.py
import psycopg2
import os

DB_USER = os.getenv("POSTGRES_USER", "admin")
DB_PASS = os.getenv("POSTGRES_PASSWORD", "admin")
DB_NAME = os.getenv("POSTGRES_DB", "payments")
DB_HOST = os.getenv("POSTGRES_HOST", "postgres")

def clean_txn():
    conn = psycopg2.connect(
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASS,
        host=DB_HOST
    )
    cur = conn.cursor()
    
    # Eliminar transacciones con account_id o terminal_id inválidos
    cur.execute("""
        DELETE FROM txn
        WHERE account_id NOT IN (SELECT id FROM account)
           OR terminal_id NOT IN (SELECT id FROM terminal)
           OR amount < 0;
    """)
    
    conn.commit()
    cur.close()
    conn.close()
    print("[CLEAN] Transacciones validadas y limpiadas.")

if __name__ == "__main__":
    clean_txn()
