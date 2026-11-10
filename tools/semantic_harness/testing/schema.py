"""Unified declarative semantic test fixture schema definition and validation.

Envelope v1 for provider-neutral semantic harness tests.
Describes test inputs, scenarios, multi-turn dialogue, and expected observations.
Python coordinates execution and assertions; actual production Lua owns semantics.
"""

from __future__ import annotations

import re
from typing import Any

SCHEMA_V1 = "semantic.harness-test.v1"
ALLOWED_SCHEMAS = frozenset({SCHEMA_V1})

ID_PATTERN = re.compile(r"^[a-zA-Z0-9_\.\-\[\]=]+$")
MAX_TURNS_PER_CASE = 32
MAX_MATRIX_EXPANSIONS = 64
MAX_TEXT_LENGTH = 1000

VALID_OPERATORS = frozenset({
    "equals",
    "notEquals",
    "exists",
    "absent",
    "contains",
    "notContains",
    "prefix",
    "oneOf",
    "min",
    "max",
    "count",
    "minCount",
    "maxCount",
    "truthy",
    "falsy",
})


class SchemaValidationError(ValueError):
    """Raised when a test fixture fails schema validation."""


def validate_case_id(case_id: Any, context: str = "case") -> str:
    if not isinstance(case_id, str) or not case_id.strip():
        raise SchemaValidationError(f"{context} id must be a non-empty string")
    clean_id = case_id.strip()
    if not ID_PATTERN.match(clean_id):
        raise SchemaValidationError(
            f"{context} id '{clean_id}' contains invalid characters; "
            f"must match {ID_PATTERN.pattern}"
        )
    return clean_id


def validate_operator_spec(path: str, operator_dict: dict[str, Any]) -> None:
    if not operator_dict:
        raise SchemaValidationError(f"Empty operator dict at path '{path}'")
    for op, expected_value in operator_dict.items():
        if op not in VALID_OPERATORS:
            raise SchemaValidationError(
                f"Unsupported operator '{op}' at path '{path}'. "
                f"Valid operators: {sorted(VALID_OPERATORS)}"
            )
        if op in {"exists", "absent", "truthy", "falsy"}:
            if not isinstance(expected_value, bool):
                raise SchemaValidationError(
                    f"Operator '{op}' at '{path}' requires a boolean value, got {type(expected_value).__name__}"
                )
        elif op in {"min", "max"}:
            if not isinstance(expected_value, (int, float)):
                raise SchemaValidationError(
                    f"Operator '{op}' at '{path}' requires a numeric value, got {type(expected_value).__name__}"
                )
        elif op in {"count", "minCount", "maxCount"}:
            if not isinstance(expected_value, int) or expected_value < 0:
                raise SchemaValidationError(
                    f"Operator '{op}' at '{path}' requires a non-negative integer, got {expected_value!r}"
                )
        elif op == "oneOf":
            if not isinstance(expected_value, (list, tuple, set, frozenset)):
                raise SchemaValidationError(
                    f"Operator 'oneOf' at '{path}' requires a collection, got {type(expected_value).__name__}"
                )
        elif op in {"contains", "notContains", "prefix"}:
            if not isinstance(expected_value, (str, int, float, bool)):
                raise SchemaValidationError(
                    f"Operator '{op}' at '{path}' requires a scalar string or number, got {type(expected_value).__name__}"
                )


def validate_expectations(expect: Any, context: str = "turn") -> dict[str, Any]:
    if not isinstance(expect, dict):
        raise SchemaValidationError(f"{context}.expect must be an object")
    validated: dict[str, Any] = {}
    for path, spec in expect.items():
        if not isinstance(path, str) or not path.strip():
            raise SchemaValidationError(f"Invalid expectation path in {context}: {path!r}")
        clean_path = path.strip()
        if isinstance(spec, dict):
            validate_operator_spec(clean_path, spec)
            validated[clean_path] = dict(spec)
        else:
            # Shorthand notation: path: value is equivalent to path: {"equals": value}
            validated[clean_path] = {"equals": spec}
    return validated


def validate_turn(turn: Any, index: int, case_id: str) -> dict[str, Any]:
    context = f"case '{case_id}' turn[{index}]"
    if not isinstance(turn, dict):
        raise SchemaValidationError(f"{context} must be an object")

    validated: dict[str, Any] = {}

    # Input / action specification
    input_text = turn.get("text") or turn.get("input")
    action_kind = turn.get("action")
    suggestion_frame = turn.get("suggestionClick") or turn.get("suggestion_frame")
    root_choice = turn.get("rootChoice") or turn.get("root_choice")

    if input_text is not None:
        if not isinstance(input_text, str):
            raise SchemaValidationError(f"{context} text/input must be a string")
        if len(input_text) > MAX_TEXT_LENGTH:
            raise SchemaValidationError(f"{context} input text exceeds max length {MAX_TEXT_LENGTH}")
        validated["text"] = input_text

    if action_kind is not None:
        if not isinstance(action_kind, str):
            raise SchemaValidationError(f"{context} action must be a string")
        validated["action"] = action_kind
        if "payload" in turn:
            validated["payload"] = turn["payload"]
    elif root_choice is not None:
        if not isinstance(root_choice, str):
            raise SchemaValidationError(f"{context} rootChoice must be a string")
        validated["rootChoice"] = root_choice
    elif suggestion_frame is not None:
        if not isinstance(suggestion_frame, dict):
            raise SchemaValidationError(f"{context} suggestionClick must be an object")
        validated["suggestionClick"] = suggestion_frame
    elif input_text is None:
        raise SchemaValidationError(
            f"{context} must specify an input ('text'/'input', 'action', 'rootChoice', or 'suggestionClick')"
        )

    # Optional speaker
    if "speaker" in turn:
        if not isinstance(turn["speaker"], str):
            raise SchemaValidationError(f"{context} speaker must be a string")
        validated["speaker"] = turn["speaker"]

    # Optional language override
    if "language" in turn:
        if not isinstance(turn["language"], str):
            raise SchemaValidationError(f"{context} language must be a string")
        validated["language"] = turn["language"].upper()

    # Optional expectations
    if "expect" in turn:
        validated["expect"] = validate_expectations(turn["expect"], context)
    else:
        validated["expect"] = {}

    # Preserve optional metadata
    for key in ("label", "description", "tags"):
        if key in turn:
            validated[key] = turn[key]

    return validated


