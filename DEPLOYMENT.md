# Despliegue web — OmniGuard Infra

Consulte el plan maestro en el repositorio central:

[WEB-DEPLOYMENT-PLAN.md](../WEB-DEPLOYMENT-PLAN.md)

## Rol

Contiene Redis, PostgreSQL, analizador alternativo, sensor C++, cve-sync y scripts de inicialización.

## Variables

```text
POSTGRES_DB
POSTGRES_USER
POSTGRES_PASSWORD
REDIS_PORT
REDIS_CHANNEL
ANALYZER_ARGS
ANALYZER_REDIS_HOST
SENSOR_REDIS_HOST
INTERFACE
BPF_FILTER
NVD_API_KEY
NVD_BASE_URL
CVE_SYNC_INTERVAL_SECONDS
SCAN_CORE_API_URL
INTERNAL_API_TOKEN
SCAN_COMMANDS_CHANNEL
SCAN_ALLOWED_TARGETS
SCAN_TIMEOUT_SECONDS
SCAN_CONCURRENCY
SCAN_MAX_PORTS
```

## Persistencia

PostgreSQL usa el volumen `postgres-data`.

## Producción

- Redis y PostgreSQL deben permanecer internos.
- El sensor debe tener acceso real a la interfaz que inspeccionará.
- Crear respaldos automáticos de PostgreSQL.

## Inicio

```powershell
docker compose up -d --build
```

El worker de escaneo activo es opcional; requiere una Core API accesible desde
Docker y un token interno configurado:

```powershell
docker compose --profile active-scan up -d --build scan-worker
```

`SCAN_ALLOWED_TARGETS` debe contener solo IPs literales autorizadas del propio
equipo. Al ejecutarlo en Docker debe configurarse explícitamente la IPv4 propia
del host; `127.0.0.1` apuntaría al contenedor del worker.
