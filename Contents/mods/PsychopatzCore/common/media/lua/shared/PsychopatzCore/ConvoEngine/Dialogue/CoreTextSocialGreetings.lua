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
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "response.ambient_visit.accepted",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "accepted",
            ["sourceId"] = "response.ambient_visit.accepted",
            ["sourcePath"] = "dialogue/core_text_social_greetings/response_ambient_visit_accepted.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
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
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "PsychopatzCore",
                },
            },
            ["metadata"] = {
                ["textKey"] = "response.ambient_visit.accepted.1",
                ["textRows"] = {
                    {
                        ["fallback"] = "Thank you. I could use somewhere safe to rest for a while.",
                        ["key"] = "response.ambient_visit.accepted.1",
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
                                ["fallback"] = "Thank you. I could use somewhere safe to rest for a while.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "greeting_goodbye",
                },
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
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
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
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
