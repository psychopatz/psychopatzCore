"""CodeBuilder compiler for portable ReactionPolicy IR (psychopatz.reaction-policy.v1)."""

from __future__ import annotations

import json
import math
from collections.abc import Mapping
from pathlib import Path
from typing import Any

from .ai_ir_core import (
    AI_IR_GENERATED_MARKER_TEMPLATE,
    DOMAIN_RE,
    VALID_TASKING_BANDS,
    apply_shard_overlays,
    flatten_inheritance,
    load_package_overlays,
    require_identifier,
    require_int,
    require_number,
    scan_portability,
    sha256_json,
)
from .dialogue_content import _lua_value
from .errors import CompileError
from .generation_ownership import normalize_owner, package_descriptor

REACTION_POLICY_PACKAGE_SCHEMA = "psychopatz.reaction-policy.package.v1"
REACTION_POLICY_SHARD_SCHEMA = "psychopatz.reaction-policy.v1"
REACTION_POLICY_PLAN_SCHEMA = "psychopatz.reaction-policy.runtime-plan.v1"
REACTION_POLICY_GENERATED_MARKER = AI_IR_GENERATED_MARKER_TEMPLATE.format(
    schema=REACTION_POLICY_SHARD_SCHEMA
)

VALID_REL_TIERS = frozenset({"any", "hostile", "rival", "neutral", "friend", "ally"})
VALID_REACTION_INTENTS = frozenset({
    "StopAndAssess",
    "BackAway",
    "Investigate",
    "WarnGroup",
    "SmartFlee",
    "Engage",
    "Ignore",
})
VALID_AGITATION_TRIGGERS = frozenset({
    "loiter_front",
    "loiter_behind",
    "loiter_vehicle",
    "bump",
    "weapon_draw",
    "antagonize",
    "defuse",
    "greet",
})


def _normalize_perception_profile(
    raw: Mapping[str, Any], *, owner: str, domain: str, source_rel: str
) -> dict[str, Any]:
    prof_id = require_identifier(raw.get("id"), f"{source_rel}.perceptionProfile.id")
    fov_deg = require_number(raw.get("fovDegrees", 120.0), f"{prof_id}.fovDegrees", 1.0, 360.0)
    cos_half_fov = round(math.cos(math.radians(fov_deg / 2.0)), 6)
    cad_raw = raw.get("cadenceMs") or {}
    if not isinstance(cad_raw, Mapping):
        raise CompileError(f"{source_rel}#{prof_id}: cadenceMs must be an object")
    cadence = {
        "combat": require_int(cad_raw.get("combat", 100), f"{prof_id}.cadenceMs.combat", 25, 10000),
        "alert": require_int(cad_raw.get("alert", 250), f"{prof_id}.cadenceMs.alert", 25, 10000),
        "moving": require_int(cad_raw.get("moving", 250), f"{prof_id}.cadenceMs.moving", 25, 10000),
        "idle": require_int(cad_raw.get("idle", 1000), f"{prof_id}.cadenceMs.idle", 50, 30000),
    }
    return {
        "id": prof_id,
        "owner": owner,
        "domain": domain,
        "fovDegrees": fov_deg,
        "cosHalfFov": cos_half_fov,
        "visionRange": require_number(
            raw.get("visionRange", 24.0), f"{prof_id}.visionRange", 1.0, 200.0
        ),
        "hearingRange": require_number(
            raw.get("hearingRange", 32.0), f"{prof_id}.hearingRange", 1.0, 300.0
        ),
        "cadenceMs": cadence,
        "clueMemoryTtlMs": require_int(
            raw.get("clueMemoryTtlMs", 20000), f"{prof_id}.clueMemoryTtlMs", 500, 600000
        ),
        "maxClues": require_int(raw.get("maxClues", 6), f"{prof_id}.maxClues", 1, 32),
    }


def _normalize_reaction(
    raw: Mapping[str, Any], *, owner: str, domain: str, source_rel: str
) -> dict[str, Any]:
    rx_id = require_identifier(raw.get("id"), f"{source_rel}.reaction.id")
    event_type = require_identifier(raw.get("eventType"), f"{rx_id}.eventType")
    archetype = require_identifier(raw.get("archetype", "default"), f"{rx_id}.archetype")
    rel_tier = str(raw.get("relTier") or "any").lower()
    if rel_tier not in VALID_REL_TIERS:
        raise CompileError(f"{source_rel}#{rx_id}: invalid relTier {rel_tier!r}")
    intent = str(raw.get("intent") or "")
    if intent not in VALID_REACTION_INTENTS:
        raise CompileError(f"{source_rel}#{rx_id}: invalid reaction intent {intent!r}")
    band = str(raw.get("band") or "HARD_EMERGENCY").upper()
    if band not in VALID_TASKING_BANDS:
        raise CompileError(f"{source_rel}#{rx_id}: invalid band {band!r}")

    rx: dict[str, Any] = {
        "id": rx_id,
        "owner": owner,
        "domain": domain,
        "eventType": event_type,
        "archetype": archetype,
        "relTier": rel_tier,
        "intent": intent,
        "band": band,
        "priority": require_int(raw.get("priority", 50), f"{rx_id}.priority", 0, 100),
    }
    for opt_field in (
        "secondaryAnimVar",
        "barkKey",
        "socialEventId",
        "convoActId",
        "workIntentId",
    ):
        if raw.get(opt_field) is not None:
            rx[opt_field] = require_identifier(raw[opt_field], f"{rx_id}.{opt_field}")
    return rx


