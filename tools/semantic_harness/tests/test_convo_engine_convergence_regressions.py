"""S9H0 regression-lock tests for Semantic Harness ConvoEngine convergence.

These tests pin reproduced S9 harness defects and invariants before S9H1-S9H6
refactor the authoring/discovery/simulation/build authorities. Tests decorated
with ``@unittest.expectedFailure`` lock currently broken behavior and are
un-decorated as each owning S9 phase resolves the underlying defect.
"""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path
from typing import Any
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[3]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.semantic_harness.codebuilder import CONVO_ENGINE_SCHEMA
from tools.semantic_harness.codebuilder.convo_engine_authoring import apply_family_patch
from tools.semantic_harness.codebuilder.convo_engine_integrity_audit import (
    audit_convo_engine_workspace,
)
from tools.semantic_harness.codebuilder.conversation_compiler import (
    compile_conversation_sources,
)
from tools.semantic_harness.codebuilder.conversation_health import (
    conversation_affected_closure,
)
from tools.semantic_harness.codebuilder.errors import CompileError
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.semantic_harness.studio.convo_engine_authoring_pane import (
    ConvoEngineAuthoringPane,
)
from tools.semantic_harness.studio.source_explorer_pane import (
    CanonicalSourceExplorerPane,
)


class _FakeVar:
    def __init__(self, value: str = "") -> None:
        self._value = value

    def get(self) -> str:
        return self._value

    def set(self, value: Any) -> None:
        self._value = str(value)


class _FakeWidget:
    def __init__(self, *_args: Any, **_kwargs: Any) -> None:
        self._items: list[str] = []
        self._selection: list[int] = []
        self._text = ""
        self._config: dict[str, Any] = {}

    def grid(self, *_args: Any, **_kwargs: Any) -> None:
        return None

    def pack(self, *_args: Any, **_kwargs: Any) -> None:
        return None

    def bind(self, *_args: Any, **_kwargs: Any) -> None:
        return None

    def add(self, *_args: Any, **_kwargs: Any) -> None:
        return None

    def rowconfigure(self, *_args: Any, **_kwargs: Any) -> None:
        return None

    def columnconfigure(self, *_args: Any, **_kwargs: Any) -> None:
        return None

    def configure(self, **kwargs: Any) -> None:
        self._config.update(kwargs)

    def yview(self, *_args: Any, **_kwargs: Any) -> None:
        return None

    def set(self, *_args: Any, **_kwargs: Any) -> None:
        return None

    def delete(self, start: Any, end: Any = None) -> None:
        if end == "end" and start in {0, "1.0"}:
            self._items.clear()
            self._selection.clear()
            self._text = ""

    def insert(self, index: Any, value: str) -> None:
        if index == "end":
            self._items.append(value)
        else:
            self._text += value

    def get(self, *_args: Any) -> str:
        return self._text

    def size(self) -> int:
        return len(self._items)

    def selection_set(self, index: int) -> None:
        self._selection = [index]

    def curselection(self) -> tuple[int, ...]:
        return tuple(self._selection)


class _FakeTk:
    StringVar = _FakeVar
    Listbox = _FakeWidget


class _FakeTtk:
    Frame = _FakeWidget
    LabelFrame = _FakeWidget
    Label = _FakeWidget
    Entry = _FakeWidget
    Button = _FakeWidget
    Combobox = _FakeWidget
    Scrollbar = _FakeWidget
    Notebook = _FakeWidget
    PanedWindow = _FakeWidget


class _FakeMessageBox:
    def askyesno(self, *_args: Any) -> bool:
        return True


def _write_json(path: Path, payload: dict[str, Any]) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return path


