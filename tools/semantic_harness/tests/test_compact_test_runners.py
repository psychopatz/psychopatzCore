"""Unit tests for compact flushed unittest and declarative semantic fixture runners."""

from __future__ import annotations

from contextlib import redirect_stdout
import io
import json
from pathlib import Path
import tempfile
import threading
import types
import unittest
from unittest.mock import patch

from tools.semantic_harness.testing import cli as testing_cli
from tools.semantic_harness.testing import compact_unittest
from tools.semantic_harness.testing.compact_unittest import (
    _partition_module_shards,
    discover_module_suites,
    main as compact_unittest_main,
)
from tools.semantic_harness.testing.executor import execute_cases_parallel
from tools.semantic_harness.testing.loader import SemanticCase


class _ProgressFakeWorker:
    def __init__(self, _scenario: dict | None = None, **_kwargs: object) -> None:
        self.imported = 0

    def __enter__(self) -> "_ProgressFakeWorker":
        return self

    def __exit__(self, *_args: object) -> None:
        return None

    def import_source(self, _scenario: dict) -> dict:
        self.imported += 1
        return {"ok": True}

    def input(self, text: str) -> dict:
        return {
            "type": "turn",
            "accepted": text != "fail_me",
            "observation": {"text": text},
            "trace": [],
            "toolCalls": [],
        }


