-- ============================================================
-- OmniGuard SOC - Tipos ENUM (PostgreSQL)
-- Ejecutado automáticamente al iniciar el contenedor postgres
-- ============================================================

-- Roles de usuario
CREATE TYPE user_role AS ENUM ('ADMIN', 'ANALYST', 'VIEWER');

-- Estado del asset
CREATE TYPE asset_status AS ENUM ('ACTIVE', 'INACTIVE', 'DECOMMISSIONED');

-- Protocolo de puerto
CREATE TYPE port_protocol AS ENUM ('TCP', 'UDP');

-- Severidad de vulnerabilidad
CREATE TYPE vulnerability_severity AS ENUM ('CRITICAL', 'HIGH', 'MEDIUM', 'LOW', 'NONE');

-- Tipo de amenaza (alerta)
CREATE TYPE alert_threat_type AS ENUM (
    'MALWARE_C2',
    'PORT_SCAN',
    'BRUTE_FORCE',
    'DATA_EXFIL',
    'LATERAL_MOVEMENT',
    'ANOMALY',
    'SUSPICIOUS_PROCESS',
    'PRIVILEGE_ESCALATION',
    'CREDENTIAL_ACCESS'
);

-- Severidad de alerta
CREATE TYPE alert_severity AS ENUM ('CRITICAL', 'HIGH', 'MEDIUM', 'LOW', 'INFO');

-- Estado de alerta
CREATE TYPE alert_status AS ENUM ('OPEN', 'IN_PROGRESS', 'RESOLVED', 'FALSE_POSITIVE');

-- Plataforma de notificación
CREATE TYPE notification_platform AS ENUM ('TELEGRAM', 'DISCORD', 'SLACK', 'EMAIL', 'WEBHOOK');

-- Acción de auditoría
CREATE TYPE audit_action AS ENUM ('CREATE', 'UPDATE', 'DELETE', 'STATUS_CHANGE', 'LOGIN', 'LOGOUT', 'PASSWORD_CHANGE', 'ROLE_CHANGE');

-- Protocolo de red
CREATE TYPE network_protocol AS ENUM ('TCP', 'UDP', 'ICMP', 'IGMP', 'GRE', 'ESP', 'AH', 'OSPF', 'VRRP', 'SCTP', 'IPIP', 'IPV6');

-- Categoría de tráfico
CREATE TYPE traffic_category AS ENUM (
    'web',
    'resolucion_dns',
    'sincronizacion_hora',
    'configuracion_red',
    'autenticacion',
    'directorio',
    'gestion_red',
    'registro',
    'acceso_remoto',
    'transferencia_archivos',
    'compartir_archivos',
    'servicios_windows',
    'correo',
    'base_de_datos',
    'descubrimiento',
    'vpn_tunel',
    'voip_streaming',
    'iot',
    'administracion_contenedores',
    'sospechoso',
    'anonimizacion',
    'diagnostico_red',
    'reconocimiento',
    'tunel',
    'enrutamiento',
    'transporte_alternativo',
    'multicast',
    'desconocido'
);

-- Nivel de riesgo
CREATE TYPE risk_level AS ENUM ('LOW', 'MEDIUM', 'HIGH');