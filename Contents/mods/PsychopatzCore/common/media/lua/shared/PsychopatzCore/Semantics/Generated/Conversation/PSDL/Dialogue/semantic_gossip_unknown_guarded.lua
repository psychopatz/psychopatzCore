-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_knowledge_gossip",
        ["id"] = "semantic.gossip.unknown.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.gossip.unknown.guarded",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_gossip.json#records[4]",
        },
        ["module"] = "PsychopatzCore/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_gossip_unknown_guarded",
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
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.gossip.unknown.guarded.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I don't have anything to share.",
                            },
                            ["TL"] = {
                                "Wala akong maibabahagi sa'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.gossip.unknown.guarded.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I don't traffic in rumors. Keep moving.",
                            },
                            ["TL"] = {
                                "Hindi ako nakikipagtsismisan. Lakad na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.gossip.unknown.guarded.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No news worth risking our necks over.",
                            },
                            ["TL"] = {
                                "Walang balitang karapat-dapat ipagsapalaran ang buhay natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.gossip.unknown.guarded.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I keep my ears open for danger, not talk.",
                            },
                            ["TL"] = {
                                "Bukas ang tenga ko sa panganib, hindi sa kwento.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.gossip.unknown.guarded.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Haven't heard anything reliable. Watch yourself.",
                            },
                            ["TL"] = {
                                "Wala akong narinig na mapagkakatiwalaan. Mag-ingat ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.gossip.unknown.guarded.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Rumors are cheap and usually wrong. Nothing to say.",
                            },
                            ["TL"] = {
                                "Mura ang tsismis at kadalasang mali. Walang masasabi.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.gossip.unknown.guarded.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I don't listen to chatter. Mind your business.",
                            },
                            ["TL"] = {
                                "Hindi ako nakikinig sa daldalan. Asikasuhin mo ang sarili mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.gossip.unknown.guarded.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No word that concerns you.",
                            },
                            ["TL"] = {
                                "Walang balitang may kinalaman sa'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.gossip.unknown.guarded.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Nothing to share. Keep your guard up.",
                            },
                            ["TL"] = {
                                "Walang maibabahagi. Panatilihing mataas ang depensa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.gossip.unknown.guarded.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't ask me for gossip.",
                            },
                            ["TL"] = {
                                "Huwag kang magtanong sa akin ng tsismis.",
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
