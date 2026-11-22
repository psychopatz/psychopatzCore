from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.semantic_harness.codebuilder.convo_engine_hygiene_audit import (
    DYNAMIC_TOKEN_AUDIT_SCHEMA,
    RULE_EN_TL_PLACEHOLDER_MISMATCH,
    RULE_UNCONDITIONAL_STRANGER_NAME,
    dynamic_token_audit,
)
from tools.semantic_harness.inspection.response_observatory import run_quality_matrix
from tools.semantic_harness.testing.sweep_quality import (
    QualityAnalyzer,
    summarize_dynamic_grounding,
)

PYTHON = sys.executable


def _make_row(
    *,
    case_id: str = "case-1",
    final_text: str = "Stay sharp.",
    familiarity: float | None = 0.0,
    bond_kind: str = "none",
    identity_trust: str | float | None = "unknown",
    knows_addressee: bool | None = None,
    addressee_name: str = "",
    speaker_name: str = "",
    scene_location: str = "",
    event_location: str = "",
    used_tokens: list[str] | None = None,
    resolved_tokens: dict[str, str] | None = None,
    intent: str = "warn",
    row_type: str = "",
) -> dict:
    rel_summary: dict = {
        "bondKind": bond_kind,
        "familiarity": familiarity,
        "identityTrust": identity_trust,
    }
    if knows_addressee is not None:
        rel_summary["knowsAddressee"] = knows_addressee

    output: dict = {"finalText": final_text}
    if used_tokens is not None:
        output["usedTokens"] = used_tokens
    if resolved_tokens is not None:
        output["resolvedTokens"] = resolved_tokens

    row: dict = {
        "identity": {"caseID": case_id},
        "semanticPath": {"intent": intent},
        "trigger": {
            "relationshipSummary": rel_summary,
            "actorSummary": {
                "listenerID": "player",
                "addresseeName": addressee_name,
                "speakerName": speaker_name,
            },
            "stateSummary": {
                "sceneLocation": scene_location,
                "eventLocation": event_location,
            },
        },
        "output": output,
        "selectionProvenance": {"canonicalSourceOwner": "PsychopatzCore"},
    }
    if row_type:
        row["rowType"] = row_type
    return row


def _write_json(path: Path, payload: dict) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return path


class _ObservatoryStubWorker:
    def __init__(self, turn: dict) -> None:
        self._turn = turn

    def __enter__(self) -> "_ObservatoryStubWorker":
        return self

    def __exit__(self, exc_type, exc, tb) -> None:
        return None

    def input(self, _utterance: str) -> dict:
        return self._turn


