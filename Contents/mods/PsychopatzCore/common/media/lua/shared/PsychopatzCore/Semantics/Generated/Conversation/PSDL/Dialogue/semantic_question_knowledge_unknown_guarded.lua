-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_knowledge_facts",
        ["id"] = "semantic.question.knowledge.unknown.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.knowledge.unknown.guarded",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_facts.json#records[4]",
        },
        ["module"] = "PsychopatzCore/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_knowledge_unknown_guarded",
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
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.unknown.guarded.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I don't know anything about that.",
                            },
                            ["TL"] = {
                                "Wala akong alam tungkol diyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.unknown.guarded.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Haven't heard of it. Don't waste time on wild goose chases.",
                            },
                            ["TL"] = {
                                "Hindi ko narinig 'yan. Huwag magsayang ng oras sa walang kabuluhan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.unknown.guarded.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No idea. Keep your thoughts on what's in front of us.",
                            },
                            ["TL"] = {
                                "Walang ideya. Ituon ang isip sa kung ano ang nasa harap natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.unknown.guarded.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I know nothing about that topic. Drop it.",
                            },
                            ["TL"] = {
                                "Wala akong alam sa paksang 'yan. Kalimutan mo na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.unknown.guarded.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Never crossed my path. Stay alert.",
                            },
                            ["TL"] = {
                                "Hindi pa dumaan sa akin 'yan. Maging alerto.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.unknown.guarded.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can't help you there. Don't get distracted.",
                            },
                            ["TL"] = {
                                "Hindi kita matutulungan diyan. Huwag mawala sa pokus.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.unknown.guarded.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm in the dark on that. Watch the road.",
                            },
                            ["TL"] = {
                                "Wala akong alam diyan. Bantayan ang daan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.unknown.guarded.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No clue. Don't go looking for things that aren't there.",
                            },
                            ["TL"] = {
                                "Walang ideya. Huwag maghanap ng mga bagay na wala naman.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.unknown.guarded.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Nothing I've ever encountered. Move along.",
                            },
                            ["TL"] = {
                                "Hindi ko pa kailanman nakaharap 'yan. Tuloy sa lakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.unknown.guarded.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I don't know and I don't care to guess.",
                            },
                            ["TL"] = {
                                "Hindi ko alam at ayaw kong manghula.",
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
