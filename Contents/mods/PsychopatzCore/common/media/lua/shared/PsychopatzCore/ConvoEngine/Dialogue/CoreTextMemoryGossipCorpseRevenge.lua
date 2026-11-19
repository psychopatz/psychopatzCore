-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_text_memory_gossip_corpse_revenge",
        ["domainPath"] = "core_text_memory_gossip_corpse_revenge",
        ["exchangeFamily"] = {
            ["familyID"] = "corpse.revenge.comrade",
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
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Damn {slot.killer.name}. {target.name} stood with {slot.faction.name}; we will answer for this.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.revenge.comrade.say.1.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "One of ours is down, {target.name}. {slot.killer.name} made enemies of all of us.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.revenge.comrade.say.2.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "We saw {slot.killer.name} take {target.name}. This is not finished.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.revenge.comrade.say.3.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["4"] = {
                        ["key"] = "4",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "{slot.killer.name} killed a member of {slot.faction.name}. We will remember.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.revenge.comrade.say.4.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["5"] = {
                        ["key"] = "5",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Run while you can, {slot.killer.name}. We will not forget what happened to {target.name}.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.revenge.comrade.say.5.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["6"] = {
                        ["key"] = "6",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Hell, {target.name}. {slot.killer.name} will pay for making us weaker.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.revenge.comrade.say.6.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["7"] = {
                        ["key"] = "7",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "{slot.faction.name} lost one today. {slot.killer.name} started something they cannot finish.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.revenge.comrade.say.7.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["8"] = {
                        ["key"] = "8",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "We do not forget our own, {target.name}. {slot.killer.name} will answer for this.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.revenge.comrade.say.8.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "corpse.revenge",
            ["slots"] = {
                ["faction"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = true,
                    ["type"] = "entity.faction",
                },
                ["killer"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = true,
                    ["type"] = "entity.person",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "Damn {slot.killer.name}. {target.name} stood with {slot.faction.name}; we will answer for this.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.revenge.comrade.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "One of ours is down, {target.name}. {slot.killer.name} made enemies of all of us.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.revenge.comrade.say.2.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "We saw {slot.killer.name} take {target.name}. This is not finished.",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.revenge.comrade.say.3.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "{slot.killer.name} killed a member of {slot.faction.name}. We will remember.",
                    ["realizationKey"] = "4",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.revenge.comrade.say.4.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Run while you can, {slot.killer.name}. We will not forget what happened to {target.name}.",
                    ["realizationKey"] = "5",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.revenge.comrade.say.5.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Hell, {target.name}. {slot.killer.name} will pay for making us weaker.",
                    ["realizationKey"] = "6",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.revenge.comrade.say.6.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "{slot.faction.name} lost one today. {slot.killer.name} started something they cannot finish.",
                    ["realizationKey"] = "7",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.revenge.comrade.say.7.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "We do not forget our own, {target.name}. {slot.killer.name} will answer for this.",
                    ["realizationKey"] = "8",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.revenge.comrade.say.8.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "corpse.revenge.comrade",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "comrade",
            ["sourceId"] = "corpse.revenge.comrade",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_comrade.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextMemoryGossipCorpseRevenge",
        ["namespace"] = "corpse.revenge",
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
                        ["fallback"] = "Damn {slot.killer.name}. {target.name} stood with {slot.faction.name}; we will answer for this.",
                        ["key"] = "corpse.revenge.comrade.01",
                    },
                    {
                        ["fallback"] = "One of ours is down, {target.name}. {slot.killer.name} made enemies of all of us.",
                        ["key"] = "corpse.revenge.comrade.02",
                    },
                    {
                        ["fallback"] = "We saw {slot.killer.name} take {target.name}. This is not finished.",
                        ["key"] = "corpse.revenge.comrade.03",
                    },
                    {
                        ["fallback"] = "{slot.killer.name} killed a member of {slot.faction.name}. We will remember.",
                        ["key"] = "corpse.revenge.comrade.04",
                    },
                    {
                        ["fallback"] = "Run while you can, {slot.killer.name}. We will not forget what happened to {target.name}.",
                        ["key"] = "corpse.revenge.comrade.05",
                    },
                    {
                        ["fallback"] = "Hell, {target.name}. {slot.killer.name} will pay for making us weaker.",
                        ["key"] = "corpse.revenge.comrade.06",
                    },
                    {
                        ["fallback"] = "{slot.faction.name} lost one today. {slot.killer.name} started something they cannot finish.",
                        ["key"] = "corpse.revenge.comrade.07",
                    },
                    {
                        ["fallback"] = "We do not forget our own, {target.name}. {slot.killer.name} will answer for this.",
                        ["key"] = "corpse.revenge.comrade.08",
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
                    "6",
                    "7",
                    "8",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Damn {slot.killer.name}. {target.name} stood with {slot.faction.name}; we will answer for this.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "One of ours is down, {target.name}. {slot.killer.name} made enemies of all of us.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "We saw {slot.killer.name} take {target.name}. This is not finished.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["4"] = {
                        ["key"] = "4",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "{slot.killer.name} killed a member of {slot.faction.name}. We will remember.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["5"] = {
                        ["key"] = "5",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Run while you can, {slot.killer.name}. We will not forget what happened to {target.name}.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["6"] = {
                        ["key"] = "6",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Hell, {target.name}. {slot.killer.name} will pay for making us weaker.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["7"] = {
                        ["key"] = "7",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "{slot.faction.name} lost one today. {slot.killer.name} started something they cannot finish.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["8"] = {
                        ["key"] = "8",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "We do not forget our own, {target.name}. {slot.killer.name} will answer for this.",
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
            ["responsePlanID"] = "corpse.revenge.comrade",
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
                            ["fallback"] = "Damn {slot.killer.name}. {target.name} stood with {slot.faction.name}; we will answer for this.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.corpse.revenge.comrade.say_1",
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
            ["killer"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = true,
                ["type"] = "entity.person",
            },
        },
        ["sourceShard"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_comrade.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Damn {slot.killer.name}. {target.name} stood with {slot.faction.name}; we will answer for this.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.revenge.comrade.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "One of ours is down, {target.name}. {slot.killer.name} made enemies of all of us.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.revenge.comrade.say.2.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "We saw {slot.killer.name} take {target.name}. This is not finished.",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.revenge.comrade.say.3.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "{slot.killer.name} killed a member of {slot.faction.name}. We will remember.",
                ["realizationKey"] = "4",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.revenge.comrade.say.4.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Run while you can, {slot.killer.name}. We will not forget what happened to {target.name}.",
                ["realizationKey"] = "5",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.revenge.comrade.say.5.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Hell, {target.name}. {slot.killer.name} will pay for making us weaker.",
                ["realizationKey"] = "6",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.revenge.comrade.say.6.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "{slot.faction.name} lost one today. {slot.killer.name} started something they cannot finish.",
                ["realizationKey"] = "7",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.revenge.comrade.say.7.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "We do not forget our own, {target.name}. {slot.killer.name} will answer for this.",
                ["realizationKey"] = "8",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.revenge.comrade.say.8.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_revenge",
        ["domainPath"] = "core_text_memory_gossip_corpse_revenge",
        ["exchangeFamily"] = {
            ["familyID"] = "corpse.revenge.friend",
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
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Damn {slot.killer.name}. {target.name} was my friend, and this will cost you.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.revenge.friend.say.1.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I saw {target.name} fall. {slot.killer.name} will answer for it.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.revenge.friend.say.2.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Hell, {target.name}. What {slot.killer.name} did will not be forgotten.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.revenge.friend.say.3.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["4"] = {
                        ["key"] = "4",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I will not let {target.name} be forgotten, and {slot.killer.name} will not get away with it.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.revenge.friend.say.4.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["5"] = {
                        ["key"] = "5",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "{target.name} always had my back. Today, I am coming for {slot.killer.name}.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.revenge.friend.say.5.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["6"] = {
                        ["key"] = "6",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Damn {slot.killer.name}. {target.name} mattered to us.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.revenge.friend.say.6.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["7"] = {
                        ["key"] = "7",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I hope {slot.killer.name} knows what they took from us when they killed {target.name}.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.revenge.friend.say.7.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["8"] = {
                        ["key"] = "8",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "No more warnings. {slot.killer.name} killed one of ours, {target.name}.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.revenge.friend.say.8.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "corpse.revenge",
            ["slots"] = {
                ["killer"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = true,
                    ["type"] = "entity.person",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "Damn {slot.killer.name}. {target.name} was my friend, and this will cost you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.revenge.friend.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I saw {target.name} fall. {slot.killer.name} will answer for it.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.revenge.friend.say.2.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Hell, {target.name}. What {slot.killer.name} did will not be forgotten.",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.revenge.friend.say.3.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I will not let {target.name} be forgotten, and {slot.killer.name} will not get away with it.",
                    ["realizationKey"] = "4",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.revenge.friend.say.4.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "{target.name} always had my back. Today, I am coming for {slot.killer.name}.",
                    ["realizationKey"] = "5",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.revenge.friend.say.5.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Damn {slot.killer.name}. {target.name} mattered to us.",
                    ["realizationKey"] = "6",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.revenge.friend.say.6.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I hope {slot.killer.name} knows what they took from us when they killed {target.name}.",
                    ["realizationKey"] = "7",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.revenge.friend.say.7.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "No more warnings. {slot.killer.name} killed one of ours, {target.name}.",
                    ["realizationKey"] = "8",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.revenge.friend.say.8.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "corpse.revenge.friend",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "friend",
            ["sourceId"] = "corpse.revenge.friend",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_friend.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextMemoryGossipCorpseRevenge",
        ["namespace"] = "corpse.revenge",
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
                        ["fallback"] = "Damn {slot.killer.name}. {target.name} was my friend, and this will cost you.",
                        ["key"] = "corpse.revenge.friend.01",
                    },
                    {
                        ["fallback"] = "I saw {target.name} fall. {slot.killer.name} will answer for it.",
                        ["key"] = "corpse.revenge.friend.02",
                    },
                    {
                        ["fallback"] = "Hell, {target.name}. What {slot.killer.name} did will not be forgotten.",
                        ["key"] = "corpse.revenge.friend.03",
                    },
                    {
                        ["fallback"] = "I will not let {target.name} be forgotten, and {slot.killer.name} will not get away with it.",
                        ["key"] = "corpse.revenge.friend.04",
                    },
                    {
                        ["fallback"] = "{target.name} always had my back. Today, I am coming for {slot.killer.name}.",
                        ["key"] = "corpse.revenge.friend.05",
                    },
                    {
                        ["fallback"] = "Damn {slot.killer.name}. {target.name} mattered to us.",
                        ["key"] = "corpse.revenge.friend.06",
                    },
                    {
                        ["fallback"] = "I hope {slot.killer.name} knows what they took from us when they killed {target.name}.",
                        ["key"] = "corpse.revenge.friend.07",
                    },
                    {
                        ["fallback"] = "No more warnings. {slot.killer.name} killed one of ours, {target.name}.",
                        ["key"] = "corpse.revenge.friend.08",
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
                    "6",
                    "7",
                    "8",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Damn {slot.killer.name}. {target.name} was my friend, and this will cost you.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I saw {target.name} fall. {slot.killer.name} will answer for it.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Hell, {target.name}. What {slot.killer.name} did will not be forgotten.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["4"] = {
                        ["key"] = "4",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I will not let {target.name} be forgotten, and {slot.killer.name} will not get away with it.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["5"] = {
                        ["key"] = "5",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "{target.name} always had my back. Today, I am coming for {slot.killer.name}.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["6"] = {
                        ["key"] = "6",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Damn {slot.killer.name}. {target.name} mattered to us.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["7"] = {
                        ["key"] = "7",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I hope {slot.killer.name} knows what they took from us when they killed {target.name}.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["8"] = {
                        ["key"] = "8",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "No more warnings. {slot.killer.name} killed one of ours, {target.name}.",
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
            ["responsePlanID"] = "corpse.revenge.friend",
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
                            ["fallback"] = "Damn {slot.killer.name}. {target.name} was my friend, and this will cost you.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.corpse.revenge.friend.say_1",
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
            ["killer"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = true,
                ["type"] = "entity.person",
            },
        },
        ["sourceShard"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_friend.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Damn {slot.killer.name}. {target.name} was my friend, and this will cost you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.revenge.friend.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I saw {target.name} fall. {slot.killer.name} will answer for it.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.revenge.friend.say.2.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Hell, {target.name}. What {slot.killer.name} did will not be forgotten.",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.revenge.friend.say.3.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I will not let {target.name} be forgotten, and {slot.killer.name} will not get away with it.",
                ["realizationKey"] = "4",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.revenge.friend.say.4.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "{target.name} always had my back. Today, I am coming for {slot.killer.name}.",
                ["realizationKey"] = "5",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.revenge.friend.say.5.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Damn {slot.killer.name}. {target.name} mattered to us.",
                ["realizationKey"] = "6",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.revenge.friend.say.6.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I hope {slot.killer.name} knows what they took from us when they killed {target.name}.",
                ["realizationKey"] = "7",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.revenge.friend.say.7.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "No more warnings. {slot.killer.name} killed one of ours, {target.name}.",
                ["realizationKey"] = "8",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.revenge.friend.say.8.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_revenge",
        ["domainPath"] = "core_text_memory_gossip_corpse_revenge",
        ["exchangeFamily"] = {
            ["familyID"] = "corpse.revenge.relative",
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
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Damn it, {slot.killer.name}. You took {target.name} from their family. This will not go unanswered.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.revenge.relative.say.1.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I saw {target.name} fall. {slot.killer.name} will answer for this, I swear it.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.revenge.relative.say.2.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "What {slot.killer.name} did to {target.name} will never be forgiven.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.revenge.relative.say.3.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["4"] = {
                        ["key"] = "4",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Hell, {target.name}. {slot.killer.name} is going to pay for this.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.revenge.relative.say.4.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["5"] = {
                        ["key"] = "5",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I will not let {target.name}'s death go unanswered. {slot.killer.name} started this.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.revenge.relative.say.5.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["6"] = {
                        ["key"] = "6",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "No. Not {target.name}. {slot.killer.name} just made this personal.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.revenge.relative.say.6.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["7"] = {
                        ["key"] = "7",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "{target.name} was family. {slot.killer.name} will regret this.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.revenge.relative.say.7.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["8"] = {
                        ["key"] = "8",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Rest now, {target.name}. I hope {slot.killer.name} runs, because I am coming.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.revenge.relative.say.8.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "corpse.revenge",
            ["slots"] = {
                ["killer"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = true,
                    ["type"] = "entity.person",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "Damn it, {slot.killer.name}. You took {target.name} from their family. This will not go unanswered.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.revenge.relative.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I saw {target.name} fall. {slot.killer.name} will answer for this, I swear it.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.revenge.relative.say.2.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "What {slot.killer.name} did to {target.name} will never be forgiven.",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.revenge.relative.say.3.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Hell, {target.name}. {slot.killer.name} is going to pay for this.",
                    ["realizationKey"] = "4",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.revenge.relative.say.4.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I will not let {target.name}'s death go unanswered. {slot.killer.name} started this.",
                    ["realizationKey"] = "5",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.revenge.relative.say.5.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "No. Not {target.name}. {slot.killer.name} just made this personal.",
                    ["realizationKey"] = "6",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.revenge.relative.say.6.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "{target.name} was family. {slot.killer.name} will regret this.",
                    ["realizationKey"] = "7",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.revenge.relative.say.7.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Rest now, {target.name}. I hope {slot.killer.name} runs, because I am coming.",
                    ["realizationKey"] = "8",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.revenge.relative.say.8.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "corpse.revenge.relative",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "relative",
            ["sourceId"] = "corpse.revenge.relative",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_relative.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextMemoryGossipCorpseRevenge",
        ["namespace"] = "corpse.revenge",
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
                        ["fallback"] = "Damn it, {slot.killer.name}. You took {target.name} from their family. This will not go unanswered.",
                        ["key"] = "corpse.revenge.relative.01",
                    },
                    {
                        ["fallback"] = "I saw {target.name} fall. {slot.killer.name} will answer for this, I swear it.",
                        ["key"] = "corpse.revenge.relative.02",
                    },
                    {
                        ["fallback"] = "What {slot.killer.name} did to {target.name} will never be forgiven.",
                        ["key"] = "corpse.revenge.relative.03",
                    },
                    {
                        ["fallback"] = "Hell, {target.name}. {slot.killer.name} is going to pay for this.",
                        ["key"] = "corpse.revenge.relative.04",
                    },
                    {
                        ["fallback"] = "I will not let {target.name}'s death go unanswered. {slot.killer.name} started this.",
                        ["key"] = "corpse.revenge.relative.05",
                    },
                    {
                        ["fallback"] = "No. Not {target.name}. {slot.killer.name} just made this personal.",
                        ["key"] = "corpse.revenge.relative.06",
                    },
                    {
                        ["fallback"] = "{target.name} was family. {slot.killer.name} will regret this.",
                        ["key"] = "corpse.revenge.relative.07",
                    },
                    {
                        ["fallback"] = "Rest now, {target.name}. I hope {slot.killer.name} runs, because I am coming.",
                        ["key"] = "corpse.revenge.relative.08",
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
                    "6",
                    "7",
                    "8",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Damn it, {slot.killer.name}. You took {target.name} from their family. This will not go unanswered.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I saw {target.name} fall. {slot.killer.name} will answer for this, I swear it.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "What {slot.killer.name} did to {target.name} will never be forgiven.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["4"] = {
                        ["key"] = "4",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Hell, {target.name}. {slot.killer.name} is going to pay for this.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["5"] = {
                        ["key"] = "5",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I will not let {target.name}'s death go unanswered. {slot.killer.name} started this.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["6"] = {
                        ["key"] = "6",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "No. Not {target.name}. {slot.killer.name} just made this personal.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["7"] = {
                        ["key"] = "7",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "{target.name} was family. {slot.killer.name} will regret this.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["8"] = {
                        ["key"] = "8",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Rest now, {target.name}. I hope {slot.killer.name} runs, because I am coming.",
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
            ["responsePlanID"] = "corpse.revenge.relative",
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
                            ["fallback"] = "Damn it, {slot.killer.name}. You took {target.name} from their family. This will not go unanswered.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.corpse.revenge.relative.say_1",
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
            ["killer"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = true,
                ["type"] = "entity.person",
            },
        },
        ["sourceShard"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_relative.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Damn it, {slot.killer.name}. You took {target.name} from their family. This will not go unanswered.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.revenge.relative.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I saw {target.name} fall. {slot.killer.name} will answer for this, I swear it.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.revenge.relative.say.2.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "What {slot.killer.name} did to {target.name} will never be forgiven.",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.revenge.relative.say.3.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Hell, {target.name}. {slot.killer.name} is going to pay for this.",
                ["realizationKey"] = "4",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.revenge.relative.say.4.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I will not let {target.name}'s death go unanswered. {slot.killer.name} started this.",
                ["realizationKey"] = "5",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.revenge.relative.say.5.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "No. Not {target.name}. {slot.killer.name} just made this personal.",
                ["realizationKey"] = "6",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.revenge.relative.say.6.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "{target.name} was family. {slot.killer.name} will regret this.",
                ["realizationKey"] = "7",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.revenge.relative.say.7.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Rest now, {target.name}. I hope {slot.killer.name} runs, because I am coming.",
                ["realizationKey"] = "8",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.revenge.relative.say.8.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
