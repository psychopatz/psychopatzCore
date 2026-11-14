"""ConvoEngine compact exchange-family normalization and runtime projection.

This module owns the compact ``psychopatz.convo-engine.v1`` exchange-family
authoring contract:

- family identity (``kind / namespace / id``) without wording-key expansion;
- direct single ``say`` shorthand and stable positive-integer ``say`` keys;
- named semantic ``reply`` outcomes with independent realizations;
- explicit runtime text-role normalization (``button_label``,
  ``spoken_action``, ``response``) with no ``button_label -> spoken_action``
  fallback;
- semantic references that cannot target wording realization keys.
"""

from __future__ import annotations

import copy
import math
import re
from collections.abc import Callable, Mapping
from typing import Any

from .errors import CompileError
from .translation_support import DEFAULT_LANGUAGE


TEXT_ROLE_BUTTON_LABEL = "button_label"
TEXT_ROLE_SPOKEN_ACTION = "spoken_action"
TEXT_ROLE_RESPONSE = "response"
RUNTIME_TEXT_ROLES = frozenset({
    TEXT_ROLE_BUTTON_LABEL,
    TEXT_ROLE_SPOKEN_ACTION,
    TEXT_ROLE_RESPONSE,
})

EXCHANGE_FAMILY_FIELDS = frozenset({
    "namespace",
    "invoke",
    "affordance",
    "say",
    "reply",
    "after",
})

MAX_SAY_REALIZATIONS = 32
MAX_REPLY_OUTCOMES = 16
MAX_RECOMMENDATIONS = 8
MAX_GROUPS = 16
MAX_UTILITY_DIMENSIONS = 16

_SEGMENT_RE = re.compile(r"^[a-z][a-z0-9_]{0,63}$")
_NAME_RE = re.compile(r"^[a-z][a-z0-9_]{0,31}$")
_ID_RE = re.compile(r"^[a-z][a-z0-9_.:-]{0,127}$")
_REALIZATION_KEY_RE = re.compile(r"^[1-9][0-9]*$")
_PLACEHOLDER_RE = re.compile(r"\{([a-z][a-zA-Z0-9_.]*)\}")
_FORBIDDEN_ID_PARTS = frozenset({
    "generated",
    "legacy",
    "compat",
    "old",
    "v1",
    "automatic_flow",
    "parameterized_task",
    "part02",
    "part03",
    "part04",
    "part05",
})


def _copy(value: Any) -> Any:
    return copy.deepcopy(value)


def _check_no_forbidden_parts(value: str, label: str) -> None:
    parts = set(re.split(r"[.:_-]+", value))
    if parts & _FORBIDDEN_ID_PARTS:
        raise CompileError(
            f"{label} contains a forbidden migration/implementation identity: {value!r}"
        )


def resolve_family_identity(
    namespace: Any,
    record_id: Any,
    *,
    strict_convo_engine: bool,
    label: str = "record",
) -> tuple[str, str | None, str]:
    """Resolve ``(canonical_id, namespace, local_id)`` for one ConvoEngine record.

    When ``namespace`` is provided, ``id`` must be a single non-numeric family
    segment and canonical identity is ``f"{namespace}.{id}"``.  Under
    ``psychopatz.convo-engine.v1``, family IDs never contain numeric wording
    key segments.
    """
    if not isinstance(record_id, str) or not record_id.strip():
        raise CompileError(f"{label}.id must be a bounded lowercase semantic ID")
    raw_id = record_id.strip()

    if namespace is not None:
        if not isinstance(namespace, str) or not namespace.strip():
            raise CompileError(f"{label}.namespace must be a dot-separated semantic namespace")
        ns = namespace.strip()
        ns_segments = ns.split(".")
        if any(not _SEGMENT_RE.fullmatch(seg) for seg in ns_segments):
            raise CompileError(
                f"{label}.namespace contains invalid or numeric segment: {ns!r}"
            )
        _check_no_forbidden_parts(ns, f"{label}.namespace")
        if not _SEGMENT_RE.fullmatch(raw_id):
            raise CompileError(
                f"{label}.id must be a single lowercase semantic segment when namespace is set: {raw_id!r}"
            )
        _check_no_forbidden_parts(raw_id, f"{label}.id")
        return f"{ns}.{raw_id}", ns, raw_id

    if not _ID_RE.fullmatch(raw_id):
        raise CompileError(f"{label}.id must be a bounded lowercase semantic ID")
    _check_no_forbidden_parts(raw_id, f"{label}.id")
    if strict_convo_engine:
        segments = raw_id.split(".")
        if any(not seg or seg.isdigit() for seg in segments):
            raise CompileError(
                f"{label}.id cannot encode numeric realization keys: {raw_id!r}"
            )
    return raw_id, None, raw_id


