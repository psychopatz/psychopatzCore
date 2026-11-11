from __future__ import annotations

import io
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from tools.semantic_harness.testing import doctor


class _Worker:
    scenario: dict[str, object] | None = None

    def __init__(self, scenario: dict[str, object], *, config: object) -> None:
        type(self).scenario = scenario
        self.config = config

    def __enter__(self) -> "_Worker":
        return self

    def __exit__(self, *_args: object) -> None:
        return None

    def ping(self) -> dict[str, str]:
        return {"type": "pong"}

    def capabilities(self) -> dict[str, str]:
        return {"type": "capabilities"}


class DoctorTests(unittest.TestCase):
    def test_doctor_uses_core_default_scenario_and_worker_dispatch(self) -> None:
        repository = Path(tempfile.mkdtemp())
        config = SimpleNamespace()
        output = io.StringIO()

        with (
            patch.object(doctor, "discover_core_repository", return_value=repository),
            patch.object(
                doctor,
                "discover_lua",
                return_value=Path("/usr/bin/lua5.3"),
            ),
            patch.object(doctor, "probe_lua", return_value=(True, "test Lua")),
            patch.object(doctor.HarnessConfig, "discover", return_value=config),
            patch.object(doctor, "LuaSemanticWorker", _Worker),
            redirect_stdout(output),
        ):
            result = doctor.run_doctor(
                repository=repository,
                core_repository=repository,
                json_output=True,
            )

        self.assertEqual(result, 0)
        self.assertIsNotNone(_Worker.scenario)
        self.assertTrue(
            {"player", "npc", "world", "conversation", "runtime"}
            <= set(_Worker.scenario or {})
        )


if __name__ == "__main__":
    unittest.main()
