"""CodeBuilder ConvoEngine S6M4 normalization and family-folding engine.

Provides effect-free preview and validated write operations that normalize
legacy PSDL/fragmented ConvoEngine sources into canonical single-family
``psychopatz.convo-engine.v1`` documents:

- Strips redundant ``semantic.`` and ``text.`` prefixes from family identities
  and first-party references.
- Folds pure style bundles (``neutral``/``warm``/``terse``/``guarded``/``friendly``)
  into ``say.variants`` with localized text arrays.
- Folds pure wording-numbered records (``.1``/``.2``/``.01``/``.line_01``/``_01``)
  into positive-integer ``say`` realization keys (or direct single-``say``
  shorthand when only one realization exists).
- Preserves ``slots``, ``target``, ``participants``, per-variant conditions,
  ``metadata.responsePoolID``, ``metadata.textTarget``, and merged
  ``metadata.textRows``.
"""

from __future__ import annotations

import copy
import re
from collections.abc import Mapping, Sequence
from pathlib import Path
from typing import Any

from .convo_engine_authoring import load_json_document, write_json_document
from .convo_engine_exchange import resolve_family_identity
from .conversation_model import fingerprint
from .errors import CompileError
from .psdl_compiler import CONVO_ENGINE_SCHEMA, compile_convo_engine_document


_STYLE_SUFFIX_RE = re.compile(r"\.(neutral|warm|terse|guarded|friendly)$")
_NUMERIC_SUFFIX_RE = re.compile(
    r"^(?P<base>.+?)(?:(?:\.line_|_|\.)0*(?P<num>[1-9][0-9]*))$"
)


def strip_redundant_id_prefix(value: str) -> str:
    """Remove redundant ``semantic.`` or legacy ``text.`` prefix from an ID."""
    text = str(value or "").strip()
    if text.startswith("semantic."):
        return text[len("semantic."):]
    if text.startswith("text."):
        return text[len("text."):]
    return text


def split_canonical_identity(
    raw_id: str,
    namespace: str | None = None,
    *,
    strip_numeric_suffix: bool = False,
) -> tuple[str, str | None, str, str | None, int | None]:
    """Return ``(canonical_id, namespace, local_id, style_hint, realization_num)``."""
    combined = f"{namespace}.{raw_id}" if namespace else str(raw_id)
    cleaned = strip_redundant_id_prefix(combined)
    style_hint: str | None = None
    realization_num: int | None = None

    style_match = _STYLE_SUFFIX_RE.search(cleaned)
    if style_match:
        candidate_base = cleaned[: style_match.start()]
        if _NUMERIC_SUFFIX_RE.match(candidate_base):
            style_hint = style_match.group(1)
            cleaned = candidate_base

    if strip_numeric_suffix:
        num_match = _NUMERIC_SUFFIX_RE.match(cleaned)
        if num_match:
            cleaned = num_match.group("base")
            realization_num = int(num_match.group("num"))

    if "." in cleaned:
        ns_part, local_part = cleaned.rsplit(".", 1)
        try:
            canon, norm_ns, norm_local = resolve_family_identity(
                ns_part, local_part, strict_convo_engine=True
            )
            return canon, norm_ns, norm_local, style_hint, realization_num
        except CompileError:
            pass
    return cleaned, None, cleaned, style_hint, realization_num


def _as_text_list(value: Any) -> list[str]:
    if isinstance(value, str):
        return [value]
    if isinstance(value, Sequence) and not isinstance(value, (str, bytes)):
        return [str(item) for item in value if isinstance(item, str) and item.strip()]
    return []


def _collapse_localized_texts(items: Sequence[Mapping[str, Any]]) -> dict[str, list[str]]:
    merged: dict[str, list[str]] = {}
    for text_map in items:
        if not isinstance(text_map, Mapping):
            continue
        for locale, raw_val in text_map.items():
            target = merged.setdefault(str(locale), [])
            target.extend(_as_text_list(raw_val))
    return merged