def validate_semantic_reference(value: Any, label: str) -> str:
    """Validate a semantic family/outcome reference that cannot target wording keys."""
    if not isinstance(value, str) or not value.strip():
        raise CompileError(f"{label} must be a semantic family reference")
    ref = value.strip()
    if ref.isdigit() or "#" in ref:
        raise CompileError(
            f"{label} cannot target a wording realization key: {ref!r}"
        )
    if not _ID_RE.fullmatch(ref):
        raise CompileError(f"{label} must be a bounded lowercase semantic ID: {ref!r}")
    _check_no_forbidden_parts(ref, label)
    segments = ref.split(".")
    for index, segment in enumerate(segments):
        if not segment or segment.isdigit():
            raise CompileError(
                f"{label} cannot target a numeric wording realization key: {ref!r}"
            )
        if segment == "say" and (
            index == len(segments) - 1
            or (index + 1 < len(segments) and segments[index + 1].isdigit())
        ):
            raise CompileError(
                f"{label} cannot target a say realization path: {ref!r}"
            )
    return ref


def normalize_compact_locale_text(
    value: Any,
    label: str,
    *,
    normalize_locale_text: Callable[..., dict[str, list[str]]],
    bindings: Mapping[str, Any],
    slots: Mapping[str, Any],
) -> dict[str, list[str]]:
    """Normalize either a single EN string shorthand or a full locale text map."""
    if isinstance(value, str):
        locale_map: Any = {DEFAULT_LANGUAGE: [value]}
    elif isinstance(value, Mapping):
        locale_map = value
    else:
        raise CompileError(
            f"{label} must be a string or locale text map (bare arrays are not allowed)"
        )
    normalized = normalize_locale_text(locale_map, label, bindings=bindings)
    _validate_slot_placeholders(normalized[DEFAULT_LANGUAGE], slots=slots, label=label)
    return normalized


def _validate_slot_placeholders(
    texts: list[str],
    *,
    slots: Mapping[str, Any],
    label: str,
) -> None:
    for text in texts:
        for placeholder in _PLACEHOLDER_RE.findall(text):
            if placeholder == "slot" or placeholder.startswith("slot."):
                parts = placeholder.split(".")
                if len(parts) < 2 or not parts[1]:
                    raise CompileError(f"{label} has invalid slot placeholder {{{placeholder}}}")
                slot_name = parts[1]
                if slot_name not in slots:
                    raise CompileError(
                        f"{label} references undeclared slot {slot_name!r} in {{{placeholder}}}"
                    )


def _validate_predicate_slot_paths(
    predicate: Any,
    *,
    slots: Mapping[str, Any],
    label: str,
) -> None:
    if predicate is None:
        return
    if "all" in predicate or "any" in predicate:
        key = "all" if "all" in predicate else "any"
        for index, child in enumerate(predicate[key]):
            _validate_predicate_slot_paths(child, slots=slots, label=f"{label}.{key}[{index}]")
        return
    if "not" in predicate:
        _validate_predicate_slot_paths(predicate["not"], slots=slots, label=f"{label}.not")
        return
    path = str(predicate.get("path", predicate.get("field", "")))
    if path.startswith("slot."):
        parts = path.split(".")
        if len(parts) < 2 or parts[1] not in slots:
            raise CompileError(f"{label} references undeclared slot in path {path!r}")


def _normalize_realization_variants(
    raw_variants: Any,
    label: str,
    *,
    normalize_locale_text: Callable[..., dict[str, list[str]]],
    normalize_predicate: Callable[[Any, str], Any],
    bindings: Mapping[str, Any],
    slots: Mapping[str, Any],
) -> list[dict[str, Any]]:
    if not isinstance(raw_variants, list) or not raw_variants or len(raw_variants) > 32:
        raise CompileError(f"{label} must contain 1..32 style/context variants")
    variants: list[dict[str, Any]] = []
    seen_ids: set[str] = set()
    for index, raw in enumerate(raw_variants):
        if not isinstance(raw, Mapping):
            raise CompileError(f"{label}[{index}] must be a variant object")
        allowed = {"id", "when", "text", "say", "metadata"}
        unsupported = set(raw) - allowed
        if unsupported:
            raise CompileError(
                f"{label}[{index}] contains unsupported variant fields: "
                + ", ".join(sorted(str(item) for item in unsupported))
            )
        if "text" in raw and "say" in raw:
            raise CompileError(f"{label}[{index}] cannot define both text and say")
        raw_text = raw.get("text", raw.get("say"))
        if raw_text is None:
            raise CompileError(f"{label}[{index}] requires text or say")
        variant_id_raw = raw.get("id")
        if variant_id_raw is not None:
            if not isinstance(variant_id_raw, str) or not _ID_RE.fullmatch(variant_id_raw.strip()):
                raise CompileError(f"{label}[{index}].id must be a valid semantic variant ID")
            variant_id = variant_id_raw.strip()
        else:
            variant_id = f"variant_{index + 1}"
        if variant_id in seen_ids:
            raise CompileError(f"{label} repeats variant id {variant_id!r}")
        seen_ids.add(variant_id)
        item: dict[str, Any] = {
            "id": variant_id,
            "text": normalize_compact_locale_text(
                raw_text,
                f"{label}[{index}].text",
                normalize_locale_text=normalize_locale_text,
                bindings=bindings,
                slots=slots,
            ),
        }
        if "when" in raw:
            predicate = normalize_predicate(raw["when"], f"{label}[{index}].when")
            _validate_predicate_slot_paths(predicate, slots=slots, label=f"{label}[{index}].when")
            item["when"] = predicate
        if "metadata" in raw:
            if not isinstance(raw["metadata"], Mapping):
                raise CompileError(f"{label}[{index}].metadata must be an object")
            item["metadata"] = _copy(raw["metadata"])
        variants.append(item)
    return variants


