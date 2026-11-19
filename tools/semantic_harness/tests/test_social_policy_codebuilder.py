"""P3 tests: CodeBuilder portable Social Policy IR, validation, owner routing, and determinism."""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

CORE_ROOT = Path(__file__).resolve().parents[3]
if str(CORE_ROOT) not in sys.path:
    sys.path.insert(0, str(CORE_ROOT))

from tools.semantic_harness.codebuilder.errors import CompileError
from tools.semantic_harness.codebuilder.semantic_contract import (
    DomainSchemaRegistry,
    ModifierSpec,
    RetentionSpec,
)
from tools.semantic_harness.codebuilder.social_policy_compiler import (
    MAX_ANCHOR_BUDGET,
    MAX_DURABLE_ACTOR_REFS,
    MAX_STRONG_ACTOR_REFS,
    SOCIAL_POLICY_PACKAGE_SCHEMA,
    SOCIAL_POLICY_PLAN_SCHEMA,
    SOCIAL_POLICY_SHARD_SCHEMA,
    build_social_domain_schema,
    compile_social_policy_package,
    compile_social_policy_workspace,
    render_social_policy_lua_artifacts,
)


def _write_pkg(root: Path, pkg_doc: dict, shards: dict[str, dict]) -> Path:
    root.mkdir(parents=True, exist_ok=True)
    (root / "package.json").write_text(json.dumps(pkg_doc, indent=2), encoding="utf-8")
    for rel, content in shards.items():
        target = root / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(json.dumps(content, indent=2), encoding="utf-8")
    return root