def _clean_variant_metadata(metadata: Any) -> dict[str, Any]:
    if not isinstance(metadata, Mapping):
        return {}
    cleaned = copy.deepcopy(dict(metadata))
    for field in ("templateID", "textKey"):
        if isinstance(cleaned.get(field), str):
            cleaned[field] = strip_redundant_id_prefix(cleaned[field])
    return cleaned


def _extract_record_variants(
    record: Mapping[str, Any],
    *,
    default_style: str = "neutral",
) -> tuple[list[dict[str, Any]], Any, list[dict[str, Any]]]:
    """Extract normalized variants, dialogue act, and any derived textRows."""
    style = default_style
    rec_meta = record.get("metadata") if isinstance(record.get("metadata"), Mapping) else {}
    if isinstance(rec_meta.get("style"), str) and rec_meta["style"].strip():
        style = rec_meta["style"].strip()
    elif str(record.get("id") or "") in {
        "neutral", "warm", "terse", "guarded", "friendly",
        "bond_neutral", "bond_warm", "bond_terse", "bond_guarded",
    }:
        style = str(record["id"])
    elif str(record.get("id") or "").endswith(".friendly"):
        style = "friendly"

    derived_rows: list[dict[str, Any]] = []
    if isinstance(rec_meta.get("textTarget"), str) and isinstance(rec_meta.get("textRows"), list):
        derived_rows.extend(copy.deepcopy(rec_meta["textRows"]))

    response = record.get("response")
    if isinstance(response, Mapping):
        act = response.get("act")
        raw_variants = response.get("variants")
        if isinstance(raw_variants, list) and raw_variants:
            has_special = any(
                "when" in v
                or bool(set(v.get("metadata") or {}) - {"style", "textKey"})
                for v in raw_variants
                if isinstance(v, Mapping)
            )
            if has_special:
                out_variants: list[dict[str, Any]] = []
                for v in raw_variants:
                    if not isinstance(v, Mapping):
                        continue
                    item: dict[str, Any] = {
                        "id": strip_redundant_id_prefix(str(v.get("id") or style)),
                        "text": copy.deepcopy(v.get("text") or {}),
                    }
                    if "when" in v:
                        item["when"] = copy.deepcopy(v["when"])
                    vmd = _clean_variant_metadata(v.get("metadata"))
                    if vmd:
                        item["metadata"] = vmd
                    out_variants.append(item)
                return out_variants, act, derived_rows

            if isinstance(rec_meta.get("textTarget"), str) and not rec_meta.get("textRows"):
                for v in raw_variants:
                    if not isinstance(v, Mapping):
                        continue
                    vmd = v.get("metadata") or {}
                    tkey = vmd.get("textKey") or v.get("id")
                    if isinstance(tkey, str) and v.get("text"):
                        derived_rows.append({
                            "key": tkey,
                            "text": copy.deepcopy(v["text"]),
                        })
            collapsed = _collapse_localized_texts(
                [v.get("text") for v in raw_variants if isinstance(v, Mapping)]
            )
            return [{"id": style, "text": collapsed}], act, derived_rows

        if isinstance(response.get("text"), Mapping):
            return [{"id": style, "text": copy.deepcopy(response["text"])}], act, derived_rows

    if isinstance(record.get("text"), Mapping):
        if (
            isinstance(rec_meta.get("textTarget"), str)
            and not rec_meta.get("textRows")
            and isinstance(rec_meta.get("textKey"), str)
        ):
            derived_rows.append({
                "key": rec_meta["textKey"],
                "text": copy.deepcopy(record["text"]),
            })
        return [{"id": style, "text": copy.deepcopy(record["text"])}], None, derived_rows

    if isinstance(record.get("respond"), Mapping):
        return [{"id": style, "text": copy.deepcopy(record["respond"])}], None, derived_rows

    return [], None, derived_rows


