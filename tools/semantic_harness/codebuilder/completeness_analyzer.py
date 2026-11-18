"""S11A4: Canonical Dialogue Completeness Analyzer.

Analyzes the frozen S11A1-A3 Portable Dialogue Plan (and optional
ActionContract / DomainSchemaRegistry / fixture coverage inputs) and emits
machine-readable diagnostics for CodeBuilder, CLI, and Semantic Lab.
"""

from __future__ import annotations

import ast
import json
from collections.abc import Iterable, Mapping
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

    def to_dict(self) -> dict[str, Any]:
        return {
            "code": self.code,
            "severity": self.severity,
            "familyId": self.family_id,
            "path": self.path,
            "message": self.message,
            "repairHint": self.repair_hint,
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


def _extract_test_texts(
    owner_kind: str, source_path: Path, test_ids: list[str]
) -> tuple[dict[str, str], list[str]]:
    """Return {test_id: searchable_text} and list of missing test_ids."""
    raw = source_path.read_text(encoding="utf-8")
    found: dict[str, str] = {}
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
                found[tid] = json.dumps(case, sort_keys=True).lower()
        return found, missing
    if owner_kind == "python_test":
        tree = ast.parse(raw)
        methods: dict[str, str] = {}
        for node in ast.walk(tree):
            if isinstance(node, ast.FunctionDef) and node.name.startswith("test_"):
                segment = ast.get_source_segment(raw, node) or node.name
                methods[node.name] = segment.lower()
        missing = [tid for tid in test_ids if tid not in methods]
        for tid in test_ids:
            if tid in methods:
                found[tid] = methods[tid]
        return found, missing
    if owner_kind == "lua_test":
        lowered = raw.lower()
        missing = [tid for tid in test_ids if tid not in raw]
        for tid in test_ids:
            if tid in raw:
                found[tid] = lowered
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
    found_texts, missing_ids = _extract_test_texts(owner_kind, source_path, test_ids)
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
        keywords = [
            str(kw).strip().lower()
            for kw in (audit_entry.get("claimKeywords") or [])
            if str(kw).strip()
        ]
        if keywords and found_texts:
            combined = "\n".join(found_texts.values())
            if not any(kw in combined for kw in keywords):
                diagnostics.append(
                    CompletenessDiagnostic(
                        code="acceptance_claim_mismatch",
                        severity="error",
                        family_id=str(fid or aid),
                        path=f"manifest.entries[{idx}].acceptance",
                        message=f"Referenced tests {test_ids} in {source!r} do not claim any of {keywords} for {aid!r}",
                        repair_hint="Bind the actual test/fixture that verifies this audit row.",
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


def analyze_portable_plan(
    plan: Mapping[str, Any],
    *,
    action_contracts: Mapping[str, Mapping[str, Any]] | None = None,
    covered_family_ids: Iterable[str] | None = None,
    constrained_manifest: Mapping[str, Any] | None = None,
    strict_manifest: bool = False,
    audit_inventory: Mapping[str, Any] | None = None,
    workspace_roots: Mapping[str, Path] | None = None,
) -> dict[str, Any]:
    """Analyze a Portable Dialogue Plan and return a machine-readable completeness report."""
    if not isinstance(plan, Mapping) or plan.get("schema") != PORTABLE_PLAN_SCHEMA:
        raise ValueError(f"Expected Portable Dialogue Plan ({PORTABLE_PLAN_SCHEMA})")

    dialogues: Mapping[str, Mapping[str, Any]] = plan.get("dialogues") or {}
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

    errors = [d for d in diagnostics if d.severity == "error"]
    warnings = [d for d in diagnostics if d.severity == "warning"]
    infos = [d for d in diagnostics if d.severity == "info"]
    return {
        "schema": COMPLETENESS_REPORT_SCHEMA,
        "ok": len(errors) == 0,
        "summary": {
            "families": len(dialogues),
            "errors": len(errors),
            "warnings": len(warnings),
            "info": len(infos),
            "sccs": len(sccs),
        },
        "diagnostics": [d.to_dict() for d in diagnostics],
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