class DynamicTokenSweepQualityTests(unittest.TestCase):
    def setUp(self) -> None:
        self.analyzer = QualityAnalyzer()

    def test_ungrounded_name_use_cases_and_negative_controls(self) -> None:
        # 1. Stranger familiarity <= 0 + bondKind == "none" using personal name
        stranger_named = _make_row(
            final_text="Stay behind me, Elena.",
            addressee_name="Elena",
            familiarity=0.0,
            bond_kind="none",
        )
        flags = {f.name for f in self.analyzer.analyze_row(stranger_named)}
        self.assertIn("UNGROUNDED_NAME_USE", flags)

        # 2. identityTrust == "unmet" / 0 even with positive familiarity
        unmet_row = _make_row(
            final_text="Good to see you, Elena.",
            addressee_name="Elena",
            familiarity=0.5,
            bond_kind="none",
            identity_trust="unmet",
        )
        self.assertIn(
            "UNGROUNDED_NAME_USE",
            {f.name for f in self.analyzer.analyze_row(unmet_row)},
        )

        # 3. knowsAddressee == False
        unknown_flag_row = _make_row(
            final_text="Watch out, Elena.",
            addressee_name="Elena",
            familiarity=0.8,
            bond_kind="friend",
            identity_trust="known",
            knows_addressee=False,
        )
        self.assertIn(
            "UNGROUNDED_NAME_USE",
            {f.name for f in self.analyzer.analyze_row(unknown_flag_row)},
        )

        # 4. {addressee.name} resolved to generic "you" in vocative
        you_vocative = _make_row(
            final_text="Thanks, you.",
            used_tokens=["{addressee.name}"],
            resolved_tokens={"addressee.name": "you"},
        )
        self.assertIn(
            "UNGROUNDED_NAME_USE",
            {f.name for f in self.analyzer.analyze_row(you_vocative)},
        )

        # 5. Negative control: single clean "Hey, stranger." is valid
        stranger_ok = _make_row(
            final_text="Hey, stranger.",
            addressee_name="Elena",
            familiarity=0.0,
            bond_kind="none",
            used_tokens=["{addressee.name}"],
            resolved_tokens={"addressee.name": "stranger"},
        )
        stranger_flags = {f.name for f in self.analyzer.analyze_row(stranger_ok)}
        self.assertNotIn("UNGROUNDED_NAME_USE", stranger_flags)
        self.assertNotIn("BROKEN_TOKEN_GRAMMAR", stranger_flags)

        # 6. Negative control: known addressee name passes cleanly
        known_ok = _make_row(
            final_text="Stay sharp, Elena.",
            addressee_name="Elena",
            familiarity=0.6,
            bond_kind="none",
            identity_trust="known",
            knows_addressee=True,
        )
        self.analyzer.tag_row(known_ok)
        self.assertEqual(known_ok["quality"]["flags"], [])
        self.assertEqual(
            known_ok["quality"]["dynamicGrounding"]["status"],
            "DYNAMIC_GROUNDING_VERIFIED",
        )

    def test_broken_token_grammar_cases(self) -> None:
        bad_texts = [
            "Hey, , watch out.",
            "Listen, Unknown",
            ", watch your step.",
            "Thanks, !",
            "Ready, ?",
            "Spotted near .",
            "Danger in .",
            "Check  the perimeter.",
            "Hey, stranger, you, move back.",
        ]
        for text in bad_texts:
            with self.subTest(text=text):
                row = _make_row(final_text=text, familiarity=0.5, identity_trust="known")
                flags = {f.name for f in self.analyzer.analyze_row(row)}
                self.assertIn("BROKEN_TOKEN_GRAMMAR", flags)

        empty_resolved = _make_row(
            final_text="Watch out.",
            used_tokens=["{slot.place.name}"],
            resolved_tokens={"slot.place.name": ""},
        )
        self.assertIn(
            "BROKEN_TOKEN_GRAMMAR",
            {f.name for f in self.analyzer.analyze_row(empty_resolved)},
        )

    def test_dynamic_grounding_opportunity_and_summary(self) -> None:
        # Known addressee + familiarity >= 0.3 without dynamic ref -> INFO opportunity
        opp_name = _make_row(
            case_id="c-opp-1",
            final_text="Watch the doorway ahead.",
            addressee_name="Marcus",
            familiarity=0.4,
            identity_trust="known",
            knows_addressee=True,
        )
        opp_flags = self.analyzer.analyze_row(opp_name)
        self.assertEqual([f.name for f in opp_flags], ["DYNAMIC_GROUNDING_OPPORTUNITY"])
        self.assertEqual(opp_flags[0].severity, "INFO")

        # Bound sceneLocation without dynamic ref -> INFO opportunity
        opp_loc = _make_row(
            case_id="c-opp-2",
            final_text="We should keep moving.",
            scene_location="Riverside Clinic",
        )
        self.assertEqual(
            [f.name for f in self.analyzer.analyze_row(opp_loc)],
            ["DYNAMIC_GROUNDING_OPPORTUNITY"],
        )

        # Bound sceneLocation USED -> verified, no opportunity flag
        used_loc = _make_row(
            case_id="c-ok-loc",
            final_text="We should fortify Riverside Clinic before nightfall.",
            scene_location="Riverside Clinic",
        )
        self.assertEqual(self.analyzer.analyze_row(used_loc), [])

        # Atomic bark negative control -> no opportunity flag
        atomic_bark = _make_row(
            case_id="c-bark",
            final_text="Okay.",
            addressee_name="Marcus",
            familiarity=0.8,
            knows_addressee=True,
            intent="bark",
            row_type="bark",
        )
        self.assertEqual(self.analyzer.analyze_row(atomic_bark), [])

        # Summary verification
        clean_named = _make_row(
            case_id="c-ok-name",
            final_text="Cover the stairs, Marcus.",
            addressee_name="Marcus",
            familiarity=0.7,
            knows_addressee=True,
            used_tokens=["{addressee.name}"],
            resolved_tokens={"addressee.name": "Marcus"},
        )
        analyzed = self.analyzer.analyze_run([clean_named, used_loc, opp_name])
        summary = summarize_dynamic_grounding(analyzed)
        self.assertEqual(summary["status"], "DYNAMIC_GROUNDING_VERIFIED")
        self.assertEqual(summary["totalRows"], 3)
        self.assertEqual(summary["rowsWithDynamicTokensResolved"], 2)
        self.assertEqual(summary["appropriateNameUsageRate"], 1.0)
        self.assertEqual(summary["brokenTokenCount"], 0)
        self.assertEqual(summary["ungroundedNameCount"], 0)
        self.assertEqual(summary["groundingOpportunityCount"], 1)
        self.assertEqual(self.analyzer.last_dynamic_grounding_summary, summary)