def _clean_family_metadata(
    records: Sequence[Mapping[str, Any]],
    *,
    derived_rows: Sequence[Mapping[str, Any]],
    response_act: Any,
    multi_folded: bool,
) -> dict[str, Any]:
    """Merge non-redundant family metadata across folded source records."""
    merged: dict[str, Any] = {}
    for rec in records:
        md = rec.get("metadata")
        if not isinstance(md, Mapping):
            continue
        for k, v in md.items():
            if k in {"responseTemplateID", "style", "textRows", "textKey"}:
                if k == "textKey" and multi_folded:
                    continue
                if k in {"responseTemplateID", "style", "textRows"}:
                    continue
            if k == "responsePoolID" and isinstance(v, str):
                merged.setdefault(k, strip_redundant_id_prefix(v))
                continue
            merged.setdefault(k, copy.deepcopy(v))

    if response_act and "responseAct" not in merged:
        merged["responseAct"] = response_act

    if derived_rows:
        dedup_rows: list[dict[str, Any]] = []
        seen_keys: set[str] = set()
        for row in derived_rows:
            key = str(row.get("key") or "")
            if not key or key in seen_keys:
                continue
            seen_keys.add(key)
            dedup_rows.append(copy.deepcopy(dict(row)))
        if dedup_rows:
            merged["textRows"] = dedup_rows
    return merged


