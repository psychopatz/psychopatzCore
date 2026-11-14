"""S9H6 tests: BuildPlanner caching, isolated determinism checks, and reentrant locking."""

from __future__ import annotations

import json
import sys
import tempfile
import threading
import unittest
from pathlib import Path
from typing import Any
from unittest.mock import patch

CORE_ROOT = Path(__file__).resolve().parents[3]
if str(CORE_ROOT) not in sys.path:
    sys.path.insert(0, str(CORE_ROOT))

from tools.semantic_harness.codebuilder.convo_transaction import workspace_generation_lock
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService


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
        {"schema": "pnc.conversation.manifest.v1", "defaultOwner": "ProjectHoomans", "shards": []},
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
        {"schema": "pnc.conversation.manifest.v1", "defaultOwner": "DTCommon", "shards": []},
    )
    _write_json(
        dt_repo / "tools/providers/dt/codebuilder/sources/conversation/dialogue/trade/dt_quote.json",
        _sample_family(owner="DTCommon", namespace="trade", family_id="dt_quote"),
    )
    (dt_repo / "Contents/mods/DTCommon/common/media/lua/shared/DTCommon/ConvoEngine").mkdir(
        parents=True, exist_ok=True
    )
    return {"core": core_repo, "hoomans": hoomans_repo, "dt": dt_repo}


class ConvoEngineS9H6BuildPlannerTests(unittest.TestCase):
    def test_build_planner_preview_effect_free_caches_and_clears_on_apply(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repos = _build_three_repo_fixture(Path(tmp))
            service = SemanticLabAuthoringService(
                repository=repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
            )
            import tools.semantic_harness.codebuilder.build_planner as bp_mod

            real_render = bp_mod.render_conversation_runtime_plan
            render_calls = 0

            def _counting_render(model: dict[str, Any]) -> Any:
                nonlocal render_calls
                render_calls += 1
                return real_render(model)

            with patch.object(bp_mod, "render_conversation_runtime_plan", side_effect=_counting_render):
                first = service.dispatch_operation("convo.build.preview", {"limit": 5})
                second = service.dispatch_operation("convo.build.preview", {"limit": 5})

            self.assertTrue(first["ok"])
            self.assertTrue(first["previewOnly"])
            self.assertTrue(first["effectFree"])
            self.assertEqual(first["writes"], [])
            self.assertLessEqual(len(first["plannedModules"]), 5)
            self.assertEqual(first["modelFingerprint"], second["modelFingerprint"])
            self.assertEqual(render_calls, 1)

            # Preview left live generated Registry.lua absent.
            core_registry = (
                repos["core"]
                / "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine/Registry.lua"
            )
            hoomans_convo_dir = (
                repos["hoomans"]
                / "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine"
            )
            self.assertFalse(core_registry.exists())
            self.assertEqual(list(hoomans_convo_dir.rglob("*.lua")), [])

            applied = service.dispatch_operation("convo.build.apply", {"limit": 5})
            self.assertTrue(applied["ok"])
            self.assertFalse(applied["previewOnly"])
            self.assertFalse(applied["effectFree"])
            self.assertGreater(applied["writtenCount"], 0)
            self.assertLessEqual(len(applied["writes"]), 5)
            self.assertTrue(core_registry.is_file())
            self.assertTrue(any(hoomans_convo_dir.rglob("*.lua")))
            self.assertEqual(service.operations._build_planner()._plan_cache, {})

    def test_isolated_determinism_preview_and_audit_preserve_live_sentinel_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repos = _build_three_repo_fixture(Path(tmp))
            sentinels = [
                repos["core"]
                / "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine/Sentinel.lua",
                repos["hoomans"]
                / "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/Sentinel.lua",
                repos["dt"]
                / "Contents/mods/DTCommon/common/media/lua/shared/DTCommon/ConvoEngine/Sentinel.lua",
            ]
            before_state: dict[Path, tuple[int, bytes]] = {}
            for path in sentinels:
                path.parent.mkdir(parents=True, exist_ok=True)
                content = f"-- live sentinel for {path.name}\nreturn {{ ok = true }}\n".encode("utf-8")
                path.write_bytes(content)
                before_state[path] = (path.stat().st_mtime_ns, content)

            service = SemanticLabAuthoringService(
                repository=repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
            )
            preview = service.dispatch_operation(
                "convo.build.preview",
                {"checkDeterminism": True},
            )
            self.assertTrue(preview["ok"])
            self.assertTrue(preview["determinism"]["checked"])
            self.assertTrue(preview["determinism"]["isolated"])
            self.assertEqual(preview["determinism"]["diffs"], [])
            self.assertGreater(preview["determinism"]["fileCount"], 0)

            audit = service.dispatch_operation(
                "convo.audit",
                {"checkDeterminism": True, "requireAllOwners": True},
            )
            self.assertTrue(audit["determinism"]["checked"])
            self.assertTrue(audit["determinism"]["isolated"])
            self.assertEqual(audit["determinism"]["diffs"], [])
            self.assertGreater(audit["determinism"]["fileCount"], 0)

            for path, (mtime_ns, raw) in before_state.items():
                self.assertTrue(path.is_file())
                self.assertEqual(path.read_bytes(), raw)
                self.assertEqual(path.stat().st_mtime_ns, mtime_ns)

    def test_concurrent_generation_lock_and_reentrancy_under_worker_threads(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            repos = _build_three_repo_fixture(Path(tmp))
            service = SemanticLabAuthoringService(
                repository=repos["hoomans"],
                core_repository=repos["core"],
                hoomans_repository=repos["hoomans"],
                dynamic_trading_repository=repos["dt"],
            )
            # Initial apply ensures generated layout exists before concurrent workers start.
            service.dispatch_operation("convo.build.apply", {})

            # Same-thread nested lock acquisition must not deadlock.
            with workspace_generation_lock(service.workspace_snapshot):
                with workspace_generation_lock(service.workspace_snapshot):
                    pass

            barrier = threading.Barrier(4)
            errors: list[BaseException] = []
            results: list[tuple[str, dict[str, Any]]] = []
            lock = threading.Lock()

            def _worker(op_id: str, payload: dict[str, Any]) -> None:
                try:
                    barrier.wait(timeout=5)
                    res = service.dispatch_operation(op_id, payload)
                    with lock:
                        results.append((op_id, res))
                except BaseException as exc:  # pragma: no cover - test failure diagnostic
                    with lock:
                        errors.append(exc)

            threads = [
                threading.Thread(
                    target=_worker,
                    args=("convo.build.preview", {"checkDeterminism": True}),
                ),
                threading.Thread(
                    target=_worker,
                    args=("convo.audit", {"checkDeterminism": True, "requireAllOwners": True}),
                ),
                threading.Thread(target=_worker, args=("convo.build.apply", {})),
                threading.Thread(
                    target=_worker,
                    args=("convo.audit", {"checkDeterminism": True, "requireAllOwners": True}),
                ),
            ]
            for thread in threads:
                thread.start()
            for thread in threads:
                thread.join(timeout=20)

            self.assertEqual(errors, [])
            self.assertEqual(len(results), 4)
            for op_id, res in results:
                self.assertTrue(res.get("ok"), (op_id, res))
                if "determinism" in res:
                    self.assertTrue(res["determinism"]["isolated"])
                    self.assertEqual(res["determinism"]["diffs"], [])


if __name__ == "__main__":
    unittest.main()
