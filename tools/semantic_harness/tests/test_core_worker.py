from __future__ import annotations

import os
import subprocess
import tempfile
import unittest
from pathlib import Path

from tools.semantic_harness.transport.protocol import decode_message, encode_request
from tools.semantic_harness.runtime.config import (
    HarnessConfig,
    build_worker_launch_spec,
)
from tools.semantic_harness.transport.process import LuaProcess


CORE_ROOT = Path(__file__).resolve().parents[3]
WORKER = CORE_ROOT / "tools/semantic_harness/lua/worker.lua"


class CoreWorkerTests(unittest.TestCase):
    def test_dtabstract_loads_live_core_and_dynamic_trading_bootstraps(self) -> None:
        config = HarnessConfig.discover(
            core_repository=CORE_ROOT,
            dynamic_trading_repository=CORE_ROOT.parent / "DynamicTrading",
            preset="dtabstract",
            lua_bin="lua",
        )
        runtime = LuaProcess(build_worker_launch_spec(config))
        try:
            hello = runtime.start()
            self.assertEqual(
                hello["providers"],
                ["PsychopatzCore", "DTCommon", "DTAbstract"],
            )
            self.assertEqual(
                [
                    entry["providerID"]
                    for entry in hello["runtimeBootstraps"]["entries"]
                ],
                ["PsychopatzCore", "DTCommon", "DTAbstract"],
            )
            self.assertEqual(
                hello["providerAdapters"][0]["providerID"],
                "DTAbstract",
            )
        finally:
            runtime.close()

    def test_core_worker_boots_without_adopters(self) -> None:
        process = subprocess.Popen(
            ["lua", str(WORKER), str(CORE_ROOT)],
            cwd=CORE_ROOT,
            env={**os.environ, "SEMANTIC_HARNESS_CORE_REPOSITORY": str(CORE_ROOT)},
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        assert process.stdin is not None
        assert process.stdout is not None
        assert process.stderr is not None
        try:
            hello = decode_message(process.stdout.readline())
            self.assertTrue(hello["ok"])
            self.assertEqual(hello["profile"], "core")
            self.assertEqual(hello["providers"], ["PsychopatzCore"])
            self.assertEqual(hello["materializationMode"], "none")
            self.assertIn("harness.runtime_state", hello["capabilities"])
            self.assertIn("harness.value_projection", hello["capabilities"])
            self.assertIn("harness.session_envelope", hello["capabilities"])
            self.assertIn("harness.working_world", hello["capabilities"])
            self.assertIn("harness.router", hello["capabilities"])
            self.assertIn("harness.semantic_execution", hello["capabilities"])
            self.assertEqual(
                hello["sessionEnvelope"]["schema"],
                "semantic.harness_session_envelope.v1",
            )
            self.assertEqual(hello["workingWorld"]["maxPatches"], 512)
            self.assertTrue(hello["router"]["dispatch"])
            self.assertEqual(
                hello["semanticExecution"]["schema"],
                "semantic.harness_execution.v1",
            )
            self.assertEqual(
                hello["semanticExecution"]["materializationMode"],
                "none",
            )

            process.stdin.write(encode_request("request-1", "PING"))
            process.stdin.flush()
            pong = decode_message(process.stdout.readline())
            self.assertEqual(pong["type"], "pong")
            self.assertEqual(pong["id"], "request-1")

            process.stdin.write(encode_request("request-2", "CAPABILITIES"))
            process.stdin.flush()
            capabilities = decode_message(process.stdout.readline())
            self.assertEqual(capabilities["providers"], ["PsychopatzCore"])

            process.stdin.write(encode_request("request-3", "QUIT"))
            process.stdin.flush()
            goodbye = decode_message(process.stdout.readline())
            self.assertEqual(goodbye["type"], "goodbye")
        finally:
            if process.poll() is None:
                process.terminate()
            process.wait(timeout=2)
            stderr = process.stderr.read().decode("utf-8")
            process.stdin.close()
            process.stdout.close()
            process.stderr.close()
            self.assertEqual(stderr, "")

    def test_core_worker_accepts_external_profile_metadata(self) -> None:
        environment = {
            **os.environ,
            "SEMANTIC_HARNESS_CORE_REPOSITORY": str(CORE_ROOT),
            "SEMANTIC_HARNESS_PROFILE": "dtabstract",
            "SEMANTIC_HARNESS_PROVIDER_IDS": (
                "PsychopatzCore,DTCommon,DTAbstract"
            ),
            "SEMANTIC_HARNESS_MATERIALIZATION_MODE": "abstract",
        }
        process = subprocess.Popen(
            ["lua", str(WORKER), str(CORE_ROOT)],
            cwd=CORE_ROOT,
            env=environment,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        assert process.stdin is not None
        assert process.stdout is not None
        assert process.stderr is not None
        try:
            hello = decode_message(process.stdout.readline())
            self.assertTrue(hello["ok"])
            self.assertEqual(hello["profile"], "dtabstract")
            self.assertEqual(
                hello["providers"],
                ["PsychopatzCore", "DTCommon", "DTAbstract"],
            )
            self.assertEqual(hello["materializationMode"], "abstract")
            self.assertEqual(
                hello["semanticExecution"]["materializationMode"],
                "abstract",
            )
            process.stdin.write(encode_request("request-1", "QUIT"))
            process.stdin.flush()
            goodbye = decode_message(process.stdout.readline())
            self.assertEqual(goodbye["profile"], "dtabstract")
        finally:
            if process.poll() is None:
                process.terminate()
            process.wait(timeout=2)
            stderr = process.stderr.read().decode("utf-8")
            process.stdin.close()
            process.stdout.close()
            process.stderr.close()
            self.assertEqual(stderr, "")

    def test_core_worker_loads_external_provider_adapter(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            module = Path(directory) / "fixture_provider.lua"
            module.write_text(
                """
local Provider = {}

function Provider.New(SemanticExecution, context, callbacks)
    return SemanticExecution.new({
        providerID = "FixtureProvider",
        materializationMode = "abstract",
        capabilities = { "fixture.provider" },
        context = context,
        callbacks = callbacks,
    })
end

return Provider
""".lstrip(),
                encoding="utf-8",
            )
            environment = {
                **os.environ,
                "SEMANTIC_HARNESS_CORE_REPOSITORY": str(CORE_ROOT),
                "SEMANTIC_HARNESS_PROFILE": "fixture",
                "SEMANTIC_HARNESS_PROVIDER_IDS": (
                    "PsychopatzCore,FixtureProvider"
                ),
                "SEMANTIC_HARNESS_MATERIALIZATION_MODE": "abstract",
                "SEMANTIC_HARNESS_PROVIDER_MODULE_PATHS": (
                    f"{directory}/?.lua"
                ),
                "SEMANTIC_HARNESS_PROVIDER_MODULES": "fixture_provider",
                "SEMANTIC_HARNESS_EXECUTION_PROVIDER_ID": "FixtureProvider",
            }
            process = subprocess.Popen(
                ["lua", str(WORKER), str(CORE_ROOT)],
                cwd=CORE_ROOT,
                env=environment,
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            assert process.stdin is not None
            assert process.stdout is not None
            assert process.stderr is not None
            try:
                hello = decode_message(process.stdout.readline())
                self.assertEqual(hello["executionProviderID"], "FixtureProvider")
                self.assertEqual(
                    hello["providerAdapters"][0]["providerID"],
                    "FixtureProvider",
                )
                process.stdin.write(
                    encode_request(
                        "request-1",
                        "SEMANTIC_PROVIDER",
                        {"operation": "submitText", "text": "hello"},
                    )
                )
                process.stdin.flush()
                response = decode_message(process.stdout.readline())
                self.assertEqual(response["type"], "semantic_provider")
                self.assertEqual(response["providerID"], "FixtureProvider")
                self.assertEqual(response["result"]["text"], "hello")
                process.stdin.write(encode_request("request-2", "QUIT"))
                process.stdin.flush()
                self.assertEqual(
                    decode_message(process.stdout.readline())["type"],
                    "goodbye",
                )
            finally:
                if process.poll() is None:
                    process.terminate()
                process.wait(timeout=2)
                stderr = process.stderr.read().decode("utf-8")
                process.stdin.close()
                process.stdout.close()
                process.stderr.close()
                self.assertEqual(stderr, "")


if __name__ == "__main__":
    unittest.main()
