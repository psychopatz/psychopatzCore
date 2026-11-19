-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_knowledge_gossip",
        ["domainPath"] = "core_knowledge_gossip",
        ["exchangeFamily"] = {
            ["familyID"] = "gossip.unknown",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "I haven't heard any news lately.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.gossip.unknown.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "{addressee.name}, I don't have anything to share.",
                                ["id"] = "bond_guarded",
                                ["templateID"] = "convo.gossip.unknown.say.1.bond_guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "{addressee.name}, I haven't heard any news lately.",
                                ["id"] = "bond_neutral",
                                ["templateID"] = "convo.gossip.unknown.say.1.bond_neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "{addressee.name}, no news.",
                                ["id"] = "bond_terse",
                                ["templateID"] = "convo.gossip.unknown.say.1.bond_terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "{addressee.name}, I haven't heard any news, sorry.",
                                ["id"] = "bond_warm",
                                ["templateID"] = "convo.gossip.unknown.say.1.bond_warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I don't have anything to share.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.gossip.unknown.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "No news.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.gossip.unknown.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I haven't heard any news, sorry.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.gossip.unknown.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "gossip",
            ["slots"] = {
                ["subject"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.person",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "I haven't heard any news lately.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.gossip.unknown.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "{addressee.name}, I don't have anything to share.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.gossip.unknown.say.1.bond_guarded",
                    ["variantID"] = "bond_guarded",
                },
                {
                    ["fallback"] = "{addressee.name}, I haven't heard any news lately.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.gossip.unknown.say.1.bond_neutral",
                    ["variantID"] = "bond_neutral",
                },
                {
                    ["fallback"] = "{addressee.name}, no news.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.gossip.unknown.say.1.bond_terse",
                    ["variantID"] = "bond_terse",
                },
                {
                    ["fallback"] = "{addressee.name}, I haven't heard any news, sorry.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.gossip.unknown.say.1.bond_warm",
                    ["variantID"] = "bond_warm",
                },
                {
                    ["fallback"] = "I don't have anything to share.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.gossip.unknown.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "No news.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.gossip.unknown.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "I haven't heard any news, sorry.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.gossip.unknown.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "gossip.unknown",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "unknown",
            ["sourceId"] = "gossip.unknown",
            ["sourcePath"] = "dialogue/core_knowledge_gossip/gossip_unknown.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreKnowledgeGossip",
        ["namespace"] = "gossip",
        ["owner"] = "PsychopatzCore",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["domains"] = {
                {
                    ["domain"] = "memory",
                    ["owner"] = "PsychopatzCore",
                },
            },
            ["metadata"] = {
                ["category"] = "psychopatzcore:knowledge",
                ["responseAct"] = "KNOWLEDGE_RESPONSE",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "I haven't heard any news lately.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "{addressee.name}, I don't have anything to share.",
                                ["id"] = "bond_guarded",
                            },
                            {
                                ["fallback"] = "{addressee.name}, I haven't heard any news lately.",
                                ["id"] = "bond_neutral",
                            },
                            {
                                ["fallback"] = "{addressee.name}, no news.",
                                ["id"] = "bond_terse",
                            },
                            {
                                ["fallback"] = "{addressee.name}, I haven't heard any news, sorry.",
                                ["id"] = "bond_warm",
                            },
                            {
                                ["fallback"] = "I don't have anything to share.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "No news.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "I haven't heard any news, sorry.",
                                ["id"] = "warm",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "knowledge",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "KNOWLEDGE_RESPONSE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "gossip.unknown",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I haven't heard any news lately.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.gossip.unknown.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
            ["subject"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "subject",
            },
        },
        ["slots"] = {
            ["subject"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.person",
            },
        },
        ["sourceShard"] = "dialogue/core_knowledge_gossip/gossip_unknown.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I haven't heard any news lately.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.gossip.unknown.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "{addressee.name}, I don't have anything to share.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.gossip.unknown.say.1.bond_guarded",
                ["variantID"] = "bond_guarded",
            },
            {
                ["fallback"] = "{addressee.name}, I haven't heard any news lately.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.gossip.unknown.say.1.bond_neutral",
                ["variantID"] = "bond_neutral",
            },
            {
                ["fallback"] = "{addressee.name}, no news.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.gossip.unknown.say.1.bond_terse",
                ["variantID"] = "bond_terse",
            },
            {
                ["fallback"] = "{addressee.name}, I haven't heard any news, sorry.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.gossip.unknown.say.1.bond_warm",
                ["variantID"] = "bond_warm",
            },
            {
                ["fallback"] = "I don't have anything to share.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.gossip.unknown.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "No news.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.gossip.unknown.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "I haven't heard any news, sorry.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.gossip.unknown.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
}