def _sample_family(
    *,
    owner: str,
    namespace: str,
    family_id: str,
    after: dict[str, Any] | None = None,
    when: dict[str, Any] | None = None,
    extra: dict[str, Any] | None = None,
) -> dict[str, Any]:
    doc: dict[str, Any] = {
        "schema": CONVO_ENGINE_SCHEMA,
        "kind": "dialogue",
        "namespace": namespace,
        "id": family_id,
        "owner": owner,
        "participants": {"speaker": ["participant"], "addressee": ["participant"]},
        "invoke": {"intent": "GREET"},
        "affordance": {"label": f"Label {family_id}"},
        "say": f"Say {family_id}.",
        "reply": {"acknowledged": {"say": f"Reply {family_id}."}},
    }
    if after is not None:
        doc["after"] = after
    if when is not None:
        doc["when"] = when
    if extra:
        doc.update(extra)
    return doc


def _setup_three_repo_workspace(base: Path) -> dict[str, Path]:
    core_repo = base / "core_repo"
    hoomans_repo = base / "isolated_adopters" / "hoomans_repo"
    dt_repo = base / "isolated_adopters" / "dt_repo"

    _write_json(
        core_repo / "tools/semantic_harness/provider.json",
        {
            "schema": "semantic.provider_manifest.v2",
            "providerID": "PsychopatzCore",
            "displayName": "PsychopatzCore",
            "repositoryKind": "core",
            "providers": [
                {
                    "providerID": "PsychopatzCore",
                    "displayName": "PsychopatzCore",
                    "repositoryKind": "core",
                    "capabilities": ["semantic.parse", "semantic.ir", "semantic.conversation"],
                    "materializationModes": ["none", "abstract", "physical"],
                    "optional": False,
                    "runtimeModules": ["PsychopatzCore"],
                }
            ],
        },
    )
    _write_json(
        core_repo / "tools/semantic_harness/codebuilder/sources/conversation/manifest.json",
        {
            "schema": "pnc.conversation.manifest.v1",
            "defaultOwner": "PsychopatzCore",
            "registryOwner": "PsychopatzCore",
            "version": 1,
            "shards": [],
            "sourceRoots": [
                {
                    "path": "dialogue",
                    "kind": "convo_engine",
                    "domain": "general",
                    "order": 3003,
                    "owner": "PsychopatzCore",
                    "domainFromSubdir": True,
                }
            ],
            "sourceProfiles": {
                "conversation.source.psychopatzcore.seed": {
                    "owner": "PsychopatzCore",
                    "name": "Seed",
                    "version": "1",
                    "contentLicense": "Core test fixture",
                }
            },
        },
    )
    _write_json(
        core_repo / "tools/semantic_harness/codebuilder/sources/conversation/dialogue/social/core_greet.json",
        _sample_family(owner="PsychopatzCore", namespace="social", family_id="core_greet"),
    )
    (core_repo / "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine").mkdir(
        parents=True, exist_ok=True
    )

    _write_json(
        hoomans_repo / "tools/providers/pnc/provider.json",
        {
            "schema": "semantic.provider_manifest.v2",
            "providerID": "ProjectHoomans",
            "displayName": "PNC",
            "providers": [
                {
                    "providerID": "ProjectHoomans",
                    "displayName": "Project Hoomans",
                    "repositoryKind": "project_hoomans",
                    "requires": ["PsychopatzCore"],
                    "capabilities": ["semantic.conversation", "semantic.interaction"],
                    "materializationModes": ["physical"],
                    "optional": True,
                    "runtimeModules": ["ProjectHoomans"],
                }
            ],
            "conversationManifest": "tools/providers/pnc/codebuilder/sources/conversation/manifest.json",
        },
    )
    _write_json(
        hoomans_repo / "tools/providers/pnc/codebuilder/sources/conversation/manifest.json",
        {
            "schema": "pnc.conversation.manifest.v1",
            "defaultOwner": "ProjectHoomans",
            "shards": [],
        },
    )
    _write_json(
        hoomans_repo / "tools/providers/pnc/codebuilder/sources/conversation/dialogue/social/pnc_checkin.json",
        _sample_family(owner="ProjectHoomans", namespace="social", family_id="pnc_checkin"),
    )
    (hoomans_repo / "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine").mkdir(
        parents=True, exist_ok=True
    )

    _write_json(
        dt_repo / "tools/providers/dt/provider.json",
        {
            "schema": "semantic.provider_manifest.v2",
            "providerID": "DTCommon",
            "displayName": "Dynamic Trading",
            "providers": [
                {
                    "providerID": "DTCommon",
                    "displayName": "Dynamic Trading common contract",
                    "repositoryKind": "dynamic_trading",
                    "requires": ["PsychopatzCore"],
                    "capabilities": ["trading.conversation"],
                    "materializationModes": ["abstract", "physical"],
                    "optional": True,
                    "runtimeModules": ["DTCommon"],
                }
            ],
            "conversationSources": [
                "tools/providers/dt/codebuilder/sources/conversation/manifest.json"
            ],
        },
    )
    _write_json(
        dt_repo / "tools/providers/dt/codebuilder/sources/conversation/manifest.json",
        {
            "schema": "pnc.conversation.manifest.v1",
            "defaultOwner": "DTCommon",
            "shards": [],
        },
    )
    _write_json(
        dt_repo / "tools/providers/dt/codebuilder/sources/conversation/dialogue/trade/dt_quote.json",
        _sample_family(owner="DTCommon", namespace="trade", family_id="dt_quote"),
    )
    (dt_repo / "Contents/mods/DTCommon/common/media/lua/shared/DTCommon/ConvoEngine").mkdir(
        parents=True, exist_ok=True
    )

    return {"core": core_repo, "hoomans": hoomans_repo, "dt": dt_repo}


