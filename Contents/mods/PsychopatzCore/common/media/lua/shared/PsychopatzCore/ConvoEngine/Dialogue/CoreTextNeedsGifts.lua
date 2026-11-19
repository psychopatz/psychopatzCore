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
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "gift.preference",
            ["slots"] = {
                ["item"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.item",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "I don't like that.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.gift.preference.dislike.say.1.neutral",
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
            ["domains"] = {
                {
                    ["domain"] = "needs",
                    ["owner"] = "PsychopatzCore",
                },
            },
            ["metadata"] = {
                ["textKey"] = "gift.preference.dislike",
                ["textRows"] = {
                    {
                        ["fallback"] = "I don't like that.",
                        ["key"] = "gift.preference.dislike",
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
                                ["fallback"] = "I don't like that.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "needs",
                    ["id"] = "gift_preference",
                },
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
            ["item"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.item",
            },
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
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "gift.preference",
            ["slots"] = {
                ["item"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.item",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "I like that.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.gift.preference.like.say.1.neutral",
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
            ["domains"] = {
                {
                    ["domain"] = "needs",
                    ["owner"] = "PsychopatzCore",
                },
            },
            ["metadata"] = {
                ["textKey"] = "gift.preference.like",
                ["textRows"] = {
                    {
                        ["fallback"] = "I like that.",
                        ["key"] = "gift.preference.like",
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
                                ["fallback"] = "I like that.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "needs",
                    ["id"] = "gift_preference",
                },
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
            ["item"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.item",
            },
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
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "gift.preference",
            ["slots"] = {
                ["item"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.item",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "I don't have a strong preference.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.gift.preference.neutral.say.1.neutral",
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
            ["domains"] = {
                {
                    ["domain"] = "needs",
                    ["owner"] = "PsychopatzCore",
                },
            },
            ["metadata"] = {
                ["textKey"] = "gift.preference.neutral",
                ["textRows"] = {
                    {
                        ["fallback"] = "I don't have a strong preference.",
                        ["key"] = "gift.preference.neutral",
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
                                ["fallback"] = "I don't have a strong preference.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "needs",
                    ["id"] = "gift_preference",
                },
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
            ["item"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.item",
            },
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
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "gift.preference",
            ["slots"] = {
                ["item"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "entity.item",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "I'm not sure which item you mean.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.gift.preference.unknown.say.1.neutral",
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
            ["domains"] = {
                {
                    ["domain"] = "needs",
                    ["owner"] = "PsychopatzCore",
                },
            },
            ["metadata"] = {
                ["textKey"] = "gift.preference.unknown",
                ["textRows"] = {
                    {
                        ["fallback"] = "I'm not sure which item you mean.",
                        ["key"] = "gift.preference.unknown",
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
                                ["fallback"] = "I'm not sure which item you mean.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "needs",
                    ["id"] = "gift_preference",
                },
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
            ["item"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "entity.item",
            },
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
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
