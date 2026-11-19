"""Fail-closed ConvoEngine localization and physical-layout audit."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any, Mapping

from .convo_engine_compiler import CONVO_ENGINE_SCHEMA
from .generation_ownership import (
    CORE_OWNER,
    DT_COMMON_OWNER,
    HOOMANS_OWNER,
    generated_conversation_root,
    translation_root,
)
from .workspace_catalog import WorkspaceCatalog


CONVO_TRANSLATION_SCHEMA = "psychopatz.convo-engine.translation.v1"
CONVO_FAMILY_SUBDIRS = ("dialogue", "behavior", "beat", "realization")
LOCALE_CODE_RE = re.compile(r"^[A-Z]{2,5}(?:_[A-Z0-9]{2,5})?$")
_NON_LOCALE_DICT_KEYS = frozenset({
    "variants", "realizations", "say", "reply", "response", "turns", "offers",
    "metadata", "affordance", "invoke", "when", "after", "roles", "slots",
    "references", "domains", "topics", "events", "activities", "memories",
    "candidates", "outputs", "effects", "frame", "payload", "playerChoice",
    "textRows", "textSidecars", "textTarget", "textDomain", "textKey",
    "id", "schema", "kind", "namespace", "owner", "profile", "type",
    "strategy", "dialogueAct", "concept", "aliases", "tokens", "plan",
    "segments", "labelKey", "utteranceKey", "choiceKey", "responseKey",
    "templateID", "translationKey",
})

_LUA_MULTI_LOCALE_PATTERNS = (
    re.compile(r'\["translations"\]\s*=\s*\{'),
    re.compile(r'\["display"\]\s*=\s*\{'),
    re.compile(r'\["forms"\]\s*=\s*\{'),
    re.compile(r'\["text"\]\s*=\s*\{[^}]*\["EN"\]'),
    re.compile(r'\["locale"\]\s*=\s*"(?!EN")[A-Z]{2,5}"'),
)
_LUA_LOCALE_ARRAY_RE = re.compile(r'\["([A-Z]{2,5})"\]\s*=\s*(?:\{|")')


def is_locale_map(value: Any) -> bool:
    """Return True if value looks like a mapping keyed by locale codes (e.g. EN/TL)."""
    if not isinstance(value, Mapping) or not value:
        return False
    keys = [str(k) for k in value.keys()]
    if any(k in _NON_LOCALE_DICT_KEYS for k in keys):
        return False
    return "EN" in keys or all(LOCALE_CODE_RE.match(k) for k in keys)


def find_inline_locale_paths(node: Any, prefix: str = "") -> list[str]:
    """Recursively find all field paths inside a semantic family doc carrying inline locale maps."""
    hits: list[str] = []
    if isinstance(node, Mapping):
        if is_locale_map(node):
            hits.append(prefix or "<root>")
            return hits
        for key, value in node.items():
            key_str = str(key)
            if key_str == "textSidecars":
                continue
            child_prefix = f"{prefix}.{key_str}" if prefix else key_str
            hits.extend(find_inline_locale_paths(value, child_prefix))
    elif isinstance(node, list):
        for idx, item in enumerate(node):
            child_prefix = f"{prefix}[{idx}]"
            hits.extend(find_inline_locale_paths(item, child_prefix))
    return hits


def deterministic_translation_path(
    source_root: Path,
    family_path: Path,
    locale: str,
) -> Path:
    """Return canonical translation path: <source_root>/translations/<LOCALE>/<kind>/<domain>/<file>.json."""
    rel = family_path.resolve().relative_to(source_root.resolve())
    return source_root.resolve() / "translations" / str(locale).upper() / rel


def discover_canonical_translation_files(
    source_root: Path,
    family_path: Path,
) -> dict[str, Path]:
    """Return {LOCALE: path} for all deterministic translation files matching family_path."""
    translations_dir = source_root.resolve() / "translations"
    if not translations_dir.is_dir():
        return {}
    rel = family_path.resolve().relative_to(source_root.resolve())
    found: dict[str, Path] = {}
    for locale_dir in sorted(translations_dir.iterdir()):
        if not locale_dir.is_dir():
            continue
        locale = locale_dir.name.upper()
        if not LOCALE_CODE_RE.match(locale):
            continue
        candidate = locale_dir / rel
        if candidate.is_file():
            found[locale] = candidate
    return found


def classify_family_localization(
    doc: Mapping[str, Any],
    family_path: Path,
    source_root: Path,
) -> dict[str, Any]:
    """Classify a ConvoEngine family's current localization shape."""
    inline_paths = find_inline_locale_paths(doc)
    has_inline = bool(inline_paths)
    has_sidecars = "textSidecars" in doc and bool(doc.get("textSidecars"))
    metadata = doc.get("metadata") if isinstance(doc.get("metadata"), Mapping) else {}
    has_text_target = isinstance(metadata.get("textTarget"), str) and bool(metadata.get("textTarget", "").strip())
    canonical_files = discover_canonical_translation_files(source_root, family_path)
    has_canonical = bool(canonical_files)

    if has_canonical and not has_inline and not has_sidecars:
        shape = "CANONICAL_EXTERNAL_TRANSLATION"
    elif has_canonical and (has_inline or has_sidecars):
        shape = "MULTIPLE_LEGACY_FORMS"
    elif has_sidecars and has_inline and has_text_target:
        shape = "MULTIPLE_LEGACY_FORMS"
    elif has_sidecars and has_inline:
        shape = "SIDECAR_PLUS_INLINE"
    elif has_sidecars and has_text_target:
        shape = "SIDECAR_PLUS_TARGET"
    elif has_text_target and has_inline:
        shape = "TARGET_PLUS_INLINE"
    elif has_sidecars:
        shape = "TEXT_SIDECARS_ONLY"
    elif has_text_target:
        shape = "TEXT_TARGET_ONLY"
    elif has_inline:
        shape = "INLINE_LOCALE_MAP"
    else:
        shape = "NO_LOCALIZED_TEXT"

    return {
        "shape": shape,
        "inlinePaths": inline_paths,
        "hasTextSidecars": has_sidecars,
        "hasTextTarget": has_text_target,
        "canonicalLocales": sorted(canonical_files.keys()),
    }


