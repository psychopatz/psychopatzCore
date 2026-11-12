-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_check_in",
        ["id"] = "social.core_check_in",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "social.core_check_in",
            ["sourcePath"] = "psdl/dialogue/core_check_in.json",
        },
        ["module"] = "PsychopatzCore/Semantics/Generated/Conversation/PSDL/Dialogue/social_core_check_in",
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
                ["textNamespace"] = "UI_PNC_Conversation_Suggestion",
            },
            ["offers"] = {
                {
                    ["consumers"] = {
                        "participant",
                    },
                    ["frame"] = {
                        ["extensions"] = {
                            ["topic"] = "activity",
                        },
                        ["hubID"] = "whats_up",
                        ["hubOnly"] = true,
                        ["intent"] = "QUESTION",
                        ["patternID"] = "pnc.question.activity",
                        ["speechAct"] = "QUESTION",
                        ["subject"] = "ACTIVITY",
                        ["topic"] = "activity",
                    },
                    ["id"] = "question.activity",
                    ["label"] = {
                        ["EN"] = {
                            "Ask what they've been doing",
                        },
                        ["TL"] = {
                            "Itanong ang pinagkakaabalahan",
                        },
                    },
                    ["metadata"] = {
                        ["domain"] = "activity",
                        ["order"] = 60,
                    },
                    ["utterance"] = {
                        ["EN"] = {
                            "What have you been doing?",
                        },
                        ["TL"] = {
                            "Ano ang mga pinagkakaabalahan mo?",
                        },
                    },
                },
                {
                    ["consumers"] = {
                        "participant",
                    },
                    ["frame"] = {
                        ["intent"] = "QUESTION",
                        ["patternID"] = "pnc.question.date",
                        ["speechAct"] = "QUESTION",
                        ["subject"] = "DATE",
                        ["topic"] = "date",
                    },
                    ["id"] = "question.date",
                    ["label"] = {
                        ["EN"] = {
                            "Ask about the date",
                        },
                        ["TL"] = {
                            "Itanong ang petsa",
                        },
                    },
                    ["metadata"] = {
                        ["domain"] = "date",
                        ["order"] = 70,
                    },
                    ["utterance"] = {
                        ["EN"] = {
                            "What's today's date?",
                        },
                        ["TL"] = {
                            "Ano ang petsa ngayon?",
                        },
                    },
                },
                {
                    ["consumers"] = {
                        "participant",
                    },
                    ["frame"] = {
                        ["intent"] = "QUESTION",
                        ["patternID"] = "pnc.question.time",
                        ["speechAct"] = "QUESTION",
                        ["subject"] = "TIME",
                        ["topic"] = "time",
                    },
                    ["id"] = "question.time",
                    ["label"] = {
                        ["EN"] = {
                            "Ask about the time",
                        },
                        ["TL"] = {
                            "Itanong ang oras",
                        },
                    },
                    ["metadata"] = {
                        ["domain"] = "time",
                        ["order"] = 60,
                    },
                    ["utterance"] = {
                        ["EN"] = {
                            "What time is it?",
                        },
                        ["TL"] = {
                            "Anong oras na?",
                        },
                    },
                },
                {
                    ["consumers"] = {
                        "participant",
                    },
                    ["frame"] = {
                        ["hubID"] = "whats_up",
                        ["hubOnly"] = true,
                        ["intent"] = "QUESTION",
                        ["patternID"] = "pnc.question.weather",
                        ["speechAct"] = "QUESTION",
                        ["subject"] = "WEATHER",
                        ["topic"] = "weather",
                    },
                    ["id"] = "question.weather",
                    ["label"] = {
                        ["EN"] = {
                            "Ask about the weather",
                        },
                        ["TL"] = {
                            "Itanong ang panahon",
                        },
                    },
                    ["metadata"] = {
                        ["domain"] = "weather",
                        ["order"] = 80,
                    },
                    ["utterance"] = {
                        ["EN"] = {
                            "How is the weather?",
                        },
                        ["TL"] = {
                            "Kumusta ang panahon?",
                        },
                    },
                },
                {
                    ["consumers"] = {
                        "participant",
                    },
                    ["frame"] = {
                        ["hubID"] = "whats_up",
                        ["hubOnly"] = true,
                        ["intent"] = "QUESTION",
                        ["patternID"] = "pnc.question.wellbeing_feeling",
                        ["speechAct"] = "QUESTION",
                        ["subject"] = "WELLBEING",
                        ["topic"] = "wellbeing",
                    },
                    ["id"] = "question.wellbeing",
                    ["label"] = {
                        ["EN"] = {
                            "Ask about wellbeing",
                        },
                        ["TL"] = {
                            "Itanong ang kalagayan",
                        },
                    },
                    ["metadata"] = {
                        ["domain"] = "wellbeing",
                        ["order"] = 10,
                    },
                    ["utterance"] = {
                        ["EN"] = {
                            "How are you feeling?",
                        },
                        ["TL"] = {
                            "Kumusta ang pakiramdam mo?",
                        },
                    },
                },
                {
                    ["consumers"] = {
                        "participant",
                    },
                    ["frame"] = {
                        ["extensions"] = {
                            ["topic"] = "wellbeing",
                        },
                        ["intent"] = "QUESTION",
                        ["patternID"] = "pnc.question.wellbeing_follow_up_what_is_wrong",
                        ["speechAct"] = "QUESTION",
                        ["subject"] = "WELLBEING",
                        ["topic"] = "wellbeing",
                    },
                    ["id"] = "question.wellbeing_detail",
                    ["label"] = {
                        ["EN"] = {
                            "Ask what is wrong",
                        },
                        ["TL"] = {
                            "Itanong kung ano ang problema",
                        },
                    },
                    ["metadata"] = {
                        ["domain"] = "wellbeing",
                        ["order"] = 20,
                    },
                    ["utterance"] = {
                        ["EN"] = {
                            "What's wrong?",
                        },
                        ["TL"] = {
                            "Ano ang problema?",
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_check_in.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
