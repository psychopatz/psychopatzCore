"""Three-repository ConvoEngine integrity, hygiene, and determinism audit."""

from __future__ import annotations

import json
import os
import re
from pathlib import Path
from typing import Any, Mapping

from .convo_engine_authoring import (
    _STALE_MIGRATION_METADATA_KEYS,
    _STALE_MIGRATION_TOP_KEYS,
)
from .convo_engine_naming_audit import scan_active_legacy_name_leakage
from .conversation_compiler import compile_conversation_sources
from .errors import CompileError
from .generation_ownership import (
    CORE_OWNER,
    DT_COMMON_OWNER,
    HOOMANS_OWNER,
    generated_conversation_root,
)
from .convo_engine_compiler import CONVO_ENGINE_SCHEMA
from .workspace_catalog import WorkspaceCatalog


CONVO_FAMILY_SUBDIRS = ("dialogue", "behavior", "beat", "realization")
_NUMERIC_FAMILY_SUFFIX_RE = re.compile(r"(?:\.line_|_|\.)0*[1-9][0-9]*$")


def _source_roots_by_owner(
    core_repository: Path,
    hoomans_repository: Path | None,
    dynamic_trading_repository: Path | None,
) -> dict[str, Path]:
    snapshot = WorkspaceCatalog.discover(
        core_repository,
        core_repository=core_repository,
        hoomans_repository=hoomans_repository,
        dynamic_trading_repository=dynamic_trading_repository,
        allow_sibling_discovery=False,
    )
    roots: dict[str, Path] = {
        CORE_OWNER: snapshot.source_roots_by_owner.get(
            CORE_OWNER,
            (core_repository / "tools/semantic_harness/codebuilder/sources/conversation").resolve(),
        ),
    }
    if hoomans_repository is not None:
        roots[HOOMANS_OWNER] = snapshot.source_roots_by_owner.get(
            HOOMANS_OWNER,
            (hoomans_repository / "tools/providers/pnc/codebuilder/sources/conversation").resolve(),
        )
    if dynamic_trading_repository is not None:
        roots[DT_COMMON_OWNER] = snapshot.source_roots_by_owner.get(
            DT_COMMON_OWNER,
            (dynamic_trading_repository / "tools/providers/dt/codebuilder/sources/conversation").resolve(),
        )
    for owner, root in snapshot.source_roots_by_owner.items():
        roots.setdefault(owner, root)
    return roots


