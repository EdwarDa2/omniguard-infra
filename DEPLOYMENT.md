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
