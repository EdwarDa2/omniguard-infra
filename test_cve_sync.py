import unittest

from cve_sync import cvss_metric, cpe_names, english_description


class CveSyncParserTests(unittest.TestCase):
    def test_description_english(self):
        cve = {
            "descriptions": [
                {"lang": "es", "value": "Descripcion"},
                {"lang": "en", "value": "English description"},
            ]
        }
        self.assertEqual(english_description(cve), "English description")

    def test_cvss31_metric(self):
        cve = {
            "metrics": {
                "cvssMetricV31": [
                    {
                        "cvssData": {
                            "version": "3.1",
                            "baseScore": 9.8,
                            "baseSeverity": "CRITICAL",
                        }
                    }
                ]
            }
        }
        self.assertEqual(cvss_metric(cve), ("3.1", 9.8, "CRITICAL"))

    def test_extract_nested_cpe_names(self):
        cve = {
            "configurations": [
                {
                    "nodes": [
                        {
                            "cpeMatch": [
                                {
                                    "criteria": "cpe:2.3:a:openssh:openssh:9.2:*:*:*:*:*:*:*"
                                }
                            ]
                        }
                    ]
                }
            ]
        }
        self.assertEqual(
            cpe_names(cve),
            ["cpe:2.3:a:openssh:openssh:9.2:*:*:*:*:*:*:*"],
        )


if __name__ == "__main__":
    unittest.main()