def _normalize_agitation_rule(
    raw: Mapping[str, Any], *, owner: str, domain: str, source_rel: str
) -> dict[str, Any]:
    rule_id = require_identifier(raw.get("id"), f"{source_rel}.agitationRule.id")
    trigger = str(raw.get("trigger") or "")
    if trigger not in VALID_AGITATION_TRIGGERS:
        raise CompileError(f"{source_rel}#{rule_id}: invalid agitation trigger {trigger!r}")
    rule: dict[str, Any] = {
        "id": rule_id,
        "owner": owner,
        "domain": domain,
        "trigger": trigger,
        "delta": require_number(raw.get("delta"), f"{rule_id}.delta", -100.0, 100.0),
        "cooldownMs": require_int(raw.get("cooldownMs", 2000), f"{rule_id}.cooldownMs", 0, 600000),
        "decayPerSec": require_number(
            raw.get("decayPerSec", 2.0), f"{rule_id}.decayPerSec", 0.0, 50.0
        ),
    }
    if raw.get("stageThresholds") is not None:
        thresh = raw["stageThresholds"]
        if not isinstance(thresh, Mapping):
            raise CompileError(f"{source_rel}#{rule_id}: stageThresholds must be an object")
        rule["stageThresholds"] = {
            str(k): require_number(v, f"{rule_id}.stageThresholds.{k}", 0.0, 100.0)
            for k, v in sorted(thresh.items())
        }
    return rule


def _normalize_bark(
    raw: Mapping[str, Any], *, owner: str, domain: str, source_rel: str
) -> dict[str, Any]:
    bark_id = require_identifier(raw.get("id"), f"{source_rel}.bark.id")
    bark: dict[str, Any] = {
        "id": bark_id,
        "owner": owner,
        "domain": domain,
        "priority": require_int(raw.get("priority", 40), f"{bark_id}.priority", 0, 100),
        "cooldownMs": require_int(raw.get("cooldownMs", 6000), f"{bark_id}.cooldownMs", 0, 600000),
        "exhaustionDecay": require_number(
            raw.get("exhaustionDecay", 0.5), f"{bark_id}.exhaustionDecay", 0.0, 1.0
        ),
    }
    for opt_field in ("voiceEvent", "convoFamilyId", "secondaryAnimVar"):
        if raw.get(opt_field) is not None:
            bark[opt_field] = require_identifier(raw[opt_field], f"{bark_id}.{opt_field}")
    return bark


