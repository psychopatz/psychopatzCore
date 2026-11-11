"""Production-backed variant reachability frontier and selection provenance analyzer.

Analyzes registered response pools and variants against executed sweep evidence,
truthfully classifying each variant into:
- UNTESTED
- TESTED_INELIGIBLE
- ELIGIBLE_NOT_SELECTED (dominated in tested contexts)
- SELECTED
- SELECTED_UNDER_SUSPICIOUS_CONTEXT

Crucial rule: Finite non-selection is NEVER claimed to be globally impossible or unreachable.
"""

from __future__ import annotations

from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Mapping, Sequence

REACHABILITY_SCHEMA_V1 = "pnc.semantic-reachability-report.v1"
ALLOWED_REACHABILITY_SCHEMAS = frozenset({REACHABILITY_SCHEMA_V1})


class VariantReachabilityState:
    UNTESTED = "UNTESTED"
    TESTED_INELIGIBLE = "TESTED_INELIGIBLE"
    ELIGIBLE_NOT_SELECTED = "ELIGIBLE_NOT_SELECTED"
    SELECTED = "SELECTED"
    SELECTED_UNDER_SUSPICIOUS_CONTEXT = "SELECTED_UNDER_SUSPICIOUS_CONTEXT"


@dataclass
class ObservedVariantEntry:
    """Aggregated observation record for a single response variant."""

    pool_id: str
    variant_id: str
    count: int = 0
    languages: set[str] = field(default_factory=set)
    surfaces: set[str] = field(default_factory=set)
    context_vectors: list[dict[str, Any]] = field(default_factory=list)
    rendered_sentences: list[str] = field(default_factory=list)
    case_ids: list[str] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        return {
            "poolID": self.pool_id,
            "variantID": self.variant_id,
            "count": self.count,
            "languages": sorted(list(self.languages)),
            "surfaces": sorted(list(self.surfaces)),
            "contextVectors": self.context_vectors[:10],
            "renderedSentences": self.rendered_sentences[:10],
            "caseIDs": self.case_ids[:10],
        }


class ObservedVariantLedger:
    """Aggregates execution truth from compact evidence rows."""

    def __init__(self) -> None:
        self.entries: dict[str, ObservedVariantEntry] = {}

    def record_row(self, row: Mapping[str, Any]) -> str | None:
        sel_prov = row.get("selectionProvenance", {})
        sem_path = row.get("semanticPath", {})
        var_id = sel_prov.get("selectedVariantID") or sem_path.get("semanticVariantID")
        if not var_id:
            return None
        pool_id = sel_prov.get("selectedPoolID") or sem_path.get("semanticTemplateID") or "unknown"
        case_id = row.get("identity", {}).get("caseID") or "unknown"
        lang = row.get("identity", {}).get("language") or "EN"
        surface = (
            row.get("identity", {}).get("plannedSurface")
            or row.get("identity", {}).get("reachedSurface")
            or "unknown"
        )
        params = row.get("trigger", {}).get("parameters") or {}
        text = str(row.get("output", {}).get("finalText") or "").strip()

        entry = self.entries.get(var_id)
        if entry is None:
            entry = ObservedVariantEntry(pool_id=pool_id, variant_id=var_id)
            self.entries[var_id] = entry

        entry.count += 1
        entry.languages.add(lang)
        entry.surfaces.add(surface)
        if case_id not in entry.case_ids:
            entry.case_ids.append(case_id)
        if params and params not in entry.context_vectors:
            entry.context_vectors.append(params)
        if text and text not in entry.rendered_sentences:
            entry.rendered_sentences.append(text)
        return var_id

    def record_rows(self, rows: Sequence[Mapping[str, Any]]) -> int:
        recorded = 0
        for r in rows:
            if self.record_row(r) is not None:
                recorded += 1
        return recorded

    def is_observed(self, variant_id: str) -> bool:
        return variant_id in self.entries

    def observed_variant_ids(self) -> set[str]:
        return set(self.entries.keys())

    def get_entry(self, variant_id: str) -> ObservedVariantEntry | None:
        return self.entries.get(variant_id)

    def total_observed_variants(self) -> int:
        return len(self.entries)

    def to_dict(self) -> dict[str, Any]:
        return {
            "totalObservedVariants": len(self.entries),
            "entries": {vid: entry.to_dict() for vid, entry in self.entries.items()},
        }


