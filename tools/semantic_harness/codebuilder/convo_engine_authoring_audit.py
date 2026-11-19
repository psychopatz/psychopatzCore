"""Inventory ConvoEngine adoption surfaces and guard frozen first-party authoring.

The inventory is deliberately Core-owned.  It describes adopter records and
runtime boundaries without moving their gameplay authority into Core.  The
guard only rejects changed paths inside known superseded authoring roots; a
generated artifact or an external compatibility adapter is not an authoring
surface and is therefore not rejected.
"""

from __future__ import annotations

import argparse
import datetime as _datetime
import json
import subprocess
from collections import Counter
from pathlib import Path
from typing import Any, Iterable, Mapping


AUDIT_SCHEMA = "psychopatz.semantic.dialogue-authoring-audit.v1"
GUARD_SCHEMA = "psychopatz.semantic.dialogue-authoring-guard.v1"
CONVO_ENGINE_SCHEMA = "psychopatz.convo-engine.v1"

# Authoring evidence must describe maintained source, not interpreter/build
# residue.  Keep this filter centralized because both the inventory and the
# reference scan consume repository file discovery.
_AUDIT_NOISE_PARTS = frozenset({
    "__pycache__",
    ".pytest_cache",
    ".mypy_cache",
    ".ruff_cache",
    ".coverage",
    "node_modules",
})
_AUDIT_NOISE_SUFFIXES = frozenset({
    ".pyc",
    ".pyo",
    ".class",
    ".tmp",
    ".swp",
    ".swo",
    ".bak",
    ".orig",
})


def _is_audit_noise(relative: str) -> bool:
    """Return whether a path is non-source interpreter/editor/build noise."""
    path = Path(_normalise(relative))
    if any(part in _AUDIT_NOISE_PARTS for part in path.parts):
        return True
    name = path.name
    return (
        name.startswith("~$")
        or name.endswith("~")
        or path.suffix.lower() in _AUDIT_NOISE_SUFFIXES
    )


