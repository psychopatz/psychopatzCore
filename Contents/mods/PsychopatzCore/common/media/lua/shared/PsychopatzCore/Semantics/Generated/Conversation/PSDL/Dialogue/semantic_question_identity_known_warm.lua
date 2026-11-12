-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_knowledge_identity",
        ["id"] = "semantic.question.identity.known.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.identity.known.warm",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_identity.json#records[7]",
        },
        ["module"] = "PsychopatzCore/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_identity_known_warm",
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
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.identity.known.warm.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm {speaker.name}. Good to see you again.",
                            },
                            ["TL"] = {
                                "Ako si {speaker.name}. Masayang makita ka ulit.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.identity.known.warm.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "You know it's me, {speaker.name}! Always glad to be by your side.",
                            },
                            ["TL"] = {
                                "Alam mong ako 'to, si {speaker.name}! Laging masayang nasa tabi mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.identity.known.warm.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "It's {speaker.name}, my friend. I'm right here.",
                            },
                            ["TL"] = {
                                "Si {speaker.name} 'to, kaibigan. Nandito lang ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.identity.known.warm.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm {speaker.name}. It's truly a pleasure knowing you.",
                            },
                            ["TL"] = {
                                "Ako si {speaker.name}. Tunay na karangalan ang makilala ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.identity.known.warm.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "You know your friend {speaker.name}. How are you holding up?",
                            },
                            ["TL"] = {
                                "Kilala mo ang kaibigan mong si {speaker.name}. Kamusta ka na?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.identity.known.warm.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Still {speaker.name}, and always here to watch your back.",
                            },
                            ["TL"] = {
                                "{speaker.name} pa rin, at laging nandito para bantayan ang likod mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.identity.known.warm.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "It's me, {speaker.name}. So glad we're traveling together.",
                            },
                            ["TL"] = {
                                "Ako 'to, si {speaker.name}. Masaya akong magkasama tayo sa paglalakbay.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.identity.known.warm.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm {speaker.name}, your companion through all of this.",
                            },
                            ["TL"] = {
                                "Ako si {speaker.name}, ang kasama mo sa lahat ng ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.identity.known.warm.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "You know me, {speaker.name}. Let's keep each other safe.",
                            },
                            ["TL"] = {
                                "Kilala mo ako, si {speaker.name}. Ingatan natin ang isa't isa.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.identity.known.warm.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "It's {speaker.name}! Always happy when you say hello.",
                            },
                            ["TL"] = {
                                "Si {speaker.name} 'to! Laging masaya kapag bumabati ka.",
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
