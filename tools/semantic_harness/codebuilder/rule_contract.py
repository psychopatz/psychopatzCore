"""Provider-neutral validation for bounded typed-rule structures."""

from __future__ import annotations

import math
import re
from collections.abc import Collection
from typing import Any

from .errors import CompileError


_PREDICATE_FIELDS = {
    "all",
    "any",
    "not",
    "path",
    "field",
    "op",
    "value",
    "values",
}
_ARGUMENT_NAME = re.compile(r"[a-z][a-zA-Z0-9_]{0,31}")


def validate_source_refs(
    value: Any,
    available: Collection[str],
    label: str,
    *,
    maximum: int = 4,
) -> list[str]:
    """Validate a bounded list of references against an available manifest."""
    if not isinstance(value, list) or not value or len(value) > maximum:
        raise CompileError(f"{label} requires 1 to {maximum} source references")
    normalized: list[str] = []
    for item in value:
        if not isinstance(item, str) or not item.strip():
            raise CompileError(f"{label} contains an invalid source reference")
        item = item.strip()
        if item not in available:
            raise CompileError(f"{label} references unknown source {item!r}")
        if item not in normalized:
            normalized.append(item)
    return normalized


def validate_predicate(
    value: Any,
    label: str,
    depth: int = 0,
    *,
    max_depth: int = 6,
    max_items: int = 8,
) -> Any:
    """Validate a bounded all/any/not predicate AST without evaluating it."""
    if depth > max_depth or not isinstance(value, dict):
        raise CompileError(f"{label} must be a bounded predicate object")
    unsupported = set(value) - _PREDICATE_FIELDS
    if unsupported:
        raise CompileError(
            f"{label} contains unsupported predicate fields: "
            + ", ".join(sorted(unsupported))
        )
    structural = [key for key in ("all", "any", "not") if key in value]
    has_leaf = "path" in value or "field" in value
    if len(structural) > 1 or (structural and has_leaf) or (
        not structural and not has_leaf
    ):
        raise CompileError(f"{label} has an invalid predicate shape")
    if structural and any(
        key in value for key in ("path", "field", "op", "value", "values")
    ):
        raise CompileError(f"{label} combines a group with a leaf predicate")
    for key in ("all", "any"):
        if key in value:
            items = value[key]
            if not isinstance(items, list) or not items or len(items) > max_items:
                raise CompileError(
                    f"{label}.{key} must contain 1..{max_items} predicates"
                )
            value[key] = [
                validate_predicate(
                    item,
                    f"{label}.{key}[{index}]",
                    depth + 1,
                    max_depth=max_depth,
                    max_items=max_items,
                )
                for index, item in enumerate(items)
            ]
    if "not" in value:
        value["not"] = validate_predicate(
            value["not"],
            f"{label}.not",
            depth + 1,
            max_depth=max_depth,
            max_items=max_items,
        )
    if "path" in value and "field" in value:
        raise CompileError(f"{label} cannot contain both path and field")
    for key in ("path", "field", "op"):
        if key in value and (not isinstance(value[key], str) or not value[key]):
            raise CompileError(f"{label}.{key} must be a non-empty string")
    if "values" in value:
        values = value["values"]
        if not isinstance(values, list) or len(values) > max_items:
            raise CompileError(
                f"{label}.values must contain at most {max_items} values"
            )
        if any(
            not isinstance(item, (str, int, float, bool)) or item is None
            for item in values
        ):
            raise CompileError(f"{label}.values must contain scalar values")
    if "value" in value and (
        not isinstance(value["value"], (str, int, float, bool))
        or value["value"] is None
    ):
        raise CompileError(f"{label}.value must be a scalar value")
    return value


def validate_typed_arguments(
    value: Any,
    label: str,
    allowed_types: Collection[str],
    *,
    maximum: int = 8,
) -> dict[str, str]:
    """Validate sorted, declarative argument-name/type mappings."""
    if value is None:
        return {}
    if not isinstance(value, dict) or len(value) > maximum:
        raise CompileError(f"{label} must contain at most {maximum} typed arguments")
    output: dict[str, str] = {}
    for name, argument_type in value.items():
        if (
            not isinstance(name, str)
            or not _ARGUMENT_NAME.fullmatch(name)
            or not isinstance(argument_type, str)
            or argument_type not in allowed_types
        ):
            raise CompileError(f"{label} contains an invalid typed argument {name!r}")
        output[name] = argument_type
    return {name: output[name] for name in sorted(output)}


def validate_scalar_conditions(
    value: Any,
    context: str,
    allowed_fields: Collection[str],
    *,
    maximum: int = 8,
    maximum_string_length: int = 96,
) -> dict[str, Any]:
    """Validate scalar condition fields while leaving field policy to adopters."""
    if value is None:
        return {}
    if not isinstance(value, dict):
        raise CompileError(f"response condition for {context} must be an object")
    output: dict[str, Any] = {}
    for field, expected in value.items():
        if field not in allowed_fields:
            raise CompileError(
                f"unsupported response condition {field!r} for {context}"
            )
        values = expected if isinstance(expected, list) else [expected]
        if not values or len(values) > maximum:
            raise CompileError(
                f"response condition {field!r} for {context} is empty or too broad"
            )
        for item in values:
            if isinstance(item, str):
                if not item or len(item) > maximum_string_length:
                    raise CompileError(
                        f"response condition value for {context} is invalid"
                    )
            elif isinstance(item, bool):
                pass
            elif isinstance(item, (int, float)) and math.isfinite(item):
                pass
            else:
                raise CompileError(
                    f"response condition value for {context} must be scalar"
                )
        output[field] = values if isinstance(expected, list) else expected
    return output


__all__ = [
    "validate_predicate",
    "validate_scalar_conditions",
    "validate_source_refs",
    "validate_typed_arguments",
]
