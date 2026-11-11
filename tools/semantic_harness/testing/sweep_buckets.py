"""Bounded semantic bucket policies for sweep dimensions.

Assigns semantic bucket values and production threshold neighbors to numeric,
enum, and boolean dimensions so that coverage strategies systematically exercise
meaningful gameplay/relationship/need boundaries without unbounded combinatorial
explosion.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from .sweep_dimensions import SweepDimension, SweepDimensionInventory


@dataclass(frozen=True)
class BucketPolicy:
    """Bounded bucket policy for a single dimension."""

    dimension_id: str
    values: tuple[Any, ...]
    thresholds: tuple[float, ...] = ()
    provenance: str = "default_endpoints"
    strategy_reason: str = ""


# Production relationship thresholds from PNC_RelationshipConstants / PNC_RelationshipStates
# Unknown familiarity exit: 5
# Friend: approval >= 35, respect >= 15
# Rival: approval <= -25, respect >= 25
# Enemy: approval <= -60, respect < 10
# Friend bond / proposal: approval >= 85, respect >= 60, familiarity >= 80
RELATIONSHIP_BUCKETS: dict[str, BucketPolicy] = {
    "relationship.approval": BucketPolicy(
        dimension_id="relationship.approval",
        values=(-100.0, -65.0, -60.0, -26.0, -25.0, 0.0, 34.0, 35.0, 85.0, 100.0),
        thresholds=(-60.0, -25.0, 35.0, 85.0),
        provenance="PNC_RelationshipConstants.lua",
        strategy_reason="Covers enemy (-60), rival (-25), neutral (0), friend (35), proposal (85), and threshold neighbors",
    ),
    "relationship.respect": BucketPolicy(
        dimension_id="relationship.respect",
        values=(-100.0, 0.0, 10.0, 14.0, 15.0, 25.0, 60.0, 100.0),
        thresholds=(10.0, 15.0, 25.0, 60.0),
        provenance="PNC_RelationshipConstants.lua",
        strategy_reason="Covers enemy max respect (10), friend respect (15), rival respect (25), proposal respect (60)",
    ),
    "relationship.familiarity": BucketPolicy(
        dimension_id="relationship.familiarity",
        values=(0.0, 4.0, 5.0, 30.0, 60.0, 80.0, 100.0),
        thresholds=(5.0, 60.0, 80.0),
        provenance="PNC_RelationshipConstants.lua",
        strategy_reason="Covers stranger (<5), known entry (5), friend bond (60), proposal (80)",
    ),
    "relationship.identityTrust": BucketPolicy(
        dimension_id="relationship.identityTrust",
        values=("unknown", "trusted", "untrustworthy"),
        thresholds=(),
        provenance="simulation_control_catalog.options",
        strategy_reason="Production identity trust options: unknown, trusted, untrustworthy",
    ),
}

# Production survival need thresholds from PNC_ColonyUIShared.NEED_METER_THRESHOLDS
# Hunger: 0.0, 0.15 (accent), 0.25 (warning), 0.45 (urgent), 1.00 (critical danger)
# Thirst: 0.0, 0.12 (accent), 0.25 (warning), 0.70 (urgent), 1.00 (critical danger)
# Fatigue: 0.0, 0.60 (accent), 0.70 (warning), 0.80 (urgent), 1.00 (critical danger)
NEED_BUCKETS: dict[str, BucketPolicy] = {
    "player.needs.hunger": BucketPolicy(
        dimension_id="player.needs.hunger",
        values=(0.0, 0.15, 0.25, 0.45, 0.80, 1.0),
        thresholds=(0.15, 0.25, 0.45),
        provenance="PNC_ColonyUIShared.lua",
        strategy_reason="Covers sated (0.0), noticeable (0.15), hungry (0.25), starving (0.45), extreme (1.0)",
    ),
    "npc.needs.hunger": BucketPolicy(
        dimension_id="npc.needs.hunger",
        values=(0.0, 0.15, 0.25, 0.45, 0.80, 1.0),
        thresholds=(0.15, 0.25, 0.45),
        provenance="PNC_ColonyUIShared.lua",
        strategy_reason="Covers NPC sated, noticeable, hungry, starving, extreme",
    ),
    "player.needs.thirst": BucketPolicy(
        dimension_id="player.needs.thirst",
        values=(0.0, 0.12, 0.25, 0.70, 1.0),
        thresholds=(0.12, 0.25, 0.70),
        provenance="PNC_ColonyUIShared.lua",
        strategy_reason="Covers quenched (0.0), noticeable (0.12), thirsty (0.25), parched (0.70), extreme (1.0)",
    ),
    "npc.needs.thirst": BucketPolicy(
        dimension_id="npc.needs.thirst",
        values=(0.0, 0.12, 0.25, 0.70, 1.0),
        thresholds=(0.12, 0.25, 0.70),
        provenance="PNC_ColonyUIShared.lua",
        strategy_reason="Covers NPC quenched, noticeable, thirsty, parched, extreme",
    ),
    "player.needs.fatigue": BucketPolicy(
        dimension_id="player.needs.fatigue",
        values=(0.0, 0.50, 0.60, 0.70, 0.80, 1.0),
        thresholds=(0.60, 0.70, 0.80),
        provenance="PNC_ColonyUIShared.lua",
        strategy_reason="Covers rested (0.0), tired (0.60), weary (0.70), exhausted (0.80), collapsed (1.0)",
    ),
    "npc.needs.fatigue": BucketPolicy(
        dimension_id="npc.needs.fatigue",
        values=(0.0, 0.50, 0.60, 0.70, 0.80, 1.0),
        thresholds=(0.60, 0.70, 0.80),
        provenance="PNC_ColonyUIShared.lua",
        strategy_reason="Covers NPC rested, tired, weary, exhausted, collapsed",
    ),
    "npc.needs.stress": BucketPolicy(
        dimension_id="npc.needs.stress",
        values=(0.0, 0.25, 0.50, 0.75, 1.0),
        thresholds=(0.25, 0.50, 0.75),
        provenance="PNC_Needs.lua",
        strategy_reason="Covers calm (0.0), tense (0.25), stressed (0.50), panicked (0.75), breaking (1.0)",
    ),
    "npc.needs.panic": BucketPolicy(
        dimension_id="npc.needs.panic",
        values=(0.0, 0.25, 0.50, 0.75, 1.0),
        thresholds=(0.25, 0.50, 0.75),
        provenance="PNC_Needs.lua",
        strategy_reason="Covers calm, slight panic, moderate panic, severe panic, extreme panic",
    ),
}

# Standard personality dimension buckets (0.0 to 1.0)
PERSONALITY_DIMENSIONS = (
    "persona.personality.aggression",
    "persona.personality.bravery",
    "persona.personality.compassion",
    "persona.personality.forgiveness",
    "persona.personality.loyalty",
    "persona.personality.materialism",
    "persona.personality.sociability",
)


def get_bucket_policy(dim: SweepDimension) -> BucketPolicy:
    """Return the bounded bucket policy for a dimension."""
    if dim.id in RELATIONSHIP_BUCKETS:
        return RELATIONSHIP_BUCKETS[dim.id]
    if dim.id in NEED_BUCKETS:
        return NEED_BUCKETS[dim.id]

    # Check aliases for needs
    if dim.id.startswith("player.stats.") or dim.id.startswith("player.needs."):
        suffix = dim.id.split(".")[-1]
        canonical = f"player.needs.{suffix}"
        if canonical in NEED_BUCKETS:
            return NEED_BUCKETS[canonical]
    if dim.id.startswith("npc.stats.") or dim.id.startswith("npc.needs."):
        suffix = dim.id.split(".")[-1]
        canonical = f"npc.needs.{suffix}"
        if canonical in NEED_BUCKETS:
            return NEED_BUCKETS[canonical]

    # Personality dimensions (0.0 to 1.0)
    if dim.id in PERSONALITY_DIMENSIONS or "personality" in dim.id:
        return BucketPolicy(
            dimension_id=dim.id,
            values=(0.0, 0.25, 0.50, 0.75, 1.0),
            thresholds=(0.25, 0.50, 0.75),
            provenance="production_personality_catalog",
            strategy_reason="Endpoints (0.0, 1.0), neutral baseline (0.5), and low/high representative values",
        )

    # Boolean
    if dim.value_type == "boolean":
        return BucketPolicy(
            dimension_id=dim.id,
            values=(False, True),
            provenance="boolean_domain",
            strategy_reason="Exhaustive boolean states",
        )

    # Enum
    if dim.value_type == "enum" and dim.options:
        return BucketPolicy(
            dimension_id=dim.id,
            values=dim.options,
            provenance=dim.options_source or "enum_options",
            strategy_reason=f"All declared production options ({len(dim.options)} values)",
        )

    # Generic numeric fallback
    if dim.value_type in ("number", "integer"):
        min_v = dim.min_value if dim.min_value is not None else 0.0
        max_v = dim.max_value if dim.max_value is not None else 1.0
        mid_v = (min_v + max_v) / 2.0
        if dim.value_type == "integer":
            min_v, mid_v, max_v = int(min_v), int(mid_v), int(max_v)
        return BucketPolicy(
            dimension_id=dim.id,
            values=(min_v, mid_v, max_v),
            thresholds=(mid_v,),
            provenance="numeric_endpoints_and_midpoint",
            strategy_reason="Min, midpoint, and max values",
        )

    # Default/text fallback
    return BucketPolicy(
        dimension_id=dim.id,
        values=("default",),
        provenance="default_single_value",
        strategy_reason="Single default placeholder",
    )


def build_bucket_inventory(inventory: SweepDimensionInventory) -> dict[str, BucketPolicy]:
    """Build a mapping of dimension ID to BucketPolicy for all sweepable dimensions."""
    policies = {}
    for dim_id, dim in inventory.dimensions.items():
        if dim.sweepable and not dim.read_only:
            policies[dim_id] = get_bucket_policy(dim)
    return policies
