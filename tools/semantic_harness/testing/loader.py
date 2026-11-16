"""Discovery, loading, and deterministic matrix expansion of semantic test fixtures."""

from __future__ import annotations

import itertools
import json
from copy import deepcopy
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable

from .schema import validate_fixture_document


@dataclass(frozen=True)
class SemanticCase:
    case_id: str
    suite: str
    tags: tuple[str, ...]
    scenario: dict[str, Any]
    turns: tuple[dict[str, Any], ...]
    description: str | None = None
    domain: str | None = None
    semantic_id: str | None = None
    source_file: Path | None = None

    def _turn_semantic_ids(self) -> set[str]:
        ids: set[str] = set()
        if self.semantic_id:
            ids.add(self.semantic_id)
        for turn in self.turns:
            payload = turn.get("payload")
            if isinstance(payload, dict):
                for key in ("recordID", "poolID", "topicID"):
                    val = payload.get(key)
                    if isinstance(val, str) and val.strip():
                        ids.add(val.strip())
        return ids

    def matches_filter(
        self,
        *,
        domain: str | None = None,
        suite: str | None = None,
        case_id: str | None = None,
        tags: Iterable[str] | None = None,
        semantic_id: str | None = None,
        pattern: str | None = None,
    ) -> bool:
        if domain:
            target_domain = domain.strip().casefold()
            case_domain = self.domain.casefold() if self.domain else None
            tag_set = {t.casefold() for t in self.tags}
            if case_domain != target_domain and target_domain not in tag_set:
                return False
        if suite and self.suite != suite:
            return False
        if case_id and self.case_id != case_id:
            return False
        if tags:
            case_tags = set(self.tags)
            if not any(tag in case_tags for tag in tags):
                return False
        if semantic_id:
            target_sid = semantic_id.strip()
            if target_sid != self.case_id and target_sid not in self._turn_semantic_ids():
                return False
        if pattern:
            lowered = pattern.casefold()
            if (
                lowered not in self.case_id.casefold()
                and lowered not in self.suite.casefold()
                and (not self.domain or lowered not in self.domain.casefold())
                and not any(lowered in t.casefold() for t in self.tags)
                and not any(lowered in sid.casefold() for sid in self._turn_semantic_ids())
            ):
                return False
        return True


def _apply_param_to_case(
    scenario: dict[str, Any],
    turns: list[dict[str, Any]],
    param: str,
    value: Any,
) -> None:
    """Apply a matrix variable into the case scenario and/or turns."""
    if param == "language":
        scenario.setdefault("runtime", {})["language"] = str(value).upper()
        for turn in turns:
            if "language" not in turn:
                turn["language"] = str(value).upper()
    elif param == "weather":
        scenario.setdefault("world", {})["weather"] = value
    elif param.startswith("scenario."):
        parts = param[len("scenario."):].split(".")
        target = scenario
        for part in parts[:-1]:
            target = target.setdefault(part, {})
        target[parts[-1]] = value
    else:
        # Default: store under scenario.matrix context
        scenario.setdefault("matrix", {})[param] = value


def expand_matrix_case(validated_case: dict[str, Any], source_file: Path | None = None) -> list[SemanticCase]:
    """Expand a validated case containing a matrix into discrete deterministic cases."""
    matrix = validated_case.get("matrix")
    if not matrix:
        return [
            SemanticCase(
                case_id=validated_case["id"],
                suite=validated_case["suite"],
                tags=tuple(validated_case.get("tags", ())),
                scenario=deepcopy(validated_case.get("scenario", {})),
                turns=tuple(deepcopy(t) for t in validated_case["turns"]),
                description=validated_case.get("description"),
                domain=validated_case.get("domain"),
                semantic_id=validated_case.get("semanticID"),
                source_file=source_file,
            )
        ]

    keys = sorted(matrix.keys())
    value_lists = [matrix[k] for k in keys]
    expanded: list[SemanticCase] = []

    for combo in itertools.product(*value_lists):
        combo_map = dict(zip(keys, combo))
        suffix_parts = [f"{k}={combo_map[k]}" for k in keys]
        suffix = "[" + ",".join(suffix_parts) + "]"
        expanded_id = validated_case["id"] + suffix

        case_scenario = deepcopy(validated_case.get("scenario", {}))
        case_turns = deepcopy(validated_case["turns"])

        for k, v in combo_map.items():
            _apply_param_to_case(case_scenario, case_turns, k, v)

        expanded.append(
            SemanticCase(
                case_id=expanded_id,
                suite=validated_case["suite"],
                tags=tuple(validated_case.get("tags", ())),
                scenario=case_scenario,
                turns=tuple(case_turns),
                description=validated_case.get("description"),
                domain=validated_case.get("domain"),
                semantic_id=validated_case.get("semanticID"),
                source_file=source_file,
            )
        )

    return expanded


