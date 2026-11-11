"""Deterministic coverage planning for semantic dialogue quality sweeps.

Implements smoke, boundary, pairwise, persona/relationship, and full-bounded
strategies with stable case identities, batch estimation, and cap enforcement.
"""

from __future__ import annotations

from dataclasses import dataclass, field
import hashlib
import json
import math
from typing import Any, Callable, Mapping, Sequence

from .sweep_buckets import BucketPolicy, build_bucket_inventory, get_bucket_policy
from .sweep_dimensions import SweepDimension, SweepDimensionInventory

MAX_BATCH_SIZE = 64
DEFAULT_MAX_SWEEP_CASES = 512


@dataclass(frozen=True)
class PlannedCase:
    """A single deterministically planned sweep case."""

    case_id: str
    sweep_id: str
    strategy: str  # "smoke", "boundary", "pairwise", "persona", "full"
    surface: str  # e.g. "scenario.rootChoice:wellbeing", "scenario.utterance:hello"
    parameters: dict[str, Any]  # normalized changed parameter vector
    language: str = "EN"
    turns: list[dict[str, Any]] = field(default_factory=list)
    metadata: dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> dict[str, Any]:
        return {
            "caseID": self.case_id,
            "sweepID": self.sweep_id,
            "strategy": self.strategy,
            "surface": self.surface,
            "parameters": self.parameters,
            "language": self.language,
            "turns": self.turns,
            "metadata": self.metadata,
        }


@dataclass(frozen=True)
class CoveragePlan:
    """A complete planned sweep covering declared strategies and surfaces."""

    sweep_id: str
    strategy: str
    plan_digest: str
    catalog_fingerprint: str
    cases: list[PlannedCase]
    total_cases: int
    estimated_batches: int
    batch_size: int = MAX_BATCH_SIZE
    planned_surfaces: list[str] = field(default_factory=list)
    languages: list[str] = field(default_factory=list)
    dimension_summary: dict[str, list[Any]] = field(default_factory=dict)
    uncovered_pairs: list[tuple[str, Any, str, Any]] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        return {
            "sweepID": self.sweep_id,
            "strategy": self.strategy,
            "planDigest": self.plan_digest,
            "catalogFingerprint": self.catalog_fingerprint,
            "totalCases": self.total_cases,
            "estimatedBatches": self.estimated_batches,
            "batchSize": self.batch_size,
            "plannedSurfaces": self.planned_surfaces,
            "languages": self.languages,
            "dimensionSummary": self.dimension_summary,
            "cases": [c.to_dict() for c in self.cases],
        }


def _make_case_id(
    sweep_id: str,
    strategy: str,
    surface: str,
    parameters: Mapping[str, Any],
    language: str,
) -> str:
    """Generate a stable, deterministic case ID."""
    clean_surface = surface.replace(".", "_").replace(":", "_").replace(" ", "_").replace("?", "")
    param_repr = json.dumps(
        sorted(parameters.items()),
        separators=(",", ":"),
        sort_keys=True,
    )
    h = hashlib.sha256(f"{strategy}:{clean_surface}:{language}:{param_repr}".encode("utf-8")).hexdigest()[:10]
    return f"{sweep_id}:{strategy}:{clean_surface}:{language}:{h}"


def _make_turn_spec_for_surface(surface: str, language: str) -> list[dict[str, Any]]:
    """Convert an interaction surface string into declarative turn specs."""
    if surface.startswith("scenario.rootChoice:"):
        choice = surface.split(":", 1)[1]
        return [{"rootChoice": choice, "surface": surface, "language": language}]
    if surface.startswith("conversation.root:menu:"):
        choice = surface.split("menu:", 1)[1]
        return [{"rootChoice": choice, "surface": surface, "language": language}]
    if surface.startswith("conversation.landing:"):
        choice = surface.split("landing:", 1)[1]
        return [{"rootChoice": choice, "surface": surface, "language": language}]
    if surface.startswith("companion.orders:"):
        return [{"rootChoice": "orders", "surface": surface, "language": language}]
    if surface.startswith("scenario.utterance:"):
        utterance = surface.split(":", 1)[1]
        is_fb = "unrecognized" in utterance or "xyzzy" in utterance
        return [{"text": utterance, "surface": surface, "language": language, "expect_fallback": is_fb}]
    if surface.startswith("utterance:"):
        utterance = surface.split(":", 1)[1]
        is_fb = "unrecognized" in utterance or "xyzzy" in utterance
        return [{"text": utterance, "surface": surface, "language": language, "expect_fallback": is_fb}]
    return [{"text": surface, "surface": surface, "language": language}]