class SocialPolicyCodeBuilderTests(unittest.TestCase):
    def test_workspace_packages_compile_deterministically_and_route_by_owner(self) -> None:
        hoomans = CORE_ROOT.parent / "ProjectHoomans"
        dt = CORE_ROOT.parent / "DynamicTrading"
        registry = DomainSchemaRegistry()
        plans = compile_social_policy_workspace(
            {
                "PsychopatzCore": CORE_ROOT,
                "ProjectHoomans": hoomans,
                "DTCommon": dt,
            },
            domain_schema_registry=registry,
        )
        self.assertEqual(set(plans), {"PsychopatzCore", "ProjectHoomans", "DTCommon"})
        for owner, plan in plans.items():
            self.assertEqual(plan["schema"], SOCIAL_POLICY_PLAN_SCHEMA)
            self.assertEqual(plan["owner"], owner)
            self.assertTrue(plan["sourceMap"])
            lua_a = render_social_policy_lua_artifacts(plan)
            lua_b = render_social_policy_lua_artifacts(plan)
            self.assertEqual(lua_a, lua_b, f"non-deterministic Lua render for {owner}")

        # Verify DomainSchemaRegistry bridge validates ConvoEngine modifiers against social schema
        social_schema = registry.require("social")
        social_schema.validate_modifier(
            ModifierSpec(
                id="mod1",
                domain="social",
                field="approval",
                delta=10.0,
                retention=RetentionSpec(kind="SESSION"),
            )
        )
        with self.assertRaises(CompileError):
            social_schema.validate_modifier(
                ModifierSpec(
                    id="bad",
                    domain="social",
                    field="approval",
                    delta=999.0,
                    retention=RetentionSpec(kind="SESSION"),
                )
            )

    def test_unknown_retention_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            pkg = _write_pkg(
                Path(tmp),
                {
                    "schema": SOCIAL_POLICY_PACKAGE_SCHEMA,
                    "version": 1,
                    "package": "test.social",
                    "owner": "PsychopatzCore",
                    "shards": ["events/bad.json"],
                },
                {
                    "events/bad.json": {
                        "schema": SOCIAL_POLICY_SHARD_SCHEMA,
                        "version": 1,
                        "owner": "PsychopatzCore",
                        "domain": "Bad",
                        "events": [
                            {
                                "id": "bad.event",
                                "memory": {"retentionClass": "FOREVER", "salience": 50},
                                "relationship": {"approvalDelta": 1},
                            }
                        ],
                    }
                },
            )
            with self.assertRaises(CompileError):
                compile_social_policy_package(pkg)

    def test_anchor_requires_salience_and_bounded_budget(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            pkg = _write_pkg(
                Path(tmp),
                {
                    "schema": SOCIAL_POLICY_PACKAGE_SCHEMA,
                    "version": 1,
                    "package": "test.social",
                    "owner": "PsychopatzCore",
                    "shards": ["events/anchor.json"],
                },
                {
                    "events/anchor.json": {
                        "schema": SOCIAL_POLICY_SHARD_SCHEMA,
                        "version": 1,
                        "owner": "PsychopatzCore",
                        "domain": "Anchor",
                        "events": [
                            {
                                "id": "bad.anchor",
                                "memory": {"retentionClass": "ANCHOR", "salience": 100},
                                "relationship": {"approvalDelta": -10},
                            }
                        ],
                    }
                },
            )
            with self.assertRaises(CompileError):
                compile_social_policy_package(pkg)

    def test_unbounded_observer_fanout_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            pkg = _write_pkg(
                Path(tmp),
                {
                    "schema": SOCIAL_POLICY_PACKAGE_SCHEMA,
                    "version": 1,
                    "package": "test.social",
                    "owner": "PsychopatzCore",
                    "shards": ["events/fanout.json"],
                },
                {
                    "events/fanout.json": {
                        "schema": SOCIAL_POLICY_SHARD_SCHEMA,
                        "version": 1,
                        "owner": "PsychopatzCore",
                        "domain": "Fanout",
                        "events": [
                            {
                                "id": "bad.fanout",
                                "memory": {
                                    "retentionClass": "SHORT",
                                    "observerPolicy": {"maxObservers": 50},
                                },
                                "relationship": {"approvalDelta": 1},
                            }
                        ],
                    }
                },
            )
            with self.assertRaises(CompileError):
                compile_social_policy_package(pkg)

    def test_forbidden_pz_or_adopter_calls_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            pkg = _write_pkg(
                Path(tmp),
                {
                    "schema": SOCIAL_POLICY_PACKAGE_SCHEMA,
                    "version": 1,
                    "package": "test.social",
                    "owner": "PsychopatzCore",
                    "shards": ["events/portable.json"],
                },
                {
                    "events/portable.json": {
                        "schema": SOCIAL_POLICY_SHARD_SCHEMA,
                        "version": 1,
                        "owner": "PsychopatzCore",
                        "domain": "Portable",
                        "events": [
                            {
                                "id": "bad.pz",
                                "memory": {
                                    "retentionClass": "SHORT",
                                    "consolidationFamily": "PNC.Relationships.Mutate",
                                },
                                "relationship": {"approvalDelta": 1},
                            }
                        ],
                    }
                },
            )
            with self.assertRaises(CompileError):
                compile_social_policy_package(pkg)

    def test_workspace_policies_expose_reference_strength_and_domain_facts(self) -> None:
        hoomans = CORE_ROOT.parent / "ProjectHoomans"
        dt = CORE_ROOT.parent / "DynamicTrading"
        registry = DomainSchemaRegistry()
        plans = compile_social_policy_workspace(
            {
                "PsychopatzCore": CORE_ROOT,
                "ProjectHoomans": hoomans,
                "DTCommon": dt,
            },
            domain_schema_registry=registry,
        )
        core_events = plans["PsychopatzCore"]["events"]
        self.assertEqual(core_events["social.greeting"]["refStrength"], "WEAK")
        self.assertEqual(core_events["social.assistance"]["refStrength"], "WEAK")
        self.assertEqual(core_events["social.assistance"]["sourceRefStrength"], "WEAK")
        self.assertEqual(core_events["social.betrayal_anchor"]["refStrength"], "STRONG")
        self.assertEqual(core_events["social.betrayal_anchor"]["sourceRefStrength"], "WEAK")
        self.assertEqual(core_events["social.betrayal_anchor"]["references"]["degradeOnPurge"], "KEEP_HISTORICAL")

        hoom_events = plans["ProjectHoomans"]["events"]
        self.assertEqual(hoom_events["friendship_established"]["refStrength"], "STRONG")
        self.assertEqual(hoom_events["treated_wound"]["refStrength"], "WEAK")
        self.assertEqual(hoom_events["player_emote_wavehi"]["refStrength"], "WEAK")

        dt_events = plans["DTCommon"]["events"]
        self.assertEqual(dt_events["commercial_trade"]["refStrength"], "WEAK")
        self.assertEqual(dt_events["trade.betrayal_or_hostile"]["refStrength"], "STRONG")
        self.assertEqual(dt_events["trade.betrayal_or_hostile"]["sourceRefStrength"], "WEAK")

        social_schema = registry.require("social")
        for fact in (
            "relationship.historical",
            "relationship.targetLifecycleStatus",
            "actor.lifecycleStatus",
            "memory.refStrength",
        ):
            self.assertIn(fact, social_schema.allowed_facts)

    def test_invalid_reference_strength_role_bounds_and_portability_rejected(self) -> None:
        def compile_one(event_doc: dict) -> dict:
            with tempfile.TemporaryDirectory() as tmp:
                pkg = _write_pkg(
                    Path(tmp),
                    {
                        "schema": SOCIAL_POLICY_PACKAGE_SCHEMA,
                        "version": 1,
                        "package": "test.refs",
                        "owner": "PsychopatzCore",
                        "shards": ["events/refs.json"],
                    },
                    {
                        "events/refs.json": {
                            "schema": SOCIAL_POLICY_SHARD_SCHEMA,
                            "version": 1,
                            "owner": "PsychopatzCore",
                            "domain": "Refs",
                            "events": [event_doc],
                        }
                    },
                )
                return compile_social_policy_package(pkg)

        # Valid ANCHOR with STRONG target + STRONG subject + LABEL_ONLY witness (maxStrongRefs=2)
        ok_plan = compile_one(
            {
                "id": "valid.murder_bond",
                "memory": {"retentionClass": "ANCHOR", "salience": 230, "anchorMax": MAX_ANCHOR_BUDGET},
                "relationship": {"approvalDelta": -50},
                "references": {
                    "target": "STRONG",
                    "subject": "STRONG",
                    "witness": "LABEL_ONLY",
                    "maxActorRefs": 2,
                    "maxStrongRefs": MAX_STRONG_ACTOR_REFS,
                    "degradeOnPurge": "LABEL_ONLY",
                },
            }
        )
        ok_ev = ok_plan["events"]["valid.murder_bond"]
        self.assertEqual(ok_ev["refStrength"], "STRONG")
        self.assertEqual(ok_ev["references"]["subject"], "STRONG")
        self.assertEqual(ok_ev["references"]["witness"], "LABEL_ONLY")

        bad_cases = [
            # SCENE cannot hold STRONG ref
            {
                "id": "bad.scene_strong",
                "memory": {"retentionClass": "SCENE", "salience": 40},
                "relationship": {"approvalDelta": 1},
                "references": {"target": "STRONG", "maxStrongRefs": 1},
            },
            # SHORT cannot hold STRONG ref
            {
                "id": "bad.short_strong",
                "memory": {"retentionClass": "SHORT", "salience": 90},
                "relationship": {"approvalDelta": 1},
                "references": {"target": "WEAK", "maxStrongRefs": 1},
            },
            # LONG cannot have 2 STRONG refs
            {
                "id": "bad.long_two_strong",
                "memory": {"retentionClass": "LONG", "salience": 120},
                "relationship": {"approvalDelta": 2},
                "references": {
                    "target": "STRONG",
                    "subject": "STRONG",
                    "maxActorRefs": 2,
                    "maxStrongRefs": 2,
                },
            },
            # Exceeds MAX_DURABLE_ACTOR_REFS (3)
            {
                "id": "bad.too_many_actor_refs",
                "memory": {"retentionClass": "LONG", "salience": 120},
                "relationship": {"approvalDelta": 1},
                "references": {"target": "WEAK", "maxActorRefs": MAX_DURABLE_ACTOR_REFS + 1},
            },
            # Active non-LABEL_ONLY roles exceed declared maxActorRefs
            {
                "id": "bad.role_count_exceeds_cap",
                "memory": {"retentionClass": "LONG", "salience": 120},
                "relationship": {"approvalDelta": 1},
                "references": {"target": "WEAK", "source": "WEAK", "maxActorRefs": 1},
            },
            # Exceeds MAX_STRONG_ACTOR_REFS (2)
            {
                "id": "bad.too_many_strong",
                "memory": {"retentionClass": "ANCHOR", "salience": 220},
                "relationship": {"approvalDelta": -20},
                "references": {
                    "target": "STRONG",
                    "subject": "STRONG",
                    "source": "STRONG",
                    "maxActorRefs": 3,
                    "maxStrongRefs": 3,
                },
            },
            # anchorMax > MAX_ANCHOR_BUDGET (16)
            {
                "id": "bad.anchor_budget",
                "memory": {"retentionClass": "ANCHOR", "salience": 210, "anchorMax": MAX_ANCHOR_BUDGET + 1},
                "relationship": {"approvalDelta": 5},
            },
            # Invalid role name
            {
                "id": "bad.role_name",
                "memory": {"retentionClass": "LONG", "salience": 100},
                "relationship": {"approvalDelta": 1},
                "references": {"roles": {"bystander_unlimited": "WEAK"}},
            },
            # Invalid strength value
            {
                "id": "bad.strength_value",
                "memory": {"retentionClass": "LONG", "salience": 100},
                "relationship": {"approvalDelta": 1},
                "references": {"target": "ETERNAL"},
            },
            # Invalid degradeOnPurge
            {
                "id": "bad.degrade_policy",
                "memory": {"retentionClass": "LONG", "salience": 100},
                "relationship": {"approvalDelta": 1},
                "references": {"target": "WEAK", "degradeOnPurge": "DELETE_SAVE"},
            },
            # Conflicting shorthand vs roles
            {
                "id": "bad.conflicting_role",
                "memory": {"retentionClass": "ANCHOR", "salience": 200},
                "relationship": {"approvalDelta": 5},
                "references": {"target": "STRONG", "roles": {"target": "WEAK"}},
            },
            # Forbidden adopter/PZ symbol inside references
            {
                "id": "bad.portable_refs",
                "memory": {"retentionClass": "LONG", "salience": 100},
                "relationship": {"approvalDelta": 1},
                "references": {"roles": {"PNC.Helper": "WEAK"}},
            },
        ]
        for idx, case in enumerate(bad_cases):
            with self.subTest(case_index=idx, event_id=case["id"]):
                with self.assertRaises(CompileError):
                    compile_one(case)


if __name__ == "__main__":
    unittest.main()
