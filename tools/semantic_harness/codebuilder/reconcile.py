#!/usr/bin/env python3
"""Recipe-driven check/apply reconciler for Semantic CodeBuilder artifacts."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from collections.abc import Mapping
from pathlib import Path, PurePosixPath
from typing import Any


ROOT = Path(__file__).resolve().parents[3]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

if __package__ in {None, ""}:
    from tools.semantic_harness.codebuilder.errors import CompileError
    from tools.semantic_harness.codebuilder.generation_ownership import (
        CORE_OWNER,
        DT_COMMON_OWNER,
        HOOMANS_OWNER,
        generated_conversation_root,
        normalize_owner,
        package_descriptor,
        translation_root,
    )
    from tools.semantic_harness.codebuilder.generation_recipe import (
        DEFAULT_RECIPE_PATH,
        DesiredArtifactLedger,
        DesiredArtifactRow,
        GenerationRecipe,
        RetiredEntry,
        build_desired_artifact_ledger,
        load_generation_recipe,
        sha256_text,
    )
    from tools.semantic_harness.codebuilder.lexicon_compiler import DEFAULT_ALLOWLIST
    from tools.semantic_harness.codebuilder.translation_support import (
        normalize_language,
        pretty_json,
    )
else:
    from .errors import CompileError
    from .generation_ownership import (
        CORE_OWNER,
        DT_COMMON_OWNER,
        HOOMANS_OWNER,
        generated_conversation_root,
        normalize_owner,
        package_descriptor,
        translation_root,
    )
    from .generation_recipe import (
        DEFAULT_RECIPE_PATH,
        DesiredArtifactLedger,
        DesiredArtifactRow,
        GenerationRecipe,
        RetiredEntry,
        build_desired_artifact_ledger,
        load_generation_recipe,
        sha256_text,
    )
    from .lexicon_compiler import DEFAULT_ALLOWLIST
    from .translation_support import normalize_language, pretty_json


RECONCILIATION_REPORT_SCHEMA = "psychopatz.semantic-generation-reconcile.v1"
GENERATION_RECEIPT_SCHEMA = "psychopatz.semantic-generation-receipt.v1"


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while chunk := handle.read(65536):
            digest.update(chunk)
    return digest.hexdigest()


def _has_generated_lua_header(path: Path, marker: str = "-- Generated") -> bool:
    try:
        with path.open("r", encoding="utf-8", errors="replace") as handle:
            first_line = handle.readline()
    except OSError:
        return False
    return first_line.startswith(marker) and "do not edit by hand." in first_line


def _read_string_map(path: Path) -> dict[str, str]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise CompileError(f"Cannot read translation JSON {path}: {error}") from error
    if not isinstance(data, dict) or any(
        not isinstance(k, str) or not isinstance(v, str)
        for k, v in data.items()
    ):
        raise CompileError(f"Translation catalog must be a flat string map: {path}")
    return dict(data)


def load_owner_receipt(
    receipt_root: Path | None,
    owner: str,
) -> dict[str, Any]:
    """Load an optional prior generation receipt for *owner*."""
    if receipt_root is None:
        return {}
    norm_owner = normalize_owner(owner)
    path = Path(receipt_root).expanduser().resolve() / f"{norm_owner}.json"
    if not path.is_file():
        return {}
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    if not isinstance(payload, dict) or payload.get("schema") != GENERATION_RECEIPT_SCHEMA:
        return {}
    return payload


def write_owner_receipt(
    receipt_root: Path | None,
    owner: str,
    ledger: DesiredArtifactLedger,
) -> Path | None:
    """Persist a compact generation receipt for *owner* when *receipt_root* is configured."""
    if receipt_root is None:
        return None
    norm_owner = normalize_owner(owner)
    owner_rows = ledger.rows_for(owner=norm_owner)
    owned_files = sorted(
        row.path
        for row in owner_rows
        if row.cleanup_policy == "owned_fileset"
    )
    mixed_catalogs = {
        row.path: list(row.generated_keys)
        for row in owner_rows
        if row.cleanup_policy == "mixed_key_catalog"
    }
    payload = {
        "schema": GENERATION_RECEIPT_SCHEMA,
        "owner": norm_owner,
        "modelFingerprint": ledger.model_fingerprint,
        "ownedFiles": owned_files,
        "mixedCatalogGeneratedKeys": dict(sorted(mixed_catalogs.items())),
    }
    target_dir = Path(receipt_root).expanduser().resolve()
    target_dir.mkdir(parents=True, exist_ok=True)
    path = target_dir / f"{norm_owner}.json"
    path.write_text(
        pretty_json(payload),
        encoding="utf-8",
        newline="\n",
    )
    return path


def _discover_locale_conversation_dirs(tr_root: Path) -> list[tuple[str, Path]]:
    found: list[tuple[str, Path]] = []
    if not tr_root.is_dir():
        return found
    for child in sorted(tr_root.iterdir(), key=lambda p: p.name):
        if not child.is_dir() or not (child / "Conversation").is_dir():
            continue
        try:
            lang = normalize_language(child.name, "translation directory")
        except CompileError:
            continue
        found.append((lang, child))
    return found


def _retired_mixed_keys_for(
    recipe: GenerationRecipe,
    owner: str,
    rel_path: str,
) -> set[str]:
    norm_owner = normalize_owner(owner)
    keys: set[str] = set()
    for entry in recipe.retired:
        if entry.kind != "mixed_keys" or norm_owner not in entry.owners:
            continue
        if rel_path in entry.paths:
            keys.update(entry.keys)
    return keys


def _retired_file_entries_for(
    recipe: GenerationRecipe,
    owner: str,
) -> tuple[dict[str, RetiredEntry], list[RetiredEntry]]:
    norm_owner = normalize_owner(owner)
    by_exact_path: dict[str, RetiredEntry] = {}
    dir_globs: list[RetiredEntry] = []
    for entry in recipe.retired:
        if norm_owner not in entry.owners:
            continue
        if entry.kind in {"file", "file_list"}:
            for p in entry.paths:
                by_exact_path[p] = entry
        elif entry.kind == "directory_glob":
            dir_globs.append(entry)
    return by_exact_path, dir_globs


def check_owner_surface_state(
    ledger: DesiredArtifactLedger,
    owner: str,
    *,
    receipt_root: Path | None = None,
    include_lexicon: bool = False,
) -> dict[str, Any]:
    """Compare desired ledger rows for *owner* against on-disk repository state without mutating disk."""
    norm_owner = normalize_owner(owner)
    owner_repo = ledger.output_repositories[norm_owner]
    recipe = ledger.recipe
    receipt = load_owner_receipt(receipt_root, norm_owner)
    receipt_owned_files = set(receipt.get("ownedFiles") or [])
    receipt_mixed_keys: Mapping[str, list[str]] = receipt.get("mixedCatalogGeneratedKeys") or {}

    owner_rows = [
        row
        for row in ledger.rows_for(owner=norm_owner)
        if include_lexicon or row.surface != "lexicon_lua"
    ]
    desired_by_path = {row.path: row for row in owner_rows}

    desired_paths: list[str] = sorted(desired_by_path)
    missing: list[dict[str, Any]] = []
    drifted: list[dict[str, Any]] = []
    stale: list[dict[str, Any]] = []
    retired_present: list[dict[str, Any]] = []
    ambiguous: list[dict[str, Any]] = []
    mixed_stale_keys: list[dict[str, Any]] = []
    preserved: list[dict[str, Any]] = []

    retired_by_path, retired_globs = _retired_file_entries_for(recipe, norm_owner)
    claimed_retired_paths: set[str] = set()

    # 1. Check explicit retired file/file_list entries first
    for ret_path, ret_entry in sorted(retired_by_path.items()):
        if ret_path in desired_by_path:
            continue
        abs_ret = owner_repo / Path(*PurePosixPath(ret_path).parts)
        if not abs_ret.exists():
            continue
        claimed_retired_paths.add(ret_path)
        proof_ok = True
        proof_reason = ret_entry.reason or "explicit recipe retirement"
        if ret_entry.sha256 is not None and abs_ret.is_file():
            actual_sha = sha256_file(abs_ret)
            if actual_sha != ret_entry.sha256:
                proof_ok = False
                proof_reason = f"retired path sha256 mismatch ({actual_sha} != {ret_entry.sha256})"
        if ret_entry.generated_marker is not None and abs_ret.is_file():
            if not _has_generated_lua_header(abs_ret, ret_entry.generated_marker):
                proof_ok = False
                proof_reason = f"retired path missing generated marker {ret_entry.generated_marker!r}"
        if proof_ok:
            retired_present.append({
                "owner": norm_owner,
                "surface": ret_entry.surface,
                "path": ret_path,
                "retiredId": ret_entry.id,
                "kind": "file",
                "reason": proof_reason,
            })
        else:
            ambiguous.append({
                "owner": norm_owner,
                "surface": ret_entry.surface,
                "path": ret_path,
                "retiredId": ret_entry.id,
                "reason": proof_reason,
            })

    # 2. Check retired directory globs
    for ret_entry in retired_globs:
        if not ret_entry.pattern:
            continue
        for hit in sorted(owner_repo.glob(ret_entry.pattern)):
            if not hit.exists():
                continue
            rel_hit = hit.relative_to(owner_repo).as_posix()
            if hit.is_dir():
                dir_files = sorted(p for p in hit.rglob("*") if p.is_file())
                if not dir_files:
                    retired_present.append({
                        "owner": norm_owner,
                        "surface": ret_entry.surface,
                        "path": rel_hit,
                        "retiredId": ret_entry.id,
                        "kind": "directory",
                        "reason": ret_entry.reason or "retired generated directory",
                    })
                    continue
                for fpath in dir_files:
                    f_rel = fpath.relative_to(owner_repo).as_posix()
                    if f_rel in claimed_retired_paths or f_rel in desired_by_path:
                        continue
                    claimed_retired_paths.add(f_rel)
                    marker = ret_entry.generated_marker
                    if fpath.suffix == ".lua" and marker:
                        is_proven = _has_generated_lua_header(fpath, marker)
                    elif fpath.suffix == ".lua":
                        is_proven = _has_generated_lua_header(fpath)
                    else:
                        is_proven = True
                    if is_proven:
                        retired_present.append({
                            "owner": norm_owner,
                            "surface": ret_entry.surface,
                            "path": f_rel,
                            "retiredId": ret_entry.id,
                            "kind": "file",
                            "reason": ret_entry.reason or "retired generated root artifact",
                        })
                    else:
                        ambiguous.append({
                            "owner": norm_owner,
                            "surface": ret_entry.surface,
                            "path": f_rel,
                            "retiredId": ret_entry.id,
                            "reason": "unrecognized file inside retired directory root",
                        })

    # 3. Check desired rows (missing / drifted / mixed_key_catalog)
    for rel_path, row in sorted(desired_by_path.items()):
        abs_path = owner_repo / Path(*PurePosixPath(rel_path).parts)
        if not abs_path.is_file():
            missing.append({
                "owner": norm_owner,
                "surface": row.surface,
                "path": rel_path,
                "artifactKind": row.artifact_kind,
                "sourceLineage": list(row.source_lineage),
            })
            continue

        if row.cleanup_policy == "mixed_key_catalog":
            existing_map = _read_string_map(abs_path)
            prior_gen_keys = set(receipt_mixed_keys.get(rel_path) or [])
            retired_ui_keys = _retired_mixed_keys_for(recipe, norm_owner, rel_path)
            desired_gen_keys = set(row.generated_keys)

            stale_from_receipt = sorted((prior_gen_keys - desired_gen_keys) & set(existing_map))
            present_retired_keys = sorted((retired_ui_keys - desired_gen_keys) & set(existing_map))
            all_stale_keys = sorted(set(stale_from_receipt) | set(present_retired_keys))

            if present_retired_keys:
                retired_present.append({
                    "owner": norm_owner,
                    "surface": row.surface,
                    "path": rel_path,
                    "kind": "mixed_keys",
                    "keys": present_retired_keys,
                    "reason": "retired generated UI catalog keys present",
                })
            if all_stale_keys:
                mixed_stale_keys.append({
                    "owner": norm_owner,
                    "surface": row.surface,
                    "path": rel_path,
                    "keys": all_stale_keys,
                })

            expected_merged = {
                k: v for k, v in existing_map.items() if k not in set(all_stale_keys)
            }
            preserved_authored_keys = sorted(set(expected_merged) - desired_gen_keys)
            if preserved_authored_keys:
                preserved.append({
                    "owner": norm_owner,
                    "surface": row.surface,
                    "path": rel_path,
                    "kind": "mixed_authored_keys",
                    "keyCount": len(preserved_authored_keys),
                })
            expected_merged.update(row.generated_key_values)
            expected_rendered = pretty_json(expected_merged)
            actual_text = abs_path.read_text(encoding="utf-8")
            # Only classify as drifted when generated keys are missing/mismatched or formatting differs
            # separate from stale/retired key presence.
            if actual_text != expected_rendered and not all_stale_keys:
                drifted.append({
                    "owner": norm_owner,
                    "surface": row.surface,
                    "path": rel_path,
                    "artifactKind": row.artifact_kind,
                    "expectedFingerprint": sha256_text(expected_rendered),
                    "actualFingerprint": sha256_file(abs_path),
                })
            elif any(existing_map.get(k) != v for k, v in row.generated_key_values.items()):
                drifted.append({
                    "owner": norm_owner,
                    "surface": row.surface,
                    "path": rel_path,
                    "artifactKind": row.artifact_kind,
                    "expectedFingerprint": sha256_text(expected_rendered),
                    "actualFingerprint": sha256_file(abs_path),
                })
        else:
            actual_fp = sha256_file(abs_path)
            if actual_fp != row.content_fingerprint:
                drifted.append({
                    "owner": norm_owner,
                    "surface": row.surface,
                    "path": rel_path,
                    "artifactKind": row.artifact_kind,
                    "expectedFingerprint": row.content_fingerprint,
                    "actualFingerprint": actual_fp,
                })

    # 4. Scan conversation_lua root for extra files
    conv_lua_surface = recipe.surface("conversation_lua")
    conv_lua_preserved = set(conv_lua_surface.preserved_for(norm_owner))
    conv_root = generated_conversation_root(
        ledger.output_repositories.get(HOOMANS_OWNER, owner_repo),
        norm_owner,
        core_repository=ledger.output_repositories.get(CORE_OWNER),
        dynamic_trading_repository=ledger.output_repositories.get(DT_COMMON_OWNER),
        runtime_root=ledger.output_repositories.get(HOOMANS_OWNER, owner_repo),
    )
    if conv_root.is_dir():
        for file_path in sorted(conv_root.rglob("*")):
            if not file_path.is_file():
                continue
            rel_path = file_path.relative_to(owner_repo).as_posix()
            if rel_path in desired_by_path or rel_path in claimed_retired_paths:
                continue
            if rel_path in conv_lua_preserved:
                preserved.append({
                    "owner": norm_owner,
                    "surface": conv_lua_surface.id,
                    "path": rel_path,
                    "kind": "preserved_file",
                })
                continue
            marker = conv_lua_surface.generated_marker or "-- Generated"
            if (
                file_path.suffix == ".lua"
                and _has_generated_lua_header(file_path, marker)
            ) or rel_path in receipt_owned_files:
                stale.append({
                    "owner": norm_owner,
                    "surface": conv_lua_surface.id,
                    "path": rel_path,
                    "reason": "proven CodeBuilder-owned Lua absent from desired ledger",
                })
            else:
                ambiguous.append({
                    "owner": norm_owner,
                    "surface": conv_lua_surface.id,
                    "path": rel_path,
                    "reason": "unowned/unmarked file inside ConvoEngine root not in preserved list",
                })

    # 5. Scan Conversation translation directories for extra files
    conv_tr_surface = recipe.surface("conversation_translations")
    conv_text_surface = recipe.surface("conversation_text")
    conv_tr_preserved = set(conv_tr_surface.preserved_for(norm_owner))
    pkg_tr_root = translation_root(
        ledger.output_repositories.get(HOOMANS_OWNER, owner_repo),
        norm_owner,
        core_repository=ledger.output_repositories.get(CORE_OWNER),
        dynamic_trading_repository=ledger.output_repositories.get(DT_COMMON_OWNER),
        runtime_root=ledger.output_repositories.get(HOOMANS_OWNER, owner_repo),
    )
    for _lang, lang_dir in _discover_locale_conversation_dirs(pkg_tr_root):
        conv_dir = lang_dir / "Conversation"
        for file_path in sorted(conv_dir.rglob("*")):
            if not file_path.is_file():
                continue
            rel_path = file_path.relative_to(owner_repo).as_posix()
            if rel_path in desired_by_path or rel_path in claimed_retired_paths:
                continue
            rel_from_lang = file_path.relative_to(lang_dir).as_posix()
            if rel_from_lang.startswith("Conversation/Text/"):
                if file_path.suffix == ".json":
                    stale.append({
                        "owner": norm_owner,
                        "surface": conv_text_surface.id,
                        "path": rel_path,
                        "reason": "Conversation/Text JSON absent from desired ledger",
                    })
                else:
                    ambiguous.append({
                        "owner": norm_owner,
                        "surface": conv_text_surface.id,
                        "path": rel_path,
                        "reason": "non-JSON file under Conversation/Text",
                    })
                continue

            if rel_path in conv_tr_preserved:
                preserved.append({
                    "owner": norm_owner,
                    "surface": conv_tr_surface.id,
                    "path": rel_path,
                    "kind": "preserved_file",
                })
                continue

            if rel_path in receipt_owned_files:
                stale.append({
                    "owner": norm_owner,
                    "surface": conv_tr_surface.id,
                    "path": rel_path,
                    "reason": "previously generated translation catalog absent from desired ledger",
                })
            else:
                ambiguous.append({
                    "owner": norm_owner,
                    "surface": conv_tr_surface.id,
                    "path": rel_path,
                    "reason": "unclassified file under Conversation translation tree",
                })

    # 6. Check lexicon_lua when requested
    if include_lexicon and norm_owner == CORE_OWNER:
        lex_surface = recipe.surface("lexicon_lua")
        lex_root = (
            owner_repo
            / package_descriptor(CORE_OWNER).shared_lua_relative
            / "PsychopatzCore/Semantics/Generated/Lexicon"
        )
        if lex_root.is_dir():
            for file_path in sorted(lex_root.rglob("*")):
                if not file_path.is_file():
                    continue
                rel_path = file_path.relative_to(owner_repo).as_posix()
                if rel_path in desired_by_path or rel_path in claimed_retired_paths:
                    continue
                marker = lex_surface.generated_marker or "-- Generated"
                if file_path.suffix == ".lua" and _has_generated_lua_header(file_path, marker):
                    stale.append({
                        "owner": norm_owner,
                        "surface": lex_surface.id,
                        "path": rel_path,
                        "reason": "proven CodeBuilder-owned Lexicon Lua absent from desired ledger",
                    })
                else:
                    ambiguous.append({
                        "owner": norm_owner,
                        "surface": lex_surface.id,
                        "path": rel_path,
                        "reason": "unowned file under Lexicon root",
                    })

    counts = {
        "desired": len(desired_paths),
        "missing": len(missing),
        "drifted": len(drifted),
        "stale": len(stale) + len(mixed_stale_keys),
        "retired_present": len(retired_present),
        "ambiguous": len(ambiguous),
        "preserved": len(preserved),
    }
    clean = (
        counts["missing"] == 0
        and counts["drifted"] == 0
        and counts["stale"] == 0
        and counts["retired_present"] == 0
        and counts["ambiguous"] == 0
    )
    return {
        "owner": norm_owner,
        "repository": str(owner_repo),
        "clean": clean,
        "counts": counts,
        "desired": desired_paths,
        "missing": missing,
        "drifted": drifted,
        "stale": stale,
        "retired_present": retired_present,
        "ambiguous": ambiguous,
        "mixed_stale_keys": mixed_stale_keys,
        "preserved": preserved,
    }


def reconcile_check(
    repository: str | Path,
    *,
    recipe_path: str | Path | None = None,
    recipe: GenerationRecipe | None = None,
    model: dict[str, Any] | None = None,
    core_repository: str | Path | None = None,
    hoomans_repository: str | Path | None = None,
    dynamic_trading_repository: str | Path | None = None,
    output_repositories: Mapping[str, str | Path] | None = None,
    receipt_root: str | Path | None = None,
    wordnet_home: str | Path | None = None,
    allowlist_path: str | Path = DEFAULT_ALLOWLIST,
    ledger: DesiredArtifactLedger | None = None,
) -> dict[str, Any]:
    """Run dry/check-mode reconciliation across all enabled owners without modifying disk."""
    active_recipe = recipe or load_generation_recipe(recipe_path)
    active_ledger = ledger or build_desired_artifact_ledger(
        repository,
        recipe=active_recipe,
        model=model,
        core_repository=core_repository,
        hoomans_repository=hoomans_repository,
        dynamic_trading_repository=dynamic_trading_repository,
        output_repositories=output_repositories,
        wordnet_home=wordnet_home,
        allowlist_path=allowlist_path,
    )
    resolved_receipt_root = (
        Path(receipt_root).expanduser().resolve() if receipt_root is not None else None
    )
    include_lexicon = wordnet_home is not None

    by_owner: dict[str, dict[str, Any]] = {}
    totals = {
        "desired": 0,
        "missing": 0,
        "drifted": 0,
        "stale": 0,
        "retired_present": 0,
        "ambiguous": 0,
        "preserved": 0,
    }
    for owner in active_ledger.enabled_owners:
        owner_report = check_owner_surface_state(
            active_ledger,
            owner,
            receipt_root=resolved_receipt_root,
            include_lexicon=include_lexicon,
        )
        by_owner[owner] = owner_report
        for k in totals:
            totals[k] += owner_report["counts"][k]

    clean = (
        totals["missing"] == 0
        and totals["drifted"] == 0
        and totals["stale"] == 0
        and totals["retired_present"] == 0
        and totals["ambiguous"] == 0
    )
    return {
        "schema": RECONCILIATION_REPORT_SCHEMA,
        "mode": "check",
        "ok": clean,
        "clean": clean,
        "effectFree": True,
        "modelFingerprint": active_ledger.model_fingerprint,
        "enabledOwners": list(active_ledger.enabled_owners),
        "counts": totals,
        "owners": by_owner,
    }


def _prune_empty_dirs(root: Path) -> None:
    if not root.is_dir():
        return
    for directory in sorted(
        (p for p in root.rglob("*") if p.is_dir()),
        key=lambda p: len(p.parts),
        reverse=True,
    ):
        try:
            directory.rmdir()
        except OSError:
            pass


def reconcile_apply(
    repository: str | Path,
    *,
    recipe_path: str | Path | None = None,
    recipe: GenerationRecipe | None = None,
    model: dict[str, Any] | None = None,
    core_repository: str | Path | None = None,
    hoomans_repository: str | Path | None = None,
    dynamic_trading_repository: str | Path | None = None,
    output_repositories: Mapping[str, str | Path] | None = None,
    receipt_root: str | Path | None = None,
    wordnet_home: str | Path | None = None,
    allowlist_path: str | Path = DEFAULT_ALLOWLIST,
    strict_closure: bool = True,
) -> dict[str, Any]:
    """Compile and validate the desired ledger, prune proven stale/retired state, write canonical outputs, and verify closure."""
    active_recipe = recipe or load_generation_recipe(recipe_path)
    # Step 1: Compile and validate full desired artifact ledger BEFORE any filesystem mutation.
    ledger = build_desired_artifact_ledger(
        repository,
        recipe=active_recipe,
        model=model,
        core_repository=core_repository,
        hoomans_repository=hoomans_repository,
        dynamic_trading_repository=dynamic_trading_repository,
        output_repositories=output_repositories,
        wordnet_home=wordnet_home,
        allowlist_path=allowlist_path,
    )
    resolved_receipt_root = (
        Path(receipt_root).expanduser().resolve() if receipt_root is not None else None
    )
    include_lexicon = wordnet_home is not None

    # Step 2: Compute pre-apply check diff.
    pre_check = reconcile_check(
        repository,
        recipe=active_recipe,
        ledger=ledger,
        receipt_root=resolved_receipt_root,
        wordnet_home=wordnet_home,
        allowlist_path=allowlist_path,
    )

    pruned_files: list[str] = []
    pruned_keys: list[dict[str, Any]] = []
    written_files: list[str] = []

    # Step 3: For each enabled owner, prune proven stale/retired files and keys, then write desired outputs.
    for owner in ledger.enabled_owners:
        owner_repo = ledger.output_repositories[owner]
        owner_check = pre_check["owners"][owner]
        receipt = load_owner_receipt(resolved_receipt_root, owner)
        receipt_mixed_keys: Mapping[str, list[str]] = receipt.get("mixedCatalogGeneratedKeys") or {}

        # 3a. Prune proven stale files
        for item in owner_check["stale"]:
            target = owner_repo / Path(*PurePosixPath(item["path"]).parts)
            if target.is_file():
                target.unlink()
                pruned_files.append(f"{owner}:{item['path']}")

        # 3b. Prune proven retired files/directories
        retired_dirs_to_prune: list[Path] = []
        for item in owner_check["retired_present"]:
            if item.get("kind") == "file":
                target = owner_repo / Path(*PurePosixPath(item["path"]).parts)
                if target.is_file():
                    target.unlink()
                    pruned_files.append(f"{owner}:{item['path']}")
            elif item.get("kind") == "directory":
                target = owner_repo / Path(*PurePosixPath(item["path"]).parts)
                if target.is_dir():
                    retired_dirs_to_prune.append(target)

        # Also collect any retired directory_glob roots that are now empty after file pruning
        for ret_entry in active_recipe.retired:
            if ret_entry.kind == "directory_glob" and owner in ret_entry.owners and ret_entry.pattern:
                for hit in sorted(owner_repo.glob(ret_entry.pattern)):
                    if hit.is_dir() and hit not in retired_dirs_to_prune:
                        retired_dirs_to_prune.append(hit)

        for target in retired_dirs_to_prune:
            _prune_empty_dirs(target)
            try:
                rel_dir = target.relative_to(owner_repo).as_posix()
                target.rmdir()
                pruned_files.append(f"{owner}:{rel_dir}")
            except OSError:
                pass

        # Clean empty subdirectories under ConvoEngine and Conversation/Text
        conv_root = generated_conversation_root(
            ledger.output_repositories.get(HOOMANS_OWNER, owner_repo),
            owner,
            core_repository=ledger.output_repositories.get(CORE_OWNER),
            dynamic_trading_repository=ledger.output_repositories.get(DT_COMMON_OWNER),
            runtime_root=ledger.output_repositories.get(HOOMANS_OWNER, owner_repo),
        )
        _prune_empty_dirs(conv_root)
        pkg_tr_root = translation_root(
            ledger.output_repositories.get(HOOMANS_OWNER, owner_repo),
            owner,
            core_repository=ledger.output_repositories.get(CORE_OWNER),
            dynamic_trading_repository=ledger.output_repositories.get(DT_COMMON_OWNER),
            runtime_root=ledger.output_repositories.get(HOOMANS_OWNER, owner_repo),
        )
        for _lang, lang_dir in _discover_locale_conversation_dirs(pkg_tr_root):
            _prune_empty_dirs(lang_dir / "Conversation")

        # 3c. Write desired artifacts canonically (only writing when missing or content differs to preserve byte/mtime stability)
        owner_rows = [
            row
            for row in ledger.rows_for(owner=owner)
            if include_lexicon or row.surface != "lexicon_lua"
        ]
        # Write non-manifest rows first, then TranslationManifest so manifest reflects pruned state
        ordered_rows = sorted(
            owner_rows,
            key=lambda r: (1 if r.artifact_kind == "json:TranslationManifest" else 0, r.path),
        )
        for row in ordered_rows:
            abs_path = owner_repo / Path(*PurePosixPath(row.path).parts)
            if row.cleanup_policy == "mixed_key_catalog":
                existing_map = _read_string_map(abs_path) if abs_path.is_file() else {}
                prior_gen_keys = set(receipt_mixed_keys.get(row.path) or [])
                retired_ui_keys = _retired_mixed_keys_for(active_recipe, owner, row.path)
                desired_gen_keys = set(row.generated_keys)
                keys_to_remove = (prior_gen_keys | retired_ui_keys) - desired_gen_keys
                removed_here = sorted(k for k in keys_to_remove if k in existing_map)
                if removed_here:
                    pruned_keys.append({
                        "owner": owner,
                        "path": row.path,
                        "keys": removed_here,
                    })
                merged = {
                    k: v for k, v in existing_map.items() if k not in keys_to_remove
                }
                merged.update(row.generated_key_values)
                content_to_write = pretty_json(merged)
            else:
                content_to_write = row.rendered_content

            if abs_path.is_file():
                try:
                    existing_text = abs_path.read_text(encoding="utf-8")
                except OSError:
                    existing_text = None
                if existing_text == content_to_write:
                    continue
            abs_path.parent.mkdir(parents=True, exist_ok=True)
            abs_path.write_text(content_to_write, encoding="utf-8", newline="\n")
            written_files.append(f"{owner}:{row.path}")

        write_owner_receipt(resolved_receipt_root, owner, ledger)

    # Step 4: Post-write closure check (rebuild ledger so manifests reflect any pruned files).
    post_ledger = build_desired_artifact_ledger(
        repository,
        recipe=active_recipe,
        model=model,
        core_repository=core_repository,
        hoomans_repository=hoomans_repository,
        dynamic_trading_repository=dynamic_trading_repository,
        output_repositories=output_repositories,
        wordnet_home=wordnet_home,
        allowlist_path=allowlist_path,
    )
    post_check = reconcile_check(
        repository,
        recipe=active_recipe,
        ledger=post_ledger,
        receipt_root=resolved_receipt_root,
        wordnet_home=wordnet_home,
        allowlist_path=allowlist_path,
    )
    if strict_closure and not post_check["clean"]:
        c = post_check["counts"]
        raise CompileError(
            "Post-reconciliation closure check failed: "
            f"missing={c['missing']} drifted={c['drifted']} stale={c['stale']} "
            f"retired_present={c['retired_present']} ambiguous={c['ambiguous']}"
        )

    desired_abs_paths = [
        post_ledger.output_repositories[row.owner] / Path(*PurePosixPath(row.path).parts)
        for row in post_ledger.rows
        if include_lexicon or row.surface != "lexicon_lua"
    ]

    return {
        "schema": RECONCILIATION_REPORT_SCHEMA,
        "mode": "apply",
        "ok": post_check["clean"] if strict_closure else (
            post_check["counts"]["missing"] == 0
            and post_check["counts"]["drifted"] == 0
            and post_check["counts"]["stale"] == 0
            and post_check["counts"]["retired_present"] == 0
        ),
        "clean": post_check["clean"],
        "effectFree": False,
        "modelFingerprint": post_ledger.model_fingerprint,
        "enabledOwners": list(post_ledger.enabled_owners),
        "prunedFiles": pruned_files,
        "prunedKeys": pruned_keys,
        "writtenFiles": written_files,
        "desiredPaths": [str(p) for p in desired_abs_paths],
        "preCounts": pre_check["counts"],
        "counts": post_check["counts"],
        "owners": post_check["owners"],
    }


def _format_summary_lines(report: Mapping[str, Any]) -> list[str]:
    c = report["counts"]
    lines = [
        f"mode = {report['mode']}",
        f"clean = {str(report['clean']).lower()}",
        f"desired = {c['desired']}",
        f"missing = {c['missing']}",
        f"drifted = {c['drifted']}",
        f"stale = {c['stale']}",
        f"retired_present = {c['retired_present']}",
        f"ambiguous = {c['ambiguous']}",
        f"preserved = {c['preserved']}",
    ]
    for owner, owner_rep in sorted((report.get("owners") or {}).items()):
        oc = owner_rep["counts"]
        lines.append(
            f"[{owner}] desired={oc['desired']} missing={oc['missing']} "
            f"drifted={oc['drifted']} stale={oc['stale']} "
            f"retired_present={oc['retired_present']} ambiguous={oc['ambiguous']} "
            f"preserved={oc['preserved']}"
        )
    return lines


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--recipe",
        type=Path,
        default=DEFAULT_RECIPE_PATH,
        help="Path to the CodeBuilder generation recipe JSON",
    )
    mode_group = parser.add_mutually_exclusive_group(required=True)
    mode_group.add_argument(
        "--check",
        action="store_true",
        help="Dry-run reconciliation check; reports missing/drifted/stale/retired/ambiguous without writing",
    )
    mode_group.add_argument(
        "--apply",
        action="store_true",
        help="Apply safe closed-set reconciliation and verify post-write closure",
    )
    parser.add_argument(
        "--repository",
        type=Path,
        default=ROOT,
        help="Primary/runtime repository (defaults to PsychopatzCore or discovered ProjectHoomans)",
    )
    parser.add_argument(
        "--core-repository",
        type=Path,
        default=None,
        help="Explicit PsychopatzCore repository path",
    )
    parser.add_argument(
        "--hoomans-repository",
        type=Path,
        default=None,
        help="Explicit ProjectHoomans repository path",
    )
    parser.add_argument(
        "--dynamic-trading-repository",
        type=Path,
        default=None,
        help="Explicit DynamicTrading repository path",
    )
    parser.add_argument(
        "--receipt-root",
        type=Path,
        default=None,
        help="Optional directory for persisted per-owner generation receipts",
    )
    parser.add_argument(
        "--wordnet-home",
        type=Path,
        default=None,
        help="Optional WordNet 3.0 directory when reconciling lexicon_lua",
    )
    parser.add_argument(
        "--format",
        choices=("json", "summary"),
        default="json",
        dest="output_format",
        help="Output format (json or summary)",
    )
    return parser


def main(arguments: list[str] | None = None) -> int:
    parser = build_parser()
    options = parser.parse_args(arguments)
    try:
        if options.check:
            report = reconcile_check(
                options.repository,
                recipe_path=options.recipe,
                core_repository=options.core_repository,
                hoomans_repository=options.hoomans_repository,
                dynamic_trading_repository=options.dynamic_trading_repository,
                receipt_root=options.receipt_root,
                wordnet_home=options.wordnet_home,
            )
        else:
            report = reconcile_apply(
                options.repository,
                recipe_path=options.recipe,
                core_repository=options.core_repository,
                hoomans_repository=options.hoomans_repository,
                dynamic_trading_repository=options.dynamic_trading_repository,
                receipt_root=options.receipt_root,
                wordnet_home=options.wordnet_home,
            )
    except CompileError as error:
        if options.output_format == "json":
            print(
                json.dumps(
                    {"ok": False, "error": str(error)},
                    ensure_ascii=False,
                    indent=2,
                )
            )
        else:
            print(f"reconcile error: {error}", file=sys.stderr)
        return 2

    if options.output_format == "summary":
        print("\n".join(_format_summary_lines(report)))
    else:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if report.get("ok") else 1


if __name__ == "__main__":
    raise SystemExit(main())
