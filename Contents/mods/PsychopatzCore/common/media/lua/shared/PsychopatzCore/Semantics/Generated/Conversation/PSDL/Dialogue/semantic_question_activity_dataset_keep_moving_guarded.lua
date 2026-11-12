-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_knowledge_activity",
        ["id"] = "semantic.question.activity.dataset.keep_moving.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.activity.dataset.keep_moving.guarded",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_activity.json#records[0]",
        },
        ["module"] = "PsychopatzCore/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_activity_dataset_keep_moving_guarded",
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
                ["responseTemplateID"] = "semantic.question.activity.dataset.keep_moving",
                ["sourceSurface"] = "content/knowledge/activity.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.guarded.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "We need to keep moving. Sitting still will get us killed.",
                            },
                            ["TL"] = {
                                "Kailangan nating magpatuloy sa paglakad. Mamamatay tayo kapag tumigil dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.guarded.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't loiter. The dead migrate toward stillness.",
                            },
                            ["TL"] = {
                                "Huwag tatambay. Dumarating ang mga patay kapag nanahimik.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.guarded.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Keep your boots moving. Danger is everywhere.",
                            },
                            ["TL"] = {
                                "Igalaw ang mga paa mo. Nasa paligid ang panganib.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.guarded.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "We stay on the road. Tarrying is suicide.",
                            },
                            ["TL"] = {
                                "Manatili tayo sa kalsada. Pagpapatiwakal ang pag-aaksaya ng oras.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.guarded.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Keep moving. Eyes on the woodline.",
                            },
                            ["TL"] = {
                                "Tuloy ang lakad. Tumingin sa kakahuyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.guarded.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No resting in the open. Walk.",
                            },
                            ["TL"] = {
                                "Walang pahinga sa lantad na lugar. Lakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.guarded.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Movement keeps us alive. Don't freeze up.",
                            },
                            ["TL"] = {
                                "Pagkilos ang bumubuhay sa atin. Huwag matulala.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.guarded.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Keep marching. We're too exposed right here.",
                            },
                            ["TL"] = {
                                "Magmartsa pa. Masyado tayong lantad dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.guarded.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Keep going. Resting here is asking for trouble.",
                            },
                            ["TL"] = {
                                "Tuloy lang. Naghahanap ka ng gulo kapag nagpahinga ka rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.guarded.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Step lively. A static survivor is a dead survivor.",
                            },
                            ["TL"] = {
                                "Bilis-bilisan ang hakbang. Ang nakatayong survivor ay patay na survivor.",
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
        ["sourceShard"] = "psdl/dialogue/core_knowledge_activity.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