SURFACES: dict[str, tuple[dict[str, Any], ...]] = {
    "PsychopatzCore": (
        {
            "id": "core.semantic_harness_mechanism",
            "source_roots": ["tools/semantic_harness/codebuilder"],
            "classification": "mechanism",
            "owner": "PsychopatzCore",
            "destination": "PsychopatzCore ConvoEngine schema, compiler, validator, authoring service and runtime contracts",
            "migration_status": "mechanism_owner; extend in place; no adopter compiler copy",
            "generated_roots": [],
            "external_compatibility": {"status": "none"},
            "reference_tokens": [
                "tools/semantic_harness/codebuilder",
                "conversation_compiler",
                "semantic_pack_compiler",
            ],
        },
        {
            "id": "core.legacy_codebuilder_records",
            "source_roots": ["tools/semantic_harness/codebuilder/sources/conversation"],
            "classification": "adopter_record_and_migration_input",
            "owner": "manifest-declared: PsychopatzCore, ProjectHoomans, DTCommon",
            "destination": "Final ConvoEngine dialogue/behavior/beat/realization records routed by declared owner",
            "migration_status": "frozen migration input; migrate by domain, then remove superseded records",
            "generated_roots": [
                "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Semantics/Generated/Conversation",
                "Contents/mods/PsychopatzCore/common/media/translation",
            ],
            "external_compatibility": {
                "status": "bounded package/provider inputs remain until migrated",
                "paths": ["tools/providers/dt/codebuilder/sources/conversation"],
            },
            "reference_tokens": [
                "tools/semantic_harness/codebuilder/sources/conversation",
                "Semantics/Generated/Conversation",
            ],
        },
        {
            "id": "core.legacy_text_catalogs",
            "source_roots": ["tools/semantic_harness/codebuilder/sources/conversation/text"],
            "classification": "manual_text_record_and_migration_input",
            "owner": "manifest-declared: PsychopatzCore, ProjectHoomans, DTCommon",
            "destination": "Inline locale maps on final ConvoEngine records with EN fallback",
            "migration_status": "frozen split text input; generated translation catalogs remain downstream-only",
            "generated_roots": ["Contents/mods/PsychopatzCore/common/media/translation"],
            "external_compatibility": {"status": "translation package boundary; no separate semantic authority"},
            "reference_tokens": [
                "sources/conversation/text",
                "Conversation/Text",
            ],
        },
        {
            "id": "core.generated_conversation_runtime",
            "source_roots": [
                "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Semantics/Generated/Conversation",
                "Contents/mods/PsychopatzCore/common/media/translation",
            ],
            "classification": "generated_output",
            "owner": "PsychopatzCore",
            "destination": "Downstream output of the Core-owned ConvoEngine compiler",
            "migration_status": "retain as generated compatibility/runtime output; never hand-author",
            "generated_roots": [],
            "external_compatibility": {
                "status": "public runtime module and translation boundary consumed by adopters",
                "paths": ["PsychopatzCore/Semantics/Generated/Conversation"],
            },
            "reference_tokens": [
                "PsychopatzCore/Semantics/Generated/Conversation",
                "PsychopatzCore/Semantics/Generated/Conversation/Registry",
            ],
        },
    ),
    "ProjectHoomans": (
        {
            "id": "hoomans.legacy_lua_definitions",
            "source_roots": [
                "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/Conversation/Definitions",
            ],
            "classification": "adopter_record",
            "owner": "ProjectHoomans",
            "destination": "ProjectHoomans-owned ConvoEngine dialogue/behavior/beat records compiled by Core",
            "migration_status": "frozen superseded node/choice/outcome and memory authoring; delete after domain parity and caller-zero",
            "generated_roots": [
                "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/Semantics/Generated/Conversation",
            ],
            "external_compatibility": {"status": "none; this is first-party authoring"},
            "reference_tokens": [
                "PNC/Conversation/Definitions",
                "ConversationDefinitions",
                "ResponsePoolID",
            ],
        },
        {
            "id": "hoomans.generated_conversation_runtime",
            "source_roots": [
                "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/Semantics/Generated/Conversation",
                "Contents/mods/ProjectHoomans/common/media/translation",
            ],
            "classification": "generated_output",
            "owner": "ProjectHoomans",
            "destination": "Downstream output of Core ConvoEngine consumed by existing PNC semantic/runtime authorities",
            "migration_status": "retain as generated output during migration; do not hand-author or duplicate Core compiler",
            "generated_roots": [],
            "external_compatibility": {
                "status": "public PNC registry/index and translation boundary",
                "paths": ["PNC/Semantics/Generated/Conversation"],
            },
            "reference_tokens": [
                "PNC/Semantics/Generated/Conversation",
                "PNC/Semantics/Generated/Conversation/Registry",
            ],
        },
        {
            "id": "hoomans.semantic_runtime_adapters",
            "source_roots": ["Contents/mods/ProjectHoomans/42.20/media/lua"],
            "classification": "adopter_runtime_adapter",
            "owner": "ProjectHoomans",
            "destination": "Existing PNC semantic, social, scene and gameplay authorities behind Core ConvoEngine contracts",
            "migration_status": "retain gameplay authority; replace only duplicated authoring inputs during S5",
            "generated_roots": [],
            "external_compatibility": {
                "status": "adopter runtime seam; not a generic ConvoEngine implementation",
                "paths": ["PNC/Semantics", "PNC/Conversation"],
            },
            "reference_tokens": [
                "PNC/Conversation/Definitions",
                "PNC/Semantics/Generated/Conversation",
                "GetStaticSuggestions",
            ],
        },
    ),
    "DynamicTrading": (
        {
            "id": "dt.trader_conversation_pack",
            "source_roots": [
                "tools/providers/dt/codebuilder/sources/conversation/dialogue/trading",
            ],
            "classification": "adopter_record",
            "owner": "DTCommon",
            "destination": "DTCommon-owned ConvoEngine dialogue recognition and offer records compiled by Core",
            "migration_status": "S5 migrated and consolidated into final DTCommon ConvoEngine dialogue; superseded pack source removed with semantic-pack parity retained",
            "generated_roots": [
                "Contents/mods/DTCommon/common/media/lua/shared/DTCommon/ConvoEngine/Packs/Dialogue",
            ],
            "external_compatibility": {
                "status": "provider action seam remains DTCommon-owned",
                "paths": ["DT.trade_action", "DT.referral_action", "DT.rumors_action"],
            },
            "reference_tokens": [
                "tools/providers/dt/codebuilder/sources/conversation/dialogue/trading",
                "DTCommon/ConvoEngine/Packs/Dialogue/Trading",
                "DTCommon_SemanticPack",
            ],
        },
        {
            "id": "dt.static_suggestions",
            "source_roots": [
                "tools/providers/dt/codebuilder/sources/conversation/dialogue/trading",
            ],
            "classification": "adopter_record",
            "owner": "DTCommon",
            "destination": "Core ConvoEngine participant-neutral offers projected to player UI or NPC affordance policy",
            "migration_status": "S5 consolidated into the final DTCommon ConvoEngine dialogue with recognition; superseded static suggestion source removed and generated UI parity retained",
            "generated_roots": [
                "Contents/mods/DTCommon/common/media/lua/shared/DTCommon/ConvoEngine/UI/Dialogue",
                "Contents/mods/DTCommon/common/media/translation",
            ],
            "external_compatibility": {
                "status": "UI projection remains a downstream consumer, not semantic authority",
                "paths": ["DTCommon_TraderConversation.lua"],
            },
            "reference_tokens": [
                "tools/providers/dt/codebuilder/sources/conversation/dialogue/trading",
                "DTCommon/ConvoEngine/UI/Dialogue/Trading",
                "GetStaticSuggestions",
            ],
        },
        {
            "id": "dt.generated_conversation_runtime",
            "source_roots": [
                "Contents/mods/DTCommon/common/media/lua/shared/DTCommon/Semantics/Generated/Conversation",
                "Contents/mods/DTCommon/common/media/translation",
            ],
            "classification": "generated_output",
            "owner": "DTCommon",
            "destination": "Downstream output of Core ConvoEngine consumed by DTCommon trader conversation",
            "migration_status": "retain as generated output during migration; do not hand-author",
            "generated_roots": [],
            "external_compatibility": {
                "status": "DTCommon registry and translation package boundary",
                "paths": ["DTCommon/Semantics/Generated/Conversation/Registry.lua"],
            },
            "reference_tokens": [
                "DTCommon/Semantics/Generated/Conversation",
                "ConversationRegistry",
            ],
        },
        {
            "id": "dt.trader_runtime_and_compatibility",
            "source_roots": [
                "Contents/mods/DTCommon/42.20/media/lua",
                "Contents/mods/DTAbstract/42.20/media/lua",
                "Contents/mods/DTHoomans/42.20/media/lua",
            ],
            "classification": "adopter_runtime_and_external_compatibility",
            "owner": "DTCommon",
            "destination": "Existing trader authority and explicit Hoomans/provider compatibility adapters behind Core ConvoEngine seams",
            "migration_status": "retain gameplay/provider authority; remove only duplicated first-party authoring inputs",
            "generated_roots": [],
            "external_compatibility": {
                "status": "explicit compatibility boundary; not a second ConvoEngine language",
                "paths": ["DTAbstract_CoreConversation.lua", "DTHoomans_Conversation.lua"],
            },
            "reference_tokens": [
                "BuildSpec",
                "DTAbstract_CoreConversation",
                "DTHoomans_Conversation",
                "DTCommon_TraderConversation",
            ],
        },
    ),
}


