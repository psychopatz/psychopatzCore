"""Optional provider source declarations remain absent when a provider is disabled."""

from __future__ import annotations

import unittest
from pathlib import Path

from tools.semantic_harness.codebuilder.source_manifest import (
    SourceManifestError,
    load_external_shard_entries,
)


class SourceManifestTests(unittest.TestCase):
    def _manifest(self, optional: bool) -> dict[str, object]:
        entry: dict[str, object] = {
            "domain": "provider",
            "kind": "packs",
            "order": 10,
            "owner": "OptionalProvider",
            "path": "packs/provider.json",
            "sourcePath": "tools/providers/optional/packs/provider.json",
        }
        if optional:
            entry["optional"] = True
        return {"externalShards": [entry]}

    def test_optional_source_is_skipped_without_provider_repository(self) -> None:
        entries = load_external_shard_entries(
            self._manifest(optional=True),
            seen_paths=set(),
            package_repositories={},
            valid_kinds={"packs"},
            validate_id=lambda value, _label: str(value),
        )
        self.assertEqual(entries, [])

    def test_required_source_still_requires_provider_repository(self) -> None:
        with self.assertRaises(SourceManifestError):
            load_external_shard_entries(
                self._manifest(optional=False),
                seen_paths=set(),
                package_repositories={},
                valid_kinds={"packs"},
                validate_id=lambda value, _label: str(value),
            )


if __name__ == "__main__":
    unittest.main()