def compile_reaction_policy_package(
    package_root: str | Path,
    *,
    expected_owner: str | None = None,
) -> dict[str, Any]:
    """Compile and validate one owner's ReactionPolicy package."""
    root = Path(package_root).expanduser().resolve()
    pkg_path = root / "package.json"
    if not pkg_path.is_file():
        raise CompileError(f"ReactionPolicy package manifest not found: {pkg_path}")
    pkg_doc = json.loads(pkg_path.read_text(encoding="utf-8"))
    if not isinstance(pkg_doc, Mapping) or pkg_doc.get("schema") != REACTION_POLICY_PACKAGE_SCHEMA:
        raise CompileError(f"{pkg_path}: expected schema {REACTION_POLICY_PACKAGE_SCHEMA!r}")

    owner = normalize_owner(pkg_doc.get("owner"))
    if expected_owner is not None and owner != normalize_owner(expected_owner):
        raise CompileError(f"{pkg_path}: owner {owner!r} does not match expected {expected_owner!r}")
    scan_portability(pkg_doc, str(pkg_path))

    shards = pkg_doc.get("shards")
    if not isinstance(shards, list) or not shards:
        raise CompileError(f"{pkg_path}: requires non-empty shards list")
    overlays = load_package_overlays(root, pkg_doc.get("overlays"))

    profiles: dict[str, dict[str, Any]] = {}
    reactions: dict[str, dict[str, Any]] = {}
    agitation_rules: dict[str, dict[str, Any]] = {}
    barks: dict[str, dict[str, Any]] = {}
    domains: dict[str, dict[str, list[str]]] = {}
    source_map: dict[str, dict[str, Any]] = {}

    for shard_rel in shards:
        shard_path = (root / str(shard_rel)).resolve()
        if not shard_path.is_file():
            raise CompileError(f"{pkg_path}: shard file not found: {shard_rel}")
        shard_doc = json.loads(shard_path.read_text(encoding="utf-8"))
        if overlays:
            shard_doc = apply_shard_overlays(shard_doc, shard_rel=str(shard_rel), overlay_docs=overlays)
        scan_portability(shard_doc, str(shard_rel))
        if not isinstance(shard_doc, Mapping) or shard_doc.get("schema") != REACTION_POLICY_SHARD_SCHEMA:
            raise CompileError(f"{shard_rel}: expected schema {REACTION_POLICY_SHARD_SCHEMA!r}")
        shard_owner = normalize_owner(shard_doc.get("owner") or owner)
        if shard_owner != owner:
            raise CompileError(f"{shard_rel}: shard owner {shard_owner!r} != {owner!r}")
        domain = str(shard_doc.get("domain") or "Reactivity")
        if not DOMAIN_RE.match(domain):
            raise CompileError(f"{shard_rel}: invalid domain {domain!r}")

        shard_hash = sha256_json(shard_doc)
        dom_entry = domains.setdefault(
            domain,
            {"perceptionProfiles": [], "reactions": [], "agitationRules": [], "barks": []},
        )

        for raw_prof in flatten_inheritance(
            shard_doc.get("perceptionProfiles") or [], source_label=f"{shard_rel}:perceptionProfiles"
        ):
            item = _normalize_perception_profile(
                raw_prof, owner=owner, domain=domain, source_rel=str(shard_rel)
            )
            iid = item["id"]
            if iid in profiles:
                raise CompileError(f"Duplicate perceptionProfile id {iid!r}")
            profiles[iid] = item
            dom_entry["perceptionProfiles"].append(iid)
            source_map[iid] = {"sourceFile": str(shard_rel), "domain": domain, "contentHash": shard_hash}

        for raw_rx in flatten_inheritance(
            shard_doc.get("reactions") or [], source_label=f"{shard_rel}:reactions"
        ):
            item = _normalize_reaction(raw_rx, owner=owner, domain=domain, source_rel=str(shard_rel))
            iid = item["id"]
            if iid in reactions:
                raise CompileError(f"Duplicate reaction id {iid!r}")
            reactions[iid] = item
            dom_entry["reactions"].append(iid)
            source_map[iid] = {"sourceFile": str(shard_rel), "domain": domain, "contentHash": shard_hash}

        for raw_rule in flatten_inheritance(
            shard_doc.get("agitationRules") or [], source_label=f"{shard_rel}:agitationRules"
        ):
            item = _normalize_agitation_rule(
                raw_rule, owner=owner, domain=domain, source_rel=str(shard_rel)
            )
            iid = item["id"]
            if iid in agitation_rules:
                raise CompileError(f"Duplicate agitationRule id {iid!r}")
            agitation_rules[iid] = item
            dom_entry["agitationRules"].append(iid)
            source_map[iid] = {"sourceFile": str(shard_rel), "domain": domain, "contentHash": shard_hash}

        for raw_bark in flatten_inheritance(
            shard_doc.get("barks") or [], source_label=f"{shard_rel}:barks"
        ):
            item = _normalize_bark(raw_bark, owner=owner, domain=domain, source_rel=str(shard_rel))
            iid = item["id"]
            if iid in barks:
                raise CompileError(f"Duplicate bark id {iid!r}")
            barks[iid] = item
            dom_entry["barks"].append(iid)
            source_map[iid] = {"sourceFile": str(shard_rel), "domain": domain, "contentHash": shard_hash}

    for dom_entry in domains.values():
        for bucket in dom_entry.values():
            bucket.sort()

    plan: dict[str, Any] = {
        "schema": REACTION_POLICY_PLAN_SCHEMA,
        "version": 1,
        "owner": owner,
        "package": str(pkg_doc.get("package") or f"{owner}.ReactionPolicy"),
        "perceptionProfiles": {k: profiles[k] for k in sorted(profiles)},
        "reactions": {k: reactions[k] for k in sorted(reactions)},
        "agitationRules": {k: agitation_rules[k] for k in sorted(agitation_rules)},
        "barks": {k: barks[k] for k in sorted(barks)},
        "domains": {k: domains[k] for k in sorted(domains)},
        "sourceMap": {k: source_map[k] for k in sorted(source_map)},
    }
    plan["fingerprint"] = sha256_json(plan)
    return plan


