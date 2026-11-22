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
    DEFAULT_VARIANT_THRESHOLD,
    HYGIENE_AUDIT_SCHEMA,
    RULE_ACTOR_OR_DIRECTION,
    RULE_EMPTY_CANONICAL_DIR,
    RULE_MISLEADING_FLOW,
    RULE_OVERPACKED_VARIANT_POOL,
    RULE_STYLE_OR_TIER_SPLIT,
    audit_convo_engine_family_hygiene,
)

PYTHON = sys.executable


def _write_json(path: Path, payload: dict) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return path


def _build_clean_tree(source_root: Path) -> None:
    _write_json(
        source_root / "dialogue" / "social" / "question_identity.json",
        {
            "schema": "psychopatz.convo-engine.v1",
            "id": "question.identity",
            "say": {
                "variants": [
                    {"id": "neutral", "intent": "ask_identity"},
                    {"id": "guarded", "intent": "ask_identity"},
                    {"id": "warm", "intent": "ask_identity"},
                ]
            },
        },
    )
    _write_json(
        source_root / "behavior" / "social" / "acknowledge_news.json",
        {
            "schema": "psychopatz.convo-engine.v1",
            "id": "behavior.acknowledge_news",
            "say": {"variants": [{"id": "neutral"}]},
        },
    )
    _write_json(
        source_root / "beat" / "social" / "flow_negotiation.json",
        {
            "schema": "psychopatz.convo-engine.v1",
            "id": "flow.negotiation.opening",
            "nodes": {
                "start": {"say": {"variants": [{"id": "neutral"}]}},
            },
        },
    )
    _write_json(
        source_root / "realization" / "social" / "agree.json",
        {
            "schema": "psychopatz.convo-engine.v1",
            "id": "construction.social.agree",
            "dialogueAct": "AGREE",
        },
    )
    # Empty translations directories must not be flagged as empty canonical dirs.
    (source_root / "dialogue" / "social" / "translations").mkdir(parents=True, exist_ok=True)


