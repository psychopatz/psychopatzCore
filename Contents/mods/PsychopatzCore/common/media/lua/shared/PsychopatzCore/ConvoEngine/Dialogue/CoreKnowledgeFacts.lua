-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_knowledge_facts",
        ["domainPath"] = "core_knowledge_facts",
        ["exchangeFamily"] = {
            ["familyID"] = "question.knowledge",
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
                                        ["fallback"] = "I know about {target.name}.",
                                        ["id"] = "neutral",
                                        ["templateID"] = "convo.question.knowledge.reply.known.say.1.neutral",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "I know enough about {target.name}.",
                                        ["id"] = "guarded",
                                        ["templateID"] = "convo.question.knowledge.reply.known.say.1.guarded",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "I know {target.name}.",
                                        ["id"] = "terse",
                                        ["templateID"] = "convo.question.knowledge.reply.known.say.1.terse",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "I know about {target.name}.",
                                        ["id"] = "warm",
                                        ["templateID"] = "convo.question.knowledge.reply.known.say.1.warm",
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
                ["unknown"] = {
                    ["act"] = "KNOWLEDGE_RESPONSE",
                    ["outcome"] = "unknown",
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
                                        ["fallback"] = "I don't have reliable information about that.",
                                        ["id"] = "neutral",
                                        ["templateID"] = "convo.question.knowledge.reply.unknown.say.1.neutral",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "I don't know anything about that.",
                                        ["id"] = "guarded",
                                        ["templateID"] = "convo.question.knowledge.reply.unknown.say.1.guarded",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "Don't know.",
                                        ["id"] = "terse",
                                        ["templateID"] = "convo.question.knowledge.reply.unknown.say.1.terse",
                                        ["textRole"] = "response",
                                        ["variantCount"] = 10,
                                    },
                                    {
                                        ["fallback"] = "I wish I knew, but I don't know anything about that.",
                                        ["id"] = "warm",
                                        ["templateID"] = "convo.question.knowledge.reply.unknown.say.1.warm",
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
                    ["fallback"] = "I know about {target.name}.",
                    ["outcome"] = "known",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.knowledge.reply.known.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I know enough about {target.name}.",
                    ["outcome"] = "known",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.knowledge.reply.known.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "I know {target.name}.",
                    ["outcome"] = "known",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.knowledge.reply.known.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "I know about {target.name}.",
                    ["outcome"] = "known",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.knowledge.reply.known.say.1.warm",
                    ["variantID"] = "warm",
                },
                {
                    ["fallback"] = "I don't have reliable information about that.",
                    ["outcome"] = "unknown",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.knowledge.reply.unknown.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I don't know anything about that.",
                    ["outcome"] = "unknown",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.knowledge.reply.unknown.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Don't know.",
                    ["outcome"] = "unknown",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.knowledge.reply.unknown.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "I wish I knew, but I don't know anything about that.",
                    ["outcome"] = "unknown",
                    ["realizationKey"] = "1",
                    ["role"] = "response",
                    ["templateID"] = "convo.question.knowledge.reply.unknown.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "question.knowledge",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "knowledge",
            ["sourceId"] = "question.knowledge",
            ["sourcePath"] = "dialogue/core_knowledge_facts/question_knowledge.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreKnowledgeFacts",
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
                                        ["fallback"] = "I know about {target.name}.",
                                        ["id"] = "neutral",
                                    },
                                    {
                                        ["fallback"] = "I know enough about {target.name}.",
                                        ["id"] = "guarded",
                                    },
                                    {
                                        ["fallback"] = "I know {target.name}.",
                                        ["id"] = "terse",
                                    },
                                    {
                                        ["fallback"] = "I know about {target.name}.",
                                        ["id"] = "warm",
                                    },
                                },
                            },
                        },
                        ["textRole"] = "response",
                    },
                    ["textRole"] = "response",
                },
                ["unknown"] = {
                    ["act"] = "KNOWLEDGE_RESPONSE",
                    ["outcome"] = "unknown",
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
                                        ["fallback"] = "I don't have reliable information about that.",
                                        ["id"] = "neutral",
                                    },
                                    {
                                        ["fallback"] = "I don't know anything about that.",
                                        ["id"] = "guarded",
                                    },
                                    {
                                        ["fallback"] = "Don't know.",
                                        ["id"] = "terse",
                                    },
                                    {
                                        ["fallback"] = "I wish I knew, but I don't know anything about that.",
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
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "knowledge",
                },
            },
        },
        ["references"] = {
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
        ["sourceShard"] = "dialogue/core_knowledge_facts/question_knowledge.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I know about {target.name}.",
                ["outcome"] = "known",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.knowledge.reply.known.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I know enough about {target.name}.",
                ["outcome"] = "known",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.knowledge.reply.known.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "I know {target.name}.",
                ["outcome"] = "known",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.knowledge.reply.known.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "I know about {target.name}.",
                ["outcome"] = "known",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.knowledge.reply.known.say.1.warm",
                ["variantID"] = "warm",
            },
            {
                ["fallback"] = "I don't have reliable information about that.",
                ["outcome"] = "unknown",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.knowledge.reply.unknown.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I don't know anything about that.",
                ["outcome"] = "unknown",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.knowledge.reply.unknown.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Don't know.",
                ["outcome"] = "unknown",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.knowledge.reply.unknown.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "I wish I knew, but I don't know anything about that.",
                ["outcome"] = "unknown",
                ["realizationKey"] = "1",
                ["role"] = "response",
                ["templateID"] = "convo.question.knowledge.reply.unknown.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
}