DEFAULT_SURFACES = (
    "scenario.rootChoice:ask_name",
    "scenario.rootChoice:recruit",
    "scenario.rootChoice:goodbye",
    "scenario.rootChoice:whats_up",
    "scenario.rootChoice:orders",
    "scenario.utterance:how are you?",
    "scenario.utterance:hello",
    "scenario.utterance:who are you?",
    "scenario.utterance:what's up?",
)


class CoveragePlanner:
    """Plans deterministic dialogue-quality sweep matrices."""

    def __init__(
        self,
        inventory: SweepDimensionInventory,
        *,
        bucket_policies: dict[str, BucketPolicy] | None = None,
        sweep_id: str = "dialogue_sweep_v1",
    ) -> None:
        self.inventory = inventory
        self.buckets = bucket_policies or build_bucket_inventory(inventory)
        self.sweep_id = sweep_id

    def plan_smoke(
        self,
        *,
        surfaces: Sequence[str] = DEFAULT_SURFACES,
        languages: Sequence[str] = ("EN", "TL"),
    ) -> CoveragePlan:
        """Smoke strategy: 1 baseline case per surface for each language."""
        cases: list[PlannedCase] = []
        for surface in surfaces:
            for lang in languages:
                params: dict[str, Any] = {}
                case_id = _make_case_id(self.sweep_id, "smoke", surface, params, lang)
                turns = _make_turn_spec_for_surface(surface, lang)
                cases.append(
                    PlannedCase(
                        case_id=case_id,
                        sweep_id=self.sweep_id,
                        strategy="smoke",
                        surface=surface,
                        parameters=params,
                        language=lang,
                        turns=turns,
                    )
                )

        return self._build_plan("smoke", cases)

    def plan_boundary(
        self,
        *,
        surfaces: Sequence[str] = ("scenario.rootChoice:ask_name", "scenario.utterance:how are you?"),
        dimensions: Sequence[str] | None = None,
        languages: Sequence[str] = ("EN", "TL"),
        max_cases: int = DEFAULT_MAX_SWEEP_CASES,
    ) -> CoveragePlan:
        """Boundary strategy: vary each selected dimension through its bucket values while holding others baseline."""
        target_dims = list(dimensions) if dimensions else [
            "relationship.approval",
            "relationship.respect",
            "relationship.familiarity",
            "persona.bondKind",
            "persona.personality.aggression",
            "persona.personality.compassion",
            "player.needs.hunger",
            "npc.needs.hunger",
            "npc.needs.fatigue",
        ]

        cases: list[PlannedCase] = []
        seen_case_ids: set[str] = set()

        for surface in surfaces:
            for lang in languages:
                # Include neutral baseline
                baseline_id = _make_case_id(self.sweep_id, "boundary", surface, {}, lang)
                if baseline_id not in seen_case_ids:
                    seen_case_ids.add(baseline_id)
                    cases.append(
                        PlannedCase(
                            case_id=baseline_id,
                            sweep_id=self.sweep_id,
                            strategy="boundary",
                            surface=surface,
                            parameters={},
                            language=lang,
                            turns=_make_turn_spec_for_surface(surface, lang),
                        )
                    )

                for dim_id in target_dims:
                    policy = self.buckets.get(dim_id)
                    if not policy:
                        continue
                    dim = self.inventory.get(dim_id)
                    if not dim:
                        continue

                    for val in policy.values:
                        if len(cases) >= max_cases:
                            break
                        try:
                            norm_params = self.inventory.validate_parameter_vector({dim_id: val})
                        except Exception:
                            continue

                        case_id = _make_case_id(self.sweep_id, "boundary", surface, norm_params, lang)
                        if case_id not in seen_case_ids:
                            seen_case_ids.add(case_id)
                            cases.append(
                                PlannedCase(
                                    case_id=case_id,
                                    sweep_id=self.sweep_id,
                                    strategy="boundary",
                                    surface=surface,
                                    parameters=norm_params,
                                    language=lang,
                                    turns=_make_turn_spec_for_surface(surface, lang),
                                    metadata={"dimension": dim_id, "value": val},
                                )
                            )

        return self._build_plan("boundary", cases)

    def plan_pairwise(
        self,
        *,
        dimensions: Sequence[str] | None = None,
        surfaces: Sequence[str] = ("scenario.rootChoice:ask_name", "scenario.utterance:how are you?"),
        languages: Sequence[str] = ("EN",),
        max_cases: int = DEFAULT_MAX_SWEEP_CASES,
    ) -> CoveragePlan:
        """Pairwise strategy: deterministic 2-way covering array across selected dimensions."""
        target_dims = list(dimensions) if dimensions else [
            "relationship.approval",
            "relationship.respect",
            "persona.bondKind",
            "persona.personality.aggression",
            "npc.needs.hunger",
        ]

        # Filter to dimensions that exist and have bucket values
        valid_dims: list[tuple[str, list[Any]]] = []
        for dim_id in target_dims:
            policy = self.buckets.get(dim_id)
            if policy and policy.values:
                # Take up to 4 representative values per dimension for compact pairwise
                vals = list(policy.values)
                if len(vals) > 4:
                    vals = [vals[0], vals[len(vals) // 3], vals[(2 * len(vals)) // 3], vals[-1]]
                valid_dims.append((dim_id, vals))

        # Generate all 2-way value pairs to be covered
        all_pairs: set[tuple[str, Any, str, Any]] = set()
        for i in range(len(valid_dims)):
            d1, vals1 = valid_dims[i]
            for j in range(i + 1, len(valid_dims)):
                d2, vals2 = valid_dims[j]
                for v1 in vals1:
                    for v2 in vals2:
                        all_pairs.add((d1, v1, d2, v2))

        # Deterministic greedy covering algorithm (AETG/IPO style)
        uncovered = set(all_pairs)
        test_vectors: list[dict[str, Any]] = []

        while uncovered and len(test_vectors) < max_cases:
            # Pick pair that covers best or first remaining
            best_vector: dict[str, Any] | None = None
            best_coverage = -1

            # Candidate generation: start from the first remaining uncovered pair
            candidate_base_pair = next(iter(uncovered))
            d1, v1, d2, v2 = candidate_base_pair
            candidate_vector = {d1: v1, d2: v2}

            # For each remaining dimension, pick value that maximizes newly covered pairs
            for dim_name, vals in valid_dims:
                if dim_name in candidate_vector:
                    continue
                best_val = vals[0]
                best_new_pairs = -1
                for cand_val in vals:
                    new_pairs = 0
                    for set_dim, set_val in candidate_vector.items():
                        pair_key = (
                            (set_dim, set_val, dim_name, cand_val)
                            if set_dim < dim_name
                            else (dim_name, cand_val, set_dim, set_val)
                        )
                        if pair_key in uncovered:
                            new_pairs += 1
                    if new_pairs > best_new_pairs:
                        best_new_pairs = new_pairs
                        best_val = cand_val
                candidate_vector[dim_name] = best_val

            # Validate and normalize vector
            try:
                norm_vec = self.inventory.validate_parameter_vector(candidate_vector)
            except Exception:
                norm_vec = candidate_vector

            test_vectors.append(norm_vec)

            # Mark all covered pairs
            covered_in_this: set[tuple[str, Any, str, Any]] = set()
            for pair in uncovered:
                pd1, pv1, pd2, pv2 = pair
                if norm_vec.get(pd1) == pv1 and norm_vec.get(pd2) == pv2:
                    covered_in_this.add(pair)
            uncovered -= covered_in_this

        # Convert vectors to PlannedCases across surfaces & languages
        cases: list[PlannedCase] = []
        for surface in surfaces:
            for lang in languages:
                for vec in test_vectors:
                    if len(cases) >= max_cases:
                        break
                    case_id = _make_case_id(self.sweep_id, "pairwise", surface, vec, lang)
                    cases.append(
                        PlannedCase(
                            case_id=case_id,
                            sweep_id=self.sweep_id,
                            strategy="pairwise",
                            surface=surface,
                            parameters=vec,
                            language=lang,
                            turns=_make_turn_spec_for_surface(surface, lang),
                        )
                    )

        plan = self._build_plan("pairwise", cases)
        object.__setattr__(plan, "uncovered_pairs", sorted(uncovered, key=lambda x: (x[0], str(x[1]), x[2], str(x[3]))))
        return plan

    def plan_persona(
        self,
        *,
        surfaces: Sequence[str] = ("scenario.rootChoice:ask_name", "scenario.utterance:how are you?"),
        languages: Sequence[str] = ("EN", "TL"),
        max_cases: int = DEFAULT_MAX_SWEEP_CASES,
    ) -> CoveragePlan:
        """Persona/Relationship preset: exercises personality extremes, bond kinds, and relationship standing."""
        personality_traits = [
            ("aggressive", {"persona.personality.aggression": 1.0, "persona.personality.compassion": 0.0}),
            ("gentle", {"persona.personality.aggression": 0.0, "persona.personality.compassion": 1.0}),
            ("brave", {"persona.personality.bravery": 1.0, "persona.personality.loyalty": 0.9}),
            ("timid", {"persona.personality.bravery": 0.0, "persona.personality.sociability": 0.1}),
            ("neutral", {"persona.personality.aggression": 0.5, "persona.personality.bravery": 0.5}),
        ]

        bonds = ("none", "friend", "sister", "brother", "lover")
        standings = [
            ("neutral", {"relationship.approval": 0.0, "relationship.respect": 0.0, "relationship.familiarity": 10.0}),
            ("enemy", {"relationship.approval": -70.0, "relationship.respect": -50.0, "relationship.familiarity": 40.0}),
            ("friend", {"relationship.approval": 60.0, "relationship.respect": 40.0, "relationship.familiarity": 50.0}),
            ("intimate", {"relationship.approval": 90.0, "relationship.respect": 70.0, "relationship.familiarity": 85.0}),
        ]

        cases: list[PlannedCase] = []
        seen: set[str] = set()

        for surface in surfaces:
            for lang in languages:
                for persona_name, p_params in personality_traits:
                    for bond in bonds:
                        for standing_name, s_params in standings:
                            if len(cases) >= max_cases:
                                break
                            combined = dict(p_params)
                            combined["persona.bondKind"] = bond
                            combined.update(s_params)

                            try:
                                norm = self.inventory.validate_parameter_vector(combined)
                            except Exception:
                                continue

                            case_id = _make_case_id(self.sweep_id, "persona", surface, norm, lang)
                            if case_id not in seen:
                                seen.add(case_id)
                                cases.append(
                                    PlannedCase(
                                        case_id=case_id,
                                        sweep_id=self.sweep_id,
                                        strategy="persona",
                                        surface=surface,
                                        parameters=norm,
                                        language=lang,
                                        turns=_make_turn_spec_for_surface(surface, lang),
                                        metadata={
                                            "persona": persona_name,
                                            "bond": bond,
                                            "standing": standing_name,
                                        },
                                    )
                                )

        return self._build_plan("persona", cases)

    def plan_full(
        self,
        *,
        surfaces: Sequence[str] = DEFAULT_SURFACES,
        languages: Sequence[str] = ("EN", "TL"),
        max_cases: int = 1024,
    ) -> CoveragePlan:
        """Balanced full-bounded review across every selected surface.

        Earlier implementations exhausted the cap on the first one or two
        surfaces.  The sentence-review workflow instead builds each strategy
        across the complete surface set, then round-robins surfaces so the
        bounded cap cannot starve later dialogue families.
        """
        surface_list = list(dict.fromkeys(surfaces))
        language_list = list(dict.fromkeys(languages))
        if not surface_list or not language_list or max_cases <= 0:
            return self._build_plan("full", [])

        # Generate enough candidate material for every surface. Planning is
        # cheap; execution remains bounded by max_cases.
        candidate_cap = max(
            max_cases * 8,
            len(surface_list) * max(1, len(language_list)) * 256,
        )
        smoke_plan = self.plan_smoke(
            surfaces=surface_list,
            languages=language_list,
        )
        boundary_plan = self.plan_boundary(
            surfaces=surface_list,
            languages=language_list,
            max_cases=candidate_cap,
        )
        pairwise_plan = self.plan_pairwise(
            surfaces=surface_list,
            languages=language_list,
            max_cases=candidate_cap,
        )
        persona_plan = self.plan_persona(
            surfaces=surface_list,
            languages=language_list,
            max_cases=candidate_cap,
        )

        combined_cases: list[PlannedCase] = []
        seen_keys: set[str] = set()

        def add_case(c: PlannedCase) -> bool:
            param_key = json.dumps(sorted(c.parameters.items()), sort_keys=True)
            dedup_key = f"{c.surface}:{c.language}:{param_key}"
            if dedup_key in seen_keys:
                return False
            seen_keys.add(dedup_key)
            case_id = _make_case_id(
                self.sweep_id, "full", c.surface, c.parameters, c.language
            )
            combined_cases.append(
                PlannedCase(
                    case_id=case_id,
                    sweep_id=self.sweep_id,
                    strategy="full",
                    surface=c.surface,
                    parameters=c.parameters,
                    language=c.language,
                    turns=c.turns,
                    metadata=c.metadata,
                )
            )
            return True

        # Always seed each surface/language with its baseline before spending
        # the remaining budget on richer contexts.
        for c in smoke_plan.cases:
            if len(combined_cases) >= max_cases:
                break
            add_case(c)

        candidate_plans = (boundary_plan, pairwise_plan, persona_plan)
        grouped: list[dict[str, list[PlannedCase]]] = []
        for plan in candidate_plans:
            by_surface: dict[str, list[PlannedCase]] = {
                surface: [] for surface in surface_list
            }
            for c in plan.cases:
                by_surface.setdefault(c.surface, []).append(c)
            grouped.append(by_surface)

        cursors: list[dict[str, int]] = [
            {surface: 0 for surface in surface_list}
            for _ in candidate_plans
        ]

        made_progress = True
        while len(combined_cases) < max_cases and made_progress:
            made_progress = False
            for surface in surface_list:
                for plan_idx, by_surface in enumerate(grouped):
                    rows = by_surface.get(surface, [])
                    cursor = cursors[plan_idx].get(surface, 0)
                    while cursor < len(rows):
                        candidate = rows[cursor]
                        cursor += 1
                        cursors[plan_idx][surface] = cursor
                        if add_case(candidate):
                            made_progress = True
                            break
                    if len(combined_cases) >= max_cases:
                        break
                if len(combined_cases) >= max_cases:
                    break

        return self._build_plan("full", combined_cases)

    def _build_plan(self, strategy: str, cases: list[PlannedCase]) -> CoveragePlan:
        total = len(cases)
        batches = math.ceil(total / MAX_BATCH_SIZE) if total > 0 else 0
        digest = hashlib.sha256(
            "\n".join(c.case_id for c in cases).encode("utf-8")
        ).hexdigest()

        planned_surfs = sorted(set(c.surface for c in cases))
        langs = sorted(set(c.language for c in cases))
        dim_summary: dict[str, set[Any]] = {}
        for c in cases:
            for k, v in c.parameters.items():
                dim_summary.setdefault(k, set()).add(str(v))

        return CoveragePlan(
            sweep_id=self.sweep_id,
            strategy=strategy,
            plan_digest=digest,
            catalog_fingerprint=self.inventory.production_fingerprint,
            cases=cases,
            total_cases=total,
            estimated_batches=batches,
            batch_size=MAX_BATCH_SIZE,
            planned_surfaces=planned_surfs,
            languages=langs,
            dimension_summary={k: sorted(list(vals)) for k, vals in dim_summary.items()},
        )