def _normalize_single_realization_entry(
    value: Any,
    key: str,
    label: str,
    *,
    shorthand: bool,
    normalize_locale_text: Callable[..., dict[str, list[str]]],
    normalize_predicate: Callable[[Any, str], Any],
    bindings: Mapping[str, Any],
    slots: Mapping[str, Any],
) -> dict[str, Any]:
    if isinstance(value, str):
        variants = [{
            "id": "default",
            "text": normalize_compact_locale_text(
                value,
                label,
                normalize_locale_text=normalize_locale_text,
                bindings=bindings,
                slots=slots,
            ),
        }]
        return {"key": key, "shorthand": shorthand, "variants": variants}

    if not isinstance(value, Mapping) or not value:
        raise CompileError(
            f"{label} must be a string, locale map, or variant object (bare arrays are not allowed)"
        )

    if "variants" in value:
        unsupported = set(value) - {"variants", "metadata"}
        if unsupported:
            raise CompileError(
                f"{label} contains unsupported realization fields: "
                + ", ".join(sorted(str(item) for item in unsupported))
            )
        entry: dict[str, Any] = {
            "key": key,
            "shorthand": shorthand,
            "variants": _normalize_realization_variants(
                value["variants"],
                f"{label}.variants",
                normalize_locale_text=normalize_locale_text,
                normalize_predicate=normalize_predicate,
                bindings=bindings,
                slots=slots,
            ),
        }
        if "metadata" in value:
            if not isinstance(value["metadata"], Mapping):
                raise CompileError(f"{label}.metadata must be an object")
            entry["metadata"] = _copy(value["metadata"])
        return entry

    if "text" in value or "when" in value:
        unsupported = set(value) - {"id", "when", "text", "metadata"}
        if unsupported:
            raise CompileError(
                f"{label} contains unsupported realization fields: "
                + ", ".join(sorted(str(item) for item in unsupported))
            )
        if "text" not in value:
            raise CompileError(f"{label}.text is required")
        return {
            "key": key,
            "shorthand": shorthand,
            "variants": _normalize_realization_variants(
                [value],
                f"{label}.variants",
                normalize_locale_text=normalize_locale_text,
                normalize_predicate=normalize_predicate,
                bindings=bindings,
                slots=slots,
            ),
        }

    # Otherwise, must be a locale map like {"EN": "...", "TL": "..."}
    text = normalize_compact_locale_text(
        value,
        label,
        normalize_locale_text=normalize_locale_text,
        bindings=bindings,
        slots=slots,
    )
    return {
        "key": key,
        "shorthand": shorthand,
        "variants": [{"id": "default", "text": text}],
    }