FROZEN_PREFIXES: dict[str, tuple[str, ...]] = {
    "PsychopatzCore": (
        "tools/semantic_harness/codebuilder/sources/conversation/content/",
        "tools/semantic_harness/codebuilder/sources/conversation/patterns/",
        "tools/semantic_harness/codebuilder/sources/conversation/flows/",
        "tools/semantic_harness/codebuilder/sources/conversation/responses/",
        "tools/semantic_harness/codebuilder/sources/conversation/ui/",
        "tools/semantic_harness/codebuilder/sources/conversation/text/",
    ),
    "ProjectHoomans": (
        "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/Conversation/Definitions/",
    ),
    "DynamicTrading": (
        "tools/providers/dt/codebuilder/sources/conversation/",
    ),
}


GENERATED_PREFIXES: dict[str, tuple[str, ...]] = {
    "PsychopatzCore": (
        "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/Semantics/Generated/",
        "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine/Manifest.lua",
        "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine/Registry.lua",
        "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine/FoundationRegistry.lua",
        "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine/Beat/",
        "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine/Beats/",
        "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine/Behavior/",
        "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine/Behaviors/",
        "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine/Content/",
        "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine/Dialogue/",
        "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine/Flows/",
        "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine/Index/",
        "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine/Packs/",
        "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine/Patterns/",
        "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine/Realization/",
        "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine/Responses/",
        "Contents/mods/PsychopatzCore/common/media/lua/shared/PsychopatzCore/ConvoEngine/UI/",
        "Contents/mods/PsychopatzCore/common/media/translation/",
    ),
    "ProjectHoomans": (
        "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/Semantics/Generated/",
        "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/Manifest.lua",
        "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/Registry.lua",
        "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/Beat/",
        "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/Beats/",
        "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/Behavior/",
        "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/Behaviors/",
        "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/Content/",
        "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/Dialogue/",
        "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/Flows/",
        "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/Index/",
        "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/Packs/",
        "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/Patterns/",
        "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/Realization/",
        "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/Responses/",
        "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/ConvoEngine/UI/",
        "Contents/mods/ProjectHoomans/common/media/translation/",
    ),
    "DynamicTrading": (
        "Contents/mods/DTCommon/common/media/lua/shared/DTCommon/Semantics/Generated/",
        "Contents/mods/DTCommon/common/media/lua/shared/DTCommon/ConvoEngine/",
        "Contents/mods/DTCommon/common/media/translation/",
    ),
}


