"""Machine-readable Feature Acceptance Registry validation for S10C."""

from __future__ import annotations

import ast
import json
from pathlib import Path
import re
from typing import Any


DEFAULT_REGISTRY_PATH = Path(__file__).resolve().with_name("feature_registry.json")

_VALID_SURFACES = frozenset({
    "World & Mods",
    "Simulation",
    "Quality Sweep",
    "Studio",
    "Log & Diagnostics",
    "Worker Lifecycle",
    "CLI & Agent Ops",
})

_VALID_MUTATION_CLASSES = frozenset({
    "read_only",
    "runtime_state",
    "canonical_source",
    "workspace_config",
})

_APP_BUTTON_RE = re.compile(r"\bapp\.([a-zA-Z0-9_]+_button)\s*=\s*")
_STUDIO_COMMAND_RE = re.compile(r"command=self\.(refresh|run_s6m8_audit|new_family|duplicate_family|delete_family|preview_record|write_source)\b")
_CONVO_SUBPARSER_RE = re.compile(r'convo_sub\.add_parser\(\s*"([a-z]+)"')


def load_feature_registry(path: Path | None = None) -> dict[str, Any]:
    target = path or DEFAULT_REGISTRY_PATH
    payload = json.loads(target.read_text(encoding="utf-8"))
    if not isinstance(payload, dict) or payload.get("schema") != "semantic.feature_registry.v1":
        raise ValueError(f"invalid feature registry schema at {target}")
    features = payload.get("features")
    if not isinstance(features, list):
        raise ValueError(f"feature registry must define a list of features at {target}")
    return payload


def discover_public_ui_buttons(core_repo: Path) -> set[str]:
    """Discover supported top-level ``app.*_button`` controls across UI builders."""
    ui_dir = core_repo / "tools/semantic_harness/ui"
    buttons: set[str] = set()
    for path in sorted(ui_dir.glob("*.py")):
        text = path.read_text(encoding="utf-8")
        for match in _APP_BUTTON_RE.finditer(text):
            buttons.add(f"app.{match.group(1)}")
    studio_pane = core_repo / "tools/semantic_harness/studio/convo_engine_authoring_pane.py"
    if studio_pane.is_file():
        for match in _STUDIO_COMMAND_RE.finditer(studio_pane.read_text(encoding="utf-8")):
            buttons.add(f"ConvoEngineAuthoringPane.{match.group(1)}")
    return buttons


def discover_public_convo_cli_commands(core_repo: Path) -> set[str]:
    """Discover supported ``convo <subcommand>`` public CLI commands."""
    ops_file = core_repo / "tools/semantic_harness/codebuilder/convo_cli_ops.py"
    if not ops_file.is_file():
        return set()
    return {
        f"convo.{match.group(1)}"
        for match in _CONVO_SUBPARSER_RE.finditer(ops_file.read_text(encoding="utf-8"))
    }


def _resolve_repo_root(
    repo_key: str,
    *,
    core_repo: Path,
    hoomans_repo: Path | None,
) -> Path | None:
    if repo_key == "PsychopatzCore":
        return core_repo
    if repo_key == "ProjectHoomans":
        return hoomans_repo
    return None


def _verify_test_symbol(
    owner: str,
    *,
    core_repo: Path,
    hoomans_repo: Path | None,
) -> tuple[bool, bool, str]:
    """Return ``(found, uses_real_tk, detail)`` by AST inspection without running tests."""
    parts = owner.split(":")
    if len(parts) != 3 or "." not in parts[2]:
        return (False, False, f"invalid owner format '{owner}'")
    repo_key, module_name, symbol_name = parts
    cls_name, method_name = symbol_name.split(".", 1)
    repo_root = _resolve_repo_root(repo_key, core_repo=core_repo, hoomans_repo=hoomans_repo)
    if repo_root is None:
        return (False, False, f"repository '{repo_key}' unavailable for '{owner}'")
    py_path = repo_root / (module_name.replace(".", "/") + ".py")
    if not py_path.is_file():
        return (False, False, f"test file not found: {py_path}")
    source = py_path.read_text(encoding="utf-8")
    tree = ast.parse(source, filename=str(py_path))
    found = False
    for node in tree.body:
        if isinstance(node, ast.ClassDef) and node.name == cls_name:
            for member in node.body:
                if isinstance(member, ast.FunctionDef) and member.name == method_name:
                    found = True
                    break
    uses_real_tk = (
        ("import tkinter" in source or "from tkinter" in source)
        and ("SemanticHarnessApp" in source or "make_gui_app" in source)
        and "_FakeTk" not in source
    )
    return (found, uses_real_tk, "" if found else f"missing {cls_name}.{method_name} in {py_path}")


