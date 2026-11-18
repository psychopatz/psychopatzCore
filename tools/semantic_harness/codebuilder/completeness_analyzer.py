"""S11A4: Canonical Dialogue Completeness Analyzer.

Analyzes the frozen S11A1-A3 Portable Dialogue Plan (and optional
ActionContract / DomainSchemaRegistry / fixture coverage inputs) and emits
machine-readable diagnostics for CodeBuilder, CLI, and Semantic Lab.
"""

from __future__ import annotations

import ast
import json
from collections.abc import Iterable, Mapping, Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from .portable_runtime import PORTABLE_PLAN_SCHEMA
from .semantic_contract import FORBIDDEN_POSITIONAL_ROLES, ROLE_CARDINALITIES

COMPLETENESS_REPORT_SCHEMA = "psychopatz.convo-engine.completeness-report.v1"
CONSTRAINED_MANIFEST_SCHEMA = "psychopatz.convo-engine.constrained-family-manifest.v1"
CONSTRAINED_MANIFEST_PATH = Path(__file__).resolve().with_name("constrained_family_manifest.json")
AUDIT_INVENTORY_SCHEMA = "psychopatz.convo-engine.branching-audit-inventory.v1"
CORE_ROOT = Path(__file__).resolve().parents[3]
AUDIT_INVENTORY_PATH = (
    CORE_ROOT / "Docs" / "semantic_dialogue_language_standard" / "S11_BRANCHING_AUDIT_INVENTORY.json"
)
ACCEPTANCE_OWNER_KINDS = frozenset({"declarative_fixture", "python_test", "lua_test"})
MANIFEST_CLASSIFICATIONS = frozenset({
    "CANONICAL_STATEFUL",
    "EXPLICIT_PRESENTATION_ONLY",
    "REFERENCE_GOOD_REGRESSION",
    "RETIRED",
})
DEFAULT_REQUIRED_STATEFUL_POLICY = ("statePolicy", "inputPolicy", "repeatPolicy", "closure")
BOUNDED_REPEAT_POLICIES = frozenset({"once", "cooldown", "max_uses", "state_retired"})
MULTI_CARDINALITIES = frozenset({"ONE_OR_MORE", "ZERO_OR_MORE", "BOUNDED_MANY"})


@dataclass(frozen=True)
class CompletenessDiagnostic:
    code: str
    severity: str  # "error" | "warning" | "info"
    family_id: str
    path: str
    message: str
    repair_hint: str
    source_path: str | None = None
    node_id: str | None = None
    edge_id: str | None = None
    witness_path: tuple[str, ...] = ()
    cycle_path: tuple[str, ...] = ()
    scc_members: tuple[str, ...] = ()
    closure_class: str | None = None
    missing_ownership: str | None = None
    suggested_closure_classes: tuple[str, ...] = ()

    def to_dict(self) -> dict[str, Any]:
        return {
            "code": self.code,
            "severity": self.severity,
            "familyId": self.family_id,
            "path": self.path,
            "message": self.message,
            "repairHint": self.repair_hint,
            "sourcePath": self.source_path,
            "nodeId": self.node_id,
            "edgeId": self.edge_id,
            "witnessPath": list(self.witness_path),
            "cyclePath": list(self.cycle_path),
            "sccMembers": list(self.scc_members),
            "closureClass": self.closure_class,
            "missingOwnership": self.missing_ownership,
            "suggestedClosureClasses": list(self.suggested_closure_classes),
        }


def _tarjan_sccs(nodes: Iterable[str], edges: Mapping[str, list[str]]) -> list[list[str]]:
    index = 0
    indices: dict[str, int] = {}
    lowlink: dict[str, int] = {}
    stack: list[str] = []
    on_stack: set[str] = set()
    sccs: list[list[str]] = []

    def strongconnect(v: str) -> None:
        nonlocal index
        indices[v] = index
        lowlink[v] = index
        index += 1
        stack.append(v)
        on_stack.add(v)

        for w in edges.get(v, ()):
            if w not in indices:
                strongconnect(w)
                lowlink[v] = min(lowlink[v], lowlink[w])
            elif w in on_stack:
                lowlink[v] = min(lowlink[v], indices[w])

        if lowlink[v] == indices[v]:
            scc: list[str] = []
            while True:
                w = stack.pop()
                on_stack.remove(w)
                scc.append(w)
                if w == v:
                    break
            sccs.append(scc)

    for node in sorted(nodes):
        if node not in indices:
            strongconnect(node)
    return sccs


def _collect_edges(dialogue_id: str, dlg: Mapping[str, Any]) -> tuple[list[str], list[tuple[str, str]]]:
    targets: list[str] = []
    refs: list[tuple[str, str]] = []

    def _inspect_after(after: Any, path: str) -> None:
        if not isinstance(after, Mapping):
            return
        if isinstance(after.get("goto"), str):
            targets.append(after["goto"])
            refs.append((f"{path}.goto", after["goto"]))
        rec = after.get("recommend")
        if isinstance(rec, list):
            for idx, item in enumerate(rec):
                if isinstance(item, str):
                    targets.append(item)
                    refs.append((f"{path}.recommend[{idx}]", item))

    _inspect_after(dlg.get("after"), f"{dialogue_id}.after")
    reply = dlg.get("reply")
    if isinstance(reply, Mapping):
        for outcome_name, branch in reply.items():
            if isinstance(branch, Mapping):
                _inspect_after(branch.get("after"), f"{dialogue_id}.reply.{outcome_name}.after")
    return targets, refs


def load_constrained_family_manifest(path: Path | None = None) -> dict[str, Any]:
    target = path or CONSTRAINED_MANIFEST_PATH
    data = json.loads(target.read_text(encoding="utf-8"))
    if not isinstance(data, Mapping) or data.get("schema") != CONSTRAINED_MANIFEST_SCHEMA:
        raise ValueError(f"Invalid constrained-family manifest schema in {target}")
    return dict(data)


def load_branching_audit_inventory(path: Path | None = None) -> dict[str, Any]:
    target = path or AUDIT_INVENTORY_PATH
    data = json.loads(target.read_text(encoding="utf-8"))
    if not isinstance(data, Mapping) or data.get("schema") != AUDIT_INVENTORY_SCHEMA:
        raise ValueError(f"Invalid branching-audit inventory schema in {target}")
    return dict(data)


def _default_workspace_roots() -> dict[str, Path]:
    workshop_root = CORE_ROOT.parent
    return {
        "PsychopatzCore": CORE_ROOT,
        "ProjectHoomans": workshop_root / "ProjectHoomans",
        "DynamicTrading": workshop_root / "DynamicTrading",
    }


def _resolve_acceptance_source(source: str, roots: Mapping[str, Path]) -> Path | None:
    parts = Path(source).parts
    if parts and parts[0] in roots:
        return roots[parts[0]].joinpath(*parts[1:])
    candidate = CORE_ROOT / source
    if candidate.is_file():
        return candidate
    return None


def _parse_docstring_audit_claims(docstring: str | None) -> set[str]:
    if not docstring:
        return set()
    claims: set[str] = set()
    for line in docstring.splitlines():
        stripped = line.strip()
        if stripped.startswith("auditClaims:"):
            raw_val = stripped[len("auditClaims:"):].strip()
            if raw_val.startswith("["):
                parsed = json.loads(raw_val)
                if isinstance(parsed, list):
                    claims.update(str(item).strip() for item in parsed if str(item).strip())
            else:
                claims.update(part.strip() for part in raw_val.split(",") if part.strip())
    return claims


def _extract_test_claims(
    owner_kind: str, source_path: Path, test_ids: list[str]
) -> tuple[dict[str, set[str]], list[str]]:
    """Return {test_id: explicit_audit_claims} and list of missing test_ids."""
    raw = source_path.read_text(encoding="utf-8")
    found: dict[str, set[str]] = {}
    if owner_kind == "declarative_fixture":
        data = json.loads(raw)
        cases = {
            str(case.get("id")): case
            for case in (data.get("cases") or [])
            if isinstance(case, Mapping) and case.get("id")
        }
        missing: list[str] = []
        for tid in test_ids:
            case = cases.get(tid)
            if case is None:
                missing.append(tid)
            else:
                raw_claims = case.get("auditClaims")
                if isinstance(raw_claims, list):
                    found[tid] = {str(c).strip() for c in raw_claims if str(c).strip()}
                else:
                    found[tid] = set()
        return found, missing
    if owner_kind == "python_test":
        tree = ast.parse(raw)
        methods: dict[str, set[str]] = {}
        for node in ast.walk(tree):
            if isinstance(node, ast.FunctionDef) and node.name.startswith("test_"):
                methods[node.name] = _parse_docstring_audit_claims(ast.get_docstring(node))
        missing = [tid for tid in test_ids if tid not in methods]
        for tid in test_ids:
            if tid in methods:
                found[tid] = methods[tid]
        return found, missing
    if owner_kind == "lua_test":
        marker_claims: dict[str, set[str]] = {}
        for line in raw.splitlines():
            stripped = line.strip()
            if stripped.startswith("-- @auditClaims "):
                rest = stripped[len("-- @auditClaims "):].strip()
                if ":" in rest:
                    target_id, raw_val = rest.split(":", 1)
                    target_id = target_id.strip()
                    raw_val = raw_val.strip()
                    claims_set = marker_claims.setdefault(target_id, set())
                    if raw_val.startswith("["):
                        parsed = json.loads(raw_val)
                        if isinstance(parsed, list):
                            claims_set.update(str(item).strip() for item in parsed if str(item).strip())
                    else:
                        claims_set.update(part.strip() for part in raw_val.split(",") if part.strip())
        missing = [tid for tid in test_ids if tid not in raw]
        for tid in test_ids:
            if tid in raw:
                found[tid] = set(marker_claims.get(tid, set()))
        return found, missing
    return {}, list(test_ids)


