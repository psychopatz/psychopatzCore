import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from moddata_formatters import detect_format, formatted_value


class ModDataFormatterTests(unittest.TestCase):
    def test_unknown_table_uses_generic_formatter(self):
        info = detect_format("SomeOtherMod_State")
        self.assertEqual(info.key, "generic")
        self.assertFalse(info.specialized)

    def test_project_hoomans_schema_is_detected_without_hiding_table(self):
        info = detect_format("PNC_Core_Global", {"schemaVersion": 15})
        self.assertEqual(info.key, "project_hoomans.directory")
        self.assertEqual(info.schema_version, 15)

    def test_project_hoomans_inventory_projection_labels_compact_indices(self):
        raw = {
            "id": "npcExample_ABCD",
            "inventory": [2, "BASELINE_DELTA", 5, {"seed": 12}, [1, {}, []]],
        }
        formatted = formatted_value("PNC_npcExample_ABCD", raw)
        self.assertEqual(formatted["inventory"]["_format"], "Project Hoomans inventory persistence")
        self.assertEqual(formatted["inventory"]["schema"], 2)
        self.assertEqual(formatted["inventory"]["mode"], "BASELINE_DELTA")
        self.assertEqual(raw["inventory"][0], 2)


if __name__ == "__main__":
    unittest.main()
