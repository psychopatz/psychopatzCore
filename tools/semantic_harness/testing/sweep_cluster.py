"""Canonical-source clustering and defect aggregation for dialogue quality sweeps.

Groups flagged evidence rows by root canonical cause (source owner + phrase/variant
+ quality flag) rather than superficial text alone, producing compact, reviewable
clusters with context ranges and targeted affected case IDs for replay.
"""

from __future__ import annotations

from dataclasses import asdict, dataclass, field
import hashlib
from typing import Any, Mapping, Sequence

from .sweep_quality import QualityAnalyzer

CLUSTER_SCHEMA_V1 = "pnc.semantic-dialogue-quality-clusters.v1"
ALLOWED_CLUSTER_SCHEMAS = frozenset({CLUSTER_SCHEMA_V1})


@dataclass
class DialogueQualityCluster:
    """A cluster of dialogue defects grouped by canonical cause and flag."""

    cluster_id: str
    primary_flag: str
    severity: str
    confidence: str
    count: int
    canonical_source_owner: str
    pool_id: str | None = None
    phrase_id: str | None = None
    semantic_variant_id: str | None = None
    affected_case_ids: list[str] = field(default_factory=list)
    affected_context_ranges: dict[str, list[Any]] = field(default_factory=dict)
    representative_examples: list[dict[str, Any]] = field(default_factory=list)
    suggested_remedy: str = ""

    def to_dict(self) -> dict[str, Any]:
        return {
            "clusterID": self.cluster_id,
            "primaryFlag": self.primary_flag,
            "severity": self.severity,
            "confidence": self.confidence,
            "count": self.count,
            "canonicalSourceOwner": self.canonical_source_owner,
            "poolID": self.pool_id,
            "phraseID": self.phrase_id,
            "semanticVariantID": self.semantic_variant_id,
            "affectedCaseIDs": self.affected_case_ids,
            "affectedContextRanges": self.affected_context_ranges,
            "representativeExamples": self.representative_examples,
            "suggestedRemedy": self.suggested_remedy,
        }


@dataclass
class DialogueClusterReport:
    """Report summarizing clusters of dialogue quality defects across a sweep."""

    sweep_id: str
    total_rows: int
    flagged_rows: int
    clean_rows: int
    total_clusters: int
    clusters: list[DialogueQualityCluster]
    schema: str = CLUSTER_SCHEMA_V1
    schema_version: int = 1

    def to_dict(self) -> dict[str, Any]:
        return {
            "schema": self.schema,
            "schemaVersion": self.schema_version,
            "sweepID": self.sweep_id,
            "totalRows": self.total_rows,
            "flaggedRows": self.flagged_rows,
            "cleanRows": self.clean_rows,
            "totalClusters": self.total_clusters,
            "clusters": [c.to_dict() for c in self.clusters],
        }

    def filter_by(
        self,
        *,
        severity: str | None = None,
        flag: str | None = None,
        pool: str | None = None,
        source: str | None = None,
    ) -> list[DialogueQualityCluster]:
        """Filter clusters by severity, primary flag, pool, or canonical source."""
        results = []
        for c in self.clusters:
            if severity and c.severity != severity:
                continue
            if flag and c.primary_flag != flag:
                continue
            if pool and c.pool_id != pool:
                continue
            if source and c.canonical_source_owner != source:
                continue
            results.append(c)
        return results

    def get_affected_case_ids(
        self,
        cluster_ids: Sequence[str] | None = None,
    ) -> list[str]:
        """Return deduplicated list of affected case IDs for selected clusters."""
        target_clusters = (
            [c for c in self.clusters if c.cluster_id in cluster_ids]
            if cluster_ids is not None
            else self.clusters
        )
        seen = set()
        cases = []
        for c in target_clusters:
            for cid in c.affected_case_ids:
                if cid not in seen:
                    seen.add(cid)
                    cases.append(cid)
        return cases