def normalize_say_realizations(
    value: Any,
    label: str,
    *,
    text_role: str,
    normalize_locale_text: Callable[..., dict[str, list[str]]],
    normalize_predicate: Callable[[Any, str], Any],
    bindings: Mapping[str, Any],
    slots: Mapping[str, Any],
) -> dict[str, Any]:
    """Normalize direct single ``say`` or stable numeric-keyed ``say`` realizations."""
    if text_role not in {TEXT_ROLE_SPOKEN_ACTION, TEXT_ROLE_RESPONSE}:
        raise CompileError(f"{label} has invalid say text role {text_role!r}")

    if isinstance(value, str):
        entry = _normalize_single_realization_entry(
            value,
            "1",
            label,
            shorthand=True,
            normalize_locale_text=normalize_locale_text,
            normalize_predicate=normalize_predicate,
            bindings=bindings,
            slots=slots,
        )
        return {
            "textRole": text_role,
            "mode": "single",
            "keyOrder": ["1"],
            "realizations": {"1": entry},
        }

    if not isinstance(value, Mapping) or not value:
        raise CompileError(
            f"{label} must be a non-empty string, locale map, or numeric-keyed realization map"
        )

    # Check if this is a single-realization variants container or locale map vs numeric-keyed map.
    if "variants" in value or "text" in value or "when" in value:
        entry = _normalize_single_realization_entry(
            value,
            "1",
            label,
            shorthand=True,
            normalize_locale_text=normalize_locale_text,
            normalize_predicate=normalize_predicate,
            bindings=bindings,
            slots=slots,
        )
        return {
            "textRole": text_role,
            "mode": "single",
            "keyOrder": ["1"],
            "realizations": {"1": entry},
        }

    has_numeric_or_digit_key = any(
        isinstance(k, int) or (isinstance(k, str) and (k.isdigit() or k.startswith("-")))
        for k in value
    )
    # If all keys look like locale codes (2-3 letter/region strings) and none are numeric/digit:
    if not has_numeric_or_digit_key:
        # Try as a locale map; if someone wrote {"warm": "..."} this will fail cleanly in normalize_language.
        try:
            entry = _normalize_single_realization_entry(
                value,
                "1",
                label,
                shorthand=True,
                normalize_locale_text=normalize_locale_text,
                normalize_predicate=normalize_predicate,
                bindings=bindings,
                slots=slots,
            )
            return {
                "textRole": text_role,
                "mode": "single",
                "keyOrder": ["1"],
                "realizations": {"1": entry},
            }
        except CompileError as error:
            raise CompileError(
                f"{label} keys must be valid locales (single realization) or positive integer strings '1', '2', ... ({error})"
            ) from error

    if len(value) > MAX_SAY_REALIZATIONS:
        raise CompileError(f"{label} cannot exceed {MAX_SAY_REALIZATIONS} realization keys")

    realizations: dict[str, dict[str, Any]] = {}
    for raw_key in value:
        if not isinstance(raw_key, str) or not _REALIZATION_KEY_RE.fullmatch(raw_key):
            raise CompileError(
                f"{label} contains invalid realization key {raw_key!r}; keys must be positive integer strings without leading zeros"
            )
        realizations[raw_key] = _normalize_single_realization_entry(
            value[raw_key],
            raw_key,
            f"{label}.{raw_key}",
            shorthand=False,
            normalize_locale_text=normalize_locale_text,
            normalize_predicate=normalize_predicate,
            bindings=bindings,
            slots=slots,
        )

    key_order = sorted(realizations, key=lambda item: int(item))
    return {
        "textRole": text_role,
        "mode": "keyed",
        "keyOrder": key_order,
        "realizations": {key: realizations[key] for key in key_order},
    }


def _normalize_invoke(value: Any, label: str, *, slots: Mapping[str, Any]) -> dict[str, Any]:
    if not isinstance(value, Mapping) or not value:
        raise CompileError(f"{label} must be a non-empty semantic invoke object")
    allowed = {
        "intent",
        "speechAct",
        "subject",
        "topic",
        "action",
        "target",
        "patternID",
        "extensions",
        "metadata",
    }
    unsupported = set(value) - allowed
    if unsupported:
        raise CompileError(
            f"{label} contains unsupported fields: "
            + ", ".join(sorted(str(item) for item in unsupported))
        )
    if not any(
        field in value
        for field in ("intent", "speechAct", "subject", "topic", "action", "patternID")
    ):
        raise CompileError(
            f"{label} requires at least one semantic field (intent, speechAct, subject, topic, action, or patternID)"
        )
    output: dict[str, Any] = {}
    for field in ("intent", "speechAct", "subject", "topic", "action", "patternID"):
        if field in value:
            token = value[field]
            if not isinstance(token, str) or not token.strip():
                raise CompileError(f"{label}.{field} must be a non-empty semantic token")
            output[field] = token.strip()
    if "target" in value:
        target = value["target"]
        if not isinstance(target, str) or not target.strip():
            raise CompileError(f"{label}.target must be a bounded slot or entity reference")
        target = target.strip()
        if target.startswith("$slot."):
            slot_name = target[len("$slot."):].split(".", 1)[0]
            if slot_name not in slots:
                raise CompileError(f"{label}.target references undeclared slot {slot_name!r}")
        elif target.startswith("$"):
            raise CompileError(f"{label}.target has unsupported binding prefix: {target!r}")
        output["target"] = target
    for field in ("extensions", "metadata"):
        if field in value:
            if not isinstance(value[field], Mapping):
                raise CompileError(f"{label}.{field} must be an object")
            output[field] = _copy(value[field])
    return output


