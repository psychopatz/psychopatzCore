-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_text_needs_gifts",
        ["domainPath"] = "core_text_needs_gifts",
        ["exchangeFamily"] = {
            ["familyID"] = "gift.preference.dislike",
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
                                ["fallback"] = "I don't like that.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.gift.preference.dislike.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I don't like that.",
                                    },
                                    ["TL"] = {
                                        "Ayaw ko niyan.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "gift.preference",
            ["textRoles"] = {
                {
                    ["fallback"] = "I don't like that.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.gift.preference.dislike.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I don't like that.",
                        },
                        ["TL"] = {
                            "Ayaw ko niyan.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "gift.preference.dislike",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "dislike",
            ["sourceId"] = "gift.preference.dislike",
            ["sourcePath"] = "dialogue/core_text_needs_gifts/gift_preference_dislike.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextNeedsGifts",
        ["namespace"] = "gift.preference",
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
                ["textKey"] = "gift.preference.dislike",
                ["textRows"] = {
                    {
                        ["key"] = "gift.preference.dislike",
                        ["text"] = {
                            ["EN"] = "I don't like that.",
                            ["TL"] = "Ayaw ko niyan.",
                        },
                    },
                },
                ["textTarget"] = "needs/gifts/preference",
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
                                        "I don't like that.",
                                    },
                                    ["TL"] = {
                                        "Ayaw ko niyan.",
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
            ["responsePlanID"] = "gift.preference.dislike",
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
                            ["fallback"] = "I don't like that.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.gift.preference.dislike.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_text_needs_gifts/gift_preference_dislike.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I don't like that.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.gift.preference.dislike.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I don't like that.",
                    },
                    ["TL"] = {
                        "Ayaw ko niyan.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_needs_gifts",
        ["domainPath"] = "core_text_needs_gifts",
        ["exchangeFamily"] = {
            ["familyID"] = "gift.preference.like",
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
                                ["fallback"] = "I like that.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.gift.preference.like.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I like that.",
                                    },
                                    ["TL"] = {
                                        "Gusto ko iyan.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "gift.preference",
            ["textRoles"] = {
                {
                    ["fallback"] = "I like that.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.gift.preference.like.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I like that.",
                        },
                        ["TL"] = {
                            "Gusto ko iyan.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "gift.preference.like",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "like",
            ["sourceId"] = "gift.preference.like",
            ["sourcePath"] = "dialogue/core_text_needs_gifts/gift_preference_like.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextNeedsGifts",
        ["namespace"] = "gift.preference",
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
                ["textKey"] = "gift.preference.like",
                ["textRows"] = {
                    {
                        ["key"] = "gift.preference.like",
                        ["text"] = {
                            ["EN"] = "I like that.",
                            ["TL"] = "Gusto ko iyan.",
                        },
                    },
                },
                ["textTarget"] = "needs/gifts/preference",
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
                                        "I like that.",
                                    },
                                    ["TL"] = {
                                        "Gusto ko iyan.",
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
            ["responsePlanID"] = "gift.preference.like",
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
                            ["fallback"] = "I like that.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.gift.preference.like.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_text_needs_gifts/gift_preference_like.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I like that.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.gift.preference.like.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I like that.",
                    },
                    ["TL"] = {
                        "Gusto ko iyan.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_needs_gifts",
        ["domainPath"] = "core_text_needs_gifts",
        ["exchangeFamily"] = {
            ["familyID"] = "gift.preference.neutral",
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
                                ["fallback"] = "I don't have a strong preference.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.gift.preference.neutral.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I don't have a strong preference.",
                                    },
                                    ["TL"] = {
                                        "Wala akong matinding kagustuhan tungkol diyan.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "gift.preference",
            ["textRoles"] = {
                {
                    ["fallback"] = "I don't have a strong preference.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.gift.preference.neutral.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I don't have a strong preference.",
                        },
                        ["TL"] = {
                            "Wala akong matinding kagustuhan tungkol diyan.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "gift.preference.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "neutral",
            ["sourceId"] = "gift.preference.neutral",
            ["sourcePath"] = "dialogue/core_text_needs_gifts/gift_preference.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextNeedsGifts",
        ["namespace"] = "gift.preference",
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
                ["textKey"] = "gift.preference.neutral",
                ["textRows"] = {
                    {
                        ["key"] = "gift.preference.neutral",
                        ["text"] = {
                            ["EN"] = "I don't have a strong preference.",
                            ["TL"] = "Wala akong matinding kagustuhan tungkol diyan.",
                        },
                    },
                },
                ["textTarget"] = "needs/gifts/preference",
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
                                        "I don't have a strong preference.",
                                    },
                                    ["TL"] = {
                                        "Wala akong matinding kagustuhan tungkol diyan.",
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
            ["responsePlanID"] = "gift.preference.neutral",
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
                            ["fallback"] = "I don't have a strong preference.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.gift.preference.neutral.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_text_needs_gifts/gift_preference.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I don't have a strong preference.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.gift.preference.neutral.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I don't have a strong preference.",
                    },
                    ["TL"] = {
                        "Wala akong matinding kagustuhan tungkol diyan.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_needs_gifts",
        ["domainPath"] = "core_text_needs_gifts",
        ["exchangeFamily"] = {
            ["familyID"] = "gift.preference.unknown",
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
                                ["fallback"] = "I'm not sure which item you mean.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.gift.preference.unknown.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'm not sure which item you mean.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko alam kung anong gamit ang tinutukoy mo.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "gift.preference",
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm not sure which item you mean.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.gift.preference.unknown.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'm not sure which item you mean.",
                        },
                        ["TL"] = {
                            "Hindi ko alam kung anong gamit ang tinutukoy mo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "gift.preference.unknown",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "unknown",
            ["sourceId"] = "gift.preference.unknown",
            ["sourcePath"] = "dialogue/core_text_needs_gifts/gift_preference_unknown.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextNeedsGifts",
        ["namespace"] = "gift.preference",
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
                ["textKey"] = "gift.preference.unknown",
                ["textRows"] = {
                    {
                        ["key"] = "gift.preference.unknown",
                        ["text"] = {
                            ["EN"] = "I'm not sure which item you mean.",
                            ["TL"] = "Hindi ko alam kung anong gamit ang tinutukoy mo.",
                        },
                    },
                },
                ["textTarget"] = "needs/gifts/preference",
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
                                        "I'm not sure which item you mean.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko alam kung anong gamit ang tinutukoy mo.",
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
            ["responsePlanID"] = "gift.preference.unknown",
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
                            ["fallback"] = "I'm not sure which item you mean.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.gift.preference.unknown.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_text_needs_gifts/gift_preference_unknown.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm not sure which item you mean.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.gift.preference.unknown.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'm not sure which item you mean.",
                    },
                    ["TL"] = {
                        "Hindi ko alam kung anong gamit ang tinutukoy mo.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
