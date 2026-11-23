"""Focused H10R7 regressions for semantic truth and matrix-aware quality checks."""

from __future__ import annotations

import unittest
from unittest.mock import patch

from tools.semantic_harness.testing.sweep_evidence import (
    extract_evidence_rows_from_turn,
    _normalize_authoritative_truth,
    _normalize_utterance_evidence,
)
from tools.semantic_harness.testing.sweep_quality import QualityAnalyzer


def _row(case_id: str, *, params: dict | None = None, claims: list[str] | None = None,
         truth: dict | None = None, relations: list[dict] | None = None,
         clauses: list[dict] | None = None, text: str = "The wound is steady.",
         variant: str = "variant-a") -> dict:
    clauses = clauses if clauses is not None else ([{"claims": claims or []}] if claims else [])
    return {
        "identity": {"caseID": case_id, "plannedSurface": "injury.triage", "language": "EN"},
        "trigger": {"parameters": params or {}, "relationshipSummary": {"bondKind": "none"}},
        "semanticPath": {"semanticTemplateID": "injury.triage", "semanticVariantID": variant},
        "selectionProvenance": {"canonicalSourceOwner": "combat.injury"},
        "output": {"finalText": text},
        "context": {
            "utteranceEvidence": {"clauses": clauses, "relations": relations or []},
            "authoritativeTruth": truth or {},
        },
    }


