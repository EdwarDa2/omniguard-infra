-- ============================================================
-- OmniGuard SOC - Datos Iniciales (Seed)
-- Ejecutado después de 02-schema.sql
-- ============================================================

-- ============================================================
-- ROLES (id fijos para referencias estables)
-- ============================================================

INSERT INTO roles (id, name, description) VALUES
    ('11111111-1111-1111-1111-111111111111', 'ADMIN', 'Administrador total del sistema: gestión de usuarios, roles, configuración global, auditoría'),
    ('22222222-2222-2222-2222-222222222222', 'ANALYST', 'Analista SOC: gestión de alertas, activos, vulnerabilidades, notificaciones'),
    ('33333333-3333-3333-3333-333333333333', 'VIEWER', 'Solo lectura: dashboards, reportes, consulta de alertas y activos')
ON CONFLICT (name) DO UPDATE SET
    description = EXCLUDED.description;

-- ============================================================
-- USUARIO ADMIN INICIAL
-- Password: "ChangeMe123!" (hash Argon2id - GENERA UNO REAL EN PRODUCCIÓN)
-- Este hash es SOLO para desarrollo. En producción usa: ./scripts/generate-password-hash.sh
-- ============================================================

INSERT INTO users (id, role_id, username, email, password_hash, is_active, totp_enabled)
VALUES (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '11111111-1111-1111-1111-111111111111',
    'admin',
    'admin@omniguard.local',
    '$argon2id$v=19$m=65536,t=3,p=4$c29tZXNhbHQ$+/xX8yZ8yZ8yZ8yZ8yZ8yZ8yZ8yZ8yZ8yZ8yZ8yZ8',  -- PLACEHOLDER
    TRUE,
    FALSE
)
ON CONFLICT (username) DO NOTHING;

-- ============================================================
-- CONFIGURACIÓN DE NOTIFICACIONES POR DEFECTO (plantilla)
-- ============================================================

-- Se crean vacías para que el admin las configure via UI
-- INSERT INTO notification_configs (user_id, platform, webhook_url, chat_id, is_active) VALUES
--     ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'DISCORD', 'https://discord.com/api/webhooks/...', NULL, FALSE),
--     ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'TELEGRAM', NULL, '-1001234567890', FALSE);

-- ============================================================
-- COMENTARIOS PARA DOCUMENTACIÓN
-- ============================================================

COMMENT ON TABLE roles IS 'Roles del sistema (RBAC). IDs fijos para migraciones estables.';
COMMENT ON TABLE users IS 'Usuarios del sistema. Password almacenado como hash Argon2id.';
COMMENT ON TABLE assets IS 'Inventario de activos de red (superficie de ataque).';
COMMENT ON TABLE open_ports IS 'Puertos abiertos descubiertos por escaneo.';
COMMENT ON TABLE vulnerabilities IS 'Vulnerabilidades asociadas a activos/puertos (CVE).';
COMMENT ON TABLE alerts IS 'Alertas de intrusión generadas por NIDS (sensor + analyzer).';
COMMENT ON TABLE notification_configs IS 'Configuraciones de notificación por usuario y plataforma.';
COMMENT ON TABLE audit_logs IS 'Log de auditoría inmutable para trazabilidad completa.';
COMMENT ON TABLE paseto_sessions IS 'Sesiones PASETO (refresh tokens) para revocación y expiración.';
COMMENT ON TABLE alert_vulnerability_links IS 'Correlación alerta-vulnerabilidad con score de confianza.';