def _normalize_affordance(
    value: Any,
    label: str,
    *,
    normalize_locale_text: Callable[..., dict[str, list[str]]],
    normalize_predicate: Callable[[Any, str], Any],
    bindings: Mapping[str, Any],
    slots: Mapping[str, Any],
    consumers: frozenset[str],
) -> dict[str, Any]:
    if not isinstance(value, Mapping):
        raise CompileError(f"{label} must be an object")
    allowed = {"label", "consumers", "groups", "priority", "utility", "when", "metadata"}
    unsupported = set(value) - allowed
    if unsupported:
        raise CompileError(
            f"{label} contains unsupported fields: "
            + ", ".join(sorted(str(item) for item in unsupported))
        )
    if "label" not in value:
        raise CompileError(f"{label}.label is required")
    normalized_label = normalize_compact_locale_text(
        value["label"],
        f"{label}.label",
        normalize_locale_text=normalize_locale_text,
        bindings=bindings,
        slots=slots,
    )
    raw_consumers = value.get("consumers", ["participant"])
    if not isinstance(raw_consumers, list) or not raw_consumers or len(raw_consumers) > 3:
        raise CompileError(f"{label}.consumers must contain 1..3 consumers")
    if any(item not in consumers for item in raw_consumers) or len(set(raw_consumers)) != len(raw_consumers):
        raise CompileError(f"{label}.consumers contains an unsupported or duplicate consumer")
    output: dict[str, Any] = {
        "textRole": TEXT_ROLE_BUTTON_LABEL,
        "label": normalized_label,
        "consumers": list(raw_consumers),
    }
    if "groups" in value:
        groups = value["groups"]
        if not isinstance(groups, list) or not groups or len(groups) > MAX_GROUPS:
            raise CompileError(f"{label}.groups must contain 1..{MAX_GROUPS} group IDs")
        normalized_groups: list[str] = []
        for group in groups:
            if not isinstance(group, str) or not _ID_RE.fullmatch(group.strip()):
                raise CompileError(f"{label}.groups contains invalid group ID {group!r}")
            g = group.strip()
            _check_no_forbidden_parts(g, f"{label}.groups")
            if g not in normalized_groups:
                normalized_groups.append(g)
        output["groups"] = normalized_groups
    if "priority" in value:
        priority = value["priority"]
        if isinstance(priority, bool) or not isinstance(priority, (int, float)) or not math.isfinite(priority):
            raise CompileError(f"{label}.priority must be a finite number")
        output["priority"] = priority
    if "utility" in value:
        utility = value["utility"]
        if not isinstance(utility, Mapping) or len(utility) > MAX_UTILITY_DIMENSIONS:
            raise CompileError(f"{label}.utility must be a bounded motivation map")
        normalized_utility: dict[str, float] = {}
        for dim, weight in sorted(utility.items(), key=lambda item: str(item[0])):
            if not isinstance(dim, str) or not _NAME_RE.fullmatch(dim):
                raise CompileError(f"{label}.utility contains invalid dimension {dim!r}")
            if isinstance(weight, bool) or not isinstance(weight, (int, float)) or not math.isfinite(weight):
                raise CompileError(f"{label}.utility.{dim} must be a finite number")
            if weight < -10.0 or weight > 10.0:
                raise CompileError(f"{label}.utility.{dim} must be within [-10, 10]")
            normalized_utility[dim] = float(weight)
        output["utility"] = normalized_utility
    if "when" in value:
        predicate = normalize_predicate(value["when"], f"{label}.when")
        _validate_predicate_slot_paths(predicate, slots=slots, label=f"{label}.when")
        output["when"] = predicate
    if "metadata" in value:
        if not isinstance(value["metadata"], Mapping):
            raise CompileError(f"{label}.metadata must be an object")
        output["metadata"] = _copy(value["metadata"])
    return output


def _normalize_after(
    value: Any,
    label: str,
    *,
    normalize_transition: Callable[[Any, str], Any],
) -> dict[str, Any]:
    if not isinstance(value, Mapping) or not value:
        raise CompileError(f"{label} must be a non-empty continuation object")
    allowed = {"recommend", "goto", "end", "resume", "transition"}
    unsupported = set(value) - allowed
    if unsupported:
        raise CompileError(
            f"{label} contains unsupported fields: "
            + ", ".join(sorted(str(item) for item in unsupported))
        )
    output: dict[str, Any] = {}
    if "recommend" in value:
        rec = value["recommend"]
        if isinstance(rec, list):
            if not rec or len(rec) > MAX_RECOMMENDATIONS:
                raise CompileError(
                    f"{label}.recommend must contain 1..{MAX_RECOMMENDATIONS} semantic family IDs"
                )
            output["recommend"] = [
                validate_semantic_reference(item, f"{label}.recommend[{idx}]")
                for idx, item in enumerate(rec)
            ]
        elif isinstance(rec, Mapping):
            if set(rec) - {"group", "limit"} or "group" not in rec:
                raise CompileError(f"{label}.recommend query must declare group and optional limit")
            group = rec["group"]
            if not isinstance(group, str) or not _ID_RE.fullmatch(group.strip()):
                raise CompileError(f"{label}.recommend.group must be a semantic group ID")
            limit = rec.get("limit", MAX_RECOMMENDATIONS)
            if isinstance(limit, bool) or not isinstance(limit, int) or limit < 1 or limit > MAX_RECOMMENDATIONS:
                raise CompileError(f"{label}.recommend.limit must be 1..{MAX_RECOMMENDATIONS}")
            output["recommend"] = {"group": group.strip(), "limit": limit}
        else:
            raise CompileError(f"{label}.recommend must be a family list or group query")
    if "goto" in value:
        output["goto"] = validate_semantic_reference(value["goto"], f"{label}.goto")
    if "end" in value:
        if value["end"] is not True:
            raise CompileError(f"{label}.end must be true when present")
        output["end"] = True
    if "resume" in value:
        if value["resume"] is not True:
            raise CompileError(f"{label}.resume must be true when present")
        output["resume"] = True
    if "transition" in value:
        output["transition"] = normalize_transition(value["transition"], f"{label}.transition")
    if output.get("end") and any(key in output for key in ("goto", "recommend", "resume")):
        raise CompileError(f"{label}.end cannot be combined with goto, recommend, or resume")
    return output


