CREATE SCHEMA IF NOT EXISTS iam;
CREATE SCHEMA IF NOT EXISTS assets;
CREATE SCHEMA IF NOT EXISTS alerts;

CREATE TABLE IF NOT EXISTS iam.users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    display_name VARCHAR(200) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT users_status CHECK (status IN ('active', 'disabled'))
);

CREATE TABLE IF NOT EXISTS assets.network_assets (
    id BIGSERIAL PRIMARY KEY,
    ip_address INET NOT NULL UNIQUE,
    hostname VARCHAR(255),
    first_seen_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    CONSTRAINT network_assets_status CHECK (status IN ('active', 'inactive', 'unknown'))
);

CREATE TABLE IF NOT EXISTS assets.services (
    id BIGSERIAL PRIMARY KEY,
    asset_id BIGINT NOT NULL REFERENCES assets.network_assets(id) ON DELETE CASCADE,
    port SMALLINT NOT NULL,
    protocol VARCHAR(10) NOT NULL DEFAULT 'TCP',
    app_protocol VARCHAR(100) NOT NULL DEFAULT 'Desconocido',
    first_seen_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (asset_id, port, protocol),
    CONSTRAINT services_port CHECK (port BETWEEN 1 AND 65535),
    CONSTRAINT services_protocol CHECK (protocol IN ('TCP', 'UDP'))
);

CREATE TABLE IF NOT EXISTS alerts.events (
    id BIGSERIAL PRIMARY KEY,
    rule VARCHAR(50) NOT NULL,
    severity VARCHAR(10) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    source_ip INET NOT NULL,
    destination_ip INET NOT NULL,
    destination_port SMALLINT,
    protocol VARCHAR(20),
    app_protocol VARCHAR(100),
    raw_event JSONB NOT NULL,
    detected_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT alert_events_severity CHECK (severity IN ('MEDIUM', 'HIGH')),
    CONSTRAINT alert_events_destination_port CHECK (
        destination_port IS NULL OR destination_port BETWEEN 1 AND 65535
    )
);

CREATE INDEX IF NOT EXISTS idx_network_assets_last_seen
    ON assets.network_assets(last_seen_at);

CREATE INDEX IF NOT EXISTS idx_services_asset
    ON assets.services(asset_id);

CREATE INDEX IF NOT EXISTS idx_alert_events_detected_at
    ON alerts.events(detected_at);

CREATE INDEX IF NOT EXISTS idx_alert_events_source_ip
    ON alerts.events(source_ip);

CREATE INDEX IF NOT EXISTS idx_alert_events_severity
    ON alerts.events(severity);
