"""CodeBuilder compiler for portable WorkDef & Scenario IR (psychopatz.work-scenario.v1)."""

from __future__ import annotations

import json
from collections.abc import Mapping
from pathlib import Path
from typing import Any

from .ai_ir_core import (
    AI_IR_GENERATED_MARKER_TEMPLATE,
    DOMAIN_RE,
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

WORK_SCENARIO_PACKAGE_SCHEMA = "psychopatz.work-scenario.package.v1"
WORK_SCENARIO_SHARD_SCHEMA = "psychopatz.work-scenario.v1"
WORK_SCENARIO_PLAN_SCHEMA = "psychopatz.work-scenario.runtime-plan.v1"
WORK_SCENARIO_GENERATED_MARKER = AI_IR_GENERATED_MARKER_TEMPLATE.format(
    schema=WORK_SCENARIO_SHARD_SCHEMA
)

VALID_EXECUTION_POLICIES = frozenset({"LIVE_ONLY", "ABSTRACT_SAFE", "HYBRID"})
VALID_TOIL_STEPS = frozenset({
    "ENSURE_TOOLS",
    "COLLECT_INPUTS",
    "APPROACH_TARGET",
    "WORK_TARGET",
    "DELIVER_OUTPUTS",
})


def _normalize_work_def(
    raw: Mapping[str, Any], *, owner: str, domain: str, source_rel: str
) -> dict[str, Any]:
    work_id = require_identifier(raw.get("id"), f"{source_rel}.workDef.id")
    op = require_identifier(raw.get("operation"), f"{work_id}.operation")
    exec_policy = str(raw.get("executionPolicy") or "HYBRID").upper()
    if exec_policy not in VALID_EXECUTION_POLICIES:
        raise CompileError(f"{source_rel}#{work_id}: invalid executionPolicy {exec_policy!r}")
    steps_raw = raw.get("toilSteps") or [
        "ENSURE_TOOLS",
        "COLLECT_INPUTS",
        "APPROACH_TARGET",
        "WORK_TARGET",
        "DELIVER_OUTPUTS",
    ]
    if not isinstance(steps_raw, list) or not steps_raw:
        raise CompileError(f"{source_rel}#{work_id}: toilSteps must be a non-empty list")
    steps: list[str] = []
    for idx, step in enumerate(steps_raw):
        step_name = str(step).upper()
        if step_name not in VALID_TOIL_STEPS:
            raise CompileError(f"{source_rel}#{work_id}.toilSteps[{idx}]: unknown step {step!r}")
        steps.append(step_name)

    work_def: dict[str, Any] = {
        "id": work_id,
        "owner": owner,
        "domain": domain,
        "operation": op,
        "job": require_identifier(raw.get("job"), f"{work_id}.job"),
        "requiredCapabilityTags": sorted(
            {require_identifier(t, f"{work_id}.requiredCapabilityTags") for t in (raw.get("requiredCapabilityTags") or [])}
        ),
        "forbiddenCapabilityTags": sorted(
            {require_identifier(t, f"{work_id}.forbiddenCapabilityTags") for t in (raw.get("forbiddenCapabilityTags") or [])}
        ),
        "usesFatigueGate": bool(raw.get("usesFatigueGate", True)),
        "executionPolicy": exec_policy,
        "toilSteps": steps,
    }
    if raw.get("toolTag") is not None:
        work_def["toolTag"] = require_identifier(raw["toolTag"], f"{work_id}.toolTag")
    if raw.get("animVar") is not None:
        work_def["animVar"] = require_identifier(raw["animVar"], f"{work_id}.animVar")
    return work_def


def _normalize_scenario(
    raw: Mapping[str, Any], *, owner: str, domain: str, source_rel: str
) -> dict[str, Any]:
    scen_id = require_identifier(raw.get("id"), f"{source_rel}.scenario.id")
    start_hr = require_int(raw.get("startHour", 0), f"{scen_id}.startHour", 0, 24)
    end_hr = require_int(raw.get("endHour", 24), f"{scen_id}.endHour", 0, 24)
    scen: dict[str, Any] = {
        "id": scen_id,
        "owner": owner,
        "domain": domain,
        "startHour": start_hr,
        "endHour": end_hr,
        "weight": require_number(raw.get("weight", 1.0), f"{scen_id}.weight", 0.0, 100.0),
        "requiredTags": sorted(
            {require_identifier(t, f"{scen_id}.requiredTags") for t in (raw.get("requiredTags") or [])}
        ),
    }
    for opt_field in ("adId", "workDefId", "nextScenarioId", "animVar", "barkKey"):
        if raw.get(opt_field) is not None:
            scen[opt_field] = require_identifier(raw[opt_field], f"{scen_id}.{opt_field}")
    return scen


def compile_work_scenario_package(
    package_root: str | Path,
    *,
    expected_owner: str | None = None,
) -> dict[str, Any]:
    """Compile and validate one owner's WorkDef & Scenario package."""
    root = Path(package_root).expanduser().resolve()
    pkg_path = root / "package.json"
    if not pkg_path.is_file():
        raise CompileError(f"WorkScenario package manifest not found: {pkg_path}")
    pkg_doc = json.loads(pkg_path.read_text(encoding="utf-8"))
    if not isinstance(pkg_doc, Mapping) or pkg_doc.get("schema") != WORK_SCENARIO_PACKAGE_SCHEMA:
        raise CompileError(f"{pkg_path}: expected schema {WORK_SCENARIO_PACKAGE_SCHEMA!r}")

    owner = normalize_owner(pkg_doc.get("owner"))
    if expected_owner is not None and owner != normalize_owner(expected_owner):
        raise CompileError(f"{pkg_path}: owner {owner!r} does not match expected {expected_owner!r}")
    scan_portability(pkg_doc, str(pkg_path))

    shards = pkg_doc.get("shards")
    if not isinstance(shards, list) or not shards:
        raise CompileError(f"{pkg_path}: requires non-empty shards list")
    overlays = load_package_overlays(root, pkg_doc.get("overlays"))

    work_defs: dict[str, dict[str, Any]] = {}
    scenarios: dict[str, dict[str, Any]] = {}
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
        if not isinstance(shard_doc, Mapping) or shard_doc.get("schema") != WORK_SCENARIO_SHARD_SCHEMA:
            raise CompileError(f"{shard_rel}: expected schema {WORK_SCENARIO_SHARD_SCHEMA!r}")
        shard_owner = normalize_owner(shard_doc.get("owner") or owner)
        if shard_owner != owner:
            raise CompileError(f"{shard_rel}: shard owner {shard_owner!r} != {owner!r}")
        domain = str(shard_doc.get("domain") or "Colony")
        if not DOMAIN_RE.match(domain):
            raise CompileError(f"{shard_rel}: invalid domain {domain!r}")

        shard_hash = sha256_json(shard_doc)
        dom_entry = domains.setdefault(domain, {"workDefs": [], "scenarios": []})

        for raw_wd in flatten_inheritance(
            shard_doc.get("workDefs") or [], source_label=f"{shard_rel}:workDefs"
        ):
            item = _normalize_work_def(raw_wd, owner=owner, domain=domain, source_rel=str(shard_rel))
            wid = item["id"]
            if wid in work_defs:
                raise CompileError(f"Duplicate workDef id {wid!r}")
            work_defs[wid] = item
            dom_entry["workDefs"].append(wid)
            source_map[wid] = {"sourceFile": str(shard_rel), "domain": domain, "contentHash": shard_hash}

        for raw_sc in flatten_inheritance(
            shard_doc.get("scenarios") or [], source_label=f"{shard_rel}:scenarios"
        ):
            item = _normalize_scenario(raw_sc, owner=owner, domain=domain, source_rel=str(shard_rel))
            sid = item["id"]
            if sid in scenarios:
                raise CompileError(f"Duplicate scenario id {sid!r}")
            scenarios[sid] = item
            dom_entry["scenarios"].append(sid)
            source_map[sid] = {"sourceFile": str(shard_rel), "domain": domain, "contentHash": shard_hash}

    for dom_entry in domains.values():
        dom_entry["workDefs"].sort()
        dom_entry["scenarios"].sort()

    plan: dict[str, Any] = {
        "schema": WORK_SCENARIO_PLAN_SCHEMA,
        "version": 1,
        "owner": owner,
        "package": str(pkg_doc.get("package") or f"{owner}.WorkScenario"),
        "workDefs": {k: work_defs[k] for k in sorted(work_defs)},
        "scenarios": {k: scenarios[k] for k in sorted(scenarios)},
        "domains": {k: domains[k] for k in sorted(domains)},
        "sourceMap": {k: source_map[k] for k in sorted(source_map)},
    }
    plan["fingerprint"] = sha256_json(plan)
    return plan


def compile_work_scenario_workspace(
    owner_repositories: Mapping[str, Path],
) -> dict[str, dict[str, Any]]:
    plans: dict[str, dict[str, Any]] = {}
    for owner, repo in sorted(owner_repositories.items()):
        desc = package_descriptor(owner)
        if desc.work_scenario_source_root_relative is None:
            continue
        pkg_dir = Path(repo).expanduser().resolve() / desc.work_scenario_source_root_relative
        if not (pkg_dir / "package.json").is_file():
            continue
        plan_a = compile_work_scenario_package(pkg_dir, expected_owner=owner)
        plan_b = compile_work_scenario_package(pkg_dir, expected_owner=owner)
        if plan_a["fingerprint"] != plan_b["fingerprint"]:
            raise CompileError(f"Non-deterministic WorkScenario compilation detected for {owner}")
        plans[owner] = plan_a
    return plans


def render_work_scenario_lua_artifacts(
    plan: Mapping[str, Any],
) -> list[tuple[str, str, str, tuple[str, ...]]]:
    owner = normalize_owner(plan["owner"])
    desc = package_descriptor(owner)
    prefix = desc.work_scenario_prefix or f"{owner}/WorkScenario"

    artifacts: list[tuple[str, str, str, tuple[str, ...]]] = []
    domain_mods: list[tuple[str, str]] = []

    for domain, dom_entry in sorted(plan["domains"].items()):
        dom_mod = f"{prefix}/Defs/{domain}"
        payload = {
            "workDefs": {k: plan["workDefs"][k] for k in dom_entry["workDefs"]},
            "scenarios": {k: plan["scenarios"][k] for k in dom_entry["scenarios"]},
        }
        lines = [
            WORK_SCENARIO_GENERATED_MARKER,
            f"-- Owner: {owner}  Domain: {domain}",
            "",
            "local DomainData = " + _lua_value(payload, indent=0),
            "",
            "return DomainData",
            "",
        ]
        all_ids = (*dom_entry["workDefs"], *dom_entry["scenarios"])
        src_files = tuple(
            sorted({str(plan["sourceMap"][eid]["sourceFile"]) for eid in all_ids if eid in plan["sourceMap"]})
        )
        artifacts.append((dom_mod, "\n".join(lines), f"lua:WorkScenarioDomain:{domain}", src_files))
        domain_mods.append((domain, dom_mod))

    reg_mod = f"{prefix}/Registry"
    ns_parts = prefix.split("/")
    root_ns = ns_parts[0]
    sub_ns = ns_parts[1] if len(ns_parts) > 1 else "WorkScenario"
    reg_lines = [
        WORK_SCENARIO_GENERATED_MARKER,
        f"-- Owner: {owner}  Package: {plan['package']}",
        "",
        f"{root_ns} = {root_ns} or {{}}",
        f"{root_ns}.{sub_ns} = {root_ns}.{sub_ns} or {{}}",
        "",
        "local Registry = {",
        f"    schema = {_lua_value(WORK_SCENARIO_PLAN_SCHEMA)},",
        f"    version = 1,",
        f"    owner = {_lua_value(owner)},",
        f"    package = {_lua_value(plan['package'])},",
        f"    fingerprint = {_lua_value(plan['fingerprint'])},",
        "    workDefs = {},",
        "    scenarios = {},",
        "}",
        "",
    ]
    for _dom, dom_mod in domain_mods:
        reg_lines.extend([
            f'local dom = require "{dom_mod}"',
            "for k, v in pairs(dom.workDefs or {}) do Registry.workDefs[k] = v end",
            "for k, v in pairs(dom.scenarios or {}) do Registry.scenarios[k] = v end",
        ])
    reg_lines.extend([
        "",
        "function Registry.GetWorkDef(workDefID)",
        "    return Registry.workDefs[tostring(workDefID or '')]",
        "end",
        "",
        "function Registry.GetScenario(scenarioID)",
        "    return Registry.scenarios[tostring(scenarioID or '')]",
        "end",
        "",
        f"{root_ns}.{sub_ns}.Registry = Registry",
        "return Registry",
        "",
    ])
    artifacts.append((reg_mod, "\n".join(reg_lines), "lua:WorkScenarioRegistry", ("package.json",)))
    return artifacts
