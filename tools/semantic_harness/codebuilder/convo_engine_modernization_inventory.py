"""S12B machine-readable ConvoEngine dataset modernization inventory and classifier.

Derived directly from compiled ConvoEngine sources, completeness analysis, and
split-authority audits. Never maintains a separate manual semantic registry.
"""

from __future__ import annotations

from collections import defaultdict
from pathlib import Path
from typing import Any, Mapping

from .completeness_analyzer import analyze_portable_plan
from .conversation_compiler import compile_conversation_sources
from .convo_engine_integrity_audit import audit_split_action_authority

MODERNIZATION_INVENTORY_SCHEMA = "psychopatz.convo-engine.modernization-inventory.v1"

MODERNIZATION_CLASSES = frozenset({
    "STATIC_LITERAL",
    "SLOT_PARAMETERIZABLE",
    "CONTEXT_VARIANT",
    "BEAT_COMPONENT",
    "ARCHETYPE_MEMBER",
    "REDUNDANT_SPECIALIZATION",
    "DOMAIN_ACTION",
    "REALIZATION_ONLY",
    "LEGACY_SPLIT_AUTHORITY",
})

_TONE_STYLE_TOKENS = frozenset({
    "aggressive",
    "brave",
    "cold",
    "practical",
    "reserved",
    "shaken",
    "supportive",
    "friendly",
    "stressed",
    "guarded",
    "warm",
    "terse",
    "neutral",
    "default",
    "default_alt",
    "polite",
    "blunt",
    "panicked",
    "calm",
    "hostile",
    "suspicious",
    "cautious",
})

_GENDER_TOKENS = frozenset({"male", "female", "unknown"})
_TIME_TOKENS = frozenset({"dawn", "morning", "noon", "afternoon", "dusk", "evening", "night", "sunrise", "sunset"})
_REL_TOKENS = frozenset({"stranger", "acquaintance", "friend", "trusted", "companion", "family", "colonist", "ally", "hostile", "default"})
_WEAPON_TOKENS = frozenset({"axe_head", "blade_head", "blunt", "firearm", "unarmed", "spear", "knife"})
_COUNT_TOKENS = frozenset({"solo", "duo", "trio", "pair", "group", "crowd", "single", "multi", "two", "three"})


def _count_realizations(payload: Mapping[str, Any]) -> int:
    total = 0
    for key in ("say", "response", "respond"):
        node = payload.get(key)
        if isinstance(node, Mapping):
            variants = node.get("variants")
            if isinstance(variants, list):
                total += len(variants)
            realizations = node.get("realizations")
            if isinstance(realizations, Mapping):
                for r in realizations.values():
                    if isinstance(r, Mapping) and isinstance(r.get("variants"), list):
                        total += len(r["variants"])
                    else:
                        total += 1
        elif isinstance(node, list):
            total += len(node)
        elif isinstance(node, str) and node.strip():
            total += 1
    reply = payload.get("reply")
    if isinstance(reply, Mapping):
        for outcome_val in reply.values():
            if isinstance(outcome_val, Mapping):
                total += _count_realizations(outcome_val)
    forms = payload.get("forms")
    if isinstance(forms, Mapping):
        total += max(1, len(forms))
    translations = payload.get("translations")
    if isinstance(translations, Mapping) and total == 0:
        total += 1
    return max(total, 1)


def _extract_hooks(plan: Mapping[str, Any], payload: Mapping[str, Any]) -> dict[str, list[str]]:
    def _str_list(val: Any) -> list[str]:
        if isinstance(val, list):
            return [str(x) for x in val if x is not None and str(x).strip()]
        if isinstance(val, str) and val.strip():
            return [val.strip()]
        return []

    topics = sorted(set(_str_list(payload.get("topics")) + _str_list(plan.get("topics"))))
    events = sorted(set(_str_list(payload.get("events")) + _str_list(plan.get("events"))))
    activities = sorted(set(_str_list(payload.get("activities")) + _str_list(plan.get("activities"))))
    memories = sorted(set(_str_list(payload.get("memories")) + _str_list(plan.get("memories"))))
    domains = sorted(set(_str_list(payload.get("domains")) + _str_list(plan.get("domains"))))

    meta = payload.get("metadata") if isinstance(payload.get("metadata"), Mapping) else {}
    if meta.get("topic") and str(meta["topic"]) not in topics:
        topics.append(str(meta["topic"]))
    if meta.get("category") and str(meta["category"]) not in domains:
        domains.append(str(meta["category"]))

    return {
        "topicRefHooks": sorted(set(topics)),
        "eventRefHooks": sorted(set(events)),
        "activityRefHooks": sorted(set(activities)),
        "memoryRefHooks": sorted(set(memories)),
        "domainRefHooks": sorted(set(domains)),
    }