def _check_source_file(
    owner: str,
    family_dir: Path,
    file_path: Path,
    source_root: Path,
    violations: list[dict[str, Any]],
) -> None:
    rel = str(file_path.relative_to(source_root))
    try:
        doc = json.loads(file_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        violations.append({
            "code": "invalid_json",
            "owner": owner,
            "path": str(file_path),
            "message": str(error),
        })
        return
    if not isinstance(doc, Mapping):
        violations.append({
            "code": "invalid_document_type",
            "owner": owner,
            "path": str(file_path),
            "message": "ConvoEngine source must be a JSON object",
        })
        return

    schema = doc.get("schema")
    if schema != CONVO_ENGINE_SCHEMA:
        code = "legacy_schema_present" if schema in {"psychopatz.semantic.dialogue-language.v1", "psychopatz.psdl.v2"} else "unexpected_schema"
        violations.append({
            "code": code,
            "owner": owner,
            "path": str(file_path),
            "message": f"{rel} uses schema {schema!r}, expected {CONVO_ENGINE_SCHEMA!r}",
        })

    if "records" in doc:
        violations.append({
            "code": "multi_record_bucket_present",
            "owner": owner,
            "path": str(file_path),
            "message": f"{rel} still uses a top-level records array instead of one family per file",
        })

    family_id = doc.get("id")
    namespace = doc.get("namespace")
    if not isinstance(family_id, str) or not family_id.strip():
        violations.append({
            "code": "missing_family_id",
            "owner": owner,
            "path": str(file_path),
            "message": f"{rel} is missing family id",
        })
    else:
        if family_id.startswith("semantic.") or (
            isinstance(namespace, str) and namespace.startswith("semantic.")
        ):
            violations.append({
                "code": "redundant_semantic_prefix",
                "owner": owner,
                "path": str(file_path),
                "message": f"{rel} retains redundant 'semantic.' prefix ({namespace}.{family_id})",
            })
        if _NUMERIC_FAMILY_SUFFIX_RE.search(family_id):
            violations.append({
                "code": "wording_numeric_family_id",
                "owner": owner,
                "path": str(file_path),
                "message": f"{rel} uses numeric wording suffix in family id {family_id!r}",
            })

    for stale_key in _STALE_MIGRATION_TOP_KEYS:
        if stale_key in doc:
            violations.append({
                "code": "stale_migration_metadata",
                "owner": owner,
                "path": str(file_path),
                "message": f"{rel} retains stale top-level migration key {stale_key!r}",
            })
    metadata = doc.get("metadata")
    if isinstance(metadata, Mapping):
        for stale_key in _STALE_MIGRATION_METADATA_KEYS:
            if stale_key in metadata:
                violations.append({
                    "code": "stale_migration_metadata",
                    "owner": owner,
                    "path": str(file_path),
                    "message": f"{rel} retains stale metadata.{stale_key!r}",
                })


def _is_owner_repository(owner: str, candidate: Path) -> bool:
    """Return True when *candidate* has verified provider/mod markers for *owner*."""
    if not candidate.is_dir():
        return False
    if owner == CORE_OWNER:
        return (
            candidate
            / "tools/semantic_harness/codebuilder/sources/conversation/manifest.json"
        ).is_file()
    if owner == HOOMANS_OWNER:
        return (
            candidate / "tools/providers/pnc/codebuilder/sources/conversation"
        ).is_dir() and (candidate / "Contents/mods/ProjectHoomans").is_dir()
    if owner == DT_COMMON_OWNER:
        return (
            candidate / "tools/providers/dt/codebuilder/sources/conversation"
        ).is_dir() and (candidate / "Contents/mods/DTCommon").is_dir()
    return False


def _resolve_owner_repository(
    owner: str,
    *,
    explicit: Path | None,
    candidates: list[Path],
    flag_hint: str,
) -> Path | None:
    if explicit is not None:
        return explicit.expanduser().resolve()
    env_name = package_descriptor(owner).repository_environment
    if env_name:
        env_val = os.environ.get(env_name)
        if env_val:
            return Path(env_val).expanduser().resolve()
    matched = [path for path in candidates if _is_owner_repository(owner, path)]
    unique: list[Path] = []
    seen: set[Path] = set()
    for path in matched:
        resolved = path.resolve()
        if resolved not in seen:
            seen.add(resolved)
            unique.append(resolved)
    if len(unique) > 1:
        joined = ", ".join(str(p) for p in unique)
        raise CompileError(
            f"Ambiguous {owner} repository discovery ({joined}); pass {flag_hint} or set {env_name}"
        )
    return unique[0] if unique else None


def discover_convo_engine_repositories(
    anchor: str | Path,
    *,
    repository: str | Path | None = None,
    core_repository: str | Path | None = None,
    hoomans_repository: str | Path | None = None,
    dynamic_trading_repository: str | Path | None = None,
) -> dict[str, Path | None]:
    """Resolve Core, Hoomans, and DTCommon repositories via WorkspaceCatalog."""
    snapshot = WorkspaceCatalog.discover(
        anchor,
        repository=repository,
        core_repository=core_repository,
        hoomans_repository=hoomans_repository,
        dynamic_trading_repository=dynamic_trading_repository,
        allow_sibling_discovery=True,
    )
    return {
        CORE_OWNER: snapshot.repository_for(CORE_OWNER),
        HOOMANS_OWNER: snapshot.repository_for(HOOMANS_OWNER),
        DT_COMMON_OWNER: snapshot.repository_for(DT_COMMON_OWNER),
    }


def audit_split_action_authority(runtime_plans: list[Mapping[str, Any]]) -> list[dict[str, Any]]:
    """Detect ``LEGACY_SPLIT_AUTHORITY`` where one mutating semantic action is split across families."""
    by_action: dict[str, list[dict[str, Any]]] = {}
    by_execute: dict[str, list[dict[str, Any]]] = {}
    for plan in runtime_plans:
        fid = str(plan.get("id") or "")
        owner = str(plan.get("owner") or CORE_OWNER)
        payload = plan.get("payload") if isinstance(plan.get("payload"), Mapping) else {}
        invoke = payload.get("invoke") if isinstance(payload.get("invoke"), Mapping) else {}
        invoke_action = str(invoke.get("action") or "").strip().upper()
        aff = payload.get("affordance") if isinstance(payload.get("affordance"), Mapping) else {}
        aff_meta = aff.get("metadata") if isinstance(aff.get("metadata"), Mapping) else {}
        aff_action = str(aff_meta.get("action") or "").strip().upper()
        exec_val = payload.get("execute")
        exec_id = (
            str(exec_val.get("use") or "").strip()
            if isinstance(exec_val, Mapping)
            else str(exec_val or "").strip()
        )
        info = {
            "id": fid,
            "owner": owner,
            "path": str(((plan.get("lineage") or {}).get("sourcePath")) or fid),
            "invokeAction": invoke_action,
            "affordanceAction": aff_action,
            "execute": exec_id,
            "hasStatePolicy": bool(payload.get("statePolicy")),
            "hasReply": bool(payload.get("reply")),
            "hasAffordance": bool(aff),
            "hasWhen": plan.get("when") is not None or payload.get("when") is not None,
        }
        for act in {a for a in (invoke_action, aff_action) if a}:
            by_action.setdefault(act, []).append(info)
        if exec_id:
            by_execute.setdefault(exec_id, []).append(info)

    violations: list[dict[str, Any]] = []
    seen_pairs: set[tuple[str, tuple[str, ...]]] = set()

    def _check_group(group_key: str, kind: str, items: list[dict[str, Any]]) -> None:
        if len(items) < 2:
            return
        policy_only = [i for i in items if i["hasStatePolicy"] and not i["execute"] and not i["hasReply"]]
        content_only = [i for i in items if (i["execute"] or i["hasReply"] or i["hasAffordance"]) and not i["hasStatePolicy"]]
        has_split = bool(policy_only and content_only)
        mutating_unconditional = [i for i in items if i["execute"] and not i["hasWhen"]]
        if not has_split and len(mutating_unconditional) < 2:
            return
        family_ids = tuple(sorted(i["id"] for i in items))
        dedupe_key = (f"{kind}:{group_key}", family_ids)
        if dedupe_key in seen_pairs:
            return
        seen_pairs.add(dedupe_key)
        violations.append({
            "code": "LEGACY_SPLIT_AUTHORITY",
            "owner": items[0]["owner"],
            "path": items[0]["path"],
            "action": group_key,
            "families": list(family_ids),
            "message": (
                f"{kind} {group_key!r} is split across multiple families: "
                + ", ".join(family_ids)
            ),
        })

    for action_name, items in sorted(by_action.items()):
        _check_group(action_name, "action", items)
    for exec_name, items in sorted(by_execute.items()):
        _check_group(exec_name, "execute", items)
    return violations


def audit_convo_engine_workspace(
    core_repository: str | Path,
    *,
    hoomans_repository: str | Path | None = None,
    dynamic_trading_repository: str | Path | None = None,
    check_determinism: bool = False,
    require_all_owners: bool = False,
) -> dict[str, Any]:
    """Run the three-repository ConvoEngine architectural and determinism audit."""
    core_root = Path(core_repository).expanduser().resolve()
    hoomans_root = (
        Path(hoomans_repository).expanduser().resolve()
        if hoomans_repository is not None
        else None
    )
    dt_root = (
        Path(dynamic_trading_repository).expanduser().resolve()
        if dynamic_trading_repository is not None
        else None
    )

    violations: list[dict[str, Any]] = []
    stats: dict[str, Any] = {
        "owners": [],
        "familyFilesChecked": 0,
        "psdlDirectories": 0,
        "catalogLuaLeaves": 0,
        "legacyRuntimeDirectories": 0,
        "legacyNameViolations": 0,
    }

    if require_all_owners:
        for owner_name, repo_opt, flag_hint in (
            (HOOMANS_OWNER, hoomans_root, "--hoomans-repository / PZ_TEST_HOOMANS_REPOSITORY"),
            (DT_COMMON_OWNER, dt_root, "--dynamic-trading-repository / PZ_TEST_DYNAMIC_TRADING_REPOSITORY"),
        ):
            if repo_opt is None or not _is_owner_repository(owner_name, repo_opt):
                violations.append({
                    "code": "missing_mandatory_repository",
                    "owner": owner_name,
                    "path": str(repo_opt) if repo_opt is not None else "",
                    "message": (
                        f"Mandatory participant repository for {owner_name} could not be resolved; "
                        f"pass {flag_hint}"
                    ),
                })

    source_roots = _source_roots_by_owner(core_root, hoomans_root, dt_root)
    for owner, source_root in source_roots.items():
        stats["owners"].append(owner)
        if not source_root.is_dir():
            violations.append({
                "code": "missing_source_root",
                "owner": owner,
                "path": str(source_root),
                "message": f"Conversation source root does not exist for {owner}: {source_root}",
            })
            continue
        psdl_dirs = [
            p for p in sorted(source_root.rglob("psdl")) if p.is_dir()
        ]
        stats["psdlDirectories"] += len(psdl_dirs)
        for pdir in psdl_dirs:
            violations.append({
                "code": "legacy_psdl_directory",
                "owner": owner,
                "path": str(pdir),
                "message": f"Legacy psdl directory still exists: {pdir}",
            })
        for subdir_name in CONVO_FAMILY_SUBDIRS:
            subdir = source_root / subdir_name
            if not subdir.is_dir():
                continue
            for file_path in sorted(subdir.rglob("*.json")):
                if "translations" in file_path.relative_to(source_root).parts:
                    continue
                stats["familyFilesChecked"] += 1
                _check_source_file(owner, subdir, file_path, source_root, violations)

    # Check generated runtime layouts across repositories.
    runtime_base = hoomans_root or core_root
    owner_repos: list[tuple[str, Path]] = [(CORE_OWNER, core_root)]
    if hoomans_root is not None:
        owner_repos.append((HOOMANS_OWNER, hoomans_root))
    if dt_root is not None:
        owner_repos.append((DT_COMMON_OWNER, dt_root))

    for owner, repo_root in owner_repos:
        conv_root = generated_conversation_root(
            runtime_base,
            owner,
            core_repository=core_root,
            dynamic_trading_repository=dt_root,
            runtime_root=runtime_base,
        )
        if not conv_root.is_dir():
            violations.append({
                "code": "missing_convo_engine_runtime_root",
                "owner": owner,
                "path": str(conv_root),
                "message": f"Missing ConvoEngine runtime root for {owner}: {conv_root}",
            })
        else:
            for leaf in sorted(conv_root.rglob("Catalog.lua")):
                stats["catalogLuaLeaves"] += 1
                violations.append({
                    "code": "vague_catalog_lua_leaf",
                    "owner": owner,
                    "path": str(leaf),
                    "message": f"Vague generated Catalog.lua leaf remains: {leaf}",
                })

        for forbidden_rel in (
            "Semantics/Generated/Conversation",
            "Conversation/PSDL",
        ):
            for hit in sorted(repo_root.glob(f"Contents/mods/*/common/media/lua/**/{forbidden_rel}")):
                if hit.exists():
                    stats["legacyRuntimeDirectories"] += 1
                    violations.append({
                        "code": "legacy_runtime_wrapper_directory",
                        "owner": owner,
                        "path": str(hit),
                        "message": f"Legacy conversation wrapper directory remains: {hit}",
                    })

    # Full compiler validation across the manifest and connected package repositories.
    manifest_path = core_root / "tools/semantic_harness/codebuilder/sources/conversation/manifest.json"
    package_repositories: dict[str, Path] = {CORE_OWNER: core_root}
    if hoomans_root is not None:
        package_repositories[HOOMANS_OWNER] = hoomans_root
    if dt_root is not None:
        package_repositories[DT_COMMON_OWNER] = dt_root

    compiled_summary: dict[str, Any] = {}
    try:
        compiled = compile_conversation_sources(
            runtime_base,
            manifest_path=None,
            runtime_root=runtime_base,
            package_repositories=package_repositories,
        )
        compiled_summary = {
            "fingerprint": compiled.get("wholeModelFingerprint"),
            "patterns": len(compiled.get("dialogue", {}).get("patterns", [])),
            "uiDefinitions": len(compiled.get("ui", [])),
            "convoPlans": len(compiled.get("convoRuntimePlans", [])),
        }
    except CompileError as error:
        violations.append({
            "code": "compile_validation_failed",
            "owner": CORE_OWNER,
            "path": str(manifest_path),
            "message": str(error),
        })
        compiled = None

    determinism_summary: dict[str, Any] = {"checked": check_determinism, "diffs": []}
    if check_determinism and compiled is not None:
        from .build_planner import BuildPlanner

        audit_workspace = WorkspaceCatalog.discover(
            core_root,
            core_repository=core_root,
            hoomans_repository=hoomans_root,
            dynamic_trading_repository=dt_root,
            allow_sibling_discovery=False,
        )
        determinism_summary = BuildPlanner.from_workspace(audit_workspace).verify_determinism(
            compiled_first=compiled,
        )
        for key in determinism_summary.get("diffs", []):
            violations.append({
                "code": "non_deterministic_build_output",
                "owner": CORE_OWNER,
                "path": key,
                "message": f"Two-pass build output differed for {key}",
            })

    if compiled is not None:
        split_violations = audit_split_action_authority(compiled.get("convoRuntimePlans") or [])
        stats["splitAuthorityViolations"] = len(split_violations)
        violations.extend(split_violations)

    leakage = scan_active_legacy_name_leakage(
        core_repository=core_root,
        hoomans_repository=hoomans_root,
        dynamic_trading_repository=dt_root,
    )
    stats["legacyNameViolations"] = len(leakage["violations"])
    violations.extend(leakage["violations"])

    return {
        "ok": len(violations) == 0,
        "schema": "psychopatz.convo-engine.integrity-audit.v1",
        "stats": stats,
        "compiled": compiled_summary,
        "determinism": determinism_summary,
        "violationCount": len(violations),
        "violations": violations,
    }
