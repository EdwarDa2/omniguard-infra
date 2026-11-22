CREATE SCHEMA IF NOT EXISTS nvd;

ALTER TABLE assets.services
    ADD COLUMN IF NOT EXISTS cpe_name VARCHAR(500),
    ADD COLUMN IF NOT EXISTS product_version VARCHAR(100);

CREATE TABLE IF NOT EXISTS nvd.cve_records (
    cve_id VARCHAR(25) PRIMARY KEY,
    description TEXT,
    cvss_version VARCHAR(10),
    cvss_score NUMERIC(3,1),
    cvss_severity VARCHAR(20),
    published_at TIMESTAMPTZ,
    last_modified_at TIMESTAMPTZ,
    nvd_json JSONB NOT NULL,
    synced_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS nvd.cpe_matches (
    cve_id VARCHAR(25) NOT NULL REFERENCES nvd.cve_records(cve_id) ON DELETE CASCADE,
    cpe_name VARCHAR(500) NOT NULL,
    PRIMARY KEY (cve_id, cpe_name)
);

CREATE TABLE IF NOT EXISTS nvd.asset_cve_matches (
    asset_id BIGINT NOT NULL REFERENCES assets.network_assets(id) ON DELETE CASCADE,
    service_id BIGINT NOT NULL REFERENCES assets.services(id) ON DELETE CASCADE,
    cve_id VARCHAR(25) NOT NULL REFERENCES nvd.cve_records(cve_id) ON DELETE CASCADE,
    cpe_name VARCHAR(500) NOT NULL,
    matched_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (service_id, cve_id)
);

CREATE INDEX IF NOT EXISTS idx_services_cpe_name
    ON assets.services(cpe_name);

CREATE INDEX IF NOT EXISTS idx_asset_cve_matches_asset
    ON nvd.asset_cve_matches(asset_id);

CREATE INDEX IF NOT EXISTS idx_asset_cve_matches_cve
    ON nvd.asset_cve_matches(cve_id);

CREATE INDEX IF NOT EXISTS idx_cve_records_synced_at
    ON nvd.cve_records(synced_at);
