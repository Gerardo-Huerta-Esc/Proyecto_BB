# Migrations

En este proyecto, el esquema inicial se crea directamente desde `db/seed.sql` durante el bootstrap.

Para un entormo de producción con evolución de esquema, esta carpeta contendría:
- Migraciones versionadas (ej: `001_initial_schema.sql`, `002_add_indexes.sql`)
- alguna herramienta como Flyway gestionar migraciones

Actualmente, el proyecto usa un enfoque simple:
- `seed.sql` contiene el DDL completo (tablas, índices, particiones)
- Se ejecuta una sola vez al levantar el entorno por primera vez
