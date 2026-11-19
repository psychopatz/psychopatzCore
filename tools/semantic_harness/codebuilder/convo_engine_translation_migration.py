"""Deterministic CodeBuilder translation migration and hydration operations (S13B)."""

from __future__ import annotations

import copy
import json
from pathlib import Path
from typing import Any, Callable, Mapping

from .convo_engine_compiler import CONVO_ENGINE_SCHEMA
from .convo_engine_localization_audit import (
    CONVO_FAMILY_SUBDIRS,
    CONVO_TRANSLATION_SCHEMA,
    classify_family_localization,
    deterministic_translation_path,
    discover_canonical_translation_files,
    is_locale_map,
)
from .errors import CompileError
from .generation_ownership import CORE_OWNER, DT_COMMON_OWNER, HOOMANS_OWNER
from .workspace_catalog import WorkspaceCatalog


def _record_entry(
    entries_by_locale: dict[str, dict[str, Any]],
    entry_key: str,
    locale_map: Mapping[str, Any],
    *,
    source_label: str,
) -> None:
    """Record a {locale: value} map into entries_by_locale, failing on conflicting values."""
    for raw_lang, value in locale_map.items():
        lang = str(raw_lang).upper()
        loc_entries = entries_by_locale.setdefault(lang, {})
        if entry_key in loc_entries and loc_entries[entry_key] != value:
            raise CompileError(
                f"Conflicting {lang} translation for {entry_key!r} in {source_label}: "
                f"{loc_entries[entry_key]!r} vs {value!r}"
            )
        loc_entries[entry_key] = copy.deepcopy(value)


