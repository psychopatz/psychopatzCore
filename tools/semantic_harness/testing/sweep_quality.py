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
from typing import Any, Mapping, Sequence

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

_GENERIC_NAME_FALLBACKS = frozenset({
    "",
    "player",
    "npc",
    "listener",
    "speaker",
    "addressee",
    "stranger",
    "you",
    "unknown",
    "none",
    "nil",
    "null",
    "n/a",
})

_ATOMIC_BARK_INTENTS = frozenset({
    "bark",
    "exertion",
    "pain",
    "grunt",
    "shout",
    "combat_bark",
})

_DOUBLE_COMMA_RE = re.compile(r",\s*,")
_MULTI_SPACE_RE = re.compile(r" {2,}")
_LEADING_PUNCT_RE = re.compile(r"^[,;:]")
_COMMA_BEFORE_END_RE = re.compile(r",\s*[.!?]")
_SPACE_BEFORE_END_RE = re.compile(r"\s+[.!?]")
_DANGLING_PREP_RE = re.compile(
    r"\b(?:near|beside|toward|towards|against|between|around|from|into|at)\s*[.!?]",
    re.IGNORECASE,
)
_VOCATIVE_PLACEHOLDER_RE = re.compile(
    r"(?:(?:,\s*|^)(?:Unknown|Null|Nil|N/A)(?:\s*[,!?]|\s*$)|"
    r"\b(?:hey|hi|hello|listen|thanks|sorry|careful|look),\s+(?:unknown|none|null|nil)\b)",
)
_DOUBLE_VOCATIVE_RE = re.compile(
    r"(?:,\s*(?:stranger|you)\s*,\s*(?:stranger|you)\b|"
    r"^(?:hey|hi|hello|listen|look|thanks|sorry),\s+[^,]+,\s+(?:stranger|you)\b|"
    r"\bstranger,\s+stranger\b)",
    re.IGNORECASE,
)
_AWKWARD_YOU_VOCATIVE_RE = re.compile(
    r"(?:,\s+you\s*[.!?]$|^(?:hey|hi|hello|listen|thanks|sorry|careful),\s+you\b)",
    re.IGNORECASE,
)


def _first_non_empty_str(*values: Any) -> str:
    for val in values:
        if isinstance(val, str):
            text = val.strip()
            if text:
                return text
    return ""


def _word_present(needle: str, haystack: str) -> bool:
    clean = needle.strip()
    if len(clean) < 2 or not haystack:
        return False
    return bool(re.search(rf"(?<!\w){re.escape(clean)}(?!\w)", haystack, re.IGNORECASE))