@dataclass
class VariantReachabilityRecord:
    """Reachability status and production evidence for a single response variant."""

    pool_id: str
    variant_id: str
    status: str  # VariantReachabilityState
    tested_contexts_count: int = 0
    eligible_contexts_count: int = 0
    selected_contexts_count: int = 0
    selected_case_ids: list[str] = field(default_factory=list)
    rejection_reasons: list[str] = field(default_factory=list)
    failed_checks: list[str] = field(default_factory=list)
    canonical_source_owner: str = "UNKNOWN"
    global_unreachable_claim: bool = False  # Mandatory: never claim global unreachability

    def to_dict(self) -> dict[str, Any]:
        return {
            "poolID": self.pool_id,
            "variantID": self.variant_id,
            "status": self.status,
            "testedContextsCount": self.tested_contexts_count,
            "eligibleContextsCount": self.eligible_contexts_count,
            "selectedContextsCount": self.selected_contexts_count,
            "selectedCaseIDs": self.selected_case_ids,
            "rejectionReasons": self.rejection_reasons,
            "failedChecks": self.failed_checks,
            "canonicalSourceOwner": self.canonical_source_owner,
            "globalUnreachableClaim": False,
        }


@dataclass
class ReachabilityReport:
    """Comprehensive reachability report across registered response pools."""

    sweep_id: str
    total_pools: int
    total_variants: int
    status_counts: dict[str, int]
    pool_records: dict[str, list[VariantReachabilityRecord]]
    frontier_candidates: list[dict[str, Any]] = field(default_factory=list)
    production_total_pools: int = 0
    enumerated_total_pools: int = 0
    pagination_complete: bool = True
    global_unreachable_warning: str = (
        "Finite non-selection in tested matrices does not prove global unreachability."
    )
    ledger: dict[str, Any] = field(default_factory=dict)
    schema: str = REACHABILITY_SCHEMA_V1
    schema_version: int = 1

    def to_dict(self) -> dict[str, Any]:
        return {
            "schema": self.schema,
            "schemaVersion": self.schema_version,
            "sweepID": self.sweep_id,
            "totalPools": self.total_pools,
            "totalVariants": self.total_variants,
            "productionTotalPools": self.production_total_pools,
            "enumeratedTotalPools": self.enumerated_total_pools,
            "paginationComplete": self.pagination_complete,
            "statusCounts": self.status_counts,
            "globalUnreachableWarning": self.global_unreachable_warning,
            "ledger": self.ledger,
            "pools": {
                p: [v.to_dict() for v in vars_list]
                for p, vars_list in self.pool_records.items()
            },
            "frontierCandidates": self.frontier_candidates,
        }


FRONTIER_CONTEXT_PROFILES: list[tuple[str, dict[str, Any]]] = [
    ("neutral", {}),
    (
        "friendly",
        {
            "relationship": {"approval": 60, "respect": 40, "familiarity": 50},
            "bond": {"kind": "friend", "class": "friend"},
        },
    ),
    (
        "rival",
        {
            "relationship": {"approval": -60, "respect": -40, "familiarity": 40},
        },
    ),
    (
        "family",
        {
            "relationship": {"approval": 90, "respect": 70, "familiarity": 85},
            "bond": {"kind": "sister", "class": "family"},
        },
    ),
]


def synthesize_condition_contexts(
    checks: Sequence[Mapping[str, Any]],
    base_context: Mapping[str, Any] | None = None,
) -> list[dict[str, Any]]:
    """Synthesize candidate contexts from failed checks on response variants."""
    candidates: list[dict[str, Any]] = []
    base = dict(base_context or {})
    current = dict(base)

    for chk in checks:
        if chk.get("matched"):
            continue
        field = chk.get("field")
        expected = chk.get("expected")
        if not field or expected is None:
            continue

        if isinstance(expected, (list, tuple)):
            for val in expected[:2]:
                cand = dict(current)
                cand[field] = val
                candidates.append(cand)
            current[field] = expected[0]
        else:
            current[field] = expected
            candidates.append(dict(current))

    if current != base and current not in candidates:
        candidates.append(current)

    return candidates