class DynamicTokenHygieneAuditTests(unittest.TestCase):
    def test_detects_en_tl_mismatch_unconditional_stranger_and_coverage(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "conversation"

            # Canonical family with stranger + guarded + conditional_named variants
            _write_json(
                root / "dialogue" / "social" / "first_contact_greet.json",
                {
                    "schema": "psychopatz.convo-engine.v1",
                    "id": "social.first_contact.greet",
                    "domains": [{"domain": "social", "owner": "PsychopatzCore"}],
                    "say": {
                        "variants": [
                            {"id": "stranger"},
                            {"id": "hostile"},
                            {
                                "id": "known_acquaintance",
                                "when": "relationship.familiarity >= 0.3",
                            },
                            {"id": "bond_warm"},
                        ]
                    },
                },
            )
            _write_json(
                root / "translations" / "EN" / "dialogue" / "social" / "first_contact_greet.json",
                {
                    "schema": "psychopatz.convo-engine.translation.v1",
                    "family": "social.first_contact.greet",
                    "locale": "EN",
                    "entries": {
                        # Stranger unconditionally uses {addressee.name} + EN/TL mismatch!
                        "say.variants.stranger": [
                            "Hold it, {addressee.name}. Who are you?",
                        ],
                        # Hostile without acquaintance condition uses {addressee.name}
                        "say.variants.hostile": [
                            "Back off, {addressee.name}, near {scene.location}.",
                        ],
                        # Acquaintance condition present -> allowed!
                        "say.variants.known_acquaintance": [
                            "Good to see you at {scene.location}, {addressee.name}.",
                        ],
                        # Bonded variant -> allowed!
                        "say.variants.bond_warm": [
                            "I'm {speaker.name}. Watch {slot.place.name} at {scene.clock}.",
                        ],
                    },
                },
            )
            _write_json(
                root / "translations" / "TL" / "dialogue" / "social" / "first_contact_greet.json",
                {
                    "schema": "psychopatz.convo-engine.translation.v1",
                    "family": "social.first_contact.greet",
                    "locale": "TL",
                    "entries": {
                        # Missing {addressee.name} -> en_tl_placeholder_mismatch!
                        "say.variants.stranger": [
                            "Tigil muna. Sino ka?",
                        ],
                        "say.variants.hostile": [
                            "Umalis ka, {addressee.name}, malapit sa {scene.location}.",
                        ],
                        "say.variants.known_acquaintance": [
                            "Buti nandito ka sa {scene.location}, {addressee.name}.",
                        ],
                        "say.variants.bond_warm": [
                            "Ako si {speaker.name}. Bantayan ang {slot.place.name} pagsapit ng {scene.clock}.",
                        ],
                    },
                },
            )

            report = dynamic_token_audit(root)
            self.assertFalse(report["ok"])
            self.assertEqual(report["schema"], DYNAMIC_TOKEN_AUDIT_SCHEMA)

            by_rule = report["stats"]["byRule"]
            self.assertEqual(by_rule[RULE_EN_TL_PLACEHOLDER_MISMATCH], 1)
            self.assertEqual(by_rule[RULE_UNCONDITIONAL_STRANGER_NAME], 2)

            coverage = report["dynamic_coverage_summary"]
            social_cov = coverage["byDomain"]["social"]
            self.assertEqual(social_cov["totalVariants"], 4)
            self.assertEqual(social_cov["variantsWithDynamicTokens"], 4)
            self.assertEqual(social_cov["tokens"]["{addressee.name}"], 3)
            self.assertEqual(social_cov["tokens"]["{speaker.name}"], 1)
            self.assertEqual(social_cov["tokens"]["{scene.location}"], 2)
            self.assertEqual(social_cov["tokens"]["{scene.clock}"], 1)
            self.assertEqual(social_cov["tokens"]["{slot.*}"], 1)

            # CLI integration check via convo_engine_cli.py hygiene-audit --dynamic-audit
            proc = subprocess.run(
                [
                    PYTHON,
                    "-m",
                    "tools.semantic_harness.codebuilder.convo_engine_cli",
                    "hygiene-audit",
                    "--source-root",
                    str(root),
                    "--dynamic-audit",
                    "--summary",
                ],
                cwd=ROOT,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(proc.returncode, 2, proc.stderr or proc.stdout)
            cli_payload = json.loads(proc.stdout)
            self.assertFalse(cli_payload["ok"])
            self.assertIn("dynamicAudit", cli_payload)
            self.assertEqual(
                cli_payload["dynamicAudit"]["stats"]["byRule"][RULE_EN_TL_PLACEHOLDER_MISMATCH],
                1,
            )


class ObservatoryDynamicGroundingTests(unittest.TestCase):
    def test_response_observatory_reports_dynamic_tokens_and_grounding(self) -> None:
        clean_turn = {
            "type": "dialogue",
            "accepted": True,
            "input": "Any updates?",
            "contextAfter": {
                "actorConversationContext": {
                    "personalRelationship": {
                        "familiarity": 0.7,
                        "identityTrust": "known",
                        "knowsAddressee": True,
                    }
                }
            },
            "messages": [
                {
                    "speaker": "npc",
                    "payload": {
                        "key": "social.check_in.01",
                        "text": "Keep your eyes open at Riverside Clinic, Elena.",
                        "templateText": "Keep your eyes open at {scene.location}, {addressee.name}.",
                        "resolvedTokens": {
                            "scene.location": "Riverside Clinic",
                            "addressee.name": "Elena",
                        },
                        "translations": {
                            "EN": "Keep your eyes open at {scene.location}, {addressee.name}.",
                            "TL": "Magmatyag ka sa {scene.location}, {addressee.name}.",
                        },
                    },
                }
            ],
            "translation": {"language": "EN", "lookups": []},
        }

        broken_turn = {
            "type": "dialogue",
            "accepted": True,
            "input": "Hello?",
            "contextAfter": {
                "actorConversationContext": {
                    "personalRelationship": {
                        "familiarity": 0.0,
                        "identityTrust": "unknown",
                        "knowsAddressee": False,
                    }
                }
            },
            "messages": [
                {
                    "speaker": "npc",
                    "payload": {
                        "key": "social.greet.stranger",
                        "text": "Hey, , watch out Elena",
                        "translations": {
                            "EN": "Hey, {addressee.name}, watch out.",
                            "TL": "Hoy, mag-ingat ka.",
                        },
                    },
                }
            ],
            "translation": {"language": "EN", "lookups": []},
        }

        cases = [
            {
                "label": "clean_grounded",
                "utterance": "Any updates?",
                "scenario": {
                    "player": {"name": "Elena"},
                    "scene": {"location": "Riverside Clinic"},
                },
            },
            {
                "label": "broken_stranger",
                "utterance": "Hello?",
                "scenario": {
                    "player": {"name": "Elena"},
                },
            },
        ]
        turns = [clean_turn, broken_turn]
        idx = {"i": 0}

        def factory(_scenario: dict) -> _ObservatoryStubWorker:
            turn = turns[idx["i"]]
            idx["i"] += 1
            return _ObservatoryStubWorker(turn)

        matrix = run_quality_matrix(cases, worker_factory=factory)
        self.assertTrue(matrix["ok"])

        clean_row, broken_row = matrix["cases"]
        self.assertEqual(
            clean_row["dynamicTokens"]["resolvedTokens"],
            {"scene.location": "Riverside Clinic", "addressee.name": "Elena"},
        )
        self.assertIn("{addressee.name}", clean_row["dynamicGrounding"]["usedTokens"])
        self.assertIn("{scene.location}", clean_row["dynamicGrounding"]["usedTokens"])
        self.assertFalse(clean_row["dynamicGrounding"]["ungroundedName"])
        self.assertFalse(clean_row["dynamicGrounding"]["brokenTokenGrammar"])
        self.assertTrue(clean_row["dynamicGrounding"]["enTlPlaceholderParity"])
        self.assertEqual(clean_row["dynamicGrounding"]["status"], "DYNAMIC_GROUNDING_VERIFIED")

        self.assertTrue(broken_row["dynamicGrounding"]["ungroundedName"])
        self.assertTrue(broken_row["dynamicGrounding"]["brokenTokenGrammar"])
        self.assertFalse(broken_row["dynamicGrounding"]["enTlPlaceholderParity"])
        self.assertEqual(broken_row["dynamicGrounding"]["status"], "ISSUES_FOUND")

        summary = matrix["dynamicGroundingSummary"]
        self.assertEqual(summary["ungroundedNameCount"], 1)
        self.assertEqual(summary["brokenTokenGrammarCount"], 1)
        self.assertEqual(summary["enTlParityFailures"], 1)


if __name__ == "__main__":
    unittest.main()