def _extract_dynamic_context(row: Mapping[str, Any]) -> dict[str, Any]:
    """Extract normalized dynamic-token, actor, relationship, and location context."""
    output = row.get("output") or {}
    final_text = str(output.get("finalText") or "").strip()
    semantic_path = row.get("semanticPath") or {}
    trigger = row.get("trigger") or {}
    rel_summary = trigger.get("relationshipSummary") or {}
    actor_summary = trigger.get("actorSummary") or {}
    state_summary = trigger.get("stateSummary") or {}
    params = trigger.get("parameters") or {}
    row_ctx = row.get("context") or {}
    trigger_ctx = trigger.get("context") or {}

    dynamic_meta = row.get("dynamicTokens") or output.get("dynamicTokens") or {}
    resolved_tokens_raw = (
        dynamic_meta.get("resolvedTokens")
        or output.get("resolvedTokens")
        or row.get("resolvedTokens")
        or {}
    )
    resolved_tokens = (
        {str(k).strip("{}"): str(v) for k, v in resolved_tokens_raw.items()}
        if isinstance(resolved_tokens_raw, Mapping)
        else {}
    )
    used_tokens_raw = (
        dynamic_meta.get("usedTokens")
        or output.get("usedTokens")
        or row.get("usedTokens")
        or []
    )
    used_tokens = [str(t) for t in used_tokens_raw] if isinstance(used_tokens_raw, (list, tuple)) else []

    bond_kind = str(rel_summary.get("bondKind") or "none").strip().lower()
    raw_fam = rel_summary.get("familiarity")
    if raw_fam is None:
        raw_fam = params.get("relationship.familiarity")
    familiarity = _optional_float(raw_fam)
    familiarity_num = familiarity if familiarity is not None else 0.0

    identity_trust_raw = rel_summary.get("identityTrust")
    if identity_trust_raw is None:
        identity_trust_raw = params.get("relationship.identityTrust")
    identity_trust = _optional_float(identity_trust_raw)
    identity_trust_state = str(identity_trust_raw or "").strip().lower()

    knows_val = rel_summary.get("knowsAddressee")
    if knows_val is None:
        knows_val = actor_summary.get("knowsAddressee")
    if knows_val is None:
        knows_val = params.get("knowsAddressee")
    if knows_val is None:
        knows_val = params.get("addressee.knowsAddressee")
    if knows_val is None:
        knows_val = row_ctx.get("knowsAddressee")

    has_bond = bond_kind not in ("", "none", "unknown", "stranger")
    trust_explicitly_unknown = (
        (identity_trust is not None and identity_trust <= 0.0)
        or (
            identity_trust is None
            and identity_trust_raw is not None
            and identity_trust_state in {"unknown", "unmet", "untrusted", "none", "0"}
        )
    )
    if knows_val is False:
        speaker_does_not_know = True
    elif knows_val is True:
        speaker_does_not_know = False
    elif trust_explicitly_unknown:
        speaker_does_not_know = True
    elif has_bond:
        speaker_does_not_know = False
    else:
        speaker_does_not_know = familiarity_num <= 0.0

    listener_id = _first_non_empty_str(actor_summary.get("listenerID"))
    personal_listener_id = (
        listener_id if listener_id.lower() not in _GENERIC_NAME_FALLBACKS else ""
    )
    addressee_name = _first_non_empty_str(
        actor_summary.get("addresseeName"),
        actor_summary.get("listenerName"),
        rel_summary.get("addresseeName"),
        params.get("addressee.name"),
        params.get("addresseeName"),
        row_ctx.get("addresseeName"),
        trigger_ctx.get("addresseeName"),
        personal_listener_id,
    )
    if addressee_name.lower() in _GENERIC_NAME_FALLBACKS:
        addressee_name = ""

    speaker_name = _first_non_empty_str(
        actor_summary.get("speakerName"),
        params.get("speaker.name"),
        params.get("speakerName"),
        row_ctx.get("speakerName"),
        trigger_ctx.get("speakerName"),
        resolved_tokens.get("speaker.name"),
    )
    if speaker_name.lower() in _GENERIC_NAME_FALLBACKS:
        speaker_name = ""

    bound_location = _first_non_empty_str(
        state_summary.get("sceneLocation"),
        state_summary.get("eventLocation"),
        state_summary.get("location"),
        row_ctx.get("sceneLocation"),
        row_ctx.get("eventLocation"),
        trigger_ctx.get("sceneLocation"),
        trigger_ctx.get("eventLocation"),
        params.get("scene.location"),
        params.get("sceneLocation"),
        params.get("eventLocation"),
        params.get("slot.place.name"),
    )

    addressee_token_val = resolved_tokens.get("addressee.name", "")
    used_name = bool(
        (addressee_name and _word_present(addressee_name, final_text))
        or (
            "addressee.name" in {t.strip("{}") for t in used_tokens}
            and addressee_token_val.strip().lower() not in _GENERIC_NAME_FALLBACKS
        )
    )
    used_location = bool(bound_location and _word_present(bound_location, final_text))
    used_speaker_name = bool(speaker_name and _word_present(speaker_name, final_text))
    used_resolved_value = any(
        val.strip()
        and val.strip().lower() not in _GENERIC_NAME_FALLBACKS
        and _word_present(val, final_text)
        for val in resolved_tokens.values()
    )
    used_dynamic_reference = bool(
        used_tokens
        or used_name
        or used_location
        or used_speaker_name
        or used_resolved_value
    )

    return {
        "finalText": final_text,
        "semanticPath": semantic_path,
        "familiarity": familiarity_num,
        "bondKind": bond_kind,
        "speakerDoesNotKnow": speaker_does_not_know,
        "addresseeName": addressee_name,
        "speakerName": speaker_name,
        "boundLocation": bound_location,
        "resolvedTokens": resolved_tokens,
        "usedTokens": used_tokens,
        "addresseeTokenValue": addressee_token_val,
        "usedName": used_name,
        "usedDynamicReference": used_dynamic_reference,
    }


