"""S12B/S12R1A machine-readable ConvoEngine dataset modernization inventory and closure authority.

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
from .semantic_dialogue_ir import SUPPORTED_SOURCE_SCHEMAS

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

CLOSURE_STATES = frozenset({
    "OPEN",
    "RESOLVED",
    "INTENTIONALLY_RETAINED",
    "NOT_APPLICABLE",
})

HOOK_STATES = frozenset({
    "HOOK_REQUIRED_PRESENT",
    "HOOK_NOT_APPLICABLE_JUSTIFIED",
    "HOOK_REQUIRED_MISSING",
    "NOT_APPLICABLE",
})

VALID_RETENTION_EVIDENCE_CODES = frozenset({
    "DISTINCT_GAMEPLAY_STATE_CONTRACT",
    "DISTINCT_SEMANTIC_ACT_OR_INTENT",
    "INCOMPATIBLE_ROLE_CARDINALITY",
    "DISTINCT_DOMAIN_AUTHORITY",
    "INCOMPATIBLE_ADMISSION_REPEAT_CLOSURE",
    "NON_PARAMETERIZABLE_PREDICATES",
    "SELECTION_SEMANTICS_LOSS",
})

FORBIDDEN_RETENTION_REASONS = frozenset({
    "owner_says_keep_it",
    "owner says keep it",
    "legacy_behavior",
    "legacy behavior",
    "different_filename",
    "different filename",
    "different_text",
    "different text",
    "different_category",
    "different category",
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

_GENDER_TOKENS = frozenset({"male", "female"})
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


def _has_template_placeholders(payload: Mapping[str, Any]) -> bool:
    for key in ("say", "response", "respond"):
        node = payload.get(key)
        if isinstance(node, str) and "{" in node and "}" in node:
            return True
        if isinstance(node, list):
            if any(isinstance(x, str) and "{" in x and "}" in x for x in node):
                return True
        if isinstance(node, Mapping):
            variants = node.get("variants")
            if isinstance(variants, list) and any(isinstance(x, str) and "{" in x and "}" in x for x in variants):
                return True
    return False


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


def _count_legacy_schema_readers(core_root: Path) -> int:
    """Count active pre-release legacy schema readers/PSDL-named active compiler surfaces."""
    count = 0
    if any(s != "psychopatz.convo-engine.v1" for s in SUPPORTED_SOURCE_SCHEMAS):
        count += 1
    codebuilder_dir = core_root / "tools" / "semantic_harness" / "codebuilder"
    for legacy_name in ("psdl_compiler.py", "psdl_compact.py", "psdl_inspect.py", "psdl_authoring_audit.py"):
        if (codebuilder_dir / legacy_name).is_file():
            count += 1
    return count


def _verify_retention_claim(
    claim: Mapping[str, Any] | None,
    member_records: list[dict[str, Any]],
    member_plans: list[Mapping[str, Any]],
) -> tuple[bool, dict[str, Any]]:
    """Mechanically verify whether an INTENTIONALLY_RETAINED claim is backed by real IR differences."""
    if not isinstance(claim, Mapping):
        return False, {"valid": False, "reason": "no_retention_claim"}

    code = str(claim.get("evidenceCode") or "").strip()
    reason = str(claim.get("reason") or "").strip()
    if reason.lower() in FORBIDDEN_RETENTION_REASONS or code.lower() in FORBIDDEN_RETENTION_REASONS:
        return False, {"valid": False, "reason": "forbidden_prose_or_blanket_waiver", "evidenceCode": code}
    if code not in VALID_RETENTION_EVIDENCE_CODES:
        return False, {"valid": False, "reason": "invalid_or_missing_evidence_code", "evidenceCode": code}
    if not reason:
        return False, {"valid": False, "reason": "empty_semantic_reason", "evidenceCode": code}

    member_count = len(member_records)
    if member_count < 2:
        return False, {"valid": False, "reason": "single_member_cannot_claim_group_retention", "evidenceCode": code}

    if code == "DISTINCT_GAMEPLAY_STATE_CONTRACT":
        contracts = {
            (
                r.get("executeContract"),
                repr((p.get("payload") or {}).get("statePolicy")),
                repr((p.get("payload") or {}).get("postconditions")),
                repr(((p.get("payload") or {}).get("invoke") or {}).get("action")),
            )
            for r, p in zip(member_records, member_plans)
        }
        ok = len(contracts) == member_count
        return ok, {
            "valid": ok,
            "evidenceCode": code,
            "reason": reason,
            "memberCount": member_count,
            "distinctContracts": len(contracts),
        }

    if code == "DISTINCT_SEMANTIC_ACT_OR_INTENT":
        acts = {
            (r.get("semanticAct"), r.get("semanticIntent"), r.get("semanticSubject"))
            for r in member_records
        }
        ok = len(acts) == member_count
        return ok, {
            "valid": ok,
            "evidenceCode": code,
            "reason": reason,
            "memberCount": member_count,
            "distinctActs": len(acts),
        }

    if code == "INCOMPATIBLE_ROLE_CARDINALITY":
        roles = {
            (tuple(r.get("currentRoles") or ()), repr((p.get("payload") or {}).get("participants")))
            for r, p in zip(member_records, member_plans)
        }
        ok = len(roles) == member_count
        return ok, {
            "valid": ok,
            "evidenceCode": code,
            "reason": reason,
            "memberCount": member_count,
            "distinctRoleContracts": len(roles),
        }

    if code == "DISTINCT_DOMAIN_AUTHORITY":
        auths = {
            (r.get("executeContract"), tuple(r.get("domainRefHooks") or ()), repr((p.get("payload") or {}).get("action")))
            for r, p in zip(member_records, member_plans)
        }
        ok = len(auths) == member_count
        return ok, {
            "valid": ok,
            "evidenceCode": code,
            "reason": reason,
            "memberCount": member_count,
            "distinctAuthorities": len(auths),
        }

    if code == "INCOMPATIBLE_ADMISSION_REPEAT_CLOSURE":
        policies = {
            (r.get("repeatPolicy"), r.get("closurePolicy"), repr((p.get("payload") or {}).get("inputPolicy")))
            for r, p in zip(member_records, member_plans)
        }
        ok = len(policies) == member_count
        return ok, {
            "valid": ok,
            "evidenceCode": code,
            "reason": reason,
            "memberCount": member_count,
            "distinctPolicies": len(policies),
        }

    if code == "NON_PARAMETERIZABLE_PREDICATES":
        pred_contracts = set()
        runtime_block_ids = set()
        text_targets = set()
        auth_contracts = set()
        for r, p in zip(member_records, member_plans):
            payload = p.get("payload") if isinstance(p.get("payload"), Mapping) else {}
            meta = payload.get("metadata") if isinstance(payload.get("metadata"), Mapping) else {}
            resp = payload.get("response") if isinstance(payload.get("response"), Mapping) else {}
            when_val = p.get("when") if p.get("when") is not None else payload.get("when")
            resp_act = resp.get("act")
            offers_repr = repr(resp.get("turns")) if resp else None
            pred_contracts.add((repr(when_val), resp_act, offers_repr, r.get("executeContract")))
            rb_id = str(meta.get("runtimeBlockID") or "").strip()
            if rb_id:
                runtime_block_ids.add(rb_id)
            tt = str(meta.get("textTarget") or "").strip()
            if tt:
                text_targets.add(tt)
            auth_contracts.add((
                r.get("executeContract"),
                resp_act,
                offers_repr,
                repr(payload.get("statePolicy")),
            ))

        blocker = str(claim.get("nonParameterizableBy") or "").strip()
        blocker_ok = False
        if blocker == "runtimeBlockID":
            blocker_ok = len(runtime_block_ids) == member_count and (
                len(text_targets) == member_count or len(auth_contracts) > 1
            )
        elif blocker == "incompatibleAuthorityOrResponse":
            blocker_ok = len(auth_contracts) == member_count

        ok = (len(pred_contracts) == member_count) and blocker_ok
        result: dict[str, Any] = {
            "valid": ok,
            "evidenceCode": code,
            "reason": reason if ok else "predicates_safely_parameterizable_without_structural_blocker",
            "memberCount": member_count,
            "distinctPredicates": len(pred_contracts),
            "nonParameterizableBy": blocker or None,
            "distinctRuntimeBlockIDs": len(runtime_block_ids),
        }
        return ok, result

    if code == "SELECTION_SEMANTICS_LOSS":
        shapes = {
            (
                tuple(sorted(((p.get("payload") or {}).get("reply") or {}).keys()))
                if isinstance((p.get("payload") or {}).get("reply"), Mapping)
                else (),
                repr((p.get("payload") or {}).get("after")),
                repr((p.get("payload") or {}).get("invoke")),
            )
            for p in member_plans
        }
        ok = len(shapes) == member_count
        return ok, {
            "valid": ok,
            "evidenceCode": code,
            "reason": reason,
            "memberCount": member_count,
            "distinctSelectionShapes": len(shapes),
        }

    return False, {"valid": False, "reason": "unhandled_evidence_code", "evidenceCode": code}


def build_modernization_inventory(
    core_repository: str | Path,
    *,
    hoomans_repository: str | Path | None = None,
    dynamic_trading_repository: str | Path | None = None,
    closure: bool = False,
    retention_claims: Mapping[str, Mapping[str, Any]] | None = None,
) -> dict[str, Any]:
    """Build the S12B/S12R1A machine-readable modernization inventory and closure authority."""
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
    plans = list(compiled.get("convoRuntimePlans") or ())
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

    prefix_members: dict[tuple[str, str, str], list[str]] = defaultdict(list)
    broad_members: dict[tuple[str, str, str], list[str]] = defaultdict(list)
    plans_by_id: dict[str, Mapping[str, Any]] = {}
    for plan in plans:
        fid = str(plan.get("id") or "")
        plans_by_id[fid] = plan
        owner = str(plan.get("owner") or "")
        kind = str(plan.get("kind") or "dialogue")
        prefix_members[(owner, kind, _group_prefix(fid))].append(fid)
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

        classes: list[str] = []
        parts = fid.split(".")
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

        dup_group: str | None = None
        prefix3 = _group_prefix(fid)
        broad2 = ".".join(parts[:2]) if len(parts) >= 2 else fid
        peer3 = prefix_members[(owner, kind, prefix3)]
        peer2 = broad_members[(owner, kind, broad2)]

        class_confidence = "high"
        class_reason = ""

        if kind == "dialogue":
            count_hits = part_set & _COUNT_TOKENS
            if "group" in count_hits and fid.startswith("ui.suggestion.group."):
                count_hits = count_hits - {"group"}
            if count_hits:
                classes.append("REDUNDANT_SPECIALIZATION")
                dup_group = f"participant_count:{owner}:{broad2}"
                class_reason = "participant_count_token_in_id"
            if (part_set & _WEAPON_TOKENS) or (part_set & _GENDER_TOKENS) or len(cand_slots) > len(current_slots):
                classes.append("SLOT_PARAMETERIZABLE")
                if len(peer3) > 1 or len(peer2) > 1:
                    classes.append("REDUNDANT_SPECIALIZATION")
                    dup_group = dup_group or f"slot_specialization:{owner}:{broad2}"
                class_reason = class_reason or "slot_parameterizable_context"
            if (part_set & _TONE_STYLE_TOKENS) and not mutating and (len(peer3) > 1 or len(peer2) > 1):
                # Only treat as a realization pool if there are actually multiple tone/style peers in the same prefix
                tone_peers = [p for p in peer3 if set(p.split(".")) & _TONE_STYLE_TOKENS]
                if len(tone_peers) > 1:
                    classes.append("REALIZATION_ONLY")
                    dup_group = dup_group or f"realization_pool:{owner}:{prefix3}"
                    class_reason = class_reason or "tone_or_style_token_in_id"
            if (part_set & (_TIME_TOKENS | _REL_TOKENS)) or plan.get("when") is not None or payload.get("when") is not None:
                classes.append("CONTEXT_VARIANT")
                if len(peer2) > 2 and dup_group is None:
                    dup_group = f"context_variant:{owner}:{broad2}"
                class_reason = class_reason or "context_or_predicate_variant"
            if not classes:
                if len(peer3) > 2 and not stateful:
                    classes.append("CONTEXT_VARIANT")
                    dup_group = f"domain_cluster:{owner}:{prefix3}"
                    class_reason = "uncollapsed_domain_cluster"
                elif _has_template_placeholders(payload) or len(peer3) > 1:
                    classes.append("STATIC_LITERAL")
                    class_confidence = "medium"
                    class_reason = "single_or_paired_literal_with_siblings_or_placeholders"
                else:
                    classes.append("STATIC_LITERAL")
                    class_confidence = "high"
                    class_reason = "isolated_non_mutating_literal"
        elif kind in ("beat", "behavior"):
            class_reason = f"{kind}_composition_component"
        elif kind == "realization":
            class_reason = "standalone_realization_pool"

        if not class_reason:
            class_reason = "domain_action_family" if "DOMAIN_ACTION" in classes else "classified_family"

        classes = sorted(set(classes), key=lambda c: sorted(MODERNIZATION_CLASSES).index(c))

        # Composition hook readiness for behaviors and beats
        has_any_hook = any(hooks.values())
        na_reason = str(meta.get("compositionHooksNotApplicableReason") or "").strip()
        if kind in ("beat", "behavior"):
            if has_any_hook and current_roles:
                hook_status = "HOOK_REQUIRED_PRESENT"
            elif na_reason and na_reason.lower() not in FORBIDDEN_RETENTION_REASONS:
                hook_status = "HOOK_NOT_APPLICABLE_JUSTIFIED"
            else:
                hook_status = "HOOK_REQUIRED_MISSING"
        else:
            hook_status = "NOT_APPLICABLE"

        if "LEGACY_SPLIT_AUTHORITY" in classes:
            rec_action = "collapse_split_authority_into_single_family"
        elif "SLOT_PARAMETERIZABLE" in classes and "REDUNDANT_SPECIALIZATION" in classes:
            rec_action = "collapse_into_slot_parameterized_family"
        elif "REALIZATION_ONLY" in classes and dup_group:
            rec_action = "merge_into_single_family_realization_variants"
        elif "DOMAIN_ACTION" in classes and not stateful:
            rec_action = "add_explicit_state_repeat_closure_policy_and_slots"
        elif "BEAT_COMPONENT" in classes or "ARCHETYPE_MEMBER" in classes:
            if hook_status == "HOOK_REQUIRED_MISSING":
                rec_action = "preserve_and_expose_director_hooks_and_roles"
            else:
                rec_action = "composition_ready"
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
            "classificationConfidence": class_confidence,
            "classificationReason": class_reason,
            "semanticAct": invoke.get("speechAct") or invoke.get("act") or on_node.get("speechAct") or meta.get("responseAct"),
            "semanticIntent": invoke.get("intent") or on_node.get("intent"),
            "semanticSubject": invoke.get("subject") or on_node.get("subject"),
            "currentRoles": current_roles,
            "candidateDynamicRoles": cand_roles,
            "currentSlots": current_slots,
            "candidateSlots": cand_slots,
            **hooks,
            "hookReadinessState": hook_status,
            "stateful": stateful,
            "mutating": mutating,
            "executeContract": exec_id,
            "repeatPolicy": repeat_policy,
            "closurePolicy": closure_policy,
            "realizationCount": realization_count,
            "testCoverageState": coverage_state,
            "possibleDuplicateSpecializationGroup": dup_group,
            "recommendedModernizationAction": rec_action,
            "closureState": "OPEN",
            "retentionEvidence": None,
        })

    records_by_id = {r["canonicalID"]: r for r in records}

    # Keep only multi-member duplicate/specialization groups
    groups: list[dict[str, Any]] = []
    for g in sorted(groups_map.values(), key=lambda x: (-len(x["members"]), x["groupId"])):
        if len(g["members"]) <= 1:
            continue
        gid = g["groupId"]
        member_recs = [records_by_id[m] for m in g["members"]]
        member_plans = [plans_by_id[m] for m in g["members"]]

        # Check explicit retention_claims arg first, then source metadata.modernizationRetention on first member
        claim = (retention_claims or {}).get(gid)
        if claim is None:
            for mp in member_plans:
                meta = (mp.get("payload") or {}).get("metadata") or {}
                if isinstance(meta, Mapping) and isinstance(meta.get("modernizationRetention"), Mapping):
                    claim = meta["modernizationRetention"]
                    break

        ok_retained, evidence = _verify_retention_claim(claim, member_recs, member_plans)
        g_closure = "INTENTIONALLY_RETAINED" if ok_retained else "OPEN"
        groups.append({
            **g,
            "memberCount": len(g["members"]),
            "closureState": g_closure,
            "retentionEvidence": evidence if claim is not None else None,
        })

    groups_by_id = {g["groupId"]: g for g in groups}
    for rec in records:
        gid = rec["possibleDuplicateSpecializationGroup"]
        if gid not in groups_by_id:
            rec["possibleDuplicateSpecializationGroup"] = None
            gid = None

        # Determine family closureState
        if gid is not None:
            grp = groups_by_id[gid]
            rec["closureState"] = grp["closureState"]
            rec["retentionEvidence"] = grp["retentionEvidence"]
        elif "LEGACY_SPLIT_AUTHORITY" in rec["classification"]:
            rec["closureState"] = "OPEN"
        elif rec["kind"] in ("beat", "behavior"):
            rec["closureState"] = "OPEN" if rec["hookReadinessState"] == "HOOK_REQUIRED_MISSING" else "RESOLVED"
        elif "DOMAIN_ACTION" in rec["classification"] and not rec["stateful"]:
            rec["closureState"] = "OPEN"
        elif rec["recommendedModernizationAction"] in (
            "collapse_into_slot_parameterized_family",
            "merge_into_single_family_realization_variants",
            "collapse_split_authority_into_single_family",
        ):
            rec["closureState"] = "OPEN"
        elif "STATIC_LITERAL" in rec["classification"] and rec["classificationConfidence"] == "low":
            rec["closureState"] = "OPEN"
        elif "STATIC_LITERAL" in rec["classification"] or rec["kind"] == "realization":
            rec["closureState"] = "NOT_APPLICABLE"
        else:
            rec["closureState"] = "RESOLVED"

    class_counts: dict[str, int] = defaultdict(int)
    closure_counts: dict[str, int] = defaultdict(int)
    unknown_owners = 0
    unclassified = 0
    open_families = 0
    retained_families = 0
    resolved_families = 0
    missing_hooks = 0

    for rec in records:
        if not rec["owner"] or not rec["source"]:
            unknown_owners += 1
        if not rec["classification"]:
            unclassified += 1
        for cls in rec["classification"]:
            class_counts[cls] += 1
        cstate = rec["closureState"]
        closure_counts[cstate] += 1
        if cstate == "OPEN":
            open_families += 1
        elif cstate == "INTENTIONALLY_RETAINED":
            retained_families += 1
        elif cstate == "RESOLVED":
            resolved_families += 1
        if rec["hookReadinessState"] == "HOOK_REQUIRED_MISSING":
            missing_hooks += 1

    open_groups = sum(1 for g in groups if g["closureState"] == "OPEN")
    retained_groups = sum(1 for g in groups if g["closureState"] == "INTENTIONALLY_RETAINED")
    legacy_readers = _count_legacy_schema_readers(core_root)
    split_count = len(split_findings)

    closure_ok = (
        len(records) == len(plans)
        and unknown_owners == 0
        and unclassified == 0
        and open_families == 0
        and open_groups == 0
        and split_count == 0
        and missing_hooks == 0
        and legacy_readers == 0
    )

    return {
        "ok": closure_ok if closure else (len(records) == len(plans) and unknown_owners == 0 and unclassified == 0),
        "closureOk": closure_ok,
        "schema": MODERNIZATION_INVENTORY_SCHEMA,
        "summary": {
            "catalogFamilyCount": len(plans),
            "inventoryFamilyCount": len(records),
            "unknownOwnershipCount": unknown_owners,
            "unclassifiedCount": unclassified,
            "duplicateGroupCount": len(groups),
            "splitAuthorityCount": split_count,
            "legacySplitAuthorityCount": split_count,
            "openActionableFamilyCount": open_families,
            "openActionableGroupCount": open_groups,
            "intentionallyRetainedCount": retained_families,
            "intentionallyRetainedGroupCount": retained_groups,
            "resolvedCount": resolved_families,
            "missingCompositionHookCount": missing_hooks,
            "legacySchemaReaderCount": legacy_readers,
            "byClassification": dict(sorted(class_counts.items())),
            "byClosureState": dict(sorted(closure_counts.items())),
        },
        "splitAuthorityFindings": split_findings,
        "groups": groups,
        "families": records,
    }


__all__ = [
    "CLOSURE_STATES",
    "FORBIDDEN_RETENTION_REASONS",
    "HOOK_STATES",
    "MODERNIZATION_CLASSES",
    "MODERNIZATION_INVENTORY_SCHEMA",
    "VALID_RETENTION_EVIDENCE_CODES",
    "build_modernization_inventory",
]
