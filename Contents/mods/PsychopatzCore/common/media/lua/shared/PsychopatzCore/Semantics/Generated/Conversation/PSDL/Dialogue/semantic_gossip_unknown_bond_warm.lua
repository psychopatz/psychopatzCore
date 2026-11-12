-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_knowledge_gossip",
        ["id"] = "semantic.gossip.unknown.bond_warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.gossip.unknown.bond_warm",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_gossip.json#records[3]",
        },
        ["module"] = "PsychopatzCore/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_gossip_unknown_bond_warm",
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
                ["style"] = "bond_warm",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "bond_warm.01",
                        ["metadata"] = {
                            ["style"] = "bond_warm",
                            ["textKey"] = "semantic.gossip.unknown.bond_warm.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, I haven't heard any news, sorry.",
                            },
                            ["TL"] = {
                                "{addressee.name}, wala akong narinig na balita, pasensya na.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.02",
                        ["metadata"] = {
                            ["style"] = "bond_warm",
                            ["textKey"] = "semantic.gossip.unknown.bond_warm.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Wish I had something to tell you, {addressee.name}, but it's quiet.",
                            },
                            ["TL"] = {
                                "Sana may maikwento ako sa'yo, {addressee.name}, pero tahimik ang paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.03",
                        ["metadata"] = {
                            ["style"] = "bond_warm",
                            ["textKey"] = "semantic.gossip.unknown.bond_warm.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, haven't heard a peep from the other camps.",
                            },
                            ["TL"] = {
                                "{addressee.name}, wala akong narinig kahit kaunti mula sa ibang kampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.04",
                        ["metadata"] = {
                            ["style"] = "bond_warm",
                            ["textKey"] = "semantic.gossip.unknown.bond_warm.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Sorry, {addressee.name}, no interesting stories today.",
                            },
                            ["TL"] = {
                                "Pasensya na, {addressee.name}, walang magagandang kwento ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.05",
                        ["metadata"] = {
                            ["style"] = "bond_warm",
                            ["textKey"] = "semantic.gossip.unknown.bond_warm.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, I'll definitely share the moment I hear anything.",
                            },
                            ["TL"] = {
                                "{addressee.name}, ibabahagi ko agad kapag may narinig ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.06",
                        ["metadata"] = {
                            ["style"] = "bond_warm",
                            ["textKey"] = "semantic.gossip.unknown.bond_warm.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Nothing new reaching my ears, {addressee.name}. Hope you're well.",
                            },
                            ["TL"] = {
                                "Walang bagong dumarating sa akin, {addressee.name}. Sana ayos ka lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.07",
                        ["metadata"] = {
                            ["style"] = "bond_warm",
                            ["textKey"] = "semantic.gossip.unknown.bond_warm.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, all's quiet on my end, my friend.",
                            },
                            ["TL"] = {
                                "{addressee.name}, tahimik ang lahat sa panig ko, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.08",
                        ["metadata"] = {
                            ["style"] = "bond_warm",
                            ["textKey"] = "semantic.gossip.unknown.bond_warm.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Haven't caught any rumors, {addressee.name}, but I'll keep listening.",
                            },
                            ["TL"] = {
                                "Walang nasagap na tsismis, {addressee.name}, pero patuloy akong makikinig.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.09",
                        ["metadata"] = {
                            ["style"] = "bond_warm",
                            ["textKey"] = "semantic.gossip.unknown.bond_warm.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, nothing yet, but stay safe out there.",
                            },
                            ["TL"] = {
                                "{addressee.name}, wala pa sa ngayon, pero mag-ingat ka sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.10",
                        ["metadata"] = {
                            ["style"] = "bond_warm",
                            ["textKey"] = "semantic.gossip.unknown.bond_warm.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'd love to share news with you, {addressee.name}, but nothing yet.",
                            },
                            ["TL"] = {
                                "Gusto ko sanang magbahagi ng balita sa'yo, {addressee.name}, pero wala pa.",
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
