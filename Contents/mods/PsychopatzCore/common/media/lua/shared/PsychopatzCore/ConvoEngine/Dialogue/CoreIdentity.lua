-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_identity",
        ["domainPath"] = "core_identity",
        ["exchangeFamily"] = {
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                },
                ["groups"] = {
                    "identity",
                },
                ["labelFallback"] = "Ask who they are",
                ["labelKey"] = "convo.offer.question.identity.affordance.label",
                ["textRole"] = "button_label",
            },
            ["familyID"] = "offer.question.identity",
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
                                ["fallback"] = "Who are you?",
                                ["id"] = "default",
                                ["templateID"] = "convo.offer.question.identity.say.1.default",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["invoke"] = {
                ["intent"] = "QUESTION",
                ["patternID"] = "pnc.question.identity",
                ["speechAct"] = "QUESTION",
                ["subject"] = "IDENTITY",
                ["topic"] = "identity",
            },
            ["namespace"] = "offer.question",
            ["textRoles"] = {
                {
                    ["fallback"] = "Ask who they are",
                    ["role"] = "button_label",
                    ["templateID"] = "convo.offer.question.identity.affordance.label",
                },
                {
                    ["fallback"] = "Who are you?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.offer.question.identity.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "offer.question.identity",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "identity",
            ["sourceId"] = "offer.question.identity",
            ["sourcePath"] = "dialogue/core_identity/question_identity.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreIdentity",
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
                },
                ["groups"] = {
                    "identity",
                },
                ["labelFallback"] = "Ask who they are",
                ["textRole"] = "button_label",
            },
            ["closure"] = {
                ["closureClass"] = "resolved_episode",
                ["episodeId"] = "identity_exchange",
            },
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "PsychopatzCore",
                },
            },
            ["inputPolicy"] = "typed_parity",
            ["invoke"] = {
                ["intent"] = "QUESTION",
                ["patternID"] = "pnc.question.identity",
                ["speechAct"] = "QUESTION",
                ["subject"] = "IDENTITY",
                ["topic"] = "identity",
            },
            ["metadata"] = {
                ["textNamespace"] = "UI_PNC_Conversation_Suggestion",
                ["ui"] = {
                    ["domain"] = "identity",
                    ["id"] = "question.identity",
                    ["intent"] = "QUESTION",
                    ["order"] = 50,
                    ["patternID"] = "pnc.question.identity",
                    ["speechAct"] = "QUESTION",
                    ["subject"] = "IDENTITY",
                    ["topic"] = "identity",
                },
            },
            ["postconditions"] = {
                "addressee.identity_known_to_speaker",
            },
            ["repeatPolicy"] = "state_retired",
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
                                ["fallback"] = "Who are you?",
                                ["id"] = "default",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["statePolicy"] = {
                {
                    ["admission"] = "no_op",
                    ["id"] = "already_known",
                    ["outcome"] = "already_satisfied",
                    ["reason"] = "identity_already_known",
                    ["when"] = {
                        ["op"] = "eq",
                        ["path"] = "addressee.identityState",
                        ["value"] = "known",
                    },
                },
                {
                    ["admission"] = "dispatch",
                    ["id"] = "first_contact_question",
                    ["outcome"] = "actionable",
                    ["reason"] = "identity_unknown",
                },
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "identity",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "offer.question.identity",
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
                            ["fallback"] = "Who are you?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.offer.question.identity.say_1",
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
        ["sourceShard"] = "dialogue/core_identity/question_identity.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Ask who they are",
                ["role"] = "button_label",
                ["templateID"] = "convo.offer.question.identity.affordance.label",
            },
            {
                ["fallback"] = "Who are you?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.offer.question.identity.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_identity",
        ["domainPath"] = "core_identity",
        ["exchangeFamily"] = {
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                },
                ["groups"] = {
                    "identity_faction",
                },
                ["labelFallback"] = "Ask who they are with",
                ["labelKey"] = "convo.question.identity_faction.affordance.label",
                ["textRole"] = "button_label",
            },
            ["familyID"] = "question.identity_faction",
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
                                ["fallback"] = "Who are you with?",
                                ["id"] = "default",
                                ["templateID"] = "convo.question.identity_faction.say.1.default",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["invoke"] = {
                ["intent"] = "QUESTION",
                ["patternID"] = "pnc.question.identity.faction",
                ["speechAct"] = "QUESTION",
                ["subject"] = "IDENTITY_FACTION",
                ["topic"] = "identity_faction",
            },
            ["namespace"] = "question",
            ["textRoles"] = {
                {
                    ["fallback"] = "Ask who they are with",
                    ["role"] = "button_label",
                    ["templateID"] = "convo.question.identity_faction.affordance.label",
                },
                {
                    ["fallback"] = "Who are you with?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.identity_faction.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "question.identity_faction",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "identity_faction",
            ["sourceId"] = "question.identity_faction",
            ["sourcePath"] = "dialogue/core_identity/question_identity_faction.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreIdentity",
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
                },
                ["groups"] = {
                    "identity_faction",
                },
                ["labelFallback"] = "Ask who they are with",
                ["textRole"] = "button_label",
            },
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "PsychopatzCore",
                },
            },
            ["invoke"] = {
                ["intent"] = "QUESTION",
                ["patternID"] = "pnc.question.identity.faction",
                ["speechAct"] = "QUESTION",
                ["subject"] = "IDENTITY_FACTION",
                ["topic"] = "identity_faction",
            },
            ["metadata"] = {
                ["textNamespace"] = "UI_PNC_Conversation_Suggestion",
                ["ui"] = {
                    ["domain"] = "identity_faction",
                    ["id"] = "question.identity_faction",
                    ["intent"] = "QUESTION",
                    ["order"] = 53,
                    ["patternID"] = "pnc.question.identity.faction",
                    ["speechAct"] = "QUESTION",
                    ["subject"] = "IDENTITY_FACTION",
                    ["topic"] = "identity_faction",
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
                                ["fallback"] = "Who are you with?",
                                ["id"] = "default",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "identity",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.identity_faction",
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
                            ["fallback"] = "Who are you with?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.identity_faction.say_1",
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
        ["sourceShard"] = "dialogue/core_identity/question_identity_faction.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Ask who they are with",
                ["role"] = "button_label",
                ["templateID"] = "convo.question.identity_faction.affordance.label",
            },
            {
                ["fallback"] = "Who are you with?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.identity_faction.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_identity",
        ["domainPath"] = "core_identity",
        ["exchangeFamily"] = {
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                },
                ["groups"] = {
                    "identity_nickname",
                },
                ["labelFallback"] = "Ask what people call them",
                ["labelKey"] = "convo.question.identity_nickname.affordance.label",
                ["textRole"] = "button_label",
            },
            ["familyID"] = "question.identity_nickname",
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
                                ["fallback"] = "What do people call you?",
                                ["id"] = "default",
                                ["templateID"] = "convo.question.identity_nickname.say.1.default",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["invoke"] = {
                ["intent"] = "QUESTION",
                ["patternID"] = "pnc.question.identity.nickname",
                ["speechAct"] = "QUESTION",
                ["subject"] = "IDENTITY_NICKNAME",
                ["topic"] = "identity_nickname",
            },
            ["namespace"] = "question",
            ["textRoles"] = {
                {
                    ["fallback"] = "Ask what people call them",
                    ["role"] = "button_label",
                    ["templateID"] = "convo.question.identity_nickname.affordance.label",
                },
                {
                    ["fallback"] = "What do people call you?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.identity_nickname.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "question.identity_nickname",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "identity_nickname",
            ["sourceId"] = "question.identity_nickname",
            ["sourcePath"] = "dialogue/core_identity/question_identity_nickname.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreIdentity",
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
                },
                ["groups"] = {
                    "identity_nickname",
                },
                ["labelFallback"] = "Ask what people call them",
                ["textRole"] = "button_label",
            },
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "PsychopatzCore",
                },
            },
            ["invoke"] = {
                ["intent"] = "QUESTION",
                ["patternID"] = "pnc.question.identity.nickname",
                ["speechAct"] = "QUESTION",
                ["subject"] = "IDENTITY_NICKNAME",
                ["topic"] = "identity_nickname",
            },
            ["metadata"] = {
                ["textNamespace"] = "UI_PNC_Conversation_Suggestion",
                ["ui"] = {
                    ["domain"] = "identity_nickname",
                    ["id"] = "question.identity_nickname",
                    ["intent"] = "QUESTION",
                    ["order"] = 51,
                    ["patternID"] = "pnc.question.identity.nickname",
                    ["speechAct"] = "QUESTION",
                    ["subject"] = "IDENTITY_NICKNAME",
                    ["topic"] = "identity_nickname",
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
                                ["fallback"] = "What do people call you?",
                                ["id"] = "default",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "identity",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.identity_nickname",
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
                            ["fallback"] = "What do people call you?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.identity_nickname.say_1",
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
        ["sourceShard"] = "dialogue/core_identity/question_identity_nickname.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Ask what people call them",
                ["role"] = "button_label",
                ["templateID"] = "convo.question.identity_nickname.affordance.label",
            },
            {
                ["fallback"] = "What do people call you?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.identity_nickname.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_identity",
        ["domainPath"] = "core_identity",
        ["exchangeFamily"] = {
            ["affordance"] = {
                ["consumers"] = {
                    "player",
                },
                ["groups"] = {
                    "identity_surname",
                },
                ["labelFallback"] = "Ask their surname",
                ["labelKey"] = "convo.question.identity_surname.affordance.label",
                ["textRole"] = "button_label",
            },
            ["familyID"] = "question.identity_surname",
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
                                ["fallback"] = "What's your surname?",
                                ["id"] = "default",
                                ["templateID"] = "convo.question.identity_surname.say.1.default",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["invoke"] = {
                ["intent"] = "QUESTION",
                ["patternID"] = "pnc.question.identity.surname",
                ["speechAct"] = "QUESTION",
                ["subject"] = "IDENTITY_SURNAME",
                ["topic"] = "identity_surname",
            },
            ["namespace"] = "question",
            ["textRoles"] = {
                {
                    ["fallback"] = "Ask their surname",
                    ["role"] = "button_label",
                    ["templateID"] = "convo.question.identity_surname.affordance.label",
                },
                {
                    ["fallback"] = "What's your surname?",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.identity_surname.say.1.default",
                    ["variantID"] = "default",
                },
            },
        },
        ["id"] = "question.identity_surname",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "identity_surname",
            ["sourceId"] = "question.identity_surname",
            ["sourcePath"] = "dialogue/core_identity/question_identity_surname.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreIdentity",
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
                },
                ["groups"] = {
                    "identity_surname",
                },
                ["labelFallback"] = "Ask their surname",
                ["textRole"] = "button_label",
            },
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "PsychopatzCore",
                },
            },
            ["invoke"] = {
                ["intent"] = "QUESTION",
                ["patternID"] = "pnc.question.identity.surname",
                ["speechAct"] = "QUESTION",
                ["subject"] = "IDENTITY_SURNAME",
                ["topic"] = "identity_surname",
            },
            ["metadata"] = {
                ["textNamespace"] = "UI_PNC_Conversation_Suggestion",
                ["ui"] = {
                    ["domain"] = "identity_surname",
                    ["id"] = "question.identity_surname",
                    ["intent"] = "QUESTION",
                    ["order"] = 52,
                    ["patternID"] = "pnc.question.identity.surname",
                    ["speechAct"] = "QUESTION",
                    ["subject"] = "IDENTITY_SURNAME",
                    ["topic"] = "identity_surname",
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
                                ["fallback"] = "What's your surname?",
                                ["id"] = "default",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "identity",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.identity_surname",
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
                            ["fallback"] = "What's your surname?",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.identity_surname.say_1",
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
        ["sourceShard"] = "dialogue/core_identity/question_identity_surname.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Ask their surname",
                ["role"] = "button_label",
                ["templateID"] = "convo.question.identity_surname.affordance.label",
            },
            {
                ["fallback"] = "What's your surname?",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.identity_surname.say.1.default",
                ["variantID"] = "default",
            },
        },
        ["when"] = nil,
    },
}
