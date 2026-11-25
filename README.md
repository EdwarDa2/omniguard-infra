# omniguard-infra

Infraestructura local de OmniGuard SOC con Docker Compose.

## Servicios

- Redis: bus `network_events`.
- PostgreSQL: activos, servicios, alertas y caché NVD.
- Analizador Python: detección, persistencia y alertas.
- Worker Python opcional: escaneo TCP limitado a IPs autorizadas.
- Sensor C++: captura del tráfico propio del host, eventos y métricas reales con TTL en Redis.
- `cve-sync`: consulta exclusiva de la API NVD 2.0.

Telegram no forma parte de esta integración.

## Inicio rápido

```bash
docker compose up --build
```

El worker de escaneo se inicia por separado y solo después de configurar el
endpoint interno, el token y las IP propias autorizadas:

```bash
docker compose --profile active-scan up -d --build scan-worker
```

Configura `SCAN_ALLOWED_TARGETS` como una lista de IP literales exactas. Si no
se configura, el perfil falla al iniciar. En Docker, `127.0.0.1` identifica al
contenedor del worker, no al host; configura únicamente la(s) IPv4 propia(s)
del equipo autorizado. El worker rechaza otros destinos y rangos que excedan
`SCAN_MAX_PORTS`. La orden llega por Redis Pub/Sub, por lo que no queda en cola
si el worker no está conectado.

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

## Estado actual

- Redis, PostgreSQL, sensor y analizador están dockerizados.
- El worker de escaneo activo es opcional, con allowlist exacta y perfil Compose separado.
- El sensor captura en modo no promiscuo y añade un filtro BPF para las IP propias de la interfaz.
- Las pruebas C++ se ejecutan durante la construcción del sensor.
- Las tablas `iam`, `assets`, `alerts` y `nvd` existen en PostgreSQL.
- El analizador persiste activos, servicios y alertas.
- El sincronizador NVD consume CPE registrados.
- Discord permanece disponible en el analizador.
- Telegram no forma parte del proyecto.

## Pendiente para el compañero backend

El propietario de `omniguard-core-java` debe implementar:

- API REST para activos, servicios, alertas y CVEs.
- Arquitectura hexagonal estricta.
- PASETO y cookies `HttpOnly`.
- Usuarios, roles y permisos IAM.
- Contrato HTTP para recibir alertas validadas.
- Repositorios JPA para PostgreSQL.

Redis y PostgreSQL no deben exponerse al navegador.

## Pendiente para el compañero frontend

El propietario de `omniguard-frontend-react` debe implementar:

- Dashboard Blue Team.
- Vistas de activos y servicios.
- Alertas MEDIUM/HIGH y filtros.
- Severidad, descripción y CVSS de CVEs.
- Gestión visual de usuarios si el backend la habilita.
- Actualización periódica o tiempo real mediante la API Java.

El frontend no captura tráfico ni accede directamente a Redis/PostgreSQL.
