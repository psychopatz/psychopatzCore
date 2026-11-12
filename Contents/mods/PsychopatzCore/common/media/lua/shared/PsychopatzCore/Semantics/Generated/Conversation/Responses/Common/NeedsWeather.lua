-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "flow",
        ["id"] = "semantic.flow.weather.raining",
        ["variants"] = {
            {
                ["fallback"] = "It is raining right now. We can return to that proposal when you are ready.",
                ["id"] = "semantic.flow.weather.raining.dataset.contextual_switch",
                ["metadata"] = {
                    ["reviewed"] = true,
                    ["sourceRefs"] = {
                        "MASSIVE",
                        "SGD",
                    },
                    ["translationKey"] = "UI_PNC_Conversation_Semantic_DatasetWeatherContextualSwitch",
                },
                ["plan"] = {
                    ["dialogueAct"] = "WEATHER_REPORT",
                    ["groundedFactRefs"] = {
                        "world.weather.raining",
                    },
                    ["personalityStyle"] = "contextual",
                    ["referenceSubject"] = nil,
                    ["referenceTopic"] = nil,
                    ["sourcePoolID"] = "semantic.flow.weather.raining",
                    ["tone"] = "conversational",
                    ["topic"] = "WEATHER",
                    ["turns"] = {
                        {
                            ["continuation"] = "continue",
                            ["id"] = "dataset_contextual_weather_switch",
                            ["segments"] = {
                                {
                                    ["fallback"] = "It is raining right now. We can return to that proposal when you are ready.",
                                    ["kind"] = "translation",
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetWeatherContextualSwitch",
                                    ["translationArgs"] = {
                                    },
                                },
                            },
                        },
                    },
                    ["uncertainty"] = "known",
                },
                ["priority"] = 4,
                ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetWeatherContextualSwitch",
                ["when"] = {
                    ["pattern"] = "pnc.dataset.question.weather.can_we_talk_about_the_weather",
                },
            },
        },
    },
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.needs.proposal",
        ["variants"] = {
            {
                ["fallback"] = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                ["id"] = "semantic.question.needs.proposal.dataset.thirst",
                ["metadata"] = {
                    ["reviewed"] = true,
                    ["sourceRefs"] = {
                        "MASSIVE",
                        "SGD",
                    },
                    ["translationKey"] = "UI_PNC_Conversation_Semantic_DatasetNeedsPromiseThirst",
                },
                ["plan"] = {
                    ["dialogueAct"] = "PROMISE_ACKNOWLEDGEMENT",
                    ["groundedFactRefs"] = {
                        "npc.needs.thirst",
                    },
                    ["personalityStyle"] = nil,
                    ["referenceSubject"] = nil,
                    ["referenceTopic"] = nil,
                    ["sourcePoolID"] = "semantic.question.needs.proposal",
                    ["tone"] = "direct",
                    ["topic"] = "NEEDS",
                    ["turns"] = {
                        {
                            ["continuation"] = "continue",
                            ["id"] = "dataset_proposal_acknowledged",
                            ["segments"] = {
                                {
                                    ["fallback"] = "I can keep that as a proposal, but I still need the item and amount before I record a commitment.",
                                    ["kind"] = "translation",
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetNeedsPromiseThirst",
                                    ["translationArgs"] = {
                                    },
                                },
                            },
                        },
                    },
                    ["uncertainty"] = "pending",
                },
                ["priority"] = 4,
                ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetNeedsPromiseThirst",
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
        },
    },
    {
        ["domain"] = "question",
        ["id"] = "semantic.question.needs.quantity",
        ["variants"] = {
            {
                ["fallback"] = "I can confirm water is a need, but which item do you mean?",
                ["id"] = "semantic.question.needs.quantity.dataset.clarify_thirst",
                ["metadata"] = {
                    ["reviewed"] = true,
                    ["sourceRefs"] = {
                        "MASSIVE",
                        "SGD",
                    },
                    ["translationKey"] = "UI_PNC_Conversation_Semantic_DatasetNeedsClarifyThirst",
                },
                ["plan"] = {
                    ["dialogueAct"] = "ASK_CLARIFICATION",
                    ["groundedFactRefs"] = {
                        "npc.needs.thirst",
                    },
                    ["personalityStyle"] = nil,
                    ["referenceSubject"] = nil,
                    ["referenceTopic"] = nil,
                    ["sourcePoolID"] = "semantic.question.needs.quantity",
                    ["tone"] = "clarifying",
                    ["topic"] = "NEEDS",
                    ["turns"] = {
                        {
                            ["continuation"] = "continue",
                            ["id"] = "dataset_needs_clarification",
                            ["segments"] = {
                                {
                                    ["fallback"] = "I can confirm water is a need, but which item do you mean?",
                                    ["kind"] = "translation",
                                    ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetNeedsClarifyThirst",
                                    ["translationArgs"] = {
                                    },
                                },
                            },
                        },
                    },
                    ["uncertainty"] = "ambiguous",
                },
                ["priority"] = 4,
                ["templateID"] = "UI_PNC_Conversation_Semantic_DatasetNeedsClarifyThirst",
                ["when"] = {
                    ["lastIntent"] = "CLARIFY",
                    ["needType"] = "thirst",
                },
            },
        },
    },
}
