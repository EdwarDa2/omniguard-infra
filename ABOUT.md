# Acerca de omniguard-infra

## Descripción General

`omniguard-infra` concentra la infraestructura como código, orquestación de contenedores y sincronización de inteligencia de amenazas de la plataforma **OmniGuard SOC**. Define mediante **Docker Compose** la topología aislada de red que interconecta el bus de mensajería **Redis 7 Alpine**, el motor relacional **PostgreSQL 16 Alpine** (con particionamiento lógico en los esquemas `iam`, `assets` y `alerts`) y los microservicios del ecosistema.

Asimismo, integra el servicio especializado `cve-sync`, encargado de consultar de manera automatizada la API REST 2.0 del **NIST National Vulnerability Database (NVD)** para enriquecer los activos detectados con sus respectivas vulnerabilidades CVE y puntuaciones de severidad CVSS.

## Contexto del Proyecto

* **Plataforma:** OmniGuard SOC (Security Operations Center Distribuido)
* **Capa Arquitectónica:** Infraestructura, Base de Datos, Bus de Eventos y Enriquecimiento NVD
* **Tecnologías Principales:** Docker, Docker Compose, PostgreSQL 16 Alpine, Redis 7 Alpine, Python (`cve_sync.py`), NIST NVD API 2.0
* **Licencia:** MIT License
* **Institución:** Universidad Politécnica de Chiapas — Ingeniería en Tecnologías de la Información e Innovación Digital
* **Autores:** Edwar Daniel Gonzalez Hernandez, Andres Eduardo Gonzalez Ruiz

---

## Metadatos para la sección "About" de GitHub

Copiar y pegar estos valores en el panel lateral derecho (icono de engranaje en **About**) del repositorio en GitHub:

* **Description:**
  `Infraestructura contenerizada y orquestacion Docker Compose para OmniGuard SOC. Incluye PostgreSQL 16, Redis 7 y el servicio cve-sync conectado a la API NIST NVD 2.0.`
* **Topics:**
  `docker`, `docker-compose`, `postgresql`, `redis`, `cve`, `nist-nvd`, `infrastructure`, `cybersecurity`, `omniguard`
