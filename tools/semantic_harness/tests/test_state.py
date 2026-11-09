from __future__ import annotations

from copy import deepcopy
import unittest

from semantic_harness.state import (
    HarnessWorkingWorld,
    ImportedSourceSnapshot,
    Provenance,
)


class StateContractTests(unittest.TestCase):
    def test_source_is_immutable_and_working_world_is_patchable(self) -> None:
        scenario = {"npc": {"relationship": {"approval": 0}}}
        source = ImportedSourceSnapshot.from_scenario(
            scenario,
            source=Provenance.SAVE,
            source_id="save:slot-1",
        )
        with self.assertRaises(TypeError):
            source.data["npc"]["relationship"]["approval"] = 90  # type: ignore[index]

        working = HarnessWorkingWorld(source)
        working.data["npc"]["relationship"]["approval"] = 90
        patches = working.patches
        self.assertTrue(any(patch["path"].endswith("approval") for patch in patches))
        self.assertTrue(all(
            patch["source"] == Provenance.HARNESS_MUTATION.value
            and patch["baseSource"] == Provenance.SAVE.value
            for patch in patches
        ))
        self.assertEqual(working.reset(), deepcopy(scenario))
        self.assertEqual(working.patches, [])


if __name__ == "__main__":
    unittest.main()
