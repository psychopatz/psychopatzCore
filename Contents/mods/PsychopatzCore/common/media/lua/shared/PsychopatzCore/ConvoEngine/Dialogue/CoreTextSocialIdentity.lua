-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_text_social_identity",
        ["exchangeFamily"] = {
            ["familyID"] = "identity.introduction",
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
                                ["fallback"] = "They introduce themselves.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.identity.introduction.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "They introduce themselves.",
                                    },
                                    ["TL"] = {
                                        "Nagpakilala sila.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "identity",
            ["textRoles"] = {
                {
                    ["fallback"] = "They introduce themselves.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.identity.introduction.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "They introduce themselves.",
                        },
                        ["TL"] = {
                            "Nagpakilala sila.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "identity.introduction",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "introduction",
            ["sourceId"] = "identity.introduction",
            ["sourcePath"] = "dialogue/core_text_social_identity/identity_introduction.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextSocialIdentity",
        ["namespace"] = "identity",
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
                ["textKey"] = "identity.introduction",
                ["textRows"] = {
                    {
                        ["key"] = "identity.introduction",
                        ["text"] = {
                            ["EN"] = "They introduce themselves.",
                            ["TL"] = "Nagpakilala sila.",
                        },
                    },
                },
                ["textTarget"] = "social/identity/response",
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
                                        "They introduce themselves.",
                                    },
                                    ["TL"] = {
                                        "Nagpakilala sila.",
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
            ["responsePlanID"] = "identity.introduction",
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
                            ["fallback"] = "They introduce themselves.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.identity.introduction.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_text_social_identity/identity_introduction.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "They introduce themselves.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.identity.introduction.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "They introduce themselves.",
                    },
                    ["TL"] = {
                        "Nagpakilala sila.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
