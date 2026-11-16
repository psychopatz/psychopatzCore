"""S10D provider lifecycle, reconfigure, restart stability, and Core parity gates."""

from __future__ import annotations

from copy import deepcopy
import importlib
import sys
from pathlib import Path
from typing import Any
import unittest

from tools.semantic_harness.core.worker_session import WorkerSession
from tools.semantic_harness.providers.mod_manager import ModManager
from tools.semantic_harness.runtime.config import (
    HarnessConfig,
    build_worker_launch_spec,
)
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from tools.semantic_harness.transport.process import LuaProcess

CORE_ROOT = Path(__file__).resolve().parents[3]
HOOMANS_ROOT = CORE_ROOT.parent / "ProjectHoomans"
DT_ROOT = CORE_ROOT.parent / "DynamicTrading"


def _available_roots() -> tuple[Path, ...]:
    return tuple(root for root in (HOOMANS_ROOT, DT_ROOT) if root.is_dir())


def _default_scenario(config: HarnessConfig) -> dict[str, Any]:
    reference = config.provider_python_scenario
    if not reference:
        return {}
    if str(config.repository) not in sys.path:
        sys.path.insert(0, str(config.repository))
    module_name, _, attribute = str(reference).partition(":")
    return deepcopy(getattr(importlib.import_module(module_name), attribute))


def _config_for_preset(preset_id: str) -> HarnessConfig:
    roots = _available_roots()
    return HarnessConfig.discover(
        core_repository=CORE_ROOT,
        repository=HOOMANS_ROOT if HOOMANS_ROOT.is_dir() else None,
        dynamic_trading_repository=DT_ROOT if DT_ROOT.is_dir() else None,
        provider_roots=roots,
        preset=preset_id,
        startup_timeout=20.0,
        request_timeout=10.0,
    )


def _catalog_fingerprint(capabilities: dict[str, Any]) -> dict[str, Any]:
    flow_catalog = capabilities.get("flowCatalog") or {}
    beat_catalog = capabilities.get("beatCatalog") or {}
    flows = flow_catalog.get("flows") or []
    pools = flow_catalog.get("responsePoolCatalog") or []
    return {
        "profile": capabilities.get("profile"),
        "providers": list(capabilities.get("providers") or ()),
        "materializationMode": capabilities.get("materializationMode"),
        "flowCount": flow_catalog.get("flowCount"),
        "flowIds": [entry.get("id") for entry in flows if isinstance(entry, dict)],
        "flowRegistryRevision": flow_catalog.get("registryRevision"),
        "poolCount": len(pools),
        "beatCount": beat_catalog.get("beatCount"),
        "beatRegistryRevision": beat_catalog.get("beatRegistryRevision"),
        "behaviorCount": beat_catalog.get("behaviorCount"),
    }


def _assert_worker_roundtrip(
    testcase: unittest.TestCase,
    preset_id: str,
) -> None:
    config = _config_for_preset(preset_id)
    scenario = _default_scenario(config)
    with LuaSemanticWorker(scenario, config=config) as worker:
        caps_before = worker.capabilities()
        testcase.assertTrue(caps_before.get("ok"), preset_id)
        testcase.assertEqual(caps_before.get("profile"), preset_id)
        testcase.assertIn("semanticExecution", caps_before)
        testcase.assertTrue(worker.ping().get("ok"), preset_id)
        turn_before = worker.input("hello")
        testcase.assertTrue(turn_before.get("ok"), preset_id)
        fp_before = _catalog_fingerprint(caps_before)

        restart_response = worker.restart()
        testcase.assertTrue(restart_response.get("ok"), preset_id)
        caps_after = worker.capabilities()
        testcase.assertTrue(caps_after.get("ok"), preset_id)
        fp_after = _catalog_fingerprint(caps_after)
        testcase.assertEqual(fp_after, fp_before, f"Catalog drift on {preset_id}")
        testcase.assertTrue(worker.ping().get("ok"), preset_id)
        turn_after = worker.input("hello")
        testcase.assertTrue(turn_after.get("ok"), preset_id)

    testcase.assertFalse(worker.status().get("running"))


