-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_knowledge_facts",
        ["id"] = "semantic.question.knowledge.unknown.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.knowledge.unknown.terse",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_facts.json#records[6]",
        },
        ["module"] = "PsychopatzCore/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_knowledge_unknown_terse",
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
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.unknown.terse.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't know.",
                            },
                            ["TL"] = {
                                "Hindi alam.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.unknown.terse.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No idea.",
                            },
                            ["TL"] = {
                                "Walang ideya.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.unknown.terse.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Unfamiliar.",
                            },
                            ["TL"] = {
                                "Hindi pamilyar.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.unknown.terse.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Never heard of it.",
                            },
                            ["TL"] = {
                                "Hindi narinig.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.unknown.terse.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can't say.",
                            },
                            ["TL"] = {
                                "Hindi masabi.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.unknown.terse.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Unknown.",
                            },
                            ["TL"] = {
                                "Hindi batid.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.unknown.terse.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No clue.",
                            },
                            ["TL"] = {
                                "Walang muwang.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.unknown.terse.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Not a clue.",
                            },
                            ["TL"] = {
                                "Wala talaga.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.unknown.terse.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Nothing.",
                            },
                            ["TL"] = {
                                "Wala.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.unknown.terse.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Blank on that.",
                            },
                            ["TL"] = {
                                "Walang alam.",
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