def summarize_dynamic_grounding(rows: Sequence[Mapping[str, Any]]) -> dict[str, Any]:
    """Summarize dynamic-token resolution, name appropriateness, and grammar health."""
    total_rows = len(rows)
    rows_with_dynamic_resolved = 0
    rows_with_name_use = 0
    rows_with_appropriate_name = 0
    broken_token_count = 0
    ungrounded_name_count = 0
    grounding_opportunity_count = 0

    for row in rows:
        quality = row.get("quality") or {}
        flags = quality.get("flags") or []
        flag_names = {
            str(f.get("name") or "")
            for f in flags
            if isinstance(f, Mapping)
        }
        has_ungrounded = "UNGROUNDED_NAME_USE" in flag_names
        has_broken = "BROKEN_TOKEN_GRAMMAR" in flag_names
        has_opportunity = "DYNAMIC_GROUNDING_OPPORTUNITY" in flag_names

        if has_ungrounded:
            ungrounded_name_count += 1
        if has_broken:
            broken_token_count += 1
        if has_opportunity:
            grounding_opportunity_count += 1

        ctx = _extract_dynamic_context(row)
        dg = quality.get("dynamicGrounding")
        if isinstance(dg, Mapping):
            used_dyn = bool(dg.get("usedDynamicReference"))
            used_name = bool(dg.get("usedName"))
        else:
            used_dyn = bool(ctx["usedDynamicReference"])
            used_name = bool(ctx["usedName"])

        if used_dyn and not has_broken:
            rows_with_dynamic_resolved += 1
        if used_name or has_ungrounded:
            rows_with_name_use += 1
            if not has_ungrounded:
                rows_with_appropriate_name += 1

    name_rate = (
        round(rows_with_appropriate_name / rows_with_name_use, 4)
        if rows_with_name_use > 0
        else 1.0
    )
    if total_rows == 0:
        status = "NO_ROWS"
    elif broken_token_count == 0 and ungrounded_name_count == 0:
        status = "DYNAMIC_GROUNDING_VERIFIED"
    else:
        status = "ISSUES_FOUND"

    return {
        "status": status,
        "totalRows": total_rows,
        "rowsWithDynamicTokensResolved": rows_with_dynamic_resolved,
        "rowsWithNameUse": rows_with_name_use,
        "rowsWithAppropriateNameUse": rows_with_appropriate_name,
        "appropriateNameUsageRate": name_rate,
        "brokenTokenCount": broken_token_count,
        "ungroundedNameCount": ungrounded_name_count,
        "groundingOpportunityCount": grounding_opportunity_count,
    }


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

        # 10. UNGROUNDED_NAME_USE & 11. BROKEN_TOKEN_GRAMMAR & 12. DYNAMIC_GROUNDING_OPPORTUNITY
        dyn_ctx = _extract_dynamic_context(row)
        flags.extend(self._analyze_dynamic_grounding(row, dyn_ctx, intent=intent))

        return flags

    def _analyze_dynamic_grounding(
        self,
        row: Mapping[str, Any],
        dyn_ctx: Mapping[str, Any],
        *,
        intent: str,
    ) -> list[QualityFlag]:
        flags: list[QualityFlag] = []
        final_text = str(dyn_ctx["finalText"])
        addressee_name = str(dyn_ctx["addresseeName"])
        speaker_does_not_know = bool(dyn_ctx["speakerDoesNotKnow"])
        addressee_tok_val = str(dyn_ctx["addresseeTokenValue"])
        used_tokens = list(dyn_ctx["usedTokens"])
        resolved_tokens = dict(dyn_ctx["resolvedTokens"])
        bound_location = str(dyn_ctx["boundLocation"])
        familiarity = float(dyn_ctx["familiarity"])
        used_dynamic_reference = bool(dyn_ctx["usedDynamicReference"])

        # BROKEN_TOKEN_GRAMMAR
        grammar_reasons: list[str] = []
        if _DOUBLE_COMMA_RE.search(final_text):
            grammar_reasons.append("empty slot between commas (', ,')")
        if _MULTI_SPACE_RE.search(final_text):
            grammar_reasons.append("consecutive spaces from empty token")
        if _LEADING_PUNCT_RE.search(final_text):
            grammar_reasons.append("leading punctuation from empty prefix token")
        if _COMMA_BEFORE_END_RE.search(final_text):
            grammar_reasons.append("comma immediately before terminal punctuation")
        if _SPACE_BEFORE_END_RE.search(final_text):
            grammar_reasons.append("whitespace immediately before terminal punctuation")
        if _DANGLING_PREP_RE.search(final_text):
            grammar_reasons.append("dangling preposition before terminal punctuation")
        if _VOCATIVE_PLACEHOLDER_RE.search(final_text):
            grammar_reasons.append("placeholder fallback ('Unknown'/'Nil'/'Null') rendered in text")
        if _DOUBLE_VOCATIVE_RE.search(final_text):
            grammar_reasons.append("double-vocative fallback artifact")

        for tok in used_tokens:
            clean_tok = str(tok).strip("{}")
            if clean_tok in resolved_tokens:
                val = str(resolved_tokens[clean_tok]).strip()
                if val == "" or val.lower() in {"unknown", "nil", "null", "n/a"}:
                    grammar_reasons.append(f"token '{{{clean_tok}}}' resolved to '{val or '<empty>'}'")

        if grammar_reasons:
            flags.append(
                QualityFlag(
                    name="BROKEN_TOKEN_GRAMMAR",
                    severity="HIGH",
                    confidence="DEFINITE",
                    detail="Broken dynamic-token grammar: " + "; ".join(dict.fromkeys(grammar_reasons)),
                )
            )

        # UNGROUNDED_NAME_USE
        ungrounded_reasons: list[str] = []
        tok_names = {str(t).strip("{}") for t in used_tokens}
        used_personal_name = bool(addressee_name and _word_present(addressee_name, final_text))
        used_addressee_tok = "addressee.name" in tok_names

        if speaker_does_not_know and (
            used_personal_name
            or (
                used_addressee_tok
                and addressee_tok_val.strip().lower() not in {"", "stranger", "you", "unknown"}
            )
        ):
            name_label = addressee_name or addressee_tok_val or "{addressee.name}"
            ungrounded_reasons.append(
                f"addressee personal name '{name_label}' used when speaker does not know addressee"
            )

        tok_low = addressee_tok_val.strip().lower()
        if tok_low == "you" and (used_addressee_tok or _AWKWARD_YOU_VOCATIVE_RE.search(final_text)):
            ungrounded_reasons.append("'{addressee.name}' resolved to generic 'you' inside vocative")
        elif not addressee_tok_val and _AWKWARD_YOU_VOCATIVE_RE.search(final_text):
            ungrounded_reasons.append("generic 'you' used in vocative address slot")
        elif tok_low == "stranger" and (not speaker_does_not_know or _DOUBLE_VOCATIVE_RE.search(final_text)):
            ungrounded_reasons.append(
                "'{addressee.name}' resolved to 'stranger' despite known addressee or double-vocative"
            )

        if ungrounded_reasons:
            flags.append(
                QualityFlag(
                    name="UNGROUNDED_NAME_USE",
                    severity="HIGH",
                    confidence="DEFINITE",
                    detail="; ".join(dict.fromkeys(ungrounded_reasons)),
                )
            )

        # DYNAMIC_GROUNDING_OPPORTUNITY (INFO/LOW)
        sem_path = dyn_ctx["semanticPath"]
        category = str(sem_path.get("category") or "").strip().lower()
        row_type = str(row.get("rowType") or sem_path.get("rowType") or "").strip().lower()
        is_atomic_bark = (
            intent in _ATOMIC_BARK_INTENTS
            or category == "bark"
            or row_type == "bark"
            or (len(final_text.split()) <= 2 and final_text.lower() in ALLOWED_SHORT_WORDS)
        )
        rich_addressee = bool(addressee_name and not speaker_does_not_know and familiarity >= 0.3)
        rich_location = bool(bound_location)

        if not is_atomic_bark and (rich_addressee or rich_location) and not used_dynamic_reference:
            context_bits: list[str] = []
            if rich_addressee:
                context_bits.append(f"known addresseeName='{addressee_name}' (familiarity={familiarity:.2f})")
            if rich_location:
                context_bits.append(f"location='{bound_location}'")
            flags.append(
                QualityFlag(
                    name="DYNAMIC_GROUNDING_OPPORTUNITY",
                    severity="INFO",
                    confidence="REVIEW",
                    detail=(
                        "Row has rich bound context ("
                        + ", ".join(context_bits)
                        + ") yet rendered text used zero dynamic references."
                    ),
                )
            )

        return flags

    def tag_row(self, row: dict[str, Any]) -> dict[str, Any]:
        """Analyze row, append flags and cluster keys, and update review state."""
        flags = self.analyze_row(row)
        flag_dicts = [f.to_dict() for f in flags]
        row.setdefault("quality", {})["flags"] = flag_dicts

        dyn_ctx = _extract_dynamic_context(row)
        flag_names = {f.name for f in flags}
        has_ungrounded = "UNGROUNDED_NAME_USE" in flag_names
        has_broken = "BROKEN_TOKEN_GRAMMAR" in flag_names
        has_opportunity = "DYNAMIC_GROUNDING_OPPORTUNITY" in flag_names
        used_dyn = bool(dyn_ctx["usedDynamicReference"])
        used_name = bool(dyn_ctx["usedName"])

        if has_ungrounded or has_broken:
            dg_status = "FAILED"
        elif used_dyn:
            dg_status = "DYNAMIC_GROUNDING_VERIFIED"
        elif has_opportunity:
            dg_status = "OPPORTUNITY"
        else:
            dg_status = "NO_DYNAMIC_TOKENS"

        row["quality"]["dynamicGrounding"] = {
            "status": dg_status,
            "usedDynamicReference": used_dyn,
            "usedName": used_name,
            "appropriateNameUse": bool(used_name and not has_ungrounded),
            "ungroundedName": has_ungrounded,
            "brokenTokenGrammar": has_broken,
            "groundingOpportunity": has_opportunity,
        }

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

    def summarize_dynamic_grounding(
        self, rows: Sequence[Mapping[str, Any]]
    ) -> dict[str, Any]:
        """Compute DYNAMIC_GROUNDING_VERIFIED summary counters across analyzed rows."""
        return summarize_dynamic_grounding(rows)

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

        self.last_dynamic_grounding_summary = self.summarize_dynamic_grounding(rows)
        return list(rows)