def _fold_say_records(
    records: Sequence[Mapping[str, Any]],
    *,
    strip_numeric_suffix: bool,
    force_style_bundle: bool = False,
) -> dict[str, Any]:
    """Fold one or more dialogue records into one canonical ``say`` family."""
    first = records[0]
    if (
        len(records) == 1
        and (
            (isinstance(first.get("response"), Mapping) and isinstance(first["response"].get("turns"), list))
            or (isinstance(first.get("response"), Mapping) and first["response"].get("variants") == [])
            or "offers" in first
        )
    ):
        doc = copy.deepcopy(dict(first))
        doc["schema"] = CONVO_ENGINE_SCHEMA
        canon_id, ns, local_id, _, _ = split_canonical_identity(
            str(doc.get("id") or ""),
            doc.get("namespace"),
            strip_numeric_suffix=strip_numeric_suffix,
        )
        if ns:
            doc["namespace"] = ns
        doc["id"] = local_id
        md = doc.get("metadata")
        if isinstance(md, dict) and isinstance(md.get("responseTemplateID"), str):
            md.pop("responseTemplateID", None)
        return doc
    if any("offers" in r for r in records) and len(records) > 1:
        raise CompileError("Cannot fold multi-record offer/turn interactions in S6M4")

    # Determine canonical target identity from records.
    style_names = {
        "guarded", "neutral", "terse", "warm", "friendly",
        "bond_guarded", "bond_neutral", "bond_terse", "bond_warm",
    }
    styles_or_ids = {str(r.get("id") or "") for r in records}
    is_style_bundle = force_style_bundle or (
        len(records) > 1
        and styles_or_ids <= (style_names | {"queued"})
    )

    def record_identity(rec: Mapping[str, Any]) -> tuple[str, str | None, str, str | None, int | None]:
        raw_id = str(rec.get("id") or "")
        ns = rec.get("namespace")
        rec_meta = rec.get("metadata") if isinstance(rec.get("metadata"), Mapping) else {}
        pool_id = rec_meta.get("responsePoolID")
        if isinstance(pool_id, str) and strip_redundant_id_prefix(pool_id) == "question.identity":
            return (
                "response_pool.question.identity",
                "response_pool.question",
                "identity",
                rec_meta.get("style") if isinstance(rec_meta.get("style"), str) else None,
                None,
            )
        if is_style_bundle and ns and raw_id in style_names:
            return split_canonical_identity(
                str(ns),
                None,
                strip_numeric_suffix=strip_numeric_suffix,
            )
        if (
            is_style_bundle
            and styles_or_ids <= {"queued", "friendly"}
            and raw_id in {"queued", "friendly"}
            and isinstance(rec_meta.get("responseTemplateID"), str)
        ):
            base = strip_redundant_id_prefix(rec_meta["responseTemplateID"])
            if base.endswith(".friendly"):
                base = base[:-len(".friendly")]
            return split_canonical_identity(base, None, strip_numeric_suffix=strip_numeric_suffix)
        raw_ident = split_canonical_identity(raw_id, ns, strip_numeric_suffix=strip_numeric_suffix)
        if (
            not is_style_bundle
            and isinstance(rec_meta.get("responseTemplateID"), str)
            and isinstance(rec_meta.get("style"), str)
        ):
            tpl_base = strip_redundant_id_prefix(rec_meta["responseTemplateID"])
            if not tpl_base.startswith("compat."):
                tpl_ident = split_canonical_identity(
                    tpl_base,
                    None,
                    strip_numeric_suffix=strip_numeric_suffix,
                )
                if len(records) == 1:
                    return tpl_ident[0], tpl_ident[1], tpl_ident[2], rec_meta["style"], tpl_ident[4]
                return tpl_ident[0], tpl_ident[1], tpl_ident[2], raw_ident[3] or rec_meta["style"], raw_ident[4]
            if len(records) == 1 and ns and raw_id in {"neutral", "terse", "warm", "guarded"}:
                base_ns = strip_redundant_id_prefix(str(ns))
                ns_ident = split_canonical_identity(base_ns, None, strip_numeric_suffix=strip_numeric_suffix)
                return ns_ident[0], ns_ident[1], ns_ident[2], rec_meta["style"], ns_ident[4]
            return raw_ident
        if (
            not is_style_bundle
            and len(records) == 1
            and ns
            and raw_id in style_names
            and rec_meta.get("style") == raw_id
        ):
            return split_canonical_identity(str(ns), None, strip_numeric_suffix=strip_numeric_suffix)
        return raw_ident

    identities = [record_identity(r) for r in records]
    _, ns0, local0, _, _ = identities[0]
    nums = [item[4] for item in identities]
    if not is_style_bundle and len(records) > 1:
        is_style_bundle = all(ident[0] == identities[0][0] and n is None for ident, n in zip(identities, nums))

    merged_slots: dict[str, Any] = {}
    merged_participants: dict[str, Any] = {}
    merged_target: dict[str, Any] | None = None
    merged_when: Any = None
    merged_on: Any = None
    all_rows: list[dict[str, Any]] = []
    chosen_act: Any = None

    def collect_shared(rec: Mapping[str, Any]) -> None:
        nonlocal merged_target, merged_when, merged_on
        if isinstance(rec.get("slots"), Mapping):
            for sk, sv in rec["slots"].items():
                merged_slots.setdefault(sk, copy.deepcopy(sv))
        if isinstance(rec.get("participants"), Mapping) and not merged_participants:
            merged_participants.update(copy.deepcopy(rec["participants"]))
        if isinstance(rec.get("target"), Mapping) and merged_target is None:
            merged_target = copy.deepcopy(rec["target"])
        if "when" in rec and merged_when is None:
            merged_when = copy.deepcopy(rec["when"])
        if "on" in rec and merged_on is None:
            merged_on = copy.deepcopy(rec["on"])

    if is_style_bundle and len(records) > 1:
        variants: list[dict[str, Any]] = []
        seen_vids: set[str] = set()
        # Sort neutral first if present, then stable lexical order.
        def style_order(rec: Mapping[str, Any]) -> tuple[int, str]:
            md_style = (rec.get("metadata") or {}).get("style") if isinstance(rec.get("metadata"), Mapping) else None
            raw_id = str(md_style or rec.get("id") or "")
            if raw_id in {"queued", "neutral"}:
                return (0, raw_id)
            return (1, raw_id)

        for rec in sorted(records, key=style_order):
            collect_shared(rec)
            hint = "neutral" if str(rec.get("id")) == "queued" else str(rec.get("id") or "neutral")
            rec_vars, act, rows = _extract_record_variants(rec, default_style=hint)
            all_rows.extend(rows)
            if act and chosen_act is None:
                chosen_act = act
            for v in rec_vars:
                vid = v["id"]
                if vid in seen_vids:
                    vid = f"{vid}_{len(variants) + 1}"
                    v["id"] = vid
                seen_vids.add(vid)
                variants.append(v)
        say_value: Any = {"variants": variants}
    elif len(records) == 1:
        rec = records[0]
        collect_shared(rec)
        hint = identities[0][3] or "neutral"
        rec_vars, act, rows = _extract_record_variants(rec, default_style=hint)
        all_rows.extend(rows)
        chosen_act = act
        say_value = {"variants": rec_vars} if rec_vars else copy.deepcopy(rec.get("say"))
    else:
        # Multi-realization numbering: sort naturally by parsed number (default 0 first if unnumbered base + .1..N)
        indexed_pairs = []
        for idx, (rec, ident) in enumerate(zip(records, identities)):
            num = ident[4] if ident[4] is not None else 0
            indexed_pairs.append((num, idx, rec, ident))
        indexed_pairs.sort(key=lambda item: (item[0], item[1]))
        say_dict: dict[str, Any] = {}
        for r_index, (_num, _orig, rec, ident) in enumerate(indexed_pairs, start=1):
            collect_shared(rec)
            hint = ident[3] or "neutral"
            rec_vars, act, rows = _extract_record_variants(rec, default_style=hint)
            all_rows.extend(rows)
            if act and chosen_act is None:
                chosen_act = act
            say_dict[str(r_index)] = {"variants": rec_vars}
        say_value = say_dict

    out: dict[str, Any] = {
        "schema": CONVO_ENGINE_SCHEMA,
        "kind": "dialogue",
    }
    if ns0:
        out["namespace"] = ns0
    out["id"] = local0
    out["owner"] = first.get("owner")
    if merged_participants:
        out["participants"] = merged_participants
    if merged_target is not None:
        out["target"] = merged_target
    if merged_slots:
        out["slots"] = merged_slots
    if merged_when is not None:
        out["when"] = merged_when
    if merged_on is not None:
        out["on"] = merged_on
    cleaned_md = _clean_family_metadata(
        records,
        derived_rows=all_rows,
        response_act=chosen_act,
        multi_folded=len(records) > 1,
    )
    if cleaned_md:
        out["metadata"] = cleaned_md
    out["say"] = say_value
    return out


