"""S9R regression-lock tests for R1-R5 closure and continuity invariants."""

from __future__ import annotations

import json
import re
import sys
import tempfile
import unittest
from pathlib import Path
from typing import Any
from unittest.mock import patch

CORE_ROOT = Path(__file__).resolve().parents[3]
if str(CORE_ROOT) not in sys.path:
    sys.path.insert(0, str(CORE_ROOT))

from tools.semantic_harness.codebuilder.build_planner import BuildPlanner
from tools.semantic_harness.codebuilder.convo_probe import ConvoProbeUnavailableError
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.semantic_harness.studio.convo_engine_authoring_pane import (
    ConvoEngineAuthoringPane,
)


def _write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8", newline="\n")


def _sample_family(*, owner: str, namespace: str, family_id: str) -> dict[str, Any]:
    return {
        "schema": "psychopatz.convo-engine.v1",
        "kind": "dialogue",
        "namespace": namespace,
        "id": family_id,
        "owner": owner,
        "participants": {"speaker": ["participant"], "addressee": ["participant"]},
        "invoke": {"intent": "GREET"},
        "affordance": {"label": f"Label {family_id}"},
        "say": f"Hello from {family_id}.",
        "reply": {"acknowledged": {"say": f"Reply {family_id}."}},
    }


def _build_three_repo_fixture(base: Path) -> dict[str, Path]:
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
        core_repo
        / "tools/semantic_harness/codebuilder/sources/conversation/dialogue/social/core_greet.json",
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
        {"schema": "pnc.conversation.manifest.v1", "defaultOwner": "ProjectHoomans", "shards": []},
    )
    _write_json(
        hoomans_repo
        / "tools/providers/pnc/codebuilder/sources/conversation/dialogue/social/pnc_checkin.json",
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
        {"schema": "pnc.conversation.manifest.v1", "defaultOwner": "DTCommon", "shards": []},
    )
    _write_json(
        dt_repo
        / "tools/providers/dt/codebuilder/sources/conversation/dialogue/trade/dt_quote.json",
        _sample_family(owner="DTCommon", namespace="trade", family_id="dt_quote"),
    )
    (dt_repo / "Contents/mods/DTCommon/common/media/lua/shared/DTCommon/ConvoEngine").mkdir(
        parents=True, exist_ok=True
    )
    return {"core": core_repo, "hoomans": hoomans_repo, "dt": dt_repo}


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


from tools.semantic_harness.tests.convo_engine_test_support import _FakeTreeview


class _FakeTtk:
    Frame = _FakeWidget
    Label = _FakeWidget
    LabelFrame = _FakeWidget
    Entry = _FakeWidget
    Button = _FakeWidget
    Combobox = _FakeWidget
    Scrollbar = _FakeWidget
    Notebook = _FakeWidget
    PanedWindow = _FakeWidget
    Treeview = _FakeTreeview


class _FakeMessageBox:
    @staticmethod
    def askyesno(*_args: Any, **_kwargs: Any) -> bool:
        return True


class _WorkerMissingConvoProbeCapability:
    def is_alive(self) -> bool:
        return True

    def capabilities(self) -> dict[str, Any]:
        # Advertises only the old understated capability, omitting semantic.convo_probe.
        return {"protocolVersion": 1, "capabilities": ["semantic.conversation"]}

    def _request(self, _command: str, _payload: dict[str, Any]) -> dict[str, Any]:
        raise AssertionError("Worker without semantic.convo_probe must fail capability check")