def _candidate_roles_and_slots(
    fid: str,
    kind: str,
    payload: Mapping[str, Any],
    current_roles: list[str],
    current_slots: list[str],
) -> tuple[list[str], list[str]]:
    parts = set(fid.split("."))
    cand_roles: list[str] = list(current_roles)
    if not cand_roles and kind == "dialogue":
        cand_roles = ["speaker", "addressee"]
    if any(t in parts for t in ("combat", "kill", "assaulted", "horde", "threat")) and "target" not in cand_roles:
        cand_roles.append("target")
    if any(t in parts for t in ("gossip", "rumors", "person", "whereabouts", "origin")) and "subject" not in cand_roles:
        cand_roles.append("subject")

    cand_slots: list[str] = list(current_slots)
    if any(t in parts for t in _WEAPON_TOKENS) and "weapon" not in cand_slots:
        cand_slots.append("weapon")
    if any(t in parts for t in _GENDER_TOKENS) and "subject" not in cand_slots:
        cand_slots.append("subject")
    if any(t in parts for t in ("destination", "whereabouts", "origin", "settlement", "camp")) and "location" not in cand_slots and "camp_site" not in cand_slots:
        cand_slots.append("location")
    if any(t in parts for t in ("item", "supplies", "gift", "trade")) and "item" not in cand_slots:
        cand_slots.append("item")
    if any(t in parts for t in ("horde", "threat", "bandits", "necroa")) and "threat" not in cand_slots:
        cand_slots.append("threat")
    return sorted(set(cand_roles)), sorted(set(cand_slots))


def _group_prefix(fid: str) -> str:
    parts = fid.split(".")
    if len(parts) >= 3:
        return ".".join(parts[:3])
    if len(parts) == 2:
        return ".".join(parts[:2])
    return fid