def normalize_reply_outcomes(
    value: Any,
    label: str,
    *,
    normalize_locale_text: Callable[..., dict[str, list[str]]],
    normalize_predicate: Callable[[Any, str], Any],
    normalize_transition: Callable[[Any, str], Any],
    normalize_turn: Callable[..., dict[str, Any]],
    bindings: Mapping[str, Any],
    slots: Mapping[str, Any],
) -> dict[str, dict[str, Any]]:
    """Normalize named semantic ``reply`` outcomes with independent realizations."""
    if not isinstance(value, Mapping) or not value:
        raise CompileError(f"{label} must be a non-empty object keyed by outcome name")
    if len(value) > MAX_REPLY_OUTCOMES:
        raise CompileError(f"{label} cannot exceed {MAX_REPLY_OUTCOMES} outcomes")
    outcomes: dict[str, dict[str, Any]] = {}
    for raw_name in sorted(value, key=lambda item: str(item)):
        if not isinstance(raw_name, str) or not _NAME_RE.fullmatch(raw_name):
            raise CompileError(
                f"{label} contains invalid outcome name {raw_name!r}; outcome keys must be semantic identifiers"
            )
        _check_no_forbidden_parts(raw_name, f"{label}.{raw_name}")
        branch = value[raw_name]
        if not isinstance(branch, Mapping):
            raise CompileError(f"{label}.{raw_name} must be an object")
        allowed = {"when", "say", "turns", "variants", "act", "after", "metadata"}
        unsupported = set(branch) - allowed
        if unsupported:
            raise CompileError(
                f"{label}.{raw_name} contains unsupported fields: "
                + ", ".join(sorted(str(item) for item in unsupported))
            )
        if not any(field in branch for field in ("say", "turns", "variants")):
            raise CompileError(f"{label}.{raw_name} requires say, turns, or variants")
        if "say" in branch and "variants" in branch:
            raise CompileError(
                f"{label}.{raw_name} cannot define both top-level say and variants; nest variants under say.<key>"
            )
        normalized: dict[str, Any] = {
            "outcome": raw_name,
            "textRole": TEXT_ROLE_RESPONSE,
        }
        if "when" in branch:
            predicate = normalize_predicate(branch["when"], f"{label}.{raw_name}.when")
            _validate_predicate_slot_paths(predicate, slots=slots, label=f"{label}.{raw_name}.when")
            normalized["when"] = predicate
        if "act" in branch:
            act = branch["act"]
            if not isinstance(act, str) or not act.strip():
                raise CompileError(f"{label}.{raw_name}.act must be a semantic act")
            normalized["act"] = act.strip()
        if "say" in branch:
            normalized["say"] = normalize_say_realizations(
                branch["say"],
                f"{label}.{raw_name}.say",
                text_role=TEXT_ROLE_RESPONSE,
                normalize_locale_text=normalize_locale_text,
                normalize_predicate=normalize_predicate,
                bindings=bindings,
                slots=slots,
            )
        if "variants" in branch:
            normalized["variants"] = _normalize_realization_variants(
                branch["variants"],
                f"{label}.{raw_name}.variants",
                normalize_locale_text=normalize_locale_text,
                normalize_predicate=normalize_predicate,
                bindings=bindings,
                slots=slots,
            )
        if "turns" in branch:
            raw_turns = branch["turns"]
            if not isinstance(raw_turns, list) or not raw_turns or len(raw_turns) > 4:
                raise CompileError(f"{label}.{raw_name}.turns must contain 1..4 turns")
            normalized["turns"] = [
                {
                    **normalize_turn(turn, f"{label}.{raw_name}.turns[{idx}]", bindings=bindings),
                    "textRole": TEXT_ROLE_RESPONSE,
                }
                for idx, turn in enumerate(raw_turns)
            ]
        if "after" in branch:
            normalized["after"] = _normalize_after(
                branch["after"],
                f"{label}.{raw_name}.after",
                normalize_transition=normalize_transition,
            )
        if "metadata" in branch:
            if not isinstance(branch["metadata"], Mapping):
                raise CompileError(f"{label}.{raw_name}.metadata must be an object")
            normalized["metadata"] = _copy(branch["metadata"])
        outcomes[raw_name] = normalized
    return outcomes


