from __future__ import annotations

import sys
import tempfile
import textwrap
import unittest
from pathlib import Path
from types import SimpleNamespace

from tools.semantic_harness.transport.process import HarnessError, LuaProcess, WorkerLaunchSpec


CORE_ROOT = Path(__file__).resolve().parents[3]


class ProcessTests(unittest.TestCase):
    def test_launch_spec_accepts_validated_profile_metadata(self) -> None:
        selection = SimpleNamespace(
            profile_id="dtabstract",
            provider_ids=("PsychopatzCore", "DTCommon", "DTAbstract"),
            materialization_mode="abstract",
        )
        spec = WorkerLaunchSpec.from_profile_selection(
            selection,
            lua_bin=Path(sys.executable),
            worker_script=CORE_ROOT / "tools/semantic_harness/lua/worker.lua",
            core_repository=CORE_ROOT,
        )
        self.assertEqual(spec.profile, "dtabstract")
        self.assertEqual(
            spec.neutral_environment(),
            {
                "SEMANTIC_HARNESS_PROFILE": "dtabstract",
                "SEMANTIC_HARNESS_PROVIDER_IDS": (
                    "PsychopatzCore,DTCommon,DTAbstract"
                ),
                "SEMANTIC_HARNESS_MATERIALIZATION_MODE": "abstract",
            },
        )

    def test_launch_spec_carries_optional_provider_loader_metadata(self) -> None:
        spec = WorkerLaunchSpec(
            lua_bin=Path(sys.executable),
            worker_script=CORE_ROOT / "tools/semantic_harness/lua/worker.lua",
            core_repository=CORE_ROOT,
            profile="fixture",
            provider_ids=("PsychopatzCore", "FixtureProvider"),
            materialization_mode="abstract",
            provider_module_paths=("/tmp/fixture/?.lua",),
            provider_modules=("fixture_provider",),
            execution_provider_id="FixtureProvider",
        )
        self.assertEqual(
            spec.neutral_environment(),
            {
                "SEMANTIC_HARNESS_PROFILE": "fixture",
                "SEMANTIC_HARNESS_PROVIDER_IDS": (
                    "PsychopatzCore,FixtureProvider"
                ),
                "SEMANTIC_HARNESS_MATERIALIZATION_MODE": "abstract",
                "SEMANTIC_HARNESS_PROVIDER_MODULE_PATHS": (
                    "/tmp/fixture/?.lua"
                ),
                "SEMANTIC_HARNESS_PROVIDER_MODULES": "fixture_provider",
                "SEMANTIC_HARNESS_EXECUTION_PROVIDER_ID": "FixtureProvider",
            },
        )

    def fake_worker(self, directory: Path) -> Path:
        script = directory / "worker.py"
        script.write_text(
            textwrap.dedent(
                """
                import json
                import sys
                import time

                print(json.dumps({"protocolVersion": 1, "id": "__hello__", "ok": True, "type": "hello", "profile": "test"}), flush=True)
                for line in sys.stdin:
                    request = json.loads(line)
                    if request.get("command") == "SLEEP":
                        time.sleep(0.2)
                    if request.get("command") == "QUIT":
                        print(json.dumps({"protocolVersion": 1, "id": request["id"], "ok": True, "type": "goodbye"}), flush=True)
                        break
                    print(json.dumps({"protocolVersion": 1, "id": request["id"], "ok": True, "type": "echo", "payload": request.get("payload")}), flush=True)
                """
            ).strip()
            + "\n",
            encoding="utf-8",
        )
        return script

    def spec(self, script: Path, **overrides: object) -> WorkerLaunchSpec:
        values: dict[str, object] = {
            "lua_bin": Path(sys.executable),
            "worker_script": script,
            "core_repository": CORE_ROOT,
            "working_directory": CORE_ROOT,
            "profile": "test",
            "worker_arguments": (),
            "startup_timeout": 1.0,
            "request_timeout": 1.0,
            "shutdown_timeout": 0.2,
        }
        values.update(overrides)
        return WorkerLaunchSpec(**values)

    def test_process_correlates_requests(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            script = self.fake_worker(Path(directory))
            runtime = LuaProcess(self.spec(script))
            try:
                hello = runtime.start()
                self.assertEqual(hello["profile"], "test")
                response = runtime.request("ECHO", {"value": 7})
                self.assertEqual(response["payload"]["value"], 7)
            finally:
                runtime.close()

    def test_process_rejects_profile_mismatch(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            script = self.fake_worker(Path(directory))
            runtime = LuaProcess(self.spec(script, profile="core"))
            with self.assertRaisesRegex(HarnessError, "profile mismatch"):
                runtime.start()
            runtime.close()

    def test_process_timeout_contains_worker(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            script = self.fake_worker(Path(directory))
            runtime = LuaProcess(self.spec(script, request_timeout=0.02))
            try:
                runtime.start()
                with self.assertRaises(HarnessError):
                    runtime.request("SLEEP")
                self.assertEqual(runtime.state, "FAILED")
            finally:
                runtime.close()


if __name__ == "__main__":
    unittest.main()
