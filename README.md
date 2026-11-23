# omniguard-infra

Infraestructura local de OmniGuard SOC con Docker Compose.

## Servicios

- Redis: bus `network_events`
- PostgreSQL: almacenamiento futuro de IAM, activos y alertas
- Analizador Python: consume eventos y detecta amenazas
- Sensor C++: captura tráfico de red y publica eventos

Telegram no forma parte de esta integración.

## Inicio rápido

```bash
docker compose up --build
```

Verificar Redis:

```bash
docker compose exec redis redis-cli ping
docker compose exec redis redis-cli SUBSCRIBE network_events
```

Detener y conservar datos de PostgreSQL:

```bash
docker compose down
```

Detener y eliminar volúmenes locales:

```bash
docker compose down -v
```

## PostgreSQL

El contenedor crea los esquemas `iam`, `assets` y `alerts` al inicializar por
primera vez el volumen `postgres-data`.

Variables requeridas en `.env`:

- `POSTGRES_DB`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `POSTGRES_PORT`

No publiques el puerto PostgreSQL fuera del servidor de despliegue.

## Sincronización NVD

El servicio `cve-sync` consulta la API NVD 2.0 únicamente para los CPE registrados
en `assets.services.cpe_name`.

Variables requeridas o opcionales:

- `NVD_API_KEY`: opcional, aumenta el límite de consultas.
- `NVD_BASE_URL`: endpoint NVD 2.0.
- `CVE_SYNC_INTERVAL_SECONDS`: intervalo de sincronización.

El cruce exacto requiere que el activo registre `cpe_name` y, opcionalmente,
`product_version`. El proyecto no usa otra fuente CVE.

## Persistencia del analizador

El analizador guarda en PostgreSQL:

- Activos origen y destino detectados en `assets.network_assets`.
- Servicios destino en `assets.services`.
- Alertas MEDIUM y HIGH en `alerts.events`.

PostgreSQL debe ser saludable antes de iniciar el analizador. Si la base está
temporalmente fuera, el analizador registrará el error y seguirá escuchando Redis.
