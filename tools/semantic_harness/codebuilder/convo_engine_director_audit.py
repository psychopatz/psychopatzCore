"""Fail-closed S13D/S13E Conversation Director layout & readiness audit."""

from __future__ import annotations

import re
from pathlib import Path
from typing import Any, Mapping

from .conversation_compiler import (
    compile_conversation_sources,
    render_conversation_runtime_plan,
)
from .convo_engine_director_index import (
    FORBIDDEN_DIRECTOR_INDEX_FIELDS,
    build_director_index,
)
from .errors import CompileError
from .generation_ownership import (
    CORE_OWNER,
    DT_COMMON_OWNER,
    HOOMANS_OWNER,
    generated_conversation_root,
    normalize_owner,
)
from .workspace_catalog import WorkspaceCatalog


DIRECTOR_READINESS_SCHEMA = "psychopatz.convo-engine.director-readiness.v1"

_RETIRED_PROJECTION_PATTERN = re.compile(r"Behaviors/Director|Beats/Director")
_FORBIDDEN_INDEX_LUA_KEYS_RE = re.compile(
    r'\["(?:' + "|".join(sorted(FORBIDDEN_DIRECTOR_INDEX_FIELDS)) + r')"\]\s*='
)
_SCAN_SUFFIXES = frozenset({".lua", ".py", ".json"})
_SKIP_DIR_NAMES = frozenset({".git", ".venv", "__pycache__", "node_modules", "docs", "Docs"})


def _resolve_repos(
    core_repository: Path,
    hoomans_repository: Path | None,
    dynamic_trading_repository: Path | None,
) -> tuple[Path, Path | None, Path | None]:
    core_root = core_repository.expanduser().resolve()
    snapshot = WorkspaceCatalog.discover(
        core_root,
        core_repository=core_root,
        hoomans_repository=hoomans_repository,
        dynamic_trading_repository=dynamic_trading_repository,
        allow_sibling_discovery=False,
    )
    repos = getattr(snapshot, "repositories_by_owner", {}) or {}
    hoomans_root = (
        hoomans_repository.expanduser().resolve()
        if hoomans_repository is not None
        else repos.get(HOOMANS_OWNER)
    )
    dt_root = (
        dynamic_trading_repository.expanduser().resolve()
        if dynamic_trading_repository is not None
        else repos.get(DT_COMMON_OWNER)
    )
    return core_root, hoomans_root, dt_root


def _iter_code_files(root: Path):
    for child in root.rglob("*"):
        if not child.is_file():
            continue
        if child.suffix not in _SCAN_SUFFIXES:
            continue
        if any(part in _SKIP_DIR_NAMES for part in child.parts):
            continue
        yield child


