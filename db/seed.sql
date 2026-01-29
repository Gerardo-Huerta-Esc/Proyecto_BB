-- Tablas principales
CREATE TABLE IF NOT EXISTS account (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS merchant (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS terminal (
  id BIGSERIAL PRIMARY KEY,
  merchant_id BIGINT NOT NULL REFERENCES merchant(id) ON DELETE CASCADE
);

-- Tabla de transacciones, particionada por rango de fechas
CREATE TABLE IF NOT EXISTS txn (
  id BIGSERIAL,
  account_id BIGINT NOT NULL REFERENCES account(id) ON DELETE CASCADE,
  terminal_id BIGINT NOT NULL REFERENCES terminal(id) ON DELETE CASCADE,
  amount NUMERIC(12,2) NOT NULL,
  created_at TIMESTAMP NOT NULL
) PARTITION BY RANGE (created_at);

-- Crear particiones para los 12 meses de 2025
DO $$
DECLARE
  m INT;
  m_txt TEXT;
  next_m_txt TEXT;
BEGIN
  FOR m IN 1..12 LOOP
    m_txt := lpad(m::text, 2, '0');
    IF m < 12 THEN
      next_m_txt := lpad((m + 1)::text, 2, '0');
      EXECUTE format(
        'CREATE TABLE IF NOT EXISTS txn_2025_%s PARTITION OF txn
         FOR VALUES FROM (''2025-%s-01'') TO (''2025-%s-01'')',
        m_txt, m_txt, next_m_txt
      );
    ELSE
      -- Para diciembre, hasta el 1 de enero 2026
      EXECUTE format(
        'CREATE TABLE IF NOT EXISTS txn_2025_%s PARTITION OF txn
         FOR VALUES FROM (''2025-%s-01'') TO (''2026-01-01'')',
        m_txt, m_txt
      );
    END IF;
  END LOOP;
END $$;


-- Índices para consultas frecuentes
CREATE INDEX IF NOT EXISTS idx_txn_account ON txn(account_id);
CREATE INDEX IF NOT EXISTS idx_txn_terminal ON txn(terminal_id);
CREATE INDEX IF NOT EXISTS idx_txn_created_at ON txn(created_at);

-- Datos sintéticos de ejemplo para las tablas base
-- Cuentas
INSERT INTO account (name)
SELECT 'account_' || generate_series(1, 100000);

-- Comercios
INSERT INTO merchant (name)
SELECT 'merchant_' || generate_series(1, 5000);

-- Terminales
INSERT INTO terminal (merchant_id)
SELECT (1 + (random() * 4999)::int) FROM generate_series(1, 20000);