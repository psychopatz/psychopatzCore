-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_text_social_departure",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Understood. I will take my chances elsewhere. Remember what you chose.",
                                    },
                                    ["TL"] = {
                                        "Naiintindihan. Susubukan ko ang kapalaran ko sa ibang lugar. Tandaan mo ang pinili mo.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "Understood. I will take my chances elsewhere. Remember what you chose.",
                        },
                        ["TL"] = {
                            "Naiintindihan. Susubukan ko ang kapalaran ko sa ibang lugar. Tandaan mo ang pinili mo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "departure.confirmed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "confirmed",
            ["sourceId"] = "departure.confirmed",
            ["sourcePath"] = "dialogue/core_text_social_departure/departure_confirmed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextSocialDeparture",
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
            ["metadata"] = {
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.social.departure.response",
                ["sourcePath"] = "social/departure/response.json",
                ["textKey"] = "departure.confirmed",
                ["textRows"] = {
                    {
                        ["key"] = "departure.confirmed",
                        ["text"] = {
                            ["EN"] = "Understood. I will take my chances elsewhere. Remember what you chose.",
                            ["TL"] = "Naiintindihan. Susubukan ko ang kapalaran ko sa ibang lugar. Tandaan mo ang pinili mo.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Understood. I will take my chances elsewhere. Remember what you chose.",
                                    },
                                    ["TL"] = {
                                        "Naiintindihan. Susubukan ko ang kapalaran ko sa ibang lugar. Tandaan mo ang pinili mo.",
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
                            ["templateID"] = "psdl.departure.confirmed.say_1",
                        },
                    },
                },
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
                ["translations"] = {
                    ["EN"] = {
                        "Understood. I will take my chances elsewhere. Remember what you chose.",
                    },
                    ["TL"] = {
                        "Naiintindihan. Susubukan ko ang kapalaran ko sa ibang lugar. Tandaan mo ang pinili mo.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_departure",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "I am not leaving with you. That decision is not yours to make right now.",
                                    },
                                    ["TL"] = {
                                        "Hindi ako aalis kasama mo. Ang desisyon na iyon ay hindi mo dapat gawin ngayon.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "I am not leaving with you. That decision is not yours to make right now.",
                        },
                        ["TL"] = {
                            "Hindi ako aalis kasama mo. Ang desisyon na iyon ay hindi mo dapat gawin ngayon.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "departure.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "rejected",
            ["sourceId"] = "departure.rejected",
            ["sourcePath"] = "dialogue/core_text_social_departure/departure_rejected.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextSocialDeparture",
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
            ["metadata"] = {
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.social.departure.response",
                ["sourcePath"] = "social/departure/response.json",
                ["textKey"] = "departure.rejected",
                ["textRows"] = {
                    {
                        ["key"] = "departure.rejected",
                        ["text"] = {
                            ["EN"] = "I am not leaving with you. That decision is not yours to make right now.",
                            ["TL"] = "Hindi ako aalis kasama mo. Ang desisyon na iyon ay hindi mo dapat gawin ngayon.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "I am not leaving with you. That decision is not yours to make right now.",
                                    },
                                    ["TL"] = {
                                        "Hindi ako aalis kasama mo. Ang desisyon na iyon ay hindi mo dapat gawin ngayon.",
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
                            ["templateID"] = "psdl.departure.rejected.say_1",
                        },
                    },
                },
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
                ["translations"] = {
                    ["EN"] = {
                        "I am not leaving with you. That decision is not yours to make right now.",
                    },
                    ["TL"] = {
                        "Hindi ako aalis kasama mo. Ang desisyon na iyon ay hindi mo dapat gawin ngayon.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_departure",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "If you cast me out, I will leave this group and make my own way. You cannot take that back.",
                                    },
                                    ["TL"] = {
                                        "Kung paalisin mo ako, aalis ako sa grupong ito at gagawa ng sarili kong paraan. Hindi mo na maibabalik iyon.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "If you cast me out, I will leave this group and make my own way. You cannot take that back.",
                        },
                        ["TL"] = {
                            "Kung paalisin mo ako, aalis ako sa grupong ito at gagawa ng sarili kong paraan. Hindi mo na maibabalik iyon.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "departure.warning",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "warning",
            ["sourceId"] = "departure.warning",
            ["sourcePath"] = "dialogue/core_text_social_departure/departure_warning.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextSocialDeparture",
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
            ["metadata"] = {
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.social.departure.response",
                ["sourcePath"] = "social/departure/response.json",
                ["textKey"] = "departure.warning",
                ["textRows"] = {
                    {
                        ["key"] = "departure.warning",
                        ["text"] = {
                            ["EN"] = "If you cast me out, I will leave this group and make my own way. You cannot take that back.",
                            ["TL"] = "Kung paalisin mo ako, aalis ako sa grupong ito at gagawa ng sarili kong paraan. Hindi mo na maibabalik iyon.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "If you cast me out, I will leave this group and make my own way. You cannot take that back.",
                                    },
                                    ["TL"] = {
                                        "Kung paalisin mo ako, aalis ako sa grupong ito at gagawa ng sarili kong paraan. Hindi mo na maibabalik iyon.",
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
                            ["templateID"] = "psdl.departure.warning.say_1",
                        },
                    },
                },
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
                ["translations"] = {
                    ["EN"] = {
                        "If you cast me out, I will leave this group and make my own way. You cannot take that back.",
                    },
                    ["TL"] = {
                        "Kung paalisin mo ako, aalis ako sa grupong ito at gagawa ng sarili kong paraan. Hindi mo na maibabalik iyon.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