def audit_convo_engine_director_readiness(
    core_repository: Path,
    *,
    hoomans_repository: Path | None = None,
    dynamic_trading_repository: Path | None = None,
    compiled_model: Mapping[str, Any] | None = None,
    require_director_records: bool = True,
) -> dict[str, Any]:
    """Verify S13D single-artifact projections and S13E Director readiness freeze."""
    core_root, hoomans_root, dt_root = _resolve_repos(
        core_repository, hoomans_repository, dynamic_trading_repository
    )
    runtime_base = hoomans_root or core_root

    owner_repos: list[tuple[str, Path]] = [(CORE_OWNER, core_root)]
    pkg_repos: dict[str, Path] = {CORE_OWNER: core_root}
    if hoomans_root is not None:
        owner_repos.append((HOOMANS_OWNER, hoomans_root))
        pkg_repos[HOOMANS_OWNER] = hoomans_root
    if dt_root is not None:
        owner_repos.append((DT_COMMON_OWNER, dt_root))
        pkg_repos[DT_COMMON_OWNER] = dt_root

    retired_behavior_files: list[str] = []
    retired_beat_files: list[str] = []
    for owner, _repo in owner_repos:
        conv_root = generated_conversation_root(
            runtime_base,
            owner,
            core_repository=core_root,
            dynamic_trading_repository=dt_root,
            runtime_root=runtime_base,
        )
        retired_beh_dir = conv_root / "Behaviors" / "Director"
        if retired_beh_dir.is_dir():
            for hit in sorted(retired_beh_dir.rglob("*.lua")):
                retired_behavior_files.append(str(hit))
        retired_beat_dir = conv_root / "Beats" / "Director"
        if retired_beat_dir.is_dir():
            for hit in sorted(retired_beat_dir.rglob("*.lua")):
                retired_beat_files.append(str(hit))

    compile_error: str | None = None
    if compiled_model is not None:
        compiled = dict(compiled_model)
    else:
        try:
            compiled = compile_conversation_sources(
                runtime_base,
                runtime_root=runtime_base,
                package_repositories=pkg_repos,
            )
        except CompileError as error:
            compiled = None
            compile_error = str(error)

    rendered: list[tuple[str, str]] = []
    reports: list[dict[str, Any]] = []
    if compiled is not None:
        rendered, reports = render_conversation_runtime_plan(compiled)

    behavior_modules_by_id: dict[str, list[str]] = {}
    beat_modules_by_id: dict[str, list[str]] = {}
    kind_by_id: dict[str, str] = {}
    if compiled is not None:
        for plan in compiled.get("convoRuntimePlans") or ():
            rec_id = str(plan.get("id") or "")
            kind = str(plan.get("kind") or "").lower()
            if rec_id:
                kind_by_id[rec_id] = kind

    for report in reports:
        if report.get("kind") in ("Index", "IndexRegistry"):
            continue
        mod = str(report.get("module") or "")
        for rec_id in report.get("recordIDs") or ():
            r_kind = kind_by_id.get(str(rec_id), "")
            if r_kind == "behavior":
                behavior_modules_by_id.setdefault(str(rec_id), []).append(mod)
            elif r_kind == "beat":
                beat_modules_by_id.setdefault(str(rec_id), []).append(mod)

    multi_behavior_ids = {
        rec_id: mods for rec_id, mods in behavior_modules_by_id.items() if len(mods) > 1
    }
    multi_beat_ids = {
        rec_id: mods for rec_id, mods in beat_modules_by_id.items() if len(mods) > 1
    }

    self_path = Path(__file__).resolve()
    obsolete_callers: list[dict[str, Any]] = []
    for _owner, repo_root in owner_repos:
        for scan_root in (
            repo_root / "Contents",
            repo_root / "tools",
            repo_root / "tests",
        ):
            if not scan_root.is_dir():
                continue
            for file_path in sorted(_iter_code_files(scan_root)):
                if file_path.resolve() == self_path:
                    continue
                try:
                    text = file_path.read_text(encoding="utf-8")
                except (OSError, UnicodeDecodeError):
                    continue
                if _RETIRED_PROJECTION_PATTERN.search(text):
                    obsolete_callers.append({"path": str(file_path)})

    # Check Director index payloads in memory + generated Lua on disk
    rendered_map = {mod: src for mod, src in rendered}
    director_index_modules = [
        mod for mod in rendered_map if mod.endswith("/Index/Director")
    ]
    index_duplication_hits: list[dict[str, Any]] = []
    for mod in director_index_modules:
        src = rendered_map[mod]
        bad_keys = sorted(set(_FORBIDDEN_INDEX_LUA_KEYS_RE.findall(src)))
        if bad_keys:
            index_duplication_hits.append({"module": mod, "forbiddenKeys": bad_keys})

    on_disk_index_files: list[str] = []
    for owner, _repo in owner_repos:
        conv_root = generated_conversation_root(
            runtime_base,
            owner,
            core_repository=core_root,
            dynamic_trading_repository=dt_root,
            runtime_root=runtime_base,
        )
        idx_file = conv_root / "Index" / "Director.lua"
        if idx_file.is_file():
            on_disk_index_files.append(str(idx_file))
            try:
                text = idx_file.read_text(encoding="utf-8")
            except OSError:
                text = ""
            bad_keys = sorted(set(_FORBIDDEN_INDEX_LUA_KEYS_RE.findall(text)))
            if bad_keys:
                index_duplication_hits.append({"path": str(idx_file), "forbiddenKeys": bad_keys})

    # S13E 8 Director Readiness Invariants
    full_index = build_director_index(compiled, reports) if compiled is not None else {
        "entries": {},
        "byStimulus": {},
        "byDomain": {},
        "byTopic": {},
        "byActivity": {},
        "byEventType": {},
        "byRequiredFact": {},
        "byKind": {},
    }
    entries = full_index["entries"]
    behavior_entries = [e for e in entries.values() if e.get("kind") == "behavior"]
    beat_entries = [e for e in entries.values() if e.get("kind") == "beat"]
    plans_by_id = {
        str(p.get("id") or ""): p
        for p in ((compiled or {}).get("convoRuntimePlans") or ())
        if isinstance(p, Mapping) and p.get("id")
    }

    has_roles = bool(entries) and all(
        isinstance(e.get("roleSpec"), Mapping) and bool(e["roleSpec"].get("roles"))
        for e in entries.values()
    )
    has_hooks = bool(full_index["byStimulus"]) and bool(full_index["byDomain"]) and all(
        all(k in e for k in ("stimuli", "domains", "topics", "events", "activities", "memories"))
        for e in entries.values()
    )
    has_required_facts = bool(full_index["byRequiredFact"]) and all(
        isinstance(e.get("requiredFacts"), list)
        for e in entries.values()
    )
    has_scoring_meta = bool(behavior_entries) and bool(beat_entries) and all(
        isinstance(e.get("baseRelevance"), (int, float))
        for e in entries.values()
    ) and all(
        isinstance(e.get("cooldownTurns"), int) and isinstance(e.get("maxTurns"), int)
        for e in beat_entries
    )
    has_continuation = all(
        (
            not isinstance((plans_by_id[e["id"]].get("payload") or {}).get("continuation"), Mapping)
            or bool(e.get("continuationMode"))
        )
        for e in behavior_entries
    ) and all(
        isinstance((plans_by_id[e["id"]].get("payload") or {}).get("exit"), Mapping)
        for e in beat_entries
    )
    catalog_ok = True
    if hoomans_root is not None:
        catalog_path = (
            hoomans_root
            / "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/ConvoEngine/Interaction/Catalog.lua"
        )
        if not catalog_path.is_file():
            catalog_ok = False
        else:
            cat_text = catalog_path.read_text(encoding="utf-8")
            catalog_ok = ("Catalog.Behaviors" in cat_text) and ("Catalog.Beats" in cat_text)
    has_compact_index_seam = bool(director_index_modules) and bool(on_disk_index_files)
    translation_key_ok = all(
        not isinstance(
            ((plans_by_id[e["id"]].get("payload") or {}).get("outputs") or {}).get("speech"),
            Mapping,
        )
        or bool(
            (plans_by_id[e["id"]]["payload"]["outputs"]["speech"]).get("contentTemplateID")
        )
        for e in behavior_entries
    )

    if not require_director_records and not entries:
        readiness_checks = {
            "participantSetAndRoleSpec": True,
            "stimulusDomainTopicEventActivityMemoryHooks": True,
            "requiredFactMetadata": True,
            "baseRelevanceCooldownDiversityMetadata": True,
            "continuationClosureInformation": True,
            "canonicalValidationEntryPoint": True,
            "compactIndexGenerationSeam": True,
            "translationKeyBasedRealization": True,
        }
        missing_capabilities = []
    else:
        readiness_checks = {
            "participantSetAndRoleSpec": has_roles,
            "stimulusDomainTopicEventActivityMemoryHooks": has_hooks,
            "requiredFactMetadata": has_required_facts,
            "baseRelevanceCooldownDiversityMetadata": has_scoring_meta,
            "continuationClosureInformation": has_continuation,
            "canonicalValidationEntryPoint": catalog_ok,
            "compactIndexGenerationSeam": has_compact_index_seam,
            "translationKeyBasedRealization": translation_key_ok,
        }
        missing_capabilities = [name for name, passed in readiness_checks.items() if not passed]

    counters = {
        "duplicateBehaviorProjectionBodies": len(retired_behavior_files) + len(multi_behavior_ids),
        "duplicateBeatProjectionBodies": len(retired_beat_files) + len(multi_beat_ids),
        "obsoleteDirectorProjectionCallers": len(obsolete_callers),
        "directorIndexBodyDuplicationCount": len(index_duplication_hits),
        "missingDirectorReadinessCapabilityCount": len(missing_capabilities),
    }

    return {
        "schema": DIRECTOR_READINESS_SCHEMA,
        "ok": all(value == 0 for value in counters.values()),
        "counters": counters,
        "readinessChecks": readiness_checks,
        "stats": {
            "behaviorCount": len(behavior_entries),
            "beatCount": len(beat_entries),
            "directorIndexModules": sorted(director_index_modules),
            "onDiskIndexFiles": sorted(on_disk_index_files),
            "sparseIndexBuckets": {
                "byStimulus": len(full_index["byStimulus"]),
                "byDomain": len(full_index["byDomain"]),
                "byTopic": len(full_index["byTopic"]),
                "byActivity": len(full_index["byActivity"]),
                "byEventType": len(full_index["byEventType"]),
                "byRequiredFact": len(full_index["byRequiredFact"]),
                "byKind": len(full_index["byKind"]),
            },
        },
        "details": {
            "retiredBehaviorFiles": retired_behavior_files,
            "retiredBeatFiles": retired_beat_files,
            "multiBehaviorIds": multi_behavior_ids,
            "multiBeatIds": multi_beat_ids,
            "obsoleteCallers": obsolete_callers,
            "indexDuplicationHits": index_duplication_hits,
            "missingCapabilities": missing_capabilities,
        },
    }


__all__ = [
    "DIRECTOR_READINESS_SCHEMA",
    "audit_convo_engine_director_readiness",
]
