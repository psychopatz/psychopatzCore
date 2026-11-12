-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_knowledge_facts",
        ["id"] = "semantic.question.knowledge.known.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.knowledge.known.neutral",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_facts.json#records[1]",
        },
        ["module"] = "PsychopatzCore/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_knowledge_known_neutral",
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
                ["responseTemplateID"] = "semantic.question.knowledge.known",
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
                            ["textKey"] = "semantic.question.knowledge.known.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I know about {target.name}.",
                            },
                            ["TL"] = {
                                "May alam ako tungkol sa {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.known.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Yes, I know about {target.name}.",
                            },
                            ["TL"] = {
                                "Oo, may alam ako tungkol sa {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.known.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm familiar with {target.name}.",
                            },
                            ["TL"] = {
                                "Pamilyar ako sa {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.known.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I have knowledge of {target.name}.",
                            },
                            ["TL"] = {
                                "May kaalaman ako sa {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.known.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Yes, I understand about {target.name}.",
                            },
                            ["TL"] = {
                                "Oo, nauunawaan ko ang tungkol sa {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.known.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm aware of {target.name}.",
                            },
                            ["TL"] = {
                                "Batid ko ang tungkol sa {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.known.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I know the situation with {target.name}.",
                            },
                            ["TL"] = {
                                "Alam ko ang sitwasyon sa {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.known.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Information on {target.name} is known to me.",
                            },
                            ["TL"] = {
                                "Batid ko ang impormasyon sa {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.known.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Yes, I've learned about {target.name} already.",
                            },
                            ["TL"] = {
                                "Oo, nalaman ko na ang tungkol sa {target.name} noon pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.known.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I have reliable word on {target.name}.",
                            },
                            ["TL"] = {
                                "Maaasahan ang balita ko tungkol sa {target.name}.",
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
