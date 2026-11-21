"""CodeBuilder compiler for portable AutonomyAd IR (psychopatz.autonomy-ad.v1)."""

from __future__ import annotations

import json
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

AUTONOMY_AD_PACKAGE_SCHEMA = "psychopatz.autonomy-ad.package.v1"
AUTONOMY_AD_SHARD_SCHEMA = "psychopatz.autonomy-ad.v1"
AUTONOMY_AD_PLAN_SCHEMA = "psychopatz.autonomy-ad.runtime-plan.v1"
AUTONOMY_AD_GENERATED_MARKER = AI_IR_GENERATED_MARKER_TEMPLATE.format(
    schema=AUTONOMY_AD_SHARD_SCHEMA
)

_ALLOWED_AD_BANDS = frozenset({"OPTIONAL", "IDLE", "NORMAL_NEED", "CRITICAL_NEED"})


def _normalize_weight_map(raw: Any, label: str, lo: float, hi: float) -> dict[str, float]:
    if raw is None:
        return {}
    if not isinstance(raw, Mapping):
        raise CompileError(f"{label} must be an object")
    out: dict[str, float] = {}
    for k, v in sorted(raw.items()):
        key = require_identifier(k, f"{label}.key")
        out[key] = require_number(v, f"{label}[{key}]", lo, hi)
    return out


def _normalize_curve(raw: Any, label: str) -> list[dict[str, float]]:
    if not isinstance(raw, list) or not raw:
        raise CompileError(f"{label} must be a non-empty list of {{value, score}} points")
    points: list[dict[str, float]] = []
    for idx, pt in enumerate(raw):
        if not isinstance(pt, Mapping):
            raise CompileError(f"{label}[{idx}] must be an object")
        val = require_number(pt.get("value"), f"{label}[{idx}].value", -1000.0, 1000.0)
        score = require_number(pt.get("score"), f"{label}[{idx}].score", 0.0, 1.0)
        points.append({"value": val, "score": score})
    points.sort(key=lambda item: item["value"])
    return points


def _normalize_ad(raw: Mapping[str, Any], *, owner: str, domain: str, source_rel: str) -> dict[str, Any]:
    ad_id = require_identifier(raw.get("id"), f"{source_rel}.ad.id")
    band = str(raw.get("band") or "OPTIONAL").upper()
    if band not in VALID_TASKING_BANDS or band not in _ALLOWED_AD_BANDS:
        raise CompileError(f"{source_rel}#{ad_id}: unsupported AutonomyAd band {band!r}")
    capability = require_identifier(raw.get("capability"), f"{source_rel}#{ad_id}.capability")
    curve = _normalize_curve(raw.get("curve"), f"{source_rel}#{ad_id}.curve")

    hyst_raw = raw.get("hysteresis") or {}
    if not isinstance(hyst_raw, Mapping):
        raise CompileError(f"{source_rel}#{ad_id}: hysteresis must be an object")
    hysteresis = {
        "enter": require_number(hyst_raw.get("enter", 0.35), f"{ad_id}.hysteresis.enter", 0.0, 1.0),
        "exit": require_number(hyst_raw.get("exit", 0.20), f"{ad_id}.hysteresis.exit", 0.0, 1.0),
        "critical": require_number(
            hyst_raw.get("critical", 0.85), f"{ad_id}.hysteresis.critical", 0.0, 1.0
        ),
    }

    ad: dict[str, Any] = {
        "id": ad_id,
        "owner": owner,
        "domain": domain,
        "capability": capability,
        "band": band,
        "curve": curve,
        "hysteresis": hysteresis,
        "cooldownMs": require_int(raw.get("cooldownMs", 5000), f"{ad_id}.cooldownMs", 0, 3600000),
        "traitWeights": _normalize_weight_map(
            raw.get("traitWeights"), f"{ad_id}.traitWeights", -1.0, 1.0
        ),
        "moodWeights": _normalize_weight_map(
            raw.get("moodWeights"), f"{ad_id}.moodWeights", -1.0, 1.0
        ),
        "distanceWeight": require_number(
            raw.get("distanceWeight", 0.15), f"{ad_id}.distanceWeight", 0.0, 1.0
        ),
        "maxRange": require_number(raw.get("maxRange", 24.0), f"{ad_id}.maxRange", 1.0, 500.0),
        "tags": sorted({str(t) for t in (raw.get("tags") or [])}),
    }
    if raw.get("needKey") is not None:
        ad["needKey"] = require_identifier(raw["needKey"], f"{ad_id}.needKey")
    if raw.get("animScene") is not None:
        ad["animScene"] = require_identifier(raw["animScene"], f"{ad_id}.animScene")
    return ad


