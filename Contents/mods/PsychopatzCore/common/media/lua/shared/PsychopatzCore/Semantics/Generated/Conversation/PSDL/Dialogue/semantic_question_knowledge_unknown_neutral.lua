-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_knowledge_facts",
        ["id"] = "semantic.question.knowledge.unknown.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.knowledge.unknown.neutral",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_facts.json#records[5]",
        },
        ["module"] = "PsychopatzCore/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_knowledge_unknown_neutral",
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
                ["responseTemplateID"] = "semantic.question.knowledge.unknown",
                ["sourceSurface"] = "content/knowledge/knowledge.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.unknown.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I don't have reliable information about that.",
                            },
                            ["TL"] = {
                                "Wala akong maaasahang impormasyon tungkol diyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.unknown.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm not familiar with that subject.",
                            },
                            ["TL"] = {
                                "Hindi ako pamilyar sa paksang iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.unknown.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I haven't encountered that information before.",
                            },
                            ["TL"] = {
                                "Hindi ko pa nalaman ang impormasyong iyon noon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.unknown.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I have no knowledge on that matter.",
                            },
                            ["TL"] = {
                                "Wala akong kaalaman sa bagay na iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.unknown.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "That's unfamiliar to me, sorry.",
                            },
                            ["TL"] = {
                                "Bago 'yan sa akin, pasensya na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.unknown.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I can't answer that. I simply don't know.",
                            },
                            ["TL"] = {
                                "Hindi ko masasagot 'yan. Talagang hindi ko alam.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.unknown.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Haven't come across that in my travels.",
                            },
                            ["TL"] = {
                                "Hindi ko pa 'yan nasalubong sa paglalakbay ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.unknown.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I don't have the answers on that one.",
                            },
                            ["TL"] = {
                                "Wala sa akin ang mga sagot tungkol diyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.unknown.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm unaware of that topic.",
                            },
                            ["TL"] = {
                                "Wala akong kamalayan sa paksang iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.unknown.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Sorry, that's outside my knowledge.",
                            },
                            ["TL"] = {
                                "Pasensya na, labas 'yan sa kaalaman ko.",
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
        ["sourceShard"] = "psdl/dialogue/core_knowledge_facts.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
