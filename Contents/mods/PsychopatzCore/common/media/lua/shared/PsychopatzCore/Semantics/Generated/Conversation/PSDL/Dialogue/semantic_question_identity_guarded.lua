-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_knowledge_identity",
        ["id"] = "semantic.question.identity.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.identity.guarded",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_identity.json#records[0]",
        },
        ["module"] = "PsychopatzCore/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_identity_guarded",
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
                ["responseTemplateID"] = "semantic.question.identity",
                ["sourceSurface"] = "content/knowledge/identity.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.identity.guarded.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Who's asking? Names can be dangerous out here.",
                            },
                            ["TL"] = {
                                "Sino'ng nagtatanong? Ang mga pangalan ay delikado rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.identity.guarded.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Why do you need to know who I am?",
                            },
                            ["TL"] = {
                                "Bakit kailangan mong malaman kung sino ako?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.identity.guarded.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Just a survivor trying not to die. Leave it at that.",
                            },
                            ["TL"] = {
                                "Survivor lang na sumusubok mabuhay. Hanggang doon na lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.identity.guarded.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I don't give my background to just anyone.",
                            },
                            ["TL"] = {
                                "Hindi ko ibinibigay ang pinagmulan ko sa kahit sino.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.identity.guarded.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "A survivor with a weapon. That's all that matters.",
                            },
                            ["TL"] = {
                                "Isang survivor na may sandata. 'Yon lang ang mahalaga.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.identity.guarded.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't pry into my identity. Keep focused on the road.",
                            },
                            ["TL"] = {
                                "Huwag mong kalkalin ang pagkatao ko. Magpokus sa kalsada.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.identity.guarded.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Names don't keep the infected away. What do you want?",
                            },
                            ["TL"] = {
                                "Hindi itinataboy ng pangalan ang mga infected. Ano'ng gusto mo?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.identity.guarded.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "You don't need my life story to walk beside me.",
                            },
                            ["TL"] = {
                                "Hindi mo kailangan ng kwento ng buhay ko para sumabay sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.identity.guarded.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I keep my identity to myself until I know I can trust you.",
                            },
                            ["TL"] = {
                                "Itinatago ko ang pagkatao ko hangga't hindi kita lubos na pinagkakatiwalaan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.identity.guarded.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I am who I need to be to survive.",
                            },
                            ["TL"] = {
                                "Ako ay kung sino ang kailangan para mabuhay.",
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