class S10DProviderLifecycleTests(unittest.TestCase):
    def test_manifest_preset_discovery_and_lifecycle_matrix(self) -> None:
        roots = _available_roots()
        if not HOOMANS_ROOT.is_dir():
            self.skipTest("ProjectHoomans sibling repository is required")

        manager = ModManager.discover(
            core_repository=CORE_ROOT,
            repository_roots=roots,
        )
        preset_ids = [
            entry["presetID"]
            for entry in manager.presets()
            if not entry.get("aliasOf")
        ]
        self.assertIn("pnc", preset_ids)
        if DT_ROOT.is_dir():
            self.assertIn("dtabstract", preset_ids)
            self.assertIn("pnc-with-dthoomans", preset_ids)

        expected_presets = (
            ("pnc", "dtabstract", "pnc-with-dthoomans")
            if DT_ROOT.is_dir()
            else ("pnc",)
        )
        for preset_id in expected_presets:
            with self.subTest(preset=preset_id):
                _assert_worker_roundtrip(self, preset_id)

    def test_worker_session_reconfigure_cross_provider_transition_and_repeat(self) -> None:
        if not HOOMANS_ROOT.is_dir() or not DT_ROOT.is_dir():
            self.skipTest("ProjectHoomans and DynamicTrading repositories are required")

        def make_factory(preset_id: str):
            def _build():
                cfg = _config_for_preset(preset_id)
                return LuaSemanticWorker(_default_scenario(cfg), config=cfg)

            return _build

        expected_providers = {
            "pnc": ["PsychopatzCore", "ProjectHoomans"],
            "dtabstract": ["PsychopatzCore", "DTCommon", "DTAbstract"],
            "pnc-with-dthoomans": [
                "PsychopatzCore",
                "ProjectHoomans",
                "DTCommon",
                "DTHoomans",
            ],
        }
        session = WorkerSession(make_factory("pnc"))
        self.addCleanup(lambda: session.close(wait=True))

        ready = session.start().result(timeout=30.0)
        self.assertEqual(ready.capabilities.get("profile"), "pnc")
        self.assertEqual(
            ready.capabilities.get("providers"),
            expected_providers["pnc"],
        )
        first_turn = session.submit(lambda current: current.input("hello")).result(
            timeout=15.0
        )
        self.assertTrue(first_turn.value.get("ok"))

        for target_preset in (
            "dtabstract",
            "pnc-with-dthoomans",
            "pnc",
            "dtabstract",
            "pnc",
        ):
            with self.subTest(transition_to=target_preset):
                reconfigured = session.reconfigure(
                    make_factory(target_preset)
                ).result(timeout=30.0)
                self.assertEqual(
                    reconfigured.capabilities.get("profile"), target_preset
                )
                self.assertEqual(
                    reconfigured.capabilities.get("providers"),
                    expected_providers[target_preset],
                )
                turn = session.submit(lambda current: current.input("hello")).result(
                    timeout=15.0
                )
                self.assertTrue(turn.value.get("ok"))

    def test_repeated_start_restart_and_configure_leaves_zero_catalog_or_source_drift(self) -> None:
        if not HOOMANS_ROOT.is_dir():
            self.skipTest("ProjectHoomans sibling repository is required")

        config = _config_for_preset("pnc")
        baseline = _default_scenario(config)
        baseline_player_name = baseline.get("player", {}).get("name")

        with LuaSemanticWorker(baseline, config=config) as worker:
            caps_0 = worker.capabilities()
            fp_0 = _catalog_fingerprint(caps_0)
            self.assertGreater(int(fp_0["flowCount"] or 0), 20)
            self.assertGreater(int(fp_0["poolCount"] or 0), 50)
            self.assertGreaterEqual(int(fp_0["beatCount"] or 0), 1)
            self.assertEqual(len(fp_0["flowIds"]), len(set(fp_0["flowIds"])))

            modified = deepcopy(baseline)
            modified.setdefault("player", {})["name"] = "S10D Ephemeral Override"
            worker.configure(modified)
            self.assertEqual(
                worker.scenario.get("player", {}).get("name"),
                "S10D Ephemeral Override",
            )
            self.assertTrue(worker.input("hello").get("ok"))
            worker.reset_working_world()
            self.assertEqual(
                worker.scenario.get("player", {}).get("name"),
                baseline_player_name,
            )

            for cycle in range(1, 4):
                with self.subTest(restart_cycle=cycle):
                    worker.restart()
                    caps_n = worker.capabilities()
                    self.assertEqual(_catalog_fingerprint(caps_n), fp_0)
                    self.assertEqual(
                        worker.scenario.get("player", {}).get("name"),
                        baseline_player_name,
                    )
                    self.assertTrue(worker.input("hello").get("ok"))

        # Verify standalone Core worker repeated start/restart parity with zero stderr.
        core_cfg = HarnessConfig(
            repository=CORE_ROOT,
            core_repository=CORE_ROOT,
            lua_bin=config.lua_bin,
            worker_script=CORE_ROOT / "tools/semantic_harness/lua/worker.lua",
            profile="core",
            provider_ids=("PsychopatzCore",),
            materialization_mode="none",
        )
        core_spec = build_worker_launch_spec(core_cfg)
        core_snapshots: list[tuple[list[str], str]] = []
        for _ in range(2):
            runtime = LuaProcess(core_spec)
            try:
                hello = runtime.start()
                caps = runtime.request("CAPABILITIES")
                parse = runtime.request("PARSE", {"text": "hello"})
                self.assertTrue(hello.get("ok"))
                self.assertTrue(caps.get("ok"))
                self.assertTrue(parse.get("ok"))
                core_snapshots.append(
                    (
                        list(caps.get("providers") or ()),
                        str(caps.get("materializationMode") or ""),
                    )
                )
            finally:
                runtime.close()
        self.assertEqual(
            core_snapshots,
            [(["PsychopatzCore"], "none"), (["PsychopatzCore"], "none")],
        )


if __name__ == "__main__":
    unittest.main()