def _validate_acceptance_ownership(
    *,
    aid: str,
    fid: str | None,
    idx: int,
    entry: Mapping[str, Any],
    audit_entry: Mapping[str, Any] | None,
    roots: Mapping[str, Path],
    diagnostics: list[CompletenessDiagnostic],
) -> None:
    acceptance = entry.get("acceptance")
    if not isinstance(acceptance, Mapping):
        diagnostics.append(
            CompletenessDiagnostic(
                code="invalid_acceptance_owner",
                severity="error",
                family_id=str(fid or aid),
                path=f"manifest.entries[{idx}].acceptance",
                message=f"Manifest entry {aid!r} requires structured acceptance metadata",
                repair_hint="Declare acceptance.{ownerKind, source, testIds, requiredClaims}.",
            )
        )
        return
    owner_kind = str(acceptance.get("ownerKind") or "").strip()
    if owner_kind not in ACCEPTANCE_OWNER_KINDS:
        diagnostics.append(
            CompletenessDiagnostic(
                code="invalid_acceptance_owner",
                severity="error",
                family_id=str(fid or aid),
                path=f"manifest.entries[{idx}].acceptance.ownerKind",
                message=f"Unsupported acceptance ownerKind {owner_kind!r} for {aid!r}",
                repair_hint=f"Use one of {sorted(ACCEPTANCE_OWNER_KINDS)}.",
            )
        )
        return
    source = str(acceptance.get("source") or "").strip()
    source_path = _resolve_acceptance_source(source, roots) if source else None
    if source_path is None or not source_path.is_file():
        diagnostics.append(
            CompletenessDiagnostic(
                code="missing_acceptance_source",
                severity="error",
                family_id=str(fid or aid),
                path=f"manifest.entries[{idx}].acceptance.source",
                message=f"Acceptance source {source!r} for {aid!r} does not exist",
                repair_hint="Point acceptance.source at an existing fixture or test file.",
            )
        )
        return
    raw_ids = acceptance.get("testIds")
    test_ids = [str(t).strip() for t in raw_ids if str(t).strip()] if isinstance(raw_ids, list) else []
    if not test_ids:
        diagnostics.append(
            CompletenessDiagnostic(
                code="missing_acceptance_test_id",
                severity="error",
                family_id=str(fid or aid),
                path=f"manifest.entries[{idx}].acceptance.testIds",
                message=f"Acceptance entry {aid!r} must declare at least one testIds entry",
                repair_hint="Bind specific fixture case IDs or test function names.",
            )
        )
        return
    found_claims, missing_ids = _extract_test_claims(owner_kind, source_path, test_ids)
    for missing_id in missing_ids:
        diagnostics.append(
            CompletenessDiagnostic(
                code="missing_acceptance_test_id",
                severity="error",
                family_id=str(fid or aid),
                path=f"manifest.entries[{idx}].acceptance.testIds",
                message=f"Acceptance testId {missing_id!r} not found in {source!r} for {aid!r}",
                repair_hint="Update acceptance.testIds to reference real existing test/case IDs.",
            )
        )
    declared_claims = {
        str(c).strip()
        for c in (acceptance.get("requiredClaims") or [])
        if str(c).strip()
    }
    if audit_entry is not None:
        needed_claims = {
            str(c).strip()
            for c in (audit_entry.get("requiredClaims") or [])
            if str(c).strip()
        }
        missing_claims = sorted(needed_claims - declared_claims)
        if missing_claims:
            diagnostics.append(
                CompletenessDiagnostic(
                    code="missing_required_acceptance_claims",
                    severity="error",
                    family_id=str(fid or aid),
                    path=f"manifest.entries[{idx}].acceptance.requiredClaims",
                    message=f"Acceptance for {aid!r} omits required audit claims: {missing_claims}",
                    repair_hint="Cover all requiredClaims declared in S11_BRANCHING_AUDIT_INVENTORY.json.",
                )
            )
        if not missing_ids:
            owned_claims: set[str] = set()
            for tid in test_ids:
                owned_claims.update(found_claims.get(tid, set()))
            if not owned_claims:
                diagnostics.append(
                    CompletenessDiagnostic(
                        code="missing_owner_audit_claims",
                        severity="error",
                        family_id=str(fid or aid),
                        path=f"manifest.entries[{idx}].acceptance",
                        message=f"Exact test owner(s) {test_ids} in {source!r} declare no explicit auditClaims for {aid!r}",
                        repair_hint="Declare explicit auditClaims on the exact fixture case, Python test docstring, or Lua @auditClaims marker.",
                    )
                )
            else:
                uncovered = sorted(needed_claims - owned_claims)
                if uncovered:
                    diagnostics.append(
                        CompletenessDiagnostic(
                            code="acceptance_claim_mismatch",
                            severity="error",
                            family_id=str(fid or aid),
                            path=f"manifest.entries[{idx}].acceptance",
                            message=f"Exact test owner(s) {test_ids} in {source!r} do not own required claims {uncovered} (owned={sorted(owned_claims)}) for {aid!r}",
                            repair_hint="Declare the required auditClaims on the exact test/case that verifies them.",
                        )
                    )


def _validate_constrained_manifest(
    dialogues: Mapping[str, Mapping[str, Any]],
    manifest: Mapping[str, Any],
    *,
    strict_manifest: bool,
    diagnostics: list[CompletenessDiagnostic],
    audit_inventory: Mapping[str, Any] | None = None,
    workspace_roots: Mapping[str, Path] | None = None,
) -> None:
    roots = workspace_roots if workspace_roots is not None else _default_workspace_roots()
    inventory = audit_inventory
    if inventory is None and strict_manifest:
        inventory = load_branching_audit_inventory()
    audit_by_id: dict[str, Mapping[str, Any]] = {}
    if inventory is not None:
        for idx, item in enumerate(inventory.get("entries") or []):
            if not isinstance(item, Mapping):
                continue
            item_id = str(item.get("auditId") or "").strip()
            if not item_id:
                continue
            if item_id in audit_by_id:
                diagnostics.append(
                    CompletenessDiagnostic(
                        code="duplicate_audit_inventory_id",
                        severity="error",
                        family_id=item_id,
                        path=f"auditInventory.entries[{idx}].auditId",
                        message=f"Duplicate audit inventory ID {item_id!r}",
                        repair_hint="Ensure every audit row in S11_BRANCHING_AUDIT_INVENTORY.json has a unique auditId.",
                    )
                )
            else:
                audit_by_id[item_id] = item
    entries = manifest.get("entries")
    if not isinstance(entries, list) or not entries:
        diagnostics.append(
            CompletenessDiagnostic(
                code="invalid_manifest",
                severity="error",
                family_id="<manifest>",
                path="manifest.entries",
                message="Constrained-family manifest must declare a non-empty entries list",
                repair_hint="Populate constrained_family_manifest.json from S11_BRANCHING_DIALOGUE_AUDIT.md.",
            )
        )
        return
    seen_audit_ids: set[str] = set()
    for idx, entry in enumerate(entries):
        if not isinstance(entry, Mapping):
            continue
        aid = str(entry.get("auditId") or f"entry[{idx}]")
        if aid in seen_audit_ids:
            diagnostics.append(
                CompletenessDiagnostic(
                    code="duplicate_manifest_audit_id",
                    severity="error",
                    family_id=aid,
                    path=f"manifest.entries[{idx}].auditId",
                    message=f"Duplicate manifest auditId {aid!r}",
                    repair_hint="Ensure each branching-audit row appears once.",
                )
            )
            continue
        seen_audit_ids.add(aid)
        classification = entry.get("classification")
        if classification not in MANIFEST_CLASSIFICATIONS:
            diagnostics.append(
                CompletenessDiagnostic(
                    code="invalid_manifest_classification",
                    severity="error",
                    family_id=aid,
                    path=f"manifest.entries[{idx}].classification",
                    message=f"Unsupported classification {classification!r}",
                    repair_hint=f"Use one of {sorted(MANIFEST_CLASSIFICATIONS)}.",
                )
            )
            continue
        owner = str(entry.get("acceptanceOwner") or "").strip()
        reason = str(entry.get("reason") or "").strip()
        fid = entry.get("canonicalFamilyId")
        if classification in ("EXPLICIT_PRESENTATION_ONLY", "REFERENCE_GOOD_REGRESSION"):
            if not owner and not isinstance(entry.get("acceptance"), Mapping):
                diagnostics.append(
                    CompletenessDiagnostic(
                        code="missing_acceptance_owner",
                        severity="error",
                        family_id=str(fid or aid),
                        path=f"manifest.entries[{idx}].acceptanceOwner",
                        message=f"{classification} entry {aid!r} requires acceptanceOwner",
                        repair_hint="Bind an explicit regression test or fixture path.",
                    )
                )
            if classification == "EXPLICIT_PRESENTATION_ONLY" and not reason:
                diagnostics.append(
                    CompletenessDiagnostic(
                        code="missing_presentation_only_reason",
                        severity="error",
                        family_id=str(fid or aid),
                        path=f"manifest.entries[{idx}].reason",
                        message=f"EXPLICIT_PRESENTATION_ONLY entry {aid!r} requires an explicit reason",
                        repair_hint="Document why typed parity is intentionally omitted.",
                    )
                )
            if strict_manifest or isinstance(entry.get("acceptance"), Mapping):
                _validate_acceptance_ownership(
                    aid=aid,
                    fid=fid,
                    idx=idx,
                    entry=entry,
                    audit_entry=audit_by_id.get(aid),
                    roots=roots,
                    diagnostics=diagnostics,
                )
        elif classification == "RETIRED":
            if isinstance(fid, str) and fid in dialogues:
                diagnostics.append(
                    CompletenessDiagnostic(
                        code="retired_family_still_present",
                        severity="error",
                        family_id=fid,
                        path=f"manifest.entries[{idx}]",
                        message=f"Retired family {fid!r} is still present in Portable Plan",
                        repair_hint="Delete superseded canonical/runtime artifacts and reconcile.",
                    )
                )
        elif classification == "CANONICAL_STATEFUL":
            phase = str(entry.get("migrationPhase") or "accepted")
            if not strict_manifest and phase != "accepted":
                continue
            if not isinstance(fid, str) or not fid or fid not in dialogues:
                diagnostics.append(
                    CompletenessDiagnostic(
                        code="missing_canonical_stateful_family",
                        severity="error",
                        family_id=str(fid or aid),
                        path=f"manifest.entries[{idx}].canonicalFamilyId",
                        message=f"Required CANONICAL_STATEFUL family {fid!r} ({aid}) is absent from Portable Plan",
                        repair_hint="Author the family in canonical CodeBuilder source and regenerate.",
                    )
                )
                continue
            dlg = dialogues[fid]
            required = entry.get("requiredPolicy") or DEFAULT_REQUIRED_STATEFUL_POLICY
            missing_fields = [f for f in required if not dlg.get(f)]
            if missing_fields:
                diagnostics.append(
                    CompletenessDiagnostic(
                        code="missing_required_state_policy",
                        severity="error",
                        family_id=fid,
                        path=fid,
                        message=f"Required CANONICAL_STATEFUL family {fid!r} lacks canonical policy fields: {missing_fields}",
                        repair_hint="Add the required S11 policy fields in canonical CodeBuilder source.",
                    )
                )
            if strict_manifest or isinstance(entry.get("acceptance"), Mapping):
                _validate_acceptance_ownership(
                    aid=aid,
                    fid=fid,
                    idx=idx,
                    entry=entry,
                    audit_entry=audit_by_id.get(aid),
                    roots=roots,
                    diagnostics=diagnostics,
                )

    if inventory is not None:
        for missing_aid in sorted(set(audit_by_id) - seen_audit_ids):
            diagnostics.append(
                CompletenessDiagnostic(
                    code="missing_audit_row_in_manifest",
                    severity="error",
                    family_id=missing_aid,
                    path="manifest.entries",
                    message=f"Branching audit row {missing_aid!r} is missing from constrained_family_manifest.json",
                    repair_hint="Classify every row from S11_BRANCHING_AUDIT_INVENTORY.json in constrained_family_manifest.json.",
                )
            )
        for extra_aid in sorted(seen_audit_ids - set(audit_by_id)):
            diagnostics.append(
                CompletenessDiagnostic(
                    code="extra_manifest_row_without_audit",
                    severity="error",
                    family_id=extra_aid,
                    path="manifest.entries",
                    message=f"Manifest row {extra_aid!r} does not exist in S11_BRANCHING_AUDIT_INVENTORY.json",
                    repair_hint="Remove stale manifest rows or add the maintained row to S11_BRANCHING_AUDIT_INVENTORY.json.",
                )
            )


