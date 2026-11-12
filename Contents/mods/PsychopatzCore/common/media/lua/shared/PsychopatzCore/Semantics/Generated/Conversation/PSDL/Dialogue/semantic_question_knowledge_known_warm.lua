-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_knowledge_facts",
        ["id"] = "semantic.question.knowledge.known.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.knowledge.known.warm",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_facts.json#records[3]",
        },
        ["module"] = "PsychopatzCore/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_knowledge_known_warm",
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
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.known.warm.01",
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
                        ["id"] = "warm.02",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.known.warm.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Yes, I know about {target.name}! Glad you asked.",
                            },
                            ["TL"] = {
                                "Oo, may alam ako tungkol sa {target.name}! Mabuti at nagtanong ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.known.warm.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm happy to share what I know about {target.name}.",
                            },
                            ["TL"] = {
                                "Masaya akong ibahagi sa'yo kung ano ang nalalaman ko sa {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.known.warm.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I do know about {target.name}, friend. Let's discuss it.",
                            },
                            ["TL"] = {
                                "May alam ako sa {target.name}, kaibigan. Pag-usapan natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.known.warm.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm quite familiar with {target.name}. What would you like to know?",
                            },
                            ["TL"] = {
                                "Pamilyar ako sa {target.name}. Ano'ng gusto mong malaman?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.known.warm.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Yes, I've got good knowledge on {target.name}.",
                            },
                            ["TL"] = {
                                "Oo, may magandang kaalaman ako tungkol sa {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.known.warm.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I know {target.name} well! Always happy to talk it through.",
                            },
                            ["TL"] = {
                                "Alam na alam ko ang {target.name}! Laging masayang pag-usapan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.known.warm.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I can definitely fill you in on {target.name}.",
                            },
                            ["TL"] = {
                                "Tiyak na matutulungan kita tungkol sa {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.known.warm.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I know about {target.name}, happy to answer your questions.",
                            },
                            ["TL"] = {
                                "May alam ako sa {target.name}, masayang sagutin ang mga tanong mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.known.warm.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Yes, I'm well acquainted with {target.name}, my friend.",
                            },
                            ["TL"] = {
                                "Oo, kabisado ko ang {target.name}, kaibigan.",
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
