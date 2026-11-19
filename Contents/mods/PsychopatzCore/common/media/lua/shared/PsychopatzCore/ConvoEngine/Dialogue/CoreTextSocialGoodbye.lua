-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_text_social_goodbye",
        ["domainPath"] = "core_text_social_goodbye",
        ["exchangeFamily"] = {
            ["familyID"] = "choice.goodbye",
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
                                ["fallback"] = "That's all. Stay safe.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.choice.goodbye.say.1.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "choice",
            ["textRoles"] = {
                {
                    ["fallback"] = "That's all. Stay safe.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.choice.goodbye.say.1.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "choice.goodbye",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "goodbye",
            ["sourceId"] = "choice.goodbye",
            ["sourcePath"] = "dialogue/core_text_social_goodbye/choice_goodbye.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextSocialGoodbye",
        ["namespace"] = "choice",
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
                ["textKey"] = "choice.goodbye",
                ["textRows"] = {
                    {
                        ["fallback"] = "That's all. Stay safe.",
                        ["key"] = "choice.goodbye",
                    },
                },
                ["textTarget"] = "social/goodbye/closing",
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
                                ["fallback"] = "That's all. Stay safe.",
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
            ["responsePlanID"] = "choice.goodbye",
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
                            ["fallback"] = "That's all. Stay safe.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.choice.goodbye.say_1",
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
        ["sourceShard"] = "dialogue/core_text_social_goodbye/choice_goodbye.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "That's all. Stay safe.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.choice.goodbye.say.1.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_goodbye",
        ["domainPath"] = "core_text_social_goodbye",
        ["exchangeFamily"] = {
            ["familyID"] = "response.goodbye",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                    "4",
                    "5",
                    "6",
                    "7",
                    "8",
                    "9",
                    "10",
                    "11",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "You too.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.response.goodbye.say.1.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["10"] = {
                        ["key"] = "10",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "See you. Keep your head down.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.response.goodbye.say.10.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["11"] = {
                        ["key"] = "11",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Be careful on the roads.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.response.goodbye.say.11.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "You too.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.response.goodbye.say.2.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Watch your back out there.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.response.goodbye.say.3.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["4"] = {
                        ["key"] = "4",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Take care. See you around.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.response.goodbye.say.4.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["5"] = {
                        ["key"] = "5",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Keep your eyes open.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.response.goodbye.say.5.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["6"] = {
                        ["key"] = "6",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Stay safe. Don't take unnecessary risks.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.response.goodbye.say.6.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["7"] = {
                        ["key"] = "7",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Until next time. Stay sharp.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.response.goodbye.say.7.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["8"] = {
                        ["key"] = "8",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Yeah. Catch you later.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.response.goodbye.say.8.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["9"] = {
                        ["key"] = "9",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Take it easy out there.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.response.goodbye.say.9.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "response",
            ["textRoles"] = {
                {
                    ["fallback"] = "You too.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.response.goodbye.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "You too.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.response.goodbye.say.2.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Watch your back out there.",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.response.goodbye.say.3.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Take care. See you around.",
                    ["realizationKey"] = "4",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.response.goodbye.say.4.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Keep your eyes open.",
                    ["realizationKey"] = "5",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.response.goodbye.say.5.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Stay safe. Don't take unnecessary risks.",
                    ["realizationKey"] = "6",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.response.goodbye.say.6.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Until next time. Stay sharp.",
                    ["realizationKey"] = "7",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.response.goodbye.say.7.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Yeah. Catch you later.",
                    ["realizationKey"] = "8",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.response.goodbye.say.8.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Take it easy out there.",
                    ["realizationKey"] = "9",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.response.goodbye.say.9.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "See you. Keep your head down.",
                    ["realizationKey"] = "10",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.response.goodbye.say.10.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Be careful on the roads.",
                    ["realizationKey"] = "11",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.response.goodbye.say.11.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "response.goodbye",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "goodbye",
            ["sourceId"] = "response.goodbye",
            ["sourcePath"] = "dialogue/core_text_social_goodbye/response_goodbye.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextSocialGoodbye",
        ["namespace"] = "response",
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
                ["textRows"] = {
                    {
                        ["fallback"] = "You too.",
                        ["key"] = "response.goodbye",
                    },
                    {
                        ["fallback"] = "You too.",
                        ["key"] = "response.goodbye.1",
                    },
                    {
                        ["fallback"] = "Watch your back out there.",
                        ["key"] = "response.goodbye.2",
                    },
                    {
                        ["fallback"] = "Take care. See you around.",
                        ["key"] = "response.goodbye.3",
                    },
                    {
                        ["fallback"] = "Keep your eyes open.",
                        ["key"] = "response.goodbye.4",
                    },
                    {
                        ["fallback"] = "Stay safe. Don't take unnecessary risks.",
                        ["key"] = "response.goodbye.5",
                    },
                    {
                        ["fallback"] = "Until next time. Stay sharp.",
                        ["key"] = "response.goodbye.6",
                    },
                    {
                        ["fallback"] = "Yeah. Catch you later.",
                        ["key"] = "response.goodbye.7",
                    },
                    {
                        ["fallback"] = "Take it easy out there.",
                        ["key"] = "response.goodbye.8",
                    },
                    {
                        ["fallback"] = "See you. Keep your head down.",
                        ["key"] = "response.goodbye.9",
                    },
                    {
                        ["fallback"] = "Be careful on the roads.",
                        ["key"] = "response.goodbye.10",
                    },
                },
                ["textTarget"] = "social/goodbye/closing",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                    "4",
                    "5",
                    "6",
                    "7",
                    "8",
                    "9",
                    "10",
                    "11",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "You too.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["10"] = {
                        ["key"] = "10",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "See you. Keep your head down.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["11"] = {
                        ["key"] = "11",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Be careful on the roads.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "You too.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Watch your back out there.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["4"] = {
                        ["key"] = "4",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Take care. See you around.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["5"] = {
                        ["key"] = "5",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Keep your eyes open.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["6"] = {
                        ["key"] = "6",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Stay safe. Don't take unnecessary risks.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["7"] = {
                        ["key"] = "7",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Until next time. Stay sharp.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["8"] = {
                        ["key"] = "8",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Yeah. Catch you later.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["9"] = {
                        ["key"] = "9",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Take it easy out there.",
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
            ["responsePlanID"] = "response.goodbye",
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
                            ["fallback"] = "You too.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.response.goodbye.say_1",
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
        ["sourceShard"] = "dialogue/core_text_social_goodbye/response_goodbye.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "You too.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.response.goodbye.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "You too.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.response.goodbye.say.2.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Watch your back out there.",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.response.goodbye.say.3.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Take care. See you around.",
                ["realizationKey"] = "4",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.response.goodbye.say.4.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Keep your eyes open.",
                ["realizationKey"] = "5",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.response.goodbye.say.5.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Stay safe. Don't take unnecessary risks.",
                ["realizationKey"] = "6",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.response.goodbye.say.6.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Until next time. Stay sharp.",
                ["realizationKey"] = "7",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.response.goodbye.say.7.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Yeah. Catch you later.",
                ["realizationKey"] = "8",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.response.goodbye.say.8.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Take it easy out there.",
                ["realizationKey"] = "9",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.response.goodbye.say.9.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "See you. Keep your head down.",
                ["realizationKey"] = "10",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.response.goodbye.say.10.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Be careful on the roads.",
                ["realizationKey"] = "11",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.response.goodbye.say.11.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
