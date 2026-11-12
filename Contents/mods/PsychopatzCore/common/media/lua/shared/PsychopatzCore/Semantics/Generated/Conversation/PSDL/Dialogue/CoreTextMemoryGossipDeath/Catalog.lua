-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_text_memory_gossip_death",
        ["id"] = "text.death.report",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "text.death.report",
            ["sourcePath"] = "psdl/dialogue/core_text_memory_gossip_death.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CoreTextMemoryGossipDeath/Catalog",
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
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.memory.gossip.death.report",
                ["sourcePath"] = "memory/gossip/death/report.json",
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
            ["text"] = {
                ["EN"] = {
                    "I heard {target.name} did not make it back.",
                },
                ["TL"] = {
                    "Balita ko, hindi na nakabalik si {target.name}.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.death.report",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I heard {target.name} did not make it back.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.death.report.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_memory_gossip_death.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_death",
        ["id"] = "text.death.sacrifice",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "text.death.sacrifice",
            ["sourcePath"] = "psdl/dialogue/core_text_memory_gossip_death.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CoreTextMemoryGossipDeath/Catalog",
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
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.memory.gossip.death.sacrifice",
                ["sourcePath"] = "memory/gossip/death/sacrifice.json",
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
            ["text"] = {
                ["EN"] = {
                    "They say {target.name} stayed behind so others could escape.",
                },
                ["TL"] = {
                    "Sabi nila, nagpaiwan si {target.name} para makatakas ang iba.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.death.sacrifice",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "They say {target.name} stayed behind so others could escape.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.death.sacrifice.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_memory_gossip_death.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["when"] = nil,
    },
}
