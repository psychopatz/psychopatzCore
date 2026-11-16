"""Corpus dialogue variation auditor and classification ledger.

Audits every canonical conversation phrase family/style for phrase count,
EN/TL uniqueness, placeholder parity, duplicates, near-duplicates,
English-identical TL entries, Quality Sweep reachability, and migration
classification.
"""

from __future__ import annotations

import json
import re
import string
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Iterable

from .conversation_compiler import CONVERSATION_MANIFEST_RELATIVE
from .conversation_manifest import load_manifest as _load_manifest
from .convo_engine_integrity_audit import discover_convo_engine_repositories
from .generation_ownership import CORE_OWNER


PLACEHOLDER_REGEX = re.compile(r"\{([a-zA-Z0-9_]+)\}")
PUNCT_TABLE = str.maketrans("", "", string.punctuation)

CLASSIFICATION_EXPAND = "EXPAND_TO_10"
CLASSIFICATION_ATOMIC_EXEMPT = "ATOMIC_EXEMPT"
CLASSIFICATION_STRUCTURAL = "STRUCTURAL_NOT_PHRASE"
CLASSIFICATION_THIRD_PARTY = "THIRD_PARTY_COMPAT_DEFERRED"
CLASSIFICATION_PLAYER_UI = "PLAYER_UI_OUT_OF_SCOPE"

ALL_CLASSIFICATIONS = (
    CLASSIFICATION_EXPAND,
    CLASSIFICATION_ATOMIC_EXEMPT,
    CLASSIFICATION_STRUCTURAL,
    CLASSIFICATION_THIRD_PARTY,
    CLASSIFICATION_PLAYER_UI,
)


def normalize_exact(text: str) -> str:
    """Lowercase and normalize whitespace."""
    return " ".join(text.strip().lower().split())


def normalize_near(text: str) -> str:
    """Normalize removing punctuation and whitespace for near-duplicate checks."""
    cleaned = text.lower().translate(PUNCT_TABLE)
    return " ".join(cleaned.split())


def extract_placeholders(text: str) -> list[str]:
    """Extract sorted placeholder names from a string."""
    return sorted(set(PLACEHOLDER_REGEX.findall(text)))


def classify_style(
    source_shard: str,
    semantic_template_id: str,
    style: str,
    phrases: list[dict[str, Any]],
) -> tuple[str, str]:
    """Assign an explicit migration classification with a concrete reason."""
    if source_shard == "content/compatibility.json" or semantic_template_id.startswith("semantic.compat."):
        return (
            CLASSIFICATION_THIRD_PARTY,
            "Third-party mod compatibility (Bandits/Companion Dogs/Necroa) fallback phrases",
        )
    if source_shard in ("content/command/player.json", "content/social/emotes/player.json") or (
        semantic_template_id.startswith("semantic.command.player.")
        or semantic_template_id.startswith("semantic.emote.player.")
    ):
        return (
            CLASSIFICATION_PLAYER_UI,
            "Player avatar spoken command/emote callout directed at NPCs, not NPC dialogue",
        )
    return (
        CLASSIFICATION_EXPAND,
        "Active canonical NPC spoken dialogue required to reach minimum 10 variants",
    )


@dataclass
class StyleAuditRecord:
    source_shard: str
    semantic_template_id: str
    family_id: str
    style: str
    phrase_count: int
    unique_normalized_en_count: int
    unique_normalized_tl_count: int
    en_phrases: list[str]
    tl_phrases: list[str]
    placeholder_signatures_en: list[list[str]]
    placeholder_signatures_tl: list[list[str]]
    placeholder_parity: bool
    duplicate_candidates: list[str]
    near_duplicate_candidates: list[str]
    suspicious_en_identical_tl: list[str]
    source_owner: str
    classification: str
    classification_reason: str
    sweep_observations: int = 0
    sweep_distinct_phrases: list[str] = field(default_factory=list)
    meets_minimum_10: bool = False

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass
class CorpusAuditReport:
    total_families: int
    total_styles: int
    under_10_count: int
    eligible_under_10_count: int
    phrase_distribution: dict[int, int]
    classification_counts: dict[str, int]
    records: list[StyleAuditRecord]

    def to_dict(self) -> dict[str, Any]:
        return {
            "total_families": self.total_families,
            "total_styles": self.total_styles,
            "under_10_count": self.under_10_count,
            "eligible_under_10_count": self.eligible_under_10_count,
            "phrase_distribution": {str(k): v for k, v in sorted(self.phrase_distribution.items())},
            "classification_counts": self.classification_counts,
            "records": [r.to_dict() for r in self.records],
        }