def validate_matrix(matrix: Any, case_id: str) -> dict[str, list[Any]]:
    context = f"case '{case_id}' matrix"
    if not isinstance(matrix, dict):
        raise SchemaValidationError(f"{context} must be an object")
    if not matrix:
        raise SchemaValidationError(f"{context} must not be empty")

    total_combinations = 1
    validated: dict[str, list[Any]] = {}
    for key, values in matrix.items():
        if not isinstance(key, str) or not key.strip():
            raise SchemaValidationError(f"{context} key must be a non-empty string")
        if not isinstance(values, (list, tuple)) or not values:
            raise SchemaValidationError(f"{context} '{key}' must be a non-empty list of values")
        total_combinations *= len(values)
        validated[key.strip()] = list(values)

    if total_combinations > MAX_MATRIX_EXPANSIONS:
        raise SchemaValidationError(
            f"{context} expands to {total_combinations} cases, exceeding maximum limit {MAX_MATRIX_EXPANSIONS}"
        )
    return validated


def validate_case(raw_case: Any, default_id: str = "case") -> dict[str, Any]:
    if not isinstance(raw_case, dict):
        raise SchemaValidationError("Case definition must be an object")

    case_id = validate_case_id(raw_case.get("id") or default_id)

    # Schema check if provided at case level
    schema = raw_case.get("schema")
    if schema is not None and schema not in ALLOWED_SCHEMAS:
        raise SchemaValidationError(
            f"Unsupported schema '{schema}' in case '{case_id}'. Allowed: {sorted(ALLOWED_SCHEMAS)}"
        )

    validated: dict[str, Any] = {
        "id": case_id,
        "suite": str(raw_case.get("suite") or "default"),
    }

    if "description" in raw_case:
        validated["description"] = str(raw_case["description"])

    tags = raw_case.get("tags", [])
    if not isinstance(tags, (list, tuple)) or not all(isinstance(t, str) for t in tags):
        raise SchemaValidationError(f"case '{case_id}' tags must be a list of strings")
    validated["tags"] = tuple(t.strip() for t in tags if t.strip())

    scenario = raw_case.get("scenario", {})
    if not isinstance(scenario, dict):
        raise SchemaValidationError(f"case '{case_id}' scenario must be an object")
    validated["scenario"] = dict(scenario)

    if "matrix" in raw_case:
        validated["matrix"] = validate_matrix(raw_case["matrix"], case_id)

    turns = raw_case.get("turns", [])
    if not isinstance(turns, list) or not turns:
        raise SchemaValidationError(f"case '{case_id}' turns must be a non-empty list")
    if len(turns) > MAX_TURNS_PER_CASE:
        raise SchemaValidationError(
            f"case '{case_id}' has {len(turns)} turns, exceeding max {MAX_TURNS_PER_CASE}"
        )

    validated["turns"] = [
        validate_turn(turn, idx, case_id) for idx, turn in enumerate(turns)
    ]

    return validated


def validate_fixture_document(doc: Any, default_suite: str = "default") -> list[dict[str, Any]]:
    """Validate a fixture JSON document which may contain either a single case or a suite of cases."""
    if not isinstance(doc, dict):
        raise SchemaValidationError("Fixture document root must be an object")

    schema = doc.get("schema")
    if schema is not None and schema not in ALLOWED_SCHEMAS:
        raise SchemaValidationError(
            f"Unsupported schema '{schema}'. Allowed: {sorted(ALLOWED_SCHEMAS)}"
        )

    suite = str(doc.get("suite") or default_suite)

    # Document can have a list of cases or represent a single case
    if "cases" in doc:
        cases_list = doc["cases"]
        if not isinstance(cases_list, list) or not cases_list:
            raise SchemaValidationError("Document 'cases' must be a non-empty list")
        validated_cases = []
        seen_ids: set[str] = set()
        for idx, item in enumerate(cases_list):
            item_copy = dict(item)
            if "suite" not in item_copy:
                item_copy["suite"] = suite
            case = validate_case(item_copy, default_id=f"case_{idx}")
            cid = case["id"]
            if cid in seen_ids:
                raise SchemaValidationError(f"Duplicate case id '{cid}' in document")
            seen_ids.add(cid)
            validated_cases.append(case)
        return validated_cases
    else:
        # Single case envelope
        case = validate_case(doc, default_id="case_0")
        return [case]
