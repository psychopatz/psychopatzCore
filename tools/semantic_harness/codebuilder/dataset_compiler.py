"""Generic deterministic compiler for bounded typed dataset envelopes."""

from __future__ import annotations

from collections.abc import Callable
from typing import Any

from .dataset_contract import normalize_utterance, validate_source_metadata
from .errors import CompileError


PatternCompiler = Callable[
    [Any, set[str]],
    tuple[dict[str, Any], list[str]],
]
ResponseCompiler = Callable[
    [Any, set[str]],
    tuple[dict[str, Any], dict[str, dict[str, str]]],
]
UtteranceNormalizer = Callable[[Any], tuple[str, tuple[str, ...]]]


def compile_typed_dataset(
    document: dict[str, Any],
    *,
    pattern_compiler: PatternCompiler,
    response_compiler: ResponseCompiler,
    utterance_normalizer: UtteranceNormalizer = normalize_utterance,
    max_patterns: int = 128,
    max_response_pools: int = 32,
    label: str = "dataset",
    error_label: str | None = None,
    source_label: str | None = None,
    reference_label: str | None = None,
) -> dict[str, Any]:
    """Compile patterns and response pools with adopter-supplied policy.

    Core owns envelope validation, provenance, deterministic ordering, and
    duplicate detection. Adopters own the meaning of each pattern and response
    through the two compiler callbacks.
    """
    error_label = error_label or label
    if not isinstance(document, dict) or document.get("schemaVersion") != 1:
        raise CompileError(f"{label} requires schemaVersion 1")
    source = validate_source_metadata(
        document.get("source"),
        label=label,
        source_label=source_label,
        reference_label=reference_label,
    )
    patterns = document.get("patterns")
    response_pools = document.get("responsePools")
    if not isinstance(patterns, list) or len(patterns) > max_patterns:
        raise CompileError(
            f"{label} requires at most {max_patterns} exact patterns"
        )
    if not isinstance(response_pools, list) or len(response_pools) > max_response_pools:
        raise CompileError(
            f"{label} requires at most {max_response_pools} response pools"
        )

    source_names = {reference["name"] for reference in source["references"]}
    compiled_patterns = []
    seen_pattern_ids: set[str] = set()
    seen_utterances: dict[str, str] = {}
    seen_negatives: dict[str, str] = {}
    for pattern in patterns:
        compiled, negatives = pattern_compiler(pattern, source_names)
        if compiled["id"] in seen_pattern_ids:
            raise CompileError(f"duplicate {error_label} pattern id {compiled['id']}")
        seen_pattern_ids.add(compiled["id"])
        normalized_utterance, _ = utterance_normalizer(
            pattern.get("utterance")
        )
        previous = seen_utterances.get(normalized_utterance)
        if previous is not None:
            raise CompileError(
                f"{error_label} utterance {normalized_utterance!r} is mapped by both "
                f"{previous} and {compiled['id']}"
            )
        previous = seen_negatives.get(normalized_utterance)
        if previous is not None:
            raise CompileError(
                f"{error_label} positive {normalized_utterance!r} collides with "
                f"negative pattern {previous}"
            )
        seen_utterances[normalized_utterance] = compiled["id"]
        for negative in negatives:
            previous = seen_utterances.get(negative)
            if previous is not None:
                raise CompileError(
                    f"{error_label} negative {negative!r} collides with positive pattern "
                    f"{previous}"
                )
            previous = seen_negatives.get(negative)
            if previous is not None and previous != compiled["id"]:
                raise CompileError(
                    f"{error_label} negative {negative!r} is repeated by {previous} "
                    f"and {compiled['id']}"
                )
            seen_negatives[negative] = compiled["id"]
        compiled_patterns.append(compiled)

    compiled_pools = []
    translations: dict[str, dict[str, str]] = {}
    seen_pool_ids: set[str] = set()
    seen_response_ids: set[str] = set()
    for pool in response_pools:
        compiled, pool_translations = response_compiler(pool, source_names)
        if compiled["id"] in seen_pool_ids:
            raise CompileError(f"duplicate {error_label} response pool {compiled['id']}")
        seen_pool_ids.add(compiled["id"])
        for variant in compiled["variants"]:
            if variant["id"] in seen_response_ids:
                raise CompileError(
                    f"duplicate {error_label} response id {variant['id']}"
                )
            seen_response_ids.add(variant["id"])
        for language, localized in sorted(pool_translations.items()):
            bucket = translations.setdefault(language, {})
            for key, text in localized.items():
                if key in bucket:
                    raise CompileError(f"duplicate {error_label} translation key {key}")
                bucket[key] = text
        compiled_pools.append(compiled)

    compiled_patterns.sort(key=lambda item: item["id"])
    compiled_pools.sort(key=lambda item: item["id"])
    return {
        "source": source,
        "patterns": compiled_patterns,
        "responsePools": compiled_pools,
        "translations": {
            language: {key: values[key] for key in sorted(values)}
            for language, values in sorted(translations.items())
        },
    }


__all__ = [
    "PatternCompiler",
    "ResponseCompiler",
    "UtteranceNormalizer",
    "compile_typed_dataset",
]
