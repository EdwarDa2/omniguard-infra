-- ============================================================
-- OmniGuard SOC - Esquema Principal (PostgreSQL 16)
-- Basado en omniguard-soc.dbml (fuente de verdad)
-- ============================================================

-- ============================================================
-- 1. DOMINIO IAM (Identidad y Accesos - PASETO)
-- ============================================================

CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name user_role NOT NULL UNIQUE,
    description VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    totp_secret VARCHAR(32),                    -- Para 2FA TOTP
    totp_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índices users
CREATE INDEX idx_users_role_id ON users(role_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_is_active ON users(is_active);
CREATE INDEX idx_users_created_at ON users(created_at);

-- ============================================================
-- 2. DOMINIO DE ACTIVOS (Superficie de Ataque)
-- ============================================================

CREATE TABLE assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ip_address INET NOT NULL UNIQUE,
    mac_address MACADDR UNIQUE,
    hostname VARCHAR(255),
    os_name VARCHAR(100),
    status asset_status NOT NULL DEFAULT 'ACTIVE',
    last_scanned_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índices assets
CREATE INDEX idx_assets_ip_address ON assets(ip_address);
CREATE INDEX idx_assets_mac_address ON assets(mac_address);
CREATE INDEX idx_assets_status ON assets(status);
CREATE INDEX idx_assets_last_scanned_at ON assets(last_scanned_at);
CREATE INDEX idx_assets_status_ip ON assets(status, ip_address);

CREATE TABLE open_ports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE ON UPDATE CASCADE,
    port_number INT NOT NULL CHECK (port_number BETWEEN 1 AND 65535),
    protocol port_protocol NOT NULL,
    service_banner TEXT,
    discovered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (asset_id, port_number, protocol)
);

-- Índices open_ports
CREATE INDEX idx_open_ports_asset_id ON open_ports(asset_id);
CREATE INDEX idx_open_ports_port_number ON open_ports(port_number);
CREATE INDEX idx_open_ports_protocol ON open_ports(protocol);
CREATE INDEX idx_open_ports_discovered_at ON open_ports(discovered_at);

CREATE TABLE vulnerabilities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE ON UPDATE CASCADE,
    open_port_id UUID REFERENCES open_ports(id) ON DELETE SET NULL ON UPDATE CASCADE,
    cve_id VARCHAR(20) NOT NULL,
    severity vulnerability_severity NOT NULL,
    description TEXT,
    discovered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Constraint: formato CVE-YYYY-NNNNN
    CONSTRAINT chk_cve_format CHECK (cve_id ~* '^CVE-\d{4}-\d{4,}$')
);

-- Índices vulnerabilities
CREATE INDEX idx_vulnerabilities_asset_id ON vulnerabilities(asset_id);
CREATE INDEX idx_vulnerabilities_open_port_id ON vulnerabilities(open_port_id);
CREATE INDEX idx_vulnerabilities_cve_id ON vulnerabilities(cve_id);
CREATE INDEX idx_vulnerabilities_severity ON vulnerabilities(severity);
CREATE INDEX idx_vulnerabilities_discovered_at ON vulnerabilities(discovered_at);
CREATE INDEX idx_vulnerabilities_asset_severity ON vulnerabilities(asset_id, severity);
CREATE INDEX idx_vulnerabilities_cve_severity ON vulnerabilities(cve_id, severity);

-- ============================================================
-- 3. DOMINIO DE ALERTAS (NIDS)
-- ============================================================

CREATE TABLE alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id UUID REFERENCES assets(id) ON DELETE SET NULL ON UPDATE CASCADE,
    threat_type alert_threat_type NOT NULL,
    severity alert_severity NOT NULL,
    source_ip INET NOT NULL,
    destination_ip INET NOT NULL,
    source_port INT,
    destination_port INT,
    protocol network_protocol,
    payload_snippet TEXT,
    status alert_status NOT NULL DEFAULT 'OPEN',
    assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
    resolution_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);

-- Índices alerts (críticos para SOC)
CREATE INDEX idx_alerts_asset_id ON alerts(asset_id);
CREATE INDEX idx_alerts_threat_type ON alerts(threat_type);
CREATE INDEX idx_alerts_severity ON alerts(severity);
CREATE INDEX idx_alerts_status ON alerts(status);
CREATE INDEX idx_alerts_source_ip ON alerts(source_ip);
CREATE INDEX idx_alerts_destination_ip ON alerts(destination_ip);
CREATE INDEX idx_alerts_created_at ON alerts(created_at DESC);
CREATE INDEX idx_alerts_assigned_to ON alerts(assigned_to);

