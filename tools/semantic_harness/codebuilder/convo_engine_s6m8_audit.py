"""S6M8 three-repository ConvoEngine integrity, hygiene, and determinism audit."""

from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path
from typing import Any, Mapping

from .convo_engine_authoring import (
    _STALE_MIGRATION_METADATA_KEYS,
    _STALE_MIGRATION_TOP_KEYS,
)
from .conversation_compiler import compile_conversation_sources
from .errors import CompileError
from .generation_ownership import (
    CORE_OWNER,
    DT_COMMON_OWNER,
    HOOMANS_OWNER,
    generated_conversation_root,
    package_descriptor,
)
from .psdl_compiler import CONVO_ENGINE_SCHEMA, LEGACY_PSDL_SCHEMA


CONVO_FAMILY_SUBDIRS = ("dialogue", "behavior", "beat", "realization")
_NUMERIC_FAMILY_SUFFIX_RE = re.compile(r"(?:\.line_|_|\.)0*[1-9][0-9]*$")


def _sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _source_roots_by_owner(
    core_repository: Path,
    hoomans_repository: Path | None,
    dynamic_trading_repository: Path | None,
) -> dict[str, Path]:
    roots: dict[str, Path] = {
        CORE_OWNER: (
            core_repository / "tools/semantic_harness/codebuilder/sources/conversation"
        ).resolve(),
    }
    if hoomans_repository is not None:
        roots[HOOMANS_OWNER] = (
            hoomans_repository / "tools/providers/pnc/codebuilder/sources/conversation"
        ).resolve()
    if dynamic_trading_repository is not None:
        roots[DT_COMMON_OWNER] = (
            dynamic_trading_repository / "tools/providers/dt/codebuilder/sources/conversation"
        ).resolve()
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
        code = "legacy_schema_present" if schema == LEGACY_PSDL_SCHEMA else "unexpected_schema"
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


def _collect_generated_hashes(
    core_repository: Path,
    hoomans_repository: Path | None,
    dynamic_trading_repository: Path | None,
) -> dict[str, str]:
    hashes: dict[str, str] = {}
    runtime_base = hoomans_repository or core_repository
    pairs: list[tuple[str, Path]] = [(CORE_OWNER, core_repository)]
    if hoomans_repository is not None:
        pairs.append((HOOMANS_OWNER, hoomans_repository))
    if dynamic_trading_repository is not None:
        pairs.append((DT_COMMON_OWNER, dynamic_trading_repository))

    for owner, repo_root in pairs:
        conv_root = generated_conversation_root(
            runtime_base,
            owner,
            core_repository=core_repository,
            dynamic_trading_repository=dynamic_trading_repository,
            runtime_root=runtime_base,
        )
        if conv_root.is_dir():
            for lua_file in sorted(conv_root.rglob("*.lua")):
                hashes[f"lua:{owner}:{lua_file.relative_to(repo_root)}"] = _sha256_file(lua_file)
        desc = package_descriptor(owner)
        trans_root = repo_root / desc.translation_relative
        for lang in ("EN", "TL"):
            lang_conv = trans_root / lang / "Conversation"
            if lang_conv.is_dir():
                for json_file in sorted(lang_conv.rglob("*.json")):
                    hashes[f"tr:{owner}:{json_file.relative_to(repo_root)}"] = _sha256_file(json_file)
    return hashes


def audit_convo_engine_workspace(
    core_repository: str | Path,
    *,
    hoomans_repository: str | Path | None = None,
    dynamic_trading_repository: str | Path | None = None,
    check_determinism: bool = False,
) -> dict[str, Any]:
    """Run the S6M8 three-repository ConvoEngine architectural and determinism audit."""
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
    }

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
            manifest_path=manifest_path,
            runtime_root=runtime_base,
            package_repositories=package_repositories,
        )
        compiled_summary = {
            "fingerprint": compiled.get("wholeModelFingerprint"),
            "patterns": len(compiled.get("dialogue", {}).get("patterns", [])),
            "uiDefinitions": len(compiled.get("ui", [])),
            "convoPlans": len(compiled.get("psdlRuntimePlans", [])),
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
        from .build import write_conversation_output

        write_conversation_output(
            runtime_base,
            compiled,
            core_repository=core_root,
            dynamic_trading_repository=dt_root,
        )
        first_hashes = _collect_generated_hashes(core_root, hoomans_root, dt_root)

        compiled_second = compile_conversation_sources(
            runtime_base,
            manifest_path=manifest_path,
            runtime_root=runtime_base,
            package_repositories=package_repositories,
        )
        write_conversation_output(
            runtime_base,
            compiled_second,
            core_repository=core_root,
            dynamic_trading_repository=dt_root,
        )
        second_hashes = _collect_generated_hashes(core_root, hoomans_root, dt_root)
        diff_keys = sorted(
            key
            for key in set(first_hashes) | set(second_hashes)
            if first_hashes.get(key) != second_hashes.get(key)
        )
        determinism_summary["fileCount"] = len(second_hashes)
        determinism_summary["diffs"] = diff_keys
        for key in diff_keys:
            violations.append({
                "code": "non_deterministic_build_output",
                "owner": CORE_OWNER,
                "path": key,
                "message": f"Two-pass build output differed for {key}",
            })

    return {
        "ok": len(violations) == 0,
        "schema": "psychopatz.convo-engine.s6m8-audit.v1",
        "stats": stats,
        "compiled": compiled_summary,
        "determinism": determinism_summary,
        "violationCount": len(violations),
        "violations": violations,
    }
