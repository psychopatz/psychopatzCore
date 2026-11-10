"""Assertion comparator for bounded semantic observation paths."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from .projection import ABSENT, resolve_observation_path


@dataclass(frozen=True)
class AssertionFailure:
    path: str
    operator: str
    expected: Any
    actual: Any
    message: str

    def __str__(self) -> str:
        return self.message


def compare_value(
    path: str,
    operator: str,
    expected: Any,
    actual: Any,
) -> AssertionFailure | None:
    """Compare actual against expected using operator.

    Returns None on success, or an AssertionFailure describing the mismatch.
    """
    if operator == "equals":
        if actual is ABSENT or actual != expected:
            return AssertionFailure(
                path=path,
                operator=operator,
                expected=expected,
                actual=actual,
                message=f"At '{path}': expected {expected!r}, got {actual!r}",
            )

    elif operator == "notEquals":
        if actual == expected:
            return AssertionFailure(
                path=path,
                operator=operator,
                expected=expected,
                actual=actual,
                message=f"At '{path}': expected not equal to {expected!r}, but was equal",
            )

    elif operator == "exists":
        is_present = (actual is not ABSENT and actual is not None)
        expected_bool = bool(expected)
        if is_present != expected_bool:
            return AssertionFailure(
                path=path,
                operator=operator,
                expected=expected_bool,
                actual=actual,
                message=f"At '{path}': expected exists={expected_bool}, but actual was {actual!r}",
            )

    elif operator == "absent":
        is_absent = (actual is ABSENT or actual is None)
        expected_bool = bool(expected)
        if is_absent != expected_bool:
            return AssertionFailure(
                path=path,
                operator=operator,
                expected=expected_bool,
                actual=actual,
                message=f"At '{path}': expected absent={expected_bool}, but actual was {actual!r}",
            )

    elif operator == "contains":
        if actual is ABSENT or actual is None:
            return AssertionFailure(
                path=path,
                operator=operator,
                expected=expected,
                actual=actual,
                message=f"At '{path}': cannot check 'contains' on absent/none value",
            )
        if isinstance(actual, str):
            if str(expected) not in actual:
                return AssertionFailure(
                    path=path,
                    operator=operator,
                    expected=expected,
                    actual=actual,
                    message=f"At '{path}': string {actual!r} does not contain {expected!r}",
                )
        elif isinstance(actual, (list, tuple, set, frozenset)):
            if expected not in actual:
                return AssertionFailure(
                    path=path,
                    operator=operator,
                    expected=expected,
                    actual=actual,
                    message=f"At '{path}': collection does not contain {expected!r}",
                )
        elif isinstance(actual, dict):
            if isinstance(expected, dict):
                missing = {k: v for k, v in expected.items() if actual.get(k) != v}
                if missing:
                    return AssertionFailure(
                        path=path,
                        operator=operator,
                        expected=expected,
                        actual=actual,
                        message=f"At '{path}': dict missing sub-entries {missing!r}",
                    )
            elif expected not in actual:
                return AssertionFailure(
                    path=path,
                    operator=operator,
                    expected=expected,
                    actual=actual,
                    message=f"At '{path}': dict keys do not contain {expected!r}",
                )
        else:
            return AssertionFailure(
                path=path,
                operator=operator,
                expected=expected,
                actual=actual,
                message=f"At '{path}': type '{type(actual).__name__}' does not support 'contains'",
            )

    elif operator == "notContains":
        if actual is not ABSENT and actual is not None:
            if isinstance(actual, str) and str(expected) in actual:
                return AssertionFailure(
                    path=path,
                    operator=operator,
                    expected=expected,
                    actual=actual,
                    message=f"At '{path}': string {actual!r} unexpectedly contains {expected!r}",
                )
            elif isinstance(actual, (list, tuple, set, frozenset, dict)) and expected in actual:
                return AssertionFailure(
                    path=path,
                    operator=operator,
                    expected=expected,
                    actual=actual,
                    message=f"At '{path}': collection unexpectedly contains {expected!r}",
                )

    elif operator == "prefix":
        if not isinstance(actual, str):
            return AssertionFailure(
                path=path,
                operator=operator,
                expected=expected,
                actual=actual,
                message=f"At '{path}': expected string prefix on {actual!r} ({type(actual).__name__})",
            )
        prefix_str = str(expected)
        if not actual.startswith(prefix_str):
            return AssertionFailure(
                path=path,
                operator=operator,
                expected=prefix_str,
                actual=actual,
                message=f"At '{path}': string {actual!r} does not start with prefix {prefix_str!r}",
            )

    elif operator == "oneOf":
        if actual is ABSENT or actual not in expected:
            return AssertionFailure(
                path=path,
                operator=operator,
                expected=expected,
                actual=actual,
                message=f"At '{path}': actual {actual!r} not in allowed choices {expected!r}",
            )

    elif operator == "min":
        if not isinstance(actual, (int, float)):
            return AssertionFailure(
                path=path,
                operator=operator,
                expected=expected,
                actual=actual,
                message=f"At '{path}': expected numeric >= {expected}, got non-numeric {actual!r}",
            )
        if actual < expected:
            return AssertionFailure(
                path=path,
                operator=operator,
                expected=expected,
                actual=actual,
                message=f"At '{path}': value {actual} is less than min {expected}",
            )

    elif operator == "max":
        if not isinstance(actual, (int, float)):
            return AssertionFailure(
                path=path,
                operator=operator,
                expected=expected,
                actual=actual,
                message=f"At '{path}': expected numeric <= {expected}, got non-numeric {actual!r}",
            )
        if actual > expected:
            return AssertionFailure(
                path=path,
                operator=operator,
                expected=expected,
                actual=actual,
                message=f"At '{path}': value {actual} is greater than max {expected}",
            )

    elif operator in {"count", "minCount", "maxCount"}:
        length: int | None = None
        if isinstance(actual, (list, tuple, dict, set, frozenset, str)):
            length = len(actual)
        elif isinstance(actual, int):
            length = actual
        if length is None:
            return AssertionFailure(
                path=path,
                operator=operator,
                expected=expected,
                actual=actual,
                message=f"At '{path}': cannot determine count for {actual!r}",
            )
        if operator == "count" and length != expected:
            return AssertionFailure(
                path=path,
                operator=operator,
                expected=expected,
                actual=length,
                message=f"At '{path}': expected count {expected}, got {length}",
            )
        elif operator == "minCount" and length < expected:
            return AssertionFailure(
                path=path,
                operator=operator,
                expected=expected,
                actual=length,
                message=f"At '{path}': count {length} is less than minCount {expected}",
            )
        elif operator == "maxCount" and length > expected:
            return AssertionFailure(
                path=path,
                operator=operator,
                expected=expected,
                actual=length,
                message=f"At '{path}': count {length} is greater than maxCount {expected}",
            )

    elif operator == "truthy":
        is_truthy = bool(actual is not ABSENT and actual)
        expected_bool = bool(expected)
        if is_truthy != expected_bool:
            return AssertionFailure(
                path=path,
                operator=operator,
                expected=expected_bool,
                actual=actual,
                message=f"At '{path}': expected truthy={expected_bool}, got {actual!r}",
            )

    elif operator == "falsy":
        is_falsy = bool(actual is ABSENT or not actual)
        expected_bool = bool(expected)
        if is_falsy != expected_bool:
            return AssertionFailure(
                path=path,
                operator=operator,
                expected=expected_bool,
                actual=actual,
                message=f"At '{path}': expected falsy={expected_bool}, got {actual!r}",
            )

    return None


def evaluate_expectations(
    turn: dict[str, Any],
    expectations: dict[str, Any],
) -> list[AssertionFailure]:
    """Evaluate all expectations against the turn observation.

    Returns a list of all AssertionFailures encountered.
    """
    failures: list[AssertionFailure] = []
    for path, spec in expectations.items():
        actual = resolve_observation_path(turn, path)
        if isinstance(spec, dict):
            for operator, expected in spec.items():
                failure = compare_value(path, operator, expected, actual)
                if failure is not None:
                    failures.append(failure)
        else:
            failure = compare_value(path, "equals", spec, actual)
            if failure is not None:
                failures.append(failure)
    return failures