class ConvoEngineConvergenceRegressionTests(unittest.TestCase):
    def test_01_project_hoomans_new_family_owner_routing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repos = _setup_three_repo_workspace(Path(tmp))
            service = SemanticLabAuthoringService(
                repos["core"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
            )
            self.assertEqual(
                service.package_repositories["ProjectHoomans"],
                repos["hoomans"].resolve(),
            )
            pane = ConvoEngineAuthoringPane(
                _FakeWidget(), _FakeTk, _FakeTtk, _FakeWidget, _FakeMessageBox(), service
            )
            pane.new_family()
            pane._owner_var.set("ProjectHoomans")
            pane._namespace_var.set("social")
            pane._id_var.set("hoomans_routed_family")
            res = pane.write_source()
            self.assertTrue(res.get("ok"), f"Write failed: {res}")
            written = Path(res["sourcePath"]).resolve()
            self.assertIn(repos["hoomans"].resolve(), written.parents)
            self.assertNotIn(repos["core"].resolve(), written.parents)

    def test_02_dt_common_new_family_owner_routing(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repos = _setup_three_repo_workspace(Path(tmp))
            service = SemanticLabAuthoringService(
                repos["core"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
            )
            pane = ConvoEngineAuthoringPane(
                _FakeWidget(), _FakeTk, _FakeTtk, _FakeWidget, _FakeMessageBox(), service
            )
            pane.new_family()
            pane._owner_var.set("DTCommon")
            pane._namespace_var.set("trade")
            pane._id_var.set("dt_routed_family")
            res = pane.write_source()
            self.assertTrue(res.get("ok"), f"Write failed: {res}")
            written = Path(res["sourcePath"]).resolve()
            self.assertIn(repos["dt"].resolve(), written.parents)
            self.assertNotIn(repos["core"].resolve(), written.parents)

    def test_03a_service_stale_source_fingerprint_write_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repos = _setup_three_repo_workspace(Path(tmp))
            service = SemanticLabAuthoringService(
                repos["core"],
                core_repository=repos["core"],
            )
            target = (
                repos["core"]
                / "tools/semantic_harness/codebuilder/sources/conversation/dialogue/social/core_greet.json"
            )
            doc = json.loads(target.read_text(encoding="utf-8"))
            doc["say"] = "Updated greeting."
            res = service.write_convo_engine_source(
                target,
                doc,
                expected_source_fingerprint="stale-fingerprint",
            )
            self.assertFalse(res["ok"])
            self.assertTrue(res.get("stale"))

    def test_03b_pane_stale_source_fingerprint_write_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repos = _setup_three_repo_workspace(Path(tmp))
            service = SemanticLabAuthoringService(
                repos["core"],
                core_repository=repos["core"],
            )
            pane = ConvoEngineAuthoringPane(
                _FakeWidget(), _FakeTk, _FakeTtk, _FakeWidget, _FakeMessageBox(), service
            )
            source_path = Path(pane._current_entry["sourcePath"])
            external = json.loads(source_path.read_text(encoding="utf-8"))
            external["say"] = "External concurrent edit."
            _write_json(source_path, external)

            pane._say_single_var.set("")
            pane._write_json_editor("say", "Stale UI overwrite.")
            res = pane.write_source()
            self.assertFalse(res.get("ok"))
            self.assertEqual(
                json.loads(source_path.read_text(encoding="utf-8"))["say"],
                "External concurrent edit.",
            )

    def test_04a_service_patch_rejects_identity_mutation(self) -> None:
        doc = _sample_family(owner="PsychopatzCore", namespace="social", family_id="alpha")
        with self.assertRaises(CompileError):
            apply_family_patch(doc, {"id": "beta"})
        with self.assertRaises(CompileError):
            apply_family_patch(doc, {"namespace": "trade"})

    def test_04b_pane_identity_edit_does_not_overwrite_old_path(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repos = _setup_three_repo_workspace(Path(tmp))
            service = SemanticLabAuthoringService(
                repos["core"],
                core_repository=repos["core"],
            )
            pane = ConvoEngineAuthoringPane(
                _FakeWidget(), _FakeTk, _FakeTtk, _FakeWidget, _FakeMessageBox(), service
            )
            old_path = Path(pane._current_entry["sourcePath"])
            pane._id_var.set("renamed_core_greet")
            res = pane.write_source()
            # Either rejected in place or moved to new path; never write renamed id into old_path.
            if old_path.is_file():
                on_disk = json.loads(old_path.read_text(encoding="utf-8"))
                self.assertEqual(on_disk["id"], "core_greet")
            else:
                self.assertTrue(res.get("ok"))

    def test_05_delete_and_move_reject_dangling_semantic_references(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repos = _setup_three_repo_workspace(Path(tmp))
            dlg_dir = repos["core"] / "tools/semantic_harness/codebuilder/sources/conversation/dialogue/social"
            target_path = _write_json(
                dlg_dir / "target_topic.json",
                _sample_family(owner="PsychopatzCore", namespace="social", family_id="target_topic"),
            )
            _write_json(
                dlg_dir / "caller_topic.json",
                _sample_family(
                    owner="PsychopatzCore",
                    namespace="social",
                    family_id="caller_topic",
                    after={
                        "goto": "social.target_topic",
                        "recommend": ["social.target_topic"],
                    },
                ),
            )
            service = SemanticLabAuthoringService(
                repos["core"],
                core_repository=repos["core"],
            )
            with self.assertRaises(CompileError):
                moved = service.move_convo_engine_source(
                    target_path,
                    dlg_dir / "renamed_topic.json",
                    family_id="renamed_topic",
                )
                if moved.get("ok"):
                    return
                raise CompileError("rejected")

            pane = ConvoEngineAuthoringPane(
                _FakeWidget(), _FakeTk, _FakeTtk, _FakeWidget, _FakeMessageBox(), service
            )
            idx = next(
                i
                for i, item in enumerate(pane._filtered_families)
                if item["canonicalID"] == "social.target_topic"
            )
            pane._family_list.selection_set(idx)
            pane._family_selected()
            pane.delete_family()
            self.assertTrue(target_path.is_file())

    def test_06_missing_dataset_library_sources_report_not_editable(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repos = _setup_three_repo_workspace(Path(tmp))
            service = SemanticLabAuthoringService(
                repos["core"],
                core_repository=repos["core"],
            )
            sources = service.list_dataset_sources()
            self.assertTrue(sources)
            for row in sources:
                if not row["exists"]:
                    self.assertFalse(row["editable"], f"Missing source {row['id']} advertised editable=True")

    def test_07_missing_workflow_datasets_report_not_ready(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repos = _setup_three_repo_workspace(Path(tmp))
            service = SemanticLabAuthoringService(
                repos["core"],
                core_repository=repos["core"],
            )
            workflows = service.list_workflow_datasets()
            self.assertTrue(workflows)
            for row in workflows:
                if not row["exists"]:
                    self.assertFalse(
                        row["workflowReady"],
                        f"Missing workflow dataset {row['id']} advertised workflowReady=True",
                    )

    def test_08_production_predicate_operators_supported_in_simulation(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repos = _setup_three_repo_workspace(Path(tmp))
            service = SemanticLabAuthoringService(
                repos["core"],
                core_repository=repos["core"],
            )
            doc = _sample_family(
                owner="PsychopatzCore",
                namespace="social",
                family_id="predicate_parity",
                when={
                    "all": [
                        {"path": "actor.isHostile", "op": "falsy"},
                        {"path": "actor.mood", "op": "not_in", "values": ["panicked", "hostile"]},
                        {"path": "actor.tags", "op": "contains", "value": "trusted"},
                        {"path": "actor.tags", "op": "not_contains", "value": "bandit"},
                        {"path": "actor.tags", "op": "contains_any", "values": ["medic", "scout"]},
                        {"path": "actor.tags", "op": "contains_all", "values": ["trusted", "medic"]},
                    ]
                },
            )
            sim = service.simulate_convo_engine_family(
                doc,
                context={
                    "actor": {
                        "isHostile": False,
                        "mood": "calm",
                        "tags": ["trusted", "medic"],
                    }
                },
            )
            self.assertTrue(sim["ok"])
            pred_stage = next(s for s in sim["trace"] if s["stage"] == "predicate")
            self.assertTrue(pred_stage["passed"])

    def test_09_action_contract_discovery_not_hardcoded_to_camp(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repos = _setup_three_repo_workspace(Path(tmp))
            service = SemanticLabAuthoringService(
                repos["core"],
                core_repository=repos["core"],
            )
            contracts = service.list_convo_engine_action_contracts()
            contract_ids = {item["id"] for item in contracts}
            self.assertNotIn("pnc.companion.camp", contract_ids)

    def test_10_studio_and_source_explorer_use_shared_manifest_authority(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repos = _setup_three_repo_workspace(Path(tmp))
            service = SemanticLabAuthoringService(
                repos["core"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
            )
            families = service.list_convo_engine_families()
            ids = {item["canonicalID"] for item in families}
            self.assertIn("social.core_greet", ids)
            self.assertIn("social.pnc_checkin", ids)
            self.assertIn("trade.dt_quote", ids)

            explorer = CanonicalSourceExplorerPane(
                _FakeWidget(), _FakeTk, _FakeTtk, _FakeWidget, service
            )
            explorer_ids = {row.get("canonicalID") or row.get("id") for row in explorer._rows}
            self.assertIn("social.core_greet", explorer_ids)
            self.assertIn("social.pnc_checkin", explorer_ids)

    def test_11_deterministic_audit_does_not_write_to_live_repository(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repos = _setup_three_repo_workspace(Path(tmp))
            write_targets: list[Path] = []
            import tools.semantic_harness.codebuilder.build as build_mod

            real_write = build_mod.write_conversation_output

            def _spy_write(repository: Path, *args: Any, **kwargs: Any) -> Any:
                out_repos = kwargs.get("output_repositories")
                if out_repos:
                    for dest in out_repos.values():
                        write_targets.append(Path(dest).expanduser().resolve())
                else:
                    write_targets.append(Path(repository).expanduser().resolve())
                written = real_write(repository, *args, **kwargs)
                write_targets.extend(Path(p).expanduser().resolve() for p in written)
                return written

            with patch.object(build_mod, "write_conversation_output", side_effect=_spy_write):
                report = audit_convo_engine_workspace(
                    repos["core"],
                    hoomans_repository=repos["hoomans"],
                    dynamic_trading_repository=repos["dt"],
                    check_determinism=True,
                )
            self.assertTrue(report["determinism"]["checked"])
            self.assertTrue(report["determinism"].get("isolated"))
            self.assertGreater(report["determinism"].get("fileCount", 0), 0)
            self.assertTrue(write_targets)
            live_roots = {
                repos["core"].resolve(),
                repos["hoomans"].resolve(),
                repos["dt"].resolve(),
            }
            for target in write_targets:
                for live in live_roots:
                    self.assertFalse(
                        target == live or target.is_relative_to(live),
                        f"Determinism audit wrote inside live repository: {target} under {live}",
                    )

    def test_12a_affected_closure_is_bounded(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repos = _setup_three_repo_workspace(Path(tmp))
            dlg_dir = repos["core"] / "tools/semantic_harness/codebuilder/sources/conversation/dialogue/social"
            for idx in range(10):
                _write_json(
                    dlg_dir / f"extra_{idx}.json",
                    _sample_family(
                        owner="PsychopatzCore",
                        namespace="social",
                        family_id=f"extra_{idx}",
                        after={"recommend": ["social.core_greet"]},
                    ),
                )
            model = compile_conversation_sources(repos["core"])
            closure = conversation_affected_closure(model, [], "social.core_greet", limit=4)
            self.assertIsNotNone(closure)
            self.assertLessEqual(len(closure["closureIDs"]), 4)
            self.assertTrue(closure["truncated"])

    def test_12b_agent_facing_workspace_and_catalog_operations_are_bounded(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repos = _setup_three_repo_workspace(Path(tmp))
            service = SemanticLabAuthoringService(
                repos["core"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
            )
            self.assertTrue(hasattr(service, "describe_workspace"))
            ws = service.describe_workspace()
            self.assertIn("providers", ws)
            self.assertTrue(hasattr(service, "query_convo_catalog"))
            page = service.query_convo_catalog(query="social", limit=2)
            self.assertLessEqual(len(page["items"]), 2)
            for item in page["items"]:
                self.assertNotIn("say", item)
                self.assertNotIn("reply", item)

    def test_13_unknown_future_fields_survive_editor_round_trip(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repos = _setup_three_repo_workspace(Path(tmp))
            dlg_dir = repos["core"] / "tools/semantic_harness/codebuilder/sources/conversation/dialogue/social"
            family_doc = _sample_family(
                owner="PsychopatzCore",
                namespace="social",
                family_id="future_roundtrip",
                extra={
                    "target": {"type": "entity.person"},
                    "metadata": {"futureExtension": {"tier": 2, "flags": ["alpha"]}},
                },
            )
            path = _write_json(dlg_dir / "future_roundtrip.json", family_doc)
            service = SemanticLabAuthoringService(
                repos["core"],
                core_repository=repos["core"],
            )
            pane = ConvoEngineAuthoringPane(
                _FakeWidget(), _FakeTk, _FakeTtk, _FakeWidget, _FakeMessageBox(), service
            )
            idx = next(
                i
                for i, item in enumerate(pane._filtered_families)
                if item["canonicalID"] == "social.future_roundtrip"
            )
            pane._family_list.selection_set(idx)
            pane._family_selected()
            # Simulate an older editor encountering a future top-level field in memory.
            pane._document["futureProtocolHint"] = {"version": 9}
            pane._write_json_editor("say", "Updated say text.")
            edited = pane._form_document()
            self.assertEqual(edited["metadata"]["futureExtension"], {"tier": 2, "flags": ["alpha"]})
            self.assertEqual(edited["target"], {"type": "entity.person"})
            self.assertEqual(edited["futureProtocolHint"], {"version": 9})

            # Valid compiler-supported fields survive write/reload round trip.
            res = service.edit_convo_engine_family(
                path,
                {"say": "Updated say text."},
                write=True,
            )
            self.assertTrue(res["ok"])
            reloaded = json.loads(path.read_text(encoding="utf-8"))
            self.assertEqual(reloaded["metadata"]["futureExtension"], {"tier": 2, "flags": ["alpha"]})
            self.assertEqual(reloaded["target"], {"type": "entity.person"})


if __name__ == "__main__":
    unittest.main()
