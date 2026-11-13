-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_text_social_departure",
        ["id"] = "text.departure.confirmed",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "confirmed",
            ["sourceId"] = "text.departure.confirmed",
            ["sourcePath"] = "dialogue/core_text_social_departure/departure_confirmed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextSocialDeparture",
        ["namespace"] = "text.departure",
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
            ["text"] = {
                ["EN"] = {
                    "Understood. I will take my chances elsewhere. Remember what you chose.",
                },
                ["TL"] = {
                    "Naiintindihan. Susubukan ko ang kapalaran ko sa ibang lugar. Tandaan mo ang pinili mo.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.departure.confirmed",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Understood. I will take my chances elsewhere. Remember what you chose.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.departure.confirmed.response",
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
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_departure",
        ["id"] = "text.departure.rejected",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "rejected",
            ["sourceId"] = "text.departure.rejected",
            ["sourcePath"] = "dialogue/core_text_social_departure/departure_rejected.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextSocialDeparture",
        ["namespace"] = "text.departure",
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
            ["text"] = {
                ["EN"] = {
                    "I am not leaving with you. That decision is not yours to make right now.",
                },
                ["TL"] = {
                    "Hindi ako aalis kasama mo. Ang desisyon na iyon ay hindi mo dapat gawin ngayon.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.departure.rejected",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I am not leaving with you. That decision is not yours to make right now.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.departure.rejected.response",
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
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_departure",
        ["id"] = "text.departure.warning",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "warning",
            ["sourceId"] = "text.departure.warning",
            ["sourcePath"] = "dialogue/core_text_social_departure/departure_warning.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextSocialDeparture",
        ["namespace"] = "text.departure",
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
            ["text"] = {
                ["EN"] = {
                    "If you cast me out, I will leave this group and make my own way. You cannot take that back.",
                },
                ["TL"] = {
                    "Kung paalisin mo ako, aalis ako sa grupong ito at gagawa ng sarili kong paraan. Hindi mo na maibabalik iyon.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.departure.warning",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "If you cast me out, I will leave this group and make my own way. You cannot take that back.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.departure.warning.response",
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
        ["when"] = nil,
    },
}
