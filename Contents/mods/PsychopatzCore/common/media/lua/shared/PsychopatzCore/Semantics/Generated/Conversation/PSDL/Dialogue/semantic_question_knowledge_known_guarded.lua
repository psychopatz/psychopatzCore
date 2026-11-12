-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_knowledge_facts",
        ["id"] = "semantic.question.knowledge.known.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.knowledge.known.guarded",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_facts.json#records[0]",
        },
        ["module"] = "PsychopatzCore/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_knowledge_known_guarded",
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
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.known.guarded.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I know enough about {target.name}.",
                            },
                            ["TL"] = {
                                "Sapat ang alam ko tungkol sa {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.known.guarded.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm aware of {target.name}, but keep it quiet.",
                            },
                            ["TL"] = {
                                "Alam ko ang {target.name}, pero huwag mong ipagsabi.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.known.guarded.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I know about {target.name}. Don't shout it out.",
                            },
                            ["TL"] = {
                                "May alam ako sa {target.name}. Huwag mong ipagsigawan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.known.guarded.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Yes, I know {target.name}. What of it?",
                            },
                            ["TL"] = {
                                "Oo, alam ko ang {target.name}. Ano naman?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.known.guarded.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I have information on {target.name}. Keep your voice down.",
                            },
                            ["TL"] = {
                                "Nasa akin ang impormasyon sa {target.name}. Hinaan mo ang boses mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.known.guarded.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I know what {target.name} is. Be cautious.",
                            },
                            ["TL"] = {
                                "Alam ko kung ano ang {target.name}. Mag-ingat ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.known.guarded.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm familiar with {target.name}. Don't spread it around.",
                            },
                            ["TL"] = {
                                "Pamilyar ako sa {target.name}. Huwag mong ikalat.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.known.guarded.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Yes, I know {target.name}. It's dangerous knowledge.",
                            },
                            ["TL"] = {
                                "Oo, alam ko ang {target.name}. Delikadong kaalaman 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.known.guarded.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I know about {target.name}. Keep it between us.",
                            },
                            ["TL"] = {
                                "May alam ako tungkol sa {target.name}. Atin-atin lang 'to.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.known.guarded.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Yes, I'm aware of {target.name}. Don't bring trouble our way.",
                            },
                            ["TL"] = {
                                "Oo, alam ko ang tungkol sa {target.name}. Huwag kang magdala ng gulo sa atin.",
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
