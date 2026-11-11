"""Compact LLM review bundles and affected-case replay planning.

Produces token-efficient developer/agent review bundles from clustered defect
evidence (representative bad outputs, parameter deltas, semantic paths, contrasting
good outputs, canonical source owners) and extracts targeted cases for replay.
"""

from __future__ import annotations

from typing import Any, Mapping, Sequence

from .sweep_cluster import DialogueClusterReport, DialogueQualityCluster
from .sweep_planner import CoveragePlan, PlannedCase

REVIEW_BUNDLE_SCHEMA_V1 = "pnc.semantic-dialogue-quality-review-bundle.v1"
ALLOWED_REVIEW_BUNDLE_SCHEMAS = frozenset({REVIEW_BUNDLE_SCHEMA_V1})


def build_llm_review_bundle(
    report: DialogueClusterReport,
    evidence_rows: Sequence[Mapping[str, Any]] | None = None,
    *,
    max_clusters: int = 10,
    max_examples_per_cluster: int = 5,
) -> dict[str, Any]:
    """Generate a compact, token-efficient review bundle suitable for human/LLM review."""
    # Find clean rows for contrasting examples if provided
    clean_examples_by_pool: dict[str, list[dict[str, Any]]] = {}
    if evidence_rows:
        for r in evidence_rows:
            flags = r.get("quality", {}).get("flags", [])
            if not flags:
                pool_id = str(r.get("semanticPath", {}).get("semanticTemplateID") or "")
                if pool_id and len(clean_examples_by_pool.get(pool_id, [])) < 2:
                    clean_examples_by_pool.setdefault(pool_id, []).append({
                        "caseID": r.get("identity", {}).get("caseID"),
                        "finalText": r.get("output", {}).get("finalText"),
                        "parameters": r.get("trigger", {}).get("parameters"),
                        "bondKind": r.get("trigger", {}).get("relationshipSummary", {}).get("bondKind"),
                    })

    target_clusters = report.clusters[:max_clusters]
    bundle_clusters = []

    for c in target_clusters:
        # Contrasting good examples from the same pool if available
        contrasting = clean_examples_by_pool.get(c.pool_id or "", [])

        bundle_clusters.append({
            "clusterID": c.cluster_id,
            "primaryFlag": c.primary_flag,
            "severity": c.severity,
            "confidence": c.confidence,
            "count": c.count,
            "canonicalSourceOwner": c.canonical_source_owner,
            "poolID": c.pool_id,
            "phraseID": c.phrase_id,
            "semanticVariantID": c.semantic_variant_id,
            "contextRanges": c.affected_context_ranges,
            "representativeBadOutputs": c.representative_examples[:max_examples_per_cluster],
            "contrastingGoodOutputs": contrasting,
            "affectedCaseIDs": c.affected_case_ids[:32],
            "suggestedRemedy": c.suggested_remedy,
        })

    return {
        "schema": REVIEW_BUNDLE_SCHEMA_V1,
        "schemaVersion": 1,
        "sweepID": report.sweep_id,
        "totalFlaggedRows": report.flagged_rows,
        "totalClusters": report.total_clusters,
        "reviewSummary": (
            f"Reviewing top {len(bundle_clusters)} of {report.total_clusters} defect clusters. "
            "Examine canonical causes and phrase/dataset ownership before approving text-only remedies."
        ),
        "clusters": bundle_clusters,
    }


def create_replay_plan(
    original_plan: CoveragePlan,
    affected_case_ids: Sequence[str],
    *,
    replay_sweep_id: str | None = None,
) -> CoveragePlan:
    """Construct a targeted CoveragePlan containing only affected cases for replay."""
    target_ids = set(affected_case_ids)
    replayed_cases: list[PlannedCase] = []

    sweep_id = replay_sweep_id or f"{original_plan.sweep_id}_replay"

    for c in original_plan.cases:
        if c.case_id in target_ids:
            replayed_cases.append(
                PlannedCase(
                    case_id=f"{sweep_id}:{c.case_id.split(':', 1)[-1]}",
                    sweep_id=sweep_id,
                    strategy="replay",
                    surface=c.surface,
                    parameters=c.parameters,
                    language=c.language,
                    turns=c.turns,
                    metadata={"originalCaseID": c.case_id},
                )
            )

    batches = (len(replayed_cases) + original_plan.batch_size - 1) // original_plan.batch_size if replayed_cases else 0

    return CoveragePlan(
        sweep_id=sweep_id,
        strategy="replay",
        plan_digest=f"replay_of_{original_plan.plan_digest[:8]}",
        catalog_fingerprint=original_plan.catalog_fingerprint,
        cases=replayed_cases,
        total_cases=len(replayed_cases),
        estimated_batches=batches,
        batch_size=original_plan.batch_size,
    )
