from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from semantic_harness.scenario import (
    deep_merge,
    derive_actor_identifier,
    derive_display_name,
    load_json_document,
    save_json_document,
)


class ScenarioDocumentTests(unittest.TestCase):
    def test_deep_merge_does_not_mutate_inputs_and_supports_clear_policy(self) -> None:
        base = {"nested": {"left": 1, "right": 2}, "cleared": {"old": True}}
        override = {"nested": {"right": 3}, "cleared": {}}

        merged = deep_merge(
            base,
            override,
            replace_empty_objects=("cleared",),
        )

        self.assertEqual(merged["nested"], {"left": 1, "right": 3})
        self.assertEqual(merged["cleared"], {})
        self.assertEqual(base["nested"]["right"], 2)

    def test_json_document_round_trip_is_atomic_and_object_only(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "nested" / "scenario.json"
            document = {"schema": "test", "values": {"count": 2}}
            self.assertEqual(save_json_document(path, document), path)
            self.assertEqual(load_json_document(path), document)

    def test_actor_identifiers_are_stable_and_bounded(self) -> None:
        self.assertEqual(derive_display_name("Ada", "Lovelace"), "Ada Lovelace")
        self.assertEqual(
            derive_actor_identifier("npc", "Ada", "Lovelace"),
            "npc_ada_lovelace",
        )
        self.assertEqual(derive_actor_identifier("npc", None, None), "npc_actor")


if __name__ == "__main__":
    unittest.main()
