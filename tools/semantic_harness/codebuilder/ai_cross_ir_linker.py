"""Two-pass cross-IR symbol linker across all five CodeBuilder IR domains."""

from __future__ import annotations

from collections.abc import Mapping
from typing import Any

from .ai_ir_core import AssetCatalog, load_b42_asset_catalog, sha256_json
from .errors import CompileError

BUILTIN_PRAGMATIC_ACTS = frozenset({
    "agree",
    "disagree",
    "praise",
    "criticize",
    "pacify",
    "greet",
    "antagonize",
    "defuse",
})


def _collect_convo_symbols(convo_model: Mapping[str, Any] | None) -> frozenset[str]:
    symbols: set[str] = set(BUILTIN_PRAGMATIC_ACTS)
    if not isinstance(convo_model, Mapping):
        return frozenset(symbols)
    for plan in convo_model.get("convoRuntimePlans") or ():
        if isinstance(plan, Mapping) and plan.get("id"):
            symbols.add(str(plan["id"]))
    for bucket_name in ("behaviors", "beats"):
        bucket = convo_model.get(bucket_name)
        if isinstance(bucket, Mapping):
            for rec in bucket.get("records") or ():
                if isinstance(rec, Mapping) and rec.get("id"):
                    symbols.add(str(rec["id"]))
    semantic = convo_model.get("semantic")
    if isinstance(semantic, Mapping):
        for flow in semantic.get("flows") or ():
            if isinstance(flow, Mapping) and flow.get("id"):
                symbols.add(str(flow["id"]))
    return frozenset(symbols)


def _collect_social_symbols(social_plans: Mapping[str, Mapping[str, Any]]) -> frozenset[str]:
    symbols: set[str] = set()
    for plan in social_plans.values():
        for ev_id in (plan.get("events") or {}).keys():
            symbols.add(str(ev_id))
        for alias in (plan.get("aliases") or {}).keys():
            symbols.add(str(alias))
    return frozenset(symbols)


