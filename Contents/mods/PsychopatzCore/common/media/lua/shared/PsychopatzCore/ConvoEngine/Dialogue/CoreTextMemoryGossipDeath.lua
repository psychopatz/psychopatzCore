-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_text_memory_gossip_death",
        ["domainPath"] = "core_text_memory_gossip_death",
        ["exchangeFamily"] = {
            ["familyID"] = "death.report",
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
                                ["fallback"] = "I heard {target.name} did not make it back.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.death.report.say.1.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "death",
            ["textRoles"] = {
                {
                    ["fallback"] = "I heard {target.name} did not make it back.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.death.report.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "death.report",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "report",
            ["sourceId"] = "death.report",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_death/death_report.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextMemoryGossipDeath",
        ["namespace"] = "death",
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
            ["events"] = {
                {
                    ["id"] = "character_death",
                    ["kind"] = "world_event",
                },
            },
            ["memories"] = {
                {
                    ["id"] = "death_episode",
                    ["scope"] = "durable",
                },
            },
            ["metadata"] = {
                ["textKey"] = "death.report",
                ["textRows"] = {
                    {
                        ["fallback"] = "I heard {target.name} did not make it back.",
                        ["key"] = "death.report",
                    },
                },
                ["textTarget"] = "memory/gossip",
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
                                ["fallback"] = "I heard {target.name} did not make it back.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "memory",
                    ["id"] = "death",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "death.report",
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
                            ["fallback"] = "I heard {target.name} did not make it back.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.death.report.say_1",
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
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_text_memory_gossip_death/death_report.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I heard {target.name} did not make it back.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.death.report.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_death",
        ["domainPath"] = "core_text_memory_gossip_death",
        ["exchangeFamily"] = {
            ["familyID"] = "death.sacrifice",
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
                                ["fallback"] = "They say {target.name} stayed behind so others could escape.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.death.sacrifice.say.1.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "death",
            ["textRoles"] = {
                {
                    ["fallback"] = "They say {target.name} stayed behind so others could escape.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.death.sacrifice.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "death.sacrifice",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "sacrifice",
            ["sourceId"] = "death.sacrifice",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_death/death_sacrifice.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextMemoryGossipDeath",
        ["namespace"] = "death",
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
            ["events"] = {
                {
                    ["id"] = "character_death",
                    ["kind"] = "world_event",
                },
            },
            ["memories"] = {
                {
                    ["id"] = "death_episode",
                    ["scope"] = "durable",
                },
            },
            ["metadata"] = {
                ["textKey"] = "death.sacrifice",
                ["textRows"] = {
                    {
                        ["fallback"] = "They say {target.name} stayed behind so others could escape.",
                        ["key"] = "death.sacrifice",
                    },
                },
                ["textTarget"] = "memory/gossip",
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
                                ["fallback"] = "They say {target.name} stayed behind so others could escape.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "memory",
                    ["id"] = "death",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "death.sacrifice",
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
                            ["fallback"] = "They say {target.name} stayed behind so others could escape.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.death.sacrifice.say_1",
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
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_text_memory_gossip_death/death_sacrifice.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "They say {target.name} stayed behind so others could escape.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.death.sacrifice.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
