"""S11A4: Canonical Dialogue Completeness Analyzer.

Analyzes the frozen S11A1-A3 Portable Dialogue Plan (and optional
ActionContract / DomainSchemaRegistry / fixture coverage inputs) and emits
machine-readable diagnostics for CodeBuilder, CLI, and Semantic Lab.
"""

from __future__ import annotations

from collections.abc import Iterable, Mapping
from dataclasses import dataclass
from typing import Any

from .portable_runtime import PORTABLE_PLAN_SCHEMA
from .semantic_contract import FORBIDDEN_POSITIONAL_ROLES, ROLE_CARDINALITIES

COMPLETENESS_REPORT_SCHEMA = "psychopatz.convo-engine.completeness-report.v1"
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


def analyze_portable_plan(
    plan: Mapping[str, Any],
    *,
    action_contracts: Mapping[str, Mapping[str, Any]] | None = None,
    covered_family_ids: Iterable[str] | None = None,
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
    "COMPLETENESS_REPORT_SCHEMA",
    "CompletenessDiagnostic",
    "analyze_portable_plan",
]
