-- ============================================================
-- OmniGuard SOC - Particionado de Tablas Grandes
-- Requiere extensión pg_partman (incluida en postgres:16-alpine)
-- Ejecutar DESPUÉS de 02-schema.sql y 03-seed.sql
-- ============================================================

-- ============================================================
-- Habilitar pg_partman
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pg_partman;

-- ============================================================
-- PARTICIONADO: alerts (por RANGE en created_at, mensual)
-- ============================================================

-- Convertir tabla alerts a particionada
-- NOTA: Requiere recrear la tabla. Si ya hay datos, usar pg_partman.create_parent con p_data_move := true

-- Paso 1: Crear tabla padre particionada (si no existe)
-- CREATE TABLE alerts_partitioned (LIKE alerts INCLUDING ALL) PARTITION BY RANGE (created_at);

-- Paso 2: Migrar datos (pg_partman lo hace automático)
-- SELECT partman.create_parent('public.alerts', 'created_at', 'native', 'monthly', p_data_move => true);

-- Paso 3: Crear particiones futuras (pg_partman lo hace via job)
-- SELECT partman.run_maintenance();

-- ============================================================
-- CONFIGURACIÓN pg_partman PARA alerts
-- ============================================================

-- INSERT INTO partman.part_config (parent_table, control, type, partition_interval, retention, retention_keep_table, infinite_time_partitions)
-- VALUES ('public.alerts', 'created_at', 'range', '1 month', '13 months', false, true);

-- ============================================================
-- PARTICIONADO: audit_logs (por RANGE en changed_at, mensual)
-- Retención: 7 años (compliance)
-- ============================================================

-- INSERT INTO partman.part_config (parent_table, control, type, partition_interval, retention, retention_keep_table, infinite_time_partitions)
-- VALUES ('public.audit_logs', 'changed_at', 'range', '1 month', '84 months', false, true);

-- ============================================================
-- PARTICIONADO: vulnerabilities (opcional - por LIST en severity)
-- Para separar CRITICAL/HIGH en particiones "hot"
-- ============================================================

-- CREATE TABLE vulnerabilities_partitioned (LIKE vulnerabilities INCLUDING ALL) PARTITION BY LIST (severity);
-- CREATE TABLE vulnerabilities_critical PARTITION OF vulnerabilities_partitioned FOR VALUES IN ('CRITICAL');
-- CREATE TABLE vulnerabilities_high PARTITION OF vulnerabilities_partitioned FOR VALUES IN ('HIGH');
-- CREATE TABLE vulnerabilities_medium PARTITION OF vulnerabilities_partitioned FOR VALUES IN ('MEDIUM');
-- CREATE TABLE vulnerabilities_low PARTITION OF vulnerabilities_partitioned FOR VALUES IN ('LOW', 'NONE');

-- ============================================================
-- ÍNDICES BRIN para tablas append-only grandes
-- (Más eficientes que B-tree para datos temporales)
-- ============================================================

-- CREATE INDEX idx_alerts_created_at_brin ON alerts USING BRIN (created_at);
-- CREATE INDEX idx_audit_logs_changed_at_brin ON audit_logs USING BRIN (changed_at);
-- CREATE INDEX idx_vulnerabilities_discovered_at_brin ON vulnerabilities USING BRIN (discovered_at);

-- ============================================================
-- JOB DE MANTENIMIENTO pg_partman (ejecutar via pg_cron o cron externo)
-- ============================================================

-- SELECT cron.schedule('partman-maintenance', '0 * * * *', 'SELECT partman.run_maintenance();');
-- SELECT cron.schedule('partman-cleanup', '0 2 * * *', 'SELECT partman.run_maintenance(p_analyze := true);');

-- ============================================================
-- VERIFICACIÓN
-- ============================================================

-- Ver configuración: SELECT * FROM partman.part_config;
-- Ver particiones: SELECT * FROM partman.show_partitions('public.alerts');
-- Ver estado: SELECT * FROM partman.check_default();