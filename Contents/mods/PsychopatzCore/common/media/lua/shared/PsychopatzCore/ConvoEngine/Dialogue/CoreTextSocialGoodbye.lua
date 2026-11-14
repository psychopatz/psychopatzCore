-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_text_social_goodbye",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "That's all. Stay safe.",
                                    },
                                    ["TL"] = {
                                        "Iyon lang. Manatiling ligtas.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "That's all. Stay safe.",
                        },
                        ["TL"] = {
                            "Iyon lang. Manatiling ligtas.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "choice.goodbye",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "goodbye",
            ["sourceId"] = "choice.goodbye",
            ["sourcePath"] = "dialogue/core_text_social_goodbye/choice_goodbye.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextSocialGoodbye",
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
            ["metadata"] = {
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.social.goodbye.closing",
                ["sourcePath"] = "social/goodbye/closing.json",
                ["textKey"] = "choice.goodbye",
                ["textRows"] = {
                    {
                        ["key"] = "choice.goodbye",
                        ["text"] = {
                            ["EN"] = "That's all. Stay safe.",
                            ["TL"] = "Iyon lang. Manatiling ligtas.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "That's all. Stay safe.",
                                    },
                                    ["TL"] = {
                                        "Iyon lang. Manatiling ligtas.",
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
                            ["templateID"] = "psdl.choice.goodbye.say_1",
                        },
                    },
                },
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
                ["translations"] = {
                    ["EN"] = {
                        "That's all. Stay safe.",
                    },
                    ["TL"] = {
                        "Iyon lang. Manatiling ligtas.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_goodbye",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "You too.",
                                    },
                                    ["TL"] = {
                                        "Ikaw rin.",
                                    },
                                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "See you. Keep your head down.",
                                    },
                                    ["TL"] = {
                                        "Sige na. Huwag kang papakita sa mga 'yun.",
                                    },
                                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Be careful on the roads.",
                                    },
                                    ["TL"] = {
                                        "Maging maingat ka palagi sa labas.",
                                    },
                                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "You too.",
                                    },
                                    ["TL"] = {
                                        "Ikaw rin.",
                                    },
                                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Watch your back out there.",
                                    },
                                    ["TL"] = {
                                        "Mag-ingat ka sa labas.",
                                    },
                                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Take care. See you around.",
                                    },
                                    ["TL"] = {
                                        "Ingat. Magkikita pa tayo.",
                                    },
                                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Keep your eyes open.",
                                    },
                                    ["TL"] = {
                                        "Bantayan mo ang likod mo.",
                                    },
                                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Stay safe. Don't take unnecessary risks.",
                                    },
                                    ["TL"] = {
                                        "Manatiling ligtas. Huwag sumuong sa panganib.",
                                    },
                                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Until next time. Stay sharp.",
                                    },
                                    ["TL"] = {
                                        "Hanggang sa muli. Maging alerto.",
                                    },
                                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Yeah. Catch you later.",
                                    },
                                    ["TL"] = {
                                        "Sige. Magkita na lang tayo mamaya.",
                                    },
                                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Take it easy out there.",
                                    },
                                    ["TL"] = {
                                        "Dahan-dahan ka lang sa daan.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "You too.",
                        },
                        ["TL"] = {
                            "Ikaw rin.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "You too.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.response.goodbye.say.2.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "You too.",
                        },
                        ["TL"] = {
                            "Ikaw rin.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Watch your back out there.",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.response.goodbye.say.3.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Watch your back out there.",
                        },
                        ["TL"] = {
                            "Mag-ingat ka sa labas.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Take care. See you around.",
                    ["realizationKey"] = "4",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.response.goodbye.say.4.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Take care. See you around.",
                        },
                        ["TL"] = {
                            "Ingat. Magkikita pa tayo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Keep your eyes open.",
                    ["realizationKey"] = "5",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.response.goodbye.say.5.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Keep your eyes open.",
                        },
                        ["TL"] = {
                            "Bantayan mo ang likod mo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Stay safe. Don't take unnecessary risks.",
                    ["realizationKey"] = "6",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.response.goodbye.say.6.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Stay safe. Don't take unnecessary risks.",
                        },
                        ["TL"] = {
                            "Manatiling ligtas. Huwag sumuong sa panganib.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Until next time. Stay sharp.",
                    ["realizationKey"] = "7",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.response.goodbye.say.7.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Until next time. Stay sharp.",
                        },
                        ["TL"] = {
                            "Hanggang sa muli. Maging alerto.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Yeah. Catch you later.",
                    ["realizationKey"] = "8",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.response.goodbye.say.8.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Yeah. Catch you later.",
                        },
                        ["TL"] = {
                            "Sige. Magkita na lang tayo mamaya.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Take it easy out there.",
                    ["realizationKey"] = "9",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.response.goodbye.say.9.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Take it easy out there.",
                        },
                        ["TL"] = {
                            "Dahan-dahan ka lang sa daan.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "See you. Keep your head down.",
                    ["realizationKey"] = "10",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.response.goodbye.say.10.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "See you. Keep your head down.",
                        },
                        ["TL"] = {
                            "Sige na. Huwag kang papakita sa mga 'yun.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Be careful on the roads.",
                    ["realizationKey"] = "11",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.response.goodbye.say.11.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Be careful on the roads.",
                        },
                        ["TL"] = {
                            "Maging maingat ka palagi sa labas.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "response.goodbye",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "goodbye",
            ["sourceId"] = "response.goodbye",
            ["sourcePath"] = "dialogue/core_text_social_goodbye/response_goodbye.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextSocialGoodbye",
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
            ["metadata"] = {
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.social.goodbye.closing",
                ["sourcePath"] = "social/goodbye/closing.json",
                ["textRows"] = {
                    {
                        ["key"] = "response.goodbye",
                        ["text"] = {
                            ["EN"] = "You too.",
                            ["TL"] = "Ikaw rin.",
                        },
                    },
                    {
                        ["key"] = "response.goodbye.1",
                        ["text"] = {
                            ["EN"] = "You too.",
                            ["TL"] = "Ikaw rin.",
                        },
                    },
                    {
                        ["key"] = "response.goodbye.2",
                        ["text"] = {
                            ["EN"] = "Watch your back out there.",
                            ["TL"] = "Mag-ingat ka sa labas.",
                        },
                    },
                    {
                        ["key"] = "response.goodbye.3",
                        ["text"] = {
                            ["EN"] = "Take care. See you around.",
                            ["TL"] = "Ingat. Magkikita pa tayo.",
                        },
                    },
                    {
                        ["key"] = "response.goodbye.4",
                        ["text"] = {
                            ["EN"] = "Keep your eyes open.",
                            ["TL"] = "Bantayan mo ang likod mo.",
                        },
                    },
                    {
                        ["key"] = "response.goodbye.5",
                        ["text"] = {
                            ["EN"] = "Stay safe. Don't take unnecessary risks.",
                            ["TL"] = "Manatiling ligtas. Huwag sumuong sa panganib.",
                        },
                    },
                    {
                        ["key"] = "response.goodbye.6",
                        ["text"] = {
                            ["EN"] = "Until next time. Stay sharp.",
                            ["TL"] = "Hanggang sa muli. Maging alerto.",
                        },
                    },
                    {
                        ["key"] = "response.goodbye.7",
                        ["text"] = {
                            ["EN"] = "Yeah. Catch you later.",
                            ["TL"] = "Sige. Magkita na lang tayo mamaya.",
                        },
                    },
                    {
                        ["key"] = "response.goodbye.8",
                        ["text"] = {
                            ["EN"] = "Take it easy out there.",
                            ["TL"] = "Dahan-dahan ka lang sa daan.",
                        },
                    },
                    {
                        ["key"] = "response.goodbye.9",
                        ["text"] = {
                            ["EN"] = "See you. Keep your head down.",
                            ["TL"] = "Sige na. Huwag kang papakita sa mga 'yun.",
                        },
                    },
                    {
                        ["key"] = "response.goodbye.10",
                        ["text"] = {
                            ["EN"] = "Be careful on the roads.",
                            ["TL"] = "Maging maingat ka palagi sa labas.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "You too.",
                                    },
                                    ["TL"] = {
                                        "Ikaw rin.",
                                    },
                                },
                            },
                        },
                    },
                    ["10"] = {
                        ["key"] = "10",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "See you. Keep your head down.",
                                    },
                                    ["TL"] = {
                                        "Sige na. Huwag kang papakita sa mga 'yun.",
                                    },
                                },
                            },
                        },
                    },
                    ["11"] = {
                        ["key"] = "11",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Be careful on the roads.",
                                    },
                                    ["TL"] = {
                                        "Maging maingat ka palagi sa labas.",
                                    },
                                },
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "You too.",
                                    },
                                    ["TL"] = {
                                        "Ikaw rin.",
                                    },
                                },
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Watch your back out there.",
                                    },
                                    ["TL"] = {
                                        "Mag-ingat ka sa labas.",
                                    },
                                },
                            },
                        },
                    },
                    ["4"] = {
                        ["key"] = "4",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Take care. See you around.",
                                    },
                                    ["TL"] = {
                                        "Ingat. Magkikita pa tayo.",
                                    },
                                },
                            },
                        },
                    },
                    ["5"] = {
                        ["key"] = "5",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Keep your eyes open.",
                                    },
                                    ["TL"] = {
                                        "Bantayan mo ang likod mo.",
                                    },
                                },
                            },
                        },
                    },
                    ["6"] = {
                        ["key"] = "6",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Stay safe. Don't take unnecessary risks.",
                                    },
                                    ["TL"] = {
                                        "Manatiling ligtas. Huwag sumuong sa panganib.",
                                    },
                                },
                            },
                        },
                    },
                    ["7"] = {
                        ["key"] = "7",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Until next time. Stay sharp.",
                                    },
                                    ["TL"] = {
                                        "Hanggang sa muli. Maging alerto.",
                                    },
                                },
                            },
                        },
                    },
                    ["8"] = {
                        ["key"] = "8",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Yeah. Catch you later.",
                                    },
                                    ["TL"] = {
                                        "Sige. Magkita na lang tayo mamaya.",
                                    },
                                },
                            },
                        },
                    },
                    ["9"] = {
                        ["key"] = "9",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Take it easy out there.",
                                    },
                                    ["TL"] = {
                                        "Dahan-dahan ka lang sa daan.",
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
                            ["templateID"] = "psdl.response.goodbye.say_1",
                        },
                    },
                },
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
                ["translations"] = {
                    ["EN"] = {
                        "You too.",
                    },
                    ["TL"] = {
                        "Ikaw rin.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "You too.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.response.goodbye.say.2.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "You too.",
                    },
                    ["TL"] = {
                        "Ikaw rin.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Watch your back out there.",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.response.goodbye.say.3.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Watch your back out there.",
                    },
                    ["TL"] = {
                        "Mag-ingat ka sa labas.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Take care. See you around.",
                ["realizationKey"] = "4",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.response.goodbye.say.4.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Take care. See you around.",
                    },
                    ["TL"] = {
                        "Ingat. Magkikita pa tayo.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Keep your eyes open.",
                ["realizationKey"] = "5",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.response.goodbye.say.5.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Keep your eyes open.",
                    },
                    ["TL"] = {
                        "Bantayan mo ang likod mo.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Stay safe. Don't take unnecessary risks.",
                ["realizationKey"] = "6",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.response.goodbye.say.6.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Stay safe. Don't take unnecessary risks.",
                    },
                    ["TL"] = {
                        "Manatiling ligtas. Huwag sumuong sa panganib.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Until next time. Stay sharp.",
                ["realizationKey"] = "7",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.response.goodbye.say.7.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Until next time. Stay sharp.",
                    },
                    ["TL"] = {
                        "Hanggang sa muli. Maging alerto.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Yeah. Catch you later.",
                ["realizationKey"] = "8",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.response.goodbye.say.8.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Yeah. Catch you later.",
                    },
                    ["TL"] = {
                        "Sige. Magkita na lang tayo mamaya.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Take it easy out there.",
                ["realizationKey"] = "9",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.response.goodbye.say.9.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Take it easy out there.",
                    },
                    ["TL"] = {
                        "Dahan-dahan ka lang sa daan.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "See you. Keep your head down.",
                ["realizationKey"] = "10",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.response.goodbye.say.10.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "See you. Keep your head down.",
                    },
                    ["TL"] = {
                        "Sige na. Huwag kang papakita sa mga 'yun.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Be careful on the roads.",
                ["realizationKey"] = "11",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.response.goodbye.say.11.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Be careful on the roads.",
                    },
                    ["TL"] = {
                        "Maging maingat ka palagi sa labas.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
