-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_knowledge_gossip",
        ["id"] = "semantic.gossip.unknown.bond_guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.gossip.unknown.bond_guarded",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_gossip.json#records[0]",
        },
        ["module"] = "PsychopatzCore/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_gossip_unknown_bond_guarded",
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
                ["category"] = "psychopatzcore:knowledge",
                ["responseTemplateID"] = "semantic.gossip.unknown",
                ["sourceSurface"] = "content/knowledge/gossip.json",
                ["style"] = "bond_guarded",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "bond_guarded.01",
                        ["metadata"] = {
                            ["style"] = "bond_guarded",
                            ["textKey"] = "semantic.gossip.unknown.bond_guarded.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, I don't have anything to share.",
                            },
                            ["TL"] = {
                                "{addressee.name}, wala akong maibabahagi sa'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.02",
                        ["metadata"] = {
                            ["style"] = "bond_guarded",
                            ["textKey"] = "semantic.gossip.unknown.bond_guarded.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, haven't heard any reliable rumors.",
                            },
                            ["TL"] = {
                                "{addressee.name}, wala akong naririnig na maaasahang balita.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.03",
                        ["metadata"] = {
                            ["style"] = "bond_guarded",
                            ["textKey"] = "semantic.gossip.unknown.bond_guarded.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Keep your head down, {addressee.name}. No news out there.",
                            },
                            ["TL"] = {
                                "Mag-ingat ka, {addressee.name}. Walang balita sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.04",
                        ["metadata"] = {
                            ["style"] = "bond_guarded",
                            ["textKey"] = "semantic.gossip.unknown.bond_guarded.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, nothing trustworthy has reached my ears.",
                            },
                            ["TL"] = {
                                "{addressee.name}, walang mapagkakatiwalaang balitang nakarating sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.05",
                        ["metadata"] = {
                            ["style"] = "bond_guarded",
                            ["textKey"] = "semantic.gossip.unknown.bond_guarded.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Not much word going around, {addressee.name}.",
                            },
                            ["TL"] = {
                                "{addressee.name}, walang gaanong kumakalat na balita.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.06",
                        ["metadata"] = {
                            ["style"] = "bond_guarded",
                            ["textKey"] = "semantic.gossip.unknown.bond_guarded.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, gossip gets people killed. I have none.",
                            },
                            ["TL"] = {
                                "{addressee.name}, ang tsismis ay nakakamatay. Wala ako no'n.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.07",
                        ["metadata"] = {
                            ["style"] = "bond_guarded",
                            ["textKey"] = "semantic.gossip.unknown.bond_guarded.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Nothing to report, {addressee.name}. Stay on your guard.",
                            },
                            ["TL"] = {
                                "Walang maiuulat, {addressee.name}. Manatiling alerto.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.08",
                        ["metadata"] = {
                            ["style"] = "bond_guarded",
                            ["textKey"] = "semantic.gossip.unknown.bond_guarded.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, nobody's talking about anything useful.",
                            },
                            ["TL"] = {
                                "{addressee.name}, walang nag-uusap ng anumang kapaki-pakinabang.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.09",
                        ["metadata"] = {
                            ["style"] = "bond_guarded",
                            ["textKey"] = "semantic.gossip.unknown.bond_guarded.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I haven't heard any safe news, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Wala akong naririnig na ligtas na balita, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.10",
                        ["metadata"] = {
                            ["style"] = "bond_guarded",
                            ["textKey"] = "semantic.gossip.unknown.bond_guarded.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, keep to our business. No rumors here.",
                            },
                            ["TL"] = {
                                "{addressee.name}, magpokus tayo sa sarili natin. Walang tsismis dito.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_knowledge_gossip.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
