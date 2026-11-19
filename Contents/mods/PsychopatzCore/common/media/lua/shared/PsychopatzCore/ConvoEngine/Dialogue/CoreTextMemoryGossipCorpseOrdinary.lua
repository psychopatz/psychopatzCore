-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_text_memory_gossip_corpse_ordinary",
        ["domainPath"] = "core_text_memory_gossip_corpse_ordinary",
        ["exchangeFamily"] = {
            ["familyID"] = "corpse.comrade",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                    "4",
                    "5",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "One less of us, {target.name}. Damn.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.comrade.say.1.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "You stood with {slot.faction.name}, {target.name}. We won't forget.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.comrade.say.2.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "We fought side by side, {target.name}. Rest easy.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.comrade.say.3.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["4"] = {
                        ["key"] = "4",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "{target.name} held the line. We'll carry on.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.comrade.say.4.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["5"] = {
                        ["key"] = "5",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I hope {slot.faction.name} remembers what you gave.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.comrade.say.5.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "corpse",
            ["slots"] = {
                ["faction"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = true,
                    ["type"] = "entity.faction",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "One less of us, {target.name}. Damn.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.comrade.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "You stood with {slot.faction.name}, {target.name}. We won't forget.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.comrade.say.2.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "We fought side by side, {target.name}. Rest easy.",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.comrade.say.3.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "{target.name} held the line. We'll carry on.",
                    ["realizationKey"] = "4",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.comrade.say.4.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I hope {slot.faction.name} remembers what you gave.",
                    ["realizationKey"] = "5",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.comrade.say.5.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "corpse.comrade",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "comrade",
            ["sourceId"] = "corpse.comrade",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_ordinary/corpse_comrade.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextMemoryGossipCorpseOrdinary",
        ["namespace"] = "corpse",
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
                    ["domain"] = "memory",
                    ["owner"] = "PsychopatzCore",
                },
            },
            ["events"] = {
                {
                    ["id"] = "character_death",
                    ["kind"] = "world_event",
                },
            },
            ["memories"] = {
                {
                    ["id"] = "death_episode",
                    ["scope"] = "durable",
                },
            },
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["fallback"] = "One less of us, {target.name}. Damn.",
                        ["key"] = "corpse.comrade.01",
                    },
                    {
                        ["fallback"] = "You stood with {slot.faction.name}, {target.name}. We won't forget.",
                        ["key"] = "corpse.comrade.02",
                    },
                    {
                        ["fallback"] = "We fought side by side, {target.name}. Rest easy.",
                        ["key"] = "corpse.comrade.03",
                    },
                    {
                        ["fallback"] = "{target.name} held the line. We'll carry on.",
                        ["key"] = "corpse.comrade.04",
                    },
                    {
                        ["fallback"] = "I hope {slot.faction.name} remembers what you gave.",
                        ["key"] = "corpse.comrade.05",
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                    "4",
                    "5",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "One less of us, {target.name}. Damn.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "You stood with {slot.faction.name}, {target.name}. We won't forget.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "We fought side by side, {target.name}. Rest easy.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["4"] = {
                        ["key"] = "4",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "{target.name} held the line. We'll carry on.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["5"] = {
                        ["key"] = "5",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I hope {slot.faction.name} remembers what you gave.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "memory",
                    ["id"] = "death",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "corpse.comrade",
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
                            ["fallback"] = "One less of us, {target.name}. Damn.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.corpse.comrade.say_1",
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
            ["subject"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "subject",
            },
        },
        ["slots"] = {
            ["faction"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = true,
                ["type"] = "entity.faction",
            },
        },
        ["sourceShard"] = "dialogue/core_text_memory_gossip_corpse_ordinary/corpse_comrade.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "One less of us, {target.name}. Damn.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.comrade.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "You stood with {slot.faction.name}, {target.name}. We won't forget.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.comrade.say.2.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "We fought side by side, {target.name}. Rest easy.",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.comrade.say.3.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "{target.name} held the line. We'll carry on.",
                ["realizationKey"] = "4",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.comrade.say.4.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I hope {slot.faction.name} remembers what you gave.",
                ["realizationKey"] = "5",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.comrade.say.5.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_ordinary",
        ["domainPath"] = "core_text_memory_gossip_corpse_ordinary",
        ["exchangeFamily"] = {
            ["familyID"] = "corpse.friend",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                    "4",
                    "5",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "We were supposed to get through this together, {target.name}.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.friend.say.1.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "You always had my back, {target.name}. I should've had yours.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.friend.say.2.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I won't let them forget you, {target.name}.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.friend.say.3.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["4"] = {
                        ["key"] = "4",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Rest now, {target.name}. You did enough.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.friend.say.4.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["5"] = {
                        ["key"] = "5",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "We still owed each other a drink, {target.name}.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.friend.say.5.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "corpse",
            ["textRoles"] = {
                {
                    ["fallback"] = "We were supposed to get through this together, {target.name}.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.friend.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "You always had my back, {target.name}. I should've had yours.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.friend.say.2.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I won't let them forget you, {target.name}.",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.friend.say.3.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Rest now, {target.name}. You did enough.",
                    ["realizationKey"] = "4",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.friend.say.4.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "We still owed each other a drink, {target.name}.",
                    ["realizationKey"] = "5",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.friend.say.5.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "corpse.friend",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "friend",
            ["sourceId"] = "corpse.friend",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_ordinary/corpse_friend.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextMemoryGossipCorpseOrdinary",
        ["namespace"] = "corpse",
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
                    ["domain"] = "memory",
                    ["owner"] = "PsychopatzCore",
                },
            },
            ["events"] = {
                {
                    ["id"] = "character_death",
                    ["kind"] = "world_event",
                },
            },
            ["memories"] = {
                {
                    ["id"] = "death_episode",
                    ["scope"] = "durable",
                },
            },
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["fallback"] = "We were supposed to get through this together, {target.name}.",
                        ["key"] = "corpse.friend.01",
                    },
                    {
                        ["fallback"] = "You always had my back, {target.name}. I should've had yours.",
                        ["key"] = "corpse.friend.02",
                    },
                    {
                        ["fallback"] = "I won't let them forget you, {target.name}.",
                        ["key"] = "corpse.friend.03",
                    },
                    {
                        ["fallback"] = "Rest now, {target.name}. You did enough.",
                        ["key"] = "corpse.friend.04",
                    },
                    {
                        ["fallback"] = "We still owed each other a drink, {target.name}.",
                        ["key"] = "corpse.friend.05",
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                    "4",
                    "5",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "We were supposed to get through this together, {target.name}.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "You always had my back, {target.name}. I should've had yours.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I won't let them forget you, {target.name}.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["4"] = {
                        ["key"] = "4",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Rest now, {target.name}. You did enough.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["5"] = {
                        ["key"] = "5",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "We still owed each other a drink, {target.name}.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "memory",
                    ["id"] = "death",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "corpse.friend",
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
                            ["fallback"] = "We were supposed to get through this together, {target.name}.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.corpse.friend.say_1",
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
            ["subject"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "subject",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_text_memory_gossip_corpse_ordinary/corpse_friend.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "We were supposed to get through this together, {target.name}.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.friend.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "You always had my back, {target.name}. I should've had yours.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.friend.say.2.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I won't let them forget you, {target.name}.",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.friend.say.3.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Rest now, {target.name}. You did enough.",
                ["realizationKey"] = "4",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.friend.say.4.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "We still owed each other a drink, {target.name}.",
                ["realizationKey"] = "5",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.friend.say.5.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_ordinary",
        ["domainPath"] = "core_text_memory_gossip_corpse_ordinary",
        ["exchangeFamily"] = {
            ["familyID"] = "corpse.hostile",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                    "4",
                    "5",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "So this is how it ends for you, {target.name}.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.hostile.say.1.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "You made plenty of enemies, {target.name}. I was one.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.hostile.say.2.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I won't mourn you, {target.name}, but I won't forget this.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.hostile.say.3.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["4"] = {
                        ["key"] = "4",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "The threat is gone. Keep moving.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.hostile.say.4.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["5"] = {
                        ["key"] = "5",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Maybe you finally found some peace, {target.name}.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.hostile.say.5.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "corpse",
            ["textRoles"] = {
                {
                    ["fallback"] = "So this is how it ends for you, {target.name}.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.hostile.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "You made plenty of enemies, {target.name}. I was one.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.hostile.say.2.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I won't mourn you, {target.name}, but I won't forget this.",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.hostile.say.3.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "The threat is gone. Keep moving.",
                    ["realizationKey"] = "4",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.hostile.say.4.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Maybe you finally found some peace, {target.name}.",
                    ["realizationKey"] = "5",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.hostile.say.5.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "corpse.hostile",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "hostile",
            ["sourceId"] = "corpse.hostile",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_ordinary/corpse_hostile.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextMemoryGossipCorpseOrdinary",
        ["namespace"] = "corpse",
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
                    ["domain"] = "memory",
                    ["owner"] = "PsychopatzCore",
                },
            },
            ["events"] = {
                {
                    ["id"] = "character_death",
                    ["kind"] = "world_event",
                },
            },
            ["memories"] = {
                {
                    ["id"] = "death_episode",
                    ["scope"] = "durable",
                },
            },
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["fallback"] = "So this is how it ends for you, {target.name}.",
                        ["key"] = "corpse.hostile.01",
                    },
                    {
                        ["fallback"] = "You made plenty of enemies, {target.name}. I was one.",
                        ["key"] = "corpse.hostile.02",
                    },
                    {
                        ["fallback"] = "I won't mourn you, {target.name}, but I won't forget this.",
                        ["key"] = "corpse.hostile.03",
                    },
                    {
                        ["fallback"] = "The threat is gone. Keep moving.",
                        ["key"] = "corpse.hostile.04",
                    },
                    {
                        ["fallback"] = "Maybe you finally found some peace, {target.name}.",
                        ["key"] = "corpse.hostile.05",
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                    "4",
                    "5",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "So this is how it ends for you, {target.name}.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "You made plenty of enemies, {target.name}. I was one.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I won't mourn you, {target.name}, but I won't forget this.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["4"] = {
                        ["key"] = "4",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "The threat is gone. Keep moving.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["5"] = {
                        ["key"] = "5",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Maybe you finally found some peace, {target.name}.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "memory",
                    ["id"] = "death",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "corpse.hostile",
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
                            ["fallback"] = "So this is how it ends for you, {target.name}.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.corpse.hostile.say_1",
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
            ["subject"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "subject",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_text_memory_gossip_corpse_ordinary/corpse_hostile.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "So this is how it ends for you, {target.name}.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.hostile.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "You made plenty of enemies, {target.name}. I was one.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.hostile.say.2.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I won't mourn you, {target.name}, but I won't forget this.",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.hostile.say.3.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "The threat is gone. Keep moving.",
                ["realizationKey"] = "4",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.hostile.say.4.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Maybe you finally found some peace, {target.name}.",
                ["realizationKey"] = "5",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.hostile.say.5.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_ordinary",
        ["domainPath"] = "core_text_memory_gossip_corpse_ordinary",
        ["exchangeFamily"] = {
            ["familyID"] = "corpse.neutral",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                    "4",
                    "5",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I didn't know you, {target.name}. You deserved better.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.neutral.say.1.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I hope someone remembers your name, {target.name}.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.neutral.say.2.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "This place takes everyone, doesn't it?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.neutral.say.3.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["4"] = {
                        ["key"] = "4",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Someone should have found you sooner, {target.name}.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.neutral.say.4.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["5"] = {
                        ["key"] = "5",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Rest now, {target.name}. I won't leave you unnamed.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.neutral.say.5.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "corpse",
            ["textRoles"] = {
                {
                    ["fallback"] = "I didn't know you, {target.name}. You deserved better.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.neutral.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I hope someone remembers your name, {target.name}.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.neutral.say.2.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "This place takes everyone, doesn't it?",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.neutral.say.3.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Someone should have found you sooner, {target.name}.",
                    ["realizationKey"] = "4",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.neutral.say.4.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Rest now, {target.name}. I won't leave you unnamed.",
                    ["realizationKey"] = "5",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.neutral.say.5.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "corpse.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "neutral",
            ["sourceId"] = "corpse.neutral",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_ordinary/corpse.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextMemoryGossipCorpseOrdinary",
        ["namespace"] = "corpse",
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
                    ["domain"] = "memory",
                    ["owner"] = "PsychopatzCore",
                },
            },
            ["events"] = {
                {
                    ["id"] = "character_death",
                    ["kind"] = "world_event",
                },
            },
            ["memories"] = {
                {
                    ["id"] = "death_episode",
                    ["scope"] = "durable",
                },
            },
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["fallback"] = "I didn't know you, {target.name}. You deserved better.",
                        ["key"] = "corpse.neutral.01",
                    },
                    {
                        ["fallback"] = "I hope someone remembers your name, {target.name}.",
                        ["key"] = "corpse.neutral.02",
                    },
                    {
                        ["fallback"] = "This place takes everyone, doesn't it?",
                        ["key"] = "corpse.neutral.03",
                    },
                    {
                        ["fallback"] = "Someone should have found you sooner, {target.name}.",
                        ["key"] = "corpse.neutral.04",
                    },
                    {
                        ["fallback"] = "Rest now, {target.name}. I won't leave you unnamed.",
                        ["key"] = "corpse.neutral.05",
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                    "4",
                    "5",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I didn't know you, {target.name}. You deserved better.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I hope someone remembers your name, {target.name}.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "This place takes everyone, doesn't it?",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["4"] = {
                        ["key"] = "4",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Someone should have found you sooner, {target.name}.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["5"] = {
                        ["key"] = "5",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Rest now, {target.name}. I won't leave you unnamed.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "memory",
                    ["id"] = "death",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "corpse.neutral",
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
                            ["fallback"] = "I didn't know you, {target.name}. You deserved better.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.corpse.neutral.say_1",
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
            ["subject"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "subject",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_text_memory_gossip_corpse_ordinary/corpse.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I didn't know you, {target.name}. You deserved better.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.neutral.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I hope someone remembers your name, {target.name}.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.neutral.say.2.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "This place takes everyone, doesn't it?",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.neutral.say.3.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Someone should have found you sooner, {target.name}.",
                ["realizationKey"] = "4",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.neutral.say.4.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Rest now, {target.name}. I won't leave you unnamed.",
                ["realizationKey"] = "5",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.neutral.say.5.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_ordinary",
        ["domainPath"] = "core_text_memory_gossip_corpse_ordinary",
        ["exchangeFamily"] = {
            ["familyID"] = "corpse.relative",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                    "4",
                    "5",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "No, {target.name}. You were family.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.relative.say.1.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I thought we'd meet again, {target.name}.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.relative.say.2.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "You should have made it home, {target.name}.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.relative.say.3.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["4"] = {
                        ["key"] = "4",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I'll carry you with me, {target.name}. I promise.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.relative.say.4.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["5"] = {
                        ["key"] = "5",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "{target.name}, I'm sorry I wasn't there.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.relative.say.5.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "corpse",
            ["textRoles"] = {
                {
                    ["fallback"] = "No, {target.name}. You were family.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.relative.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I thought we'd meet again, {target.name}.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.relative.say.2.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "You should have made it home, {target.name}.",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.relative.say.3.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I'll carry you with me, {target.name}. I promise.",
                    ["realizationKey"] = "4",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.relative.say.4.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "{target.name}, I'm sorry I wasn't there.",
                    ["realizationKey"] = "5",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.relative.say.5.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "corpse.relative",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "relative",
            ["sourceId"] = "corpse.relative",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_ordinary/corpse_relative.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextMemoryGossipCorpseOrdinary",
        ["namespace"] = "corpse",
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
                    ["domain"] = "memory",
                    ["owner"] = "PsychopatzCore",
                },
            },
            ["events"] = {
                {
                    ["id"] = "character_death",
                    ["kind"] = "world_event",
                },
            },
            ["memories"] = {
                {
                    ["id"] = "death_episode",
                    ["scope"] = "durable",
                },
            },
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["fallback"] = "No, {target.name}. You were family.",
                        ["key"] = "corpse.relative.01",
                    },
                    {
                        ["fallback"] = "I thought we'd meet again, {target.name}.",
                        ["key"] = "corpse.relative.02",
                    },
                    {
                        ["fallback"] = "You should have made it home, {target.name}.",
                        ["key"] = "corpse.relative.03",
                    },
                    {
                        ["fallback"] = "I'll carry you with me, {target.name}. I promise.",
                        ["key"] = "corpse.relative.04",
                    },
                    {
                        ["fallback"] = "{target.name}, I'm sorry I wasn't there.",
                        ["key"] = "corpse.relative.05",
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                    "4",
                    "5",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "No, {target.name}. You were family.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I thought we'd meet again, {target.name}.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "You should have made it home, {target.name}.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["4"] = {
                        ["key"] = "4",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I'll carry you with me, {target.name}. I promise.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["5"] = {
                        ["key"] = "5",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "{target.name}, I'm sorry I wasn't there.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "memory",
                    ["id"] = "death",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "corpse.relative",
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
                            ["fallback"] = "No, {target.name}. You were family.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.corpse.relative.say_1",
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
            ["subject"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "subject",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_text_memory_gossip_corpse_ordinary/corpse_relative.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "No, {target.name}. You were family.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.relative.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I thought we'd meet again, {target.name}.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.relative.say.2.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "You should have made it home, {target.name}.",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.relative.say.3.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I'll carry you with me, {target.name}. I promise.",
                ["realizationKey"] = "4",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.relative.say.4.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "{target.name}, I'm sorry I wasn't there.",
                ["realizationKey"] = "5",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.relative.say.5.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