def normalize_exchange_family_payload(
    payload: dict[str, Any],
    *,
    label: str,
    slots: Mapping[str, Any],
    bindings: Mapping[str, Any],
    normalize_locale_text: Callable[..., dict[str, list[str]]],
    normalize_predicate: Callable[[Any, str], Any],
    normalize_transition: Callable[[Any, str], Any],
    normalize_turn: Callable[..., dict[str, Any]],
    consumers: frozenset[str],
) -> dict[str, Any]:
    """Normalize exchange-family fields in place on a dialogue payload."""
    if "invoke" in payload:
        payload["invoke"] = _normalize_invoke(payload["invoke"], f"{label}.invoke", slots=slots)
    if "affordance" in payload:
        payload["affordance"] = _normalize_affordance(
            payload["affordance"],
            f"{label}.affordance",
            normalize_locale_text=normalize_locale_text,
            normalize_predicate=normalize_predicate,
            bindings=bindings,
            slots=slots,
            consumers=consumers,
        )
        if "say" not in payload and not any(
            field in payload for field in ("respond", "response", "variants", "turns")
        ):
            raise CompileError(
                f"{label}.say is required when affordance is declared; affordance.label (button_label) cannot fall back to spoken_action"
            )
    if "say" in payload:
        payload["say"] = normalize_say_realizations(
            payload["say"],
            f"{label}.say",
            text_role=TEXT_ROLE_SPOKEN_ACTION,
            normalize_locale_text=normalize_locale_text,
            normalize_predicate=normalize_predicate,
            bindings=bindings,
            slots=slots,
        )
    if "reply" in payload:
        payload["reply"] = normalize_reply_outcomes(
            payload["reply"],
            f"{label}.reply",
            normalize_locale_text=normalize_locale_text,
            normalize_predicate=normalize_predicate,
            normalize_transition=normalize_transition,
            normalize_turn=normalize_turn,
            bindings=bindings,
            slots=slots,
        )
    if "after" in payload:
        payload["after"] = _normalize_after(
            payload["after"],
            f"{label}.after",
            normalize_transition=normalize_transition,
        )
    return payload


def _project_realizations_runtime(
    say_block: Mapping[str, Any],
    *,
    key_prefix: str,
) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    text_role = str(say_block["textRole"])
    key_order = list(say_block.get("keyOrder") or [])
    projected: dict[str, Any] = {}
    text_entries: list[dict[str, Any]] = []
    for rkey in key_order:
        entry = say_block["realizations"][rkey]
        projected_variants: list[dict[str, Any]] = []
        for variant in entry["variants"]:
            template_id = f"{key_prefix}.{rkey}.{variant['id']}"
            text = variant["text"]
            projected_variant: dict[str, Any] = {
                "id": variant["id"],
                "templateID": template_id,
                "textRole": text_role,
                "fallback": text[DEFAULT_LANGUAGE][0],
                "translations": _copy(text),
            }
            if "when" in variant:
                projected_variant["when"] = _copy(variant["when"])
            projected_variants.append(projected_variant)
            text_entries.append({
                "role": text_role,
                "realizationKey": rkey,
                "variantID": variant["id"],
                "templateID": template_id,
                "fallback": text[DEFAULT_LANGUAGE][0],
                "translations": _copy(text),
            })
        projected[rkey] = {
            "key": rkey,
            "shorthand": bool(entry.get("shorthand")),
            "variants": projected_variants,
        }
    return {
        "textRole": text_role,
        "mode": say_block.get("mode", "single"),
        "keyOrder": key_order,
        "realizations": projected,
    }, text_entries


def project_exchange_family_runtime(record: Mapping[str, Any]) -> dict[str, Any] | None:
    """Project a compiled ConvoEngine exchange family to explicit runtime structures."""
    payload = record.get("payload") or {}
    if not any(field in payload for field in ("invoke", "affordance", "say", "reply", "after")):
        return None

    family_id = str(record["id"])
    text_entries: list[dict[str, Any]] = []
    projection: dict[str, Any] = {
        "familyID": family_id,
    }
    if "namespace" in record:
        projection["namespace"] = record["namespace"]
    if record.get("slots"):
        projection["slots"] = _copy(record["slots"])
    if "invoke" in payload:
        projection["invoke"] = _copy(payload["invoke"])
    if "affordance" in payload:
        aff = payload["affordance"]
        label_text = aff["label"]
        label_key = f"convo.{family_id}.affordance.label"
        projection["affordance"] = {
            "textRole": TEXT_ROLE_BUTTON_LABEL,
            "labelKey": label_key,
            "labelFallback": label_text[DEFAULT_LANGUAGE][0],
            "translations": _copy(label_text),
            "consumers": list(aff["consumers"]),
        }
        for opt in ("groups", "priority", "utility", "when", "metadata"):
            if opt in aff:
                projection["affordance"][opt] = _copy(aff[opt])
        text_entries.append({
            "role": TEXT_ROLE_BUTTON_LABEL,
            "templateID": label_key,
            "fallback": label_text[DEFAULT_LANGUAGE][0],
            "translations": _copy(label_text),
        })
    if "say" in payload:
        say_proj, say_entries = _project_realizations_runtime(
            payload["say"],
            key_prefix=f"convo.{family_id}.say",
        )
        projection["initiatingSay"] = say_proj
        text_entries.extend(say_entries)
    if "reply" in payload:
        replies_proj: dict[str, Any] = {}
        for outcome_name, branch in payload["reply"].items():
            branch_proj: dict[str, Any] = {
                "outcome": outcome_name,
                "textRole": TEXT_ROLE_RESPONSE,
            }
            if "when" in branch:
                branch_proj["when"] = _copy(branch["when"])
            if "act" in branch:
                branch_proj["act"] = branch["act"]
            if "say" in branch:
                reply_say_proj, reply_entries = _project_realizations_runtime(
                    branch["say"],
                    key_prefix=f"convo.{family_id}.reply.{outcome_name}.say",
                )
                for entry in reply_entries:
                    entry["outcome"] = outcome_name
                branch_proj["say"] = reply_say_proj
                text_entries.extend(reply_entries)
            if "variants" in branch:
                variant_projs: list[dict[str, Any]] = []
                for variant in branch["variants"]:
                    template_id = f"convo.{family_id}.reply.{outcome_name}.{variant['id']}"
                    text = variant["text"]
                    v_item = {
                        "id": variant["id"],
                        "templateID": template_id,
                        "textRole": TEXT_ROLE_RESPONSE,
                        "fallback": text[DEFAULT_LANGUAGE][0],
                        "translations": _copy(text),
                    }
                    if "when" in variant:
                        v_item["when"] = _copy(variant["when"])
                    variant_projs.append(v_item)
                    text_entries.append({
                        "role": TEXT_ROLE_RESPONSE,
                        "outcome": outcome_name,
                        "variantID": variant["id"],
                        "templateID": template_id,
                        "fallback": text[DEFAULT_LANGUAGE][0],
                        "translations": _copy(text),
                    })
                branch_proj["variants"] = variant_projs
            if "after" in branch:
                branch_proj["after"] = _copy(branch["after"])
            replies_proj[outcome_name] = branch_proj
        projection["replies"] = replies_proj
    if "after" in payload:
        projection["after"] = _copy(payload["after"])
    projection["textRoles"] = text_entries
    return projection


