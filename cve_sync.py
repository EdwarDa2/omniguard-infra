import json
import os
import time
from datetime import datetime

import psycopg
import requests


def english_description(cve):
    for description in cve.get("descriptions", []):
        if description.get("lang") == "en":
            return description.get("value")
    return None


def cvss_metric(cve):
    metrics = cve.get("metrics", {})
    for metric_name in (
        "cvssMetricV40",
        "cvssMetricV31",
        "cvssMetricV30",
        "cvssMetricV2",
    ):
        values = metrics.get(metric_name)
        if values:
            data = values[0]
            if "cvssData" in data:
                cvss = data["cvssData"]
                version = cvss.get("version")
                score = cvss.get("baseScore")
                severity = cvss.get("baseSeverity") or data.get("baseSeverity")
                return version, score, severity
    return None, None, None


def cpe_names(cve):
    names = set()

    def walk(value):
        if isinstance(value, dict):
            criteria = value.get("criteria")
            if criteria:
                names.add(criteria)
            for nested in value.values():
                walk(nested)
        elif isinstance(value, list):
            for nested in value:
                walk(nested)

    walk(cve.get("configurations"))
    return sorted(names)


def nvd_headers():
    headers = {"User-Agent": "OmniGuard-SOC-CVE-Sync/1.0"}
    api_key = os.getenv("NVD_API_KEY", "").strip()
    if api_key:
        headers["apiKey"] = api_key
    return headers


def fetch_cve_page(base_url, cpe_name, start_index=0):
    response = requests.get(
        base_url,
        params={
            "cpeName": cpe_name,
            "startIndex": start_index,
            "resultsPerPage": 2000,
        },
        headers=nvd_headers(),
        timeout=60,
    )
    response.raise_for_status()
    return response.json()


def connect_database():
    return psycopg.connect(
        host=os.getenv("POSTGRES_HOST", "postgres"),
        port=int(os.getenv("POSTGRES_PORT", "5432")),
        dbname=os.getenv("POSTGRES_DB", "omniguard"),
        user=os.getenv("POSTGRES_USER", "omniguard"),
        password=os.getenv("POSTGRES_PASSWORD"),
        connect_timeout=10,
    )


def sync_once():
    base_url = os.getenv(
        "NVD_BASE_URL",
        "https://services.nvd.nist.gov/rest/json/cves/2.0",
    )

    with connect_database() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT id, cpe_name
                FROM assets.services
                WHERE cpe_name IS NOT NULL
                  AND btrim(cpe_name) <> ''
                """
            )
            services = cursor.fetchall()

        for service_id, cpe_name in services:
            start_index = 0
            total_results = None

            while total_results is None or start_index < total_results:
                payload = fetch_cve_page(base_url, cpe_name, start_index)
                total_results = payload.get("totalResults", 0)

                with connection.cursor() as cursor:
                    for item in payload.get("vulnerabilities", []):
                        cve = item["cve"]
                        cve_id = cve["id"]
                        version, score, severity = cvss_metric(cve)

                        cursor.execute(
                            """
                            INSERT INTO nvd.cve_records (
                                cve_id, description, cvss_version, cvss_score,
                                cvss_severity, published_at, last_modified_at, nvd_json
                            )
                            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                            ON CONFLICT (cve_id) DO UPDATE SET
                                description = EXCLUDED.description,
                                cvss_version = EXCLUDED.cvss_version,
                                cvss_score = EXCLUDED.cvss_score,
                                cvss_severity = EXCLUDED.cvss_severity,
                                published_at = EXCLUDED.published_at,
                                last_modified_at = EXCLUDED.last_modified_at,
                                nvd_json = EXCLUDED.nvd_json,
                                synced_at = CURRENT_TIMESTAMP
                            """,
                            (
                                cve_id,
                                english_description(cve),
                                version,
                                score,
                                severity,
                                cve.get("published"),
                                cve.get("lastModified"),
                                json.dumps(cve),
                            ),
                        )

                        for matched_cpe in cpe_names(cve):
                            cursor.execute(
                                """
                                INSERT INTO nvd.cpe_matches (cve_id, cpe_name)
                                VALUES (%s, %s)
                                ON CONFLICT DO NOTHING
                                """,
                                (cve_id, matched_cpe),
                            )

                        cursor.execute(
                            """
                            INSERT INTO nvd.asset_cve_matches (
                                asset_id, service_id, cve_id, cpe_name
                            )
                            SELECT asset_id, %s, %s, %s
                            FROM assets.services
                            WHERE id = %s
                            ON CONFLICT (service_id, cve_id) DO UPDATE
                            SET cpe_name = EXCLUDED.cpe_name,
                                matched_at = CURRENT_TIMESTAMP
                            """,
                            (service_id, cve_id, cpe_name, service_id),
                        )

                connection.commit()
                start_index += payload.get("resultsPerPage", 2000)
                if payload.get("resultsPerPage", 0) == 0:
                    break

                if not os.getenv("NVD_API_KEY"):
                    time.sleep(6)


def main():
    interval = int(os.getenv("CVE_SYNC_INTERVAL_SECONDS", "86400"))
    while True:
        try:
            sync_once()
            print("[CVE-SYNC] Sincronización NVD completada.", flush=True)
        except requests.RequestException as exc:
            print(f"[CVE-SYNC] Error HTTP con NVD: {exc}", flush=True)
        except psycopg.Error as exc:
            print(f"[CVE-SYNC] Error PostgreSQL: {exc}", flush=True)
        except Exception as exc:
            print(f"[CVE-SYNC] Error inesperado: {type(exc).__name__}: {exc}", flush=True)

        time.sleep(interval)


if __name__ == "__main__":
    main()