_DIAGNOSTIC_OWNERSHIP_MAP: dict[str, tuple[str, tuple[str, ...]]] = {
    "dead_end": ("continuation_target", ("resolved_episode", "open_domain_obligation")),
    "unreachable_branch": ("state_policy_order", ()),
    "pending_without_exit": ("pending_exit", ("bounded_pending", "resolved_episode")),
    "unbounded_loop": ("repeat_policy", ("resolved_episode",)),
    "missing_repeat_policy": ("repeat_policy", ("resolved_episode",)),
    "unhandled_state_outcome": ("reply_outcome", ("resolved_episode",)),
    "unhandled_action_outcome": ("reply_outcome", ("resolved_episode", "open_domain_obligation")),
    "stale_poststate_risk": ("postconditions_or_state_policy", ("resolved_episode", "open_domain_obligation")),
    "dangling_memory": ("memory_episode", ("resolved_episode",)),
    "lost_commitment": ("domain_obligation", ("open_domain_obligation",)),
    "role_unbound": ("role_binding", ()),
    "role_cardinality_mismatch": ("role_cardinality", ()),
    "unbounded_group_reaction": ("participant_set_bound", ()),
    "ambiguous_group_effect": ("effect_scope", ()),
    "uncovered_fixture": ("fixture_coverage", ()),
}


def _check_roles_and_participant_set(
    fid: str,
    rec: Mapping[str, Any],
    diagnostics: list[CompletenessDiagnostic],
) -> None:
    """Validate semantic roles and participantSet cardinality bounds on any family."""
    roles = rec.get("roles") or {}
    pset = rec.get("participantSet")
    multi_roles: set[str] = set()
    for rname, rspec in roles.items():
        if rname in FORBIDDEN_POSITIONAL_ROLES:
            diagnostics.append(
                CompletenessDiagnostic(
                    code="role_unbound",
                    severity="error",
                    family_id=fid,
                    path=f"{fid}.roles.{rname}",
                    message=f"Forbidden positional role {rname!r}",
                    repair_hint="Use semantic roles (speaker, addressee, actor, target, mediator, etc.).",
                )
            )
        card = (rspec or {}).get("cardinality", "ONE")
        if card not in ROLE_CARDINALITIES:
            diagnostics.append(
                CompletenessDiagnostic(
                    code="role_cardinality_mismatch",
                    severity="error",
                    family_id=fid,
                    path=f"{fid}.roles.{rname}.cardinality",
                    message=f"Unsupported role cardinality {card!r}",
                    repair_hint=f"Use one of {sorted(ROLE_CARDINALITIES)}.",
                )
            )
        if card in MULTI_CARDINALITIES:
            multi_roles.add(rname)
            if card in ("ONE_OR_MORE", "ZERO_OR_MORE") and not (
                isinstance(pset, Mapping) and pset.get("maxSize")
            ):
                diagnostics.append(
                    CompletenessDiagnostic(
                        code="unbounded_group_reaction",
                        severity="error",
                        family_id=fid,
                        path=f"{fid}.roles.{rname}",
                        message=f"Unbounded multi-entity role {rname!r} ({card}) lacks participantSet.maxSize",
                        repair_hint="Use BOUNDED_MANY with min/max or set participantSet.maxSize.",
                    )
                )
    for idx, eff in enumerate(rec.get("effects") or []):
        trole = (eff or {}).get("targetRole")
        if trole in multi_roles and not (eff.get("params") or {}).get("scope"):
            diagnostics.append(
                CompletenessDiagnostic(
                    code="ambiguous_group_effect",
                    severity="error",
                    family_id=fid,
                    path=f"{fid}.effects[{idx}]",
                    message=f"Effect targets multi-entity role {trole!r} without params.scope",
                    repair_hint="Set params.scope (e.g. 'all' or 'first') on group-targeted effects.",
                )
            )


def _common_non_dialogue_envelope(
    fid: str,
    rec: Mapping[str, Any],
    *,
    kind: str,
    family_diags: Sequence[CompletenessDiagnostic],
    covered_set: set[str] | None,
    manifest_families: set[str],
    source_path: str | None,
    reachable_branches: int,
    outgoing: Sequence[str],
    incoming: Sequence[str],
    nodes: list[dict[str, Any]],
    graph_edges: list[dict[str, Any]],
    closure_health: str,
    semantic_status: str,
    closure_class: str,
    kind_detail: dict[str, Any],
) -> dict[str, Any]:
    lineage = rec.get("lineage") if isinstance(rec.get("lineage"), Mapping) else {}
    error_count = sum(1 for d in family_diags if d.severity == "error")
    warning_count = sum(1 for d in family_diags if d.severity == "warning")
    info_count = sum(1 for d in family_diags if d.severity == "info")
    if error_count > 0:
        closure_health = "invalid"
        semantic_status = "RED"
    elif warning_count > 0:
        closure_health = "warning"
        semantic_status = "ORANGE"

    handled_branches = max(0, reachable_branches - error_count)
    if covered_set is not None:
        fixture_coverage = "covered" if fid in covered_set else "uncovered"
    elif fid in manifest_families:
        fixture_coverage = "manifest_owned"
    else:
        fixture_coverage = "unknown"

    return {
        "familyId": fid,
        "owner": str(rec.get("owner") or "PsychopatzCore"),
        "kind": kind,
        "namespace": str(rec.get("namespace") or (fid.rsplit(".", 1)[0] if "." in fid else "")),
        "localId": str(lineage.get("localId") or fid.rsplit(".", 1)[-1]),
        "sourceShard": lineage.get("sourcePath"),
        "sourcePath": source_path,
        "reachableBranches": reachable_branches,
        "handledBranches": handled_branches,
        "closureClass": closure_class,
        "closureHealth": closure_health,
        "semanticStatus": semantic_status,
        "errorCount": error_count,
        "warningCount": warning_count,
        "infoCount": info_count,
        "diagnosticCodes": sorted({d.code for d in family_diags}),
        "fixtureCoverage": fixture_coverage,
        "typedClickParity": "not_applicable",
        "repeatPolicy": str(rec.get("repeatPolicy") or ("cooldown" if rec.get("cooldownTurns") else "not_applicable")),
        "hasStatePolicy": bool(rec.get("when") or rec.get("entry")),
        "hasPostconditions": False,
        "hasClosure": True,
        "stateOutcomeMatrix": [],
        "actionOutcomeMatrix": [],
        "sccMembers": [fid],
        "dependencies": sorted(set(outgoing)),
        "dependents": sorted(set(incoming)),
        "affectedClosure": sorted(set(outgoing) | set(incoming) | {fid}),
        "kindDetail": kind_detail,
        "graph": {"nodes": nodes, "edges": graph_edges},
    }