def load_sweep_evidence(sweep_dirs: Iterable[Path]) -> dict[str, dict[str, Any]]:
    """Index observation counts and observed phrase IDs by (template_id, style)."""
    evidence_index: dict[str, dict[str, Any]] = {}
    for sweep_dir in sweep_dirs:
        evidence_file = sweep_dir / "evidence.jsonl"
        if not evidence_file.is_file():
            continue
        try:
            with open(evidence_file, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    row = json.loads(line)
                    path_info = row.get("semanticPath") or {}
                    template_id = path_info.get("semanticTemplateID")
                    variant = path_info.get("realizationVariant") or "neutral"
                    phrase_id = path_info.get("phraseID")
                    if not template_id:
                        continue
                    key = f"{template_id}:{variant}"
                    if key not in evidence_index:
                        evidence_index[key] = {
                            "observations": 0,
                            "phrase_ids": set(),
                        }
                    evidence_index[key]["observations"] += 1
                    if phrase_id:
                        evidence_index[key]["phrase_ids"].add(phrase_id)
        except Exception:
            continue
    return evidence_index


def _resolve_package_repositories(repository: Path) -> dict[str, Path] | None:
    try:
        discovered = discover_convo_engine_repositories(repository)
        if isinstance(discovered, dict) and discovered:
            return discovered
    except Exception:
        pass
    return {CORE_OWNER: repository}


def _convo_shard_path(
    repository: Path,
    conv_root: Path,
    entry: dict[str, Any],
) -> Path:
    source_repo = entry.get("sourceRepository")
    source_path = entry.get("sourcePath")
    if isinstance(source_repo, str) and source_repo and isinstance(source_path, str) and source_path:
        return Path(source_repo) / source_path
    return conv_root / entry["path"]


def _append_text_rows(
    bucket: dict[str, list[dict[str, Any]]],
    style_key: str,
    text_obj: Any,
) -> None:
    if not isinstance(text_obj, dict):
        return
    en_raw = text_obj.get("EN", "")
    tl_raw = text_obj.get("TL", "")
    en_list = en_raw if isinstance(en_raw, list) else ([en_raw] if isinstance(en_raw, str) else [])
    tl_list = tl_raw if isinstance(tl_raw, list) else ([tl_raw] if isinstance(tl_raw, str) else [])
    rows = bucket.setdefault(style_key, [])
    for idx in range(max(len(en_list), len(tl_list))):
        en_val = en_list[idx] if idx < len(en_list) and isinstance(en_list[idx], str) else ""
        tl_val = tl_list[idx] if idx < len(tl_list) and isinstance(tl_list[idx], str) else ""
        if en_val or tl_val:
            rows.append({"translations": {"EN": en_val, "TL": tl_val}})


def _extract_say_styles(say_value: Any, prefix: str = "") -> dict[str, list[dict[str, Any]]]:
    styles: dict[str, list[dict[str, Any]]] = {}
    if not isinstance(say_value, dict):
        return styles
    if "EN" in say_value or "TL" in say_value:
        _append_text_rows(styles, f"{prefix}default" if prefix else "default", say_value)
        return styles
    if isinstance(say_value.get("variants"), list):
        for variant in say_value["variants"]:
            if not isinstance(variant, dict):
                continue
            vid = str(variant.get("id") or "default")
            key = f"{prefix}{vid}" if prefix else vid
            _append_text_rows(styles, key, variant.get("text") or variant.get("translations"))
        return styles
    for sub_key, sub_val in say_value.items():
        if isinstance(sub_val, dict):
            nested = _extract_say_styles(sub_val, prefix=f"{prefix}{sub_key}." if prefix else f"{sub_key}.")
            for k, v in nested.items():
                styles.setdefault(k, []).extend(v)
    return styles


def _extract_convo_engine_families(document: dict[str, Any]) -> list[dict[str, Any]]:
    doc_kind = document.get("kind")
    if doc_kind not in {"dialogue", "realization"}:
        return []
    namespace = str(document.get("namespace") or "").strip()
    raw_id = str(document.get("id") or "").strip()
    canonical_id = f"{namespace}.{raw_id}".strip(".") if namespace and not raw_id.startswith(f"{namespace}.") else raw_id
    if not canonical_id:
        return []
    owner = str(document.get("owner") or "ProjectHoomans")
    styles: dict[str, list[dict[str, Any]]] = {}
    if doc_kind == "dialogue":
        styles.update(_extract_say_styles(document.get("say")))
        styles.update(_extract_say_styles(document.get("respond"), prefix="respond."))
        reply = document.get("reply")
        if isinstance(reply, dict):
            for outcome, branch in reply.items():
                if isinstance(branch, dict):
                    styles.update(_extract_say_styles(branch.get("say"), prefix=f"reply.{outcome}."))
        for idx, turn in enumerate(document.get("turns") or (), start=1):
            if isinstance(turn, dict):
                _append_text_rows(styles, f"turn.{idx}", turn.get("text"))
    else:
        if isinstance(document.get("translations"), dict):
            trans = document["translations"]
            en_tokens = trans.get("EN") or []
            tl_tokens = trans.get("TL") or []
            if isinstance(en_tokens, list) and isinstance(tl_tokens, list):
                en_text = [" ".join(str(t.get("value", "")) for t in en_tokens if isinstance(t, dict))] if en_tokens and isinstance(en_tokens[0], dict) else en_tokens
                tl_text = [" ".join(str(t.get("value", "")) for t in tl_tokens if isinstance(t, dict))] if tl_tokens and isinstance(tl_tokens[0], dict) else tl_tokens
                _append_text_rows(styles, "realization", {"EN": en_text, "TL": tl_text})
    if not styles:
        return []
    return [{
        "semanticTemplateID": canonical_id,
        "owner": owner,
        "styles": styles,
    }]


def audit_corpus(
    repository: Path | None = None,
    manifest_path: Path | None = None,
    sweep_dirs: Iterable[Path] | None = None,
) -> CorpusAuditReport:
    """Perform a comprehensive audit of all canonical conversation phrase styles."""
    if repository is None:
        repository = Path(__file__).resolve().parents[3]
    if manifest_path is None:
        manifest_path = repository / CONVERSATION_MANIFEST_RELATIVE

    manifest_path = manifest_path.resolve()
    conv_root = manifest_path.parent
    package_repositories = _resolve_package_repositories(repository)
    _, entries = _load_manifest(
        repository,
        manifest_path,
        package_repositories=package_repositories,
    )

    if sweep_dirs is None:
        sweeps_base = repository / "tools/semantic_harness/reports/sweeps"
        if sweeps_base.is_dir():
            sweep_dirs = [p for p in sweeps_base.iterdir() if p.is_dir()]
        else:
            sweep_dirs = []

    sweep_evidence = load_sweep_evidence(sweep_dirs)

    records: list[StyleAuditRecord] = []
    total_families = 0
    phrase_distribution: dict[int, int] = {}
    classification_counts: dict[str, int] = {c: 0 for c in ALL_CLASSIFICATIONS}

    for entry in entries:
        if entry["kind"] not in {"content", "convo_engine"}:
            continue
        shard_path = _convo_shard_path(repository, conv_root, entry)
        with open(shard_path, "r", encoding="utf-8") as f:
            document = json.load(f)

        groups = document.get("groups") or {}
        if entry["kind"] == "content":
            families = document.get("phraseFamilies") or []
        else:
            families = _extract_convo_engine_families(document)
        for family in families:
            total_families += 1
            template_id = family["semanticTemplateID"]
            family_id = f"phrase.{template_id}"
            group_name = family.get("group", "")
            group_meta = groups.get(group_name) or {}
            source_owner = family.get("owner") or group_meta.get("contentOwner") or entry.get("owner") or "UNKNOWN"
            styles = family.get("styles") or {}

            for style_key, raw_phrases in styles.items():
                phrase_count = len(raw_phrases)
                phrase_distribution[phrase_count] = phrase_distribution.get(phrase_count, 0) + 1

                en_phrases: list[str] = []
                tl_phrases: list[str] = []
                en_norm_exact: list[str] = []
                tl_norm_exact: list[str] = []
                en_norm_near: list[str] = []
                en_placeholders: list[list[str]] = []
                tl_placeholders: list[list[str]] = []
                suspicious_identical: list[str] = []

                for phrase in raw_phrases:
                    trans = phrase.get("translations") or {}
                    en = trans.get("EN", "")
                    tl = trans.get("TL", "")
                    en_phrases.append(en)
                    tl_phrases.append(tl)

                    en_norm_exact.append(normalize_exact(en))
                    tl_norm_exact.append(normalize_exact(tl))
                    en_norm_near.append(normalize_near(en))

                    p_en = extract_placeholders(en)
                    p_tl = extract_placeholders(tl)
                    en_placeholders.append(p_en)
                    tl_placeholders.append(p_tl)

                    # English identical in TL
                    if en.strip() and tl.strip() and en.strip() == tl.strip():
                        # Exclude trivial non-word strings like "..." or pure numbers
                        if len(en.strip()) > 3 and any(c.isalpha() for c in en):
                            suspicious_identical.append(en)

                unique_en_exact = set(en_norm_exact)
                unique_tl_exact = set(tl_norm_exact)

                # Check duplicates
                duplicates: list[str] = []
                exact_counts: dict[str, int] = {}
                for text in en_norm_exact:
                    exact_counts[text] = exact_counts.get(text, 0) + 1
                for text, count in exact_counts.items():
                    if count > 1:
                        duplicates.append(text)

                # Check near duplicates
                near_duplicates: list[str] = []
                near_counts: dict[str, int] = {}
                for text in en_norm_near:
                    near_counts[text] = near_counts.get(text, 0) + 1
                for text, count in near_counts.items():
                    if count > 1 and count > len(duplicates):
                        near_duplicates.append(text)

                # Check placeholder parity across pairs
                placeholder_parity = True
                for p_en, p_tl in zip(en_placeholders, tl_placeholders):
                    if p_en != p_tl:
                        placeholder_parity = False
                        break

                classification, reason = classify_style(
                    entry["path"], template_id, style_key, raw_phrases
                )
                classification_counts[classification] = classification_counts.get(classification, 0) + 1

                evidence_key = f"{template_id}:{style_key}"
                obs_data = sweep_evidence.get(evidence_key, {})
                obs_count = obs_data.get("observations", 0)
                obs_phrases = sorted(obs_data.get("phrase_ids", set()))

                meets_min_10 = (
                    phrase_count >= 10
                    and len(unique_en_exact) >= 10
                    and len(unique_tl_exact) >= 10
                    and placeholder_parity
                    and len(duplicates) == 0
                )

                records.append(
                    StyleAuditRecord(
                        source_shard=entry["path"],
                        semantic_template_id=template_id,
                        family_id=family_id,
                        style=style_key,
                        phrase_count=phrase_count,
                        unique_normalized_en_count=len(unique_en_exact),
                        unique_normalized_tl_count=len(unique_tl_exact),
                        en_phrases=en_phrases,
                        tl_phrases=tl_phrases,
                        placeholder_signatures_en=en_placeholders,
                        placeholder_signatures_tl=tl_placeholders,
                        placeholder_parity=placeholder_parity,
                        duplicate_candidates=duplicates,
                        near_duplicate_candidates=near_duplicates,
                        suspicious_en_identical_tl=suspicious_identical,
                        source_owner=source_owner,
                        classification=classification,
                        classification_reason=reason,
                        sweep_observations=obs_count,
                        sweep_distinct_phrases=obs_phrases,
                        meets_minimum_10=meets_min_10,
                    )
                )

    records.sort(key=lambda r: (r.source_shard, r.semantic_template_id, r.style))

    under_10_count = sum(1 for r in records if r.phrase_count < 10)
    eligible_under_10_count = sum(
        1 for r in records if r.classification == CLASSIFICATION_EXPAND and r.phrase_count < 10
    )

    return CorpusAuditReport(
        total_families=total_families,
        total_styles=len(records),
        under_10_count=under_10_count,
        eligible_under_10_count=eligible_under_10_count,
        phrase_distribution=phrase_distribution,
        classification_counts=classification_counts,
        records=records,
    )


def render_markdown_ledger(report: CorpusAuditReport) -> str:
    """Render a comprehensive Markdown classification and variation ledger."""
    lines = [
        "# Canonical Dialogue Variation & Classification Ledger",
        "",
        f"- Total canonical phrase families: **{report.total_families}**",
        f"- Total canonical style buckets: **{report.total_styles}**",
        f"- Under-10 style buckets total: **{report.under_10_count}**",
        f"- Eligible under-10 style buckets (`EXPAND_TO_10`): **{report.eligible_under_10_count}**",
        "",
        "## Classification counts",
        "",
    ]
    for classification, count in sorted(report.classification_counts.items()):
        lines.append(f"- `{classification}`: {count}")

    lines.extend([
        "",
        "## Phrase count distribution",
        "",
    ])
    for count, frequency in sorted(report.phrase_distribution.items()):
        lines.append(f"- Exactly {count} phrase(s): {frequency}")

    lines.extend([
        "",
        "## Style buckets inventory",
        "",
        "| Shard | SemanticTemplateID | Style | Count | U_EN | U_TL | Parity | Dups | Identical TL | Classification | Reason |",
        "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
    ])

    for r in report.records:
        parity_str = "YES" if r.placeholder_parity else "MISMATCH"
        dups_count = len(r.duplicate_candidates) + len(r.near_duplicate_candidates)
        ident_count = len(r.suspicious_en_identical_tl)
        lines.append(
            f"| `{r.source_shard}` | `{r.semantic_template_id}` | `{r.style}` | {r.phrase_count} | "
            f"{r.unique_normalized_en_count} | {r.unique_normalized_tl_count} | {parity_str} | "
            f"{dups_count} | {ident_count} | `{r.classification}` | {r.classification_reason} |"
        )

    return "\n".join(lines) + "\n"
