-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_knowledge_gossip",
        ["id"] = "semantic.gossip.unknown.bond_terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.gossip.unknown.bond_terse",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_gossip.json#records[2]",
        },
        ["module"] = "PsychopatzCore/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_gossip_unknown_bond_terse",
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
                ["style"] = "bond_terse",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "bond_terse.01",
                        ["metadata"] = {
                            ["style"] = "bond_terse",
                            ["textKey"] = "semantic.gossip.unknown.bond_terse.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, no news.",
                            },
                            ["TL"] = {
                                "{addressee.name}, walang balita.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.02",
                        ["metadata"] = {
                            ["style"] = "bond_terse",
                            ["textKey"] = "semantic.gossip.unknown.bond_terse.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Nothing, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Wala, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.03",
                        ["metadata"] = {
                            ["style"] = "bond_terse",
                            ["textKey"] = "semantic.gossip.unknown.bond_terse.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, heard nothing.",
                            },
                            ["TL"] = {
                                "{addressee.name}, walang narinig.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.04",
                        ["metadata"] = {
                            ["style"] = "bond_terse",
                            ["textKey"] = "semantic.gossip.unknown.bond_terse.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Quiet, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Tahimik, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.05",
                        ["metadata"] = {
                            ["style"] = "bond_terse",
                            ["textKey"] = "semantic.gossip.unknown.bond_terse.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, no rumors.",
                            },
                            ["TL"] = {
                                "{addressee.name}, walang tsismis.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.06",
                        ["metadata"] = {
                            ["style"] = "bond_terse",
                            ["textKey"] = "semantic.gossip.unknown.bond_terse.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No word, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Walang balita, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.07",
                        ["metadata"] = {
                            ["style"] = "bond_terse",
                            ["textKey"] = "semantic.gossip.unknown.bond_terse.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, all quiet.",
                            },
                            ["TL"] = {
                                "{addressee.name}, tahimik lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.08",
                        ["metadata"] = {
                            ["style"] = "bond_terse",
                            ["textKey"] = "semantic.gossip.unknown.bond_terse.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Nothing to share, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Walang maibabahagi, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.09",
                        ["metadata"] = {
                            ["style"] = "bond_terse",
                            ["textKey"] = "semantic.gossip.unknown.bond_terse.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, zero news.",
                            },
                            ["TL"] = {
                                "{addressee.name}, walang balita.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.10",
                        ["metadata"] = {
                            ["style"] = "bond_terse",
                            ["textKey"] = "semantic.gossip.unknown.bond_terse.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Blank slate, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Walang anuman, {addressee.name}.",
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