class SweepQualityH10R7Tests(unittest.TestCase):
    def setUp(self) -> None:
        self.analyzer = QualityAnalyzer()

    def test_optional_evidence_normalizers_keep_contract_bounded(self) -> None:
        utterance = _normalize_utterance_evidence({
            "clauses": [{
                "claims": ["treatment.splinted", "x" * 160],
                "modifiers": ["urgent"],
                "diagnostic": "ok",
                "referenceMode": "anaphora",
                "refersTo": "wound:left-leg",
                "constructionID": "clause-1",
            }],
            "relations": [{"relation": "CAUSE", "constructionID": "clause-1"}],
        })
        self.assertEqual(utterance["clauses"][0]["claims"][0], "treatment.splinted")
        self.assertEqual(len(utterance["clauses"][0]["claims"][1]), 128)
        self.assertEqual(utterance["relations"], [{"relation": "CAUSE", "constructionID": "clause-1"}])

        truth = _normalize_authoritative_truth({
            "source": "ProjectHoomans.selectedWound",
            "selectedWound": {"splinted": False, "ordinaryInfection": True, "unboundedExtra": True},
            "inventory": {"bandageAvailable": False, "knownToSpeaker": True, "unboundedExtra": "ignored"},
        })
        self.assertEqual(truth["selectedWound"], {"splinted": False, "ordinaryInfection": True})
        self.assertEqual(truth["inventory"], {"bandageAvailable": False, "knownToSpeaker": True})

    def test_evidence_extraction_preserves_optional_adapter_contract(self) -> None:
        utterance = {"clauses": [{"claims": ["treatment.splinted"]}],
                     "relations": [{"relation": "CAUSE", "constructionID": "c1"}]}
        truth = {"selectedWound": {"splinted": False}, "source": "pnc.selectedWound"}
        record = {
            "messages": [{"speaker": "npc", "payload": {"text": "That wound is open."}}],
            "context": {"utteranceEvidence": utterance, "authoritativeTruth": truth},
        }
        view = {"context": {}, "semantic": {}, "personaChoices": {}, "socialContext": {},
                "execution": {}, "effects": {}, "visibleResponse": {}, "facts": {}}
        with patch("tools.semantic_harness.testing.sweep_evidence.build_conversation_inspector",
                   return_value=view):
            rows = extract_evidence_rows_from_turn(record)
        self.assertEqual(rows[0]["context"]["utteranceEvidence"], utterance)
        self.assertEqual(rows[0]["context"]["authoritativeTruth"], truth)

    def test_truth_guards_cover_wound_function_infection_relation_inventory_and_connector(self) -> None:
        row = _row(
            "case-negative",
            claims=[
                "treatment.splinted", "bandaged", "bandageDirty",
                "function.cannot_run", "locomotionImpaired", "infection.ordinary",
                "infection.knox_confirmed", "infection.fever",
                "relationship.family", "inventory.bandage_available",
            ],
            truth={
                "physiology": {"feverBand": "none"},
                "selectedWound": {"splinted": False, "bandaged": False, "bandageDirty": False,
                                  "locomotionImpaired": False,
                                  "ordinaryInfection": False, "knoxExposure": "possible"},
                "relationship": {"bondKind": "stranger"},
                "inventory": {"bandageAvailable": False, "knownToSpeaker": True},
            },
            relations=[{"relation": "CAUSE", "constructionID": "c1"}],
            clauses=[{
                "claims": ["treatment.splinted", "bandaged", "bandageDirty",
                           "function.cannot_run", "locomotionImpaired", "infection.ordinary",
                           "infection.knox_confirmed", "infection.fever",
                           "relationship.family", "inventory.bandage_available"],
                "constructionID": "c1", "realizedRelation": "CONTRAST",
            }],
        )
        flags = {flag.name for flag in self.analyzer.analyze_row(row)}
        self.assertTrue({
            "TREATMENT_REALIZATION_MISMATCH", "FUNCTION_REALIZATION_MISMATCH",
            "INFECTION_REALIZATION_MISMATCH", "RELATION_REALIZATION_MISMATCH",
            "INVENTORY_REALIZATION_MISMATCH", "CONNECTOR_RELATION_MISMATCH",
        }.issubset(flags))

    def test_supported_claims_and_explicit_references_pass(self) -> None:
        row = _row(
            "case-supported",
            claims=["treatment.splinted", "function.cannot_run", "infection.ordinary",
                    "relationship.family", "inventory.bandage_available"],
            truth={
                "physiology": {"feverBand": "feverish"},
                "selectedWound": {"splinted": True, "bandaged": True, "bandageDirty": True,
                                  "locomotionImpaired": True,
                                  "ordinaryInfection": True, "knoxExposure": "confirmed"},
                "relationship": {"bondKind": "sister", "bondClass": "family"},
                "inventory": {"bandageAvailable": True, "knownToSpeaker": True},
                "referents": {"candidateCount": 1, "resolvedID": "wound:left-leg"},
            },
            relations=[{"relation": "CAUSE", "constructionID": "c1"}],
            clauses=[{
                "claims": ["treatment.splinted", "bandaged", "bandageDirty",
                           "function.cannot_run", "locomotionImpaired", "infection.ordinary",
                           "infection.knox_confirmed", "infection.fever",
                           "relationship.family", "inventory.bandage_available"],
                "referenceMode": "explicit", "refersTo": "wound:left-leg",
                "constructionID": "c1", "realizedRelation": "CAUSE",
            }],
        )
        flags = {flag.name for flag in self.analyzer.analyze_row(row)}
        self.assertFalse(flags.intersection({
            "TREATMENT_REALIZATION_MISMATCH", "FUNCTION_REALIZATION_MISMATCH",
            "INFECTION_REALIZATION_MISMATCH", "RELATION_REALIZATION_MISMATCH",
            "INVENTORY_REALIZATION_MISMATCH", "CONNECTOR_RELATION_MISMATCH",
            "REFERENCE_AMBIGUOUS",
        }))

    def test_reference_guard_flags_only_unresolved_or_ambiguous_plan(self) -> None:
        unresolved = _row("case-unresolved", clauses=[{"referenceMode": "anaphora"}])
        explicit = _row("case-explicit", clauses=[{
            "referenceMode": "explicit_fallback", "diagnostic": "REFERENCE_AMBIGUOUS",
        }])
        ambiguous = _row("case-ambiguous", clauses=[{"referenceMode": "anaphora", "refersTo": "wound"}],
                         truth={"referents": {"candidateCount": 2, "ambiguous": True}})
        for candidate in (unresolved, ambiguous):
            self.assertIn("REFERENCE_AMBIGUOUS", {f.name for f in self.analyzer.analyze_row(candidate)})
        self.assertNotIn("REFERENCE_AMBIGUOUS", {f.name for f in self.analyzer.analyze_row(explicit)})

    def test_matrix_axis_reuse_does_not_look_like_duplicate_authorship(self) -> None:
        rows = [
            _row(f"case-{axis}", params={axis: value})
            for axis, value in (
                ("relationship.approval", 1), ("relationship.respect", 2),
                ("npc.needs.hunger", 3), ("player.needs.hunger", 4),
            )
        ]
        self.analyzer.analyze_run(rows)
        self.assertTrue(all(
            "DUPLICATE_RENDERED_TEXT" not in {flag["name"] for flag in row["quality"]["flags"]}
            for row in rows
        ))

    def test_low_variety_inside_one_matrix_axis_remains_discoverable(self) -> None:
        rows = [
            _row(f"case-{value}", params={"npc.needs.hunger": value}, variant=f"variant-{value}")
            for value in range(4)
        ]
        self.analyzer.analyze_run(rows)
        names = [{flag["name"] for flag in row["quality"]["flags"]} for row in rows]
        self.assertTrue(all("DUPLICATE_RENDERED_TEXT" in flags for flags in names))
        self.assertTrue(all("VARIANT_COLLAPSE" in flags for flags in names))

    def test_authoring_duplicate_requires_distinct_ids_in_one_pool(self) -> None:
        rows = [
            _row(f"case-{index}", text="I can help with that.", variant=f"semantic-{index}")
            for index in range(2)
        ]
        for index, row in enumerate(rows):
            row["semanticPath"]["phraseID"] = f"authored-phrase-{index}"
        self.analyzer.analyze_run(rows)
        self.assertTrue(all(
            "AUTHORING_DUPLICATE" in {flag["name"] for flag in row["quality"]["flags"]}
            for row in rows
        ))

    def test_low_variety_requires_pool_size_and_controlled_sample(self) -> None:
        rows = [
            _row(f"case-{index}", variant="selected-only-variant")
            for index in range(4)
        ]
        for row in rows:
            row["semanticPath"]["poolVariantCount"] = 4
        self.analyzer.analyze_run(rows)
        self.assertTrue(all(
            "LOW_VARIETY_POOL" in {flag["name"] for flag in row["quality"]["flags"]}
            for row in rows
        ))

        uncontrolled = [_row(f"small-{index}", variant="only-variant") for index in range(3)]
        self.analyzer.analyze_run(uncontrolled)
        self.assertTrue(all(
            "LOW_VARIETY_POOL" not in {flag["name"] for flag in row["quality"]["flags"]}
            for row in uncontrolled
        ))

    def test_semantic_text_collision_requires_comparable_distinct_meanings(self) -> None:
        rows = [
            _row(f"case-{index}", text="I'm here for you.",
                 claims=[claim])
            for index, claim in enumerate(("relationship.family", "inventory.bandage_available",
                                           "function.locomotion_impaired"))
        ]
        for index, row in enumerate(rows):
            row["semanticPath"]["semanticTemplateID"] = f"meaning-{index}"
        self.analyzer.analyze_run(rows)
        self.assertTrue(all(
            "SEMANTIC_TEXT_COLLISION" in {flag["name"] for flag in row["quality"]["flags"]}
            for row in rows
        ))


if __name__ == "__main__":
    unittest.main()
