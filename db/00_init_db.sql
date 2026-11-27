-- ============================================================================
-- MAY DELICIAS - GESTIÓN GASTRONÓMICA
-- Archivo: db/00_init_db.sql
-- NOTA IMPORTANTE:
-- En PostgreSQL, CREATE DATABASE NO se puede ejecutar dentro de un bloque
-- de transacción (BEGIN ... COMMIT). Debe ejecutarse de forma independiente
-- conectado a la base de datos por defecto 'postgres'.
-- ============================================================================

-- 1. Crear la base de datos (ejecutar fuera de transacciones)
CREATE DATABASE may_delicias
    WITH 
    ENCODING = 'UTF8'
    LC_COLLATE = 'C'
    LC_CTYPE = 'C'
    TEMPLATE = template0;

-- 2. Conectarse a la base recién creada (en psql):
-- \c may_delicias

-- Una vez conectado a 'may_delicias', ejecutar:
-- db/01_schema.sql
-- db/02_seed.sql
