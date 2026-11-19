-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_knowledge_identity",
        ["domainPath"] = "core_knowledge_identity",
        ["exchangeFamily"] = {
            ["familyID"] = "question.identity",
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
                                ["fallback"] = "I'm just a survivor trying to make it through.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.question.identity.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Who's asking? Names can be dangerous out here.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.question.identity.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "A survivor.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.question.identity.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "I'm glad to share this road with you, friend.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.question.identity.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "question",
            ["replies"] = {
                ["known"] = {
                    ["act"] = "KNOWLEDGE_RESPONSE",
                    ["outcome"] = "known",
                    ["say"] = {
                        ["keyOrder"] = {
                            "1",
                        },
                        ["mode"] = "keyed",
                        ["realizations"] = {
                            ["1"] = {
                                ["key"] = "1",
                                ["shorthand"] = false,
                                ["variants"] = {
                                    {
                                        ["fallback"] = "I'm {speaker.name}. We already know each other.",
                                        ["id"] = "neutral",
                                        ["templateID"] = "convo.question.identity.reply.known.say.1.neutral",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "I'm {speaker.name}. You should already know that.",
                                        ["id"] = "guarded",
                                        ["templateID"] = "convo.question.identity.reply.known.say.1.guarded",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "You know me. I'm {speaker.name}.",
                                        ["id"] = "terse",
                                        ["templateID"] = "convo.question.identity.reply.known.say.1.terse",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "I'm {speaker.name}. Good to see you again.",
                                        ["id"] = "warm",
                                        ["templateID"] = "convo.question.identity.reply.known.say.1.warm",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm just a survivor trying to make it through.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.identity.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Who's asking? Names can be dangerous out here.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.identity.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "A survivor.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.identity.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "I'm glad to share this road with you, friend.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.question.identity.say.1.warm",
                    ["variantID"] = "warm",
                },
                {
                    ["fallback"] = "I'm {speaker.name}. We already know each other.",
                    ["outcome"] = "known",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.identity.reply.known.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I'm {speaker.name}. You should already know that.",
                    ["outcome"] = "known",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.identity.reply.known.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "You know me. I'm {speaker.name}.",
                    ["outcome"] = "known",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.identity.reply.known.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "I'm {speaker.name}. Good to see you again.",
                    ["outcome"] = "known",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.identity.reply.known.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "question.identity",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "identity",
            ["sourceId"] = "question.identity",
            ["sourcePath"] = "dialogue/core_knowledge_identity/question_identity.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreKnowledgeIdentity",
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
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "PsychopatzCore",
                },
            },
            ["metadata"] = {
                ["category"] = "psychopatzcore:knowledge",
                ["responseAct"] = "KNOWLEDGE_RESPONSE",
            },
            ["reply"] = {
                ["known"] = {
                    ["act"] = "KNOWLEDGE_RESPONSE",
                    ["outcome"] = "known",
                    ["say"] = {
                        ["keyOrder"] = {
                            "1",
                        },
                        ["mode"] = "keyed",
                        ["realizations"] = {
                            ["1"] = {
                                ["key"] = "1",
                                ["shorthand"] = false,
                                ["variants"] = {
                                    {
                                        ["fallback"] = "I'm {speaker.name}. We already know each other.",
                                        ["id"] = "neutral",
                                    },
                                    {
                                        ["fallback"] = "I'm {speaker.name}. You should already know that.",
                                        ["id"] = "guarded",
                                    },
                                    {
                                        ["fallback"] = "You know me. I'm {speaker.name}.",
                                        ["id"] = "terse",
                                    },
                                    {
                                        ["fallback"] = "I'm {speaker.name}. Good to see you again.",
                                        ["id"] = "warm",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
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
                                ["fallback"] = "I'm just a survivor trying to make it through.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "Who's asking? Names can be dangerous out here.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "A survivor.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "I'm glad to share this road with you, friend.",
                                ["id"] = "warm",
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
            ["dialogueAct"] = "KNOWLEDGE_RESPONSE",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "question.identity",
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
                            ["fallback"] = "I'm just a survivor trying to make it through.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.question.identity.say_1",
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
        ["sourceShard"] = "dialogue/core_knowledge_identity/question_identity.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I'm just a survivor trying to make it through.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.identity.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Who's asking? Names can be dangerous out here.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.identity.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "A survivor.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.identity.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "I'm glad to share this road with you, friend.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.question.identity.say.1.warm",
                ["variantID"] = "warm",
            },
            {
                ["fallback"] = "I'm {speaker.name}. We already know each other.",
                ["outcome"] = "known",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.identity.reply.known.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I'm {speaker.name}. You should already know that.",
                ["outcome"] = "known",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.identity.reply.known.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "You know me. I'm {speaker.name}.",
                ["outcome"] = "known",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.identity.reply.known.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "I'm {speaker.name}. Good to see you again.",
                ["outcome"] = "known",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.identity.reply.known.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
}