class CompactUnittestRunnerTests(unittest.TestCase):
    def _write_module(self, root: Path, name: str, body: str) -> None:
        (root / f"{name}.py").write_text(body, encoding="utf-8")

    def test_discovers_sorted_modules_runs_heartbeats_and_class_teardown(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            teardown_marker = root / "teardown.log"
            self._write_module(
                root,
                "test_beta",
                """
import time
import unittest

class BetaTests(unittest.TestCase):
    def test_slow_pass(self):
        time.sleep(0.06)
        self.assertTrue(True)
""",
            )
            self._write_module(
                root,
                "test_alpha",
                f"""
import unittest
from pathlib import Path

class AlphaTests(unittest.TestCase):
    @classmethod
    def tearDownClass(cls):
        Path({str(teardown_marker)!r}).write_text("torn_down", encoding="utf-8")

    def test_one(self):
        self.assertEqual(1 + 1, 2)

    def test_two(self):
        self.assertEqual(2 + 2, 4)
""",
            )
            self._write_module(
                root,
                "test_gamma",
                """
import unittest

class GammaTests(unittest.TestCase):
    @unittest.skip("intentional skip check")
    def test_skip(self):
        pass
""",
            )

            suites = discover_module_suites(root)
            self.assertEqual([name for name, _ in suites], ["test_alpha", "test_beta", "test_gamma"])

            buf = io.StringIO()
            with redirect_stdout(buf):
                rc = compact_unittest_main([
                    "-s",
                    str(root),
                    "--progress-every",
                    "2",
                    "--slow-threshold",
                    "0.04",
                ])
            output = buf.getvalue()
            self.assertEqual(rc, 0, output)
            self.assertEqual(teardown_marker.read_text(encoding="utf-8"), "torn_down")
            self.assertIn("Running 3 unittest modules (4 tests) from", output)
            self.assertIn("[slow] test_beta (1 tests,", output)
            self.assertIn("[2/3] PASS 2/2 modules (3 tests)", output)
            self.assertIn("[3/3] PASS 3/3 modules (4 tests)", output)
            self.assertIn("Ran 4 tests in", output)
            self.assertIn("OK (skipped=1)", output)

    def test_failure_prints_immediate_fail_line_tracebacks_and_fail_fast(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            ran_marker = root / "ran_second.txt"
            self._write_module(
                root,
                "test_first_fails",
                """
import unittest

class FirstFailTests(unittest.TestCase):
    def test_boom(self):
        self.fail("expected compact runner failure")
""",
            )
            self._write_module(
                root,
                "test_second_skipped_by_failfast",
                f"""
import unittest
from pathlib import Path

class SecondTests(unittest.TestCase):
    def test_never_runs(self):
        Path({str(ran_marker)!r}).write_text("ran", encoding="utf-8")
""",
            )

            buf = io.StringIO()
            with redirect_stdout(buf):
                rc = compact_unittest_main([
                    "-s",
                    str(root),
                    "--progress-every",
                    "1",
                    "--fail-fast",
                ])
            output = buf.getvalue()
            self.assertEqual(rc, 1)
            self.assertFalse(ran_marker.exists())
            self.assertIn("[FAIL] test_first_fails (1 tests, 1 failures, 0 errors,", output)
            self.assertIn("FAIL: test_first_fails.FirstFailTests.test_boom", output)
            self.assertIn("expected compact runner failure", output)
            self.assertIn("Ran 1 test in", output)
            self.assertIn("FAILED (failures=1)", output)

    def test_list_and_verbose_modes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._write_module(
                root,
                "test_sample",
                """
import unittest

class SampleTests(unittest.TestCase):
    def test_ok(self):
        self.assertTrue(True)
""",
            )
            list_buf = io.StringIO()
            with redirect_stdout(list_buf):
                rc_list = compact_unittest_main(["-s", str(root), "--list"])
            self.assertEqual(rc_list, 0)
            self.assertIn("test_sample (1)", list_buf.getvalue())

            verb_buf = io.StringIO()
            with redirect_stdout(verb_buf):
                rc_verb = compact_unittest_main(["-s", str(root), "-v"])
            self.assertEqual(rc_verb, 0)
            self.assertIn("test_ok", verb_buf.getvalue())
            self.assertIn("... ok", verb_buf.getvalue())
            self.assertIn("Ran 1 test in", verb_buf.getvalue())

    def test_parallel_jobs_isolates_gui_modules_and_invokes_warm_worker_cleanup(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self._write_module(
                root,
                "test_unit_a",
                """
import unittest

class UnitATests(unittest.TestCase):
    def test_a(self):
        self.assertEqual(1 + 1, 2)
""",
            )
            self._write_module(
                root,
                "test_unit_b",
                """
import unittest

class UnitBTests(unittest.TestCase):
    def test_b(self):
        self.assertEqual(2 + 2, 4)
""",
            )
            self._write_module(
                root,
                "test_gui_marker",
                """
import unittest

# Simulates GUI module detection marker without opening an X11 window.
_MARKER = "SemanticHarnessApp"

class GuiMarkerTests(unittest.TestCase):
    def test_gui_marker(self):
        self.assertEqual(_MARKER, "SemanticHarnessApp")
""",
            )
            suites = discover_module_suites(root)
            shards = _partition_module_shards([name for name, _ in suites], jobs=3)
            self.assertEqual(shards[0], ["test_gui_marker"])
            self.assertEqual(
                sorted(m for shard in shards[1:] for m in shard),
                ["test_unit_a", "test_unit_b"],
            )

            buf = io.StringIO()
            with redirect_stdout(buf):
                rc = compact_unittest_main([
                    "-s",
                    str(root),
                    "--jobs",
                    "2",
                    "--progress-every",
                    "1",
                ])
            output = buf.getvalue()
            self.assertEqual(rc, 0, output)
            self.assertIn("Running 3 unittest modules (3 tests) from", output)
            self.assertIn("[3/3] PASS 3/3 modules (3 tests)", output)
            self.assertIn("Ran 3 tests in", output)
            self.assertIn("OK", output)

            cleaned = {"calls": 0}
            fake_mod = types.ModuleType("tools.providers.pnc.tests.worker_reuse")
            fake_mod.close_all_warm_workers = lambda: cleaned.__setitem__(  # type: ignore[attr-defined]
                "calls", cleaned["calls"] + 1
            )
            with patch.dict("sys.modules", {"tools.providers.pnc.tests.worker_reuse": fake_mod}):
                compact_unittest._cleanup_warm_workers()
            self.assertEqual(cleaned["calls"], 1)


class DeclarativeFixtureProgressCliTests(unittest.TestCase):
    def test_execute_cases_parallel_reports_thread_safe_progress_and_order(self) -> None:
        cases = [
            SemanticCase(
                case_id=f"c_{i}",
                suite="parallel",
                tags=(),
                domain="beats" if i % 2 == 0 else "knowledge",
                scenario={},
                turns=({"text": f"msg_{i}", "expect": {"accepted": True}},),
            )
            for i in range(6)
        ]
        seen: list[tuple[str, int, int, int]] = []
        lock = threading.Lock()

        def _cb(res: object, idx: int, total: int) -> None:
            with lock:
                seen.append((res.case_id, idx, total, threading.get_ident()))  # type: ignore[attr-defined]

        results = execute_cases_parallel(
            cases,
            jobs=2,
            worker_factory=_ProgressFakeWorker,
            progress_callback=_cb,
        )
        self.assertEqual([r.case_id for r in results], [c.case_id for c in cases])
        self.assertEqual([item[1] for item in seen], [1, 2, 3, 4, 5, 6])
        self.assertTrue(all(item[2] == 6 for item in seen))

    def test_cli_compact_mode_summarizes_by_domain_and_verbose_prints_cases(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            fixture = root / "cases.json"
            fixture.write_text(
                json.dumps(
                    {
                        "schema": "semantic.harness-test.v1",
                        "suite": "compact_cli_suite",
                        "domain": "beats",
                        "cases": [
                            {
                                "id": "beats.one",
                                "turns": [{"text": "hello", "expect": {"accepted": True}}],
                            },
                            {
                                "id": "beats.two",
                                "turns": [{"text": "hello", "expect": {"accepted": True}}],
                            },
                        ],
                    }
                ),
                encoding="utf-8",
            )
            fixture_unset = root / "unset_domain.json"
            fixture_unset.write_text(
                json.dumps(
                    {
                        "schema": "semantic.harness-test.v1",
                        "suite": "unset_suite",
                        "cases": [
                            {
                                "id": "unset.fail_case",
                                "turns": [{"text": "fail_me", "expect": {"accepted": True}}],
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )

            compact_buf = io.StringIO()
            with patch.object(testing_cli, "execute_cases", side_effect=lambda cases, **kw: execute_cases_parallel(cases, jobs=1, worker_factory=_ProgressFakeWorker, **kw)):
                with patch.object(testing_cli, "execute_cases_parallel", side_effect=lambda cases, **kw: execute_cases_parallel(cases, worker_factory=_ProgressFakeWorker, **kw)):
                    with redirect_stdout(compact_buf):
                        rc = testing_cli.run_cli([
                            "--file",
                            str(fixture),
                            "--file",
                            str(fixture_unset),
                            "--jobs",
                            "2",
                        ])
            compact_out = compact_buf.getvalue()
            self.assertEqual(rc, 1)
            self.assertIn("Running 3 semantic test case(s)...", compact_out)
            self.assertIn("PASS domain=beats (2/2 cases,", compact_out)
            self.assertIn("FAIL [unset_suite] unset.fail_case", compact_out)
            self.assertIn("FAIL chunk=1 (0/1 passed, 1 failed,", compact_out)
            self.assertNotIn("PASS [compact_cli_suite] beats.one", compact_out)
            self.assertIn("SEMANTIC TESTS: PASS 2, FAIL 1, TOTAL 3 in", compact_out)

            verbose_buf = io.StringIO()
            with patch.object(testing_cli, "execute_cases", side_effect=lambda cases, **kw: execute_cases_parallel(cases, jobs=1, worker_factory=_ProgressFakeWorker, **kw)):
                with redirect_stdout(verbose_buf):
                    rc_v = testing_cli.run_cli(["--file", str(fixture), "--verbose"])
            verbose_out = verbose_buf.getvalue()
            self.assertEqual(rc_v, 0)
            self.assertIn("PASS [compact_cli_suite] beats.one", verbose_out)
            self.assertIn("PASS [compact_cli_suite] beats.two", verbose_out)


if __name__ == "__main__":
    unittest.main()
