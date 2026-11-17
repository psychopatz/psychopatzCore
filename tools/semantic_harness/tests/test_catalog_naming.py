"""Tests for source-to-runtime module naming."""

from __future__ import annotations

from pathlib import Path
import unittest

from tools.semantic_harness.codebuilder.catalog_naming import (
    ModuleNameRegistry,
    source_owned_module,
)


class CatalogNamingTests(unittest.TestCase):
    def test_no_hardcoded_live_workspace_paths(self) -> None:
        forbidden = "/home/psychopatz/" + "Zomboid/Workshop"
        root = Path(__file__).resolve().parents[1]
        offenders: list[str] = []
        for path in sorted(root.rglob("*.py")):
            if "__pycache__" in path.parts or ".venv" in path.parts:
                continue
            if forbidden in path.read_text(encoding="utf-8"):
                offenders.append(str(path.relative_to(root)))
        self.assertEqual(offenders, [], f"Hardcoded live workspace paths: {offenders}")

    def test_responses_root_is_not_repeated_in_generated_module(self) -> None:
        module = source_owned_module(
            "PNC/Semantics/Generated/Conversation/Responses",
            "responses/common/social.json",
            ModuleNameRegistry(),
        )
        self.assertEqual(
            module,
            "PNC/Semantics/Generated/Conversation/Responses/Common/Social",
        )


if __name__ == "__main__":
    unittest.main()