def _analyze_behavior_family(
    fid: str,
    beh: Mapping[str, Any],
    *,
    all_ids: set[str],
    covered_set: set[str] | None,
    manifest_families: set[str],
    source_path: str | None,
) -> tuple[dict[str, Any], list[CompletenessDiagnostic], list[str]]:
    diags: list[CompletenessDiagnostic] = []
    stimuli = list(beh.get("stimuli") or ())
    outputs = beh.get("outputs") if isinstance(beh.get("outputs"), Mapping) else {}
    act = beh.get("act")
    cont = beh.get("continuation") if isinstance(beh.get("continuation"), Mapping) else {}
    refs = beh.get("references") if isinstance(beh.get("references"), Mapping) else {}
    outgoing: list[str] = []

    if not stimuli:
        diags.append(
            CompletenessDiagnostic(
                code="missing_behavior_stimuli",
                severity="error",
                family_id=fid,
                path=f"{fid}.stimuli",
                message="Behavior declares no trigger stimuli",
                repair_hint="Add at least one stimulus (e.g. HUMAN_UTTERANCE or NPC_SEMANTIC_ACT) to stimuli.",
            )
        )
    if not outputs and not act:
        diags.append(
            CompletenessDiagnostic(
                code="missing_behavior_outputs",
                severity="error",
                family_id=fid,
                path=f"{fid}.outputs",
                message="Behavior declares neither outputs nor semantic act",
                repair_hint="Add outputs (speech/emote/flavor) or an act identifier.",
            )
        )
    _check_roles_and_participant_set(fid, beh, diags)

    for ref_key, ref_val in refs.items():
        if isinstance(ref_val, str) and "." in ref_val and ref_val not in all_ids:
            diags.append(
                CompletenessDiagnostic(
                    code="unresolved_family_reference",
                    severity="error",
                    family_id=fid,
                    path=f"{fid}.references.{ref_key}",
                    message=f"Behavior reference {ref_val!r} does not exist in canonical catalog",
                    repair_hint=f"Fix or remove references.{ref_key}.",
                )
            )
        elif isinstance(ref_val, str) and ref_val in all_ids:
            outgoing.append(ref_val)

    cont_mode = str(cont.get("mode") or "terminate")
    if cont_mode == "emit" and not (cont.get("intent") or cont.get("speechAct")):
        diags.append(
            CompletenessDiagnostic(
                code="incomplete_behavior_continuation",
                severity="warning",
                family_id=fid,
                path=f"{fid}.continuation",
                message="Behavior emit continuation has no intent or speechAct",
                repair_hint="Set continuation.intent or continuation.speechAct.",
            )
        )

    if covered_set is not None and fid not in covered_set:
        diags.append(
            CompletenessDiagnostic(
                code="uncovered_fixture",
                severity="info",
                family_id=fid,
                path=fid,
                message=f"Behavior family {fid!r} has no recorded declarative fixture coverage",
                repair_hint="Add a provider-owned declarative fixture case exercising this behavior.",
            )
        )

    is_emit = cont_mode == "emit"
    nodes = [
        {
            "id": f"{fid}:trigger",
            "kind": "behavior_trigger",
            "label": f"stimuli: {', '.join(str(s) for s in stimuli) or '(none)'}",
            "status": "invalid" if not stimuli else "valid",
            "colorClass": "RED" if not stimuli else "GREEN",
            "path": f"{fid}.stimuli",
        },
        {
            "id": f"{fid}:outputs",
            "kind": "behavior_outputs",
            "label": f"act={act or '(none)'} outputs={sorted(outputs.keys())}",
            "status": "invalid" if (not outputs and not act) else "valid",
            "colorClass": "RED" if (not outputs and not act) else ("BLUE" if is_emit else "GREEN"),
            "path": f"{fid}.outputs",
        },
    ]
    graph_edges = [
        {
            "id": f"{fid}:trigger->outputs",
            "from": f"{fid}:trigger",
            "to": f"{fid}:outputs",
            "label": str(beh.get("mode") or "one_shot"),
            "status": "valid",
            "colorClass": "BLUE" if is_emit else "GREEN",
            "path": f"{fid}.outputs",
        }
    ]
    metrics = _common_non_dialogue_envelope(
        fid,
        beh,
        kind="behavior",
        family_diags=diags,
        covered_set=covered_set,
        manifest_families=manifest_families,
        source_path=source_path,
        reachable_branches=max(1, len(outputs) + len(beh.get("modifiers") or ())),
        outgoing=outgoing,
        incoming=(),
        nodes=nodes,
        graph_edges=graph_edges,
        closure_health="continuation" if is_emit else "resolved_terminal",
        semantic_status="BLUE" if is_emit else "GREEN",
        closure_class="behavior_emit" if is_emit else "behavior_terminal",
        kind_detail={
            "act": act,
            "mode": beh.get("mode"),
            "stimuli": stimuli,
            "outputChannels": sorted(outputs.keys()),
            "continuationMode": cont_mode,
        },
    )
    return metrics, diags, outgoing


def _analyze_beat_family(
    fid: str,
    beat: Mapping[str, Any],
    *,
    behaviors: Mapping[str, Mapping[str, Any]],
    dialogues: Mapping[str, Mapping[str, Any]],
    covered_set: set[str] | None,
    manifest_families: set[str],
    source_path: str | None,
) -> tuple[dict[str, Any], list[CompletenessDiagnostic], list[str]]:
    diags: list[CompletenessDiagnostic] = []
    candidates = list(beat.get("candidates") or ())
    entry = beat.get("entry")
    exit_cond = beat.get("exit")
    max_turns = beat.get("maxTurns")
    outgoing: list[str] = []

    if not entry:
        diags.append(
            CompletenessDiagnostic(
                code="missing_beat_entry",
                severity="error",
                family_id=fid,
                path=f"{fid}.entry",
                message="Beat declares no entry condition",
                repair_hint="Declare an entry predicate for beat activation.",
            )
        )
    if not exit_cond and not max_turns:
        diags.append(
            CompletenessDiagnostic(
                code="unbounded_beat_progression",
                severity="warning",
                family_id=fid,
                path=f"{fid}.exit",
                message="Beat has neither exit condition nor maxTurns bound",
                repair_hint="Add an exit predicate or maxTurns to guarantee bounded progression.",
            )
        )
    _check_roles_and_participant_set(fid, beat, diags)

    for idx, cand in enumerate(candidates):
        if not isinstance(cand, Mapping):
            continue
        target = cand.get("behavior") or cand.get("family")
        if isinstance(target, str):
            if target in behaviors or target in dialogues:
                outgoing.append(target)
            else:
                diags.append(
                    CompletenessDiagnostic(
                        code="unresolved_beat_candidate",
                        severity="error",
                        family_id=fid,
                        path=f"{fid}.candidates[{idx}].behavior",
                        message=f"Beat candidate {target!r} does not exist in canonical behaviors/dialogues",
                        repair_hint=f"Reference a valid behavior or dialogue ID in candidates[{idx}].",
                    )
                )

    if covered_set is not None and fid not in covered_set:
        diags.append(
            CompletenessDiagnostic(
                code="uncovered_fixture",
                severity="info",
                family_id=fid,
                path=fid,
                message=f"Beat family {fid!r} has no recorded declarative fixture coverage",
                repair_hint="Add a provider-owned declarative fixture case exercising this beat.",
            )
        )

    nodes = [
        {
            "id": f"{fid}:entry",
            "kind": "beat_entry",
            "label": f"entry ({'bounded' if (exit_cond or max_turns) else 'unbounded'})",
            "status": "invalid" if not entry else "valid",
            "colorClass": "RED" if not entry else "GREEN",
            "path": f"{fid}.entry",
        },
        {
            "id": f"{fid}:candidates",
            "kind": "beat_candidates",
            "label": f"candidates={len(candidates)} maxTurns={max_turns}",
            "status": "valid",
            "colorClass": "GREEN",
            "path": f"{fid}.candidates",
        },
    ]
    graph_edges = [
        {
            "id": f"{fid}:entry->candidates",
            "from": f"{fid}:entry",
            "to": f"{fid}:candidates",
            "label": "arbitrate",
            "status": "valid",
            "colorClass": "GREEN",
            "path": f"{fid}.candidates",
        }
    ]
    metrics = _common_non_dialogue_envelope(
        fid,
        beat,
        kind="beat",
        family_diags=diags,
        covered_set=covered_set,
        manifest_families=manifest_families,
        source_path=source_path,
        reachable_branches=max(1, len(candidates)),
        outgoing=outgoing,
        incoming=(),
        nodes=nodes,
        graph_edges=graph_edges,
        closure_health="resolved_terminal",
        semantic_status="GREEN",
        closure_class="bounded_beat" if (exit_cond or max_turns) else "unbounded_beat",
        kind_detail={
            "candidateCount": len(candidates),
            "candidates": [c.get("behavior") for c in candidates if isinstance(c, Mapping)],
            "maxTurns": max_turns,
            "cooldownTurns": beat.get("cooldownTurns"),
            "hasEntry": bool(entry),
            "hasMaintain": bool(beat.get("maintain")),
            "hasExit": bool(exit_cond),
        },
    )
    return metrics, diags, outgoing


