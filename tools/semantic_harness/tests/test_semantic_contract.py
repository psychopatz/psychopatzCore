"""Unit tests for the frozen S11 v1 canonical semantic data-model contracts."""

from __future__ import annotations

import unittest

from tools.semantic_harness.codebuilder.errors import CompileError
from tools.semantic_harness.codebuilder.semantic_contract import (
    ActivityRef,
    ConversationArchetypeSpec,
    DomainRef,
    DomainSchema,
    DomainSchemaRegistry,
    EffectSpec,
    EntityRef,
    EventRef,
    MemoryRef,
    MemoryResidueSpec,
    ModifierSpec,
    ParticipantSet,
    RetentionSpec,
    RoleBinding,
    RoleSpec,
    SemanticBeatSpec,
    SemanticOutcomeEnvelope,
    StatePolicyRule,
    TopicRef,
    normalize_duration_minutes,
    validate_semantic_role,
)


class SemanticContractTests(unittest.TestCase):
    def test_rejects_positional_participant_roles(self) -> None:
        for bad in ("actor1", "actor2", "actor3", "speaker1", "speaker2"):
            with self.assertRaises(CompileError):
                validate_semantic_role(bad)

    def test_duration_normalization(self) -> None:
        self.assertEqual(normalize_duration_minutes("30m"), 30)
        self.assertEqual(normalize_duration_minutes("6h"), 360)
        self.assertEqual(normalize_duration_minutes("1d"), 1440)
        self.assertEqual(normalize_duration_minutes("7d"), 10080)
        self.assertEqual(normalize_duration_minutes("2w"), 20160)
        with self.assertRaises(CompileError):
            normalize_duration_minutes("0d")

    def test_synthetic_one_to_one_state_action_as_specialization(self) -> None:
        roles = {
            "speaker": RoleSpec.from_mapping("speaker", {"cardinality": "ONE", "kinds": ["actor"]}),
            "addressee": RoleSpec.from_mapping("addressee", {"cardinality": "ONE", "kinds": ["actor"]}),
        }
        pset = ParticipantSet.from_iterable(
            [{"id": "player", "kind": "actor"}, {"id": "npc_a", "kind": "actor"}]
        )
        self.assertEqual(len(pset.participants), 2)
        RoleBinding("speaker", (pset.participants[0],)).validate_against(roles["speaker"])
        RoleBinding("addressee", (pset.participants[1],)).validate_against(roles["addressee"])

        arch = ConversationArchetypeSpec(
            id="test.one_to_one_state_action",
            roles=roles,
            input_policy="typed_parity",
            repeat_policy="state_retired",
            state_policy=(
                StatePolicyRule.from_mapping(
                    {
                        "id": "already_active",
                        "when": {"path": "addressee.state.active", "op": "eq", "value": True},
                        "outcome": "already_satisfied",
                        "reason": "already_active",
                        "admission": "no_op",
                    }
                ),
                StatePolicyRule.from_mapping(
                    {
                        "id": "default",
                        "outcome": "actionable",
                        "reason": "actionable",
                        "admission": "dispatch",
                    }
                ),
            ),
            postconditions=("addressee.state.active == true",),
            continuation="close",
            closure=MemoryResidueSpec.from_mapping({"closureClass": "state_transition"}),
        )
        self.assertEqual(arch.to_dict()["id"], "test.one_to_one_state_action")

    def test_group_argument_and_optional_mediator_roles(self) -> None:
        roles = {
            "speaker": RoleSpec.from_mapping("speaker", {"cardinality": "ONE"}),
            "target": RoleSpec.from_mapping("target", {"cardinality": "ONE_OR_MORE"}),
            "mediator": RoleSpec.from_mapping("mediator", {"cardinality": "OPTIONAL_ONE"}),
            "witness": RoleSpec.from_mapping("witness", {"cardinality": "ZERO_OR_MORE"}),
            "supporter": RoleSpec.from_mapping(
                "supporter", {"cardinality": "BOUNDED_MANY", "min": 0, "max": 3}
            ),
        }
        beat = SemanticBeatSpec(
            id="test.optional_mediator_group",
            archetype="test.group_argument_roles",
            roles=roles,
            topics=(TopicRef("conflict", "social"),),
            events=(EventRef("argument_started"),),
            activities=(ActivityRef("mediate", role="mediator"),),
            memories=(MemoryRef("group_argument_episode", scope="same_day"),),
        )
        self.assertEqual(beat.to_dict()["id"], "test.optional_mediator_group")
        RoleBinding("mediator", ()).validate_against(roles["mediator"])
        with self.assertRaises(CompileError):
            RoleBinding("target", ()).validate_against(roles["target"])

    def test_domain_schema_timed_modifiers_and_memory_residue(self) -> None:
        registry = DomainSchemaRegistry()
        registry.register(
            DomainSchema(
                domain="relationship",
                owner="ProjectHoomans",
                allowed_modifier_fields={"approval": (-50, 50)},
            )
        )
        registry.register(
            DomainSchema(
                domain="mood",
                owner="ProjectHoomans",
                allowed_modifier_fields={"morale": (-30, 30)},
            )
        )
        rel_mod = ModifierSpec.from_mapping(
            {
                "id": "test.timed_relationship_modifier",
                "domain": "relationship",
                "field": "approval",
                "delta": -10,
                "retention": {"kind": "TIMED", "duration": "7d"},
                "stacking": "refresh",
            }
        )
        mood_mod = ModifierSpec.from_mapping(
            {
                "id": "test.timed_mood_modifier",
                "domain": "mood",
                "field": "morale",
                "delta": 5,
                "retention": {"kind": "TIMED", "duration": "6h"},
                "stacking": "replace",
            }
        )
        registry.validate_modifier(rel_mod)
        registry.validate_modifier(mood_mod)
        self.assertEqual(rel_mod.retention.duration_minutes, 10080)
        self.assertEqual(mood_mod.retention.duration_minutes, 360)

        bad_mod = ModifierSpec.from_mapping(
            {
                "id": "test.bad_delta",
                "domain": "relationship",
                "field": "approval",
                "delta": -999,
                "retention": {"kind": "TIMED", "duration": "1d"},
            }
        )
        with self.assertRaises(CompileError):
            registry.validate_modifier(bad_mod)

        residue = MemoryResidueSpec.from_mapping(
            {
                "closureClass": "open_domain_obligation",
                "episodeId": "test.semantic_episode_with_obligation",
                "retention": {"kind": "TIMED", "duration": "30d"},
                "obligationRef": "task:fetch_water",
            }
        )
        self.assertEqual(residue.to_dict()["closureClass"], "open_domain_obligation")

        eff = EffectSpec.from_mapping(
            {"type": "consume_item", "targetRole": "actor", "params": {"itemTag": "water"}}
        )
        self.assertEqual(eff.to_dict()["type"], "consume_item")

        env = SemanticOutcomeEnvelope(
            family_id="test.inventory_gated_action",
            matched_rule_id="default",
            outcome="actionable",
            reason="actionable",
            admission="dispatch",
            capability_id="test:action",
        )
        self.assertEqual(env.to_dict()["outcome"], "actionable")
        self.assertEqual(DomainRef("inventory", "ProjectHoomans").to_dict()["domain"], "inventory")


if __name__ == "__main__":
    unittest.main()