def build_modernization_inventory(
    core_repository: str | Path,
    *,
    hoomans_repository: str | Path | None = None,
    dynamic_trading_repository: str | Path | None = None,
) -> dict[str, Any]:
    """Build the S12B machine-readable modernization inventory for all maintained families."""
    core_root = Path(core_repository).expanduser().resolve()
    hoomans_root = (
        Path(hoomans_repository).expanduser().resolve()
        if hoomans_repository is not None
        else core_root.parent / "ProjectHoomans"
    )
    dt_root = (
        Path(dynamic_trading_repository).expanduser().resolve()
        if dynamic_trading_repository is not None
        else core_root.parent / "DynamicTrading"
    )
    pkg_repos = {
        "PsychopatzCore": core_root,
        "ProjectHoomans": hoomans_root,
        "DTCommon": dt_root,
    }
    compiled = compile_conversation_sources(core_root, package_repositories=pkg_repos)
    plans = list(compiled.get("psdlRuntimePlans") or ())
    portable_plan = compiled.get("portablePlan") or {}
    completeness = analyze_portable_plan(
        portable_plan,
        strict_manifest=True,
        workspace_roots=pkg_repos,
    )
    comp_families = completeness.get("families") or {}
    split_findings = audit_split_action_authority(plans)
    split_ids: set[str] = set()
    for finding in split_findings:
        for fid in finding.get("families") or ():
            split_ids.add(str(fid))

    # First pass: group families by structural specialization prefix to detect duplicate/specialization pools.
    prefix_members: dict[tuple[str, str, str], list[str]] = defaultdict(list)
    for plan in plans:
        fid = str(plan.get("id") or "")
        owner = str(plan.get("owner") or "")
        kind = str(plan.get("kind") or "dialogue")
        prefix = _group_prefix(fid)
        prefix_members[(owner, kind, prefix)].append(fid)

    # Also group by 2-segment prefix for broader domain families (e.g., social.greetings.*, combat.human_kill.*)
    broad_members: dict[tuple[str, str, str], list[str]] = defaultdict(list)
    for plan in plans:
        fid = str(plan.get("id") or "")
        owner = str(plan.get("owner") or "")
        kind = str(plan.get("kind") or "dialogue")
        parts = fid.split(".")
        broad = ".".join(parts[:2]) if len(parts) >= 2 else fid
        broad_members[(owner, kind, broad)].append(fid)

    records: list[dict[str, Any]] = []
    groups_map: dict[str, dict[str, Any]] = {}

    for plan in sorted(plans, key=lambda p: (str(p.get("owner") or ""), str(p.get("id") or ""))):
        fid = str(plan.get("id") or "")
        owner = str(plan.get("owner") or "")
        kind = str(plan.get("kind") or "dialogue")
        lineage = plan.get("lineage") if isinstance(plan.get("lineage"), Mapping) else {}
        source_path = str(lineage.get("sourcePath") or "")
        payload = plan.get("payload") if isinstance(plan.get("payload"), Mapping) else {}
        meta = payload.get("metadata") if isinstance(payload.get("metadata"), Mapping) else {}
        invoke = payload.get("invoke") if isinstance(payload.get("invoke"), Mapping) else {}
        on_node = payload.get("on") if isinstance(payload.get("on"), Mapping) else {}
        exec_val = payload.get("execute")
        exec_id = (
            str(exec_val.get("use") or "").strip()
            if isinstance(exec_val, Mapping)
            else (str(exec_val).strip() if exec_val else None)
        )
        action_obj = payload.get("action") if isinstance(payload.get("action"), Mapping) else {}
        mutating = bool(exec_id or action_obj.get("mutating") or invoke.get("action"))

        state_policy = payload.get("statePolicy")
        stateful = bool(state_policy or payload.get("repeatPolicy") or payload.get("closure") or payload.get("postconditions"))

        raw_participants = plan.get("participants") or payload.get("participants") or {}
        current_roles = sorted(str(k) for k in raw_participants.keys()) if isinstance(raw_participants, Mapping) else []
        raw_slots = plan.get("slots") or payload.get("slots") or {}
        current_slots = sorted(str(k) for k in raw_slots.keys()) if isinstance(raw_slots, Mapping) else []

        cand_roles, cand_slots = _candidate_roles_and_slots(fid, kind, payload, current_roles, current_slots)
        hooks = _extract_hooks(plan, payload)

        comp_row = comp_families.get(fid) or {}
        repeat_policy = comp_row.get("repeatPolicy") or payload.get("repeatPolicy")
        closure_policy = comp_row.get("closureClass") or (
            (payload.get("closure") or {}).get("closureClass")
            if isinstance(payload.get("closure"), Mapping)
            else None
        )
        coverage_state = str(comp_row.get("fixtureCoverage") or "unknown")
        realization_count = _count_realizations(payload)

        # Classification rules
        classes: list[str] = []
        parts = fid.split(".")
        last_tok = parts[-1] if parts else ""
        part_set = set(parts)

        if fid in split_ids:
            classes.append("LEGACY_SPLIT_AUTHORITY")
        if kind == "beat":
            classes.append("BEAT_COMPONENT")
        elif kind == "behavior":
            classes.append("ARCHETYPE_MEMBER")
        elif kind == "realization":
            classes.append("REALIZATION_ONLY")

        if mutating or exec_id:
            classes.append("DOMAIN_ACTION")

        # Detect duplicate/specialization groups
        dup_group: str | None = None
        prefix3 = _group_prefix(fid)
        broad2 = ".".join(parts[:2]) if len(parts) >= 2 else fid
        peer3 = prefix_members[(owner, kind, prefix3)]
        peer2 = broad_members[(owner, kind, broad2)]

        if kind == "dialogue":
            if part_set & _COUNT_TOKENS:
                classes.append("REDUNDANT_SPECIALIZATION")
                dup_group = f"participant_count:{owner}:{broad2}"
            if (part_set & _WEAPON_TOKENS) or (part_set & _GENDER_TOKENS) or len(cand_slots) > len(current_slots):
                classes.append("SLOT_PARAMETERIZABLE")
                if len(peer3) > 1 or len(peer2) > 1:
                    classes.append("REDUNDANT_SPECIALIZATION")
                    dup_group = dup_group or f"slot_specialization:{owner}:{broad2}"
            if (part_set & _TONE_STYLE_TOKENS) and not mutating:
                classes.append("REALIZATION_ONLY")
                if len(peer3) > 1 or len(peer2) > 1:
                    dup_group = dup_group or f"realization_pool:{owner}:{prefix3}"
            if (part_set & (_TIME_TOKENS | _REL_TOKENS)) or plan.get("when") is not None or payload.get("when") is not None:
                classes.append("CONTEXT_VARIANT")
                if len(peer2) > 2 and dup_group is None:
                    dup_group = f"context_variant:{owner}:{broad2}"
            if not classes:
                if len(peer3) > 2 and not stateful:
                    classes.append("CONTEXT_VARIANT")
                    dup_group = f"domain_cluster:{owner}:{prefix3}"
                else:
                    classes.append("STATIC_LITERAL")

        classes = sorted(set(classes), key=lambda c: sorted(MODERNIZATION_CLASSES).index(c))

        if "LEGACY_SPLIT_AUTHORITY" in classes:
            rec_action = "collapse_split_authority_into_single_family"
        elif "SLOT_PARAMETERIZABLE" in classes and "REDUNDANT_SPECIALIZATION" in classes:
            rec_action = "collapse_into_slot_parameterized_family"
        elif "REALIZATION_ONLY" in classes and dup_group:
            rec_action = "merge_into_single_family_realization_variants"
        elif "DOMAIN_ACTION" in classes and not stateful:
            rec_action = "add_explicit_state_repeat_closure_policy_and_slots"
        elif "BEAT_COMPONENT" in classes or "ARCHETYPE_MEMBER" in classes:
            rec_action = "preserve_and_expose_director_hooks_and_roles"
        elif "CONTEXT_VARIANT" in classes:
            rec_action = "parameterize_context_or_predicate_variants"
        else:
            rec_action = "verify_actor_neutrality_and_retain"

        if dup_group:
            grp = groups_map.setdefault(
                dup_group,
                {
                    "groupId": dup_group,
                    "owner": owner,
                    "kind": kind,
                    "recommendedAction": rec_action,
                    "members": [],
                },
            )
            grp["members"].append(fid)

        records.append({
            "canonicalID": fid,
            "owner": owner,
            "kind": kind,
            "source": source_path,
            "classification": classes,
            "semanticAct": invoke.get("act") or on_node.get("speechAct") or meta.get("responseAct"),
            "semanticIntent": invoke.get("intent") or on_node.get("intent"),
            "semanticSubject": invoke.get("subject") or on_node.get("subject"),
            "currentRoles": current_roles,
            "candidateDynamicRoles": cand_roles,
            "currentSlots": current_slots,
            "candidateSlots": cand_slots,
            **hooks,
            "stateful": stateful,
            "mutating": mutating,
            "executeContract": exec_id,
            "repeatPolicy": repeat_policy,
            "closurePolicy": closure_policy,
            "realizationCount": realization_count,
            "testCoverageState": coverage_state,
            "possibleDuplicateSpecializationGroup": dup_group,
            "recommendedModernizationAction": rec_action,
        })

    # Keep only multi-member duplicate/specialization groups
    groups = [
        {**g, "memberCount": len(g["members"])}
        for g in sorted(groups_map.values(), key=lambda x: (-len(x["members"]), x["groupId"]))
        if len(g["members"]) > 1
    ]
    valid_group_ids = {g["groupId"] for g in groups}
    for rec in records:
        if rec["possibleDuplicateSpecializationGroup"] not in valid_group_ids:
            rec["possibleDuplicateSpecializationGroup"] = None

    class_counts: dict[str, int] = defaultdict(int)
    unknown_owners = 0
    unclassified = 0
    for rec in records:
        if not rec["owner"] or not rec["source"]:
            unknown_owners += 1
        if not rec["classification"]:
            unclassified += 1
        for cls in rec["classification"]:
            class_counts[cls] += 1

    return {
        "ok": (
            len(records) == len(plans)
            and unknown_owners == 0
            and unclassified == 0
        ),
        "schema": MODERNIZATION_INVENTORY_SCHEMA,
        "summary": {
            "catalogFamilyCount": len(plans),
            "inventoryFamilyCount": len(records),
            "unknownOwnershipCount": unknown_owners,
            "unclassifiedCount": unclassified,
            "duplicateGroupCount": len(groups),
            "splitAuthorityCount": len(split_findings),
            "byClassification": dict(sorted(class_counts.items())),
        },
        "splitAuthorityFindings": split_findings,
        "groups": groups,
        "families": records,
    }


__all__ = [
    "MODERNIZATION_CLASSES",
    "MODERNIZATION_INVENTORY_SCHEMA",
    "build_modernization_inventory",
]