def compile_reaction_policy_workspace(
    owner_repositories: Mapping[str, Path],
) -> dict[str, dict[str, Any]]:
    plans: dict[str, dict[str, Any]] = {}
    for owner, repo in sorted(owner_repositories.items()):
        desc = package_descriptor(owner)
        if desc.reaction_policy_source_root_relative is None:
            continue
        pkg_dir = Path(repo).expanduser().resolve() / desc.reaction_policy_source_root_relative
        if not (pkg_dir / "package.json").is_file():
            continue
        plan_a = compile_reaction_policy_package(pkg_dir, expected_owner=owner)
        plan_b = compile_reaction_policy_package(pkg_dir, expected_owner=owner)
        if plan_a["fingerprint"] != plan_b["fingerprint"]:
            raise CompileError(f"Non-deterministic ReactionPolicy compilation detected for {owner}")
        plans[owner] = plan_a
    return plans


def render_reaction_policy_lua_artifacts(
    plan: Mapping[str, Any],
) -> list[tuple[str, str, str, tuple[str, ...]]]:
    owner = normalize_owner(plan["owner"])
    desc = package_descriptor(owner)
    prefix = desc.reaction_policy_prefix or f"{owner}/ReactionPolicy"

    artifacts: list[tuple[str, str, str, tuple[str, ...]]] = []
    domain_mods: list[tuple[str, str]] = []

    for domain, dom_entry in sorted(plan["domains"].items()):
        dom_mod = f"{prefix}/Policies/{domain}"
        payload = {
            "perceptionProfiles": {k: plan["perceptionProfiles"][k] for k in dom_entry["perceptionProfiles"]},
            "reactions": {k: plan["reactions"][k] for k in dom_entry["reactions"]},
            "agitationRules": {k: plan["agitationRules"][k] for k in dom_entry["agitationRules"]},
            "barks": {k: plan["barks"][k] for k in dom_entry["barks"]},
        }
        lines = [
            REACTION_POLICY_GENERATED_MARKER,
            f"-- Owner: {owner}  Domain: {domain}",
            "",
            "local DomainData = " + _lua_value(payload, indent=0),
            "",
            "return DomainData",
            "",
        ]
        all_ids = (
            *dom_entry["perceptionProfiles"],
            *dom_entry["reactions"],
            *dom_entry["agitationRules"],
            *dom_entry["barks"],
        )
        src_files = tuple(
            sorted({str(plan["sourceMap"][eid]["sourceFile"]) for eid in all_ids if eid in plan["sourceMap"]})
        )
        artifacts.append((dom_mod, "\n".join(lines), f"lua:ReactionPolicyDomain:{domain}", src_files))
        domain_mods.append((domain, dom_mod))

    reg_mod = f"{prefix}/Registry"
    ns_parts = prefix.split("/")
    root_ns = ns_parts[0]
    sub_ns = ns_parts[1] if len(ns_parts) > 1 else "ReactionPolicy"
    reg_lines = [
        REACTION_POLICY_GENERATED_MARKER,
        f"-- Owner: {owner}  Package: {plan['package']}",
        "",
        f"{root_ns} = {root_ns} or {{}}",
        f"{root_ns}.{sub_ns} = {root_ns}.{sub_ns} or {{}}",
        "",
        "local Registry = {",
        f"    schema = {_lua_value(REACTION_POLICY_PLAN_SCHEMA)},",
        f"    version = 1,",
        f"    owner = {_lua_value(owner)},",
        f"    package = {_lua_value(plan['package'])},",
        f"    fingerprint = {_lua_value(plan['fingerprint'])},",
        "    perceptionProfiles = {},",
        "    reactions = {},",
        "    agitationRules = {},",
        "    barks = {},",
        "}",
        "",
    ]
    for _dom, dom_mod in domain_mods:
        reg_lines.extend([
            f'local dom = require "{dom_mod}"',
            "for k, v in pairs(dom.perceptionProfiles or {}) do Registry.perceptionProfiles[k] = v end",
            "for k, v in pairs(dom.reactions or {}) do Registry.reactions[k] = v end",
            "for k, v in pairs(dom.agitationRules or {}) do Registry.agitationRules[k] = v end",
            "for k, v in pairs(dom.barks or {}) do Registry.barks[k] = v end",
        ])
    reg_lines.extend([
        "",
        "function Registry.GetProfile(profileID)",
        "    return Registry.perceptionProfiles[tostring(profileID or '')]",
        "end",
        "",
        "function Registry.GetReaction(reactionID)",
        "    return Registry.reactions[tostring(reactionID or '')]",
        "end",
        "",
        "function Registry.GetBark(barkID)",
        "    return Registry.barks[tostring(barkID or '')]",
        "end",
        "",
        f"{root_ns}.{sub_ns}.Registry = Registry",
        "return Registry",
        "",
    ])
    artifacts.append((reg_mod, "\n".join(reg_lines), "lua:ReactionPolicyRegistry", ("package.json",)))
    return artifacts
