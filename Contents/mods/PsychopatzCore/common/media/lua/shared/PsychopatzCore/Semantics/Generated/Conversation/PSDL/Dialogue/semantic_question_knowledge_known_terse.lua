-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_knowledge_facts",
        ["id"] = "semantic.question.knowledge.known.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.knowledge.known.terse",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_facts.json#records[2]",
        },
        ["module"] = "PsychopatzCore/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_knowledge_known_terse",
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
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.known.terse.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I know {target.name}.",
                            },
                            ["TL"] = {
                                "Alam ko ang {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.known.terse.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Know it: {target.name}.",
                            },
                            ["TL"] = {
                                "Alam ko: {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.known.terse.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Aware of {target.name}.",
                            },
                            ["TL"] = {
                                "Batid ang {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.known.terse.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Familiar with {target.name}.",
                            },
                            ["TL"] = {
                                "Pamilyar sa {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.known.terse.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Yes, {target.name}.",
                            },
                            ["TL"] = {
                                "Oo, {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.known.terse.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Heard of {target.name}.",
                            },
                            ["TL"] = {
                                "Narinig ang {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.known.terse.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Got info on {target.name}.",
                            },
                            ["TL"] = {
                                "May balita sa {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.known.terse.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Understood: {target.name}.",
                            },
                            ["TL"] = {
                                "Naintindihan: {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.known.terse.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Already know {target.name}.",
                            },
                            ["TL"] = {
                                "Alam na ang {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.known.terse.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Clear on {target.name}.",
                            },
                            ["TL"] = {
                                "Malinaw sa {target.name}.",
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
