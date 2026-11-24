"""Verify canonical CodeBuilder inputs against the actual loaded Lua registry.

This is a *read-only* cross-check, not a second Lua parser or a guess from a
registration source path. Only canonical datasets discovered through the
existing authoring service, its compiler and its preview parity can qualify.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any

from tools.semantic_harness.codebuilder.dialogue_dataset import compile_dialogue_dataset
from tools.semantic_harness.codebuilder.generation_ownership import (
    module_target,
    owner_repository,
)
from tools.semantic_harness.codebuilder.semantic_definition_compiler import compile_semantic_definitions
from tools.semantic_harness.codebuilder.service import SemanticLabAuthoringService
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


def _condition(value: Any) -> Any:
    # Empty Lua arrays and Python JSON objects both represent unkeyed Lua {}.
    if value == [] or value == {} or value is None:
        return {}
    return value


def _convo_engine_english_lines(record: dict[str, Any]) -> set[str]:
    lines: set[str] = set()
    payload = record.get("payload") if isinstance(record.get("payload"), dict) else {}
    say = payload.get("say") if isinstance(payload.get("say"), dict) else {}
    realizations = say.get("realizations") if isinstance(say.get("realizations"), dict) else {}
    for slot in realizations.values():
        if not isinstance(slot, dict):
            continue
        for variant in slot.get("variants") or []:
            if not isinstance(variant, dict):
                continue
            text_map = variant.get("text") if isinstance(variant.get("text"), dict) else {}
            en = text_map.get("EN")
            if isinstance(en, str) and en:
                lines.add(en)
            elif isinstance(en, list):
                lines.update(item for item in en if isinstance(item, str) and item)
    return lines


def _convo_engine_generated_matches(
    service: SemanticLabAuthoringService,
    row: dict[str, Any],
    template_id: str,
) -> bool:
    owner = str(row.get("owner") or "")
    modules = row.get("generatedModules") or []
    if not owner or not modules:
        return False
    sibling_dt = getattr(service, "dynamic_trading_repository", None) or (
        service.repository.parent / "DynamicTrading"
    )
    sibling_core = getattr(service, "core_repository", None) or (
        service.repository.parent / "psychopatzCore"
    )
    try:
        owner_repo = owner_repository(
            service.repository,
            owner,
            core_repository=sibling_core,
            dynamic_trading_repository=sibling_dt,
        )
    except Exception:
        return False
    for module in modules:
        try:
            _, lua_path = module_target(
                owner_repo,
                str(module),
                core_repository=sibling_core,
                dynamic_trading_repository=sibling_dt,
            )
        except Exception:
            continue
        if lua_path.is_file() and template_id in lua_path.read_text(encoding="utf-8"):
            return True
        lua_dir = lua_path.with_suffix("")
        if lua_dir.is_dir():
            for leaf in sorted(lua_dir.rglob("*.lua")):
                if template_id in leaf.read_text(encoding="utf-8"):
                    return True
    return False


def _matches_convo_engine_lineage(
    service: SemanticLabAuthoringService,
    row: dict[str, Any],
    loaded_variant: dict[str, Any],
) -> dict[str, Any] | None:
    source_path = Path(str(row["sourcePath"]))
    if not source_path.is_file():
        return None
    doc = json.loads(source_path.read_text(encoding="utf-8"))
    preview = service.preview_convo_engine_document(doc, source_path=source_path)
    if not preview.get("ok"):
        return None
    records = (preview.get("compiled") or {}).get("records") or []
    template_id = str(loaded_variant.get("templateID") or row["canonicalID"])
    canonical_id = str(row["canonicalID"])
    record = next(
        (
            item for item in records
            if item.get("id") == template_id
            or (item.get("id") == canonical_id and template_id.startswith(canonical_id + "."))
        ),
        None,
    )
    if not isinstance(record, dict):
        return None
    fallback = loaded_variant.get("fallback")
    en_lines = _convo_engine_english_lines(record)
    if isinstance(fallback, str) and fallback and en_lines and fallback not in en_lines:
        return None
    match_token = canonical_id if template_id.startswith(canonical_id + ".") else template_id
    if not _convo_engine_generated_matches(service, row, match_token):
        return None
    try:
        rel_path = str(source_path.relative_to(service.repository))
    except ValueError:
        rel_path = str(source_path)
    return {
        "sourceID": str(row["sourceID"]),
        "canonicalID": str(row["canonicalID"]),
        "sourcePath": rel_path,
        "sourceSHA256": hashlib.sha256(source_path.read_bytes()).hexdigest(),
        "validatedBy": "convo_engine_compiler_and_loaded_lua",
        "generatedArtifactParity": "unchanged",
    }


def _matches(authored: dict[str, Any], loaded: dict[str, Any]) -> bool:
    return (
        authored.get("id") == loaded.get("id")
        and authored.get("templateID") == loaded.get("templateID")
        and authored.get("fallback") == loaded.get("fallback")
        and _condition(authored.get("when")) == _condition(loaded.get("when"))
        and int(authored.get("priority", 0)) == int(loaded.get("priority", 0))
    )


def inspect_codebuilder_lineage(
    worker: LuaSemanticWorker,
    pool_id: str,
    *,
    authoring_service: SemanticLabAuthoringService | None = None,
) -> dict[str, Any]:
    """Return verified per-variant source ownership; unresolved stays UNKNOWN."""
    service = authoring_service or SemanticLabAuthoringService(
        repository=worker.config.repository,
        runtime_root=worker.config.repository,
    )
    detail = worker.response_pool_detail(pool_id, limit=16)
    loaded = detail.get("variants", [])
    if detail.get("hasMore"):
        return {
            "ok": False, "type": "response_codebuilder_lineage",
            "schemaVersion": 1, "poolID": pool_id, "reason": "pool_exceeds_detail_bound",
            "sourceKind": "UNKNOWN", "sourceOwners": [],
        }
    by_id = {variant["id"]: variant for variant in loaded}
    matches: dict[str, list[dict[str, Any]]] = {variant_id: [] for variant_id in by_id}
    checked_sources = []
    # Check unified .convo DSL packs first as primary authored authority.
    convo_matches = service.find_convo_pool_lineage(pool_id, by_id)
    if any(convo_matches.values()):
        for vid, rows in convo_matches.items():
            matches[vid].extend(rows)
        checked_sources.append({
            "sourceID": "convo_dsl",
            "verified": True,
            "reason": "matched_convo_dsl_script",
        })
    for source in service.list_dataset_sources():
        kind = source.get("kind")
        if kind not in ("dialogue", "semantic") or not source.get("exists"):
            continue
        source_id = source["id"]
        spec = service._dataset_spec(source_id)
        # Validate this logical dataset through the one canonical Conversation
        # generation plan. No legacy aggregate or standalone generator is read.
        preview = service.preview_dataset_generation(source_id)
        if not preview.get("ok"):
            checked_sources.append({
                "sourceID": source_id,
                "verified": False,
                "reason": "canonical_conversation_preview_failed",
            })
            continue
        diffs = preview.get("generatedArtifactDiffs") or []
        artifacts_current = bool(diffs) and all(
            row.get("status") == "unchanged" for row in diffs
        )
        if not artifacts_current:
            checked_sources.append({
                "sourceID": source_id,
                "verified": False,
                "reason": "generated_conversation_differs_from_source",
            })
            continue
        source_document = service.load_dataset_document(source_id)
        compiled = (compile_dialogue_dataset(source_document) if kind == "dialogue"
                    else compile_semantic_definitions(source_document))
        for pool in compiled.get("responsePools", []):
            if pool["id"] != pool_id:
                continue
            for variant in pool.get("variants", []):
                loaded_variant = by_id.get(variant.get("id"))
                if loaded_variant is not None and _matches(variant, loaded_variant):
                    if kind == "dialogue":
                        source_path = None
                        for relative in spec.get("responsePaths", ()):
                            candidate_path = service.repository / relative
                            candidate_document = json.loads(
                                candidate_path.read_text(encoding="utf-8")
                            )
                            for candidate_pool in candidate_document.get(
                                "responsePools", []
                            ):
                                if candidate_pool.get("id") != pool_id:
                                    continue
                                if any(
                                    isinstance(candidate_variant, dict)
                                    and candidate_variant.get("id")
                                    == loaded_variant["id"]
                                    for candidate_variant in candidate_pool.get(
                                        "variants", []
                                    )
                                ):
                                    source_path = candidate_path
                                    break
                            if source_path is not None:
                                break
                        if source_path is None:
                            continue
                    else:
                        source_path = service.repository / spec["path"]
                    matches[loaded_variant["id"]].append({
                        "sourceID": source_id,
                        "sourcePath": str(
                            source_path.relative_to(service.repository)
                        ),
                        "sourceSHA256": hashlib.sha256(
                            source_path.read_bytes()
                        ).hexdigest(),
                        "validatedBy": "canonical_Conversation_preview_and_compiler",
                        "generatedArtifactParity": "unchanged",
                    })
        checked_sources.append({
            "sourceID": source_id,
            "verified": True,
            "generatedArtifactParity": "unchanged",
        })
    convo_by_id = {
        str(row["canonicalID"]): row
        for row in service.list_convo_engine_families()
        if row.get("canonicalID") and row.get("sourcePath")
    }
    for loaded_variant in loaded:
        variant_id = loaded_variant["id"]
        if matches[variant_id]:
            continue
        template_id = str(loaded_variant.get("templateID") or "")
        row = convo_by_id.get(template_id)
        if row is None and "." in template_id:
            row = convo_by_id.get(template_id.rsplit(".", 1)[0])
        if row is None:
            continue
        convo_match = _matches_convo_engine_lineage(service, row, loaded_variant)
        if convo_match is not None:
            matches[variant_id].append(convo_match)
            checked_sources.append({
                "sourceID": convo_match["sourceID"],
                "verified": True,
                "generatedArtifactParity": "unchanged",
            })
        else:
            checked_sources.append({
                "sourceID": str(row["sourceID"]),
                "verified": False,
                "reason": "convo_engine_source_mismatch",
            })
    owners = []
    for variant in loaded:
        candidates = matches[variant["id"]]
        unique = candidates[0] if len(candidates) == 1 else None
        owners.append({
            "variantID": variant["id"],
            "sourceKind": "CODEBUILDER_CANONICAL" if unique else "UNKNOWN",
            "verifiedCanonicalSource": bool(unique),
            "reason": ("matched_compiled_variant_and_loaded_registry"
                       if unique else "ambiguous_canonical_matches"
                       if len(candidates) > 1 else "no_verified_canonical_match"),
            "canonicalSource": unique,
        })
    verified = sum(bool(row["verifiedCanonicalSource"]) for row in owners)
    return {
        "ok": True, "type": "response_codebuilder_lineage",
        "schemaVersion": 1, "poolID": pool_id,
        "sourceKind": "FIXTURE",
        "registryRevision": detail["registryRevision"],
        "contentFingerprint": detail["contentFingerprint"],
        "variantCount": detail["variantCount"],
        "verifiedVariantCount": verified,
        "unverifiedVariantCount": len(owners) - verified,
        "fullPoolCanonicalOwnershipVerified": verified == len(owners),
        "sourceOwners": owners, "checkedCanonicalSources": checked_sources,
        "selectionAuthority": "production_lua",
        "approvalRequired": True, "writes": 0,
    }
