"""Regression gates for provider-aware semantic fixture authority (R1-R5)."""

from __future__ import annotations

import io
import json
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from types import SimpleNamespace

from tools.semantic_harness.testing.cli import run_cli
from tools.semantic_harness.testing.lint import lint_fixtures
from tools.semantic_harness.testing.loader import discover_cases
from tools.semantic_harness.testing.resolver import (
    FixtureResolutionError,
    resolve_fixture_file,
    resolve_fixture_roots,
)
from tools.semantic_harness.ui.regression_controller import (
    cancel_semantic_fixtures,
    discover_semantic_fixture_domains,
    run_regression_command_rejections,
    run_regression_lifecycle,
    run_regression_selection,
    run_semantic_fixtures,
)


CORE_ROOT = Path(__file__).resolve().parents[3]
HOOMANS_ROOT = CORE_ROOT.parent / "ProjectHoomans"


class FixtureAuthorityTests(unittest.TestCase):
    def test_active_pnc_provider_resolves_project_hoomans_corpus(self) -> None:
        roots = resolve_fixture_roots(
            kind="semantic",
            core_repository=CORE_ROOT,
            repository=HOOMANS_ROOT,
        )
        expected_root = (HOOMANS_ROOT / "tools/providers/pnc/fixtures/v1").resolve()
        self.assertEqual(roots, (expected_root,))
        cases = discover_cases(roots)
        self.assertGreaterEqual(len(cases), 116)

    def test_synthetic_provider_declares_fixture_root_without_core_edits(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            provider_root = Path(tmp) / "SyntheticMod"
            fixtures_dir = provider_root / "custom_fixtures" / "v1"
            fixtures_dir.mkdir(parents=True)
            (provider_root / "provider.json").write_text(
                json.dumps({
                    "schema": "semantic.provider_manifest.v2",
                    "providerID": "SyntheticProvider",
                    "displayName": "Synthetic Provider",
                    "providers": [{
                        "providerID": "SyntheticProvider",
                        "displayName": "Synthetic Provider",
                        "repositoryKind": "external",
                        "requires": ["PsychopatzCore"],
                        "materializationModes": ["abstract"],
                        "fixtureRoots": {
                            "semantic": "${repository}/custom_fixtures/v1",
                        },
                    }],
                }),
                encoding="utf-8",
            )
            (fixtures_dir / "smoke.json").write_text(
                json.dumps({
                    "schema": "semantic.harness-test.v1",
                    "suite": "synthetic.smoke",
                    "cases": [{
                        "id": "synthetic.hello",
                        "turns": [{"text": "hello", "expect": {"accepted": True}}],
                    }],
                }),
                encoding="utf-8",
            )

            roots = resolve_fixture_roots(
                kind="semantic",
                core_repository=CORE_ROOT,
                provider_roots=[provider_root],
                mods=["SyntheticProvider"],
            )
            self.assertEqual(roots, (fixtures_dir.resolve(),))
            cases = discover_cases(roots)
            self.assertEqual([c.case_id for c in cases], ["synthetic.hello"])

    def test_missing_or_invalid_fixture_roots_fail_with_diagnostics(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            missing = Path(tmp) / "does_not_exist"
            with self.assertRaisesRegex(FixtureResolutionError, "Fixtures directory not found"):
                resolve_fixture_roots(explicit_dir=missing)

            provider_root = Path(tmp) / "BrokenProvider"
            provider_root.mkdir(parents=True)
            (provider_root / "provider.json").write_text(
                json.dumps({
                    "schema": "semantic.provider_manifest.v2",
                    "providerID": "BrokenProvider",
                    "displayName": "Broken Provider",
                    "providers": [{
                        "providerID": "BrokenProvider",
                        "displayName": "Broken Provider",
                        "repositoryKind": "external",
                        "requires": ["PsychopatzCore"],
                        "materializationModes": ["abstract"],
                        "fixtureRoots": {
                            "semantic": "${repository}/missing_dir",
                        },
                    }],
                }),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(FixtureResolutionError, "BrokenProvider.*missing directory"):
                resolve_fixture_roots(
                    kind="semantic",
                    core_repository=CORE_ROOT,
                    provider_roots=[provider_root],
                    mods=["BrokenProvider"],
                )

            no_roots_provider = Path(tmp) / "NoRootsProvider"
            no_roots_provider.mkdir(parents=True)
            (no_roots_provider / "provider.json").write_text(
                json.dumps({
                    "schema": "semantic.provider_manifest.v2",
                    "providerID": "NoRootsProvider",
                    "displayName": "No Roots Provider",
                    "providers": [{
                        "providerID": "NoRootsProvider",
                        "displayName": "No Roots Provider",
                        "repositoryKind": "external",
                        "requires": ["PsychopatzCore"],
                        "materializationModes": ["abstract"],
                    }],
                }),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(FixtureResolutionError, "No active provider declares fixtureRoots.semantic"):
                resolve_fixture_roots(
                    kind="semantic",
                    core_repository=CORE_ROOT,
                    provider_roots=[no_roots_provider],
                    mods=["NoRootsProvider"],
                )

    def test_no_duplicate_pnc_corpus_or_retired_schema_in_core(self) -> None:
        self.assertFalse(
            (CORE_ROOT / "tools/semantic_harness/fixtures").exists(),
            "Duplicate PNC fixtures directory must not exist under generic Core",
        )
        for rel in (
            "tools/semantic_harness/testing/cli.py",
            "tools/semantic_harness/testing/lint.py",
            "tools/semantic_harness/entrypoints/cli.py",
            "tools/semantic_harness/ui/regression_controller.py",
        ):
            content = (CORE_ROOT / rel).read_text(encoding="utf-8")
            self.assertNotIn("tools/semantic_harness/fixtures", content, rel)

        pnc_v1 = HOOMANS_ROOT / "tools/providers/pnc/fixtures/v1"
        for fixture_file in pnc_v1.rglob("*.json"):
            doc = json.loads(fixture_file.read_text(encoding="utf-8"))
            self.assertNotEqual(doc.get("schema"), "pnc.semantic-test.v1", str(fixture_file))

    def test_gui_regression_controller_resolves_provider_fixtures(self) -> None:
        captured: list[tuple[str, Any]] = []

        class _Var:
            def __init__(self) -> None:
                self.value = ""

            def set(self, value: str) -> None:
                self.value = value

        app = SimpleNamespace(
            authoring_service=SimpleNamespace(
                repository=HOOMANS_ROOT,
                core_repository=CORE_ROOT,
            ),
            arguments=SimpleNamespace(
                repository=str(HOOMANS_ROOT),
                core_repository=str(CORE_ROOT),
                profile="pnc",
            ),
            selection_active={},
            session=SimpleNamespace(ready=True),
            busy=False,
            regression_status_var=_Var(),
            _start_operation=lambda op, finish: captured.append(("op", op)),
        )

        run_regression_lifecycle(app)
        run_regression_command_rejections(app)
        run_regression_selection(app)
        self.assertEqual(len(captured), 3, app.regression_status_var.value)
        resolved = resolve_fixture_file(
            "observatory_lifecycle_en_tl.json",
            kind="regression",
            core_repository=CORE_ROOT,
            repository=HOOMANS_ROOT,
        )
        self.assertEqual(
            resolved,
            (HOOMANS_ROOT / "tools/providers/pnc/fixtures/observatory_lifecycle_en_tl.json").resolve(),
        )

    def test_standalone_cli_default_list_discovers_provider_corpus(self) -> None:
        buf = io.StringIO()
        with redirect_stdout(buf):
            rc = run_cli(["--list", "--core-repository", str(CORE_ROOT)])
        self.assertEqual(rc, 0)
        output = buf.getvalue()
        self.assertRegex(output, r"Discovered (?:1[1-9]\d|[2-9]\d\d|\d{4,}) matching test case\(s\):")
        self.assertIn("command.follow.direct", output)

        report = lint_fixtures(
            resolve_fixture_roots(kind="semantic", core_repository=CORE_ROOT)
        )
        self.assertTrue(report["ok"], report)
        self.assertGreaterEqual(report["files_checked"], 17)
        self.assertGreaterEqual(report["cases_checked"], 116)

    def test_main_cli_run_semantic_tests_without_explicit_file(self) -> None:
        proc = subprocess.run(
            [
                sys.executable,
                "-m",
                "tools.semantic_harness",
                "--no-gui",
                "--repository",
                str(HOOMANS_ROOT),
                "--core-repository",
                str(CORE_ROOT),
                "--preset",
                "pnc",
                "--startup-timeout",
                "20",
                "--run-semantic-tests",
                "--semantic-test-filter",
                "command.follow.direct",
                "--jsonl",
            ],
            cwd=str(CORE_ROOT),
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(proc.returncode, 0, proc.stderr or proc.stdout)
        rows = [json.loads(line) for line in proc.stdout.splitlines() if line.strip()]
        self.assertTrue(rows and rows[0]["ok"], rows)
        self.assertEqual(rows[0]["passed"], 1)
        self.assertEqual(rows[0]["total"], 1)

    def test_gui_semantic_fixture_domain_discovery_filter_run_and_cancel(self) -> None:
        from tools.semantic_harness.runtime.config import HarnessConfig

        class _FakeVar:
            def __init__(self, value: str = "") -> None:
                self._value = value

            def get(self) -> str:
                return self._value

            def set(self, value: str) -> None:
                self._value = value

        class _FakeApp:
            def __init__(self) -> None:
                self.session = SimpleNamespace(ready=True)
                self.busy = False
                self.arguments = SimpleNamespace(
                    repository=str(HOOMANS_ROOT),
                    core_repository=str(CORE_ROOT),
                    dynamic_trading_repository=None,
                    mods=None,
                    preset=None,
                    profile="pnc",
                    provider_root=(),
                )
                self.selection_active = {}
                self.authoring_service = None
                self.regression_status_var = _FakeVar()
                self.regression_output = object()
                self.fixture_domain_var = _FakeVar("compiler")
                self.fixture_semantic_id_var = _FakeVar("beat.argument_escalation")
                self.fixture_domain_combo: dict[str, Any] = {}
                self.trace_tabs = SimpleNamespace(select=lambda _w: None)
                self.compare_tabs = SimpleNamespace(select=lambda _w: None)
                self.compare_frame = object()
                self.regression_frame = object()
                self.rendered_text = ""

            def _set_text(self, _widget: Any, text: str) -> None:
                self.rendered_text = text

            def _start_operation(self, operation: Any, finish: Any) -> None:
                cfg = HarnessConfig.discover(
                    repository=HOOMANS_ROOT,
                    core_repository=CORE_ROOT,
                )
                worker = SimpleNamespace(config=cfg)
                finish(operation(worker))

        app = _FakeApp()
        counts = discover_semantic_fixture_domains(app)
        self.assertIn("compiler", counts)
        self.assertIn("beats", counts)
        self.assertIn("compiler", app.fixture_domain_combo["values"])

        run_semantic_fixtures(app)
        self.assertIn("PASS=1 FAIL=0 TOTAL=1", app.rendered_text)
        self.assertIn("compiler.beat_argument_escalation_linkage", app.rendered_text)

        cancel_semantic_fixtures(app)
        self.assertTrue(app._fixture_cancel_requested)


if __name__ == "__main__":
    unittest.main()
