import unittest

from tools.semantic_harness.codebuilder.conversation_validation import (
    _validate_realization_shard,
)
from tools.semantic_harness.codebuilder.errors import CompileError


class ConversationRealizationContractTests(unittest.TestCase):
    def test_one_source_record_compiles_to_locale_runtime_records(self) -> None:
        compiled = _validate_realization_shard(
            {
                "realizations": [
                    {
                        "id": "construction.social.acknowledge",
                        "type": "construction",
                        "dialogueAct": "ACKNOWLEDGE",
                        "strategy": "ACKNOWLEDGE",
                        "translations": {
                            "EN": [{"kind": "literal", "value": "I hear you."}],
                            "TL": [{"kind": "literal", "value": "Naririnig kita."}],
                        },
                    }
                ]
            },
            "realization/social/constructions.json",
        )
        self.assertEqual(
            [record["id"] for record in compiled["records"]],
            ["construction.en.social.acknowledge", "construction.tl.social.acknowledge"],
        )
        self.assertEqual(compiled["records"][0]["locale"], "EN")
        self.assertEqual(compiled["records"][1]["locale"], "TL")

    def test_locale_split_runtime_shape_is_not_valid_authoring(self) -> None:
        with self.assertRaises(CompileError):
            _validate_realization_shard(
                {
                    "realizations": [
                        {
                            "id": "construction.en.social.acknowledge",
                            "type": "construction",
                            "locale": "EN",
                            "strategy": "ACKNOWLEDGE",
                            "tokens": [{"kind": "literal", "value": "I hear you."}],
                        }
                    ]
                },
                "realization/social/legacy.json",
            )


if __name__ == "__main__":
    unittest.main()
