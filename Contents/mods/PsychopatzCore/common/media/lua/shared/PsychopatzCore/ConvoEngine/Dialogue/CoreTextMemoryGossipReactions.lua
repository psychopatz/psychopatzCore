-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_text_memory_gossip_reactions",
        ["domainPath"] = "core_text_memory_gossip_reactions",
        ["exchangeFamily"] = {
            ["familyID"] = "negative.mockery.gear",
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
                                ["fallback"] = "Someone says {target.name} cannot keep track of their own gear.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.negative.mockery.gear.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Someone says {target.name} cannot keep track of their own gear.",
                                    },
                                    ["TL"] = {
                                        "Sabi nila, hindi maalagaan ni {target.name} ang sarili niyang gamit.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "negative.mockery",
            ["textRoles"] = {
                {
                    ["fallback"] = "Someone says {target.name} cannot keep track of their own gear.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.negative.mockery.gear.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Someone says {target.name} cannot keep track of their own gear.",
                        },
                        ["TL"] = {
                            "Sabi nila, hindi maalagaan ni {target.name} ang sarili niyang gamit.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "negative.mockery.gear",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "gear",
            ["sourceId"] = "negative.mockery.gear",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_reactions/negative_mockery_gear.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextMemoryGossipReactions",
        ["namespace"] = "negative.mockery",
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
                ["textKey"] = "negative.mockery.gear",
                ["textRows"] = {
                    {
                        ["key"] = "negative.mockery.gear",
                        ["text"] = {
                            ["EN"] = "Someone says {target.name} cannot keep track of their own gear.",
                            ["TL"] = "Sabi nila, hindi maalagaan ni {target.name} ang sarili niyang gamit.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
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
                                        "Someone says {target.name} cannot keep track of their own gear.",
                                    },
                                    ["TL"] = {
                                        "Sabi nila, hindi maalagaan ni {target.name} ang sarili niyang gamit.",
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
            ["responsePlanID"] = "negative.mockery.gear",
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
                            ["fallback"] = "Someone says {target.name} cannot keep track of their own gear.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.negative.mockery.gear.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_text_memory_gossip_reactions/negative_mockery_gear.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Someone says {target.name} cannot keep track of their own gear.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.negative.mockery.gear.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Someone says {target.name} cannot keep track of their own gear.",
                    },
                    ["TL"] = {
                        "Sabi nila, hindi maalagaan ni {target.name} ang sarili niyang gamit.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_reactions",
        ["domainPath"] = "core_text_memory_gossip_reactions",
        ["exchangeFamily"] = {
            ["familyID"] = "negative.mockery.retreat",
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
                                ["fallback"] = "{target.name} talked big, then backed down when it mattered.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.negative.mockery.retreat.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "{target.name} talked big, then backed down when it mattered.",
                                    },
                                    ["TL"] = {
                                        "Malakas ang loob magsalita ni {target.name}, pero umurong nang kailangan nang kumilos.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "negative.mockery",
            ["textRoles"] = {
                {
                    ["fallback"] = "{target.name} talked big, then backed down when it mattered.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.negative.mockery.retreat.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "{target.name} talked big, then backed down when it mattered.",
                        },
                        ["TL"] = {
                            "Malakas ang loob magsalita ni {target.name}, pero umurong nang kailangan nang kumilos.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "negative.mockery.retreat",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "retreat",
            ["sourceId"] = "negative.mockery.retreat",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_reactions/negative_mockery_retreat.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextMemoryGossipReactions",
        ["namespace"] = "negative.mockery",
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
                ["textKey"] = "negative.mockery.retreat",
                ["textRows"] = {
                    {
                        ["key"] = "negative.mockery.retreat",
                        ["text"] = {
                            ["EN"] = "{target.name} talked big, then backed down when it mattered.",
                            ["TL"] = "Malakas ang loob magsalita ni {target.name}, pero umurong nang kailangan nang kumilos.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
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
                                        "{target.name} talked big, then backed down when it mattered.",
                                    },
                                    ["TL"] = {
                                        "Malakas ang loob magsalita ni {target.name}, pero umurong nang kailangan nang kumilos.",
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
            ["responsePlanID"] = "negative.mockery.retreat",
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
                            ["fallback"] = "{target.name} talked big, then backed down when it mattered.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.negative.mockery.retreat.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_text_memory_gossip_reactions/negative_mockery_retreat.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "{target.name} talked big, then backed down when it mattered.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.negative.mockery.retreat.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "{target.name} talked big, then backed down when it mattered.",
                    },
                    ["TL"] = {
                        "Malakas ang loob magsalita ni {target.name}, pero umurong nang kailangan nang kumilos.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_reactions",
        ["domainPath"] = "core_text_memory_gossip_reactions",
        ["exchangeFamily"] = {
            ["familyID"] = "negative.suspicion.story",
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
                                ["fallback"] = "Watch {target.name}; their story keeps changing.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.negative.suspicion.story.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Watch {target.name}; their story keeps changing.",
                                    },
                                    ["TL"] = {
                                        "Bantayan si {target.name}; pabago-bago ang kuwento niya.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "negative.suspicion",
            ["textRoles"] = {
                {
                    ["fallback"] = "Watch {target.name}; their story keeps changing.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.negative.suspicion.story.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Watch {target.name}; their story keeps changing.",
                        },
                        ["TL"] = {
                            "Bantayan si {target.name}; pabago-bago ang kuwento niya.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "negative.suspicion.story",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "story",
            ["sourceId"] = "negative.suspicion.story",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_reactions/negative_suspicion_story.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextMemoryGossipReactions",
        ["namespace"] = "negative.suspicion",
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
                ["textKey"] = "negative.suspicion.story",
                ["textRows"] = {
                    {
                        ["key"] = "negative.suspicion.story",
                        ["text"] = {
                            ["EN"] = "Watch {target.name}; their story keeps changing.",
                            ["TL"] = "Bantayan si {target.name}; pabago-bago ang kuwento niya.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
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
                                        "Watch {target.name}; their story keeps changing.",
                                    },
                                    ["TL"] = {
                                        "Bantayan si {target.name}; pabago-bago ang kuwento niya.",
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
            ["responsePlanID"] = "negative.suspicion.story",
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
                            ["fallback"] = "Watch {target.name}; their story keeps changing.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.negative.suspicion.story.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_text_memory_gossip_reactions/negative_suspicion_story.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Watch {target.name}; their story keeps changing.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.negative.suspicion.story.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Watch {target.name}; their story keeps changing.",
                    },
                    ["TL"] = {
                        "Bantayan si {target.name}; pabago-bago ang kuwento niya.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_reactions",
        ["domainPath"] = "core_text_memory_gossip_reactions",
        ["exchangeFamily"] = {
            ["familyID"] = "negative.warning.abandoned",
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
                                ["fallback"] = "{target.name} left someone behind when the zombies closed in.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.negative.warning.abandoned.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "{target.name} left someone behind when the zombies closed in.",
                                    },
                                    ["TL"] = {
                                        "Iniwan ni {target.name} ang kasama niya nang sumalakay ang mga zombie.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "negative.warning",
            ["textRoles"] = {
                {
                    ["fallback"] = "{target.name} left someone behind when the zombies closed in.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.negative.warning.abandoned.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "{target.name} left someone behind when the zombies closed in.",
                        },
                        ["TL"] = {
                            "Iniwan ni {target.name} ang kasama niya nang sumalakay ang mga zombie.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "negative.warning.abandoned",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "abandoned",
            ["sourceId"] = "negative.warning.abandoned",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_reactions/negative_warning_abandoned.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextMemoryGossipReactions",
        ["namespace"] = "negative.warning",
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
                ["textKey"] = "negative.warning.abandoned",
                ["textRows"] = {
                    {
                        ["key"] = "negative.warning.abandoned",
                        ["text"] = {
                            ["EN"] = "{target.name} left someone behind when the zombies closed in.",
                            ["TL"] = "Iniwan ni {target.name} ang kasama niya nang sumalakay ang mga zombie.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
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
                                        "{target.name} left someone behind when the zombies closed in.",
                                    },
                                    ["TL"] = {
                                        "Iniwan ni {target.name} ang kasama niya nang sumalakay ang mga zombie.",
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
            ["responsePlanID"] = "negative.warning.abandoned",
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
                            ["fallback"] = "{target.name} left someone behind when the zombies closed in.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.negative.warning.abandoned.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_text_memory_gossip_reactions/negative_warning_abandoned.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "{target.name} left someone behind when the zombies closed in.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.negative.warning.abandoned.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "{target.name} left someone behind when the zombies closed in.",
                    },
                    ["TL"] = {
                        "Iniwan ni {target.name} ang kasama niya nang sumalakay ang mga zombie.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_reactions",
        ["domainPath"] = "core_text_memory_gossip_reactions",
        ["exchangeFamily"] = {
            ["familyID"] = "negative.warning.danger",
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
                                ["fallback"] = "People have spotted danger near {slot.place.name}.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.negative.warning.danger.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "People have spotted danger near {slot.place.name}.",
                                    },
                                    ["TL"] = {
                                        "May nakapansing panganib malapit sa {slot.place.name}.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "negative.warning",
            ["slots"] = {
                ["place"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = true,
                    ["type"] = "entity.location",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "People have spotted danger near {slot.place.name}.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.negative.warning.danger.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "People have spotted danger near {slot.place.name}.",
                        },
                        ["TL"] = {
                            "May nakapansing panganib malapit sa {slot.place.name}.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "negative.warning.danger",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "danger",
            ["sourceId"] = "negative.warning.danger",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_reactions/negative_warning_danger.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextMemoryGossipReactions",
        ["namespace"] = "negative.warning",
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
                ["textKey"] = "negative.warning.danger",
                ["textRows"] = {
                    {
                        ["key"] = "negative.warning.danger",
                        ["text"] = {
                            ["EN"] = "People have spotted danger near {slot.place.name}.",
                            ["TL"] = "May nakapansing panganib malapit sa {slot.place.name}.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
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
                                        "People have spotted danger near {slot.place.name}.",
                                    },
                                    ["TL"] = {
                                        "May nakapansing panganib malapit sa {slot.place.name}.",
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
            ["responsePlanID"] = "negative.warning.danger",
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
                            ["fallback"] = "People have spotted danger near {slot.place.name}.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.negative.warning.danger.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
            ["place"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = true,
                ["type"] = "entity.location",
            },
        },
        ["sourceShard"] = "dialogue/core_text_memory_gossip_reactions/negative_warning_danger.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "People have spotted danger near {slot.place.name}.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.negative.warning.danger.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "People have spotted danger near {slot.place.name}.",
                    },
                    ["TL"] = {
                        "May nakapansing panganib malapit sa {slot.place.name}.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_reactions",
        ["domainPath"] = "core_text_memory_gossip_reactions",
        ["exchangeFamily"] = {
            ["familyID"] = "neutral.horde_survival",
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
                                ["fallback"] = "I got away when a whole horde came after me.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.neutral.horde_survival.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I got away when a whole horde came after me.",
                                    },
                                    ["TL"] = {
                                        "Nakatakas ako nang habulin ako ng napakaraming zombie.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "neutral",
            ["textRoles"] = {
                {
                    ["fallback"] = "I got away when a whole horde came after me.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.neutral.horde_survival.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I got away when a whole horde came after me.",
                        },
                        ["TL"] = {
                            "Nakatakas ako nang habulin ako ng napakaraming zombie.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "neutral.horde_survival",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "horde_survival",
            ["sourceId"] = "neutral.horde_survival",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_reactions/neutral_horde_survival.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextMemoryGossipReactions",
        ["namespace"] = "neutral",
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
                ["textKey"] = "neutral.horde_survival",
                ["textRows"] = {
                    {
                        ["key"] = "neutral.horde_survival",
                        ["text"] = {
                            ["EN"] = "I got away when a whole horde came after me.",
                            ["TL"] = "Nakatakas ako nang habulin ako ng napakaraming zombie.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
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
                                        "I got away when a whole horde came after me.",
                                    },
                                    ["TL"] = {
                                        "Nakatakas ako nang habulin ako ng napakaraming zombie.",
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
            ["responsePlanID"] = "neutral.horde_survival",
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
                            ["fallback"] = "I got away when a whole horde came after me.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.neutral.horde_survival.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_text_memory_gossip_reactions/neutral_horde_survival.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I got away when a whole horde came after me.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.neutral.horde_survival.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I got away when a whole horde came after me.",
                    },
                    ["TL"] = {
                        "Nakatakas ako nang habulin ako ng napakaraming zombie.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_reactions",
        ["domainPath"] = "core_text_memory_gossip_reactions",
        ["exchangeFamily"] = {
            ["familyID"] = "neutral.sighting",
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
                                ["fallback"] = "Word is {target.name} was seen near {slot.place.name}.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.neutral.sighting.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Word is {target.name} was seen near {slot.place.name}.",
                                    },
                                    ["TL"] = {
                                        "May nakakita raw kay {target.name} malapit sa {slot.place.name}.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "neutral",
            ["slots"] = {
                ["place"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = true,
                    ["type"] = "entity.location",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "Word is {target.name} was seen near {slot.place.name}.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.neutral.sighting.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Word is {target.name} was seen near {slot.place.name}.",
                        },
                        ["TL"] = {
                            "May nakakita raw kay {target.name} malapit sa {slot.place.name}.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "neutral.sighting",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "sighting",
            ["sourceId"] = "neutral.sighting",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_reactions/neutral_sighting.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextMemoryGossipReactions",
        ["namespace"] = "neutral",
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
                ["textKey"] = "neutral.sighting",
                ["textRows"] = {
                    {
                        ["key"] = "neutral.sighting",
                        ["text"] = {
                            ["EN"] = "Word is {target.name} was seen near {slot.place.name}.",
                            ["TL"] = "May nakakita raw kay {target.name} malapit sa {slot.place.name}.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
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
                                        "Word is {target.name} was seen near {slot.place.name}.",
                                    },
                                    ["TL"] = {
                                        "May nakakita raw kay {target.name} malapit sa {slot.place.name}.",
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
            ["responsePlanID"] = "neutral.sighting",
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
                            ["fallback"] = "Word is {target.name} was seen near {slot.place.name}.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.neutral.sighting.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
            ["place"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = true,
                ["type"] = "entity.location",
            },
        },
        ["sourceShard"] = "dialogue/core_text_memory_gossip_reactions/neutral_sighting.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Word is {target.name} was seen near {slot.place.name}.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.neutral.sighting.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Word is {target.name} was seen near {slot.place.name}.",
                    },
                    ["TL"] = {
                        "May nakakita raw kay {target.name} malapit sa {slot.place.name}.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_reactions",
        ["domainPath"] = "core_text_memory_gossip_reactions",
        ["exchangeFamily"] = {
            ["familyID"] = "positive.praise.help",
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
                                ["fallback"] = "{target.name} has been looking out for people.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.positive.praise.help.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "{target.name} has been looking out for people.",
                                    },
                                    ["TL"] = {
                                        "Inaalalayan ni {target.name} ang mga tao.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "positive.praise",
            ["textRoles"] = {
                {
                    ["fallback"] = "{target.name} has been looking out for people.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.positive.praise.help.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "{target.name} has been looking out for people.",
                        },
                        ["TL"] = {
                            "Inaalalayan ni {target.name} ang mga tao.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "positive.praise.help",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "help",
            ["sourceId"] = "positive.praise.help",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_reactions/positive_praise_help.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextMemoryGossipReactions",
        ["namespace"] = "positive.praise",
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
                ["textKey"] = "positive.praise.help",
                ["textRows"] = {
                    {
                        ["key"] = "positive.praise.help",
                        ["text"] = {
                            ["EN"] = "{target.name} has been looking out for people.",
                            ["TL"] = "Inaalalayan ni {target.name} ang mga tao.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
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
                                        "{target.name} has been looking out for people.",
                                    },
                                    ["TL"] = {
                                        "Inaalalayan ni {target.name} ang mga tao.",
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
            ["responsePlanID"] = "positive.praise.help",
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
                            ["fallback"] = "{target.name} has been looking out for people.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.positive.praise.help.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_text_memory_gossip_reactions/positive_praise_help.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "{target.name} has been looking out for people.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.positive.praise.help.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "{target.name} has been looking out for people.",
                    },
                    ["TL"] = {
                        "Inaalalayan ni {target.name} ang mga tao.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_reactions",
        ["domainPath"] = "core_text_memory_gossip_reactions",
        ["exchangeFamily"] = {
            ["familyID"] = "positive.protection",
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
                                ["fallback"] = "{target.name} stood up for someone when an attacker closed in.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.positive.protection.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "{target.name} stood up for someone when an attacker closed in.",
                                    },
                                    ["TL"] = {
                                        "Ipinagtanggol ni {target.name} ang isang tao nang may umatake.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "positive",
            ["textRoles"] = {
                {
                    ["fallback"] = "{target.name} stood up for someone when an attacker closed in.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.positive.protection.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "{target.name} stood up for someone when an attacker closed in.",
                        },
                        ["TL"] = {
                            "Ipinagtanggol ni {target.name} ang isang tao nang may umatake.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "positive.protection",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "protection",
            ["sourceId"] = "positive.protection",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_reactions/positive_protection.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextMemoryGossipReactions",
        ["namespace"] = "positive",
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
                ["textKey"] = "positive.protection",
                ["textRows"] = {
                    {
                        ["key"] = "positive.protection",
                        ["text"] = {
                            ["EN"] = "{target.name} stood up for someone when an attacker closed in.",
                            ["TL"] = "Ipinagtanggol ni {target.name} ang isang tao nang may umatake.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
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
                                        "{target.name} stood up for someone when an attacker closed in.",
                                    },
                                    ["TL"] = {
                                        "Ipinagtanggol ni {target.name} ang isang tao nang may umatake.",
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
            ["responsePlanID"] = "positive.protection",
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
                            ["fallback"] = "{target.name} stood up for someone when an attacker closed in.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.positive.protection.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_text_memory_gossip_reactions/positive_protection.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "{target.name} stood up for someone when an attacker closed in.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.positive.protection.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "{target.name} stood up for someone when an attacker closed in.",
                    },
                    ["TL"] = {
                        "Ipinagtanggol ni {target.name} ang isang tao nang may umatake.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_reactions",
        ["domainPath"] = "core_text_memory_gossip_reactions",
        ["exchangeFamily"] = {
            ["familyID"] = "positive.rescue.return",
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
                                ["fallback"] = "{target.name} got someone home alive.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.positive.rescue.return.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "{target.name} got someone home alive.",
                                    },
                                    ["TL"] = {
                                        "Naiuwi ni {target.name} nang buhay ang isang tao.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "positive.rescue",
            ["textRoles"] = {
                {
                    ["fallback"] = "{target.name} got someone home alive.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.positive.rescue.return.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "{target.name} got someone home alive.",
                        },
                        ["TL"] = {
                            "Naiuwi ni {target.name} nang buhay ang isang tao.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "positive.rescue.return",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "return",
            ["sourceId"] = "positive.rescue.return",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_reactions/positive_rescue_return.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextMemoryGossipReactions",
        ["namespace"] = "positive.rescue",
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
                ["textKey"] = "positive.rescue.return",
                ["textRows"] = {
                    {
                        ["key"] = "positive.rescue.return",
                        ["text"] = {
                            ["EN"] = "{target.name} got someone home alive.",
                            ["TL"] = "Naiuwi ni {target.name} nang buhay ang isang tao.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
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
                                        "{target.name} got someone home alive.",
                                    },
                                    ["TL"] = {
                                        "Naiuwi ni {target.name} nang buhay ang isang tao.",
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
            ["responsePlanID"] = "positive.rescue.return",
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
                            ["fallback"] = "{target.name} got someone home alive.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.positive.rescue.return.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_text_memory_gossip_reactions/positive_rescue_return.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "{target.name} got someone home alive.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.positive.rescue.return.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "{target.name} got someone home alive.",
                    },
                    ["TL"] = {
                        "Naiuwi ni {target.name} nang buhay ang isang tao.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_reactions",
        ["domainPath"] = "core_text_memory_gossip_reactions",
        ["exchangeFamily"] = {
            ["familyID"] = "positive.sympathy.loss",
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
                                ["fallback"] = "I heard what happened to {target.name}. I hope they are holding up.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.positive.sympathy.loss.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I heard what happened to {target.name}. I hope they are holding up.",
                                    },
                                    ["TL"] = {
                                        "Narinig ko ang nangyari kay {target.name}. Sana kinakaya niya.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "positive.sympathy",
            ["textRoles"] = {
                {
                    ["fallback"] = "I heard what happened to {target.name}. I hope they are holding up.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.positive.sympathy.loss.say.1.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I heard what happened to {target.name}. I hope they are holding up.",
                        },
                        ["TL"] = {
                            "Narinig ko ang nangyari kay {target.name}. Sana kinakaya niya.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "positive.sympathy.loss",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "loss",
            ["sourceId"] = "positive.sympathy.loss",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_reactions/positive_sympathy_loss.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextMemoryGossipReactions",
        ["namespace"] = "positive.sympathy",
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
                ["textKey"] = "positive.sympathy.loss",
                ["textRows"] = {
                    {
                        ["key"] = "positive.sympathy.loss",
                        ["text"] = {
                            ["EN"] = "I heard what happened to {target.name}. I hope they are holding up.",
                            ["TL"] = "Narinig ko ang nangyari kay {target.name}. Sana kinakaya niya.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
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
                                        "I heard what happened to {target.name}. I hope they are holding up.",
                                    },
                                    ["TL"] = {
                                        "Narinig ko ang nangyari kay {target.name}. Sana kinakaya niya.",
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
            ["responsePlanID"] = "positive.sympathy.loss",
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
                            ["fallback"] = "I heard what happened to {target.name}. I hope they are holding up.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.positive.sympathy.loss.say_1",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_text_memory_gossip_reactions/positive_sympathy_loss.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I heard what happened to {target.name}. I hope they are holding up.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.positive.sympathy.loss.say.1.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I heard what happened to {target.name}. I hope they are holding up.",
                    },
                    ["TL"] = {
                        "Narinig ko ang nangyari kay {target.name}. Sana kinakaya niya.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
