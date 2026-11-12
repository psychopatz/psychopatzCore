-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_knowledge_identity",
        ["id"] = "semantic.question.identity.known.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.identity.known.terse",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_identity.json#records[6]",
        },
        ["module"] = "PsychopatzCore/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_identity_known_terse",
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
                ["responseTemplateID"] = "semantic.question.identity.known",
                ["sourceSurface"] = "content/knowledge/identity.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.identity.known.terse.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "You know me. I'm {speaker.name}.",
                            },
                            ["TL"] = {
                                "Kilala mo ako. Ako si {speaker.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.identity.known.terse.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm {speaker.name}.",
                            },
                            ["TL"] = {
                                "Ako si {speaker.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.identity.known.terse.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still {speaker.name}.",
                            },
                            ["TL"] = {
                                "{speaker.name} pa rin.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.identity.known.terse.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{speaker.name}. That's me.",
                            },
                            ["TL"] = {
                                "{speaker.name}. Ako 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.identity.known.terse.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "It's {speaker.name}.",
                            },
                            ["TL"] = {
                                "Si {speaker.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.identity.known.terse.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Name's {speaker.name}.",
                            },
                            ["TL"] = {
                                "Pangalan ay {speaker.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.identity.known.terse.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Me. {speaker.name}.",
                            },
                            ["TL"] = {
                                "Ako. Si {speaker.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.identity.known.terse.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Remember? {speaker.name}.",
                            },
                            ["TL"] = {
                                "Tanda mo? Si {speaker.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.identity.known.terse.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Just {speaker.name}.",
                            },
                            ["TL"] = {
                                "Si {speaker.name} lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.identity.known.terse.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{speaker.name}.",
                            },
                            ["TL"] = {
                                "{speaker.name}.",
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
        ["sourceShard"] = "psdl/dialogue/core_knowledge_identity.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
