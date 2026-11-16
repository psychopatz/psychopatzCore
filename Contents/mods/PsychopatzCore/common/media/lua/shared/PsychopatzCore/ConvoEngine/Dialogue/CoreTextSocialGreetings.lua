-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_text_social_greetings",
        ["domainPath"] = "core_text_social_greetings",
        ["exchangeFamily"] = {
            ["familyID"] = "response.ambient_visit.accepted",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "Thank you. I could use somewhere safe to rest for a while.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.response.ambient_visit.accepted.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Thank you. I could use somewhere safe to rest for a while.",
                                    },
                                    ["TL"] = {
                                        "Salamat. Kailangan ko muna ng ligtas na lugar para makapagpahinga.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "response.ambient_visit",
            ["textRoles"] = {
                {
                    ["fallback"] = "Thank you. I could use somewhere safe to rest for a while.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.response.ambient_visit.accepted.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Thank you. I could use somewhere safe to rest for a while.",
                        },
                        ["TL"] = {
                            "Salamat. Kailangan ko muna ng ligtas na lugar para makapagpahinga.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "response.ambient_visit.accepted",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "accepted",
            ["sourceId"] = "response.ambient_visit.accepted",
            ["sourcePath"] = "dialogue/core_text_social_greetings/response_ambient_visit_accepted.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextSocialGreetings",
        ["namespace"] = "response.ambient_visit",
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
                ["textKey"] = "response.ambient_visit.accepted.1",
                ["textRows"] = {
                    {
                        ["key"] = "response.ambient_visit.accepted.1",
                        ["text"] = {
                            ["EN"] = "Thank you. I could use somewhere safe to rest for a while.",
                            ["TL"] = "Salamat. Kailangan ko muna ng ligtas na lugar para makapagpahinga.",
                        },
                    },
                },
                ["textTarget"] = "social/greetings/ambient_visit/arrival",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Thank you. I could use somewhere safe to rest for a while.",
                                    },
                                    ["TL"] = {
                                        "Salamat. Kailangan ko muna ng ligtas na lugar para makapagpahinga.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "response.ambient_visit.accepted",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Thank you. I could use somewhere safe to rest for a while.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.response.ambient_visit.accepted.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_text_social_greetings/response_ambient_visit_accepted.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Thank you. I could use somewhere safe to rest for a while.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.response.ambient_visit.accepted.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Thank you. I could use somewhere safe to rest for a while.",
                    },
                    ["TL"] = {
                        "Salamat. Kailangan ko muna ng ligtas na lugar para makapagpahinga.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
