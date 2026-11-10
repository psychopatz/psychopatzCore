from __future__ import annotations

from pathlib import Path
import unittest

from semantic_harness.process import WorkerLaunchSpec
from semantic_harness.worker import SemanticWorker


class FakeRuntime:
    def __init__(self) -> None:
        self.process = None
        self.started = 0
        self.closed = 0
        self.requests: list[tuple[str, object]] = []

    def start(self) -> dict[str, object]:
        self.started += 1
        return {"ok": True}

    def request(self, command: str, value: object = None) -> dict[str, object]:
        self.requests.append((command, value))
        if command in {"IMPORT_SOURCE", "CONFIG"}:
            payload = value if isinstance(value, dict) else {}
            scenario = payload.get("scenario", payload)
            return {"ok": True, "scenario": scenario}
        return {"ok": True}

    def status(self) -> dict[str, object]:
        return {"state": "RUNNING", "started": self.started}

    def close(self) -> None:
        self.closed += 1


class SemanticWorkerTests(unittest.TestCase):
    def _spec(self) -> WorkerLaunchSpec:
        return WorkerLaunchSpec(
            lua_bin=Path("/usr/bin/lua"),
            worker_script=Path("/tmp/worker.lua"),
            core_repository=Path("/tmp/core"),
            working_directory=Path("/tmp"),
        )

    def test_core_owns_source_world_lifecycle_and_restart(self) -> None:
        runtime = FakeRuntime()
        worker = SemanticWorker(
            {"npc": {"name": "Mara"}},
            self._spec(),
            activity_log=object(),  # type: ignore[arg-type]
            import_source_on_start=True,
            runtime_factory=lambda _spec, _log: runtime,
        )
        self.addCleanup(worker.close)

        self.assertEqual(runtime.started, 1)
        self.assertEqual(runtime.requests[0][0], "IMPORT_SOURCE")
        worker.configure({"npc": {"name": "Mara", "mood": "calm"}})
        self.assertEqual(worker.scenario["npc"]["mood"], "calm")
        worker.reset_working_world()
        worker.restart()

        self.assertEqual(runtime.started, 2)
        self.assertGreaterEqual(
            sum(command == "IMPORT_SOURCE" for command, _ in runtime.requests),
            2,
        )

    def test_adopter_hooks_are_the_only_scenario_policy_boundary(self) -> None:
        runtime = FakeRuntime()

        class AdapterWorker(SemanticWorker):
            def _normalize_scenario(self, scenario):
                value = dict(scenario)
                value.setdefault("provider", "adapter")
                return value

            def _validate_scenario(self, scenario):
                if scenario.get("provider") != "adapter":
                    raise ValueError("adapter marker required")

        worker = AdapterWorker(
            {},
            self._spec(),
            activity_log=object(),  # type: ignore[arg-type]
            import_source_on_start=True,
            runtime_factory=lambda _spec, _log: runtime,
        )
        self.addCleanup(worker.close)

        self.assertEqual(worker.scenario["provider"], "adapter")
        with self.assertRaises(ValueError):
            worker.configure({"provider": "other"})


if __name__ == "__main__":
    unittest.main()
