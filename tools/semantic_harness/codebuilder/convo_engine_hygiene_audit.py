"""Semantic family hygiene, anti-duplication, and anti-overpacking audit."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any, Iterable, Mapping

from .convo_engine_integrity_audit import CONVO_FAMILY_SUBDIRS

HYGIENE_AUDIT_SCHEMA = "psychopatz.convo-engine.family-hygiene-audit.v1"
DYNAMIC_TOKEN_AUDIT_SCHEMA = "psychopatz.convo-engine.dynamic-token-audit.v1"
DEFAULT_VARIANT_THRESHOLD = 12

RULE_ACTOR_OR_DIRECTION = "actor_or_direction_encoded_family_id"
RULE_STYLE_OR_TIER_SPLIT = "style_or_tier_split_family_id"
RULE_MISLEADING_FLOW = "misleading_flow_family_id"
RULE_OVERPACKED_VARIANT_POOL = "overpacked_variant_pool"
RULE_EMPTY_CANONICAL_DIR = "empty_canonical_source_dir"

RULE_EN_TL_PLACEHOLDER_MISMATCH = "en_tl_placeholder_mismatch"
RULE_UNCONDITIONAL_STRANGER_NAME = "unconditional_name_on_stranger_variant"

ALL_HYGIENE_RULES = (
    RULE_ACTOR_OR_DIRECTION,
    RULE_STYLE_OR_TIER_SPLIT,
    RULE_MISLEADING_FLOW,
    RULE_OVERPACKED_VARIANT_POOL,
    RULE_EMPTY_CANONICAL_DIR,
)

ALL_DYNAMIC_TOKEN_RULES = (
    RULE_EN_TL_PLACEHOLDER_MISMATCH,
    RULE_UNCONDITIONAL_STRANGER_NAME,
)

_PLACEHOLDER_TOKEN_RE = re.compile(r"\{([a-zA-Z0-9_.*]+)\}")
_STRANGER_VARIANT_RE = re.compile(
    r"(?:^|[._:/-])(stranger|unknown|first_contact|hostile|unmet)(?:$|[._:/-])",
    re.IGNORECASE,
)
_STRANGER_FAMILY_RE = re.compile(
    r"(?:^|[._:/-])(stranger|first_contact|hostile)(?:$|[._:/-])",
    re.IGNORECASE,
)
_BOND_PREFIX_RE = re.compile(
    r"^(?:bond|friend|ally|lover|companion|relative|partner|acquaintance|known)(?:_|$)",
    re.IGNORECASE,
)
_ACQUAINTANCE_COND_RE = re.compile(
    r"(?:"
    r"familiarity\s*(?:>|>=)\s*0*[1-9]|"
    r"familiarity\s*>\s*0\b|"
    r"familiarity\s*>=\s*0?\.[1-9]|"
    r"identitystate\s*==\s*['\"]?known|"
    r"identitytrust|"
    r"knowsaddressee|"
    r"knowsname|"
    r"bondkind\s*!=\s*['\"]?none|"
    r"\bbond\."
    r")",
    re.IGNORECASE,
)
_COVERAGE_TOKEN_BUCKETS = (
    "{addressee.name}",
    "{speaker.name}",
    "{scene.location}",
    "{scene.clock}",
    "{slot.*}",
)

_DIRECTION_COMPOUND_RE = re.compile(
    r"(?:^|_)(?:"
    r"npc_to_player|player_to_npc|npc_to_npc|player_to_actor|"
    r"actor_to_actor|speaker_to_listener|speaker_to_addressee|"
    r"one_to_one|two_actor|multi_actor"
    r")(?:$|_)"
)
_NUMBERED_ACTOR_RE = re.compile(
    r"(?:^|_)(?:witness|actor|npc|speaker|bystander|target)_?[0-9]+(?:$|_)"
)
_INTENT_FIELDS = ("intent", "semanticIntent", "dialogueAct", "act", "strategy")

STYLE_OR_TIER_TOKENS = frozenset({
    "aggressive",
    "acquaintance",
    "ally",
    "blunt",
    "bold",
    "bonded",
    "brave",
    "cautious",
    "cheerful",
    "close_friend",
    "cold",
    "comrade",
    "confident",
    "enemy",
    "friend",
    "grumpy",
    "guarded",
    "hostile",
    "lover",
    "nervous",
    "neutral",
    "panicked",
    "partner",
    "polite",
    "relative",
    "reserved",
    "rival",
    "rude",
    "sarcastic",
    "shaken",
    "stoic",
    "stranger",
    "terse",
    "timid",
    "trusted",
    "warm",
    "wary",
})


def _is_translation_path(rel_parts: tuple[str, ...]) -> bool:
    return "translations" in rel_parts


def _check_actor_or_direction_id(family_id: str) -> str | None:
    segments = [seg for seg in family_id.lower().split(".") if seg]
    for seg in segments:
        if seg in {"player", "npc"} or seg.startswith("player_") or seg.startswith("npc_"):
            return f"actor-encoded segment {seg!r}"
        if _DIRECTION_COMPOUND_RE.search(seg):
            return f"speaker-direction segment {seg!r}"
        if _NUMBERED_ACTOR_RE.search(seg):
            return f"numbered-actor segment {seg!r}"
    return None


def _check_style_or_tier_id(family_id: str) -> str | None:
    segments = [seg for seg in family_id.lower().split(".") if seg]
    if not segments:
        return None
    if len(segments) >= 2:
        for seg in segments[1:]:
            if seg in STYLE_OR_TIER_TOKENS:
                return seg
    last = segments[-1]
    if "_" in last:
        tail = last.rsplit("_", 1)[-1]
        if tail in STYLE_OR_TIER_TOKENS:
            return tail
    return None


def _has_flow_graph(doc: Mapping[str, Any]) -> bool:
    for key in ("flow", "nodes"):
        val = doc.get(key)
        if isinstance(val, (Mapping, list)) and len(val) > 0:
            return True
    return False


def _iter_variant_pools(node: Any, prefix: str = "") -> Iterable[tuple[str, list[Any]]]:
    if isinstance(node, Mapping):
        for key, val in node.items():
            path = f"{prefix}.{key}" if prefix else str(key)
            if key == "variants" and isinstance(val, list):
                yield path, val
            else:
                yield from _iter_variant_pools(val, path)
    elif isinstance(node, list):
        for idx, item in enumerate(node):
            yield from _iter_variant_pools(item, f"{prefix}[{idx}]")


def _pool_heterogeneous_intents(variants: list[Any]) -> dict[str, list[str]]:
    by_field: dict[str, set[str]] = {}
    for item in variants:
        if not isinstance(item, Mapping):
            continue
        for field in _INTENT_FIELDS:
            raw = item.get(field)
            if isinstance(raw, str) and raw.strip():
                by_field.setdefault(field, set()).add(raw.strip().lower())
        tags = item.get("tags")
        if isinstance(tags, list):
            for tag in tags:
                if isinstance(tag, str) and ":" in tag:
                    prefix, val = tag.split(":", 1)
                    prefix_low = prefix.strip().lower()
                    if prefix_low in {"intent", "act"} and val.strip():
                        by_field.setdefault(f"tag.{prefix_low}", set()).add(val.strip().lower())
    return {
        field: sorted(values)
        for field, values in sorted(by_field.items())
        if len(values) > 1
    }


def _check_empty_canonical_dirs(
    source_root: Path,
    findings: list[dict[str, Any]],
) -> tuple[int, int]:
    canonical_checked = 0
    empty_count = 0
    for subdir_name in CONVO_FAMILY_SUBDIRS:
        subdir = source_root / subdir_name
        if not subdir.is_dir():
            continue
        dirs_to_check = [subdir] + [
            p for p in sorted(subdir.rglob("*"))
            if p.is_dir() and not _is_translation_path(p.relative_to(source_root).parts)
        ]
        for dir_path in dirs_to_check:
            canonical_checked += 1
            has_json = any(
                not _is_translation_path(p.relative_to(source_root).parts)
                for p in dir_path.rglob("*.json")
            )
            if not has_json:
                empty_count += 1
                rel = dir_path.relative_to(source_root).as_posix()
                findings.append({
                    "code": RULE_EMPTY_CANONICAL_DIR,
                    "severity": "error",
                    "path": str(dir_path),
                    "relativePath": rel,
                    "familyId": None,
                    "message": f"Empty canonical source directory contains no family JSON files: {rel}",
                })
    return canonical_checked, empty_count


def check_family_hygiene_inline(
    family_id: str | None,
    *,
    has_flow_graph: bool | None = None,
    variants: list[Any] | None = None,
    variant_threshold: int = DEFAULT_VARIANT_THRESHOLD,
) -> dict[str, Any]:
    """Return bounded inline hygiene badge and warnings for a single family/pool."""

    fid = family_id.strip() if isinstance(family_id, str) else ""
    if not fid:
        return {
            "badge": "UNKNOWN",
            "warningCount": 0,
            "warnings": [],
        }

    warnings: list[dict[str, Any]] = []
    actor_reason = _check_actor_or_direction_id(fid)
    if actor_reason is not None:
        warnings.append({
            "code": RULE_ACTOR_OR_DIRECTION,
            "severity": "warning",
            "familyId": fid,
            "message": f"Actor/direction-encoded family id {fid!r} ({actor_reason})",
        })

    style_token = _check_style_or_tier_id(fid)
    if style_token is not None:
        warnings.append({
            "code": RULE_STYLE_OR_TIER_SPLIT,
            "severity": "warning",
            "familyId": fid,
            "matchedToken": style_token,
            "message": (
                f"Style/tier token {style_token!r} split into family id {fid!r} "
                "instead of variants/realizations"
            ),
        })

    if fid.lower().startswith("flow.") and has_flow_graph is False:
        warnings.append({
            "code": RULE_MISLEADING_FLOW,
            "severity": "warning",
            "familyId": fid,
            "message": f"flow.* family id {fid!r} has no non-empty flow/nodes graph",
        })

    if isinstance(variants, list) and variants:
        count = len(variants)
        heterogeneous = _pool_heterogeneous_intents(variants)
        reasons: list[str] = []
        if count >= variant_threshold:
            reasons.append(f"variantCount={count} >= threshold={variant_threshold}")
        if heterogeneous:
            reasons.append(f"heterogeneousIntents={heterogeneous}")
        if reasons:
            warnings.append({
                "code": RULE_OVERPACKED_VARIANT_POOL,
                "severity": "warning",
                "familyId": fid,
                "variantCount": count,
                "threshold": variant_threshold,
                "distinctIntents": heterogeneous,
                "message": f"Overpacked variant pool ({'; '.join(reasons)})",
            })

    return {
        "badge": "CLEAN" if not warnings else f"WARN ({len(warnings)})",
        "warningCount": len(warnings),
        "warnings": warnings,
    }


def _audit_family_document(
    doc: Mapping[str, Any],
    *,
    file_path: Path,
    rel_path: str,
    variant_threshold: int,
    findings: list[dict[str, Any]],
) -> None:
    family_id = doc.get("id")
    if isinstance(family_id, str) and family_id.strip():
        fid = family_id.strip()
        actor_reason = _check_actor_or_direction_id(fid)
        if actor_reason is not None:
            findings.append({
                "code": RULE_ACTOR_OR_DIRECTION,
                "severity": "error",
                "path": str(file_path),
                "relativePath": rel_path,
                "familyId": fid,
                "message": f"{rel_path} uses actor/speaker-direction-encoded family id {fid!r} ({actor_reason})",
            })

        style_token = _check_style_or_tier_id(fid)
        if style_token is not None:
            findings.append({
                "code": RULE_STYLE_OR_TIER_SPLIT,
                "severity": "error",
                "path": str(file_path),
                "relativePath": rel_path,
                "familyId": fid,
                "matchedToken": style_token,
                "message": (
                    f"{rel_path} splits style/personality/relationship tier {style_token!r} "
                    f"into family id {fid!r} instead of variants/realizations"
                ),
            })

        if fid.lower().startswith("flow.") and not _has_flow_graph(doc):
            findings.append({
                "code": RULE_MISLEADING_FLOW,
                "severity": "error",
                "path": str(file_path),
                "relativePath": rel_path,
                "familyId": fid,
                "message": f"{rel_path} uses flow.* family id {fid!r} without a non-empty flow/nodes graph",
            })
    else:
        fid = None

    for pool_path, variants in _iter_variant_pools(doc):
        count = len(variants)
        heterogeneous = _pool_heterogeneous_intents(variants)
        reasons: list[str] = []
        if count >= variant_threshold:
            reasons.append(f"variantCount={count} >= threshold={variant_threshold}")
        if heterogeneous:
            reasons.append(f"heterogeneousIntents={heterogeneous}")
        if reasons:
            findings.append({
                "code": RULE_OVERPACKED_VARIANT_POOL,
                "severity": "error",
                "path": str(file_path),
                "relativePath": rel_path,
                "familyId": fid,
                "poolPath": pool_path,
                "variantCount": count,
                "threshold": variant_threshold,
                "distinctIntents": heterogeneous,
                "message": f"{rel_path} has overpacked variant pool at {pool_path!r} ({'; '.join(reasons)})",
            })


def _extract_placeholders(text: str) -> set[str]:
    return {f"{{{m}}}" for m in _PLACEHOLDER_TOKEN_RE.findall(text)}


def _coerce_lines(value: Any) -> list[str]:
    if isinstance(value, str):
        return [value]
    if isinstance(value, list):
        return [item for item in value if isinstance(item, str)]
    return []


def _when_text(when_val: Any) -> str:
    if isinstance(when_val, str):
        return when_val
    if isinstance(when_val, (Mapping, list)):
        return json.dumps(when_val, ensure_ascii=False)
    return ""


def _resolve_domain(doc: Mapping[str, Any] | None, rel_path: str) -> str:
    if isinstance(doc, Mapping):
        domains = doc.get("domains")
        if isinstance(domains, list):
            for entry in domains:
                if isinstance(entry, Mapping):
                    dom = entry.get("domain")
                    if isinstance(dom, str) and dom.strip():
                        return dom.strip()
        meta = doc.get("metadata")
        if isinstance(meta, Mapping):
            ui = meta.get("ui")
            if isinstance(ui, Mapping):
                dom = ui.get("domain")
                if isinstance(dom, str) and dom.strip():
                    return dom.strip()
    parts = [p for p in Path(rel_path).parts if p]
    if len(parts) >= 2 and parts[0] in CONVO_FAMILY_SUBDIRS:
        return parts[1]
    if parts:
        return parts[0]
    return "unknown"


def _empty_domain_bucket() -> dict[str, Any]:
    return {
        "totalVariants": 0,
        "variantsWithDynamicTokens": 0,
        "tokens": {bucket: 0 for bucket in _COVERAGE_TOKEN_BUCKETS},
        "exactTokens": {},
    }


def _record_coverage(
    by_domain: dict[str, dict[str, Any]],
    totals: dict[str, Any],
    domain: str,
    tokens: set[str],
) -> None:
    dom_bucket = by_domain.setdefault(domain, _empty_domain_bucket())
    for target in (dom_bucket, totals):
        target["totalVariants"] += 1
        if tokens:
            target["variantsWithDynamicTokens"] += 1
        for tok in sorted(tokens):
            target["exactTokens"][tok] = target["exactTokens"].get(tok, 0) + 1
            if tok.startswith("{slot."):
                target["tokens"]["{slot.*}"] += 1
            elif tok in target["tokens"]:
                target["tokens"][tok] += 1


def _variant_metadata_map(doc: Mapping[str, Any]) -> dict[str, Mapping[str, Any]]:
    meta: dict[str, Mapping[str, Any]] = {}
    for pool_path, variants in _iter_variant_pools(doc):
        for idx, var in enumerate(variants):
            if not isinstance(var, Mapping):
                continue
            vid = str(var.get("id") or f"idx_{idx}").strip()
            meta[f"{pool_path}.{vid}"] = var
            meta.setdefault(vid, var)
    return meta


def _variant_stranger_and_acquaintance(
    *,
    variant_id: str,
    variant_meta: Mapping[str, Any] | None,
    family_id: str,
    rel_path: str,
    family_when: Any,
) -> tuple[bool, bool]:
    tags: list[str] = []
    when_str = _when_text(family_when)
    if isinstance(variant_meta, Mapping):
        raw_tags = variant_meta.get("tags")
        if isinstance(raw_tags, list):
            tags = [str(t) for t in raw_tags]
        var_when = _when_text(variant_meta.get("when") or variant_meta.get("condition"))
        if var_when:
            when_str = f"{when_str} {var_when}".strip()

    has_acquaintance = bool(
        _BOND_PREFIX_RE.match(variant_id)
        or any(_BOND_PREFIX_RE.match(t) for t in tags)
        or _ACQUAINTANCE_COND_RE.search(when_str)
    )
    marked_stranger = bool(
        _STRANGER_VARIANT_RE.search(variant_id)
        or any(_STRANGER_VARIANT_RE.search(t) for t in tags)
        or _STRANGER_VARIANT_RE.search(when_str)
        or _STRANGER_FAMILY_RE.search(family_id)
        or _STRANGER_FAMILY_RE.search(rel_path)
    )
    return marked_stranger, has_acquaintance


def _check_en_tl_parity(
    *,
    en_lines: list[str],
    tl_lines: list[str],
    file_path: Path,
    rel_path: str,
    family_id: str | None,
    entry_key: str,
    domain: str,
    findings: list[dict[str, Any]],
) -> None:
    if len(en_lines) == len(tl_lines) and len(en_lines) > 0:
        for idx, (en_line, tl_line) in enumerate(zip(en_lines, tl_lines)):
            en_set = _extract_placeholders(en_line)
            tl_set = _extract_placeholders(tl_line)
            if en_set != tl_set:
                findings.append({
                    "code": RULE_EN_TL_PLACEHOLDER_MISMATCH,
                    "severity": "error",
                    "path": str(file_path),
                    "relativePath": rel_path,
                    "familyId": family_id,
                    "entryKey": entry_key,
                    "lineIndex": idx,
                    "domain": domain,
                    "enPlaceholders": sorted(en_set),
                    "tlPlaceholders": sorted(tl_set),
                    "message": (
                        f"{rel_path} [{entry_key}#{idx}] EN/TL placeholder mismatch: "
                        f"EN={sorted(en_set)} vs TL={sorted(tl_set)}"
                    ),
                })
        return

    en_union = {tok for line in en_lines for tok in _extract_placeholders(line)}
    tl_union = {tok for line in tl_lines for tok in _extract_placeholders(line)}
    if en_union != tl_union:
        findings.append({
            "code": RULE_EN_TL_PLACEHOLDER_MISMATCH,
            "severity": "error",
            "path": str(file_path),
            "relativePath": rel_path,
            "familyId": family_id,
            "entryKey": entry_key,
            "domain": domain,
            "enPlaceholders": sorted(en_union),
            "tlPlaceholders": sorted(tl_union),
            "message": (
                f"{rel_path} [{entry_key}] EN/TL placeholder mismatch: "
                f"EN={sorted(en_union)} vs TL={sorted(tl_union)}"
            ),
        })


def _collect_inline_locale_maps(
    node: Any,
    prefix: str = "",
) -> Iterable[tuple[str, Mapping[str, Any]]]:
    if isinstance(node, Mapping):
        if "EN" in node or "TL" in node:
            yield prefix or "root", node
            return
        for key, val in node.items():
            child_prefix = f"{prefix}.{key}" if prefix else str(key)
            yield from _collect_inline_locale_maps(val, child_prefix)
    elif isinstance(node, list):
        for idx, item in enumerate(node):
            yield from _collect_inline_locale_maps(item, f"{prefix}[{idx}]")


def dynamic_token_audit(
    source_roots: str | Path | Iterable[str | Path],
) -> dict[str, Any]:
    """Audit canonical ConvoEngine dialogue and translation sources for dynamic-token safety."""
    if isinstance(source_roots, (str, Path)):
        raw_roots = [source_roots]
    else:
        raw_roots = list(source_roots)
    resolved_roots = [Path(r).expanduser().resolve() for r in raw_roots]

    findings: list[dict[str, Any]] = []
    by_domain: dict[str, dict[str, Any]] = {}
    totals = _empty_domain_bucket()

    family_files_checked = 0
    translation_pairs_checked = 0
    variants_checked = 0

    for source_root in resolved_roots:
        if not source_root.is_dir():
            continue

        family_docs_by_rel: dict[str, tuple[Path, Mapping[str, Any]]] = {}
        for subdir_name in CONVO_FAMILY_SUBDIRS:
            subdir = source_root / subdir_name
            if not subdir.is_dir():
                continue
            for file_path in sorted(subdir.rglob("*.json")):
                rel_parts = file_path.relative_to(source_root).parts
                if _is_translation_path(rel_parts):
                    continue
                family_files_checked += 1
                rel_path = file_path.relative_to(source_root).as_posix()
                try:
                    doc = json.loads(file_path.read_text(encoding="utf-8"))
                except (OSError, json.JSONDecodeError):
                    continue
                if isinstance(doc, Mapping):
                    family_docs_by_rel[rel_path] = (file_path, doc)

        seen_translation_rels: set[str] = set()

        # 1. Inspect family docs + matched canonical translation files
        for rel_path, (file_path, doc) in sorted(family_docs_by_rel.items()):
            family_id = str(doc.get("id") or "").strip() or None
            domain = _resolve_domain(doc, rel_path)
            family_when = doc.get("when")
            var_meta_map = _variant_metadata_map(doc)

            # Inline translations / text maps inside family doc
            inline_hits = list(_collect_inline_locale_maps(doc))
            for inline_path, locale_map in inline_hits:
                en_lines = _coerce_lines(locale_map.get("EN"))
                tl_lines = _coerce_lines(locale_map.get("TL"))
                if en_lines and tl_lines:
                    translation_pairs_checked += 1
                    _check_en_tl_parity(
                        en_lines=en_lines,
                        tl_lines=tl_lines,
                        file_path=file_path,
                        rel_path=rel_path,
                        family_id=family_id,
                        entry_key=inline_path,
                        domain=domain,
                        findings=findings,
                    )

            # Inline variants (string say/text or inline locale map) when no external canonical translations exist
            en_path = source_root / "translations" / "EN" / rel_path
            tl_path = source_root / "translations" / "TL" / rel_path
            has_external = en_path.is_file() or tl_path.is_file()

            if not has_external:
                for pool_path, variants in _iter_variant_pools(doc):
                    for idx, var in enumerate(variants):
                        if not isinstance(var, Mapping):
                            continue
                        vid = str(var.get("id") or f"v{idx}").strip()
                        texts: list[str] = []
                        for field_name in ("say", "text", "fallback", "reply", "respond"):
                            val = var.get(field_name)
                            if isinstance(val, str):
                                texts.append(val)
                            elif isinstance(val, list):
                                texts.extend(_coerce_lines(val))
                            elif isinstance(val, Mapping):
                                for loc_val in val.values():
                                    texts.extend(_coerce_lines(loc_val))
                        tr_map = var.get("translations")
                        if isinstance(tr_map, Mapping):
                            for loc_val in tr_map.values():
                                texts.extend(_coerce_lines(loc_val))
                        if not texts:
                            continue
                        variants_checked += 1
                        toks = {tok for t in texts for tok in _extract_placeholders(t)}
                        _record_coverage(by_domain, totals, domain, toks)
                        marked_stranger, has_acquaintance = _variant_stranger_and_acquaintance(
                            variant_id=vid,
                            variant_meta=var,
                            family_id=family_id or "",
                            rel_path=rel_path,
                            family_when=family_when,
                        )
                        if marked_stranger and not has_acquaintance and "{addressee.name}" in toks:
                            findings.append({
                                "code": RULE_UNCONDITIONAL_STRANGER_NAME,
                                "severity": "error",
                                "path": str(file_path),
                                "relativePath": rel_path,
                                "familyId": family_id,
                                "variantId": vid,
                                "poolPath": pool_path,
                                "domain": domain,
                                "message": (
                                    f"{rel_path} variant {vid!r} is marked stranger/unknown/first_contact/hostile "
                                    "without an acquaintance condition yet uses '{addressee.name}'"
                                ),
                            })

        # 2. Inspect all canonical translation files under translations/EN & translations/TL
        translations_root = source_root / "translations"
        if translations_root.is_dir():
            en_dir = translations_root / "EN"
            tl_dir = translations_root / "TL"
            rel_candidates: set[str] = set()
            for loc_dir in (en_dir, tl_dir):
                if loc_dir.is_dir():
                    for p in loc_dir.rglob("*.json"):
                        rel_candidates.add(p.relative_to(loc_dir).as_posix())

            for rel_path in sorted(rel_candidates):
                if rel_path in seen_translation_rels:
                    continue
                seen_translation_rels.add(rel_path)

                en_file = en_dir / rel_path
                tl_file = tl_dir / rel_path
                en_doc: Mapping[str, Any] | None = None
                tl_doc: Mapping[str, Any] | None = None
                if en_file.is_file():
                    try:
                        parsed = json.loads(en_file.read_text(encoding="utf-8"))
                        if isinstance(parsed, Mapping):
                            en_doc = parsed
                    except (OSError, json.JSONDecodeError):
                        en_doc = None
                if tl_file.is_file():
                    try:
                        parsed = json.loads(tl_file.read_text(encoding="utf-8"))
                        if isinstance(parsed, Mapping):
                            tl_doc = parsed
                    except (OSError, json.JSONDecodeError):
                        tl_doc = None

                en_entries = en_doc.get("entries") if isinstance(en_doc, Mapping) and isinstance(en_doc.get("entries"), Mapping) else {}
                tl_entries = tl_doc.get("entries") if isinstance(tl_doc, Mapping) and isinstance(tl_doc.get("entries"), Mapping) else {}

                fam_pair = family_docs_by_rel.get(rel_path)
                fam_path = fam_pair[0] if fam_pair else (en_file if en_file.is_file() else tl_file)
                fam_doc = fam_pair[1] if fam_pair else None
                family_id = (
                    (str(fam_doc.get("id") or "").strip() if fam_doc else "")
                    or (str((en_doc or {}).get("family") or "").strip())
                    or (str((tl_doc or {}).get("family") or "").strip())
                    or None
                )
                domain = _resolve_domain(fam_doc, rel_path)
                family_when = fam_doc.get("when") if fam_doc else None
                var_meta_map = _variant_metadata_map(fam_doc) if fam_doc else {}

                all_keys = sorted(set(en_entries.keys()) | set(tl_entries.keys()))
                for entry_key in all_keys:
                    en_lines = _coerce_lines(en_entries.get(entry_key))
                    tl_lines = _coerce_lines(tl_entries.get(entry_key))
                    if entry_key in en_entries and entry_key in tl_entries:
                        translation_pairs_checked += 1
                        _check_en_tl_parity(
                            en_lines=en_lines,
                            tl_lines=tl_lines,
                            file_path=en_file,
                            rel_path=f"translations/EN/{rel_path}",
                            family_id=family_id,
                            entry_key=entry_key,
                            domain=domain,
                            findings=findings,
                        )

                    all_lines = en_lines + tl_lines
                    if not all_lines:
                        continue
                    variants_checked += 1
                    toks = {tok for line in all_lines for tok in _extract_placeholders(line)}
                    _record_coverage(by_domain, totals, domain, toks)

                    vid = entry_key.rsplit(".", 1)[-1] if "." in entry_key else entry_key
                    var_meta = var_meta_map.get(entry_key) or var_meta_map.get(vid)
                    marked_stranger, has_acquaintance = _variant_stranger_and_acquaintance(
                        variant_id=vid,
                        variant_meta=var_meta,
                        family_id=family_id or "",
                        rel_path=rel_path,
                        family_when=family_when,
                    )
                    if marked_stranger and not has_acquaintance and "{addressee.name}" in toks:
                        findings.append({
                            "code": RULE_UNCONDITIONAL_STRANGER_NAME,
                            "severity": "error",
                            "path": str(fam_path),
                            "relativePath": rel_path,
                            "familyId": family_id,
                            "variantId": vid,
                            "entryKey": entry_key,
                            "domain": domain,
                            "message": (
                                f"{rel_path} [{entry_key}] is marked stranger/unknown/first_contact/hostile "
                                "without an acquaintance condition yet uses '{addressee.name}'"
                            ),
                        })

    findings.sort(
        key=lambda item: (
            str(item.get("code") or ""),
            str(item.get("path") or ""),
            str(item.get("entryKey") or item.get("variantId") or ""),
        )
    )
    by_rule = {rule: 0 for rule in ALL_DYNAMIC_TOKEN_RULES}
    for item in findings:
        code = str(item.get("code") or "")
        if code in by_rule:
            by_rule[code] += 1

    coverage_summary = {
        "byDomain": {dom: by_domain[dom] for dom in sorted(by_domain)},
        "totals": totals,
    }

    return {
        "ok": len(findings) == 0,
        "schema": DYNAMIC_TOKEN_AUDIT_SCHEMA,
        "sourceRoots": [str(r) for r in resolved_roots],
        "stats": {
            "familyFilesChecked": family_files_checked,
            "translationPairsChecked": translation_pairs_checked,
            "variantsChecked": variants_checked,
            "findingCount": len(findings),
            "byRule": by_rule,
        },
        "dynamic_coverage_summary": coverage_summary,
        "findings": findings,
    }


def audit_convo_engine_family_hygiene(
    source_roots: str | Path | Iterable[str | Path],
    *,
    variant_threshold: int = DEFAULT_VARIANT_THRESHOLD,
    include_dynamic_audit: bool = False,
) -> dict[str, Any]:
    """Audit one or more ConvoEngine source trees for family hygiene violations."""
    if variant_threshold < 1:
        raise ValueError(f"variant_threshold must be >= 1, got {variant_threshold}")

    if isinstance(source_roots, (str, Path)):
        raw_roots = [source_roots]
    else:
        raw_roots = list(source_roots)
    resolved_roots = [Path(r).expanduser().resolve() for r in raw_roots]

    findings: list[dict[str, Any]] = []
    family_files_checked = 0
    canonical_dirs_checked = 0
    empty_canonical_dirs = 0

    for source_root in resolved_roots:
        if not source_root.is_dir():
            findings.append({
                "code": RULE_EMPTY_CANONICAL_DIR,
                "severity": "error",
                "path": str(source_root),
                "relativePath": ".",
                "familyId": None,
                "message": f"Conversation source root does not exist: {source_root}",
            })
            continue

        dirs_checked, empty_found = _check_empty_canonical_dirs(source_root, findings)
        canonical_dirs_checked += dirs_checked
        empty_canonical_dirs += empty_found

        for subdir_name in CONVO_FAMILY_SUBDIRS:
            subdir = source_root / subdir_name
            if not subdir.is_dir():
                continue
            for file_path in sorted(subdir.rglob("*.json")):
                rel_parts = file_path.relative_to(source_root).parts
                if _is_translation_path(rel_parts):
                    continue
                family_files_checked += 1
                rel_path = file_path.relative_to(source_root).as_posix()
                try:
                    doc = json.loads(file_path.read_text(encoding="utf-8"))
                except (OSError, json.JSONDecodeError):
                    continue
                if not isinstance(doc, Mapping):
                    continue
                _audit_family_document(
                    doc,
                    file_path=file_path,
                    rel_path=rel_path,
                    variant_threshold=variant_threshold,
                    findings=findings,
                )

    findings.sort(
        key=lambda item: (
            str(item.get("code") or ""),
            str(item.get("path") or ""),
            str(item.get("poolPath") or ""),
            str(item.get("familyId") or ""),
        )
    )

    by_rule = {rule: 0 for rule in ALL_HYGIENE_RULES}
    for item in findings:
        code = str(item.get("code") or "")
        if code in by_rule:
            by_rule[code] += 1

    result: dict[str, Any] = {
        "ok": len(findings) == 0,
        "schema": HYGIENE_AUDIT_SCHEMA,
        "sourceRoots": [str(r) for r in resolved_roots],
        "variantThreshold": variant_threshold,
        "stats": {
            "familyFilesChecked": family_files_checked,
            "canonicalDirsChecked": canonical_dirs_checked,
            "emptyCanonicalDirs": empty_canonical_dirs,
            "findingCount": len(findings),
            "byRule": by_rule,
        },
        "findings": findings,
    }
    if include_dynamic_audit:
        dyn_report = dynamic_token_audit(resolved_roots)
        result["dynamicAudit"] = dyn_report
        result["ok"] = result["ok"] and dyn_report["ok"]
    return result


def _parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "source_roots",
        nargs="+",
        type=Path,
        help="One or more ConvoEngine conversation source root directories",
    )
    parser.add_argument(
        "--variant-threshold",
        type=int,
        default=DEFAULT_VARIANT_THRESHOLD,
        help=f"Flag variant pools with >= N variants (default: {DEFAULT_VARIANT_THRESHOLD})",
    )
    parser.add_argument(
        "--dynamic-audit",
        action="store_true",
        help="Include static dynamic-token / EN-TL parity / stranger-name audit",
    )
    parser.add_argument(
        "--summary",
        action="store_true",
        help="Print summary stats only without full findings list",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(argv)
    result = audit_convo_engine_family_hygiene(
        args.source_roots,
        variant_threshold=args.variant_threshold,
        include_dynamic_audit=bool(args.dynamic_audit),
    )
    if args.summary:
        output = {
            "ok": result["ok"],
            "schema": result["schema"],
            "sourceRoots": result["sourceRoots"],
            "variantThreshold": result["variantThreshold"],
            "stats": result["stats"],
        }
        if "dynamicAudit" in result:
            dyn = result["dynamicAudit"]
            output["dynamicAudit"] = {
                "ok": dyn["ok"],
                "schema": dyn["schema"],
                "stats": dyn["stats"],
                "dynamic_coverage_summary": dyn["dynamic_coverage_summary"],
            }
    else:
        output = result
    print(json.dumps(output, ensure_ascii=False, indent=2))
    return 0 if result["ok"] else 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