def validate_feature_registry(
    core_repo: Path,
    *,
    hoomans_repo: Path | None = None,
    registry_path: Path | None = None,
) -> dict[str, Any]:
    """Validate completeness, schema integrity, and real-path acceptance ownership."""
    payload = load_feature_registry(registry_path)
    features = payload["features"]
    seen_ids: set[str] = set()
    registered_controls: set[str] = set()
    errors: list[str] = []

    for row in features:
        if not isinstance(row, dict):
            errors.append("non-dict feature row")
            continue
        fid = str(row.get("featureID") or "").strip()
        if not fid:
            errors.append("empty featureID")
            continue
        if fid in seen_ids:
            errors.append(f"duplicate featureID: {fid}")
        seen_ids.add(fid)

        if row.get("surface") not in _VALID_SURFACES:
            errors.append(f"{fid}: invalid surface {row.get('surface')!r}")
        if row.get("mutationClass") not in _VALID_MUTATION_CLASSES:
            errors.append(f"{fid}: invalid mutationClass {row.get('mutationClass')!r}")
        if not str(row.get("canonicalOperation") or "").strip():
            errors.append(f"{fid}: missing canonicalOperation")
        applicability = row.get("providerApplicability")
        if not isinstance(applicability, list) or not applicability:
            errors.append(f"{fid}: providerApplicability must be a non-empty list")

        controls = row.get("controls")
        if not isinstance(controls, list) or not controls:
            errors.append(f"{fid}: controls must be a non-empty list")
        else:
            for ctrl in controls:
                registered_controls.add(str(ctrl))

        owners = row.get("acceptanceOwners")
        mandatory = bool(row.get("mandatory", True))
        requires_gui = bool(row.get("requiresRealGui", False))
        if mandatory and (not isinstance(owners, list) or not owners):
            errors.append(f"{fid}: mandatory feature lacks acceptanceOwners")
            continue

        gui_owner_verified = False
        for owner in owners or []:
            found, uses_real_tk, detail = _verify_test_symbol(
                str(owner), core_repo=core_repo, hoomans_repo=hoomans_repo
            )
            if not found:
                # Only fail on unavailable sibling repository when hoomans_repo is provided.
                if hoomans_repo is not None or str(owner).startswith("PsychopatzCore:"):
                    errors.append(f"{fid}: {detail}")
            elif uses_real_tk:
                gui_owner_verified = True

        if requires_gui and hoomans_repo is not None and not gui_owner_verified:
            errors.append(f"{fid}: requiresRealGui=true lacks a real non-mocked Tk acceptance owner")

    discovered_buttons = discover_public_ui_buttons(core_repo)
    missing_buttons = sorted(discovered_buttons - registered_controls)
    if missing_buttons:
        errors.append(f"unmapped public UI controls: {missing_buttons}")

    discovered_convo_cli = discover_public_convo_cli_commands(core_repo)
    missing_cli = sorted(discovered_convo_cli - registered_controls)
    if missing_cli:
        errors.append(f"unmapped public convo CLI commands: {missing_cli}")

    return {
        "ok": not errors,
        "featureCount": len(features),
        "discoveredUiControls": len(discovered_buttons),
        "discoveredCliCommands": len(discovered_convo_cli),
        "errors": errors,
    }