class ConvoEngineStudioContinuityInvariantTests(unittest.TestCase):
    def test_convo_simulate_descriptor_advertises_convo_probe_requirement(self) -> None:
        service = SemanticLabAuthoringService(core_repository=CORE_ROOT)
        try:
            desc = service.operations.describe("convo.simulate")
            self.assertIsNotNone(desc)
            assert desc is not None
            self.assertEqual(desc["requiredCapability"], "semantic.convo_probe")
            self.assertEqual(desc["workerRequirement"], "required")

            # Keep bounded operation vocabulary (12 operations including convo.migrate_schema).
            self.assertEqual(len(service.describe_operations()), 12)

            # A worker without semantic.convo_probe fails closed (no Python fallback).
            service.attach_convo_probe_worker(_WorkerMissingConvoProbeCapability())
            with self.assertRaises(ConvoProbeUnavailableError):
                service.dispatch_operation(
                    "convo.simulate",
                    {
                        "document": _sample_family(
                            owner="PsychopatzCore", namespace="social", family_id="r3"
                        )
                    },
                )
        finally:
            service.close()

    def test_harness_context_owns_build_planner_without_private_registry_factory(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repos = _build_three_repo_fixture(Path(tmp))
            service = SemanticLabAuthoringService(
                repository=repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
            )
            self.assertIsInstance(service.harness.build, BuildPlanner)
            self.assertEqual(
                service.harness.build.workspace.workspace_fingerprint,
                service.workspace_snapshot.workspace_fingerprint,
            )
            self.assertFalse(hasattr(service.operations, "_build_planner"))

            with patch.object(
                service.harness.build,
                "preview",
                wraps=service.harness.build.preview,
            ) as spy_preview:
                preview_res = service.dispatch_operation("convo.build.preview", {"limit": 5})
            self.assertTrue(preview_res["ok"])
            self.assertEqual(spy_preview.call_count, 1)

            with patch.object(
                service.harness.build,
                "apply",
                wraps=service.harness.build.apply,
            ) as spy_apply:
                apply_res = service.dispatch_operation("convo.build.apply", {"limit": 5})
            self.assertTrue(apply_res["ok"])
            self.assertEqual(spy_apply.call_count, 1)

            # Workspace refresh updates the composition-root build port.
            extra = (
                repos["core"]
                / "tools/semantic_harness/codebuilder/sources/conversation/dialogue/social/extra.json"
            )
            _write_json(extra, _sample_family(owner="PsychopatzCore", namespace="social", family_id="extra"))
            refreshed = service.refresh_workspace()
            self.assertEqual(
                service.harness.build.workspace.workspace_fingerprint,
                refreshed.workspace_fingerprint,
            )

    def test_convo_engine_pane_dispatches_canonical_operations(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repos = _build_three_repo_fixture(Path(tmp))
            service = SemanticLabAuthoringService(
                repository=repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
            )
            try:
                dispatched: list[str] = []
                real_dispatch = service.dispatch_operation

                def _spy_dispatch(op_id: str, payload: dict[str, Any] | None = None) -> dict[str, Any]:
                    dispatched.append(op_id)
                    return real_dispatch(op_id, payload)

                with patch.object(service, "dispatch_operation", side_effect=_spy_dispatch):
                    pane = ConvoEngineAuthoringPane(
                        _FakeWidget(), _FakeTk, _FakeTtk, _FakeWidget, _FakeMessageBox, service
                    )
                    self.assertIn("convo.catalog", dispatched)
                    self.assertIn("convo.get", dispatched)

                    dispatched.clear()
                    pane.new_family()
                    self.assertIn("convo.change.preview", dispatched)
                    pane._id_var.set("r5_draft_topic")

                    dispatched.clear()
                    preview_report = pane.preview_record()
                    self.assertTrue(preview_report and preview_report.get("ok"), preview_report)
                    self.assertEqual(dispatched, ["convo.simulate"])

                    dispatched.clear()
                    with patch.object(pane._messagebox, "askyesno", return_value=True):
                        write_report = pane.write_source()
                    self.assertTrue(write_report.get("ok"), write_report)
                    self.assertIn("convo.simulate", dispatched)
                    self.assertIn("convo.change.apply", dispatched)
                    self.assertIn("convo.catalog", dispatched)

                    dispatched.clear()
                    audit_report = pane.run_integrity_audit()
                    self.assertTrue(audit_report.get("ok"), audit_report)
                    self.assertEqual(dispatched, ["convo.audit"])

                    dispatched.clear()
                    with patch.object(pane._messagebox, "askyesno", return_value=True):
                        del_report = pane.delete_family()
                    self.assertTrue(del_report and del_report.get("ok"), del_report)
                    self.assertIn("convo.change.apply", dispatched)

                # Typed convenience wrappers still match OperationRegistry results 1:1.
                cat_op = service.dispatch_operation("convo.catalog", {"limit": 50})
                self.assertEqual(
                    {row["canonicalID"] for row in cat_op["items"]},
                    {row["canonicalID"] for row in service.list_convo_engine_families()},
                )
            finally:
                service.close()

    def test_continuity_docs_have_no_stale_legacy_claims(self) -> None:
        docs_dir = CORE_ROOT / "Docs/semantic_dialogue_language_standard"
        doc_names = (
            "PROGRESS.md",
            "HANDOFF.md",
            "ROADMAP.md",
            "SEMANTIC_HARNESS_AUDIT.md",
            "AGENT_RUNBOOK.md",
            "CONVO_ENGINE.md",
        )
        forbidden_patterns = (
            re.compile(r"S9 implementation has not started", re.IGNORECASE),
            re.compile(r"S9R implementation has not started", re.IGNORECASE),
            re.compile(r"S9R_IMPLEMENTATION_NOT_STARTED", re.IGNORECASE),
            re.compile(r"S9R BOUNDED CLOSURE ACTIVE", re.IGNORECASE),
            re.compile(r"Immediate Next Chunk:\*?\*?\s*S9H0", re.IGNORECASE),
            re.compile(r"Python semantic simulation is current", re.IGNORECASE),
            re.compile(r"direct unsafe ConvoEngine CRUD remains current", re.IGNORECASE),
            re.compile(r"main CLI lacks ConvoEngine", re.IGNORECASE),
            re.compile(r"deterministic auditing still mutates", re.IGNORECASE),
            re.compile(r"PENDING_CORE_S9H", re.IGNORECASE),
        )
        for name in doc_names:
            text = (docs_dir / name).read_text(encoding="utf-8")
            for pattern in forbidden_patterns:
                self.assertIsNone(
                    pattern.search(text),
                    f"Stale pre-S9 statement {pattern.pattern!r} found in {name}",
                )


if __name__ == "__main__":
    unittest.main()