class ConvoEngineHygieneAuditTests(unittest.TestCase):
    def test_clean_normalized_fixtures_pass(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            source_root = Path(tmp) / "conversation"
            _build_clean_tree(source_root)

            report = audit_convo_engine_family_hygiene(source_root)
            self.assertTrue(report["ok"], report["findings"])
            self.assertEqual(report["schema"], HYGIENE_AUDIT_SCHEMA)
            self.assertEqual(report["variantThreshold"], DEFAULT_VARIANT_THRESHOLD)
            self.assertEqual(report["stats"]["familyFilesChecked"], 4)
            self.assertEqual(report["stats"]["findingCount"], 0)
            self.assertEqual(report["findings"], [])

    def test_catches_all_five_hygiene_violations_deterministically(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            source_root = Path(tmp) / "conversation"

            # 1. Actor-encoded / speaker-direction-encoded family IDs
            for idx, bad_id in enumerate((
                "player_greeting",
                "npc_to_player_warning",
                "two_actor_banter",
                "witness1_callout",
                "combat.player_assaulted.react",
            )):
                _write_json(
                    source_root / "dialogue" / "actor_bad" / f"actor_{idx}.json",
                    {
                        "schema": "psychopatz.convo-engine.v1",
                        "id": bad_id,
                        "say": {"variants": [{"id": "neutral"}]},
                    },
                )

            # 2. Style/personality/relationship-tier-split family IDs
            for idx, bad_id in enumerate((
                "greeting.brave",
                "greeting.aggressive",
                "greeting.shaken",
                "greeting.reserved",
                "greeting.friend",
                "greeting.lover",
                "greeting.wary",
            )):
                _write_json(
                    source_root / "dialogue" / "style_bad" / f"style_{idx}.json",
                    {
                        "schema": "psychopatz.convo-engine.v1",
                        "id": bad_id,
                        "say": {"variants": [{"id": "neutral"}]},
                    },
                )

            # 3. Misleading flow.* family IDs without flow/nodes graph
            _write_json(
                source_root / "dialogue" / "flow_bad" / "misleading_flow.json",
                {
                    "schema": "psychopatz.convo-engine.v1",
                    "id": "flow.single_turn_greeting",
                    "say": {"variants": [{"id": "neutral"}]},
                },
            )
            _write_json(
                source_root / "dialogue" / "flow_bad" / "empty_nodes_flow.json",
                {
                    "schema": "psychopatz.convo-engine.v1",
                    "id": "flow.empty_graph",
                    "nodes": {},
                    "say": {"variants": [{"id": "neutral"}]},
                },
            )

            # 4a. Overpacked variant pool by count (>= 12 default)
            _write_json(
                source_root / "dialogue" / "overpacked" / "too_many_variants.json",
                {
                    "schema": "psychopatz.convo-engine.v1",
                    "id": "social.chat.idle",
                    "say": {
                        "variants": [{"id": f"v{i}"} for i in range(12)],
                    },
                },
            )
            # 4b. Overpacked variant pool by heterogeneous semantic intents
            _write_json(
                source_root / "dialogue" / "overpacked" / "mixed_intents.json",
                {
                    "schema": "psychopatz.convo-engine.v1",
                    "id": "social.chat.mixed",
                    "say": {
                        "variants": [
                            {"id": "v1", "intent": "greet"},
                            {"id": "v2", "intent": "threaten"},
                        ],
                    },
                },
            )

            # 5. Empty canonical source directories
            (source_root / "beat").mkdir(parents=True, exist_ok=True)
            (source_root / "dialogue" / "empty_domain").mkdir(parents=True, exist_ok=True)

            report_a = audit_convo_engine_family_hygiene(source_root)
            report_b = audit_convo_engine_family_hygiene(source_root)
            self.assertEqual(report_a, report_b)
            self.assertFalse(report_a["ok"])

            by_rule = report_a["stats"]["byRule"]
            self.assertEqual(by_rule[RULE_ACTOR_OR_DIRECTION], 5)
            self.assertEqual(by_rule[RULE_STYLE_OR_TIER_SPLIT], 7)
            self.assertEqual(by_rule[RULE_MISLEADING_FLOW], 2)
            self.assertEqual(by_rule[RULE_OVERPACKED_VARIANT_POOL], 2)
            self.assertEqual(by_rule[RULE_EMPTY_CANONICAL_DIR], 2)

            # Configurable threshold check
            _write_json(
                source_root / "dialogue" / "overpacked" / "four_variants.json",
                {
                    "schema": "psychopatz.convo-engine.v1",
                    "id": "social.chat.small",
                    "say": {"variants": [{"id": f"v{i}"} for i in range(4)]},
                },
            )
            strict_report = audit_convo_engine_family_hygiene(source_root, variant_threshold=4)
            self.assertEqual(strict_report["stats"]["byRule"][RULE_OVERPACKED_VARIANT_POOL], 3)

    def test_cli_entrypoints_clean_and_dirty(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            clean_root = Path(tmp) / "clean"
            _build_clean_tree(clean_root)

            dirty_root = Path(tmp) / "dirty"
            _build_clean_tree(dirty_root)
            _write_json(
                dirty_root / "dialogue" / "social" / "bad.json",
                {
                    "schema": "psychopatz.convo-engine.v1",
                    "id": "npc_to_player_greet.brave",
                    "say": {"variants": [{"id": "neutral"}]},
                },
            )

            # Standalone module CLI on clean tree
            clean_proc = subprocess.run(
                [
                    PYTHON,
                    "-m",
                    "tools.semantic_harness.codebuilder.convo_engine_hygiene_audit",
                    str(clean_root),
                    "--summary",
                ],
                cwd=ROOT,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(clean_proc.returncode, 0, clean_proc.stderr or clean_proc.stdout)
            clean_payload = json.loads(clean_proc.stdout)
            self.assertTrue(clean_payload["ok"])

            # Unified convo_engine_cli.py hygiene-audit on dirty tree
            dirty_proc = subprocess.run(
                [
                    PYTHON,
                    "-m",
                    "tools.semantic_harness.codebuilder.convo_engine_cli",
                    "hygiene-audit",
                    "--source-root",
                    str(dirty_root),
                ],
                cwd=ROOT,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(dirty_proc.returncode, 2, dirty_proc.stderr or dirty_proc.stdout)
            dirty_payload = json.loads(dirty_proc.stdout)
            self.assertFalse(dirty_payload["ok"])
            codes = {item["code"] for item in dirty_payload["findings"]}
            self.assertIn(RULE_ACTOR_OR_DIRECTION, codes)
            self.assertIn(RULE_STYLE_OR_TIER_SPLIT, codes)


if __name__ == "__main__":
    unittest.main()
