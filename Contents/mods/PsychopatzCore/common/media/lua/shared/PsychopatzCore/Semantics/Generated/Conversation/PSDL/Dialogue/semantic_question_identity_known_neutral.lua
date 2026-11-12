-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_knowledge_identity",
        ["id"] = "semantic.question.identity.known.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.identity.known.neutral",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_identity.json#records[5]",
        },
        ["module"] = "PsychopatzCore/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_identity_known_neutral",
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
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.identity.known.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm {speaker.name}. We already know each other.",
                            },
                            ["TL"] = {
                                "Ako si {speaker.name}. Magkakilala na tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.identity.known.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "My name is {speaker.name}, as you know.",
                            },
                            ["TL"] = {
                                "Ang pangalan ko ay {speaker.name}, tulad ng alam mo na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.identity.known.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm {speaker.name}. We've met before.",
                            },
                            ["TL"] = {
                                "Ako si {speaker.name}. Nagkita na tayo noon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.identity.known.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "It's me, {speaker.name}.",
                            },
                            ["TL"] = {
                                "Ako 'to, si {speaker.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.identity.known.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "You remember me, right? {speaker.name}.",
                            },
                            ["TL"] = {
                                "Naaalala mo ako, di ba? Si {speaker.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.identity.known.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm {speaker.name}. Good to speak with you again.",
                            },
                            ["TL"] = {
                                "Ako si {speaker.name}. Mabuting makausap ka ulit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.identity.known.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still {speaker.name}, same as yesterday.",
                            },
                            ["TL"] = {
                                "{speaker.name} pa rin, tulad kahapon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.identity.known.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm {speaker.name}. We're on the same team.",
                            },
                            ["TL"] = {
                                "Ako si {speaker.name}. Nasa iisang grupo tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.identity.known.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "You know me well enough, I'm {speaker.name}.",
                            },
                            ["TL"] = {
                                "Kilala mo na ako nang maigi, ako si {speaker.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.identity.known.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "It's {speaker.name}. Just checking in?",
                            },
                            ["TL"] = {
                                "Si {speaker.name} 'to. Nangungumusta lang?",
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