-- Índices compuestos para dashboards SOC
CREATE INDEX idx_alerts_status_severity_created ON alerts(status, severity, created_at DESC);
CREATE INDEX idx_alerts_asset_status_created ON alerts(asset_id, status, created_at DESC);
CREATE INDEX idx_alerts_threat_severity_created ON alerts(threat_type, severity, created_at DESC);
CREATE INDEX idx_alerts_source_ip_created ON alerts(source_ip, created_at DESC);
CREATE INDEX idx_alerts_dest_ip_created ON alerts(destination_ip, created_at DESC);

-- ============================================================
-- 4. DOMINIO DE NOTIFICACIONES (Integraciones)
-- ============================================================

CREATE TABLE notification_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    platform notification_platform NOT NULL,
    webhook_url TEXT,
    chat_id VARCHAR(100),
    bot_token VARCHAR(255),              -- Para Telegram (encriptado en app)
    email_address VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, platform)
);

-- Índices notification_configs
CREATE INDEX idx_notification_configs_user_id ON notification_configs(user_id);
CREATE INDEX idx_notification_configs_platform ON notification_configs(platform);
CREATE INDEX idx_notification_configs_is_active ON notification_configs(is_active);

-- ============================================================
-- 5. TABLAS DE APOYO / AUDITORÍA
-- ============================================================

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID NOT NULL,
    action audit_action NOT NULL,
    old_values JSONB,
    new_values JSONB,
    changed_by UUID REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata JSONB,                      -- IP, user-agent, request-id, correlation-id
    -- Índice compuesto para consultas de auditoría
    CONSTRAINT chk_entity_type CHECK (entity_type IN ('users', 'roles', 'assets', 'open_ports', 'vulnerabilities', 'alerts', 'notification_configs', 'paseto_sessions'))
);

CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_logs_changed_by ON audit_logs(changed_by);
CREATE INDEX idx_audit_logs_changed_at ON audit_logs(changed_at DESC);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_entity_changed ON audit_logs(entity_type, entity_id, changed_at DESC);

-- Particionado por mes para audit_logs (requiere pg_partman o manual)
-- Ver 04-partitions.sql

CREATE TABLE paseto_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    token_hash VARCHAR(255) NOT NULL UNIQUE,  -- Argon2id hash del refresh token
    issued_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    revoked_reason VARCHAR(100),         -- LOGOUT, PASSWORD_CHANGE, ADMIN_REVOKE, EXPIRED, SECURITY_EVENT
    ip_address INET,
    user_agent TEXT,
    device_fingerprint VARCHAR(64)
);

CREATE INDEX idx_paseto_sessions_user_id ON paseto_sessions(user_id);
CREATE INDEX idx_paseto_sessions_expires_at ON paseto_sessions(expires_at);
CREATE INDEX idx_paseto_sessions_revoked_at ON paseto_sessions(revoked_at);
CREATE INDEX idx_paseto_sessions_token_hash ON paseto_sessions(token_hash);
CREATE INDEX idx_paseto_sessions_expires_revoked ON paseto_sessions(expires_at, revoked_at);

-- ============================================================
-- 6. CORRELACIÓN ALERTA-VULNERABILIDAD
-- ============================================================

CREATE TABLE alert_vulnerability_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_id UUID NOT NULL REFERENCES alerts(id) ON DELETE CASCADE ON UPDATE CASCADE,
    vulnerability_id UUID NOT NULL REFERENCES vulnerabilities(id) ON DELETE CASCADE ON UPDATE CASCADE,
    confidence_score NUMERIC(3,2) NOT NULL DEFAULT 1.00 CHECK (confidence_score BETWEEN 0.00 AND 1.00),
    linked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    linked_by UUID REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    UNIQUE (alert_id, vulnerability_id)
);

CREATE INDEX idx_alert_vuln_links_alert_id ON alert_vulnerability_links(alert_id);
CREATE INDEX idx_alert_vuln_links_vuln_id ON alert_vulnerability_links(vulnerability_id);
CREATE INDEX idx_alert_vuln_links_confidence ON alert_vulnerability_links(confidence_score);

-- ============================================================
-- 7. TRIGGERS PARA updated_at AUTOMÁTICO
-- ============================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar a tablas con updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_assets_updated_at BEFORE UPDATE ON assets FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_alerts_updated_at BEFORE UPDATE ON alerts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_notification_configs_updated_at BEFORE UPDATE ON notification_configs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 8. FUNCIÓN PARA LIMPIEZA DE SESIONES EXPIRADAS (job programado)
-- ============================================================

CREATE OR REPLACE FUNCTION cleanup_expired_paseto_sessions()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM paseto_sessions
    WHERE expires_at < NOW() - INTERVAL '30 days'
       OR (revoked_at IS NOT NULL AND revoked_at < NOW() - INTERVAL '90 days');
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;