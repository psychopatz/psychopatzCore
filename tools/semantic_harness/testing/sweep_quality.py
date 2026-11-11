"""Deterministic dialogue quality analyzer with confidence classes and negative controls.

Evaluates compact evidence rows against QUALITY_RUBRIC rules:
- Empty, fragment, and one-word detection (with negative controls for valid short words)
- Placeholder leaks ({0}, %s, nil, NaN) and translation key leaks (IGUI_, UI_)
- Unsupported family references (e.g. 'family' without a family bond)
- Relationship and intimacy terms without supporting bond
- Identity and private name leaks without sufficient familiarity/trust
- Perspective and agency suspicions
- Generic acknowledgement overuse
"""

from __future__ import annotations

import re
from typing import Any, Mapping

from .sweep_evidence import QualityFlag

# Words that are legitimately valid short responses (negative controls)
ALLOWED_SHORT_WORDS = frozenset({
    "yeah",
    "yeah.",
    "yes",
    "yes.",
    "no",
    "no.",
    "sure",
    "sure.",
    "right",
    "right.",
    "okay",
    "okay.",
    "thanks",
    "thanks.",
    "fine",
    "fine.",
    "nevermind",
    "nevermind.",
    "sige",
    "sige.",
    "oo",
    "oo.",
    "hindi",
    "hindi.",
    "ayos",
    "ayos.",
    "salamat",
    "salamat.",
    "you too",
    "you too.",
    "kayo rin",
    "kayo rin.",
    "ikaw rin",
    "ikaw rin.",
    "ingat",
    "ingat.",
})

FAMILY_TERMS_PATTERN = re.compile(
    r"\b(family|mother|father|sister|brother|mom|dad|sis|bro|nanay|tatay|ate|kuya)\b",
    re.IGNORECASE,
)

ROMANTIC_TERMS_PATTERN = re.compile(
    r"\b(darling|sweetheart|sweetie|babe|baby|honey|mahal|irog)\b",
    re.IGNORECASE,
)

PLACEHOLDER_LEAK_PATTERN = re.compile(
    r"(\{[0-9a-zA-Z_]+\}|%[0-9]*[sdif]|<[0-9a-zA-Z_]+>|\bNaN\b|\bnil\b|\bundefined\b)",
)

TRANSLATION_KEY_PATTERN = re.compile(
    r"\b(IGUI_[a-zA-Z0-9_]+|UI_[a-zA-Z0-9_]+|ContextMenu_[a-zA-Z0-9_]+)\b",
)

VALID_FAMILY_BONDS = frozenset({"mother", "father", "sister", "brother"})


def _optional_float(value: Any) -> float | None:
    """Return a numeric value without crashing on categorical production states."""
    if value is None or isinstance(value, bool):
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


