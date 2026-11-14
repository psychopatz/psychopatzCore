"""Focused S9H1 tests for WorkspaceCatalog (Port A) and ConvoCatalog (Port B)."""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[3]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.semantic_harness.codebuilder import CONVO_ENGINE_SCHEMA
from tools.semantic_harness.codebuilder.convo_catalog import (
    _FILE_SUMMARY_CACHE,
    _INDEX_CACHE,
    ConvoCatalog,
)
from tools.semantic_harness.codebuilder.errors import CompileError
from tools.semantic_harness.codebuilder.generation_ownership import (
    HOOMANS_OWNER,
    OwnerConfigurationError,
)
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.semantic_harness.codebuilder.workspace_catalog import (
    WorkspaceCatalog,
    WorkspaceResolutionError,
)


def _write_json(path: Path, payload: dict) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return path


def _family(owner: str, namespace: str, family_id: str, **extra: object) -> dict:
    doc: dict = {
        "schema": CONVO_ENGINE_SCHEMA,
        "kind": "dialogue",
        "namespace": namespace,
        "id": family_id,
        "owner": owner,
        "say": {"EN": f"{family_id} line"},
    }
    doc.update(extra)
    return doc


class WorkspaceAndConvoCatalogTests(unittest.TestCase):
    def test_explicit_override_beats_sibling_discovery_and_fixes_hoomans_routing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            core = base / "psychopatzCore"
            sibling_hoomans = base / "ProjectHoomans"
            explicit_hoomans = base / "overrides/CustomHoomans"

            _write_json(
                core / "tools/semantic_harness/provider.json",
                {
                    "schema": "semantic.provider_manifest.v2",
                    "providerID": "PsychopatzCore",
                    "displayName": "Core",
                    "providers": [{"providerID": "PsychopatzCore", "displayName": "Core"}],
                },
            )
            _write_json(
                core / "tools/semantic_harness/codebuilder/sources/conversation/manifest.json",
                {
                    "schema": "pnc.conversation.manifest.v1",
                    "defaultOwner": "PsychopatzCore",
                    "shards": [],
                    "sourceProfiles": {"seed": {"owner": "PsychopatzCore", "name": "Seed", "version": "1"}},
                },
            )
            _write_json(
                core / "tools/semantic_harness/codebuilder/sources/conversation/dialogue/social/core_one.json",
                _family("PsychopatzCore", "social", "core_one"),
            )

            for repo, fid in ((sibling_hoomans, "sib_one"), (explicit_hoomans, "exp_one")):
                _write_json(
                    repo / "tools/providers/pnc/provider.json",
                    {
                        "schema": "semantic.provider_manifest.v2",
                        "providerID": "ProjectHoomans",
                        "displayName": "Hoomans",
                        "providers": [{"providerID": "ProjectHoomans", "displayName": "Hoomans"}],
                        "conversationSources": ["tools/providers/pnc/codebuilder/sources/conversation/manifest.json"],
                    },
                )
                _write_json(
                    repo / "tools/providers/pnc/codebuilder/sources/conversation/manifest.json",
                    {"schema": "pnc.conversation.manifest.v1", "defaultOwner": "ProjectHoomans", "shards": []},
                )
                _write_json(
                    repo / f"tools/providers/pnc/codebuilder/sources/conversation/dialogue/social/{fid}.json",
                    _family("ProjectHoomans", "social", fid),
                )

            service = SemanticLabAuthoringService(
                core,
                core_repository=core,
                hoomans_repository=explicit_hoomans,
            )
            self.assertEqual(service.package_repositories[HOOMANS_OWNER], explicit_hoomans.resolve())
            self.assertEqual(service.workspace_snapshot.repository_for(HOOMANS_OWNER), explicit_hoomans.resolve())
            ids = {item["canonicalID"] for item in service.list_convo_engine_families()}
            self.assertEqual(ids, {"social.core_one", "social.exp_one"})
            self.assertNotIn("social.sib_one", ids)

    def test_future_mod_provider_manifest_discovered_without_core_branches(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            core = base / "psychopatzCore"
            future_mod = base / "FutureFactionMod"
            _write_json(
                core / "tools/semantic_harness/provider.json",
                {
                    "schema": "semantic.provider_manifest.v2",
                    "providerID": "PsychopatzCore",
                    "displayName": "Core",
                    "providers": [{"providerID": "PsychopatzCore", "displayName": "Core"}],
                },
            )
            _write_json(
                core / "tools/semantic_harness/codebuilder/sources/conversation/manifest.json",
                {"schema": "pnc.conversation.manifest.v1", "defaultOwner": "PsychopatzCore", "shards": []},
            )
            _write_json(
                future_mod / "tools/providers/faction/provider.json",
                {
                    "schema": "semantic.provider_manifest.v2",
                    "providerID": "FutureFaction",
                    "displayName": "Future Faction Mod",
                    "providers": [
                        {
                            "providerID": "FutureFaction",
                            "displayName": "Future Faction Mod",
                            "capabilities": ["faction.dialogue"],
                            "materializationModes": ["physical"],
                            "runtimeModules": ["FutureFaction"],
                        }
                    ],
                    "conversationSources": ["tools/providers/faction/codebuilder/sources/conversation/manifest.json"],
                },
            )
            _write_json(
                future_mod / "tools/providers/faction/codebuilder/sources/conversation/manifest.json",
                {"schema": "pnc.conversation.manifest.v1", "defaultOwner": "FutureFaction", "shards": []},
            )
            _write_json(
                future_mod / "tools/providers/faction/codebuilder/sources/conversation/dialogue/faction/recruit.json",
                _family("FutureFaction", "faction", "recruit"),
            )

            snapshot = WorkspaceCatalog.discover(core, core_repository=core)
            self.assertEqual(snapshot.repository_for("FutureFaction"), future_mod.resolve())
            catalog = ConvoCatalog(snapshot)
            page = catalog.query(owner="FutureFaction")
            self.assertEqual(page["total"], 1)
            self.assertEqual(page["items"][0]["canonicalID"], "faction.recruit")
            self.assertEqual(page["items"][0]["owner"], "FutureFaction")
            self.assertIn("FutureFaction/ConvoEngine/Dialogue/Faction", page["items"][0]["generatedModules"])

    def test_required_unresolved_owner_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            core = Path(tmp) / "core_only"
            core.mkdir(parents=True, exist_ok=True)
            with self.assertRaises((WorkspaceResolutionError, CompileError, OwnerConfigurationError)):
                WorkspaceCatalog.discover(
                    core,
                    core_repository=core,
                    required_owners=("ProjectHoomans", "DTCommon"),
                    allow_sibling_discovery=False,
                )

    def test_convo_catalog_cache_impact_and_on_demand_load(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            core = base / "core_repo"
            dlg = core / "tools/semantic_harness/codebuilder/sources/conversation/dialogue/social"
            _write_json(core / "tools/semantic_harness/codebuilder/sources/conversation/manifest.json", {
                "schema": "pnc.conversation.manifest.v1",
                "defaultOwner": "PsychopatzCore",
                "shards": [],
            })
            _write_json(dlg / "target.json", _family("PsychopatzCore", "social", "target"))
            _write_json(
                dlg / "caller.json",
                _family("PsychopatzCore", "social", "caller", after={"goto": "social.target"}),
            )

            _FILE_SUMMARY_CACHE.clear()
            _INDEX_CACHE.clear()
            snapshot = WorkspaceCatalog.discover(core, core_repository=core, allow_sibling_discovery=False)
            catalog = ConvoCatalog(snapshot)

            first = catalog.query(query="target")
            self.assertEqual(first["total"], 1)
            item = first["items"][0]
            self.assertEqual(item["incomingReferenceCount"], 1)
            self.assertEqual(item["locales"], ["EN"])
            self.assertNotIn("say", item)

            # Subsequent query hits cache without re-reading family JSON files from disk.
            with patch("tools.semantic_harness.codebuilder.convo_catalog._parse_family_summary") as mock_parse:
                second = catalog.query(query="caller")
                mock_parse.assert_not_called()
            self.assertEqual(second["total"], 1)
            self.assertEqual(second["items"][0]["outgoingReferenceCount"], 1)

            impact = catalog.impact("social.target")
            self.assertIsNotNone(impact)
            assert impact is not None
            self.assertEqual(impact["incoming"], ["social.caller"])
            self.assertFalse(impact["safeToDeleteOrRename"])

            loaded = catalog.get_family("social.caller")
            self.assertIsNotNone(loaded)
            assert loaded is not None
            self.assertEqual(loaded["document"]["say"], {"EN": "caller line"})

    def test_gui_service_audit_and_codebuilder_agree_on_live_workspace_catalog(self) -> None:
        from tools.semantic_harness.codebuilder.convo_engine_s6m8_audit import (
            discover_convo_engine_repositories,
        )

        hoomans_root = ROOT.parent / "ProjectHoomans"
        dt_root = ROOT.parent / "DynamicTrading"
        if not hoomans_root.is_dir() or not dt_root.is_dir():
            self.skipTest("Sibling participant repositories unavailable")

        discovered = discover_convo_engine_repositories(ROOT)
        svc = SemanticLabAuthoringService(ROOT, core_repository=ROOT)
        self.assertEqual(discovered["PsychopatzCore"], svc.workspace_snapshot.repository_for("PsychopatzCore"))
        self.assertEqual(discovered["ProjectHoomans"], svc.workspace_snapshot.repository_for("ProjectHoomans"))
        self.assertEqual(discovered["DTCommon"], svc.workspace_snapshot.repository_for("DTCommon"))

        from tools.semantic_harness.codebuilder.convo_engine_studio_trace import (
            list_convo_engine_families as trace_list_families,
        )

        catalog_ids = {item["canonicalID"] for item in svc.convo_catalog.list_summaries()}
        service_ids = {item["canonicalID"] for item in svc.list_convo_engine_families()}
        trace_ids = {item["canonicalID"] for item in trace_list_families(svc)}
        self.assertGreaterEqual(len(catalog_ids), 500)
        self.assertEqual(catalog_ids, service_ids)
        self.assertEqual(service_ids, trace_ids)


if __name__ == "__main__":
    unittest.main()
