-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_text_memory_gossip_death",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "I heard {target.name} did not make it back.",
                                    },
                                    ["TL"] = {
                                        "Balita ko, hindi na nakabalik si {target.name}.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "I heard {target.name} did not make it back.",
                        },
                        ["TL"] = {
                            "Balita ko, hindi na nakabalik si {target.name}.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "death.report",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "report",
            ["sourceId"] = "death.report",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_death/death_report.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipDeath",
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
            ["metadata"] = {
                ["textKey"] = "death.report",
                ["textRows"] = {
                    {
                        ["key"] = "death.report",
                        ["text"] = {
                            ["EN"] = "I heard {target.name} did not make it back.",
                            ["TL"] = "Balita ko, hindi na nakabalik si {target.name}.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "I heard {target.name} did not make it back.",
                                    },
                                    ["TL"] = {
                                        "Balita ko, hindi na nakabalik si {target.name}.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
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
                ["translations"] = {
                    ["EN"] = {
                        "I heard {target.name} did not make it back.",
                    },
                    ["TL"] = {
                        "Balita ko, hindi na nakabalik si {target.name}.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_death",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "They say {target.name} stayed behind so others could escape.",
                                    },
                                    ["TL"] = {
                                        "Sabi nila, nagpaiwan si {target.name} para makatakas ang iba.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "They say {target.name} stayed behind so others could escape.",
                        },
                        ["TL"] = {
                            "Sabi nila, nagpaiwan si {target.name} para makatakas ang iba.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "death.sacrifice",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "sacrifice",
            ["sourceId"] = "death.sacrifice",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_death/death_sacrifice.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipDeath",
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
            ["metadata"] = {
                ["textKey"] = "death.sacrifice",
                ["textRows"] = {
                    {
                        ["key"] = "death.sacrifice",
                        ["text"] = {
                            ["EN"] = "They say {target.name} stayed behind so others could escape.",
                            ["TL"] = "Sabi nila, nagpaiwan si {target.name} para makatakas ang iba.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "They say {target.name} stayed behind so others could escape.",
                                    },
                                    ["TL"] = {
                                        "Sabi nila, nagpaiwan si {target.name} para makatakas ang iba.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
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
                ["translations"] = {
                    ["EN"] = {
                        "They say {target.name} stayed behind so others could escape.",
                    },
                    ["TL"] = {
                        "Sabi nila, nagpaiwan si {target.name} para makatakas ang iba.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