class ClusterAggregator:
    """Aggregates evidence rows into canonical-cause clusters."""

    def __init__(self, analyzer: QualityAnalyzer | None = None) -> None:
        self.analyzer = analyzer or QualityAnalyzer()

    def aggregate_rows(
        self,
        rows: Sequence[dict[str, Any]],
        *,
        sweep_id: str = "dialogue_cluster_analysis",
    ) -> DialogueClusterReport:
        """Analyze and cluster rows by canonical cause and quality signature."""
        total_rows = len(rows)
        flagged_count = 0
        clean_count = 0

        # Group rows by canonical cause key:
        # (primary_flag, canonical_source, pool_id, phrase_id, variant_id)
        grouped_rows: dict[tuple[str, str, str, str, str], list[dict[str, Any]]] = {}

        # Run analyzer across all rows (Stage 1 per-row + Stage 2 cross-row checks)
        self.analyzer.analyze_run(rows)

        for row in rows:
            flags = row.get("quality", {}).get("flags", [])

            if not flags:
                clean_count += 1
                continue

            flagged_count += 1
            sem_path = row.get("semanticPath", {})
            sel_prov = row.get("selectionProvenance", {})

            source_owner = str(sel_prov.get("canonicalSourceOwner") or "UNKNOWN")
            pool_id = str(sem_path.get("semanticTemplateID") or "")
            phrase_id = str(sem_path.get("phraseID") or "")
            var_id = str(sem_path.get("semanticVariantID") or sel_prov.get("selectedVariantID") or "")

            for f in flags:
                flag_name = f.get("name")
                key = (flag_name, source_owner, pool_id, phrase_id, var_id)
                grouped_rows.setdefault(key, []).append(row)

        clusters: list[DialogueQualityCluster] = []

        for (flag_name, source_owner, pool_id, phrase_id, var_id), cluster_rows in grouped_rows.items():
            first_row = cluster_rows[0]
            first_flag = next(
                (f for f in first_row.get("quality", {}).get("flags", []) if f.get("name") == flag_name),
                {},
            )
            severity = first_flag.get("severity", "MEDIUM")
            confidence = first_flag.get("confidence", "REVIEW")

            # Collect affected cases and context ranges
            case_ids = list(dict.fromkeys(
                r.get("identity", {}).get("caseID")
                for r in cluster_rows
                if r.get("identity", {}).get("caseID")
            ))

            bonds = list(dict.fromkeys(
                str(r.get("trigger", {}).get("relationshipSummary", {}).get("bondKind"))
                for r in cluster_rows
            ))
            languages = list(dict.fromkeys(
                str(r.get("identity", {}).get("language"))
                for r in cluster_rows
            ))

            context_ranges = {
                "bonds": bonds,
                "languages": languages,
            }

            # Representative examples (up to 5)
            examples = []
            for r in cluster_rows[:5]:
                examples.append({
                    "caseID": r.get("identity", {}).get("caseID"),
                    "finalText": r.get("output", {}).get("finalText"),
                    "parameters": r.get("trigger", {}).get("parameters"),
                    "bondKind": r.get("trigger", {}).get("relationshipSummary", {}).get("bondKind"),
                    "phraseID": r.get("semanticPath", {}).get("phraseID"),
                    "flagDetail": next(
                        (f.get("detail") for f in r.get("quality", {}).get("flags", []) if f.get("name") == flag_name),
                        "",
                    ),
                })

            # Suggested remedy
            remedy = self._suggest_remedy(flag_name, source_owner, pool_id, phrase_id)

            cluster_slug = f"{flag_name}:{source_owner}:{pool_id}:{phrase_id}:{var_id}".lower()
            cluster_hash = hashlib.sha256(cluster_slug.encode("utf-8")).hexdigest()[:8]
            cluster_id = f"cluster:{flag_name.lower()}:{cluster_hash}"

            clusters.append(
                DialogueQualityCluster(
                    cluster_id=cluster_id,
                    primary_flag=flag_name,
                    severity=severity,
                    confidence=confidence,
                    count=len(cluster_rows),
                    canonical_source_owner=source_owner,
                    pool_id=pool_id or None,
                    phrase_id=phrase_id or None,
                    semantic_variant_id=var_id or None,
                    affected_case_ids=case_ids,
                    affected_context_ranges=context_ranges,
                    representative_examples=examples,
                    suggested_remedy=remedy,
                )
            )

        # Sort clusters by severity (CRITICAL first, then HIGH, etc.) then count descending
        severity_order = {"CRITICAL": 0, "HIGH": 1, "MEDIUM": 2, "LOW": 3, "INFO": 4}
        clusters.sort(key=lambda c: (severity_order.get(c.severity, 99), -c.count))

        return DialogueClusterReport(
            sweep_id=sweep_id,
            total_rows=total_rows,
            flagged_rows=flagged_count,
            clean_rows=clean_count,
            total_clusters=len(clusters),
            clusters=clusters,
        )

    def _suggest_remedy(
        self, flag_name: str, source: str, pool: str, phrase: str
    ) -> str:
        if flag_name == "UNSUPPORTED_FAMILY_REFERENCE":
            return (
                "Ensure family address terms are gated behind a valid family bond condition "
                "or replace with neutral/companion phrasing."
            )
        if flag_name == "PLACEHOLDER_LEAK":
            return "Provide missing translation argument or format parameter in speech realization."
        if flag_name == "TRANSLATION_KEY_LEAK":
            return "Add missing localization key entry to Translate/<LANG>/*.json."
        if flag_name == "ONE_WORD_RESPONSE":
            return "Expand one-word fragment into a complete natural survival response."
        if flag_name == "RELATIONSHIP_TERM_WITHOUT_BOND":
            return "Gate romantic terms behind bondKind == 'lover'."
        if flag_name == "IDENTITY_TERM_WITHOUT_KNOWLEDGE":
            return "Gate player name usage behind familiarity >= 5 and identityTrust >= 50."
        return "Review dialogue phrasing in canonical dataset."