def collect_semantic_references(record: Mapping[str, Any]) -> list[tuple[str, str]]:
    """Return ``(field_label, ref)`` pairs for semantic cross-reference checks."""
    refs: list[tuple[str, str]] = []
    record_id = str(record.get("id") or "record")
    payload = record.get("payload") or {}
    if not isinstance(payload, Mapping):
        return refs

    def _collect_after(after: Any, prefix: str) -> None:
        if not isinstance(after, Mapping):
            return
        if "goto" in after and isinstance(after["goto"], str):
            refs.append((f"{prefix}.goto", after["goto"]))
        if isinstance(after.get("recommend"), list):
            for idx, target in enumerate(after["recommend"]):
                if isinstance(target, str):
                    refs.append((f"{prefix}.recommend[{idx}]", target))

    _collect_after(payload.get("after"), f"{record_id}.after")
    reply = payload.get("reply")
    if isinstance(reply, Mapping):
        for outcome_name, branch in reply.items():
            if isinstance(branch, Mapping):
                _collect_after(branch.get("after"), f"{record_id}.reply.{outcome_name}.after")
    if isinstance(payload.get("respondWith"), str):
        refs.append((f"{record_id}.respondWith", payload["respondWith"]))
    if isinstance(payload.get("candidates"), list):
        for idx, candidate in enumerate(payload["candidates"]):
            if isinstance(candidate, Mapping) and isinstance(candidate.get("behavior"), str):
                refs.append((f"{record_id}.candidates[{idx}].behavior", candidate["behavior"]))
    return refs


def collect_disallowed_realization_targets(record: Mapping[str, Any]) -> set[str]:
    """Return wording-keyed identifiers that semantic callers must never target."""
    disallowed: set[str] = set()
    family_id = str(record.get("id") or "")
    payload = record.get("payload") or {}
    if not family_id or not isinstance(payload, Mapping):
        return disallowed

    say = payload.get("say")
    if isinstance(say, Mapping) and isinstance(say.get("realizations"), Mapping):
        for rkey in say["realizations"]:
            disallowed.add(f"{family_id}.{rkey}")
            disallowed.add(f"{family_id}.say.{rkey}")

    reply = payload.get("reply")
    if isinstance(reply, Mapping):
        for outcome_name, branch in reply.items():
            if not isinstance(branch, Mapping):
                continue
            reply_say = branch.get("say")
            if isinstance(reply_say, Mapping) and isinstance(reply_say.get("realizations"), Mapping):
                for rkey in reply_say["realizations"]:
                    disallowed.add(f"{family_id}.{rkey}")
                    disallowed.add(f"{family_id}.reply.{outcome_name}.{rkey}")
                    disallowed.add(f"{family_id}.reply.{outcome_name}.say.{rkey}")
    return disallowed


__all__ = [
    "EXCHANGE_FAMILY_FIELDS",
    "RUNTIME_TEXT_ROLES",
    "TEXT_ROLE_BUTTON_LABEL",
    "TEXT_ROLE_RESPONSE",
    "TEXT_ROLE_SPOKEN_ACTION",
    "collect_disallowed_realization_targets",
    "collect_semantic_references",
    "normalize_compact_locale_text",
    "normalize_exchange_family_payload",
    "normalize_reply_outcomes",
    "normalize_say_realizations",
    "project_exchange_family_runtime",
    "resolve_family_identity",
    "validate_semantic_reference",
]
