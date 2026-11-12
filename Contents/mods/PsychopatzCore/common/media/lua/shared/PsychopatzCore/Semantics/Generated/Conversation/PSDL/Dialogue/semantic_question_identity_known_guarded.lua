-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_knowledge_identity",
        ["id"] = "semantic.question.identity.known.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.identity.known.guarded",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_identity.json#records[4]",
        },
        ["module"] = "PsychopatzCore/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_identity_known_guarded",
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
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.identity.known.guarded.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm {speaker.name}. You should already know that.",
                            },
                            ["TL"] = {
                                "Ako si {speaker.name}. Dapat alam mo na 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.identity.known.guarded.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "It's {speaker.name}. Don't act like you forgot.",
                            },
                            ["TL"] = {
                                "Si {speaker.name} 'to. Huwag kang umastang nakalimot ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.identity.known.guarded.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "You know my name, {speaker.name}. Don't play games.",
                            },
                            ["TL"] = {
                                "Alam mo ang pangalan ko, si {speaker.name}. Huwag kang makipaglaro.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.identity.known.guarded.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still {speaker.name}. Nothing has changed.",
                            },
                            ["TL"] = {
                                "{speaker.name} pa rin. Walang nagbago.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.identity.known.guarded.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm {speaker.name}. Stop asking questions you know the answers to.",
                            },
                            ["TL"] = {
                                "Ako si {speaker.name}. Tigilan mo ang pagtatanong sa alam mo na ang sagot.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.identity.known.guarded.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Name's {speaker.name}. Keep your head focused on our perimeter.",
                            },
                            ["TL"] = {
                                "Pangalan ko ay {speaker.name}. Ituon ang isip sa paligid natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.identity.known.guarded.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I am {speaker.name}. We've walked together long enough for you to know.",
                            },
                            ["TL"] = {
                                "Ako si {speaker.name}. Matagal na tayong magkasama para malaman mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.identity.known.guarded.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still {speaker.name}. Keep your eyes sharp.",
                            },
                            ["TL"] = {
                                "{speaker.name} pa rin. Maging matalas ang paningin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.identity.known.guarded.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "You know me, {speaker.name}. What's the real question?",
                            },
                            ["TL"] = {
                                "Kilala mo ako, si {speaker.name}. Ano ang totoong tanong mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.identity.known.guarded.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm {speaker.name}. Let's get back to surviving.",
                            },
                            ["TL"] = {
                                "Ako si {speaker.name}. Bumalik na tayo sa kaligtasan.",
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