class QualityAnalyzer:
    """Evaluates evidence rows and attaches deterministic quality flags."""

    def analyze_row(self, row: dict[str, Any]) -> list[QualityFlag]:
        """Analyze a single evidence row and return any discovered QualityFlags."""
        flags: list[QualityFlag] = []

        final_text = str(row.get("output", {}).get("finalText") or "").strip()
        semantic_path = row.get("semanticPath", {})
        trigger = row.get("trigger", {})
        rel_summary = trigger.get("relationshipSummary", {})
        bond_kind = str(rel_summary.get("bondKind") or "none").lower()
        bond_class = str(rel_summary.get("bondClass") or "").lower()
        familiarity = _optional_float(rel_summary.get("familiarity")) or 0.0
        identity_trust_raw = rel_summary.get("identityTrust")
        identity_trust = _optional_float(identity_trust_raw)
        identity_trust_state = str(identity_trust_raw or "unknown").strip().lower()

        # 1. EMPTY_RESPONSE
        if not final_text:
            flags.append(
                QualityFlag(
                    name="EMPTY_RESPONSE",
                    severity="CRITICAL",
                    confidence="DEFINITE",
                    detail="Rendered NPC response is completely empty or blank.",
                )
            )
            return flags

        # 2. PLACEHOLDER_LEAK
        placeholder_match = PLACEHOLDER_LEAK_PATTERN.search(final_text)
        if placeholder_match:
            flags.append(
                QualityFlag(
                    name="PLACEHOLDER_LEAK",
                    severity="CRITICAL",
                    confidence="DEFINITE",
                    detail=f"Unreplaced template placeholder found in text: '{placeholder_match.group(1)}'",
                )
            )

        # 3. TRANSLATION_KEY_LEAK
        key_match = TRANSLATION_KEY_PATTERN.search(final_text)
        if key_match:
            flags.append(
                QualityFlag(
                    name="TRANSLATION_KEY_LEAK",
                    severity="CRITICAL",
                    confidence="DEFINITE",
                    detail=f"Raw translation key leaked into final text: '{key_match.group(1)}'",
                )
            )

        # 4. ONE_WORD_RESPONSE / VERY_SHORT_FRAGMENT
        words = final_text.split()
        if len(words) == 1:
            clean_word = words[0].lower().rstrip(".!?,")
            # Negative control check: allowed conversational words pass cleanly
            if clean_word not in ALLOWED_SHORT_WORDS and words[0].lower() not in ALLOWED_SHORT_WORDS:
                flags.append(
                    QualityFlag(
                        name="ONE_WORD_RESPONSE",
                        severity="HIGH",
                        confidence="SUSPECT",
                        detail=f"Single-word response '{final_text}' is not an approved conversational short response.",
                    )
                )

        # 5. UNSUPPORTED_FAMILY_REFERENCE
        # Required user-observed defect class:
        # Detects family wording or familyAddress when relationship context is NOT a family bond
        family_match = FAMILY_TERMS_PATTERN.search(final_text)
        has_family_address = bool(semantic_path.get("familyAddress"))
        is_family_bond = bond_kind in VALID_FAMILY_BONDS or bond_class == "family"

        if (family_match or has_family_address) and not is_family_bond:
            term = family_match.group(1) if family_match else "familyAddress"
            flags.append(
                QualityFlag(
                    name="UNSUPPORTED_FAMILY_REFERENCE",
                    severity="CRITICAL",
                    confidence="DEFINITE",
                    detail=(
                        f"Family reference '{term}' used but relationship bond is '{bond_kind}' "
                        f"(bondClass: '{bond_class or 'none'}'). Unsupported by context."
                    ),
                )
            )

        # 6. RELATIONSHIP_TERM_WITHOUT_BOND
        romantic_match = ROMANTIC_TERMS_PATTERN.search(final_text)
        if romantic_match and bond_kind != "lover":
            flags.append(
                QualityFlag(
                    name="RELATIONSHIP_TERM_WITHOUT_BOND",
                    severity="HIGH",
                    confidence="DEFINITE",
                    detail=f"Intimate address '{romantic_match.group(1)}' used when bondKind is '{bond_kind}' (expected 'lover').",
                )
            )

        # 7. IDENTITY_TERM_WITHOUT_KNOWLEDGE
        # Check if NPC uses player name when stranger / low trust
        player_id = trigger.get("actorSummary", {}).get("listenerID") or ""
        if player_id and len(player_id) > 2 and player_id.lower() in final_text.lower():
            trust_is_low = (
                (identity_trust is not None and identity_trust < 50.0)
                or identity_trust_state in {"unknown", "untrusted", "none"}
            )
            if familiarity < 5.0 or trust_is_low:
                trust_detail = (
                    f"{identity_trust:.1f}"
                    if identity_trust is not None
                    else identity_trust_state
                )
                flags.append(
                    QualityFlag(
                        name="IDENTITY_TERM_WITHOUT_KNOWLEDGE",
                        severity="HIGH",
                        confidence="SUSPECT",
                        detail=(
                            f"Name '{player_id}' used with low familiarity ({familiarity:.1f} < 5) "
                            f"or insufficient identity trust ({trust_detail})."
                        ),
                    )
                )

        # 8. PERSPECTIVE_SUSPECT
        intent = str(semantic_path.get("intent") or "").lower()
        subject = str(semantic_path.get("subject") or "").lower()
        template_id = str(semantic_path.get("semanticTemplateID") or "").lower()
        is_wellbeing = "wellbeing" in intent or "wellbeing" in subject or "wellbeing" in template_id
        if is_wellbeing and final_text.lower().startswith("you are "):
            flags.append(
                QualityFlag(
                    name="PERSPECTIVE_SUSPECT",
                    severity="MEDIUM",
                    confidence="REVIEW",
                    detail="Wellbeing reply appears to describe listener ('You are...') instead of speaker.",
                )
            )

        # 9. GENERIC_ACKNOWLEDGEMENT_SUSPECT
        if final_text.lower() in ("i understand.", "i see.", "acknowledged.", "that is good."):
            flags.append(
                QualityFlag(
                    name="GENERIC_ACKNOWLEDGEMENT_SUSPECT",
                    severity="LOW",
                    confidence="REVIEW",
                    detail=f"Canned generic acknowledgement '{final_text}' may lack situational specificity.",
                )
            )

        return flags

    def tag_row(self, row: dict[str, Any]) -> dict[str, Any]:
        """Analyze row, append flags and cluster keys, and update review state."""
        flags = self.analyze_row(row)
        flag_dicts = [f.to_dict() for f in flags]
        row.setdefault("quality", {})["flags"] = flag_dicts

        # Build cluster keys
        cluster_keys: list[str] = []
        sem_path = row.get("semanticPath", {})
        canonical_source = row.get("selectionProvenance", {}).get("canonicalSourceOwner") or "UNKNOWN"
        phrase_id = sem_path.get("phraseID") or sem_path.get("semanticVariantID")
        pool_id = sem_path.get("semanticTemplateID")

        for f in flags:
            cluster_keys.append(f"flag:{f.name}")
            if canonical_source != "UNKNOWN":
                cluster_keys.append(f"source:{canonical_source}:{f.name}")
            if phrase_id:
                cluster_keys.append(f"phrase:{phrase_id}:{f.name}")
            elif pool_id:
                cluster_keys.append(f"pool:{pool_id}:{f.name}")

        row["quality"]["clusterKeys"] = cluster_keys
        if flags:
            row["quality"]["reviewState"] = "FLAGGED"
        else:
            row["quality"]["reviewState"] = "UNREVIEWED"

        return row

    def analyze_run(self, rows: Sequence[dict[str, Any]]) -> list[dict[str, Any]]:
        """Run two-stage analysis across all rows in a sweep run:

        Stage 1: Per-row local quality heuristics (tag_row).
        Stage 2: Cross-row analysis for duplicate rendered text, fallback saturation,
        variant collapse, and generic acknowledgement concentration.
        """
        # Stage 1: Tag each row locally
        for row in rows:
            self.tag_row(row)

        # Stage 2: Cross-row analysis
        text_groups: dict[str, list[dict[str, Any]]] = {}
        for row in rows:
            text = str(row.get("output", {}).get("finalText") or "").strip()
            if text:
                text_groups.setdefault(text.lower(), []).append(row)

        for text_lower, group_rows in text_groups.items():
            count = len(group_rows)
            if count < 2:
                continue

            first_text = group_rows[0].get("output", {}).get("finalText") or ""
            distinct_cases = list(dict.fromkeys(
                r.get("identity", {}).get("caseID")
                for r in group_rows
                if r.get("identity", {}).get("caseID")
            ))

            # Only analyze if repeated across distinct cases
            if len(distinct_cases) < 2:
                continue

            # 1. Fallback / clarification saturation across intended non-clarification surfaces
            clarification_rows = [
                r for r in group_rows
                if (
                    r.get("semanticPath", {}).get("semanticTemplateID") == "semantic.ask_clarification"
                    or r.get("identity", {}).get("reachedSurface") == "semantic.ask_clarification"
                    or text_lower == "i'm not sure what you mean."
                )
            ]
            if len(clarification_rows) >= 2:
                for r in clarification_rows:
                    if r.get("identity", {}).get("surfaceStatus") != "EXPECTED_FALLBACK":
                        # Check if flag already added
                        existing_flag_names = {f["name"] for f in r.get("quality", {}).get("flags", [])}
                        if "FALLBACK_SATURATION" not in existing_flag_names:
                            flag = QualityFlag(
                                name="FALLBACK_SATURATION",
                                severity="HIGH",
                                confidence="DEFINITE",
                                detail=f"Clarification fallback '{first_text}' rendered across {len(distinct_cases)} distinct cases",
                            )
                            r.setdefault("quality", {}).setdefault("flags", []).append(flag.to_dict())
                            r.setdefault("quality", {}).setdefault("clusterKeys", []).append("flag:FALLBACK_SATURATION")
                            r["quality"]["reviewState"] = "FLAGGED"

            # 2. Variant collapse: multiple distinct semantic variants render identical visible text
            variants_in_group = list(dict.fromkeys(
                r.get("semanticPath", {}).get("semanticVariantID")
                for r in group_rows
                if r.get("semanticPath", {}).get("semanticVariantID")
            ))
            if len(variants_in_group) >= 2:
                for r in group_rows:
                    existing_flag_names = {f["name"] for f in r.get("quality", {}).get("flags", [])}
                    if "VARIANT_COLLAPSE" not in existing_flag_names:
                        flag = QualityFlag(
                            name="VARIANT_COLLAPSE",
                            severity="MEDIUM",
                            confidence="DEFINITE",
                            detail=f"Multiple semantic variants ({', '.join(variants_in_group[:3])}) rendered identical text '{first_text}'",
                        )
                        r.setdefault("quality", {}).setdefault("flags", []).append(flag.to_dict())
                        r.setdefault("quality", {}).setdefault("clusterKeys", []).append("flag:VARIANT_COLLAPSE")
                        r["quality"]["reviewState"] = "FLAGGED"

            # 3. Generic acknowledgement concentration
            if text_lower in ("i understand.", "i see.", "acknowledged.", "that is good.", "okay.", "sure."):
                if len(distinct_cases) >= 3:
                    for r in group_rows:
                        existing_flag_names = {f["name"] for f in r.get("quality", {}).get("flags", [])}
                        if "GENERIC_ACKNOWLEDGEMENT_CONCENTRATION" not in existing_flag_names:
                            flag = QualityFlag(
                                name="GENERIC_ACKNOWLEDGEMENT_CONCENTRATION",
                                severity="MEDIUM",
                                confidence="SUSPECT",
                                detail=f"Generic acknowledgement '{first_text}' concentrated across {len(distinct_cases)} cases",
                            )
                            r.setdefault("quality", {}).setdefault("flags", []).append(flag.to_dict())
                            r.setdefault("quality", {}).setdefault("clusterKeys", []).append("flag:GENERIC_ACKNOWLEDGEMENT_CONCENTRATION")
                            r["quality"]["reviewState"] = "FLAGGED"

            # 4. Duplicate rendered text across distinct cases (general)
            # Flags abnormal repetition exceeding the 10-variant uniform distribution expectation.
            # Across 50+ cases testing a prompt, a 10-variant pool expects ~5-6 occurrences per phrase.
            # Concentration is defective when an exact string appears in >= 8 distinct cases,
            # or represents an excessive concentration in targeted test suites (>= 4 cases and >= 20% of run).
            is_heavy_concentration = len(distinct_cases) >= 8
            is_targeted_run_collapse = len(distinct_cases) >= 4 and (len(group_rows) / max(1, len(rows))) >= 0.20

            if (is_heavy_concentration or is_targeted_run_collapse) and text_lower not in ALLOWED_SHORT_WORDS:
                for r in group_rows:
                    existing_flag_names = {f["name"] for f in r.get("quality", {}).get("flags", [])}
                    if "DUPLICATE_RENDERED_TEXT" not in existing_flag_names:
                        flag = QualityFlag(
                            name="DUPLICATE_RENDERED_TEXT",
                            severity="MEDIUM",
                            confidence="DEFINITE",
                            detail=f"Exact text '{first_text}' duplicated across {len(distinct_cases)} cases",
                        )
                        r.setdefault("quality", {}).setdefault("flags", []).append(flag.to_dict())
                        r.setdefault("quality", {}).setdefault("clusterKeys", []).append("flag:DUPLICATE_RENDERED_TEXT")
                        r["quality"]["reviewState"] = "FLAGGED"

        return list(rows)