def _load_legacy_sidecars(
    doc: Mapping[str, Any],
    family_path: Path,
    source_root: Path,
) -> tuple[dict[str, dict[str, Any]], list[Path]]:
    sidecars = doc.get("textSidecars")
    if not isinstance(sidecars, Mapping):
        return {}, []
    loaded: dict[str, dict[str, Any]] = {}
    paths: list[Path] = []
    for raw_lang, rel_path in sorted(sidecars.items()):
        lang = str(raw_lang).upper()
        candidate = (family_path.parent / str(rel_path)).resolve()
        if not candidate.is_file():
            candidate = (source_root / str(rel_path)).resolve()
        if not candidate.is_file():
            raise CompileError(f"Missing legacy textSidecars file {rel_path!r} for {family_path}")
        try:
            payload = json.loads(candidate.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            raise CompileError(f"Invalid JSON in sidecar {candidate}: {error}") from error
        if not isinstance(payload, dict):
            raise CompileError(f"Sidecar must be a JSON object: {candidate}")
        loaded[lang] = payload
        paths.append(candidate)
    return loaded, paths


def _extract_say_block(
    say_node: Any,
    prefix: str,
    entries_by_locale: dict[str, dict[str, Any]],
    source_label: str,
) -> Any:
    """Extract inline locale maps from a say block and return the stripped structure."""
    if is_locale_map(say_node):
        _record_entry(entries_by_locale, f"{prefix}.variants.default", say_node, source_label=source_label)
        return {"variants": [{"id": "default"}]}
    if not isinstance(say_node, dict):
        return say_node

    out = copy.deepcopy(say_node)
    if "text" in out and is_locale_map(out["text"]):
        _record_entry(entries_by_locale, f"{prefix}.text", out.pop("text"), source_label=source_label)

    if isinstance(out.get("variants"), list):
        for idx, variant in enumerate(out["variants"]):
            if not isinstance(variant, dict):
                continue
            vid = str(variant.get("id") or f"idx_{idx}")
            if "text" in variant and is_locale_map(variant["text"]):
                _record_entry(
                    entries_by_locale,
                    f"{prefix}.variants.{vid}",
                    variant.pop("text"),
                    source_label=source_label,
                )
            vmeta = variant.get("metadata")
            if isinstance(vmeta, dict) and isinstance(vmeta.get("plan"), dict):
                turns = vmeta["plan"].get("turns")
                if isinstance(turns, list):
                    for t_idx, turn in enumerate(turns):
                        if not isinstance(turn, dict):
                            continue
                        tid = str(turn.get("id") or f"turn_{t_idx}")
                        segs = turn.get("segments")
                        if isinstance(segs, list):
                            for s_idx, seg in enumerate(segs):
                                if isinstance(seg, dict) and is_locale_map(seg.get("translations")):
                                    _record_entry(
                                        entries_by_locale,
                                        f"{prefix}.variants.{vid}.plan.turn.{tid}.segment.{s_idx}",
                                        seg.pop("translations"),
                                        source_label=source_label,
                                    )

    # Tiered keys like say.1, say.2, say.neutral, etc.
    for key, val in list(out.items()):
        if key in {"variants", "text", "realizations", "metadata"}:
            continue
        if is_locale_map(val):
            _record_entry(entries_by_locale, f"{prefix}.{key}.default", val, source_label=source_label)
            out[key] = {"variants": [{"id": "default"}]}
        elif isinstance(val, dict):
            if "text" in val and is_locale_map(val["text"]):
                _record_entry(entries_by_locale, f"{prefix}.{key}.text", val.pop("text"), source_label=source_label)
            if isinstance(val.get("variants"), list):
                for idx, variant in enumerate(val["variants"]):
                    if isinstance(variant, dict) and is_locale_map(variant.get("text")):
                        vid = str(variant.get("id") or f"idx_{idx}")
                        _record_entry(
                            entries_by_locale,
                            f"{prefix}.{key}.{vid}",
                            variant.pop("text"),
                            source_label=source_label,
                        )
    return out


def migrate_family_document(
    doc: Mapping[str, Any],
    family_path: Path,
    source_root: Path,
) -> tuple[dict[str, Any], dict[str, dict[str, Any]], list[Path]]:
    """Extract all localized prose from a ConvoEngine family and return (stripped_doc, translations_by_locale, legacy_sidecar_paths)."""
    source_label = str(family_path)
    out = copy.deepcopy(dict(doc))
    entries_by_locale: dict[str, dict[str, Any]] = {}

    # 1. Load legacy textSidecars first (if any)
    sidecar_by_locale, legacy_sidecar_paths = _load_legacy_sidecars(out, family_path, source_root)
    out.pop("textSidecars", None)

    for lang, sc in sidecar_by_locale.items():
        if isinstance(sc.get("variants"), Mapping):
            for vid, txt in sc["variants"].items():
                _record_entry(entries_by_locale, f"say.variants.{vid}", {lang: txt}, source_label=source_label)
        if isinstance(sc.get("reply"), Mapping):
            for outcome, turn_map in sc["reply"].items():
                if not isinstance(turn_map, Mapping):
                    continue
                for turn_key, var_map in turn_map.items():
                    if not isinstance(var_map, Mapping):
                        continue
                    for vid, txt in var_map.items():
                        _record_entry(
                            entries_by_locale,
                            f"reply.{outcome}.say.{turn_key}.{vid}",
                            {lang: txt},
                            source_label=source_label,
                        )
        if "translations" in sc:
            _record_entry(
                entries_by_locale,
                "realization.translations",
                {lang: sc["translations"]},
                source_label=source_label,
            )

    # 2. Extract inline fields (and fail closed on conflicts with sidecars)
    if isinstance(out.get("affordance"), dict) and is_locale_map(out["affordance"].get("label")):
        _record_entry(entries_by_locale, "affordance.label", out["affordance"].pop("label"), source_label=source_label)

    if "say" in out:
        out["say"] = _extract_say_block(out["say"], "say", entries_by_locale, source_label)

    if isinstance(out.get("reply"), dict):
        for outcome, outcome_payload in out["reply"].items():
            if isinstance(outcome_payload, dict) and "say" in outcome_payload:
                outcome_payload["say"] = _extract_say_block(
                    outcome_payload["say"],
                    f"reply.{outcome}.say",
                    entries_by_locale,
                    source_label,
                )

    if isinstance(out.get("response"), dict) and isinstance(out["response"].get("turns"), list):
        for t_idx, turn in enumerate(out["response"]["turns"]):
            if not isinstance(turn, dict):
                continue
            tid = str(turn.get("id") or f"turn_{t_idx}")
            if is_locale_map(turn.get("text")):
                _record_entry(entries_by_locale, f"response.turn.{tid}.text", turn.pop("text"), source_label=source_label)
            if isinstance(turn.get("offers"), list):
                for o_idx, offer in enumerate(turn["offers"]):
                    if not isinstance(offer, dict):
                        continue
                    oid = str(offer.get("id") or f"offer_{o_idx}")
                    if is_locale_map(offer.get("label")):
                        _record_entry(
                            entries_by_locale,
                            f"response.turn.{tid}.offer.{oid}.label",
                            offer.pop("label"),
                            source_label=source_label,
                        )
                    if is_locale_map(offer.get("utterance")):
                        _record_entry(
                            entries_by_locale,
                            f"response.turn.{tid}.offer.{oid}.utterance",
                            offer.pop("utterance"),
                            source_label=source_label,
                        )
                    ometa = offer.get("metadata")
                    if isinstance(ometa, dict) and is_locale_map(ometa.get("responseText")):
                        _record_entry(
                            entries_by_locale,
                            f"response.turn.{tid}.offer.{oid}.responseText",
                            ometa.pop("responseText"),
                            source_label=source_label,
                        )

    metadata = out.get("metadata")
    if isinstance(metadata, dict):
        pc = metadata.get("playerChoice")
        if isinstance(pc, dict):
            if is_locale_map(pc.get("label")):
                _record_entry(entries_by_locale, "playerChoice.label", pc.pop("label"), source_label=source_label)
            if is_locale_map(pc.get("choice")):
                _record_entry(entries_by_locale, "playerChoice.choice", pc.pop("choice"), source_label=source_label)
        if isinstance(metadata.get("textRows"), list):
            for idx, row in enumerate(metadata["textRows"]):
                if isinstance(row, dict) and is_locale_map(row.get("text")):
                    rkey = str(row.get("key") or f"row_{idx}")
                    _record_entry(entries_by_locale, f"textRows.{rkey}", row.pop("text"), source_label=source_label)

    if is_locale_map(out.get("forms")):
        _record_entry(entries_by_locale, "realization.forms", out.pop("forms"), source_label=source_label)
    if is_locale_map(out.get("translations")):
        _record_entry(entries_by_locale, "realization.translations", out.pop("translations"), source_label=source_label)

    # Ensure say.variants exists if sidecars populated say.variants.* without inline say
    if any(k.startswith("say.variants.") for loc in entries_by_locale.values() for k in loc):
        if "say" not in out:
            vids = sorted({
                k[len("say.variants."):]
                for loc in entries_by_locale.values()
                for k in loc
                if k.startswith("say.variants.") and "." not in k[len("say.variants."):]
            })
            out["say"] = {"variants": [{"id": vid} for vid in vids]}

    if entries_by_locale and "EN" not in entries_by_locale:
        raise CompileError(f"Migrated family {source_label} has localized entries without required EN locale")

    return out, entries_by_locale, legacy_sidecar_paths


def _hydrate_say_block(
    say_node: Any,
    prefix: str,
    by_entry_key: Mapping[str, dict[str, Any]],
) -> Any:
    if not isinstance(say_node, dict):
        return say_node
    out = copy.deepcopy(say_node)
    if f"{prefix}.text" in by_entry_key and "text" not in out:
        out["text"] = copy.deepcopy(by_entry_key[f"{prefix}.text"])
    if isinstance(out.get("variants"), list):
        for idx, variant in enumerate(out["variants"]):
            if not isinstance(variant, dict):
                continue
            vid = str(variant.get("id") or f"idx_{idx}")
            ek = f"{prefix}.variants.{vid}"
            if ek in by_entry_key and "text" not in variant:
                variant["text"] = copy.deepcopy(by_entry_key[ek])
            vmeta = variant.get("metadata")
            if isinstance(vmeta, dict) and isinstance(vmeta.get("plan"), dict):
                turns = vmeta["plan"].get("turns")
                if isinstance(turns, list):
                    for t_idx, turn in enumerate(turns):
                        if not isinstance(turn, dict):
                            continue
                        tid = str(turn.get("id") or f"turn_{t_idx}")
                        segs = turn.get("segments")
                        if isinstance(segs, list):
                            for s_idx, seg in enumerate(segs):
                                seg_ek = f"{prefix}.variants.{vid}.plan.turn.{tid}.segment.{s_idx}"
                                if isinstance(seg, dict) and seg_ek in by_entry_key and "translations" not in seg:
                                    seg["translations"] = copy.deepcopy(by_entry_key[seg_ek])
    for key, val in list(out.items()):
        if key in {"variants", "text", "realizations", "metadata"}:
            continue
        if isinstance(val, dict):
            if f"{prefix}.{key}.text" in by_entry_key and "text" not in val:
                val["text"] = copy.deepcopy(by_entry_key[f"{prefix}.{key}.text"])
            if isinstance(val.get("variants"), list):
                for idx, variant in enumerate(val["variants"]):
                    if isinstance(variant, dict):
                        vid = str(variant.get("id") or f"idx_{idx}")
                        ek = f"{prefix}.{key}.{vid}"
                        if ek in by_entry_key and "text" not in variant:
                            variant["text"] = copy.deepcopy(by_entry_key[ek])
    return out


def hydrate_family_translations(
    doc: dict[str, Any],
    translations_by_locale: Mapping[str, Mapping[str, Any]],
) -> dict[str, Any]:
    """Hydrate in-memory localized fields on a canonical ConvoEngine family from external translation entries."""
    if not translations_by_locale:
        return doc
    by_entry_key: dict[str, dict[str, Any]] = {}
    for lang, tr_doc in sorted(translations_by_locale.items()):
        entries = tr_doc.get("entries") if isinstance(tr_doc, Mapping) and "entries" in tr_doc else tr_doc
        if not isinstance(entries, Mapping):
            continue
        for entry_key, value in entries.items():
            by_entry_key.setdefault(str(entry_key), {})[str(lang).upper()] = copy.deepcopy(value)

    if not by_entry_key:
        return doc

    out = copy.deepcopy(doc)
    if "affordance.label" in by_entry_key and isinstance(out.get("affordance"), dict) and "label" not in out["affordance"]:
        out["affordance"]["label"] = copy.deepcopy(by_entry_key["affordance.label"])

    if "say" in out:
        out["say"] = _hydrate_say_block(out["say"], "say", by_entry_key)

    if isinstance(out.get("reply"), dict):
        for outcome, outcome_payload in out["reply"].items():
            if isinstance(outcome_payload, dict) and "say" in outcome_payload:
                outcome_payload["say"] = _hydrate_say_block(
                    outcome_payload["say"],
                    f"reply.{outcome}.say",
                    by_entry_key,
                )

    if isinstance(out.get("response"), dict) and isinstance(out["response"].get("turns"), list):
        for t_idx, turn in enumerate(out["response"]["turns"]):
            if not isinstance(turn, dict):
                continue
            tid = str(turn.get("id") or f"turn_{t_idx}")
            t_ek = f"response.turn.{tid}.text"
            if t_ek in by_entry_key and "text" not in turn:
                turn["text"] = copy.deepcopy(by_entry_key[t_ek])
            if isinstance(turn.get("offers"), list):
                for o_idx, offer in enumerate(turn["offers"]):
                    if not isinstance(offer, dict):
                        continue
                    oid = str(offer.get("id") or f"offer_{o_idx}")
                    l_ek = f"response.turn.{tid}.offer.{oid}.label"
                    u_ek = f"response.turn.{tid}.offer.{oid}.utterance"
                    r_ek = f"response.turn.{tid}.offer.{oid}.responseText"
                    if l_ek in by_entry_key and "label" not in offer:
                        offer["label"] = copy.deepcopy(by_entry_key[l_ek])
                    if u_ek in by_entry_key and "utterance" not in offer:
                        offer["utterance"] = copy.deepcopy(by_entry_key[u_ek])
                    ometa = offer.get("metadata")
                    if isinstance(ometa, dict) and r_ek in by_entry_key and "responseText" not in ometa:
                        ometa["responseText"] = copy.deepcopy(by_entry_key[r_ek])

    metadata = out.get("metadata")
    if isinstance(metadata, dict):
        pc = metadata.get("playerChoice")
        if isinstance(pc, dict):
            if "playerChoice.label" in by_entry_key and "label" not in pc:
                pc["label"] = copy.deepcopy(by_entry_key["playerChoice.label"])
            if "playerChoice.choice" in by_entry_key and "choice" not in pc:
                pc["choice"] = copy.deepcopy(by_entry_key["playerChoice.choice"])
        if isinstance(metadata.get("textRows"), list):
            for idx, row in enumerate(metadata["textRows"]):
                if isinstance(row, dict) and "text" not in row:
                    rkey = str(row.get("key") or f"row_{idx}")
                    ek = f"textRows.{rkey}"
                    if ek in by_entry_key:
                        row["text"] = copy.deepcopy(by_entry_key[ek])

    if "realization.forms" in by_entry_key and "forms" not in out:
        out["forms"] = copy.deepcopy(by_entry_key["realization.forms"])
    if "realization.translations" in by_entry_key and "translations" not in out:
        out["translations"] = copy.deepcopy(by_entry_key["realization.translations"])

    return out


def _resolve_source_roots(
    core_repository: Path,
    hoomans_repository: Path | None,
    dynamic_trading_repository: Path | None,
) -> dict[str, Path]:
    core_root = core_repository.expanduser().resolve()
    snapshot = WorkspaceCatalog.discover(
        core_root,
        core_repository=core_root,
        hoomans_repository=hoomans_repository,
        dynamic_trading_repository=dynamic_trading_repository,
        allow_sibling_discovery=False,
    )
    return dict(snapshot.source_roots_by_owner)


def run_translation_migration(
    core_repository: Path,
    *,
    hoomans_repository: Path | None = None,
    dynamic_trading_repository: Path | None = None,
    owner_filter: str | None = None,
    path_prefix: str | None = None,
    apply: bool = False,
    delete_legacy_sidecars: bool = True,
) -> dict[str, Any]:
    """Preview or atomically apply canonical translation migration for selected owner/path scope."""
    source_roots = _resolve_source_roots(core_repository, hoomans_repository, dynamic_trading_repository)
    planned: list[dict[str, Any]] = []
    skipped_clean: int = 0
    errors: list[dict[str, Any]] = []
    orphaned_legacy_sidecars: list[Path] = []

    for owner, source_root in sorted(source_roots.items()):
        if owner_filter and owner != owner_filter:
            continue
        if not source_root.is_dir():
            continue

        referenced_sidecars: set[Path] = set()
        all_legacy_sidecars: set[Path] = set()

        for subdir_name in CONVO_FAMILY_SUBDIRS:
            subdir = source_root / subdir_name
            if not subdir.is_dir():
                continue
            for file_path in sorted(subdir.rglob("*.json")):
                rel_from_root = str(file_path.relative_to(source_root))
                if "translations" in file_path.relative_to(source_root).parts:
                    all_legacy_sidecars.add(file_path.resolve())
                    continue
                if path_prefix and not rel_from_root.startswith(path_prefix):
                    continue
                try:
                    doc = json.loads(file_path.read_text(encoding="utf-8"))
                except (OSError, json.JSONDecodeError) as error:
                    errors.append({"owner": owner, "path": str(file_path), "error": str(error)})
                    continue
                if not isinstance(doc, Mapping) or doc.get("schema") != CONVO_ENGINE_SCHEMA:
                    continue

                info = classify_family_localization(doc, file_path, source_root)
                if info["shape"] in {"NO_LOCALIZED_TEXT", "CANONICAL_EXTERNAL_TRANSLATION"}:
                    skipped_clean += 1
                    continue

                try:
                    rewritten, entries_by_locale, legacy_paths = migrate_family_document(doc, file_path, source_root)
                except CompileError as error:
                    errors.append({"owner": owner, "id": doc.get("id"), "path": str(file_path), "error": str(error)})
                    continue

                for lp in legacy_paths:
                    referenced_sidecars.add(lp.resolve())

                # Validate round-trip hydration before writing
                hydrated = hydrate_family_translations(rewritten, entries_by_locale)
                if not entries_by_locale and info["shape"] != "TEXT_TARGET_ONLY":
                    errors.append({
                        "owner": owner,
                        "id": doc.get("id"),
                        "path": str(file_path),
                        "error": f"No entries extracted for shape {info['shape']}",
                    })
                    continue

                translation_outputs: dict[str, dict[str, Any]] = {}
                for lang, entries in sorted(entries_by_locale.items()):
                    out_path = deterministic_translation_path(source_root, file_path, lang)
                    payload = {
                        "schema": CONVO_TRANSLATION_SCHEMA,
                        "family": str(doc.get("id") or ""),
                        "locale": lang,
                        "entries": entries,
                    }
                    translation_outputs[str(out_path)] = payload

                planned.append({
                    "owner": owner,
                    "id": doc.get("id"),
                    "shape": info["shape"],
                    "sourcePath": str(file_path),
                    "rewrittenDoc": rewritten,
                    "translationOutputs": translation_outputs,
                    "legacySidecarPaths": [str(p) for p in legacy_paths],
                    "entryCount": len(entries_by_locale.get("EN", {})),
                })

        if not path_prefix:
            for sc_path in sorted(all_legacy_sidecars - referenced_sidecars):
                orphaned_legacy_sidecars.append(sc_path)

    if errors:
        return {
            "ok": False,
            "applied": False,
            "errorCount": len(errors),
            "errors": errors,
            "plannedCount": len(planned),
            "skippedClean": skipped_clean,
        }

    written_files: list[str] = []
    deleted_files: list[str] = []
    if apply:
        for item in planned:
            for out_path_str, payload in item["translationOutputs"].items():
                out_path = Path(out_path_str)
                out_path.parent.mkdir(parents=True, exist_ok=True)
                out_path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
                written_files.append(out_path_str)
            src_path = Path(item["sourcePath"])
            src_path.write_text(json.dumps(item["rewrittenDoc"], indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
            written_files.append(item["sourcePath"])
            if delete_legacy_sidecars:
                for lp_str in item["legacySidecarPaths"]:
                    lp = Path(lp_str)
                    if lp.is_file():
                        lp.unlink()
                        deleted_files.append(lp_str)
        if delete_legacy_sidecars:
            for sc_path in orphaned_legacy_sidecars:
                if sc_path.is_file():
                    sc_path.unlink()
                    deleted_files.append(str(sc_path))

    return {
        "ok": True,
        "applied": apply,
        "plannedCount": len(planned),
        "skippedClean": skipped_clean,
        "orphanedLegacySidecarCount": len(orphaned_legacy_sidecars),
        "writtenFileCount": len(written_files),
        "deletedFileCount": len(deleted_files),
        "preview": [
            {
                "owner": item["owner"],
                "id": item["id"],
                "shape": item["shape"],
                "sourcePath": item["sourcePath"],
                "translationPaths": sorted(item["translationOutputs"].keys()),
                "legacySidecarPaths": item["legacySidecarPaths"],
                "entryCount": item["entryCount"],
            }
            for item in planned
        ],
    }


__all__ = [
    "hydrate_family_translations",
    "migrate_family_document",
    "run_translation_migration",
]