def _scan_generated_lua_multi_locale(conv_root: Path) -> list[dict[str, Any]]:
    hits: list[dict[str, Any]] = []
    if not conv_root.is_dir():
        return hits
    for lua_file in sorted(conv_root.rglob("*.lua")):
        try:
            text = lua_file.read_text(encoding="utf-8")
        except OSError:
            continue
        if "-- ConvoEngine: hand-written" in text:
            continue
        locales_found = sorted(set(_LUA_LOCALE_ARRAY_RE.findall(text)))
        has_multi_locale = len(locales_found) > 1 or any(
            pat.search(text) for pat in _LUA_MULTI_LOCALE_PATTERNS
        )
        if has_multi_locale:
            hits.append({
                "path": str(lua_file),
                "locales": locales_found,
            })
    return hits


def _audit_translation_trees(
    owner_repos: list[tuple[str, Path]],
    core_root: Path,
    dt_root: Path | None,
) -> dict[str, Any]:
    """Audit media/translation/<LOCALE>/Conversation across owners for cross-owner writes, duplicates, and EN parity."""
    cross_owner_writes: list[dict[str, Any]] = []
    missing_en: list[dict[str, Any]] = []
    duplicate_keys: list[dict[str, Any]] = []

    owner_foreign_prefixes = {
        CORE_OWNER: ("UI_DT_", "dt."),
        HOOMANS_OWNER: ("UI_DT_", "UI_Psychopatz", "dt."),
        DT_COMMON_OWNER: ("UI_PNC_", "UI_Psychopatz", "pnc.convo."),
    }
    ui_key_owners_seen: dict[str, str] = {}

    for owner, repo_root in owner_repos:
        t_root = translation_root(
            repo_root,
            owner,
            core_repository=core_root,
            dynamic_trading_repository=dt_root,
        )
        if not t_root.is_dir():
            continue
        en_conv = t_root / "EN" / "Conversation"
        en_keys_by_rel: dict[str, set[str]] = {}
        seen_ui_keys: dict[str, str] = {}

        if en_conv.is_dir():
            for jf in sorted(en_conv.rglob("*.json")):
                rel = str(jf.relative_to(en_conv))
                try:
                    data = json.loads(jf.read_text(encoding="utf-8"))
                except (OSError, json.JSONDecodeError):
                    continue
                if not isinstance(data, Mapping):
                    continue
                keys = set(str(k) for k in data.keys())
                en_keys_by_rel[rel] = keys
                for k in sorted(keys):
                    for foreign in owner_foreign_prefixes.get(owner, ()):
                        if k.startswith(foreign):
                            cross_owner_writes.append({
                                "owner": owner,
                                "path": str(jf),
                                "key": k,
                                "reason": f"Foreign prefix {foreign!r} in {owner}",
                            })
                    if rel == "UI.json":
                        if k in seen_ui_keys:
                            duplicate_keys.append({
                                "owner": owner,
                                "key": k,
                                "path": str(jf),
                            })
                        seen_ui_keys[k] = str(jf)
                        prev_owner = ui_key_owners_seen.get(k)
                        if prev_owner is not None and prev_owner != owner:
                            cross_owner_writes.append({
                                "owner": owner,
                                "path": str(jf),
                                "key": k,
                                "reason": f"UI key {k!r} duplicated across {prev_owner} and {owner}",
                            })
                        ui_key_owners_seen[k] = owner

        for locale_dir in sorted(t_root.iterdir()):
            if not locale_dir.is_dir() or locale_dir.name in {"EN", "manifests"}:
                continue
            loc_conv = locale_dir / "Conversation"
            if not loc_conv.is_dir():
                continue
            for jf in sorted(loc_conv.rglob("*.json")):
                rel = str(jf.relative_to(loc_conv))
                try:
                    data = json.loads(jf.read_text(encoding="utf-8"))
                except (OSError, json.JSONDecodeError):
                    continue
                if not isinstance(data, Mapping):
                    continue
                en_keys = en_keys_by_rel.get(rel, set())
                for k in sorted(data.keys()):
                    if str(k) not in en_keys:
                        missing_en.append({
                            "owner": owner,
                            "locale": locale_dir.name,
                            "path": str(jf),
                            "key": str(k),
                        })

    return {
        "crossOwnerTranslationWrites": cross_owner_writes,
        "translationKeyMissingEN": missing_en,
        "duplicateTranslationKeyCount": duplicate_keys,
    }


