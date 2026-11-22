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
