"""Tests for the unified multi-suite acceptance runner."""

from __future__ import annotations

import json
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
        args = _parser().parse_args(["--acceptance", "--acceptance-suite", "convo_audit", "--strict-baselines"])
        self.assertTrue(_should_run_cli(args))
        self.assertEqual(args.acceptance_suite, ["convo_audit"])
        self.assertTrue(args.strict_baselines)

    def test_unrelated_baseline_requires_exact_signature_and_non_convo_provenance(self) -> None:
        from pathlib import Path
        import tempfile
        import subprocess
        from unittest import mock
        from tools.semantic_harness.testing.acceptance import (
            classify_hoomans_lua_results,
            load_unrelated_baselines,
            run_acceptance_suites,
            run_hoomans_lua_suite,
        )

        baselines = load_unrelated_baselines()
        self.assertGreaterEqual(len(baselines), 4)
        hoomans_root = Path("/tmp/fake-hoomans")

        # Exact signature matches as reviewed unrelated baseline with provenance
        matching = classify_hoomans_lua_results(
            [
                {
                    "path": str(hoomans_root / "tests/pnc_population_director_smoke.lua"),
                    "returncode": 1,
                    "failureOutput": (
                        "lua: ...p/ProjectHoomans/tests/pnc_population_director_smoke.lua:316: "
                        "new world immediately receives one canonical settlement: expected=1 actual=0"
                    ),
                }
            ],
            hoomans_root=hoomans_root,
            baselines=baselines,
        )
        self.assertEqual(matching["classifiedBaselines"], ["tests/pnc_population_director_smoke.lua"])
        self.assertEqual(matching["unexpectedFailures"], [])
        self.assertEqual(matching["baselineRecords"][0]["provenanceCommit"], "79114089")

        # Same file failing with a DIFFERENT error must NOT be waived by filename
        different_error = classify_hoomans_lua_results(
            [
                {
                    "path": str(hoomans_root / "tests/pnc_population_director_smoke.lua"),
                    "returncode": 1,
                    "failureOutput": "lua: syntax error near unexpected token",
                }
            ],
            hoomans_root=hoomans_root,
            baselines=baselines,
        )
        self.assertEqual(different_error["classifiedBaselines"], [])
        self.assertEqual(different_error["unexpectedFailures"], ["tests/pnc_population_director_smoke.lua"])

        # Timeout in a reviewed file must never be waived
        timed_out = classify_hoomans_lua_results(
            [
                {
                    "path": str(hoomans_root / "tests/pnc_population_director_smoke.lua"),
                    "returncode": 124,
                    "timedOut": True,
                    "failureOutput": "pnc_population_director_smoke.lua:316: new world immediately receives one canonical settlement: expected=1 actual=0",
                }
            ],
            hoomans_root=hoomans_root,
            baselines=baselines,
        )
        self.assertEqual(timed_out["unexpectedFailures"], ["tests/pnc_population_director_smoke.lua"])

        # ConvoEngine / semantic baseline entries are forbidden even in synthetic JSON
        with tempfile.TemporaryDirectory() as tmp:
            bad_json = Path(tmp) / "bad_baselines.json"
            bad_json.write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "baselines": [
                            {
                                "suite": "hoomans_lua",
                                "test": "tests/pnc_convo_engine_smoke.lua",
                                "owner": "none",
                                "provenanceCommit": "deadbeef",
                                "reason": "bad",
                                "signaturePatterns": ["error"],
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )
            with self.assertRaises(ValueError):
                load_unrelated_baselines(bad_json)

        # Strict mode rejects even signature-matched baselines; unexpected failure still fails when convoScopeOk is True
        def fake_subprocess_run(*args, **kwargs):
            report_flag_idx = args[0].index("--harness-report") + 1
            report_file = Path(args[0][report_flag_idx])
            report_file.write_text(
                json.dumps(
                    {
                        "results": [
                            {
                                "path": str(hoomans_root / "tests/pnc_population_director_smoke.lua"),
                                "returncode": 1,
                                "failureOutput": (
                                    "pnc_population_director_smoke.lua:316: "
                                    "new world immediately receives one canonical settlement: expected=1 actual=0"
                                ),
                            },
                            {
                                "path": str(hoomans_root / "tests/pnc_unrelated_new_bug_smoke.lua"),
                                "returncode": 1,
                                "failureOutput": "new failure in non-convo test",
                            },
                        ],
                        "conflicts": [],
                    }
                ),
                encoding="utf-8",
            )
            return subprocess.CompletedProcess(args[0], 1, stdout="", stderr="")

        with tempfile.TemporaryDirectory() as tmp_core:
            core_repo = Path(tmp_core)
            with mock.patch("tools.semantic_harness.testing.acceptance.subprocess.run", side_effect=fake_subprocess_run):
                with mock.patch(
                    "tools.semantic_harness.testing.acceptance.resolve_repositories",
                    return_value={"core": core_repo, "hoomans": hoomans_root, "dynamic_trading": core_repo},
                ):
                    report = run_acceptance_suites(
                        core_repository=core_repo,
                        hoomans_repository=hoomans_root,
                        dynamic_trading_repository=core_repo,
                        suites=("hoomans_lua",),
                    )
                    self.assertTrue(report["convoScopeOk"])
                    self.assertFalse(report["ok"])
                    self.assertFalse(report["suites"]["hoomans_lua"]["ok"])

                    strict = run_hoomans_lua_suite(
                        {"core": core_repo, "hoomans": hoomans_root, "dynamic_trading": core_repo},
                        allow_unrelated_baselines=False,
                    )
                    self.assertFalse(strict["ok"])

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
