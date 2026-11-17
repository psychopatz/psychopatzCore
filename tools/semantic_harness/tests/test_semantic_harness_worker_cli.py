"""Real-worker CLI acceptance for session, language, doctor, observatory, and fixture runner flags."""

from __future__ import annotations

from contextlib import redirect_stdout
import io
import json
from pathlib import Path
import tempfile
import unittest

from tools.semantic_harness.entrypoints import app
from tools.semantic_harness.entrypoints.cli import _parser, cli
from tools.semantic_harness.runtime.worker import LuaSemanticWorker  # noqa: F401  # routes into real_provider_worker

CORE_ROOT = Path(__file__).resolve().parents[3]
HOOMANS_ROOT = CORE_ROOT.parent / "ProjectHoomans"
DT_ROOT = CORE_ROOT.parent / "DynamicTrading"


def _run_cli(argv: list[str]) -> tuple[int, list[dict]]:
    arguments = _parser().parse_args(argv)
    output = io.StringIO()
    with redirect_stdout(output):
        rc = cli(arguments)
    records = [json.loads(line) for line in output.getvalue().splitlines() if line.strip()]
    return rc, records


@unittest.skipUnless(HOOMANS_ROOT.is_dir(), "ProjectHoomans sibling repository is required")
class SemanticHarnessWorkerCliTests(unittest.TestCase):
    def _base_args(self) -> list[str]:
        args = [
            "--no-gui",
            "--preset",
            "pnc",
            "--core-repository",
            str(CORE_ROOT),
            "--repository",
            str(HOOMANS_ROOT),
            "--startup-timeout",
            "20",
        ]
        if DT_ROOT.is_dir():
            args.extend(["--dynamic-trading-repository", str(DT_ROOT)])
        return args

    def test_cli_worker_ping_capabilities_snapshot_input_language_and_doctor(self) -> None:
        base = self._base_args()
        rc_ping, ping_rows = _run_cli([*base, "--ping", "--jsonl"])
        self.assertEqual(rc_ping, 0)
        self.assertEqual(ping_rows[0].get("type"), "pong")

        rc_caps, caps_rows = _run_cli([*base, "--capabilities", "--jsonl"])
        self.assertEqual(rc_caps, 0)
        self.assertEqual(caps_rows[0].get("type"), "capabilities")

        rc_snap, snap_rows = _run_cli([*base, "--snapshot", "--jsonl"])
        self.assertEqual(rc_snap, 0)
        self.assertEqual(snap_rows[0].get("type"), "snapshot")

        rc_turn, turn_rows = _run_cli([
            *base,
            "--language",
            "TL",
            "--input",
            "hello",
            "--jsonl",
        ])
        self.assertEqual(rc_turn, 0)
        self.assertTrue(any(row.get("ok") for row in turn_rows), turn_rows)

        doc_out = io.StringIO()
        with redirect_stdout(doc_out):
            rc_doc = app.main([*base, "--doctor-json"])
        doc_rows = [json.loads(line) for line in doc_out.getvalue().splitlines() if line.strip()]
        self.assertEqual(rc_doc, 0)
        self.assertEqual(len(doc_rows), 1)
        self.assertTrue(doc_rows[0].get("ok"), doc_rows[0])

    def test_cli_runs_declarative_semantic_test_fixture_and_observatory_flags(self) -> None:
        base = self._base_args()
        with tempfile.TemporaryDirectory() as tmp:
            fixture_path = Path(tmp) / "smoke_case.json"
            fixture_path.write_text(
                json.dumps({
                    "schemaVersion": 1,
                    "suite": "s10r2_smoke",
                    "cases": [{
                        "id": "greeting_turn",
                        "description": "Smoke greeting case",
                        "turns": [{
                            "input": "hello",
                            "expect": {"accepted": True},
                        }],
                    }],
                }),
                encoding="utf-8",
            )
            rc_tests, test_rows = _run_cli([
                "--repository",
                str(HOOMANS_ROOT),
                "--core-repository",
                str(CORE_ROOT),
                "--preset",
                "pnc",
                "--startup-timeout",
                "20",
                "--run-semantic-tests",
                "--semantic-test-file",
                str(fixture_path),
                "--jsonl",
            ])
            self.assertEqual(rc_tests, 0, test_rows)
            self.assertTrue(test_rows[0]["ok"])
            self.assertEqual(test_rows[0]["passed"], 1)

        for flag, arg in (
            ("--response-translation-coverage", "semantic.accept"),
            ("--response-codebuilder-lineage", "semantic.accept"),
            ("--inspect-response-turn", "hello"),
        ):
            with self.subTest(flag=flag):
                rc, rows = _run_cli([*base, flag, arg, "--jsonl"])
                self.assertEqual(rc, 0, (flag, rows))
                self.assertTrue(rows and rows[0].get("ok", True), (flag, rows))


if __name__ == "__main__":
    unittest.main()