def _analyze_realization_family(
    fid: str,
    real: Mapping[str, Any],
    *,
    all_ids: set[str],
    covered_set: set[str] | None,
    manifest_families: set[str],
    source_path: str | None,
) -> tuple[dict[str, Any], list[CompletenessDiagnostic], list[str]]:
    diags: list[CompletenessDiagnostic] = []
    translations = real.get("translations") if isinstance(real.get("translations"), Mapping) else {}
    forms = real.get("forms") if isinstance(real.get("forms"), Mapping) else {}
    refs = real.get("references") if isinstance(real.get("references"), Mapping) else {}
    outgoing: list[str] = []

    has_en = bool(translations.get("EN"))
    has_forms = bool(forms)
    if not has_en and not has_forms:
        diags.append(
            CompletenessDiagnostic(
                code="missing_en_realization",
                severity="error",
                family_id=fid,
                path=f"{fid}.translations.EN",
                message="Realization has no EN translation entries or forms",
                repair_hint="Provide at least one EN translation template or form.",
            )
        )
    if not (real.get("dialogueAct") or real.get("strategy") or real.get("concept")):
        diags.append(
            CompletenessDiagnostic(
                code="missing_realization_binding",
                severity="warning",
                family_id=fid,
                path=f"{fid}.dialogueAct",
                message="Realization has no dialogueAct, strategy, or concept binding",
                repair_hint="Declare dialogueAct, strategy, or concept.",
            )
        )

    for ref_key, ref_val in refs.items():
        if isinstance(ref_val, str) and "." in ref_val and ref_val not in all_ids:
            diags.append(
                CompletenessDiagnostic(
                    code="unresolved_realization_reference",
                    severity="error",
                    family_id=fid,
                    path=f"{fid}.references.{ref_key}",
                    message=f"Realization reference {ref_val!r} does not exist in canonical catalog",
                    repair_hint=f"Fix or remove references.{ref_key}.",
                )
            )
        elif isinstance(ref_val, str) and ref_val in all_ids:
            outgoing.append(ref_val)

    if covered_set is not None and fid not in covered_set:
        diags.append(
            CompletenessDiagnostic(
                code="uncovered_fixture",
                severity="info",
                family_id=fid,
                path=fid,
                message=f"Realization family {fid!r} has no recorded declarative fixture coverage",
                repair_hint="Add a provider-owned declarative fixture case exercising this realization.",
            )
        )

    locales = sorted(str(k) for k in translations.keys())
    nodes = [
        {
            "id": f"{fid}:template",
            "kind": "realization_template",
            "label": f"act={real.get('dialogueAct') or real.get('concept') or '(none)'} locales={locales}",
            "status": "invalid" if (not has_en and not has_forms) else "valid",
            "colorClass": "RED" if (not has_en and not has_forms) else "GREEN",
            "path": f"{fid}.translations",
        }
    ]
    metrics = _common_non_dialogue_envelope(
        fid,
        real,
        kind="realization",
        family_diags=diags,
        covered_set=covered_set,
        manifest_families=manifest_families,
        source_path=source_path,
        reachable_branches=max(1, len(locales) + len(forms)),
        outgoing=outgoing,
        incoming=(),
        nodes=nodes,
        graph_edges=[],
        closure_health="resolved_terminal",
        semantic_status="GREEN",
        closure_class="realization_template",
        kind_detail={
            "type": real.get("type"),
            "dialogueAct": real.get("dialogueAct"),
            "strategy": real.get("strategy"),
            "concept": real.get("concept"),
            "locales": locales,
            "formCount": len(forms),
        },
    )
    return metrics, diags, outgoing


def _family_source_path(
    fid: str,
    dlg: Mapping[str, Any],
    source_paths: Mapping[str, str] | None,
) -> str | None:
    if source_paths and fid in source_paths:
        return str(source_paths[fid])
    lineage = dlg.get("lineage")
    if isinstance(lineage, Mapping) and isinstance(lineage.get("sourcePath"), str):
        return str(lineage["sourcePath"])
    return None