def find_frontier_targets(
    active_worker: Any,
    ledger: ObservedVariantLedger,
    *,
    pool_ids: Sequence[str] | None = None,
    limit: int = 16,
) -> list[dict[str, Any]]:
    """Discover candidate contexts that reach unobserved variants in registered pools."""
    if pool_ids is None:
        pools, _, _ = ReachabilityAnalyzer().enumerate_all_response_pools(active_worker)
        pool_ids = [p["id"] for p in pools if isinstance(p, dict) and p.get("id")]

    reached_targets: list[dict[str, Any]] = []

    for pool_id in pool_ids:
        if len(reached_targets) >= limit:
            break
        try:
            detail = active_worker.response_pool_detail(pool_id)
        except Exception:
            continue

        variants = detail.get("variants", [])
        unobserved = [v for v in variants if not ledger.is_observed(v.get("id", ""))]
        if not unobserved:
            continue

        test_contexts: list[dict[str, Any]] = [ctx for _, ctx in FRONTIER_CONTEXT_PROFILES]

        try:
            neutral_exp = active_worker.explain_response_selection(pool_id, {}, "")
            for c in neutral_exp.get("candidates", []):
                checks = c.get("checks", [])
                for synth_ctx in synthesize_condition_contexts(checks):
                    if synth_ctx not in test_contexts:
                        test_contexts.append(synth_ctx)
        except Exception:
            pass

        for ctx in test_contexts:
            if len(reached_targets) >= limit:
                break
            try:
                exp = active_worker.explain_response_selection(pool_id, ctx, "")
                sel_id = exp.get("selectedID")
                if sel_id and not ledger.is_observed(sel_id):
                    reached_targets.append({
                        "poolID": pool_id,
                        "variantID": sel_id,
                        "context": ctx,
                        "explanation": exp,
                    })
                    break
            except Exception:
                pass

    return reached_targets


def enumerate_all_response_pools(
    active_worker: Any, limit: int = 64
) -> list[dict[str, Any]]:
    """Paginate all response pools until hasMore is False and return list of pools."""
    analyzer = ReachabilityAnalyzer()
    pools, _, _ = analyzer.enumerate_all_response_pools(active_worker, limit=limit)
    return pools