def normalize_behavior_document(document: Mapping[str, Any]) -> dict[str, Any]:
    """Strip redundant ``semantic.`` prefixes inside a behavior document's outputs."""
    out = copy.deepcopy(dict(document))
    if "schema" not in out:
        out["schema"] = CONVO_ENGINE_SCHEMA
    outputs = out.get("outputs")
    if isinstance(outputs, dict):
        for spec in outputs.values():
            if isinstance(spec, dict) and isinstance(spec.get("contentTemplateID"), str):
                spec["contentTemplateID"] = strip_redundant_id_prefix(
                    spec["contentTemplateID"]
                )
    return out


def normalize_documents(
    documents: Sequence[Mapping[str, Any]],
    *,
    dest_path: Path | None = None,
    source_paths: Sequence[Path] = (),
    default_owner: str | None = None,
    strip_numeric_suffix: bool = True,
    force_style_bundle: bool = False,
    write: bool = False,
    prune_sources: bool = False,
) -> dict[str, Any]:
    """Normalize one or more ConvoEngine/PSDL in-memory documents into one canonical family."""
    if not documents:
        raise CompileError("normalize_documents requires at least one document")
    resolved_sources = [Path(p).expanduser().resolve() for p in source_paths]
    if dest_path is not None:
        target_dest = Path(dest_path).expanduser().resolve()
    elif resolved_sources:
        target_dest = resolved_sources[0]
    else:
        target_dest = None

    records: list[dict[str, Any]] = []
    source_kinds: set[str] = set()
    for doc in documents:
        if "records" in doc and isinstance(doc["records"], list):
            for rec in doc["records"]:
                if isinstance(rec, Mapping):
                    rec_copy = copy.deepcopy(dict(rec))
                    if "owner" not in rec_copy and doc.get("owner"):
                        rec_copy["owner"] = doc["owner"]
                    records.append(rec_copy)
                    source_kinds.add(str(rec_copy.get("kind") or "dialogue"))
        else:
            records.append(copy.deepcopy(dict(doc)))
            source_kinds.add(str(doc.get("kind") or "dialogue"))

    if not records:
        raise CompileError(f"No records found in {[str(p) for p in resolved_sources]}")

    if source_kinds == {"behavior"} and len(records) == 1:
        canonical = normalize_behavior_document(records[0])
    elif "dialogue" in source_kinds:
        if len(source_kinds) > 1:
            raise CompileError(f"Cannot normalize mixed record kinds {sorted(source_kinds)}")
        if len(records) == 1 and "say" in records[0] and not str(records[0].get("id") or "").startswith(("semantic.", "text.")):
            canonical = copy.deepcopy(records[0])
            canonical["schema"] = CONVO_ENGINE_SCHEMA
        else:
            canonical = _fold_say_records(
                records,
                strip_numeric_suffix=strip_numeric_suffix,
                force_style_bundle=force_style_bundle,
            )
    else:
        if len(records) != 1:
            raise CompileError(f"Cannot fold multiple non-dialogue records of kind {sorted(source_kinds)}")
        canonical = copy.deepcopy(records[0])
        canonical["schema"] = CONVO_ENGINE_SCHEMA
        _canon_id, ns, local_id, _, _ = split_canonical_identity(
            str(canonical.get("id") or ""),
            canonical.get("namespace"),
            strip_numeric_suffix=False,
        )
        if ns:
            canonical["namespace"] = ns
        canonical["id"] = local_id

    if "owner" not in canonical or not canonical["owner"]:
        if not default_owner:
            raise CompileError("Cannot determine owner for normalized ConvoEngine family")
        canonical["owner"] = default_owner

    compiled = compile_convo_engine_document(
        canonical,
        source_path=target_dest or Path("convo_engine_normalized.json"),
        default_owner=default_owner,
        allow_legacy_schema=False,
        validate_cross_references=False,
    )

    removed_paths: list[str] = []
    writes: list[str] = []
    if write:
        if target_dest is None:
            raise CompileError("normalize_documents with write=True requires dest_path or source_paths")
        write_json_document(target_dest, canonical)
        writes.append(str(target_dest))
        if prune_sources:
            for src in resolved_sources:
                if src != target_dest and src.is_file():
                    src.unlink()
                    removed_paths.append(str(src))

    return {
        "ok": True,
        "previewOnly": not write,
        "effectFree": not write,
        "destPath": str(target_dest) if target_dest is not None else "",
        "sourcePaths": [str(p) for p in resolved_sources],
        "sourceRecordCount": len(records),
        "familyId": compiled["records"][0]["id"],
        "compiledFingerprint": compiled["fingerprint"],
        "sourceFingerprint": fingerprint(canonical),
        "document": canonical,
        "removedSources": removed_paths,
        "writes": writes,
    }


def normalize_source_group(
    source_paths: Sequence[Path],
    *,
    dest_path: Path | None = None,
    default_owner: str | None = None,
    strip_numeric_suffix: bool = True,
    force_style_bundle: bool = False,
    write: bool = False,
    prune_sources: bool = False,
) -> dict[str, Any]:
    """Normalize one or more ConvoEngine/PSDL source files into one canonical family."""
    if not source_paths:
        raise CompileError("normalize_source_group requires at least one source path")
    resolved_sources = [Path(p).expanduser().resolve() for p in source_paths]
    docs = [load_json_document(path) for path in resolved_sources]
    return normalize_documents(
        docs,
        dest_path=dest_path,
        source_paths=resolved_sources,
        default_owner=default_owner,
        strip_numeric_suffix=strip_numeric_suffix,
        force_style_bundle=force_style_bundle,
        write=write,
        prune_sources=prune_sources,
    )
