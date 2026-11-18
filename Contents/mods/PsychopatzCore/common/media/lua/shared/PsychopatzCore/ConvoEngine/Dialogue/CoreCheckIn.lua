-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_check_in",
        ["domainPath"] = "core_check_in",
        ["exchangeFamily"] = {
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                    "npc",
                },
                ["groups"] = {
                    "activity",
                },
                ["labelFallback"] = "Ask what they've been doing",
                ["labelKey"] = "convo.offer.question.activity.affordance.label",
                ["textRole"] = "button_label",
                ["translations"] = {
                    ["EN"] = {
                        "Ask what they've been doing",
                    },
                    ["TL"] = {
                        "Itanong ang pinagkakaabalahan",
                    },
                },
            },
            ["familyID"] = "offer.question.activity",
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
                                ["fallback"] = "What have you been doing?",
                                ["id"] = "default",
                                ["templateID"] = "convo.offer.question.activity.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "What have you been doing?",
                                    },
                                    ["TL"] = {
                                        "Ano ang mga pinagkakaabalahan mo?",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["invoke"] = {
                ["intent"] = "QUESTION",
                ["patternID"] = "pnc.question.activity",
                ["speechAct"] = "QUESTION",
                ["subject"] = "ACTIVITY",
                ["topic"] = "activity",
            },
            ["namespace"] = "offer.question",
            ["textRoles"] = {
                {
                    ["fallback"] = "Ask what they've been doing",
                    ["role"] = "button_label",
                    ["templateID"] = "convo.offer.question.activity.affordance.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Ask what they've been doing",
                        },
                        ["TL"] = {
                            "Itanong ang pinagkakaabalahan",
                        },
                    },
                },
                {
                    ["fallback"] = "What have you been doing?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.offer.question.activity.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "What have you been doing?",
                        },
                        ["TL"] = {
                            "Ano ang mga pinagkakaabalahan mo?",
                        },
                    },
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "offer.question.activity",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "activity",
            ["sourceId"] = "offer.question.activity",
            ["sourcePath"] = "dialogue/core_check_in/question_activity.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreCheckIn",
        ["namespace"] = "offer.question",
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
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                    "npc",
                },
                ["groups"] = {
                    "activity",
                },
                ["label"] = {
                    ["EN"] = {
                        "Ask what they've been doing",
                    },
                    ["TL"] = {
                        "Itanong ang pinagkakaabalahan",
                    },
                },
                ["textRole"] = "button_label",
            },
            ["invoke"] = {
                ["intent"] = "QUESTION",
                ["patternID"] = "pnc.question.activity",
                ["speechAct"] = "QUESTION",
                ["subject"] = "ACTIVITY",
                ["topic"] = "activity",
            },
            ["metadata"] = {
                ["textNamespace"] = "UI_PNC_Conversation_Suggestion",
                ["ui"] = {
                    ["domain"] = "activity",
                    ["extensions"] = {
                        ["topic"] = "activity",
                    },
                    ["hubID"] = "whats_up",
                    ["hubOnly"] = true,
                    ["id"] = "question.activity",
                    ["intent"] = "QUESTION",
                    ["order"] = 60,
                    ["patternID"] = "pnc.question.activity",
                    ["speechAct"] = "QUESTION",
                    ["subject"] = "ACTIVITY",
                    ["topic"] = "activity",
                },
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
                                ["id"] = "default",
                                ["text"] = {
                                    ["EN"] = {
                                        "What have you been doing?",
                                    },
                                    ["TL"] = {
                                        "Ano ang mga pinagkakaabalahan mo?",
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
            ["responsePlanID"] = "offer.question.activity",
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
                            ["fallback"] = "What have you been doing?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.offer.question.activity.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_check_in/question_activity.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Ask what they've been doing",
                ["role"] = "button_label",
                ["templateID"] = "convo.offer.question.activity.affordance.label",
                ["translations"] = {
                    ["EN"] = {
                        "Ask what they've been doing",
                    },
                    ["TL"] = {
                        "Itanong ang pinagkakaabalahan",
                    },
                },
            },
            {
                ["fallback"] = "What have you been doing?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.offer.question.activity.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "What have you been doing?",
                    },
                    ["TL"] = {
                        "Ano ang mga pinagkakaabalahan mo?",
                    },
                },
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_check_in",
        ["domainPath"] = "core_check_in",
        ["exchangeFamily"] = {
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                    "npc",
                },
                ["groups"] = {
                    "wellbeing",
                },
                ["labelFallback"] = "Ask about wellbeing",
                ["labelKey"] = "convo.offer.question.wellbeing.affordance.label",
                ["textRole"] = "button_label",
                ["translations"] = {
                    ["EN"] = {
                        "Ask about wellbeing",
                    },
                    ["TL"] = {
                        "Itanong ang kalagayan",
                    },
                },
                ["utility"] = {
                    ["social"] = 1.2,
                },
            },
            ["after"] = {
                ["recommend"] = {
                    "question.wellbeing_detail",
                },
            },
            ["familyID"] = "offer.question.wellbeing",
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
                                ["fallback"] = "How are you feeling?",
                                ["id"] = "default",
                                ["templateID"] = "convo.offer.question.wellbeing.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "How are you feeling?",
                                    },
                                    ["TL"] = {
                                        "Kumusta ang pakiramdam mo?",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["invoke"] = {
                ["intent"] = "QUESTION",
                ["patternID"] = "pnc.question.wellbeing_feeling",
                ["speechAct"] = "QUESTION",
                ["subject"] = "WELLBEING",
                ["topic"] = "wellbeing",
            },
            ["namespace"] = "offer.question",
            ["textRoles"] = {
                {
                    ["fallback"] = "Ask about wellbeing",
                    ["role"] = "button_label",
                    ["templateID"] = "convo.offer.question.wellbeing.affordance.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Ask about wellbeing",
                        },
                        ["TL"] = {
                            "Itanong ang kalagayan",
                        },
                    },
                },
                {
                    ["fallback"] = "How are you feeling?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.offer.question.wellbeing.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "How are you feeling?",
                        },
                        ["TL"] = {
                            "Kumusta ang pakiramdam mo?",
                        },
                    },
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "offer.question.wellbeing",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "wellbeing",
            ["sourceId"] = "offer.question.wellbeing",
            ["sourcePath"] = "dialogue/core_check_in/question_wellbeing.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreCheckIn",
        ["namespace"] = "offer.question",
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
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                    "npc",
                },
                ["groups"] = {
                    "wellbeing",
                },
                ["label"] = {
                    ["EN"] = {
                        "Ask about wellbeing",
                    },
                    ["TL"] = {
                        "Itanong ang kalagayan",
                    },
                },
                ["textRole"] = "button_label",
                ["utility"] = {
                    ["social"] = 1.2,
                },
            },
            ["after"] = {
                ["recommend"] = {
                    "question.wellbeing_detail",
                },
            },
            ["invoke"] = {
                ["intent"] = "QUESTION",
                ["patternID"] = "pnc.question.wellbeing_feeling",
                ["speechAct"] = "QUESTION",
                ["subject"] = "WELLBEING",
                ["topic"] = "wellbeing",
            },
            ["metadata"] = {
                ["textNamespace"] = "UI_PNC_Conversation_Suggestion",
                ["ui"] = {
                    ["domain"] = "wellbeing",
                    ["hubID"] = "whats_up",
                    ["hubOnly"] = true,
                    ["id"] = "question.wellbeing",
                    ["intent"] = "QUESTION",
                    ["order"] = 10,
                    ["patternID"] = "pnc.question.wellbeing_feeling",
                    ["speechAct"] = "QUESTION",
                    ["subject"] = "WELLBEING",
                    ["topic"] = "wellbeing",
                },
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
                                ["id"] = "default",
                                ["text"] = {
                                    ["EN"] = {
                                        "How are you feeling?",
                                    },
                                    ["TL"] = {
                                        "Kumusta ang pakiramdam mo?",
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
            ["responsePlanID"] = "offer.question.wellbeing",
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
                            ["fallback"] = "How are you feeling?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.offer.question.wellbeing.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_check_in/question_wellbeing.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Ask about wellbeing",
                ["role"] = "button_label",
                ["templateID"] = "convo.offer.question.wellbeing.affordance.label",
                ["translations"] = {
                    ["EN"] = {
                        "Ask about wellbeing",
                    },
                    ["TL"] = {
                        "Itanong ang kalagayan",
                    },
                },
            },
            {
                ["fallback"] = "How are you feeling?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.offer.question.wellbeing.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "How are you feeling?",
                    },
                    ["TL"] = {
                        "Kumusta ang pakiramdam mo?",
                    },
                },
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_check_in",
        ["domainPath"] = "core_check_in",
        ["exchangeFamily"] = {
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                    "npc",
                },
                ["groups"] = {
                    "date",
                },
                ["labelFallback"] = "Ask about the date",
                ["labelKey"] = "convo.question.date.affordance.label",
                ["textRole"] = "button_label",
                ["translations"] = {
                    ["EN"] = {
                        "Ask about the date",
                    },
                    ["TL"] = {
                        "Itanong ang petsa",
                    },
                },
            },
            ["familyID"] = "question.date",
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
                                ["fallback"] = "What's today's date?",
                                ["id"] = "default",
                                ["templateID"] = "convo.question.date.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "What's today's date?",
                                    },
                                    ["TL"] = {
                                        "Ano ang petsa ngayon?",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["invoke"] = {
                ["intent"] = "QUESTION",
                ["patternID"] = "pnc.question.date",
                ["speechAct"] = "QUESTION",
                ["subject"] = "DATE",
                ["topic"] = "date",
            },
            ["namespace"] = "question",
            ["textRoles"] = {
                {
                    ["fallback"] = "Ask about the date",
                    ["role"] = "button_label",
                    ["templateID"] = "convo.question.date.affordance.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Ask about the date",
                        },
                        ["TL"] = {
                            "Itanong ang petsa",
                        },
                    },
                },
                {
                    ["fallback"] = "What's today's date?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.date.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "What's today's date?",
                        },
                        ["TL"] = {
                            "Ano ang petsa ngayon?",
                        },
                    },
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "question.date",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "date",
            ["sourceId"] = "question.date",
            ["sourcePath"] = "dialogue/core_check_in/question_date.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreCheckIn",
        ["namespace"] = "question",
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
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                    "npc",
                },
                ["groups"] = {
                    "date",
                },
                ["label"] = {
                    ["EN"] = {
                        "Ask about the date",
                    },
                    ["TL"] = {
                        "Itanong ang petsa",
                    },
                },
                ["textRole"] = "button_label",
            },
            ["invoke"] = {
                ["intent"] = "QUESTION",
                ["patternID"] = "pnc.question.date",
                ["speechAct"] = "QUESTION",
                ["subject"] = "DATE",
                ["topic"] = "date",
            },
            ["metadata"] = {
                ["textNamespace"] = "UI_PNC_Conversation_Suggestion",
                ["ui"] = {
                    ["domain"] = "date",
                    ["id"] = "question.date",
                    ["intent"] = "QUESTION",
                    ["order"] = 70,
                    ["patternID"] = "pnc.question.date",
                    ["speechAct"] = "QUESTION",
                    ["subject"] = "DATE",
                    ["topic"] = "date",
                },
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
                                ["id"] = "default",
                                ["text"] = {
                                    ["EN"] = {
                                        "What's today's date?",
                                    },
                                    ["TL"] = {
                                        "Ano ang petsa ngayon?",
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
            ["responsePlanID"] = "question.date",
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
                            ["fallback"] = "What's today's date?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.date.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_check_in/question_date.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Ask about the date",
                ["role"] = "button_label",
                ["templateID"] = "convo.question.date.affordance.label",
                ["translations"] = {
                    ["EN"] = {
                        "Ask about the date",
                    },
                    ["TL"] = {
                        "Itanong ang petsa",
                    },
                },
            },
            {
                ["fallback"] = "What's today's date?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.date.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "What's today's date?",
                    },
                    ["TL"] = {
                        "Ano ang petsa ngayon?",
                    },
                },
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_check_in",
        ["domainPath"] = "core_check_in",
        ["exchangeFamily"] = {
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                    "npc",
                },
                ["groups"] = {
                    "time",
                },
                ["labelFallback"] = "Ask about the time",
                ["labelKey"] = "convo.question.time.affordance.label",
                ["textRole"] = "button_label",
                ["translations"] = {
                    ["EN"] = {
                        "Ask about the time",
                    },
                    ["TL"] = {
                        "Itanong ang oras",
                    },
                },
            },
            ["familyID"] = "question.time",
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
                                ["fallback"] = "What time is it?",
                                ["id"] = "default",
                                ["templateID"] = "convo.question.time.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "What time is it?",
                                    },
                                    ["TL"] = {
                                        "Anong oras na?",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["invoke"] = {
                ["intent"] = "QUESTION",
                ["patternID"] = "pnc.question.time",
                ["speechAct"] = "QUESTION",
                ["subject"] = "TIME",
                ["topic"] = "time",
            },
            ["namespace"] = "question",
            ["textRoles"] = {
                {
                    ["fallback"] = "Ask about the time",
                    ["role"] = "button_label",
                    ["templateID"] = "convo.question.time.affordance.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Ask about the time",
                        },
                        ["TL"] = {
                            "Itanong ang oras",
                        },
                    },
                },
                {
                    ["fallback"] = "What time is it?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.time.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "What time is it?",
                        },
                        ["TL"] = {
                            "Anong oras na?",
                        },
                    },
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "question.time",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "time",
            ["sourceId"] = "question.time",
            ["sourcePath"] = "dialogue/core_check_in/question_time.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreCheckIn",
        ["namespace"] = "question",
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
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                    "npc",
                },
                ["groups"] = {
                    "time",
                },
                ["label"] = {
                    ["EN"] = {
                        "Ask about the time",
                    },
                    ["TL"] = {
                        "Itanong ang oras",
                    },
                },
                ["textRole"] = "button_label",
            },
            ["invoke"] = {
                ["intent"] = "QUESTION",
                ["patternID"] = "pnc.question.time",
                ["speechAct"] = "QUESTION",
                ["subject"] = "TIME",
                ["topic"] = "time",
            },
            ["metadata"] = {
                ["textNamespace"] = "UI_PNC_Conversation_Suggestion",
                ["ui"] = {
                    ["domain"] = "time",
                    ["id"] = "question.time",
                    ["intent"] = "QUESTION",
                    ["order"] = 60,
                    ["patternID"] = "pnc.question.time",
                    ["speechAct"] = "QUESTION",
                    ["subject"] = "TIME",
                    ["topic"] = "time",
                },
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
                                ["id"] = "default",
                                ["text"] = {
                                    ["EN"] = {
                                        "What time is it?",
                                    },
                                    ["TL"] = {
                                        "Anong oras na?",
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
            ["responsePlanID"] = "question.time",
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
                            ["fallback"] = "What time is it?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.time.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_check_in/question_time.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Ask about the time",
                ["role"] = "button_label",
                ["templateID"] = "convo.question.time.affordance.label",
                ["translations"] = {
                    ["EN"] = {
                        "Ask about the time",
                    },
                    ["TL"] = {
                        "Itanong ang oras",
                    },
                },
            },
            {
                ["fallback"] = "What time is it?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.time.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "What time is it?",
                    },
                    ["TL"] = {
                        "Anong oras na?",
                    },
                },
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_check_in",
        ["domainPath"] = "core_check_in",
        ["exchangeFamily"] = {
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                    "npc",
                },
                ["groups"] = {
                    "weather",
                },
                ["labelFallback"] = "Ask about the weather",
                ["labelKey"] = "convo.question.weather.affordance.label",
                ["textRole"] = "button_label",
                ["translations"] = {
                    ["EN"] = {
                        "Ask about the weather",
                    },
                    ["TL"] = {
                        "Itanong ang panahon",
                    },
                },
            },
            ["familyID"] = "question.weather",
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
                                ["fallback"] = "How is the weather?",
                                ["id"] = "default",
                                ["templateID"] = "convo.question.weather.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "How is the weather?",
                                    },
                                    ["TL"] = {
                                        "Kumusta ang panahon?",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["invoke"] = {
                ["intent"] = "QUESTION",
                ["patternID"] = "pnc.question.weather",
                ["speechAct"] = "QUESTION",
                ["subject"] = "WEATHER",
                ["topic"] = "weather",
            },
            ["namespace"] = "question",
            ["textRoles"] = {
                {
                    ["fallback"] = "Ask about the weather",
                    ["role"] = "button_label",
                    ["templateID"] = "convo.question.weather.affordance.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Ask about the weather",
                        },
                        ["TL"] = {
                            "Itanong ang panahon",
                        },
                    },
                },
                {
                    ["fallback"] = "How is the weather?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.weather.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "How is the weather?",
                        },
                        ["TL"] = {
                            "Kumusta ang panahon?",
                        },
                    },
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "question.weather",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "weather",
            ["sourceId"] = "question.weather",
            ["sourcePath"] = "dialogue/core_check_in/question_weather.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreCheckIn",
        ["namespace"] = "question",
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
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                    "npc",
                },
                ["groups"] = {
                    "weather",
                },
                ["label"] = {
                    ["EN"] = {
                        "Ask about the weather",
                    },
                    ["TL"] = {
                        "Itanong ang panahon",
                    },
                },
                ["textRole"] = "button_label",
            },
            ["invoke"] = {
                ["intent"] = "QUESTION",
                ["patternID"] = "pnc.question.weather",
                ["speechAct"] = "QUESTION",
                ["subject"] = "WEATHER",
                ["topic"] = "weather",
            },
            ["metadata"] = {
                ["textNamespace"] = "UI_PNC_Conversation_Suggestion",
                ["ui"] = {
                    ["domain"] = "weather",
                    ["hubID"] = "whats_up",
                    ["hubOnly"] = true,
                    ["id"] = "question.weather",
                    ["intent"] = "QUESTION",
                    ["order"] = 80,
                    ["patternID"] = "pnc.question.weather",
                    ["speechAct"] = "QUESTION",
                    ["subject"] = "WEATHER",
                    ["topic"] = "weather",
                },
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
                                ["id"] = "default",
                                ["text"] = {
                                    ["EN"] = {
                                        "How is the weather?",
                                    },
                                    ["TL"] = {
                                        "Kumusta ang panahon?",
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
            ["responsePlanID"] = "question.weather",
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
                            ["fallback"] = "How is the weather?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.weather.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_check_in/question_weather.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Ask about the weather",
                ["role"] = "button_label",
                ["templateID"] = "convo.question.weather.affordance.label",
                ["translations"] = {
                    ["EN"] = {
                        "Ask about the weather",
                    },
                    ["TL"] = {
                        "Itanong ang panahon",
                    },
                },
            },
            {
                ["fallback"] = "How is the weather?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.weather.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "How is the weather?",
                    },
                    ["TL"] = {
                        "Kumusta ang panahon?",
                    },
                },
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_check_in",
        ["domainPath"] = "core_check_in",
        ["exchangeFamily"] = {
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                    "npc",
                },
                ["groups"] = {
                    "wellbeing",
                },
                ["labelFallback"] = "Ask what is wrong",
                ["labelKey"] = "convo.question.wellbeing_detail.affordance.label",
                ["textRole"] = "button_label",
                ["translations"] = {
                    ["EN"] = {
                        "Ask what is wrong",
                    },
                    ["TL"] = {
                        "Itanong kung ano ang problema",
                    },
                },
            },
            ["familyID"] = "question.wellbeing_detail",
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
                                ["fallback"] = "What's wrong?",
                                ["id"] = "default",
                                ["templateID"] = "convo.question.wellbeing_detail.say.1.default",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "What's wrong?",
                                    },
                                    ["TL"] = {
                                        "Ano ang problema?",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["invoke"] = {
                ["intent"] = "QUESTION",
                ["patternID"] = "pnc.question.wellbeing_follow_up_what_is_wrong",
                ["speechAct"] = "QUESTION",
                ["subject"] = "WELLBEING",
                ["topic"] = "wellbeing",
            },
            ["namespace"] = "question",
            ["textRoles"] = {
                {
                    ["fallback"] = "Ask what is wrong",
                    ["role"] = "button_label",
                    ["templateID"] = "convo.question.wellbeing_detail.affordance.label",
                    ["translations"] = {
                        ["EN"] = {
                            "Ask what is wrong",
                        },
                        ["TL"] = {
                            "Itanong kung ano ang problema",
                        },
                    },
                },
                {
                    ["fallback"] = "What's wrong?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.wellbeing_detail.say.1.default",
                    ["translations"] = {
                        ["EN"] = {
                            "What's wrong?",
                        },
                        ["TL"] = {
                            "Ano ang problema?",
                        },
                    },
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "question.wellbeing_detail",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "wellbeing_detail",
            ["sourceId"] = "question.wellbeing_detail",
            ["sourcePath"] = "dialogue/core_check_in/question_wellbeing_detail.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreCheckIn",
        ["namespace"] = "question",
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
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                    "npc",
                },
                ["groups"] = {
                    "wellbeing",
                },
                ["label"] = {
                    ["EN"] = {
                        "Ask what is wrong",
                    },
                    ["TL"] = {
                        "Itanong kung ano ang problema",
                    },
                },
                ["textRole"] = "button_label",
            },
            ["invoke"] = {
                ["intent"] = "QUESTION",
                ["patternID"] = "pnc.question.wellbeing_follow_up_what_is_wrong",
                ["speechAct"] = "QUESTION",
                ["subject"] = "WELLBEING",
                ["topic"] = "wellbeing",
            },
            ["metadata"] = {
                ["textNamespace"] = "UI_PNC_Conversation_Suggestion",
                ["ui"] = {
                    ["domain"] = "wellbeing",
                    ["extensions"] = {
                        ["topic"] = "wellbeing",
                    },
                    ["id"] = "question.wellbeing_detail",
                    ["intent"] = "QUESTION",
                    ["order"] = 20,
                    ["patternID"] = "pnc.question.wellbeing_follow_up_what_is_wrong",
                    ["speechAct"] = "QUESTION",
                    ["subject"] = "WELLBEING",
                    ["topic"] = "wellbeing",
                },
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
                                ["id"] = "default",
                                ["text"] = {
                                    ["EN"] = {
                                        "What's wrong?",
                                    },
                                    ["TL"] = {
                                        "Ano ang problema?",
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
            ["responsePlanID"] = "question.wellbeing_detail",
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
                            ["fallback"] = "What's wrong?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.wellbeing_detail.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_check_in/question_wellbeing_detail.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Ask what is wrong",
                ["role"] = "button_label",
                ["templateID"] = "convo.question.wellbeing_detail.affordance.label",
                ["translations"] = {
                    ["EN"] = {
                        "Ask what is wrong",
                    },
                    ["TL"] = {
                        "Itanong kung ano ang problema",
                    },
                },
            },
            {
                ["fallback"] = "What's wrong?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.wellbeing_detail.say.1.default",
                ["translations"] = {
                    ["EN"] = {
                        "What's wrong?",
                    },
                    ["TL"] = {
                        "Ano ang problema?",
                    },
                },
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
}