def _normalize_situation(
    raw: Mapping[str, Any], *, owner: str, domain: str, source_rel: str
) -> dict[str, Any]:
    sit_id = require_identifier(raw.get("id"), f"{source_rel}.situation.id")
    min_p = require_int(raw.get("minParticipants", 2), f"{sit_id}.minParticipants", 2, 8)
    max_p = require_int(raw.get("maxParticipants", min_p), f"{sit_id}.maxParticipants", min_p, 8)
    roles_raw = raw.get("roles")
    if not isinstance(roles_raw, list) or not roles_raw:
        raise CompileError(f"{source_rel}#{sit_id}: roles must be a non-empty list")
    roles = [require_identifier(r, f"{sit_id}.roles[{i}]") for i, r in enumerate(roles_raw)]

    sit: dict[str, Any] = {
        "id": sit_id,
        "owner": owner,
        "domain": domain,
        "minParticipants": min_p,
        "maxParticipants": max_p,
        "maxRadius": require_number(raw.get("maxRadius", 4.5), f"{sit_id}.maxRadius", 0.5, 50.0),
        "roles": roles,
        "socialOpportunityId": require_identifier(
            raw.get("socialOpportunityId"), f"{sit_id}.socialOpportunityId"
        ),
        "cooldownMs": require_int(raw.get("cooldownMs", 30000), f"{sit_id}.cooldownMs", 0, 3600000),
    }
    if raw.get("convoFamilyId") is not None:
        sit["convoFamilyId"] = require_identifier(raw["convoFamilyId"], f"{sit_id}.convoFamilyId")
    return sit


def compile_autonomy_ad_package(
    package_root: str | Path,
    *,
    expected_owner: str | None = None,
) -> dict[str, Any]:
    """Compile and validate one owner's AutonomyAd package (with inheritance & overlays)."""
    root = Path(package_root).expanduser().resolve()
    pkg_path = root / "package.json"
    if not pkg_path.is_file():
        raise CompileError(f"AutonomyAd package manifest not found: {pkg_path}")
    pkg_doc = json.loads(pkg_path.read_text(encoding="utf-8"))
    if not isinstance(pkg_doc, Mapping) or pkg_doc.get("schema") != AUTONOMY_AD_PACKAGE_SCHEMA:
        raise CompileError(f"{pkg_path}: expected schema {AUTONOMY_AD_PACKAGE_SCHEMA!r}")

    owner = normalize_owner(pkg_doc.get("owner"))
    if expected_owner is not None and owner != normalize_owner(expected_owner):
        raise CompileError(f"{pkg_path}: owner {owner!r} does not match expected {expected_owner!r}")
    scan_portability(pkg_doc, str(pkg_path))

    shards = pkg_doc.get("shards")
    if not isinstance(shards, list) or not shards:
        raise CompileError(f"{pkg_path}: requires non-empty shards list")
    overlays = load_package_overlays(root, pkg_doc.get("overlays"))

    ads_by_id: dict[str, dict[str, Any]] = {}
    sits_by_id: dict[str, dict[str, Any]] = {}
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
        if not isinstance(shard_doc, Mapping) or shard_doc.get("schema") != AUTONOMY_AD_SHARD_SCHEMA:
            raise CompileError(f"{shard_rel}: expected schema {AUTONOMY_AD_SHARD_SCHEMA!r}")
        shard_owner = normalize_owner(shard_doc.get("owner") or owner)
        if shard_owner != owner:
            raise CompileError(f"{shard_rel}: shard owner {shard_owner!r} != {owner!r}")
        domain = str(shard_doc.get("domain") or "Autonomy")
        if not DOMAIN_RE.match(domain):
            raise CompileError(f"{shard_rel}: invalid domain {domain!r}")

        raw_ads = shard_doc.get("ads") or []
        raw_sits = shard_doc.get("situations") or []
        if not isinstance(raw_ads, list) or not isinstance(raw_sits, list):
            raise CompileError(f"{shard_rel}: ads and situations must be lists")

        shard_hash = sha256_json(shard_doc)
        dom_entry = domains.setdefault(domain, {"ads": [], "situations": []})

        for raw_ad in flatten_inheritance(raw_ads, source_label=f"{shard_rel}:ads"):
            ad = _normalize_ad(raw_ad, owner=owner, domain=domain, source_rel=str(shard_rel))
            ad_id = ad["id"]
            if ad_id in ads_by_id:
                raise CompileError(f"Duplicate AutonomyAd id {ad_id!r} in {owner}")
            ads_by_id[ad_id] = ad
            dom_entry["ads"].append(ad_id)
            source_map[ad_id] = {"sourceFile": str(shard_rel), "domain": domain, "contentHash": shard_hash}

        for raw_sit in flatten_inheritance(raw_sits, source_label=f"{shard_rel}:situations"):
            sit = _normalize_situation(
                raw_sit, owner=owner, domain=domain, source_rel=str(shard_rel)
            )
            sit_id = sit["id"]
            if sit_id in sits_by_id:
                raise CompileError(f"Duplicate AutonomyAd situation id {sit_id!r} in {owner}")
            sits_by_id[sit_id] = sit
            dom_entry["situations"].append(sit_id)
            source_map[sit_id] = {"sourceFile": str(shard_rel), "domain": domain, "contentHash": shard_hash}

    for dom_entry in domains.values():
        dom_entry["ads"].sort()
        dom_entry["situations"].sort()

    plan: dict[str, Any] = {
        "schema": AUTONOMY_AD_PLAN_SCHEMA,
        "version": 1,
        "owner": owner,
        "package": str(pkg_doc.get("package") or f"{owner}.AutonomyAd"),
        "ads": {k: ads_by_id[k] for k in sorted(ads_by_id)},
        "situations": {k: sits_by_id[k] for k in sorted(sits_by_id)},
        "domains": {k: domains[k] for k in sorted(domains)},
        "sourceMap": {k: source_map[k] for k in sorted(source_map)},
    }
    plan["fingerprint"] = sha256_json(plan)
    return plan


