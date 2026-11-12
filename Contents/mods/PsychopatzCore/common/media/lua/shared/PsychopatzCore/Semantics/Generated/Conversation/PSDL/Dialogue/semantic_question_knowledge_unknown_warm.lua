-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_knowledge_facts",
        ["id"] = "semantic.question.knowledge.unknown.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.knowledge.unknown.warm",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_facts.json#records[7]",
        },
        ["module"] = "PsychopatzCore/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_knowledge_unknown_warm",
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
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.unknown.warm.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I wish I knew, but I don't know anything about that.",
                            },
                            ["TL"] = {
                                "Sana may alam ako, pero wala akong alam tungkol diyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.unknown.warm.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm sorry, friend, I haven't heard about that.",
                            },
                            ["TL"] = {
                                "Pasensya na, kaibigan, wala akong narinig tungkol diyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.unknown.warm.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I wish I could help you with that, but I'm unfamiliar.",
                            },
                            ["TL"] = {
                                "Gusto sana kitang tulungan diyan, pero hindi ako pamilyar.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.unknown.warm.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I don't know, but we can try to find out together.",
                            },
                            ["TL"] = {
                                "Hindi ko alam, pero pwede nating alamin nang magkasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.unknown.warm.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Sorry I can't be more helpful on that topic.",
                            },
                            ["TL"] = {
                                "Pasensya na kung hindi ako masyadong makatulong sa paksang 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.unknown.warm.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "That's new to me! I wish I had more answers for you.",
                            },
                            ["TL"] = {
                                "Bago 'yan sa akin! Sana may mga sagot ako para sa'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.unknown.warm.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I haven't learned about that yet, my friend.",
                            },
                            ["TL"] = {
                                "Hindi ko pa natututunan 'yan, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.unknown.warm.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Wish I could answer that, but I'm in the dark too.",
                            },
                            ["TL"] = {
                                "Sana masasagot ko 'yan, pero wala rin akong alam.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.unknown.warm.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I don't know about that, but let's keep learning together.",
                            },
                            ["TL"] = {
                                "Hindi ko alam 'yan, pero magkasama tayong mag-aral.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.unknown.warm.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Sorry to disappoint, but that's unfamiliar to me.",
                            },
                            ["TL"] = {
                                "Pasensya na kung mabigo kita, pero hindi ako pamilyar diyan.",
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
