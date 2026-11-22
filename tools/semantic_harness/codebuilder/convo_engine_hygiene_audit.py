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
DEFAULT_VARIANT_THRESHOLD = 12

RULE_ACTOR_OR_DIRECTION = "actor_or_direction_encoded_family_id"
RULE_STYLE_OR_TIER_SPLIT = "style_or_tier_split_family_id"
RULE_MISLEADING_FLOW = "misleading_flow_family_id"
RULE_OVERPACKED_VARIANT_POOL = "overpacked_variant_pool"
RULE_EMPTY_CANONICAL_DIR = "empty_canonical_source_dir"

ALL_HYGIENE_RULES = (
    RULE_ACTOR_OR_DIRECTION,
    RULE_STYLE_OR_TIER_SPLIT,
    RULE_MISLEADING_FLOW,
    RULE_OVERPACKED_VARIANT_POOL,
    RULE_EMPTY_CANONICAL_DIR,
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


def audit_convo_engine_family_hygiene(
    source_roots: str | Path | Iterable[str | Path],
    *,
    variant_threshold: int = DEFAULT_VARIANT_THRESHOLD,
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

    return {
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
    )
    if args.summary:
        output = {
            "ok": result["ok"],
            "schema": result["schema"],
            "sourceRoots": result["sourceRoots"],
            "variantThreshold": result["variantThreshold"],
            "stats": result["stats"],
        }
    else:
        output = result
    print(json.dumps(output, ensure_ascii=False, indent=2))
    return 0 if result["ok"] else 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