def filter_cases(
    cases: Iterable[SemanticCase],
    *,
    domain: str | None = None,
    suite: str | None = None,
    case_id: str | None = None,
    tags: Iterable[str] | None = None,
    semantic_id: str | None = None,
    filters: Iterable[str] | None = None,
) -> list[SemanticCase]:
    """Filter semantic cases using shared provider-neutral metadata criteria."""
    filter_terms = [str(f).strip() for f in (filters or ()) if str(f).strip()]
    tag_list = tuple(tags) if tags else None
    matched: list[SemanticCase] = []
    for c in cases:
        if not c.matches_filter(
            domain=domain,
            suite=suite,
            case_id=case_id,
            tags=tag_list,
            semantic_id=semantic_id,
        ):
            continue
        if filter_terms and not any(c.matches_filter(pattern=term) for term in filter_terms):
            continue
        matched.append(c)
    return matched


def discover_domains(cases: Iterable[SemanticCase]) -> dict[str, int]:
    """Return discovered domain/category counts from fixture metadata without hardcoding enums."""
    counts: dict[str, int] = {}
    for c in cases:
        if c.domain:
            counts[c.domain] = counts.get(c.domain, 0) + 1
        elif c.tags:
            counts[c.tags[0]] = counts.get(c.tags[0], 0) + 1
        else:
            counts[c.suite] = counts.get(c.suite, 0) + 1
    return dict(sorted(counts.items()))


def load_cases_from_dict(
    doc: dict[str, Any],
    source_file: Path | None = None,
    default_suite: str = "default",
) -> list[SemanticCase]:
    """Validate a fixture dict and expand all declared cases."""
    validated_cases = validate_fixture_document(doc, default_suite=default_suite)
    cases: list[SemanticCase] = []
    for raw_case in validated_cases:
        cases.extend(expand_matrix_case(raw_case, source_file=source_file))
    return cases


def load_cases_from_file(path: Path) -> list[SemanticCase]:
    """Load, validate, and expand cases from a single JSON fixture file."""
    text = path.read_text(encoding="utf-8")
    doc = json.loads(text)
    default_suite = path.stem.replace(".", "_")
    return load_cases_from_dict(doc, source_file=path, default_suite=default_suite)


def discover_cases(
    targets: Iterable[Path | str],
    *,
    pattern: str = "*.json",
) -> list[SemanticCase]:
    """Discover and load all semantic fixture cases from paths and directories.

    Validates that case IDs are unique across the entire discovery set.
    """
    cases: list[SemanticCase] = []
    seen_ids: dict[str, Path | None] = {}

    for target in targets:
        path = Path(target).resolve()
        if path.is_file():
            loaded = load_cases_from_file(path)
            for c in loaded:
                if c.case_id in seen_ids:
                    raise ValueError(
                        f"Duplicate case id '{c.case_id}' found in {path} (first seen in {seen_ids[c.case_id]})"
                    )
                seen_ids[c.case_id] = path
                cases.append(c)
        elif path.is_dir():
            for sub_path in sorted(path.rglob(pattern)):
                if sub_path.is_file():
                    loaded = load_cases_from_file(sub_path)
                    for c in loaded:
                        if c.case_id in seen_ids:
                            raise ValueError(
                                f"Duplicate case id '{c.case_id}' found in {sub_path} "
                                f"(first seen in {seen_ids[c.case_id]})"
                            )
                        seen_ids[c.case_id] = sub_path
                        cases.append(c)

    return cases
