-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_knowledge_activity",
        ["domainPath"] = "core_knowledge_activity",
        ["exchangeFamily"] = {
            ["familyID"] = "question.activity.dataset.keep_moving",
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
                                ["fallback"] = "We should keep moving. It's not safe to linger.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.question.activity.dataset.keep_moving.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "We need to keep moving. Sitting still will get us killed.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.question.activity.dataset.keep_moving.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Keep moving.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.question.activity.dataset.keep_moving.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Let's keep moving together, friend. We'll find safety.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.question.activity.dataset.keep_moving.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.activity.dataset",
            ["textRoles"] = {
                {
                    ["fallback"] = "We should keep moving. It's not safe to linger.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.activity.dataset.keep_moving.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "We need to keep moving. Sitting still will get us killed.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.activity.dataset.keep_moving.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Keep moving.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.activity.dataset.keep_moving.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "Let's keep moving together, friend. We'll find safety.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.activity.dataset.keep_moving.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "question.activity.dataset.keep_moving",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "keep_moving",
            ["sourceId"] = "question.activity.dataset.keep_moving",
            ["sourcePath"] = "dialogue/core_knowledge_activity/question_activity_dataset_keep_moving.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreKnowledgeActivity",
        ["namespace"] = "question.activity.dataset",
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
            ["activities"] = {
                {
                    ["id"] = "current_activity",
                    ["role"] = "actor",
                },
            },
            ["domains"] = {
                {
                    ["domain"] = "activity",
                    ["owner"] = "PsychopatzCore",
                },
            },
            ["metadata"] = {
                ["category"] = "psychopatzcore:knowledge",
                ["responseAct"] = "KNOWLEDGE_RESPONSE",
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
                                ["fallback"] = "We should keep moving. It's not safe to linger.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "We need to keep moving. Sitting still will get us killed.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Keep moving.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "Let's keep moving together, friend. We'll find safety.",
                                ["id"] = "warm",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "activity",
                    ["id"] = "activity",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "KNOWLEDGE_RESPONSE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.activity.dataset.keep_moving",
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
                            ["fallback"] = "We should keep moving. It's not safe to linger.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.activity.dataset.keep_moving.say_1",
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
        ["sourceShard"] = "dialogue/core_knowledge_activity/question_activity_dataset_keep_moving.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "We should keep moving. It's not safe to linger.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.activity.dataset.keep_moving.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "We need to keep moving. Sitting still will get us killed.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.activity.dataset.keep_moving.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Keep moving.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.activity.dataset.keep_moving.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "Let's keep moving together, friend. We'll find safety.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.activity.dataset.keep_moving.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_knowledge_activity",
        ["domainPath"] = "core_knowledge_activity",
        ["exchangeFamily"] = {
            ["familyID"] = "question.activity.fishing",
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
                                ["fallback"] = "Fishing is a solid way to secure fresh food.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.question.activity.fishing.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Fishing leaves you exposed by the water. Watch your back.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.question.activity.fishing.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Fishing.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.question.activity.fishing.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Fishing by the water sounds peaceful right now.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.question.activity.fishing.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question.activity",
            ["textRoles"] = {
                {
                    ["fallback"] = "Fishing is a solid way to secure fresh food.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.activity.fishing.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Fishing leaves you exposed by the water. Watch your back.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.activity.fishing.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Fishing.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.activity.fishing.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "Fishing by the water sounds peaceful right now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.activity.fishing.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "question.activity.fishing",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "fishing",
            ["sourceId"] = "question.activity.fishing",
            ["sourcePath"] = "dialogue/core_knowledge_activity/question_activity_fishing.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreKnowledgeActivity",
        ["namespace"] = "question.activity",
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
            ["activities"] = {
                {
                    ["id"] = "current_activity",
                    ["role"] = "actor",
                },
            },
            ["domains"] = {
                {
                    ["domain"] = "activity",
                    ["owner"] = "PsychopatzCore",
                },
            },
            ["metadata"] = {
                ["category"] = "psychopatzcore:knowledge",
                ["responseAct"] = "KNOWLEDGE_RESPONSE",
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
                                ["fallback"] = "Fishing is a solid way to secure fresh food.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "Fishing leaves you exposed by the water. Watch your back.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Fishing.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "Fishing by the water sounds peaceful right now.",
                                ["id"] = "warm",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "activity",
                    ["id"] = "activity",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "KNOWLEDGE_RESPONSE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.activity.fishing",
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
                            ["fallback"] = "Fishing is a solid way to secure fresh food.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.activity.fishing.say_1",
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
        ["sourceShard"] = "dialogue/core_knowledge_activity/question_activity_fishing.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Fishing is a solid way to secure fresh food.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.activity.fishing.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Fishing leaves you exposed by the water. Watch your back.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.activity.fishing.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Fishing.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.activity.fishing.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "Fishing by the water sounds peaceful right now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.activity.fishing.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
}
