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


if __name__ == "__main__":
    unittest.main()