def compile_autonomy_ad_workspace(owner_repositories: Mapping[str, Path]) -> dict[str, dict[str, Any]]:
    plans: dict[str, dict[str, Any]] = {}
    for owner, repo in sorted(owner_repositories.items()):
        desc = package_descriptor(owner)
        if desc.autonomy_ad_source_root_relative is None:
            continue
        pkg_dir = Path(repo).expanduser().resolve() / desc.autonomy_ad_source_root_relative
        if not (pkg_dir / "package.json").is_file():
            continue
        plan_a = compile_autonomy_ad_package(pkg_dir, expected_owner=owner)
        plan_b = compile_autonomy_ad_package(pkg_dir, expected_owner=owner)
        if plan_a["fingerprint"] != plan_b["fingerprint"]:
            raise CompileError(f"Non-deterministic AutonomyAd compilation detected for {owner}")
        plans[owner] = plan_a
    return plans


def render_autonomy_ad_lua_artifacts(
    plan: Mapping[str, Any],
) -> list[tuple[str, str, str, tuple[str, ...]]]:
    owner = normalize_owner(plan["owner"])
    desc = package_descriptor(owner)
    prefix = desc.autonomy_ad_prefix or f"{owner}/AutonomyAd"
    ads = plan["ads"]
    situations = plan["situations"]
    domains = plan["domains"]

    artifacts: list[tuple[str, str, str, tuple[str, ...]]] = []
    domain_mods: list[tuple[str, str]] = []

    for domain, dom_entry in sorted(domains.items()):
        dom_mod = f"{prefix}/Ads/{domain}"
        payload = {
            "ads": {aid: ads[aid] for aid in dom_entry["ads"]},
            "situations": {sid: situations[sid] for sid in dom_entry["situations"]},
        }
        lines = [
            AUTONOMY_AD_GENERATED_MARKER,
            f"-- Owner: {owner}  Domain: {domain}",
            "",
            "local DomainData = " + _lua_value(payload, indent=0),
            "",
            "return DomainData",
            "",
        ]
        src_files = tuple(
            sorted(
                {
                    str(plan["sourceMap"][eid]["sourceFile"])
                    for eid in (*dom_entry["ads"], *dom_entry["situations"])
                    if eid in plan["sourceMap"]
                }
            )
        )
        artifacts.append((dom_mod, "\n".join(lines), f"lua:AutonomyAdDomain:{domain}", src_files))
        domain_mods.append((domain, dom_mod))

    reg_mod = f"{prefix}/Registry"
    ns_parts = prefix.split("/")
    root_ns = ns_parts[0]
    sub_ns = ns_parts[1] if len(ns_parts) > 1 else "AutonomyAd"
    reg_lines = [
        AUTONOMY_AD_GENERATED_MARKER,
        f"-- Owner: {owner}  Package: {plan['package']}",
        "",
        f"{root_ns} = {root_ns} or {{}}",
        f"{root_ns}.{sub_ns} = {root_ns}.{sub_ns} or {{}}",
        "",
        "local Registry = {",
        f"    schema = {_lua_value(AUTONOMY_AD_PLAN_SCHEMA)},",
        f"    version = 1,",
        f"    owner = {_lua_value(owner)},",
        f"    package = {_lua_value(plan['package'])},",
        f"    fingerprint = {_lua_value(plan['fingerprint'])},",
        "    ads = {},",
        "    situations = {},",
        "}",
        "",
    ]
    for _dom, dom_mod in domain_mods:
        reg_lines.extend([
            f'local dom = require "{dom_mod}"',
            "for adID, spec in pairs(dom.ads or {}) do Registry.ads[adID] = spec end",
            "for sitID, spec in pairs(dom.situations or {}) do Registry.situations[sitID] = spec end",
        ])
    reg_lines.extend([
        "",
        "function Registry.GetAd(adID)",
        "    return Registry.ads[tostring(adID or '')]",
        "end",
        "",
        "function Registry.GetSituation(sitID)",
        "    return Registry.situations[tostring(sitID or '')]",
        "end",
        "",
        f"{root_ns}.{sub_ns}.Registry = Registry",
        "return Registry",
        "",
    ])
    artifacts.append((reg_mod, "\n".join(reg_lines), "lua:AutonomyAdRegistry", ("package.json",)))
    return artifacts
