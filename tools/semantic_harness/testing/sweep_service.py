"""Unified machine-readable service interface for sweeps.

Consumed identically by headless CLI and Simulation UI.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Callable, Mapping, Sequence

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker
from .sweep_batch import SweepBatch, SweepBatchExecutor, SweepManifest
from .sweep_cluster import ClusterAggregator, DialogueClusterReport
from .sweep_dimensions import SweepDimensionInventory, discover_interaction_surfaces, extract_dimension_inventory
from .sweep_planner import CoveragePlan, CoveragePlanner, MAX_BATCH_SIZE
from .sweep_quality import QualityAnalyzer
from .sweep_reachability import ReachabilityAnalyzer, ReachabilityReport
from .sweep_review import build_llm_review_bundle, create_replay_plan


class DialogueQualitySweepService:
    """Orchestrates dialogue quality sweep planning, execution, analysis, and replay."""

    def __init__(
        self,
        *,
        base_dir: Path | str = "tools/semantic_harness/reports/sweeps",
        worker_factory: Callable[..., Any] = LuaSemanticWorker,
    ) -> None:
        self.base_dir = Path(base_dir)
        self.worker_factory = worker_factory
        self.quality_analyzer = QualityAnalyzer()
        self.cluster_aggregator = ClusterAggregator(self.quality_analyzer)
        self.reachability_analyzer = ReachabilityAnalyzer()

    def get_dimension_inventory(
        self, worker: Any | None = None
    ) -> SweepDimensionInventory:
        """Extract dimension inventory using provided or temporary worker."""
        if worker is not None:
            return extract_dimension_inventory(worker)
        with self.worker_factory(DEFAULT_SCENARIO) as temp_worker:
            return extract_dimension_inventory(temp_worker)

    def plan_sweep(
        self,
        *,
        strategy: str = "smoke",
        sweep_id: str = "dialogue_sweep_v1",
        surfaces: Sequence[str] | None = None,
        dimensions: Sequence[str] | None = None,
        languages: Sequence[str] = ("EN", "TL"),
        max_cases: int = 512,
        worker: Any | None = None,
        inventory: SweepDimensionInventory | None = None,
    ) -> CoveragePlan:
        """Generate a deterministic coverage plan."""
        inv = inventory or self.get_dimension_inventory(worker)

        # Default to the current production interaction inventory rather than a
        # historical hard-coded surface list.  Expected fallback probes stay
        # available to explicit callers but are excluded from the user-facing
        # sentence review by default.
        resolved_surfaces = list(surfaces) if surfaces else None
        if resolved_surfaces is None:
            if worker is not None:
                discovered = discover_interaction_surfaces(worker)
            else:
                with self.worker_factory(DEFAULT_SCENARIO) as temp_worker:
                    discovered = discover_interaction_surfaces(temp_worker)
            resolved_surfaces = [
                item.surface_id
                for item in discovered
                if item.executable and not item.expect_fallback
            ]

        planner = CoveragePlanner(inv, sweep_id=sweep_id)
        surfaces = resolved_surfaces

        strat_lower = strategy.lower()
        if strat_lower == "smoke":
            kwargs = {}
            if surfaces:
                kwargs["surfaces"] = surfaces
            if languages:
                kwargs["languages"] = languages
            return planner.plan_smoke(**kwargs)
        if strat_lower == "boundary":
            kwargs = {"max_cases": max_cases}
            if surfaces:
                kwargs["surfaces"] = surfaces
            if dimensions:
                kwargs["dimensions"] = dimensions
            if languages:
                kwargs["languages"] = languages
            return planner.plan_boundary(**kwargs)
        if strat_lower == "pairwise":
            kwargs = {"max_cases": max_cases}
            if surfaces:
                kwargs["surfaces"] = surfaces
            if dimensions:
                kwargs["dimensions"] = dimensions
            if languages:
                kwargs["languages"] = languages
            return planner.plan_pairwise(**kwargs)
        if strat_lower == "persona":
            kwargs = {"max_cases": max_cases}
            if surfaces:
                kwargs["surfaces"] = surfaces
            if languages:
                kwargs["languages"] = languages
            return planner.plan_persona(**kwargs)
        if strat_lower in ("full", "review"):
            kwargs = {"max_cases": max_cases}
            if surfaces:
                kwargs["surfaces"] = surfaces
            if languages:
                kwargs["languages"] = languages
            return planner.plan_full(**kwargs)

        raise ValueError(f"Unknown coverage strategy: '{strategy}'")

    def run_sweep(
        self,
        plan: CoveragePlan,
        *,
        inventory: SweepDimensionInventory | None = None,
        batch_size: int = MAX_BATCH_SIZE,
        is_cancelled: Callable[[], bool] | None = None,
        progress_callback: Callable[[SweepBatch, SweepManifest], None] | None = None,
    ) -> SweepManifest:
        """Run all batches in a sweep plan to completion or cancellation."""
        inv = inventory or self.get_dimension_inventory()
        artifact_dir = self.base_dir / plan.sweep_id
        executor = SweepBatchExecutor(
            plan,
            inv,
            artifact_dir=artifact_dir,
            worker_factory=self.worker_factory,
            batch_size=batch_size,
        )
        return executor.execute_all(
            is_cancelled=is_cancelled,
            progress_callback=progress_callback,
        )

    def load_manifest(self, sweep_id: str) -> SweepManifest:
        """Load manifest for an existing sweep."""
        manifest_path = self.base_dir / sweep_id / "manifest.json"
        return SweepManifest.load(manifest_path)

    def load_evidence_rows(self, sweep_id: str) -> list[dict[str, Any]]:
        """Load all evidence rows from a sweep's evidence.jsonl."""
        evidence_path = self.base_dir / sweep_id / "evidence.jsonl"
        if not evidence_path.exists():
            return []
        rows = []
        with open(evidence_path, "r", encoding="utf-8") as f:
            for line in f:
                stripped = line.strip()
                if stripped:
                    rows.append(json.loads(stripped))
        return rows

    def generate_cluster_report(self, sweep_id: str) -> DialogueClusterReport:
        """Load evidence rows, evaluate quality flags, and produce a cluster report."""
        rows = self.load_evidence_rows(sweep_id)
        return self.cluster_aggregator.aggregate_rows(rows, sweep_id=sweep_id)

    def generate_review_bundle(
        self, sweep_id: str, *, max_clusters: int = 10
    ) -> dict[str, Any]:
        """Generate token-efficient LLM review bundle for a sweep."""
        rows = self.load_evidence_rows(sweep_id)
        report = self.cluster_aggregator.aggregate_rows(rows, sweep_id=sweep_id)
        return build_llm_review_bundle(report, rows, max_clusters=max_clusters)

    def generate_reachability_report(
        self, sweep_id: str, *, worker: Any | None = None
    ) -> ReachabilityReport:
        """Analyze variant reachability across registered pools."""
        rows = self.load_evidence_rows(sweep_id)
        if worker is not None:
            return self.reachability_analyzer.analyze_reachability(
                rows, worker=worker, sweep_id=sweep_id
            )
        with self.worker_factory(DEFAULT_SCENARIO) as temp_worker:
            return self.reachability_analyzer.analyze_reachability(
                rows, worker=temp_worker, sweep_id=sweep_id
            )

    def plan_replay(
        self,
        original_plan: CoveragePlan,
        affected_case_ids: Sequence[str],
        *,
        replay_sweep_id: str | None = None,
    ) -> CoveragePlan:
        """Construct a targeted replay plan for affected case IDs."""
        return create_replay_plan(
            original_plan, affected_case_ids, replay_sweep_id=replay_sweep_id
        )

    def resolve_trace(
        self,
        trace_handle: dict[str, Any],
        *,
        worker: Any | None = None,
        turn_input_spec: dict[str, Any] | None = None,
        language: str = "EN",
        parameters: Mapping[str, Any] | None = None,
        inventory: SweepDimensionInventory | None = None,
    ) -> dict[str, Any]:
        """Resolve a lazy trace handle into the matching full Inspector context."""
        from .sweep_evidence import resolve_trace_handle

        if worker is not None:
            return resolve_trace_handle(
                trace_handle,
                worker=worker,
                input_spec=turn_input_spec,
                language=language,
                parameters=parameters,
                inventory=inventory,
            )

        inv = inventory or self.get_dimension_inventory()
        scenario = inv.project_to_scenario(parameters or {}, DEFAULT_SCENARIO)
        with self.worker_factory(scenario) as temp_worker:
            return resolve_trace_handle(
                trace_handle,
                worker=temp_worker,
                input_spec=turn_input_spec,
                language=language,
                parameters=parameters,
                inventory=inv,
            )

    def expand_frontier_sentences(
        self,
        sweep_id: str,
        *,
        max_new_cases: int = 16,
        worker: Any | None = None,
        inventory: SweepDimensionInventory | None = None,
    ) -> list[dict[str, Any]]:
        """Discover unobserved variants, execute targeted frontier cases, and append evidence rows."""
        from .sweep_evidence import extract_evidence_rows_from_turn
        from .sweep_reachability import ObservedVariantLedger, find_frontier_targets

        manifest = self.load_manifest(sweep_id)
        evidence_path = self.base_dir / sweep_id / "evidence.jsonl"
        manifest_path = self.base_dir / sweep_id / "manifest.json"
        existing_rows = self.load_evidence_rows(sweep_id)

        ledger = ObservedVariantLedger()
        ledger.record_rows(existing_rows)

        inv = inventory or self.get_dimension_inventory(worker)

        def run_frontier_with_worker(active_worker: Any) -> list[dict[str, Any]]:
            pools_to_search = [
                "semantic.flow.greeting.opening",
                "semantic.flow.farewell",
                "semantic.question.identity",
                "semantic.question.wellbeing",
                "semantic.question.whats_up",
            ]
            targets = find_frontier_targets(
                active_worker,
                ledger,
                pool_ids=pools_to_search,
                limit=max_new_cases,
            )
            if not targets:
                return []

            new_rows: list[dict[str, Any]] = []

            for i, target in enumerate(targets):
                pool_id = target["poolID"]
                ctx = target["context"]
                surface = "utterance:hello"
                turn_text = "hello"

                if "farewell" in pool_id:
                    surface = "utterance:goodbye"
                    turn_text = "goodbye"
                elif "identity" in pool_id:
                    surface = "utterance:who are you?"
                    turn_text = "who are you?"
                elif "wellbeing" in pool_id:
                    surface = "utterance:how are you?"
                    turn_text = "how are you?"
                elif "whats_up" in pool_id:
                    surface = "utterance:what's up?"
                    turn_text = "what's up?"

                params: dict[str, Any] = {}
                if "socialStyle" in ctx:
                    params["persona.socialStyle"] = ctx["socialStyle"]
                if "relationship" in ctx:
                    rel = ctx["relationship"]
                    if "approval" in rel:
                        params["relationship.approval"] = float(rel["approval"])
                    if "respect" in rel:
                        params["relationship.respect"] = float(rel["respect"])
                    if "familiarity" in rel:
                        params["relationship.familiarity"] = float(rel["familiarity"])
                if "bond" in ctx:
                    bond = ctx["bond"]
                    if "kind" in bond:
                        params["persona.bondKind"] = str(bond["kind"])
                if "identityTrust" in ctx:
                    params["relationship.identityTrust"] = str(ctx["identityTrust"])

                case_id = f"{sweep_id}:frontier:{pool_id.replace('.', '_')}:{i}"
                case_scenario = inv.project_to_scenario(params, DEFAULT_SCENARIO)

                with self.worker_factory(case_scenario) as case_worker:
                    rec = case_worker.input(turn_text)
                    extracted = extract_evidence_rows_from_turn(
                        rec,
                        turn_index=0,
                        case_id=case_id,
                        sweep_id=sweep_id,
                        strategy="frontier",
                        parameters=params,
                        planned_surface=surface,
                        worker=case_worker,
                    )
                    for r in extracted:
                        new_rows.append(r)
                        ledger.record_row(r)

            if new_rows:
                with open(evidence_path, "a", encoding="utf-8") as f:
                    for r in new_rows:
                        f.write(json.dumps(r) + "\n")

                # Update manifest
                manifest.completed_cases += len(new_rows)
                manifest.total_cases += len(new_rows)
                manifest.save(self.base_dir / sweep_id)

            return new_rows

        if worker is not None:
            return run_frontier_with_worker(worker)
        with self.worker_factory(DEFAULT_SCENARIO) as temp_worker:
            return run_frontier_with_worker(temp_worker)
