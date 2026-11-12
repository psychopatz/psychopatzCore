-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_knowledge_activity",
        ["id"] = "semantic.question.activity.fishing.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.activity.fishing.guarded",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_activity.json#records[4]",
        },
        ["module"] = "PsychopatzCore/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_question_activity_fishing_guarded",
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
                ["responseTemplateID"] = "semantic.question.activity.fishing",
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
                            ["textKey"] = "semantic.question.activity.fishing.guarded.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Fishing leaves you exposed by the water. Watch your back.",
                            },
                            ["TL"] = {
                                "Nakalantad ka sa tubig kapag nangingisda. Bantayan mo ang likod mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.fishing.guarded.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Water draws the dead. Keep your weapon close while casting.",
                            },
                            ["TL"] = {
                                "Umaakit ng patay ang tubig. Ihanda ang sandata habang naghahagis ng bingwit.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.fishing.guarded.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't get tunnel vision looking at the bobber.",
                            },
                            ["TL"] = {
                                "Huwag matutok sa lumulutang na pamingwit.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.fishing.guarded.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Fish fast and leave. Banks are ambush territory.",
                            },
                            ["TL"] = {
                                "Mangisda nang mabilis at umalis. Lugar ng tambangan ang pampang.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.fishing.guarded.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Quiet catches only. Splashing brings infected.",
                            },
                            ["TL"] = {
                                "Tahimik na huli lang. Ang tilamsik ng tubig ay umaakit ng infected.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.fishing.guarded.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Watch the treeline while you work the line.",
                            },
                            ["TL"] = {
                                "Bantayan ang kakahuyan habang humahawak ng tali.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.fishing.guarded.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "If something rustles in the reeds, drop the rod and draw.",
                            },
                            ["TL"] = {
                                "Kapag may kumaluskos sa talahiban, bitawan ang pamingwit at mag-armas.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.fishing.guarded.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Fishing is risky out here. Keep eyes peeled.",
                            },
                            ["TL"] = {
                                "Delikado ang pangingisda rito. Buksan ang mga mata.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.fishing.guarded.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Get the protein and get off the shore.",
                            },
                            ["TL"] = {
                                "Kunin ang isda at umalis agad sa pampang.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.fishing.guarded.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't get dragged in. Watch the water.",
                            },
                            ["TL"] = {
                                "Huwag magpahila sa tubig. Bantayan ang paligid.",
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