def _normalise(value: str) -> str:
    return value.replace("\\", "/").lstrip("./")


def _is_under(path: str, prefixes: Iterable[str]) -> bool:
    normalised = _normalise(path)
    return any(normalised == prefix.rstrip("/") or normalised.startswith(prefix) for prefix in prefixes)


def _git_files(root: Path) -> list[str]:
    completed = subprocess.run(
        ["git", "-C", str(root), "ls-files", "-co", "--exclude-standard"],
        check=True,
        capture_output=True,
        text=True,
    )
    return sorted(
        relative
        for relative in (
            _normalise(line) for line in completed.stdout.splitlines() if line.strip()
        )
        if not _is_audit_noise(relative)
    )


def _git_state(root: Path) -> dict[str, Any]:
    head = subprocess.run(
        ["git", "-C", str(root), "rev-parse", "HEAD"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()
    status = subprocess.run(
        ["git", "-C", str(root), "status", "--short"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.splitlines()
    return {"head": head, "dirty": bool(status), "statusCount": len(status)}


def _surface_files(root: Path, source_roots: Iterable[str]) -> list[str]:
    files: list[str] = []
    for source_root in source_roots:
        path = root / source_root
        if path.is_file():
            files.append(source_root)
        elif path.is_dir():
            files.extend(
                _normalise(str(candidate.relative_to(root)))
                for candidate in path.rglob("*")
                if candidate.is_file()
                and not _is_audit_noise(str(candidate.relative_to(root)))
            )
    return sorted(set(files))


def _read_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError):
        return None


def _source_summary(root: Path, files: Iterable[str]) -> dict[str, Any]:
    extensions: Counter[str] = Counter()
    schemas: Counter[str] = Counter()
    owners: Counter[str] = Counter()
    json_files = 0
    invalid_json = 0
    total_bytes = 0
    for relative in files:
        path = root / relative
        total_bytes += path.stat().st_size
        extensions[path.suffix.lower() or "<none>"] += 1
        if path.suffix.lower() != ".json":
            continue
        json_files += 1
        document = _read_json(path)
        if document is None:
            invalid_json += 1
            continue
        if isinstance(document, Mapping):
            schema = document.get("schema")
            owner = document.get("owner")
            if isinstance(schema, str):
                schemas[schema] += 1
            if isinstance(owner, str):
                owners[owner] += 1
    return {
        "fileCount": len(list(files)) if not isinstance(files, list) else len(files),
        "totalBytes": total_bytes,
        "extensions": dict(sorted(extensions.items())),
        "jsonFileCount": json_files,
        "invalidJsonCount": invalid_json,
        "schemas": dict(sorted(schemas.items())),
        "owners": dict(sorted(owners.items())),
    }


def _reference_files(root: Path, files: list[str], surface: Mapping[str, Any]) -> dict[str, list[str]]:
    source_files = set(files)
    generated_roots = tuple(surface.get("generated_roots", ()))
    tokens = tuple(token for token in surface.get("reference_tokens", ()) if token)
    references: dict[str, list[str]] = {
        "production": [],
        "tests": [],
        "documentation": [],
        "generated": [],
    }
    for relative in _git_files(root):
        if relative in source_files or _is_audit_noise(relative):
            continue
        path = root / relative
        if not path.is_file() or path.stat().st_size > 2 * 1024 * 1024:
            continue
        try:
            content = path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError):
            continue
        if not any(token in content for token in tokens):
            continue
        if _is_under(relative, generated_roots):
            bucket = "generated"
        elif relative.startswith(("tests/", "tools/", "test/")) and "/tests/" in f"/{relative}":
            bucket = "tests"
        elif relative.startswith(("Docs/", "docs/")) or path.suffix.lower() in {".md", ".rst"}:
            bucket = "documentation"
        else:
            bucket = "production"
        references[bucket].append(relative)
    return {key: sorted(set(value)) for key, value in references.items()}


def _surface_report(root: Path, surface: Mapping[str, Any]) -> dict[str, Any]:
    files = _surface_files(root, surface["source_roots"])
    report = dict(surface)
    report["source_roots"] = list(surface["source_roots"])
    report["source_files"] = files
    report["source_summary"] = _source_summary(root, files)
    report["generated_outputs"] = _surface_files(root, surface.get("generated_roots", ()))
    report["references"] = _reference_files(root, files, surface)
    return report


def _repo_spec(spec: str) -> tuple[str, Path]:
    name, separator, raw_path = spec.partition("=")
    if not separator or name not in SURFACES or not raw_path:
        raise ValueError(f"--repo must be NAME=PATH for one of {sorted(SURFACES)}")
    root = Path(raw_path).expanduser().resolve()
    if not root.is_dir():
        raise ValueError(f"repository root does not exist: {root}")
    return name, root


def _status_paths(root: Path) -> list[tuple[str, str]]:
    completed = subprocess.run(
        ["git", "-C", str(root), "status", "--short", "--untracked-files=all"],
        check=True,
        capture_output=True,
        text=True,
    )
    paths: list[tuple[str, str]] = []
    for line in completed.stdout.splitlines():
        if len(line) < 4:
            continue
        status = line[:2]
        raw_path = line[3:]
        if " -> " in raw_path:
            raw_path = raw_path.rsplit(" -> ", 1)[-1]
        paths.append((status, _normalise(raw_path)))
    return paths


def _looks_like_convo_engine_record(root: Path, relative: str) -> bool:
    path = root / relative
    if path.suffix.lower() != ".json" or not path.is_file():
        return any(part in {"semantic_dialogue", "semantic-dialogue"} for part in Path(relative).parts)
    document = _read_json(path)
    return isinstance(document, Mapping) and document.get("schema") == CONVO_ENGINE_SCHEMA


def guard_changed_paths(
    repositories: Mapping[str, Path],
    *,
    changed_paths: Mapping[str, Iterable[str]] | None = None,
) -> dict[str, Any]:
    """Reject changed first-party authoring under frozen superseded roots."""

    results: list[dict[str, Any]] = []
    violations: list[dict[str, Any]] = []
    for name, root in repositories.items():
        candidates = (
            [("??", _normalise(path)) for path in changed_paths.get(name, ())]
            if changed_paths is not None and name in changed_paths
            else _status_paths(root)
        )
        accepted: list[dict[str, str]] = []
        repo_violations: list[dict[str, str]] = []
        for status, relative in candidates:
            if _is_under(relative, GENERATED_PREFIXES[name]):
                accepted.append({"path": relative, "reason": "generated_output_or_translation_boundary"})
                continue
            if "D" in status:
                accepted.append({"path": relative, "reason": "superseded_source_removal"})
                continue
            if not _is_under(relative, FROZEN_PREFIXES[name]):
                reason = "convo_engine_record" if _looks_like_convo_engine_record(root, relative) else "outside_frozen_authoring_root"
                accepted.append({"path": relative, "reason": reason})
                continue
            if Path(relative).name == "manifest.json" or _looks_like_convo_engine_record(root, relative):
                accepted.append({
                    "path": relative,
                    "reason": "manifest_control_plane" if Path(relative).name == "manifest.json" else "convo_engine_record",
                })
                continue
            repo_violations.append({
                "repository": name,
                "path": relative,
                "status": status,
                "code": "new_first_party_authoring_on_frozen_surface",
                "message": "New or modified first-party dialogue authoring must be added as a Core-compiled ConvoEngine record, not to a frozen superseded surface.",
            })
        result = {
            "repository": name,
            "root": str(root),
            "changed_paths": [path for _status, path in candidates],
            "accepted": sorted(accepted, key=lambda item: item["path"]),
            "violations": sorted(repo_violations, key=lambda item: item["path"]),
        }
        results.append(result)
        violations.extend(repo_violations)
    return {
        "schema": GUARD_SCHEMA,
        "passed": not violations,
        "repositories": results,
        "violations": violations,
    }


def build_inventory(repository_specs: Mapping[str, Path]) -> dict[str, Any]:
    surfaces: list[dict[str, Any]] = []
    repository_reports: list[dict[str, Any]] = []
    for name, root in repository_specs.items():
        state = _git_state(root)
        repo_surfaces = [_surface_report(root, surface) for surface in SURFACES[name]]
        surfaces.extend({"repository": name, **surface} for surface in repo_surfaces)
        repository_reports.append({
            "name": name,
            "root": str(root),
            "git": state,
            "surfaceCount": len(repo_surfaces),
        })
    guard = guard_changed_paths(repository_specs)
    classifications = Counter(surface["classification"] for surface in surfaces)
    owners = Counter(surface["owner"] for surface in surfaces)
    return {
        "schema": AUDIT_SCHEMA,
        "generatedAtUtc": _datetime.datetime.now(_datetime.timezone.utc).isoformat(),
        "scope": {
            "primary": "PsychopatzCore",
            "mandatory_adopters": ["ProjectHoomans", "DynamicTrading"],
            "scope": "convo-engine-authoring-audit",
        },
        "repositories": repository_reports,
        "surfaces": surfaces,
        "summary": {
            "repositoryCount": len(repository_reports),
            "surfaceCount": len(surfaces),
            "classifications": dict(sorted(classifications.items())),
            "owners": dict(sorted(owners.items())),
        },
        "guard": guard,
    }


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", action="append", required=True, metavar="NAME=PATH")
    parser.add_argument("--output", type=Path)
    parser.add_argument("--check", action="store_true", help="return non-zero when the no-new-authoring guard fails")
    return parser


def main(argv: list[str] | None = None) -> int:
    options = _parser().parse_args(argv)
    repository_specs: dict[str, Path] = {}
    for raw_spec in options.repo:
        name, root = _repo_spec(raw_spec)
        repository_specs[name] = root
    missing = set(SURFACES) - set(repository_specs)
    if missing:
        raise SystemExit(f"all three repositories are required; missing {sorted(missing)}")
    report = build_inventory(repository_specs)
    rendered = json.dumps(report, indent=2, sort_keys=True) + "\n"
    if options.output:
        options.output.parent.mkdir(parents=True, exist_ok=True)
        options.output.write_text(rendered, encoding="utf-8")
    else:
        print(rendered, end="")
    if options.check and not report["guard"]["passed"]:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
