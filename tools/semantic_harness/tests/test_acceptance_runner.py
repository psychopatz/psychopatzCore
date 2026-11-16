"""Tests for the S10B unified multi-suite acceptance runner."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

CORE_ROOT = Path(__file__).resolve().parents[3]
if str(CORE_ROOT) not in sys.path:
    sys.path.insert(0, str(CORE_ROOT))

from tools.semantic_harness.entrypoints.app import _should_run_cli
from tools.semantic_harness.entrypoints.cli import _parser
from tools.semantic_harness.testing.acceptance import (
    REQUIRED_SUITES,
    _classify_runtime_skips,
    _parse_unittest_counts,
    classify_pnc_provider_modules,
    resolve_repositories,
    run_acceptance_suites,
)


class AcceptanceRunnerTests(unittest.TestCase):
    def test_required_suites_include_all_nine_layers(self) -> None:
        self.assertEqual(
            REQUIRED_SUITES,
            (
                "core_python",
                "core_lua",
                "hoomans_lua",
                "hoomans_provider_python",
                "real_provider_worker",
                "tk_xvfb_gui",
                "dynamic_trading",
                "convo_audit",
                "kahlua_static",
            ),
        )

    def test_pnc_provider_module_classification_is_disjoint_and_complete(self) -> None:
        repos = resolve_repositories(CORE_ROOT)
        pnc_tests = repos["hoomans"] / "tools/providers/pnc/tests"
        if not pnc_tests.is_dir():
            self.skipTest("ProjectHoomans sibling repository unavailable")
        all_files = {
            f"tools.providers.pnc.tests.{path.stem}"
            for path in pnc_tests.glob("test_*.py")
        }
        buckets = classify_pnc_provider_modules(pnc_tests)
        combined = (
            set(buckets["hoomans_provider_python"])
            | set(buckets["real_provider_worker"])
            | set(buckets["tk_xvfb_gui"])
        )
        self.assertEqual(combined, all_files)
        self.assertFalse(
            set(buckets["tk_xvfb_gui"]) & set(buckets["real_provider_worker"])
        )
        self.assertFalse(
            set(buckets["tk_xvfb_gui"]) & set(buckets["hoomans_provider_python"])
        )
        self.assertFalse(
            set(buckets["real_provider_worker"]) & set(buckets["hoomans_provider_python"])
        )
        self.assertGreaterEqual(len(buckets["tk_xvfb_gui"]), 30)
        self.assertGreaterEqual(len(buckets["real_provider_worker"]), 100)
        self.assertGreaterEqual(len(buckets["hoomans_provider_python"]), 30)

    def test_runtime_skip_classification_allows_only_reviewed_real_save_skips(self) -> None:
        save_output = (
            "test_a (...) ... skipped 'real local save is unavailable'\n"
            "test_b (...) ... skipped 'local Dana save unavailable'\n"
            "Ran 2 tests in 0.001s\n\nOK (skipped=2)\n"
        )
        allowed, details = _classify_runtime_skips(save_output, 2)
        self.assertEqual(allowed, 2)
        self.assertTrue(all(d["category"] == "real_local_save_unavailable" for d in details))

        display_output = (
            "test_ui (...) ... skipped 'Tk display is unavailable'\n"
            "Ran 1 test in 0.001s\n\nOK (skipped=1)\n"
        )
        allowed_disp, details_disp = _classify_runtime_skips(display_output, 1)
        self.assertEqual(allowed_disp, 0)
        self.assertEqual(details_disp[0]["category"], "unclassified")

    def test_parse_unittest_counts_handles_skips_and_failures(self) -> None:
        self.assertEqual(
            _parse_unittest_counts(
                {"status": "SKIP", "skipCount": 3, "output": "Ran 3 tests in 0.1s\n\nOK (skipped=3)"}
            ),
            (3, 0, 0, 3),
        )
        self.assertEqual(
            _parse_unittest_counts(
                {"status": "FAIL", "skipCount": 1, "output": "Ran 5 tests in 1.0s\n\nFAILED (failures=1, errors=1, skipped=1)"}
            ),
            (5, 2, 2, 1),
        )

    def test_cli_routes_acceptance_flag_headless(self) -> None:
        args = _parser().parse_args(["--acceptance", "--acceptance-suite", "convo_audit"])
        self.assertTrue(_should_run_cli(args))
        self.assertEqual(args.acceptance_suite, ["convo_audit"])

    def test_fast_subset_of_real_suites_executes_cleanly(self) -> None:
        repos = resolve_repositories(CORE_ROOT)
        if not repos["hoomans"].is_dir() or not repos["dynamic_trading"].is_dir():
            self.skipTest("Sibling participant repositories unavailable")
        report = run_acceptance_suites(
            core_repository=repos["core"],
            hoomans_repository=repos["hoomans"],
            dynamic_trading_repository=repos["dynamic_trading"],
            suites=("core_lua", "dynamic_trading", "convo_audit"),
            jobs=4,
        )
        self.assertTrue(report["ok"], report)
        self.assertEqual(report["summary"]["suitesPassed"], 3)
        self.assertEqual(report["summary"]["failed"], 0)
        self.assertEqual(report["summary"]["skipped"], 0)


if __name__ == "__main__":
    unittest.main()