def _build_family_graph_and_metrics(
    fid: str,
    dlg: Mapping[str, Any],
    *,
    dialogues: Mapping[str, Mapping[str, Any]],
    action_contracts: Mapping[str, Mapping[str, Any]] | None,
    family_diags: Sequence[CompletenessDiagnostic],
    scc_members: Sequence[str],
    outgoing: Sequence[str],
    incoming: Sequence[str],
    covered_set: set[str] | None,
    manifest_families: set[str],
    source_path: str | None,
) -> dict[str, Any]:
    lineage = dlg.get("lineage") if isinstance(dlg.get("lineage"), Mapping) else {}
    state_policy = dlg.get("statePolicy") or []
    reply = dlg.get("reply") if isinstance(dlg.get("reply"), Mapping) else {}
    execute = dlg.get("execute")
    after = dlg.get("after") if isinstance(dlg.get("after"), Mapping) else {}
    closure = dlg.get("closure") if isinstance(dlg.get("closure"), Mapping) else {}
    closure_class = str(closure.get("closureClass") or "").strip() or None

    error_count = sum(1 for d in family_diags if d.severity == "error")
    warning_count = sum(1 for d in family_diags if d.severity == "warning")
    info_count = sum(1 for d in family_diags if d.severity == "info")

    nodes: list[dict[str, Any]] = []
    graph_edges: list[dict[str, Any]] = []
    entry_id = f"{fid}:entry"
    nodes.append({
        "id": entry_id,
        "kind": "entry",
        "label": fid,
        "status": "entry",
        "colorClass": "GREEN" if error_count == 0 else "RED",
        "path": fid,
        "details": {"kind": dlg.get("kind") or "dialogue", "owner": dlg.get("owner") or "PsychopatzCore"},
    })

    input_policy = dlg.get("inputPolicy")
    last_gate_id = entry_id
    if input_policy:
        ip_id = f"{fid}:inputPolicy"
        nodes.append({
            "id": ip_id,
            "kind": "input_policy",
            "label": f"inputPolicy: {input_policy}",
            "status": "valid",
            "colorClass": "GREEN",
            "path": f"{fid}.inputPolicy",
            "details": {"inputPolicy": input_policy},
        })
        graph_edges.append({
            "id": f"{entry_id}->{ip_id}",
            "from": entry_id,
            "to": ip_id,
            "label": "input gate",
            "status": "valid",
            "colorClass": "GREEN",
            "path": f"{fid}.inputPolicy",
        })
        last_gate_id = ip_id

    state_matrix: list[dict[str, Any]] = []
    has_pending = False
    for idx, rule in enumerate(state_policy):
        if not isinstance(rule, Mapping):
            continue
        rid = str(rule.get("id") or f"rule_{idx}")
        outcome = str(rule.get("outcome") or "")
        admission = str(rule.get("admission") or "")
        rep_out = rule.get("replyOutcome")
        handled = bool(not rep_out or not reply or rep_out in reply)
        if outcome in ("pending", "deferred"):
            has_pending = True
        state_matrix.append({
            "ruleId": rid,
            "outcome": outcome,
            "admission": admission,
            "replyOutcome": rep_out,
            "handled": handled,
            "hasWhen": rule.get("when") is not None,
        })
        sp_id = f"{fid}:state:{idx}"
        sp_color = "RED" if not handled else ("YELLOW" if outcome in ("pending", "deferred") else "GREEN")
        nodes.append({
            "id": sp_id,
            "kind": "state_policy",
            "label": f"{rid} ({outcome}/{admission})",
            "status": "invalid" if not handled else ("pending" if outcome in ("pending", "deferred") else "valid"),
            "colorClass": sp_color,
            "path": f"{fid}.statePolicy[{idx}]",
            "details": dict(rule),
        })
        graph_edges.append({
            "id": f"{last_gate_id}->{sp_id}",
            "from": last_gate_id,
            "to": sp_id,
            "label": "when" if rule.get("when") is not None else "default",
            "status": "valid",
            "colorClass": sp_color,
            "path": f"{fid}.statePolicy[{idx}]",
        })
        if outcome in ("pending", "deferred"):
            pend_id = f"{fid}:pending:{rid}"
            pend_diags = [d for d in family_diags if d.code == "pending_without_exit"]
            pend_color = "RED" if pend_diags else "YELLOW"
            nodes.append({
                "id": pend_id,
                "kind": "pending_obligation",
                "label": f"pending: {rid}",
                "status": "invalid" if pend_diags else "bounded_pending",
                "colorClass": pend_color,
                "path": f"{fid}.statePolicy[{idx}]",
                "details": {"outcome": outcome, "replyOutcome": rep_out},
            })
            graph_edges.append({
                "id": f"{sp_id}->{pend_id}",
                "from": sp_id,
                "to": pend_id,
                "label": outcome,
                "status": "pending",
                "colorClass": pend_color,
                "path": f"{fid}.statePolicy[{idx}]",
            })

    action_matrix: list[dict[str, Any]] = []
    if isinstance(execute, Mapping) or dlg.get("action"):
        contract_id = (
            str(execute.get("use") or execute.get("id") or "execute")
            if isinstance(execute, Mapping)
            else str(dlg.get("action"))
        )
        act_id = f"{fid}:execute"
        stale_warn = any(d.code == "stale_poststate_risk" for d in family_diags)
        act_color = "ORANGE" if stale_warn else "GREEN"
        nodes.append({
            "id": act_id,
            "kind": "action_contract",
            "label": f"ActionContract: {contract_id}",
            "status": "warning" if stale_warn else "valid",
            "colorClass": act_color,
            "path": f"{fid}.execute" if isinstance(execute, Mapping) else f"{fid}.action",
            "details": {"contractId": contract_id},
        })
        graph_edges.append({
            "id": f"{last_gate_id}->{act_id}",
            "from": last_gate_id,
            "to": act_id,
            "label": "dispatch",
            "status": "valid",
            "colorClass": act_color,
            "path": f"{fid}.execute",
        })
        if action_contracts and contract_id in action_contracts:
            contract = action_contracts[contract_id]
            expected = set((contract.get("outcomeMap") or {}).values())
            if contract.get("defaultOutcome"):
                expected.add(str(contract["defaultOutcome"]))
            for out_name in sorted(expected):
                is_handled = out_name in reply
                action_matrix.append({"contractId": contract_id, "outcome": out_name, "handled": is_handled})
                res_id = f"{fid}:result:{out_name}"
                res_color = "GREEN" if is_handled else "RED"
                nodes.append({
                    "id": res_id,
                    "kind": "action_result",
                    "label": f"result: {out_name}",
                    "status": "valid" if is_handled else "missing_reply",
                    "colorClass": res_color,
                    "path": f"{fid}.reply.{out_name}",
                    "details": {"outcome": out_name, "handled": is_handled},
                })
                graph_edges.append({
                    "id": f"{act_id}->{res_id}",
                    "from": act_id,
                    "to": res_id,
                    "label": out_name,
                    "status": "valid" if is_handled else "invalid",
                    "colorClass": res_color,
                    "path": f"{fid}.reply.{out_name}",
                })

    for out_name, branch in reply.items():
        rep_id = f"{fid}:reply:{out_name}"
        branch_after = branch.get("after") if isinstance(branch, Mapping) and isinstance(branch.get("after"), Mapping) else {}
        branch_closure = branch.get("closure") if isinstance(branch, Mapping) and isinstance(branch.get("closure"), Mapping) else {}
        rep_color = "BLUE" if (branch_after.get("goto") or branch_after.get("recommend")) else "GREEN"
        nodes.append({
            "id": rep_id,
            "kind": "reply_outcome",
            "label": f"reply.{out_name}",
            "status": "continuation" if rep_color == "BLUE" else "valid",
            "colorClass": rep_color,
            "path": f"{fid}.reply.{out_name}",
            "details": {"after": branch_after, "closure": branch_closure},
        })
        graph_edges.append({
            "id": f"{last_gate_id}->{rep_id}",
            "from": last_gate_id,
            "to": rep_id,
            "label": out_name,
            "status": "valid",
            "colorClass": rep_color,
            "path": f"{fid}.reply.{out_name}",
        })

    for target_id in outgoing:
        cont_id = f"{fid}:continuation:{target_id}"
        exists = target_id in dialogues
        cont_color = "BLUE" if exists else "RED"
        nodes.append({
            "id": cont_id,
            "kind": "continuation",
            "label": f"-> {target_id}",
            "status": "valid_continuation" if exists else "dead_end",
            "colorClass": cont_color,
            "path": f"{fid}.after",
            "details": {"target": target_id, "exists": exists},
        })
        graph_edges.append({
            "id": f"{last_gate_id}->{cont_id}",
            "from": last_gate_id,
            "to": cont_id,
            "label": "goto/recommend",
            "status": "valid" if exists else "invalid",
            "colorClass": cont_color,
            "path": f"{fid}.after",
        })

    if closure_class == "open_domain_obligation":
        cl_id = f"{fid}:closure"
        cl_err = any(d.code == "lost_commitment" for d in family_diags)
        nodes.append({
            "id": cl_id,
            "kind": "domain_obligation",
            "label": f"obligation: {closure.get('obligationRef') or 'missing'}",
            "status": "invalid" if cl_err else "domain_obligation",
            "colorClass": "RED" if cl_err else "PURPLE",
            "path": f"{fid}.closure",
            "details": dict(closure),
        })
        graph_edges.append({
            "id": f"{last_gate_id}->{cl_id}",
            "from": last_gate_id,
            "to": cl_id,
            "label": "open_domain_obligation",
            "status": "invalid" if cl_err else "domain_obligation",
            "colorClass": "RED" if cl_err else "PURPLE",
            "path": f"{fid}.closure",
        })
    elif closure_class == "resolved_episode":
        cl_id = f"{fid}:closure"
        cl_err = any(d.code == "dangling_memory" for d in family_diags)
        nodes.append({
            "id": cl_id,
            "kind": "memory_residue",
            "label": f"episode: {closure.get('episodeId') or 'missing'}",
            "status": "invalid" if cl_err else "resolved_terminal",
            "colorClass": "RED" if cl_err else "GREEN",
            "path": f"{fid}.closure",
            "details": dict(closure),
        })
        graph_edges.append({
            "id": f"{last_gate_id}->{cl_id}",
            "from": last_gate_id,
            "to": cl_id,
            "label": "resolved_episode",
            "status": "invalid" if cl_err else "resolved_terminal",
            "colorClass": "RED" if cl_err else "GREEN",
            "path": f"{fid}.closure",
        })
    else:
        term_id = f"{fid}:terminal"
        term_color = "RED" if error_count > 0 else ("ORANGE" if warning_count > 0 else ("BLUE" if outgoing else "GREEN"))
        nodes.append({
            "id": term_id,
            "kind": "terminal_closure",
            "label": f"closure: {closure_class or ('continuation' if outgoing else 'terminal')}",
            "status": "invalid" if error_count > 0 else ("warning" if warning_count > 0 else "terminal"),
            "colorClass": term_color,
            "path": f"{fid}.closure" if closure else f"{fid}.after",
            "details": dict(closure) if closure else {"end": after.get("end", True)},
        })

    if error_count > 0:
        closure_health = "invalid"
        semantic_status = "RED"
    elif warning_count > 0:
        closure_health = "warning"
        semantic_status = "ORANGE"
    elif has_pending or closure_class == "bounded_pending":
        closure_health = "bounded_pending"
        semantic_status = "YELLOW"
    elif closure_class == "open_domain_obligation":
        closure_health = "domain_obligation"
        semantic_status = "PURPLE"
    elif outgoing:
        closure_health = "continuation"
        semantic_status = "BLUE"
    else:
        closure_health = "resolved_terminal"
        semantic_status = "GREEN"

    reachable_branches = max(1, len(state_policy) + len(reply) + len(outgoing))
    handled_branches = max(
        0,
        reachable_branches - sum(1 for d in family_diags if d.severity == "error"),
    )
    if covered_set is not None:
        fixture_coverage = "covered" if fid in covered_set else "uncovered"
    elif fid in manifest_families:
        fixture_coverage = "manifest_owned"
    else:
        fixture_coverage = "unknown"

    return {
        "familyId": fid,
        "owner": str(dlg.get("owner") or "PsychopatzCore"),
        "kind": str(dlg.get("kind") or "dialogue"),
        "namespace": str(dlg.get("namespace") or (fid.rsplit(".", 1)[0] if "." in fid else "")),
        "localId": str(lineage.get("localId") or fid.rsplit(".", 1)[-1]),
        "sourceShard": lineage.get("sourcePath"),
        "sourcePath": source_path,
        "reachableBranches": reachable_branches,
        "handledBranches": handled_branches,
        "closureClass": closure_class or ("continuation" if outgoing else "implicit_terminal"),
        "closureHealth": closure_health,
        "semanticStatus": semantic_status,
        "errorCount": error_count,
        "warningCount": warning_count,
        "infoCount": info_count,
        "diagnosticCodes": sorted({d.code for d in family_diags}),
        "fixtureCoverage": fixture_coverage,
        "typedClickParity": str(input_policy or "unspecified"),
        "repeatPolicy": str(dlg.get("repeatPolicy") or "unspecified"),
        "hasStatePolicy": bool(state_policy),
        "hasPostconditions": bool(dlg.get("postconditions")),
        "hasClosure": bool(closure),
        "stateOutcomeMatrix": state_matrix,
        "actionOutcomeMatrix": action_matrix,
        "sccMembers": sorted(scc_members),
        "dependencies": sorted(set(outgoing)),
        "dependents": sorted(set(incoming)),
        "affectedClosure": sorted(set(outgoing) | set(incoming) | set(scc_members) | {fid}),
        "graph": {"nodes": nodes, "edges": graph_edges},
    }