def link_workspace_ai_irs(
    *,
    convo_model: Mapping[str, Any] | None = None,
    social_plans: Mapping[str, Mapping[str, Any]] | None = None,
    autonomy_plans: Mapping[str, Mapping[str, Any]] | None = None,
    reaction_plans: Mapping[str, Mapping[str, Any]] | None = None,
    work_scenario_plans: Mapping[str, Mapping[str, Any]] | None = None,
    asset_catalog: AssetCatalog | None = None,
) -> dict[str, Any]:
    """Pass 1: build global symbol tables; Pass 2: validate all cross-IR & asset links."""
    social_map = social_plans or {}
    autonomy_map = autonomy_plans or {}
    reaction_map = reaction_plans or {}
    work_map = work_scenario_plans or {}
    catalog = asset_catalog or load_b42_asset_catalog(None)

    convo_symbols = _collect_convo_symbols(convo_model)
    social_symbols = _collect_social_symbols(social_map)

    autonomy_ads: set[str] = set()
    for plan in autonomy_map.values():
        autonomy_ads.update(str(k) for k in (plan.get("ads") or {}).keys())

    reaction_barks: set[str] = set()
    for plan in reaction_map.values():
        reaction_barks.update(str(k) for k in (plan.get("barks") or {}).keys())

    work_defs: set[str] = set()
    scenarios: set[str] = set()
    for plan in work_map.values():
        work_defs.update(str(k) for k in (plan.get("workDefs") or {}).keys())
        scenarios.update(str(k) for k in (plan.get("scenarios") or {}).keys())

    linked_edges: list[tuple[str, str, str, str]] = []

    def require_symbol(
        owner: str,
        src_kind: str,
        src_id: str,
        field: str,
        target_id: str | None,
        table: frozenset[str] | set[str],
        target_kind: str,
    ) -> None:
        if not target_id:
            return
        if target_id not in table:
            raise CompileError(
                f"Cross-IR link error in {owner} {src_kind}#{src_id}.{field}: "
                f"unresolved {target_kind} {target_id!r}"
            )
        linked_edges.append((f"{src_kind}:{src_id}.{field}", target_kind, target_id, owner))

    for owner, plan in sorted(autonomy_map.items()):
        for sit_id, sit in sorted((plan.get("situations") or {}).items()):
            require_symbol(
                owner,
                "AutonomyAd.situation",
                sit_id,
                "convoFamilyId",
                sit.get("convoFamilyId"),
                convo_symbols,
                "ConvoEngine.family",
            )

    for owner, plan in sorted(reaction_map.items()):
        for rx_id, rx in sorted((plan.get("reactions") or {}).items()):
            require_symbol(
                owner,
                "ReactionPolicy.reaction",
                rx_id,
                "socialEventId",
                rx.get("socialEventId"),
                social_symbols,
                "SocialPolicy.event",
            )
            require_symbol(
                owner,
                "ReactionPolicy.reaction",
                rx_id,
                "convoActId",
                rx.get("convoActId"),
                convo_symbols,
                "ConvoEngine.family_or_act",
            )
            require_symbol(
                owner,
                "ReactionPolicy.reaction",
                rx_id,
                "workIntentId",
                rx.get("workIntentId"),
                work_defs,
                "WorkScenario.workDef",
            )
            require_symbol(
                owner,
                "ReactionPolicy.reaction",
                rx_id,
                "barkKey",
                rx.get("barkKey"),
                reaction_barks,
                "ReactionPolicy.bark",
            )
            require_symbol(
                owner,
                "ReactionPolicy.reaction",
                rx_id,
                "secondaryAnimVar",
                rx.get("secondaryAnimVar"),
                catalog.anim_variables,
                "Build42.AnimSet.variable",
            )

        for bark_id, bark in sorted((plan.get("barks") or {}).items()):
            require_symbol(
                owner,
                "ReactionPolicy.bark",
                bark_id,
                "voiceEvent",
                bark.get("voiceEvent"),
                catalog.voice_events,
                "NPCVoice.Catalog.Event",
            )
            require_symbol(
                owner,
                "ReactionPolicy.bark",
                bark_id,
                "convoFamilyId",
                bark.get("convoFamilyId"),
                convo_symbols,
                "ConvoEngine.family_or_act",
            )
            require_symbol(
                owner,
                "ReactionPolicy.bark",
                bark_id,
                "secondaryAnimVar",
                bark.get("secondaryAnimVar"),
                catalog.anim_variables,
                "Build42.AnimSet.variable",
            )

    for owner, plan in sorted(work_map.items()):
        for wd_id, wd in sorted((plan.get("workDefs") or {}).items()):
            require_symbol(
                owner,
                "WorkScenario.workDef",
                wd_id,
                "animVar",
                wd.get("animVar"),
                catalog.anim_variables,
                "Build42.AnimSet.variable",
            )
        for scen_id, scen in sorted((plan.get("scenarios") or {}).items()):
            require_symbol(
                owner,
                "WorkScenario.scenario",
                scen_id,
                "adId",
                scen.get("adId"),
                autonomy_ads,
                "AutonomyAd.ad",
            )
            require_symbol(
                owner,
                "WorkScenario.scenario",
                scen_id,
                "workDefId",
                scen.get("workDefId"),
                work_defs,
                "WorkScenario.workDef",
            )
            require_symbol(
                owner,
                "WorkScenario.scenario",
                scen_id,
                "nextScenarioId",
                scen.get("nextScenarioId"),
                scenarios,
                "WorkScenario.scenario",
            )
            require_symbol(
                owner,
                "WorkScenario.scenario",
                scen_id,
                "animVar",
                scen.get("animVar"),
                catalog.anim_variables,
                "Build42.AnimSet.variable",
            )
            require_symbol(
                owner,
                "WorkScenario.scenario",
                scen_id,
                "barkKey",
                scen.get("barkKey"),
                reaction_barks,
                "ReactionPolicy.bark",
            )

    linked_edges.sort()
    summary = {
        "counts": {
            "convoSymbols": len(convo_symbols),
            "socialEvents": len(social_symbols),
            "autonomyAds": len(autonomy_ads),
            "reactionBarks": len(reaction_barks),
            "workDefs": len(work_defs),
            "scenarios": len(scenarios),
            "linkedEdges": len(linked_edges),
        },
        "linkedEdges": linked_edges,
    }
    summary["fingerprint"] = sha256_json(summary)
    return summary
