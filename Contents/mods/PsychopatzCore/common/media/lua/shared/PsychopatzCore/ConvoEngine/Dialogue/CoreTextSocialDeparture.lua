-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_text_social_departure",
        ["domainPath"] = "core_text_social_departure",
        ["exchangeFamily"] = {
            ["familyID"] = "departure.confirmed",
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
                                ["fallback"] = "Understood. I will take my chances elsewhere. Remember what you chose.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.departure.confirmed.say.1.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "departure",
            ["textRoles"] = {
                {
                    ["fallback"] = "Understood. I will take my chances elsewhere. Remember what you chose.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.departure.confirmed.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "departure.confirmed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "confirmed",
            ["sourceId"] = "departure.confirmed",
            ["sourcePath"] = "dialogue/core_text_social_departure/departure_confirmed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextSocialDeparture",
        ["namespace"] = "departure",
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
                ["textKey"] = "departure.confirmed",
                ["textRows"] = {
                    {
                        ["fallback"] = "Understood. I will take my chances elsewhere. Remember what you chose.",
                        ["key"] = "departure.confirmed",
                    },
                },
                ["textTarget"] = "social/departure/response",
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
                                ["fallback"] = "Understood. I will take my chances elsewhere. Remember what you chose.",
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
                    ["id"] = "departure",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "departure.confirmed",
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
                            ["fallback"] = "Understood. I will take my chances elsewhere. Remember what you chose.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.departure.confirmed.say_1",
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
        ["sourceShard"] = "dialogue/core_text_social_departure/departure_confirmed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Understood. I will take my chances elsewhere. Remember what you chose.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.departure.confirmed.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_departure",
        ["domainPath"] = "core_text_social_departure",
        ["exchangeFamily"] = {
            ["familyID"] = "departure.rejected",
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
                                ["fallback"] = "I am not leaving with you. That decision is not yours to make right now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.departure.rejected.say.1.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "departure",
            ["textRoles"] = {
                {
                    ["fallback"] = "I am not leaving with you. That decision is not yours to make right now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.departure.rejected.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "departure.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "rejected",
            ["sourceId"] = "departure.rejected",
            ["sourcePath"] = "dialogue/core_text_social_departure/departure_rejected.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextSocialDeparture",
        ["namespace"] = "departure",
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
                ["textKey"] = "departure.rejected",
                ["textRows"] = {
                    {
                        ["fallback"] = "I am not leaving with you. That decision is not yours to make right now.",
                        ["key"] = "departure.rejected",
                    },
                },
                ["textTarget"] = "social/departure/response",
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
                                ["fallback"] = "I am not leaving with you. That decision is not yours to make right now.",
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
                    ["id"] = "departure",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "departure.rejected",
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
                            ["fallback"] = "I am not leaving with you. That decision is not yours to make right now.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.departure.rejected.say_1",
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
        ["sourceShard"] = "dialogue/core_text_social_departure/departure_rejected.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I am not leaving with you. That decision is not yours to make right now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.departure.rejected.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_departure",
        ["domainPath"] = "core_text_social_departure",
        ["exchangeFamily"] = {
            ["familyID"] = "departure.warning",
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
                                ["fallback"] = "If you cast me out, I will leave this group and make my own way. You cannot take that back.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.departure.warning.say.1.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "departure",
            ["textRoles"] = {
                {
                    ["fallback"] = "If you cast me out, I will leave this group and make my own way. You cannot take that back.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.departure.warning.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "departure.warning",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "warning",
            ["sourceId"] = "departure.warning",
            ["sourcePath"] = "dialogue/core_text_social_departure/departure_warning.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextSocialDeparture",
        ["namespace"] = "departure",
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
                ["textKey"] = "departure.warning",
                ["textRows"] = {
                    {
                        ["fallback"] = "If you cast me out, I will leave this group and make my own way. You cannot take that back.",
                        ["key"] = "departure.warning",
                    },
                },
                ["textTarget"] = "social/departure/response",
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
                                ["fallback"] = "If you cast me out, I will leave this group and make my own way. You cannot take that back.",
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
                    ["id"] = "departure",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "departure.warning",
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
                            ["fallback"] = "If you cast me out, I will leave this group and make my own way. You cannot take that back.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.departure.warning.say_1",
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
        ["sourceShard"] = "dialogue/core_text_social_departure/departure_warning.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "If you cast me out, I will leave this group and make my own way. You cannot take that back.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.departure.warning.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
