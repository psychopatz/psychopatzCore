-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.activity",
        ["variants"] = {
            {
                ["fallback"] = "Just doing what I can to keep things moving.",
                ["id"] = "semantic.question.activity.dataset.keep_moving",
                ["metadata"] = {
                    ["translationKey"] = "semantic.question.activity.dataset.keep_moving",
                },
                ["templateID"] = "semantic.question.activity.dataset.keep_moving",
            },
            {
                ["fallback"] = "A little bit of everything.",
                ["id"] = "semantic.question.activity.dataset.bit_of_everything",
                ["metadata"] = {
                    ["translationKey"] = "semantic.question.activity.dataset.bit_of_everything",
                },
                ["templateID"] = "semantic.question.activity.dataset.bit_of_everything",
            },
            {
                ["fallback"] = "Just taking care of what needs doing.",
                ["id"] = "semantic.question.activity.dataset.taking_care",
                ["metadata"] = {
                    ["translationKey"] = "semantic.question.activity.dataset.taking_care",
                },
                ["templateID"] = "semantic.question.activity.dataset.taking_care",
            },
        },
    },
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.identity",
        ["variants"] = {
            {
                ["fallback"] = "I keep my name to myself until I know someone better. What should I call you?",
                ["id"] = "semantic.question.identity.dataset.stranger_alt_1",
                ["metadata"] = {
                    ["translationKey"] = "semantic.question.identity.stranger_alt_1",
                },
                ["templateID"] = "semantic.question.identity.stranger_alt_1",
            },
            {
                ["fallback"] = "Let's get to know each other first. What do people call you?",
                ["id"] = "semantic.question.identity.dataset.stranger_alt_2",
                ["metadata"] = {
                    ["translationKey"] = "semantic.question.identity.stranger_alt_2",
                },
                ["templateID"] = "semantic.question.identity.stranger_alt_2",
            },
            {
                ["fallback"] = "I don't trust you enough to share my name. Who are you, really?",
                ["id"] = "semantic.question.identity.dataset.wary_alt_1",
                ["metadata"] = {
                    ["translationKey"] = "semantic.question.identity.wary_alt_1",
                },
                ["priority"] = 2,
                ["templateID"] = "semantic.question.identity.wary_alt_1",
                ["when"] = {
                    ["identityTrust"] = "untrustworthy",
                },
            },
            {
                ["fallback"] = "After that lie, I'm not telling you my name. Tell me the truth about yours.",
                ["id"] = "semantic.question.identity.dataset.wary_alt_2",
                ["metadata"] = {
                    ["translationKey"] = "semantic.question.identity.wary_alt_2",
                },
                ["priority"] = 2,
                ["templateID"] = "semantic.question.identity.wary_alt_2",
                ["when"] = {
                    ["identityTrust"] = "untrustworthy",
                },
            },
        },
    },
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.wellbeing",
        ["variants"] = {
            {
                ["fallback"] = "I'm hanging in there. Thanks for asking.",
                ["id"] = "semantic.question.wellbeing.dataset.hanging_in",
                ["metadata"] = {
                    ["translationKey"] = "semantic.question.wellbeing.dataset.hanging_in",
                },
                ["templateID"] = "semantic.question.wellbeing.dataset.hanging_in",
            },
            {
                ["fallback"] = "Doing okay, all things considered.",
                ["id"] = "semantic.question.wellbeing.dataset.all_things_considered",
                ["metadata"] = {
                    ["translationKey"] = "semantic.question.wellbeing.dataset.all_things_considered",
                },
                ["templateID"] = "semantic.question.wellbeing.dataset.all_things_considered",
            },
            {
                ["fallback"] = "I'm getting by, one day at a time. How about you?",
                ["id"] = "semantic.question.wellbeing.dataset.getting_by",
                ["metadata"] = {
                    ["translationKey"] = "semantic.question.wellbeing.dataset.getting_by",
                },
                ["templateID"] = "semantic.question.wellbeing.dataset.getting_by",
            },
            {
                ["fallback"] = "I'm hungry, but I'll manage. If you have food to spare, I'd appreciate it.",
                ["id"] = "semantic.question.wellbeing.dataset.hungry",
                ["metadata"] = {
                    ["translationKey"] = "semantic.question.wellbeing.dataset.hungry",
                },
                ["priority"] = 2,
                ["templateID"] = "semantic.question.wellbeing.dataset.hungry",
                ["when"] = {
                    ["needType"] = "hunger",
                    ["needUrgency"] = {
                        "moderate",
                        "severe",
                        "emergency",
                        "critical",
                    },
                },
            },
            {
                ["fallback"] = "I'm pretty thirsty. If you have water, could you spare some?",
                ["id"] = "semantic.question.wellbeing.dataset.thirsty",
                ["metadata"] = {
                    ["translationKey"] = "semantic.question.wellbeing.dataset.thirsty",
                },
                ["priority"] = 3,
                ["templateID"] = "semantic.question.wellbeing.dataset.thirsty",
                ["when"] = {
                    ["needType"] = "thirst",
                    ["needUrgency"] = {
                        "moderate",
                        "severe",
                        "emergency",
                        "critical",
                    },
                },
            },
            {
                ["fallback"] = "I'm tired, though I can manage for now.",
                ["id"] = "semantic.question.wellbeing.dataset.tired",
                ["metadata"] = {
                    ["translationKey"] = "semantic.question.wellbeing.dataset.tired",
                },
                ["priority"] = 2,
                ["templateID"] = "semantic.question.wellbeing.dataset.tired",
                ["when"] = {
                    ["needType"] = "fatigue",
                    ["needUrgency"] = {
                        "moderate",
                        "severe",
                        "emergency",
                        "critical",
                    },
                },
            },
        },
    },
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.wellbeing.unknown",
        ["variants"] = {
            {
                ["fallback"] = "I can tell something is off, but I do not know what caused it yet.",
                ["id"] = "semantic.question.wellbeing.unknown.dataset.causal_followup",
                ["metadata"] = {
                    ["reviewed"] = true,
                    ["sourceRefs"] = {
                        "MASSIVE",
                        "SGD",
                    },
                    ["translationKey"] = "UI_PNC_Conversation_Semantic_DatasetWellbeingCausalUnknown",
                },
                ["plan"] = {
                    ["dialogueAct"] = "ASK_CLARIFICATION",
                    ["groundedFactRefs"] = {
                    },
                    ["personalityStyle"] = "truthful",
                    ["referenceSubject"] = nil,
                    ["referenceTopic"] = nil,
                    ["sourcePoolID"] = "semantic.question.wellbeing.unknown",
                    ["tone"] = "clarifying",
                    ["topic"] = "WELLBEING",
                    ["turns"] = {
                        {
                            ["continuation"] = "continue",
                            ["id"] = "dataset_causal_wellbeing_unknown",
                            ["segments"] = {
                                {
                                    ["fallback"] = "I can tell something is off, but I do not know what caused it yet.",
                                    ["kind"] = "translation",
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetWellbeingCausalUnknown",
                                    ["translationArgs"] = {
                                    },
                                },
                            },
                        },
                    },
                    ["uncertainty"] = "unknown",
                },
                ["priority"] = 4,
                ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetWellbeingCausalUnknown",
                ["when"] = {
                    ["healthState"] = "unknown",
                    ["pattern"] = "pnc.dataset.question.wellbeing.what_is_going_on_with_you",
                },
            },
        },
    },
}
