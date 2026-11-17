"""Approved-source *preview*, never publication or automatic source promotion.

One reviewed existing authored variant is copied into a disposable, isolated
worker overlay. Production Lua and the actual Core translation loader render
both language candidates; no mock Python selector or second compiler is used.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import re
import tempfile
from typing import Any

from tools.semantic_harness.codebuilder.conversation_compiler import (
    CONVERSATION_SOURCE_RELATIVE,
    compile_conversation_sources,
    conversation_record,
)
from tools.semantic_harness.codebuilder.translation_support import (
    DEFAULT_LANGUAGE,
    normalize_translations,
)
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from .conversation_inspector import build_conversation_inspector
from .response_observatory import review_variant_proposal, source_evidence


def _sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _content_fingerprint(values: dict[str, str]) -> str:
    encoded = json.dumps(values, ensure_ascii=False, sort_keys=True).encode(
        "utf-8"
    )
    return "content-v2:" + _sha256(encoded)


def _without_content_realization(value):
    """Copy plan metadata without authored wording fields.

    A candidate preview is allowed to change the Dialogue Content fallback
    attached to a response-plan segment. The plan itself remains part of the
    semantic contract, so compare its IDs, offers, gates, and effects while
    excluding only the wording fields that the candidate is meant to edit.
    """
    if isinstance(value, dict):
        return {
            key: _without_content_realization(item)
            for key, item in value.items()
            if key not in {"fallback", "text"}
        }
    if isinstance(value, list):
        return [_without_content_realization(item) for item in value]
    return value


def _semantic_variant_metadata(variant):
    metadata = dict(variant)
    for ignored in ("fallback", "sourceKind", "sourcePath"):
        metadata.pop(ignored, None)
    if "responsePlan" in metadata:
        metadata["responsePlan"] = _without_content_realization(
            metadata["responsePlan"]
        )
    return metadata


def _convo_engine_translation_asset(
    repository: Path, language: str, key: str,
) -> tuple[Path, str, dict[str, str]] | None:
    """Resolve inline ConvoEngine dialogue wording and overlay via Conversation manifest."""
    prefix = "conversation.content.semantic."
    if not key.startswith(prefix):
        return None
    parts = key[len(prefix):].split(".")
    if len(parts) < 3 or not parts[-1].isdigit():
        return None
    seq = int(parts[-1])
    style = parts[-2]
    family_id = ".".join(parts[:-2])
    sources_root = (
        repository / "tools/providers/pnc/codebuilder/sources/conversation/dialogue"
    )
    if not sources_root.is_dir():
        return None
    matches: list[tuple[Path, str]] = []
    for src_path in sorted(sources_root.rglob("*.json")):
        doc = json.loads(src_path.read_text(encoding="utf-8"))
        if not isinstance(doc, dict):
            continue
        doc_family = ".".join(
            part for part in (doc.get("namespace"), doc.get("id"))
            if isinstance(part, str) and part
        )
        if doc_family != family_id:
            continue
        say = doc.get("say") if isinstance(doc.get("say"), dict) else {}
        variants = list(say.get("variants") or [])
        if any(not isinstance(v.get("text"), dict) for v in variants if isinstance(v, dict)) or "textSidecars" in doc:
            from ..codebuilder.psdl_compiler import compile_convo_engine_document
            compiled = compile_convo_engine_document(
                doc,
                source_path=src_path,
                default_owner=doc.get("owner") or "ProjectHoomans",
                validate_cross_references=False,
            )
            records = compiled.get("records") or []
            if records:
                variants = (
                    ((records[0].get("payload") or {}).get("say") or {})
                    .get("realizations", {})
                    .get("1", {})
                    .get("variants")
                    or variants
                )
        for variant in variants:
            if not isinstance(variant, dict) or variant.get("id") != style:
                continue
            text_map = variant.get("text") if isinstance(variant.get("text"), dict) else {}
            lines = text_map.get(language)
            if isinstance(lines, str) and seq == 1:
                matches.append((src_path, lines))
            elif isinstance(lines, list) and 1 <= seq <= len(lines):
                item = lines[seq - 1]
                if isinstance(item, str):
                    matches.append((src_path, item))
    if len(matches) != 1:
        return None
    src_path, baseline_text = matches[0]
    relative = f"media/translation/{language}/Conversation/Text/convo/SemanticResponses.json"
    disk_path = repository / "Contents/mods/ProjectHoomans/common" / relative
    merged = json.loads(disk_path.read_text(encoding="utf-8"))
    if not isinstance(merged, dict):
        return None
    merged = dict(merged)
    merged[key] = baseline_text
    return src_path, relative, merged


def _verified_translation_asset(
    repository: Path, language: str, key: str,
) -> tuple[Path, str, dict[str, str]]:
    """Lookup the *actual manifest listed* translator source for the real key."""
    media = repository / "Contents/mods/ProjectHoomans/common/media"
    manifest = json.loads(
        (media / "translation/manifests/Conversation.json").read_text(
            encoding="utf-8"
        )
    )
    files = manifest["languages"][language]
    found: list[tuple[Path, str, dict[str, str]]] = []
    for relative in files:
        if not relative.startswith(f"{language}/Conversation/"):
            continue
        if not relative.endswith(".json") or ".." in relative:
            raise ValueError("invalid manifest translation asset path")
        path = media / "translation" / relative
        data = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(data, dict):
            raise ValueError("manifest translation asset is not an object")
        if key in data:
            found.append((path, "media/translation/" + relative, data))
    if len(found) == 1:
        return found[0]
    if not found:
        convo_match = _convo_engine_translation_asset(repository, language, key)
        if convo_match is not None:
            return convo_match
    raise ValueError("translation source absent or ambiguous in canonical manifest")


def _real_case(
    scenario: dict[str, Any],
    utterance: str,
    *,
    worker: LuaSemanticWorker | None = None,
    candidate_overlay_root: Path | None = None,
    candidate_overlay_module: str | None = None,
) -> dict[str, Any]:
    if worker is not None:
        worker.import_source(scenario)
        turn = worker.input(utterance)
        inspector = build_conversation_inspector(turn)
    else:
        with LuaSemanticWorker(
            scenario,
            candidate_overlay_root=candidate_overlay_root,
            candidate_overlay_module=candidate_overlay_module,
        ) as owned_worker:
            turn = owned_worker.input(utterance)
            inspector = build_conversation_inspector(turn)
    responses = [
        m["payload"] for m in turn.get("messages", [])
        if m.get("speaker") == "npc" and isinstance(m.get("payload"), dict)
    ]
    side = inspector.get("effects", {}).get("sideEffects", {})
    return {
        "accepted": turn.get("accepted"),
        "messages": [{
            "id": m.get("semanticTemplateID") or m.get("key"),
            "variantID": m.get("semanticVariantID"),
            "translationKey": m.get("translationKey"),
            "text": m.get("text"),
        } for m in responses[-4:]],
        "actionCount": side.get("actionCount"),
        "transportCount": side.get("transportCount"),
    }


def preview_authored_variant(
    proposal: dict[str, Any], *,
    repository: Path,
) -> dict[str, Any]:
    """Test a *single* approved-source candidate in an ephemeral real-Lua tree.

    This routine NEVER promotes, accepts or rewrites source files. Invalid
    proposals or Lua failures propagate, with TemporaryDirectory cleanup.
    """
    repository = repository.resolve(strict=True)
    if not isinstance(proposal, dict):
        raise ValueError("proposal must be an object")
    entries = proposal.get("variants")
    if not isinstance(entries, list) or len(entries) != 1:
        raise ValueError("isolated preview requires exactly one existing variant")
    case = proposal.get("case")
    if not isinstance(case, dict) or set(case) - {"utterance", "scenario"}:
        raise ValueError("isolated preview requires one bounded case")
    utterance = case.get("utterance")
    if not isinstance(utterance, str) or not 1 <= len(utterance) <= 200:
        raise ValueError("isolated preview utterance must be 1 to 200 characters")
    overrides = case.get("scenario") or {}
    if not isinstance(overrides, dict):
        raise ValueError("isolated preview scenario must be a JSON object")

    variant_id = entries[0].get("id")
    with LuaSemanticWorker(merge(DEFAULT_SCENARIO, overrides),
                           repository=repository) as worker:
        review = review_variant_proposal(worker, proposal)
        if not review["ok"]:
            raise ValueError(f"proposal preflight rejected: {review['reason']}")
        details = worker.response_pool_detail(proposal["poolID"], limit=16)
        candidates = [v for v in details["variants"] if v["id"] == variant_id]
        if len(candidates) != 1:
            raise ValueError("selected variant was not registered")
        variant = candidates[0]
        origin = variant["sourcePath"]
        if variant["sourceKind"] != "AUTHORED_LUA":
            raise ValueError("no verified canonical authored Lua owner")
        owner_source = (repository / origin).resolve(strict=True)
        root = (repository / "Contents/mods/ProjectHoomans").resolve()
        if not owner_source.is_relative_to(root) or not owner_source.name.endswith(".lua"):
            raise ValueError("source ownership is outside the checked-out mod")
        conversation_model = compile_conversation_sources(repository)
        template_id = str(
            variant.get("templateID") or variant.get("semanticTemplateID") or ""
        )
        content_location = conversation_record(
            conversation_model,
            "phrase." + template_id,
        )
        convo_engine_root = (
            repository
            / "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/ConvoEngine"
        ).resolve()
        if isinstance(content_location, dict) and content_location.get("kind") == "content":
            content_source = (
                repository
                / CONVERSATION_SOURCE_RELATIVE
                / Path(content_location["sourceShard"])
            ).resolve(strict=True)
        elif template_id and owner_source.is_relative_to(convo_engine_root):
            content_source = owner_source
        else:
            raise ValueError("selected variant has no canonical Conversation content owner")
        original_bytes = content_source.read_bytes()
        original_hash = _sha256(original_bytes)
        expected_source_hash = proposal.get("expectedSourceSHA256")
        if expected_source_hash is not None:
            if (not isinstance(expected_source_hash, str)
                    or not re.fullmatch(r"[a-f0-9]{64}", expected_source_hash)):
                raise ValueError("invalid_expected_source_sha256")
            if expected_source_hash != original_hash:
                raise ValueError("stale_source_sha256")
        source_diff: list[str] = []
        evidence = source_evidence(worker)

        proposed_translations = normalize_translations(
            entries[0].get("translations"),
            "isolated preview translations",
        )
        original_translation_hashes: dict[str, tuple[Path, str]] = {}
        baseline_content: dict[str, str] = {}
        cases: list[tuple[str, dict[str, Any], dict[str, Any], str]] = []
        for language in proposed_translations:
            scenario = merge(DEFAULT_SCENARIO, overrides)
            scenario.setdefault("runtime", {})["language"] = language
            observed = _real_case(scenario, utterance, worker=worker)
            target_ids = {variant_id} | ({template_id} if template_id else set())
            selection = [
                m for m in observed["messages"]
                if m.get("id") in target_ids
            ]
            if len(selection) != 1 or not isinstance(
                selection[0]["translationKey"], str
            ):
                raise ValueError("fixture did not realize precisely the proposed variant")
            key = selection[0]["translationKey"]
            src, relative, content = _verified_translation_asset(
                repository, language, key
            )
            if not isinstance(content.get(key), str):
                raise ValueError("missing canonical translation text")
            baseline_content[language] = content[key]
            original_translation_hashes[language] = (
                src, _sha256(src.read_bytes())
            )
            cases.append((language, scenario, observed, relative))

    with tempfile.TemporaryDirectory(prefix="pnc-observatory-proposal-") as dirname:
        overlay = Path(dirname)
        translation_diff: list[dict[str, str]] = []
        for language, _scenario, observed, relative in cases:
            key = next(
                m["translationKey"] for m in observed["messages"]
                if m.get("id") in target_ids
            )
            src, confirmed, data = _verified_translation_asset(
                repository, language, key)
            if relative != confirmed:
                raise ValueError("translation source changed during review")
            before = data[key]
            data[key] = proposed_translations[language]
            dest = overlay / relative
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
            translation_diff.append({
                "language": language, "key": key, "manifestPath": relative,
                "before": before, "candidate": proposed_translations[language],
            })

        result_cases = []
        selected_fingerprint = None
        candidate_worker: LuaSemanticWorker | None = None
        try:
            for language, scenario, baseline, _ in cases:
                # Run the exact production worker with only the two staged
                # authoritative source files substituted; all other behavior
                # remains loaded from the actual checkout and installed Core.
                if candidate_worker is None:
                    candidate_worker = LuaSemanticWorker(
                        scenario, repository=repository,
                        candidate_overlay_root=overlay,
                        candidate_overlay_module="",
                    )
                    candidate_worker.__enter__()
                else:
                    candidate_worker.import_source(scenario)
                candidate_turn = candidate_worker.input(utterance)
                final_inspector = build_conversation_inspector(candidate_turn)
                candidate_detail = candidate_worker.response_pool_detail(
                    proposal["poolID"], limit=16)
                candidate_messages = [
                    m["payload"] for m in candidate_turn.get("messages", [])
                    if m.get("speaker") == "npc"
                    and isinstance(m.get("payload"), dict)
                ]
                candidate = {
                    "accepted": candidate_turn.get("accepted"),
                    "messages": [{
                        "id": m.get("semanticTemplateID") or m.get("key"),
                        "variantID": m.get("semanticVariantID"),
                        "translationKey": m.get("translationKey"),
                        "text": m.get("text"),
                    } for m in candidate_messages[-4:]],
                    "actionCount": final_inspector.get("effects", {})
                        .get("sideEffects", {}).get("actionCount"),
                    "transportCount": final_inspector.get("effects", {})
                        .get("sideEffects", {}).get("transportCount"),
                }
                candidate_variant = next(
                    v for v in candidate_detail["variants"]
                    if v["id"] == variant_id
                )
                base_variant = _semantic_variant_metadata(variant)
                new_variant = _semantic_variant_metadata(candidate_variant)
                if base_variant != new_variant:
                    raise ValueError("candidate unexpectedly changed variant metadata")
                expected_new = proposed_translations[language]
                before_text = [
                    m["text"] for m in baseline["messages"]
                    if m.get("id") in target_ids
                ]
                after_text = [
                    m["text"] for m in candidate["messages"]
                    if m.get("id") in target_ids
                ]
                if (len(after_text) != 1 or after_text[0] != expected_new
                        or before_text == after_text):
                    raise ValueError("real-Lua candidate did not change target translation")
                if (baseline["actionCount"] != candidate["actionCount"]
                    or baseline["transportCount"] != candidate["transportCount"]
                    or baseline["accepted"] != candidate["accepted"]
                    or [m["id"] for m in baseline["messages"]]
                       != [m["id"] for m in candidate["messages"]]):
                    raise ValueError("candidate altered gameplay effects or selected keys")
                selected_fingerprint = _content_fingerprint(
                    proposed_translations
                )
                result_cases.append({
                    "language": language, "status": "PASS",
                    "baseline": baseline, "candidate": candidate,
                })
        finally:
            if candidate_worker is not None:
                candidate_worker.__exit__(None, None, None)
    if _sha256(content_source.read_bytes()) != original_hash or any(
        _sha256(path.read_bytes()) != sha for path, sha
        in original_translation_hashes.values()
    ):
        raise ValueError("production source files changed during candidate review")
    return {
        "ok": True, "schemaVersion": 1, "type": "response_candidate_isolated_preview",
        "sourceKind": "FIXTURE", "workerKind": "production_lua",
        "poolID": proposal["poolID"], "variantID": variant_id,
        "baselineFingerprint": _content_fingerprint(baseline_content),
        "candidateFingerprint": selected_fingerprint,
        "variantContract": {
            "conditions": variant.get("when") or {},
            "priority": variant.get("priority", 0),
            "plan": variant.get("planSummary") or {},
            "selectionSource": variant.get("selectionSource", "UNKNOWN"),
            "sourceKind": variant.get("sourceKind", "UNKNOWN"),
            "sourcePath": origin,
        },
        "sourcePath": origin, "canonicalOwnerVerified": True,
        "contentSourcePath": str(content_source.relative_to(repository)),
        "sourceSHA256": original_hash,
        "sourceSHA256GuardMatched": expected_source_hash == original_hash
            if expected_source_hash is not None else None,
        "translationSourceSHA256": {
            language: path_and_hash[1]
            for language, path_and_hash in original_translation_hashes.items()
        },
        "sourceDiff": source_diff,
        "translationDiff": translation_diff,
        "languageCases": result_cases, "checks": {
            "sameSelectedKey": True, "unchangedGameplayEffects": True,
            "unchangedSelectionMetadata": True,
            "authoritativeWorkerRenderedTranslations": True,
            "productionSourceUnchanged": True,
        },
        "sourceEvidence": evidence,
        "approved": False, "writesToProduction": 0,
        "candidateOverlayCleaned": True,
    }