def audit_convo_engine_localization(
    core_repository: Path,
    *,
    hoomans_repository: Path | None = None,
    dynamic_trading_repository: Path | None = None,
) -> dict[str, Any]:
    """Run the full T2 fail-closed localization audit across all connected owners."""
    core_root = core_repository.expanduser().resolve()
    snapshot = WorkspaceCatalog.discover(
        core_root,
        core_repository=core_root,
        hoomans_repository=hoomans_repository,
        dynamic_trading_repository=dynamic_trading_repository,
        allow_sibling_discovery=False,
    )
    hoomans_root = (
        hoomans_repository.expanduser().resolve()
        if hoomans_repository is not None
        else snapshot.repositories_by_owner.get(HOOMANS_OWNER)
        if hasattr(snapshot, "repositories_by_owner")
        else None
    )
    dt_root = (
        dynamic_trading_repository.expanduser().resolve()
        if dynamic_trading_repository is not None
        else snapshot.repositories_by_owner.get(DT_COMMON_OWNER)
        if hasattr(snapshot, "repositories_by_owner")
        else None
    )
    runtime_base = hoomans_root or core_root

    source_roots = dict(snapshot.source_roots_by_owner)
    owner_repos: list[tuple[str, Path]] = [(CORE_OWNER, core_root)]
    if hoomans_root is not None:
        owner_repos.append((HOOMANS_OWNER, hoomans_root))
    if dt_root is not None:
        owner_repos.append((DT_COMMON_OWNER, dt_root))

    inline_families: list[dict[str, Any]] = []
    mixed_families: list[dict[str, Any]] = []
    legacy_sidecar_files: list[str] = []
    unknown_shapes: list[dict[str, Any]] = []
    orphan_canonical_translations: list[str] = []
    missing_en_canonical: list[dict[str, Any]] = []
    shape_counts: dict[str, int] = {}
    family_paths_seen: set[Path] = set()

    for owner, source_root in sorted(source_roots.items()):
        if not source_root.is_dir():
            continue
        for subdir_name in CONVO_FAMILY_SUBDIRS:
            subdir = source_root / subdir_name
            if not subdir.is_dir():
                continue
            for file_path in sorted(subdir.rglob("*.json")):
                rel_parts = file_path.relative_to(source_root).parts
                if "translations" in rel_parts:
                    legacy_sidecar_files.append(str(file_path))
                    continue
                family_paths_seen.add(file_path.resolve())
                try:
                    doc = json.loads(file_path.read_text(encoding="utf-8"))
                except (OSError, json.JSONDecodeError) as error:
                    unknown_shapes.append({
                        "owner": owner,
                        "path": str(file_path),
                        "error": str(error),
                    })
                    continue
                if not isinstance(doc, Mapping) or doc.get("schema") != CONVO_ENGINE_SCHEMA:
                    unknown_shapes.append({
                        "owner": owner,
                        "path": str(file_path),
                        "error": "Not a valid ConvoEngine v1 family object",
                    })
                    continue

                info = classify_family_localization(doc, file_path, source_root)
                shape = info["shape"]
                shape_counts[shape] = shape_counts.get(shape, 0) + 1

                if info["inlinePaths"]:
                    inline_families.append({
                        "owner": owner,
                        "id": doc.get("id"),
                        "path": str(file_path),
                        "shape": shape,
                        "inlinePaths": info["inlinePaths"],
                    })
                if shape in {"SIDECAR_PLUS_INLINE", "TARGET_PLUS_INLINE", "SIDECAR_PLUS_TARGET", "MULTIPLE_LEGACY_FORMS"}:
                    mixed_families.append({
                        "owner": owner,
                        "id": doc.get("id"),
                        "path": str(file_path),
                        "shape": shape,
                    })
                if info["hasTextSidecars"]:
                    for rel_sc in (doc.get("textSidecars") or {}).values():
                        sc_path = (file_path.parent / str(rel_sc)).resolve()
                        if str(sc_path) not in legacy_sidecar_files and sc_path.is_file():
                            legacy_sidecar_files.append(str(sc_path))

                canonical_files = discover_canonical_translation_files(source_root, file_path)
                if canonical_files and "EN" not in canonical_files:
                    missing_en_canonical.append({
                        "owner": owner,
                        "id": doc.get("id"),
                        "path": str(file_path),
                        "locales": sorted(canonical_files.keys()),
                    })

        # Check canonical translations/ directory for orphaned translation files
        translations_dir = source_root / "translations"
        if translations_dir.is_dir():
            for locale_dir in sorted(translations_dir.iterdir()):
                if not locale_dir.is_dir():
                    continue
                for tr_file in sorted(locale_dir.rglob("*.json")):
                    rel = tr_file.relative_to(locale_dir)
                    expected_family = (source_root / rel).resolve()
                    if expected_family not in family_paths_seen and not expected_family.is_file():
                        orphan_canonical_translations.append(str(tr_file))

    generated_lua_hits: list[dict[str, Any]] = []
    for owner, _repo_root in owner_repos:
        conv_root = generated_conversation_root(
            runtime_base,
            owner,
            core_repository=core_root,
            dynamic_trading_repository=dt_root,
            runtime_root=runtime_base,
        )
        generated_lua_hits.extend(_scan_generated_lua_multi_locale(conv_root))

    tree_audit = _audit_translation_trees(owner_repos, core_root, dt_root)

    counters = {
        "inlineLocaleCorpusInCanonicalFamilies": len(inline_families),
        "mixedLocalizationAuthoringFamilies": len(mixed_families),
        "legacyTextSidecarsPathCount": len(set(legacy_sidecar_files)),
        "generatedLuaMultiLocaleCorpusCount": len(generated_lua_hits),
        "crossOwnerTranslationWrites": len(tree_audit["crossOwnerTranslationWrites"]),
        "translationKeyMissingEN": len(tree_audit["translationKeyMissingEN"]) + len(missing_en_canonical),
        "orphanTranslationEntryCount": len(orphan_canonical_translations),
        "duplicateTranslationKeyCount": len(tree_audit["duplicateTranslationKeyCount"]),
        "unknownLocalizationShapeCount": len(unknown_shapes),
    }

    return {
        "schema": "psychopatz.convo-engine.localization-audit.v1",
        "ok": all(v == 0 for v in counters.values()),
        "counters": counters,
        "shapeCounts": shape_counts,
        "details": {
            "inlineFamilies": inline_families,
            "mixedFamilies": mixed_families,
            "legacySidecarFiles": sorted(set(legacy_sidecar_files)),
            "generatedLuaMultiLocaleFiles": generated_lua_hits,
            "crossOwnerTranslationWrites": tree_audit["crossOwnerTranslationWrites"],
            "translationKeyMissingEN": tree_audit["translationKeyMissingEN"] + missing_en_canonical,
            "orphanCanonicalTranslations": orphan_canonical_translations,
            "duplicateTranslationKeys": tree_audit["duplicateTranslationKeyCount"],
            "unknownShapes": unknown_shapes,
        },
    }


__all__ = [
    "CONVO_TRANSLATION_SCHEMA",
    "audit_convo_engine_localization",
    "classify_family_localization",
    "deterministic_translation_path",
    "discover_canonical_translation_files",
    "find_inline_locale_paths",
    "is_locale_map",
]
