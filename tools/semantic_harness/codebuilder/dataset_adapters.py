"""Reviewed build-time adapters for external MASSIVE/SGD-style sources.

Adapters are deliberately read-only with respect to the repository. They
produce bounded review candidates and provenance diagnostics; only an
explicitly approved, redistribution-cleared decision may produce canonical
pattern records for the existing CodeBuilder.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import re
from typing import Any, Iterable


ADAPTERS = ("massive", "sgd")
MAX_SOURCE_BYTES = 64 * 1024 * 1024
MAX_RECORDS = 128
MAX_UTTERANCE = 256
MAX_DIAGNOSTICS = 32
PROMOTION_STATUSES = frozenset(("metadata_only", "derived_review_required", "approved"))


def _diagnostic(message: str, *, record: str | None = None) -> dict[str, str]:
    value = {"severity": "error", "message": str(message)}
    if record is not None:
        value["record"] = str(record)
    return value


def _bounded_text(value: Any, limit: int = MAX_UTTERANCE) -> str | None:
    if not isinstance(value, str):
        return None
    text = " ".join(value.split()).strip()
    return text[:limit] if text else None


def _source_is_runtime_media(path: Path) -> bool:
    parts = [part.lower() for part in path.resolve().parts]
    for index, part in enumerate(parts[:-1]):
        if part == "contents" and index + 2 < len(parts):
            if parts[index + 1] == "mods" and "media" in parts[index + 2:]:
                return True
    return False


def _load_manifest(path: Path, source_path: Path, adapter: str) -> tuple[dict[str, Any] | None, list[dict[str, str]]]:
    diagnostics: list[dict[str, str]] = []
    try:
        manifest = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        return None, [_diagnostic(f"cannot read dataset manifest: {error}")]
    if not isinstance(manifest, dict):
        return None, [_diagnostic("dataset manifest must be an object")]
    required = (
        "sourceName", "version", "revision", "url", "sha256", "language",
        "license", "allowedUse", "redistribution", "reviewedOn",
    )
    missing = [field for field in required if not isinstance(manifest.get(field), str) or not manifest[field].strip()]
    if missing:
        diagnostics.append(_diagnostic("dataset manifest missing: " + ", ".join(missing)))
    if manifest.get("adapter") != adapter:
        diagnostics.append(_diagnostic(f"manifest adapter must be {adapter!r}"))
    if manifest.get("redistribution") not in PROMOTION_STATUSES:
        diagnostics.append(_diagnostic("manifest redistribution must be metadata_only, derived_review_required, or approved"))
    if _source_is_runtime_media(source_path):
        diagnostics.append(_diagnostic("raw dataset source cannot be under Contents/mods/**/media"))
    try:
        size = source_path.stat().st_size
    except OSError as error:
        diagnostics.append(_diagnostic(f"cannot stat dataset source: {error}"))
        size = 0
    if size > MAX_SOURCE_BYTES:
        diagnostics.append(_diagnostic(f"dataset source exceeds {MAX_SOURCE_BYTES} byte build-time limit"))
    if not diagnostics:
        try:
            digest = hashlib.sha256(source_path.read_bytes()).hexdigest()
        except (OSError, UnicodeError) as error:
            diagnostics.append(_diagnostic(f"cannot hash dataset source: {error}"))
        else:
            if digest.lower() != str(manifest.get("sha256", "")).lower():
                diagnostics.append(_diagnostic("dataset source sha256 does not match manifest"))
    return manifest, diagnostics


def _load_records(path: Path, *, limit: int = MAX_RECORDS) -> tuple[list[Any], list[dict[str, str]]]:
    diagnostics: list[dict[str, str]] = []
    if path.suffix.lower() in {".jsonl", ".ndjson"}:
        records: list[Any] = []
        try:
            with path.open("r", encoding="utf-8") as handle:
                for line_number, line in enumerate(handle, 1):
                    if len(records) >= limit:
                        break
                    if not line.strip():
                        continue
                    try:
                        records.append(json.loads(line))
                    except json.JSONDecodeError as error:
                        diagnostics.append(_diagnostic(f"invalid JSONL record: {error.msg}", record=str(line_number)))
        except (OSError, UnicodeError) as error:
            diagnostics.append(_diagnostic(f"cannot read dataset source: {error}"))
        return records, diagnostics[:MAX_DIAGNOSTICS]
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        return [], [_diagnostic(f"cannot read dataset source: {error}")]
    if isinstance(value, list):
        return value[:limit], []
    if isinstance(value, dict):
        for key in ("data", "examples", "dialogues", "conversations"):
            if isinstance(value.get(key), list):
                return value[key][:limit], []
    return [], [_diagnostic("dataset source must contain a list or a supported list field")]


def _stable_id(prefix: str, *values: Any) -> str:
    payload = "\x1f".join(str(value or "") for value in values)
    return f"{prefix}.{hashlib.sha256(payload.encode('utf-8')).hexdigest()[:16]}"


def _massive_candidates(records: Iterable[Any], manifest: dict[str, Any]) -> tuple[list[dict[str, Any]], list[dict[str, str]]]:
    candidates: list[dict[str, Any]] = []
    diagnostics: list[dict[str, str]] = []
    for index, record in enumerate(records):
        if not isinstance(record, dict):
            diagnostics.append(_diagnostic("MASSIVE record must be an object", record=str(index)))
            continue
        utterance = _bounded_text(record.get("utt") or record.get("utterance") or record.get("text"))
        if not utterance:
            diagnostics.append(_diagnostic("MASSIVE record has no bounded utterance", record=str(index)))
            continue
        record_id = record.get("id") or record.get("uid") or index
        candidates.append({
            "id": _stable_id("massive", manifest.get("revision"), record_id, utterance),
            "adapter": "massive",
            "sourceRecordID": str(record_id),
            "locale": _bounded_text(record.get("locale") or manifest.get("language"), 32),
            "domain": _bounded_text(record.get("domain") or record.get("scenario"), 96),
            "intent": _bounded_text(record.get("intent") or record.get("category"), 96),
            "slots": record.get("slots") if isinstance(record.get("slots"), (dict, list)) else {},
            "utterance": utterance,
            "reviewed": False,
            "status": "unmapped",
        })
    return candidates, diagnostics[:MAX_DIAGNOSTICS]


def _sgd_candidates(records: Iterable[Any], manifest: dict[str, Any]) -> tuple[list[dict[str, Any]], list[dict[str, str]]]:
    candidates: list[dict[str, Any]] = []
    diagnostics: list[dict[str, str]] = []
    for dialogue_index, dialogue in enumerate(records):
        if not isinstance(dialogue, dict):
            diagnostics.append(_diagnostic("SGD dialogue must be an object", record=str(dialogue_index)))
            continue
        dialogue_id = dialogue.get("dialogue_id") or dialogue.get("id") or dialogue_index
        turns = dialogue.get("turns")
        if not isinstance(turns, list):
            diagnostics.append(_diagnostic("SGD dialogue has no turns list", record=str(dialogue_id)))
            continue
        for turn_index, turn in enumerate(turns):
            if not isinstance(turn, dict) or str(turn.get("speaker", "")).upper() not in {"USER", "CUSTOMER"}:
                continue
            utterance = _bounded_text(turn.get("utterance") or turn.get("text"))
            if not utterance:
                diagnostics.append(_diagnostic("SGD user turn has no bounded utterance", record=f"{dialogue_id}:{turn_index}"))
                continue
            frames = turn.get("frames") if isinstance(turn.get("frames"), list) else []
            frame = frames[0] if frames and isinstance(frames[0], dict) else {}
            state = frame.get("state") if isinstance(frame.get("state"), dict) else {}
            acts = turn.get("dialogue_acts") if isinstance(turn.get("dialogue_acts"), list) else []
            candidates.append({
                "id": _stable_id("sgd", manifest.get("revision"), dialogue_id, turn_index, utterance),
                "adapter": "sgd",
                "sourceRecordID": f"{dialogue_id}:{turn_index}",
                "locale": _bounded_text(manifest.get("language"), 32),
                "service": _bounded_text(frame.get("service") or dialogue.get("service"), 96),
                "intent": _bounded_text(state.get("active_intent") or turn.get("intent"), 96),
                "dialogueActs": acts[:8],
                "slots": state.get("slot_values") if isinstance(state.get("slot_values"), dict) else {},
                "utterance": utterance,
                "reviewed": False,
                "status": "unmapped",
            })
    return candidates, diagnostics[:MAX_DIAGNOSTICS]


def preview_dataset_adapter(
    adapter: str,
    source_path: Path,
    manifest_path: Path,
    *,
    max_records: int = MAX_RECORDS,
) -> dict[str, Any]:
    """Read a bounded external source into an effect-free review report."""
    source_path = source_path.expanduser().resolve()
    manifest_path = manifest_path.expanduser().resolve()
    base: dict[str, Any] = {
        "ok": False,
        "type": "dataset_adapter_review",
        "adapter": adapter,
        "sourcePath": str(source_path),
        "manifestPath": str(manifest_path),
        "previewOnly": True,
        "effectFree": True,
        "runtimePackaged": False,
        "writes": [],
        "candidates": [],
        "diagnostics": [],
    }
    if adapter not in ADAPTERS:
        base["diagnostics"] = [_diagnostic(f"unsupported dataset adapter: {adapter}")]
        return base
    if max_records < 1 or max_records > MAX_RECORDS:
        base["diagnostics"] = [_diagnostic(f"max_records must be 1..{MAX_RECORDS}")]
        return base
    manifest, manifest_diagnostics = _load_manifest(manifest_path, source_path, adapter)
    if manifest is None or manifest_diagnostics:
        base["diagnostics"] = manifest_diagnostics[:MAX_DIAGNOSTICS]
        return base
    records, load_diagnostics = _load_records(source_path, limit=max_records)
    if adapter == "massive":
        candidates, adapter_diagnostics = _massive_candidates(records, manifest)
    else:
        candidates, adapter_diagnostics = _sgd_candidates(records, manifest)
    diagnostics = (load_diagnostics + adapter_diagnostics)[:MAX_DIAGNOSTICS]
    base.update({
        "ok": not diagnostics,
        "source": {
            key: manifest.get(key)
            for key in (
                "sourceName", "version", "revision", "url", "sha256", "language",
                "license", "allowedUse", "redistribution", "reviewedOn",
            )
        },
        "recordLimit": max_records,
        "recordsRead": len(records),
        "candidateCount": len(candidates),
        "unmappedCount": len(candidates),
        "candidates": candidates,
        "diagnostics": diagnostics,
        "promotionAllowed": manifest.get("redistribution") == "approved"
        and manifest.get("allowRawText") is True,
    })
    return base


def promote_reviewed_candidates(
    report: dict[str, Any],
    decisions: Iterable[dict[str, Any]],
) -> dict[str, Any]:
    """Convert explicit, license-cleared reviewer decisions into canonical patterns."""
    if not isinstance(report, dict) or report.get("ok") is not True:
        return {
            "ok": False,
            "type": "dataset_adapter_promotion",
            "patterns": [],
            "diagnostics": [_diagnostic("adapter report is not valid")],
            "writes": [],
        }
    if report.get("promotionAllowed") is not True:
        return {
            "ok": False,
            "type": "dataset_adapter_promotion",
            "patterns": [],
            "diagnostics": [_diagnostic("manifest does not approve derived raw-text redistribution")],
            "writes": [],
        }
    candidates = {
        str(candidate.get("id")): candidate
        for candidate in report.get("candidates", [])
        if isinstance(candidate, dict) and candidate.get("id")
    }
    patterns: list[dict[str, Any]] = []
    diagnostics: list[dict[str, str]] = []
    for decision in decisions:
        if not isinstance(decision, dict):
            diagnostics.append(_diagnostic("review decision must be an object"))
            continue
        candidate_id = str(decision.get("candidateID") or "")
        candidate = candidates.get(candidate_id)
        if candidate is None:
            diagnostics.append(_diagnostic("review decision references unknown candidate", record=candidate_id))
            continue
        if decision.get("approved") is not True:
            continue
        mapping = decision.get("mapping")
        if not isinstance(mapping, dict):
            diagnostics.append(_diagnostic("approved candidate requires an explicit mapping", record=candidate_id))
            continue
        emit = mapping.get("emit")
        canonical_concept = mapping.get("canonicalConcept")
        dialogue_state = mapping.get("dialogueState")
        if not isinstance(emit, dict) or not isinstance(canonical_concept, str) or not isinstance(dialogue_state, str):
            diagnostics.append(_diagnostic("mapping requires emit, canonicalConcept, and dialogueState", record=candidate_id))
            continue
        pattern_id = decision.get("patternID") or f"pnc.dataset.{candidate['adapter']}.{candidate_id.rsplit('.', 1)[-1]}"
        source_name = str((report.get("source") or {}).get("sourceName") or candidate["adapter"])
        patterns.append({
            "id": str(pattern_id),
            "utterance": candidate["utterance"],
            "emit": copy_scalar_json(emit),
            "negatives": [
                value for value in decision.get("negatives", [])
                if isinstance(value, str) and value.strip()
            ][:8],
            "reviewed": True,
            "sourceRefs": [source_name],
            "mapping": {
                "canonicalConcept": canonical_concept,
                "dialogueState": dialogue_state,
                "sourceRefs": [source_name],
            },
            "confidence": float(decision.get("confidence", 0.95)),
            "priority": int(decision.get("priority", 100)),
        })
    return {
        "ok": not diagnostics,
        "type": "dataset_adapter_promotion",
        "adapter": report.get("adapter"),
        "patterns": patterns,
        "promotedCount": len(patterns),
        "diagnostics": diagnostics,
        "writes": [],
        "canonicalSource": (
            "tools/semantic_harness/codebuilder/sources/conversation/patterns/common/"
        ),
        "runtimePackaged": False,
    }


def copy_scalar_json(value: Any) -> Any:
    """Copy reviewer-provided JSON without retaining adapter/raw-record objects."""
    return json.loads(json.dumps(value, ensure_ascii=False))
