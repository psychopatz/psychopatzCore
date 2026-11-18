"""S11A7: Compile-time dependency index, required-fact projection, and incremental cache.

Derives deterministic stable IDs, family -> required facts, fact -> consuming
families, and action/effect/modifier -> invalidated facts from a Portable
Dialogue Plan without creating shadow gameplay state.
"""

from __future__ import annotations

import hashlib
import json
from collections.abc import Iterable, Mapping
from typing import Any

DEPENDENCY_INDEX_SCHEMA = "psychopatz.convo-engine.dependency-index.v1"


def _extract_predicate_paths(node: Any, out: set[str]) -> None:
    if not isinstance(node, Mapping):
        return
    if "all" in node and isinstance(node["all"], list):
        for child in node["all"]:
            _extract_predicate_paths(child, out)
        return
    if "any" in node and isinstance(node["any"], list):
        for child in node["any"]:
            _extract_predicate_paths(child, out)
        return
    if "not" in node:
        _extract_predicate_paths(node["not"], out)
        return
    path = node.get("path") or node.get("field")
    if isinstance(path, str) and path.strip():
        out.add(path.strip())


def extract_family_required_facts(dlg: Mapping[str, Any]) -> list[str]:
    """Return sorted unique fact paths required to evaluate one dialogue family."""
    facts: set[str] = set()
    _extract_predicate_paths(dlg.get("when"), facts)
    for rule in dlg.get("statePolicy") or []:
        if isinstance(rule, Mapping):
            _extract_predicate_paths(rule.get("when"), facts)
    for q in dlg.get("queries") or []:
        if isinstance(q, Mapping) and isinstance(q.get("path"), str) and q["path"].strip():
            facts.add(q["path"].strip())
    aff = dlg.get("affordance")
    if isinstance(aff, Mapping):
        _extract_predicate_paths(aff.get("when"), facts)
    reply = dlg.get("reply")
    if isinstance(reply, Mapping):
        for branch in reply.values():
            if isinstance(branch, Mapping):
                _extract_predicate_paths(branch.get("when"), facts)
    return sorted(facts)


def extract_family_invalidations(dlg: Mapping[str, Any]) -> list[str]:
    """Return sorted fact/domain keys potentially invalidated by executing this family."""
    inv: set[str] = set()
    for pc in dlg.get("postconditions") or []:
        if isinstance(pc, str) and pc.strip():
            inv.add(pc.strip())
    for mod in dlg.get("modifiers") or []:
        if isinstance(mod, Mapping) and mod.get("domain") and mod.get("field"):
            inv.add(f"{mod['domain']}.{mod['field']}")
    for eff in dlg.get("effects") or []:
        if isinstance(eff, Mapping) and eff.get("type"):
            inv.add(f"effect:{eff['type']}")
    reply = dlg.get("reply")
    if isinstance(reply, Mapping):
        for branch in reply.values():
            if isinstance(branch, Mapping):
                for pc in branch.get("postconditions") or []:
                    if isinstance(pc, str) and pc.strip():
                        inv.add(pc.strip())
                for mod in branch.get("modifiers") or []:
                    if isinstance(mod, Mapping) and mod.get("domain") and mod.get("field"):
                        inv.add(f"{mod['domain']}.{mod['field']}")
    return sorted(inv)


def build_dependency_index(plan: Mapping[str, Any]) -> dict[str, Any]:
    """Build deterministic S11A7 dependency & stable-ID index from a Portable Plan."""
    dialogues: Mapping[str, Mapping[str, Any]] = plan.get("dialogues") or {}
    sorted_ids = sorted(dialogues)
    stable_ids: dict[str, int] = {}
    id_to_family: dict[str, str] = {}
    family_required_facts: dict[str, list[str]] = {}
    fact_to_families: dict[str, list[str]] = {}
    family_invalidates: dict[str, list[str]] = {}
    modifier_affected_facts: dict[str, str] = {}

    for idx, fid in enumerate(sorted_ids, start=1):
        dlg = dialogues[fid]
        stable_ids[fid] = idx
        id_to_family[str(idx)] = fid
        req = extract_family_required_facts(dlg)
        family_required_facts[fid] = req
        for fact in req:
            fact_to_families.setdefault(fact, []).append(fid)
        inv = extract_family_invalidations(dlg)
        if inv:
            family_invalidates[fid] = inv
        for mod in dlg.get("modifiers") or []:
            if isinstance(mod, Mapping) and mod.get("id") and mod.get("domain") and mod.get("field"):
                modifier_affected_facts[str(mod["id"])] = f"{mod['domain']}.{mod['field']}"

    return {
        "schema": DEPENDENCY_INDEX_SCHEMA,
        "stableIds": stable_ids,
        "idToFamily": id_to_family,
        "familyRequiredFacts": family_required_facts,
        "factToFamilies": {k: sorted(v) for k, v in sorted(fact_to_families.items())},
        "familyInvalidates": family_invalidates,
        "modifierAffectedFacts": dict(sorted(modifier_affected_facts.items())),
    }


def project_required_facts(
    family_id: str,
    index: Mapping[str, Any],
    context: Mapping[str, Any],
) -> dict[str, Any]:
    """Project only the required fact paths for ``family_id`` from ``context``."""
    req = (index.get("familyRequiredFacts") or {}).get(family_id) or []
    projected: dict[str, Any] = {}
    for path in req:
        cur: Any = context
        ok = True
        parts = path.split(".")
        for seg in parts:
            if isinstance(cur, Mapping) and seg in cur:
                cur = cur[seg]
            else:
                ok = False
                break
        if not ok:
            continue
        dst = projected
        for seg in parts[:-1]:
            dst = dst.setdefault(seg, {})
        dst[parts[-1]] = cur
    return projected


def families_invalidated_by(
    changed_facts: Iterable[str],
    index: Mapping[str, Any],
) -> list[str]:
    """Return sorted family IDs whose required facts intersect ``changed_facts``."""
    fact_map = index.get("factToFamilies") or {}
    affected: set[str] = set()
    for fact in changed_facts:
        for fid in fact_map.get(fact) or ():
            affected.add(fid)
    return sorted(affected)


class IncrementalAnalysisCache:
    """Fingerprint-keyed incremental cache for per-family compiler analysis."""

    def __init__(self) -> None:
        self._fingerprints: dict[str, str] = {}
        self._results: dict[str, Any] = {}
        self.hits = 0
        self.misses = 0

    @staticmethod
    def family_fingerprint(dlg: Mapping[str, Any]) -> str:
        raw = json.dumps(dlg, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
        return hashlib.sha256(raw.encode("utf-8")).hexdigest()[:16]

    def get_or_compute(self, family_id: str, dlg: Mapping[str, Any], compute_fn: Any) -> Any:
        fp = self.family_fingerprint(dlg)
        if self._fingerprints.get(family_id) == fp and family_id in self._results:
            self.hits += 1
            return self._results[family_id]
        self.misses += 1
        val = compute_fn(family_id, dlg)
        self._fingerprints[family_id] = fp
        self._results[family_id] = val
        return val


__all__ = [
    "DEPENDENCY_INDEX_SCHEMA",
    "IncrementalAnalysisCache",
    "build_dependency_index",
    "extract_family_invalidations",
    "extract_family_required_facts",
    "families_invalidated_by",
    "project_required_facts",
]