class ReachabilityAnalyzer:
    """Analyzes response variant reachability using production worker evidence."""

    def __init__(self, worker: Any | None = None) -> None:
        self.worker = worker

    def enumerate_all_response_pools(
        self, active_worker: Any, limit: int = 64
    ) -> tuple[list[dict[str, Any]], int, bool]:
        """Paginate all response pools until hasMore is False."""
        all_pools: list[dict[str, Any]] = []
        offset = 0
        prod_total = 0

        while True:
            res = active_worker.response_pool_list(offset=offset, limit=limit)
            pools = res.get("pools", [])
            if not pools:
                break
            all_pools.extend(pools)
            prod_total = int(res.get("total", len(all_pools)))
            if not res.get("hasMore"):
                break
            offset += len(pools)

        is_complete = len(all_pools) == prod_total or prod_total == 0
        return all_pools, prod_total, is_complete

    def analyze_reachability(
        self,
        evidence_rows: Sequence[Mapping[str, Any]],
        *,
        worker: Any | None = None,
        sweep_id: str = "reachability_analysis",
        target_pools: Sequence[str] | None = None,
        lineage_cache: Mapping[str, str] | None = None,
    ) -> ReachabilityReport:
        """Analyze reachability of registered response variants against executed evidence rows."""
        active_worker = worker or self.worker
        if active_worker is None:
            raise ValueError("A LuaSemanticWorker is required to discover registered pools and explain selection")

        # Discover registered pools with pagination
        if target_pools:
            pool_ids = list(target_pools)
            prod_total = len(pool_ids)
            enumerated_total = len(pool_ids)
            pag_complete = True
        else:
            discovered_pools, prod_total, pag_complete = self.enumerate_all_response_pools(active_worker)
            enumerated_total = len(discovered_pools)
            pool_ids = [
                p["id"]
                for p in discovered_pools
                if isinstance(p, dict) and p.get("id")
            ]

        # Build observed variant ledger from executed evidence rows
        ledger = ObservedVariantLedger()
        ledger.record_rows(evidence_rows)

        # Map executed evidence rows by selected variant and template
        selected_variant_counts: dict[str, int] = {}
        selected_variant_cases: dict[str, list[str]] = {}
        selected_variant_suspicious: dict[str, bool] = {}

        for row in evidence_rows:
            case_id = row.get("identity", {}).get("caseID") or "unknown"
            sel_provenance = row.get("selectionProvenance", {})
            sem_path = row.get("semanticPath", {})
            out = row.get("output", {})
            quality = row.get("quality", {})
            flags = quality.get("flags", [])

            is_suspicious = any(
                f.get("name") in (
                    "UNSUPPORTED_FAMILY_REFERENCE",
                    "RELATIONSHIP_TERM_WITHOUT_BOND",
                    "PERSPECTIVE_SUSPECT",
                    "EXECUTION_ERROR",
                    "INVALID_SURFACE",
                )
                for f in flags
            )

            # Check selectedVariantID or semanticVariantID
            var_id = (
                sel_provenance.get("selectedVariantID")
                or sem_path.get("semanticVariantID")
            )
            if var_id:
                selected_variant_counts[var_id] = selected_variant_counts.get(var_id, 0) + 1
                selected_variant_cases.setdefault(var_id, []).append(case_id)
                if is_suspicious:
                    selected_variant_suspicious[var_id] = True

        total_variants_count = 0
        pool_records: dict[str, list[VariantReachabilityRecord]] = {}
        status_counts: dict[str, int] = {
            VariantReachabilityState.UNTESTED: 0,
            VariantReachabilityState.TESTED_INELIGIBLE: 0,
            VariantReachabilityState.ELIGIBLE_NOT_SELECTED: 0,
            VariantReachabilityState.SELECTED: 0,
            VariantReachabilityState.SELECTED_UNDER_SUSPICIOUS_CONTEXT: 0,
        }
        frontier_candidates: list[dict[str, Any]] = []

        # Analyze each pool
        for pool_id in pool_ids:
            try:
                detail = active_worker.response_pool_detail(pool_id)
            except Exception:
                continue

            variants = detail.get("variants", [])
            total_variants_count += len(variants)
            records: list[VariantReachabilityRecord] = []

            # Check candidate explanations across all declared frontier profiles
            cand_explanations: list[dict[str, Any]] = []
            cand_by_id: dict[str, list[dict[str, Any]]] = {}
            tested_contexts: list[dict[str, Any]] = []

            for profile_name, ctx in FRONTIER_CONTEXT_PROFILES:
                try:
                    exp = active_worker.explain_response_selection(pool_id, ctx, "")
                    if exp and exp.get("candidates"):
                        cand_explanations.append(exp)
                        tested_contexts.append(ctx)
                except Exception:
                    pass

            # Gather candidate explanations by variant ID
            for exp in cand_explanations:
                for c in exp.get("candidates", []):
                    if isinstance(c, dict) and c.get("id"):
                        cand_by_id.setdefault(c["id"], []).append(c)

            # For unobserved variants that are not eligible under standard profiles, synthesize condition contexts
            unobserved_variants = [
                v for v in variants
                if v.get("id") and not ledger.is_observed(v.get("id"))
            ]
            for v in unobserved_variants:
                var_id = v.get("id")
                cands = cand_by_id.get(var_id, [])
                is_already_eligible = any(c.get("eligible") for c in cands)
                if not is_already_eligible and cands:
                    synth_contexts = []
                    for c in cands:
                        for sc in synthesize_condition_contexts(c.get("checks", [])):
                            if sc not in tested_contexts:
                                synth_contexts.append(sc)
                    for s_ctx in synth_contexts[:4]:  # Bounded search budget
                        tested_contexts.append(s_ctx)
                        try:
                            exp = active_worker.explain_response_selection(pool_id, s_ctx, "")
                            if exp and exp.get("candidates"):
                                cand_explanations.append(exp)
                                for c in exp.get("candidates", []):
                                    if isinstance(c, dict) and c.get("id"):
                                        cand_by_id.setdefault(c["id"], []).append(c)
                        except Exception:
                            pass

            for v in variants:
                var_id = v.get("id")
                if not var_id:
                    continue

                source_owner = "UNKNOWN"
                if lineage_cache and var_id in lineage_cache:
                    source_owner = lineage_cache[var_id]
                elif v.get("contentOwner"):
                    source_owner = str(v.get("contentOwner"))
                elif v.get("sourcePath") and v.get("sourcePath") != "UNKNOWN":
                    src_p = v.get("sourcePath")
                    if ".dataset." in var_id:
                        parts = var_id.split(".dataset.")[0].split(".")
                        topic = parts[-1] if parts else "dialogue"
                        source_owner = f"dialogue_dataset.{topic}"
                    else:
                        source_owner = Path(src_p).name

                sel_count = selected_variant_counts.get(var_id, 0)
                cases = selected_variant_cases.get(var_id, [])

                if sel_count > 0:
                    if selected_variant_suspicious.get(var_id):
                        status = VariantReachabilityState.SELECTED_UNDER_SUSPICIOUS_CONTEXT
                    else:
                        status = VariantReachabilityState.SELECTED
                    rec = VariantReachabilityRecord(
                        pool_id=pool_id,
                        variant_id=var_id,
                        status=status,
                        tested_contexts_count=sel_count,
                        eligible_contexts_count=sel_count,
                        selected_contexts_count=sel_count,
                        selected_case_ids=cases[:10],
                        canonical_source_owner=source_owner,
                        global_unreachable_claim=False,
                    )
                else:
                    cand_list = cand_by_id.get(var_id, [])
                    selected_in_frontier = any(
                        exp.get("selectedID") == var_id for exp in cand_explanations
                    )
                    eligible_cand = next((c for c in cand_list if c.get("eligible")), None)

                    if selected_in_frontier:
                        status = VariantReachabilityState.SELECTED
                        status_counts[status] += 1
                        rec = VariantReachabilityRecord(
                            pool_id=pool_id,
                            variant_id=var_id,
                            status=status,
                            tested_contexts_count=len(cand_list),
                            eligible_contexts_count=1,
                            selected_contexts_count=1,
                            canonical_source_owner=source_owner,
                            global_unreachable_claim=False,
                        )
                        frontier_candidates.append({
                            "poolID": pool_id,
                            "variantID": var_id,
                            "status": status,
                            "reason": "selected_in_frontier_probe",
                        })
                    elif eligible_cand:
                        status = VariantReachabilityState.ELIGIBLE_NOT_SELECTED
                        reason = eligible_cand.get("reason", "lower_score")
                        status_counts[status] += 1
                        rec = VariantReachabilityRecord(
                            pool_id=pool_id,
                            variant_id=var_id,
                            status=status,
                            tested_contexts_count=len(cand_list),
                            eligible_contexts_count=1,
                            selected_contexts_count=0,
                            rejection_reasons=[reason],
                            canonical_source_owner=source_owner,
                            global_unreachable_claim=False,
                        )
                        frontier_candidates.append({
                            "poolID": pool_id,
                            "variantID": var_id,
                            "status": status,
                            "reason": reason,
                        })
                    elif cand_list:
                        status = VariantReachabilityState.TESTED_INELIGIBLE
                        status_counts[status] += 1
                        reasons = [c.get("reason", "ineligible") for c in cand_list]
                        failed_checks = []
                        for c in cand_list:
                            for chk in c.get("checks", []):
                                if not chk.get("matched"):
                                    failed_checks.append(chk.get("field", "unknown"))
                        rec = VariantReachabilityRecord(
                            pool_id=pool_id,
                            variant_id=var_id,
                            status=status,
                            tested_contexts_count=len(cand_list),
                            eligible_contexts_count=0,
                            selected_contexts_count=0,
                            rejection_reasons=reasons[:3],
                            failed_checks=list(set(failed_checks))[:5],
                            canonical_source_owner=source_owner,
                            global_unreachable_claim=False,
                        )
                        frontier_candidates.append({
                            "poolID": pool_id,
                            "variantID": var_id,
                            "status": status,
                            "failedChecks": failed_checks,
                        })
                    else:
                        status = VariantReachabilityState.UNTESTED
                        status_counts[status] += 1
                        rec = VariantReachabilityRecord(
                            pool_id=pool_id,
                            variant_id=var_id,
                            status=status,
                            canonical_source_owner=source_owner,
                            global_unreachable_claim=False,
                        )

                if rec.status in (
                    VariantReachabilityState.SELECTED,
                    VariantReachabilityState.SELECTED_UNDER_SUSPICIOUS_CONTEXT,
                ) and sel_count > 0:
                    status_counts[rec.status] += 1

                records.append(rec)

            pool_records[pool_id] = records

        return ReachabilityReport(
            sweep_id=sweep_id,
            total_pools=len(pool_records),
            total_variants=total_variants_count,
            production_total_pools=prod_total,
            enumerated_total_pools=enumerated_total,
            pagination_complete=pag_complete,
            status_counts=status_counts,
            pool_records=pool_records,
            frontier_candidates=frontier_candidates,
            ledger=ledger.to_dict(),
        )