def analyze_portable_plan(
    plan: Mapping[str, Any],
    *,
    action_contracts: Mapping[str, Mapping[str, Any]] | None = None,
    covered_family_ids: Iterable[str] | None = None,
    constrained_manifest: Mapping[str, Any] | None = None,
    strict_manifest: bool = False,
    audit_inventory: Mapping[str, Any] | None = None,
    workspace_roots: Mapping[str, Path] | None = None,
    source_paths: Mapping[str, str] | None = None,
    family_ids: Iterable[str] | None = None,
    catalog_family_ids: Iterable[str] | None = None,
) -> dict[str, Any]:
    """Analyze a Portable Dialogue Plan and return a machine-readable completeness report."""
    if not isinstance(plan, Mapping) or plan.get("schema") != PORTABLE_PLAN_SCHEMA:
        raise ValueError(f"Expected Portable Dialogue Plan ({PORTABLE_PLAN_SCHEMA})")

    dialogues: Mapping[str, Mapping[str, Any]] = plan.get("dialogues") or {}
    behaviors: Mapping[str, Mapping[str, Any]] = plan.get("behaviors") or {}
    beats: Mapping[str, Mapping[str, Any]] = plan.get("beats") or {}
    realizations: Mapping[str, Mapping[str, Any]] = plan.get("realizations") or {}
    all_records: dict[str, Mapping[str, Any]] = {}
    all_records.update(dialogues)
    all_records.update(behaviors)
    all_records.update(beats)
    all_records.update(realizations)
    all_ids = set(all_records.keys())
    covered_set = set(covered_family_ids) if covered_family_ids is not None else None
    diagnostics: list[CompletenessDiagnostic] = []
    edges: dict[str, list[str]] = {}
    in_degree: dict[str, int] = {fid: 0 for fid in dialogues}

    for fid in sorted(dialogues):
        dlg = dialogues[fid]
        targets, refs = _collect_edges(fid, dlg)
        edges[fid] = [t for t in targets if t in dialogues]
        for target_id in edges[fid]:
            in_degree[target_id] = in_degree.get(target_id, 0) + 1
        for ref_path, ref_target in refs:
            if ref_target not in dialogues:
                diagnostics.append(
                    CompletenessDiagnostic(
                        code="dead_end",
                        severity="error",
                        family_id=fid,
                        path=ref_path,
                        message=f"Continuation target {ref_target!r} does not exist in plan",
                        repair_hint=f"Define dialogue {ref_target!r} or replace {ref_path} with a valid family or end=true.",
                    )
                )

        # 1. State policy & reachability
        state_policy = dlg.get("statePolicy") or []
        reply = dlg.get("reply") if isinstance(dlg.get("reply"), Mapping) else {}
        seen_unconditional = False
        has_pending_rule = False
        has_exit_from_pending = False
        for idx, rule in enumerate(state_policy):
            rpath = f"{fid}.statePolicy[{idx}]"
            if seen_unconditional:
                diagnostics.append(
                    CompletenessDiagnostic(
                        code="unreachable_branch",
                        severity="error",
                        family_id=fid,
                        path=rpath,
                        message=f"State rule {rule.get('id')!r} is unreachable after an unconditional rule",
                        repair_hint="Reorder rules so guarded rules precede the default/unconditional fallback.",
                    )
                )
            rep_out = rule.get("replyOutcome")
            if rep_out and reply and rep_out not in reply:
                diagnostics.append(
                    CompletenessDiagnostic(
                        code="unhandled_state_outcome",
                        severity="error",
                        family_id=fid,
                        path=f"{rpath}.replyOutcome",
                        message=f"State rule replyOutcome {rep_out!r} is missing from reply outcomes",
                        repair_hint=f"Add reply.{rep_out} with independent spoken realization.",
                    )
                )
            if rule.get("outcome") in ("pending", "deferred") and not seen_unconditional:
                has_pending_rule = True
                if rep_out and rep_out in reply:
                    branch = reply[rep_out]
                    if isinstance(branch, Mapping) and (branch.get("after") or branch.get("closure")):
                        has_exit_from_pending = True
            elif (
                not seen_unconditional
                and rule.get("admission") in ("dispatch", "no_op")
                and rule.get("outcome") in ("actionable", "already_satisfied")
            ):
                has_exit_from_pending = True
            if rule.get("when") is None:
                seen_unconditional = True

        if state_policy and not seen_unconditional:
            diagnostics.append(
                CompletenessDiagnostic(
                    code="unhandled_state_outcome",
                    severity="warning",
                    family_id=fid,
                    path=f"{fid}.statePolicy",
                    message="statePolicy has no unconditional fallback rule",
                    repair_hint="Add a final fallback rule without 'when' (e.g. unavailable/no_op or actionable/dispatch).",
                )
            )
        if has_pending_rule and not has_exit_from_pending:
            diagnostics.append(
                CompletenessDiagnostic(
                    code="pending_without_exit",
                    severity="error",
                    family_id=fid,
                    path=f"{fid}.statePolicy",
                    message="Pending/deferred state has no reachable exit, resolution, or continuation",
                    repair_hint="Add an acceptance/resolution state rule or reply branch with after/closure.",
                )
            )

        # 2. ActionContract outcome completeness & stale poststate risk
        execute = dlg.get("execute")
        action = dlg.get("action")
        has_mutation = bool(execute or action)
        if has_mutation and not dlg.get("postconditions") and not state_policy:
            diagnostics.append(
                CompletenessDiagnostic(
                    code="stale_poststate_risk",
                    severity="warning",
                    family_id=fid,
                    path=fid,
                    message="Mutating family has no postconditions or statePolicy to prevent stale re-dispatch",
                    repair_hint="Declare statePolicy rules and postconditions for idempotent/state-aware closure.",
                )
            )
        if action_contracts and isinstance(execute, Mapping):
            contract_id = execute.get("use") or execute.get("id")
            if isinstance(contract_id, str) and contract_id in action_contracts:
                contract = action_contracts[contract_id]
                expected_outcomes = set((contract.get("outcomeMap") or {}).values())
                if contract.get("defaultOutcome"):
                    expected_outcomes.add(str(contract["defaultOutcome"]))
                missing = sorted(o for o in expected_outcomes if o not in reply)
                for m in missing:
                    diagnostics.append(
                        CompletenessDiagnostic(
                            code="unhandled_action_outcome",
                            severity="error",
                            family_id=fid,
                            path=f"{fid}.reply",
                            message=f"ActionContract {contract_id!r} outcome {m!r} is not handled in reply",
                            repair_hint=f"Add reply.{m} to handle action outcome {m!r}.",
                        )
                    )

        # 3. Closure / Memory residue integrity
        closure = dlg.get("closure")
        if isinstance(closure, Mapping):
            cclass = closure.get("closureClass")
            if cclass == "resolved_episode" and not closure.get("episodeId"):
                diagnostics.append(
                    CompletenessDiagnostic(
                        code="dangling_memory",
                        severity="error",
                        family_id=fid,
                        path=f"{fid}.closure.episodeId",
                        message="resolved_episode closure requires an episodeId",
                        repair_hint="Set closure.episodeId to a stable lowercase semantic episode identifier.",
                    )
                )
            if cclass == "open_domain_obligation" and not closure.get("obligationRef"):
                diagnostics.append(
                    CompletenessDiagnostic(
                        code="lost_commitment",
                        severity="error",
                        family_id=fid,
                        path=f"{fid}.closure.obligationRef",
                        message="open_domain_obligation closure requires an obligationRef",
                        repair_hint="Set closure.obligationRef to the authoritative task/promise reference.",
                    )
                )

        # 4. Role / cardinality legality & group safety
        roles = dlg.get("roles") or {}
        pset = dlg.get("participantSet")
        multi_roles: set[str] = set()
        for rname, rspec in roles.items():
            if rname in FORBIDDEN_POSITIONAL_ROLES:
                diagnostics.append(
                    CompletenessDiagnostic(
                        code="role_unbound",
                        severity="error",
                        family_id=fid,
                        path=f"{fid}.roles.{rname}",
                        message=f"Forbidden positional role {rname!r}",
                        repair_hint="Use semantic roles (speaker, addressee, actor, target, mediator, etc.).",
                    )
                )
            card = (rspec or {}).get("cardinality", "ONE")
            if card not in ROLE_CARDINALITIES:
                diagnostics.append(
                    CompletenessDiagnostic(
                        code="role_cardinality_mismatch",
                        severity="error",
                        family_id=fid,
                        path=f"{fid}.roles.{rname}.cardinality",
                        message=f"Unsupported role cardinality {card!r}",
                        repair_hint=f"Use one of {sorted(ROLE_CARDINALITIES)}.",
                    )
                )
            if card in MULTI_CARDINALITIES:
                multi_roles.add(rname)
                if card in ("ONE_OR_MORE", "ZERO_OR_MORE") and not (
                    isinstance(pset, Mapping) and pset.get("maxSize")
                ):
                    diagnostics.append(
                        CompletenessDiagnostic(
                            code="unbounded_group_reaction",
                            severity="error",
                            family_id=fid,
                            path=f"{fid}.roles.{rname}",
                            message=f"Unbounded multi-entity role {rname!r} ({card}) lacks participantSet.maxSize",
                            repair_hint="Use BOUNDED_MANY with min/max or set participantSet.maxSize.",
                        )
                    )

        for idx, eff in enumerate(dlg.get("effects") or []):
            trole = (eff or {}).get("targetRole")
            if trole in multi_roles and not (eff.get("params") or {}).get("scope"):
                diagnostics.append(
                    CompletenessDiagnostic(
                        code="ambiguous_group_effect",
                        severity="error",
                        family_id=fid,
                        path=f"{fid}.effects[{idx}]",
                        message=f"Effect targets multi-entity role {trole!r} without params.scope",
                        repair_hint="Set params.scope (e.g. 'all' or 'first') on group-targeted effects.",
                    )
                )

        # 5. Fixture coverage (optional)
        if covered_set is not None and fid not in covered_set:
            diagnostics.append(
                CompletenessDiagnostic(
                    code="uncovered_fixture",
                    severity="info",
                    family_id=fid,
                    path=fid,
                    message=f"Dialogue family {fid!r} has no recorded declarative fixture coverage",
                    repair_hint="Add a provider-owned declarative fixture case referencing this family.",
                )
            )

    # 6. SCC / cycle bounded progress
    sccs = _tarjan_sccs(dialogues.keys(), edges)
    for scc in sccs:
        has_cycle = len(scc) > 1 or (len(scc) == 1 and scc[0] in edges.get(scc[0], ()))
        if not has_cycle:
            continue
        bounded = any(
            (dialogues[fid].get("repeatPolicy") in BOUNDED_REPEAT_POLICIES)
            or bool(dialogues[fid].get("cooldownTurns"))
            or bool(dialogues[fid].get("maxTurns"))
            for fid in scc
        )
        if not bounded:
            rep_fid = sorted(scc)[0]
            diagnostics.append(
                CompletenessDiagnostic(
                    code="unbounded_loop",
                    severity="error",
                    family_id=rep_fid,
                    path=f"{rep_fid}.after",
                    message=f"Cyclic continuation SCC {sorted(scc)} lacks bounded repeatPolicy or maxTurns/cooldownTurns",
                    repair_hint="Set repeatPolicy ('once'|'cooldown'|'max_uses'|'state_retired') on cycle members.",
                )
            )
            diagnostics.append(
                CompletenessDiagnostic(
                    code="missing_repeat_policy",
                    severity="error",
                    family_id=rep_fid,
                    path=f"{rep_fid}.repeatPolicy",
                    message=f"Cycle member {rep_fid!r} requires an explicit bounded repeatPolicy",
                    repair_hint="Declare repeatPolicy on cyclic dialogue families.",
                )
            )

    if constrained_manifest is not None:
        _validate_constrained_manifest(
            dialogues,
            constrained_manifest,
            strict_manifest=strict_manifest,
            diagnostics=diagnostics,
            audit_inventory=audit_inventory,
            workspace_roots=workspace_roots,
        )

    reverse_edges: dict[str, list[str]] = {fid: [] for fid in dialogues}
    for src_fid, target_list in edges.items():
        for tgt_fid in target_list:
            reverse_edges.setdefault(tgt_fid, []).append(src_fid)

    scc_by_family: dict[str, list[str]] = {}
    for scc in sccs:
        sorted_scc = sorted(scc)
        for member in sorted_scc:
            scc_by_family[member] = sorted_scc

    manifest_families: set[str] = set()
    if isinstance(constrained_manifest, Mapping):
        for entry in constrained_manifest.get("entries") or ():
            if isinstance(entry, Mapping) and entry.get("familyId"):
                manifest_families.add(str(entry["familyId"]))

    requested_families = {str(f) for f in family_ids} if family_ids is not None else None
    if requested_families is not None:
        affected_set: set[str] = set()
        for seed in requested_families:
            if seed in all_records:
                affected_set.add(seed)
                affected_set.update(edges.get(seed, ()))
                affected_set.update(reverse_edges.get(seed, ()))
                affected_set.update(scc_by_family.get(seed, ()))
    else:
        affected_set = set(all_records.keys())

    non_dialogue_metrics: dict[str, dict[str, Any]] = {}
    non_dialogue_edges: dict[str, list[str]] = {}
    for fid in sorted(behaviors):
        m, dlist, out_list = _analyze_behavior_family(
            fid,
            behaviors[fid],
            all_ids=all_ids,
            covered_set=covered_set,
            manifest_families=manifest_families,
            source_path=_family_source_path(fid, behaviors[fid], source_paths),
        )
        non_dialogue_metrics[fid] = m
        diagnostics.extend(dlist)
        if out_list:
            non_dialogue_edges[fid] = out_list
    for fid in sorted(beats):
        m, dlist, out_list = _analyze_beat_family(
            fid,
            beats[fid],
            behaviors=behaviors,
            dialogues=dialogues,
            covered_set=covered_set,
            manifest_families=manifest_families,
            source_path=_family_source_path(fid, beats[fid], source_paths),
        )
        non_dialogue_metrics[fid] = m
        diagnostics.extend(dlist)
        if out_list:
            non_dialogue_edges[fid] = out_list
    for fid in sorted(realizations):
        m, dlist, out_list = _analyze_realization_family(
            fid,
            realizations[fid],
            all_ids=all_ids,
            covered_set=covered_set,
            manifest_families=manifest_families,
            source_path=_family_source_path(fid, realizations[fid], source_paths),
        )
        non_dialogue_metrics[fid] = m
        diagnostics.extend(dlist)
        if out_list:
            non_dialogue_edges[fid] = out_list

    for src_fid, targets in non_dialogue_edges.items():
        edges[src_fid] = targets
        for tgt in targets:
            reverse_edges.setdefault(tgt, []).append(src_fid)

    catalog_mismatch = False
    if catalog_family_ids is not None and requested_families is None:
        catalog_set = {str(x) for x in catalog_family_ids if x}
        missing_in_plan = sorted(catalog_set - all_ids)
        extra_in_plan = sorted(all_ids - catalog_set)
        if missing_in_plan or extra_in_plan:
            catalog_mismatch = True
            for fid in missing_in_plan:
                diagnostics.append(
                    CompletenessDiagnostic(
                        code="catalog_report_mismatch",
                        severity="error",
                        family_id=fid,
                        path=fid,
                        message=f"Maintained catalog family {fid!r} is missing from authoring-health report",
                        repair_hint="Ensure compiler/PortablePlan includes all maintained canonical families.",
                    )
                )
            for fid in extra_in_plan:
                diagnostics.append(
                    CompletenessDiagnostic(
                        code="catalog_report_mismatch",
                        severity="error",
                        family_id=fid,
                        path=fid,
                        message=f"Analyzed family {fid!r} is absent from maintained source catalog",
                        repair_hint="Reconcile canonical catalog and PortablePlan.",
                    )
                )

    enriched_diagnostics: list[CompletenessDiagnostic] = []
    diags_by_family: dict[str, list[CompletenessDiagnostic]] = {}
    for diag in diagnostics:
        fid = diag.family_id
        dlg = all_records.get(fid)
        src_path = _family_source_path(fid, dlg, source_paths) if isinstance(dlg, Mapping) else None
        scc_members = tuple(scc_by_family.get(fid, (fid,) if fid in all_records else ()))
        closure_obj = dlg.get("closure") if isinstance(dlg, Mapping) and isinstance(dlg.get("closure"), Mapping) else {}
        closure_cls = str(closure_obj.get("closureClass") or "none") if isinstance(dlg, Mapping) else None
        ownership, suggested_closures = _DIAGNOSTIC_OWNERSHIP_MAP.get(diag.code, ("semantic_structure", ()))
        cycle_path: tuple[str, ...] = ()
        if diag.code in ("unbounded_loop", "missing_repeat_policy") and scc_members:
            cycle_path = (*scc_members, scc_members[0])
        witness = diag.witness_path or (
            (f"{fid}:entry", diag.path) if diag.path and diag.path != fid else (f"{fid}:entry",)
        )
        node_id = diag.node_id or (
            f"{fid}:after" if diag.code in ("dead_end", "unbounded_loop")
            else f"{fid}:closure" if diag.code in ("dangling_memory", "lost_commitment")
            else f"{fid}:entry"
        )
        edge_id = diag.edge_id or (f"{fid}:after->{diag.path}" if diag.code == "dead_end" else None)
        enriched = CompletenessDiagnostic(
            code=diag.code,
            severity=diag.severity,
            family_id=diag.family_id,
            path=diag.path,
            message=diag.message,
            repair_hint=diag.repair_hint,
            source_path=src_path,
            node_id=node_id,
            edge_id=edge_id,
            witness_path=witness,
            cycle_path=cycle_path,
            scc_members=scc_members,
            closure_class=closure_cls,
            missing_ownership=ownership,
            suggested_closure_classes=suggested_closures,
        )
        enriched_diagnostics.append(enriched)
        diags_by_family.setdefault(fid, []).append(enriched)

    families_report: dict[str, dict[str, Any]] = {}
    health_counts: dict[str, int] = {
        "resolved_terminal": 0,
        "continuation": 0,
        "domain_obligation": 0,
        "bounded_pending": 0,
        "warning": 0,
        "invalid": 0,
    }
    by_kind: dict[str, dict[str, int]] = {
        k: {"total": 0, "analyzed": 0, "healthy": 0, "warning": 0, "error": 0, "missingCoverage": 0}
        for k in ("dialogue", "behavior", "beat", "realization")
    }
    by_kind["dialogue"]["total"] = len(dialogues)
    by_kind["behavior"]["total"] = len(behaviors)
    by_kind["beat"]["total"] = len(beats)
    by_kind["realization"]["total"] = len(realizations)

    for fid in sorted(affected_set):
        if fid in dialogues:
            dlg = dialogues[fid]
            fmetrics = _build_family_graph_and_metrics(
                fid,
                dlg,
                dialogues=dialogues,
                action_contracts=action_contracts,
                family_diags=diags_by_family.get(fid, ()),
                scc_members=scc_by_family.get(fid, [fid]),
                outgoing=edges.get(fid, ()),
                incoming=reverse_edges.get(fid, ()),
                covered_set=covered_set,
                manifest_families=manifest_families,
                source_path=_family_source_path(fid, dlg, source_paths),
            )
        elif fid in non_dialogue_metrics:
            fmetrics = dict(non_dialogue_metrics[fid])
            fmetrics["dependents"] = sorted(set(reverse_edges.get(fid, ())))
            fmetrics["affectedClosure"] = sorted(
                set(fmetrics.get("dependencies") or ()) | set(fmetrics["dependents"]) | {fid}
            )
        else:
            continue
        families_report[fid] = fmetrics
        health_counts[fmetrics["closureHealth"]] = health_counts.get(fmetrics["closureHealth"], 0) + 1
        k = str(fmetrics.get("kind") or "dialogue")
        ks = by_kind.setdefault(k, {"total": 0, "analyzed": 0, "healthy": 0, "warning": 0, "error": 0, "missingCoverage": 0})
        ks["analyzed"] += 1
        if int(fmetrics.get("errorCount", 0)) > 0:
            ks["error"] += 1
        elif int(fmetrics.get("warningCount", 0)) > 0:
            ks["warning"] += 1
        else:
            ks["healthy"] += 1
        if fmetrics.get("fixtureCoverage") == "uncovered":
            ks["missingCoverage"] += 1

    if requested_families is not None:
        visible_diagnostics = [
            d for d in enriched_diagnostics if d.family_id in affected_set or d.family_id not in all_records
        ]
    else:
        visible_diagnostics = enriched_diagnostics

    errors = [d for d in visible_diagnostics if d.severity == "error"]
    warnings = [d for d in visible_diagnostics if d.severity == "warning"]
    infos = [d for d in visible_diagnostics if d.severity == "info"]
    return {
        "schema": COMPLETENESS_REPORT_SCHEMA,
        "ok": len(errors) == 0 and not catalog_mismatch,
        "summary": {
            "families": len(all_records),
            "analyzedFamilies": len(families_report),
            "errors": len(errors),
            "warnings": len(warnings),
            "info": len(infos),
            "sccs": len(sccs),
            "catalogMismatch": catalog_mismatch,
            "byKind": by_kind,
            "byClosureHealth": health_counts,
        },
        "affectedFamilyIds": sorted(affected_set),
        "families": families_report,
        "dependencyGraph": {
            "edges": {fid: sorted(set(targets)) for fid, targets in edges.items()},
            "reverseEdges": {fid: sorted(set(srcs)) for fid, srcs in reverse_edges.items()},
        },
        "diagnostics": [d.to_dict() for d in visible_diagnostics],
    }


__all__ = [
    "AUDIT_INVENTORY_PATH",
    "AUDIT_INVENTORY_SCHEMA",
    "COMPLETENESS_REPORT_SCHEMA",
    "CONSTRAINED_MANIFEST_PATH",
    "CONSTRAINED_MANIFEST_SCHEMA",
    "CompletenessDiagnostic",
    "MANIFEST_CLASSIFICATIONS",
    "analyze_portable_plan",
    "load_branching_audit_inventory",
    "load_constrained_family_manifest",
]
