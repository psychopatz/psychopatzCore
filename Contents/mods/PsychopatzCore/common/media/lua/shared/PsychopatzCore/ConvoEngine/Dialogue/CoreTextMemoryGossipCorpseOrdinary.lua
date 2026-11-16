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
                                ["translations"] = {
                                    ["EN"] = {
                                        "One less of us, {target.name}. Damn.",
                                    },
                                    ["TL"] = {
                                        "Nabawasan na naman tayo, {target.name}. Nakakainis.",
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
                                ["fallback"] = "You stood with {slot.faction.name}, {target.name}. We won't forget.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.comrade.say.2.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "You stood with {slot.faction.name}, {target.name}. We won't forget.",
                                    },
                                    ["TL"] = {
                                        "Kasama ka ng {slot.faction.name}, {target.name}. Hindi ka namin kalilimutan.",
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
                                ["fallback"] = "We fought side by side, {target.name}. Rest easy.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.comrade.say.3.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "We fought side by side, {target.name}. Rest easy.",
                                    },
                                    ["TL"] = {
                                        "Magkatabi tayong lumaban, {target.name}. Pahinga ka na.",
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
                                ["fallback"] = "{target.name} held the line. We'll carry on.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.comrade.say.4.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "{target.name} held the line. We'll carry on.",
                                    },
                                    ["TL"] = {
                                        "Hindi ka umatras, {target.name}. Itutuloy namin ito.",
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
                                ["fallback"] = "I hope {slot.faction.name} remembers what you gave.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.comrade.say.5.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I hope {slot.faction.name} remembers what you gave.",
                                    },
                                    ["TL"] = {
                                        "Sana maalala ng {slot.faction.name} ang lahat ng ibinigay mo.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "One less of us, {target.name}. Damn.",
                        },
                        ["TL"] = {
                            "Nabawasan na naman tayo, {target.name}. Nakakainis.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "You stood with {slot.faction.name}, {target.name}. We won't forget.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.comrade.say.2.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "You stood with {slot.faction.name}, {target.name}. We won't forget.",
                        },
                        ["TL"] = {
                            "Kasama ka ng {slot.faction.name}, {target.name}. Hindi ka namin kalilimutan.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "We fought side by side, {target.name}. Rest easy.",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.comrade.say.3.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "We fought side by side, {target.name}. Rest easy.",
                        },
                        ["TL"] = {
                            "Magkatabi tayong lumaban, {target.name}. Pahinga ka na.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "{target.name} held the line. We'll carry on.",
                    ["realizationKey"] = "4",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.comrade.say.4.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "{target.name} held the line. We'll carry on.",
                        },
                        ["TL"] = {
                            "Hindi ka umatras, {target.name}. Itutuloy namin ito.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I hope {slot.faction.name} remembers what you gave.",
                    ["realizationKey"] = "5",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.comrade.say.5.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I hope {slot.faction.name} remembers what you gave.",
                        },
                        ["TL"] = {
                            "Sana maalala ng {slot.faction.name} ang lahat ng ibinigay mo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "corpse.comrade",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "comrade",
            ["sourceId"] = "corpse.comrade",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_ordinary/corpse_comrade.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
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
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["key"] = "corpse.comrade.01",
                        ["text"] = {
                            ["EN"] = "One less of us, {target.name}. Damn.",
                            ["TL"] = "Nabawasan na naman tayo, {target.name}. Nakakainis.",
                        },
                    },
                    {
                        ["key"] = "corpse.comrade.02",
                        ["text"] = {
                            ["EN"] = "You stood with {slot.faction.name}, {target.name}. We won't forget.",
                            ["TL"] = "Kasama ka ng {slot.faction.name}, {target.name}. Hindi ka namin kalilimutan.",
                        },
                    },
                    {
                        ["key"] = "corpse.comrade.03",
                        ["text"] = {
                            ["EN"] = "We fought side by side, {target.name}. Rest easy.",
                            ["TL"] = "Magkatabi tayong lumaban, {target.name}. Pahinga ka na.",
                        },
                    },
                    {
                        ["key"] = "corpse.comrade.04",
                        ["text"] = {
                            ["EN"] = "{target.name} held the line. We'll carry on.",
                            ["TL"] = "Hindi ka umatras, {target.name}. Itutuloy namin ito.",
                        },
                    },
                    {
                        ["key"] = "corpse.comrade.05",
                        ["text"] = {
                            ["EN"] = "I hope {slot.faction.name} remembers what you gave.",
                            ["TL"] = "Sana maalala ng {slot.faction.name} ang lahat ng ibinigay mo.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "One less of us, {target.name}. Damn.",
                                    },
                                    ["TL"] = {
                                        "Nabawasan na naman tayo, {target.name}. Nakakainis.",
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
                                        "You stood with {slot.faction.name}, {target.name}. We won't forget.",
                                    },
                                    ["TL"] = {
                                        "Kasama ka ng {slot.faction.name}, {target.name}. Hindi ka namin kalilimutan.",
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
                                        "We fought side by side, {target.name}. Rest easy.",
                                    },
                                    ["TL"] = {
                                        "Magkatabi tayong lumaban, {target.name}. Pahinga ka na.",
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
                                        "{target.name} held the line. We'll carry on.",
                                    },
                                    ["TL"] = {
                                        "Hindi ka umatras, {target.name}. Itutuloy namin ito.",
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
                                        "I hope {slot.faction.name} remembers what you gave.",
                                    },
                                    ["TL"] = {
                                        "Sana maalala ng {slot.faction.name} ang lahat ng ibinigay mo.",
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
                ["translations"] = {
                    ["EN"] = {
                        "One less of us, {target.name}. Damn.",
                    },
                    ["TL"] = {
                        "Nabawasan na naman tayo, {target.name}. Nakakainis.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "You stood with {slot.faction.name}, {target.name}. We won't forget.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.comrade.say.2.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "You stood with {slot.faction.name}, {target.name}. We won't forget.",
                    },
                    ["TL"] = {
                        "Kasama ka ng {slot.faction.name}, {target.name}. Hindi ka namin kalilimutan.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "We fought side by side, {target.name}. Rest easy.",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.comrade.say.3.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "We fought side by side, {target.name}. Rest easy.",
                    },
                    ["TL"] = {
                        "Magkatabi tayong lumaban, {target.name}. Pahinga ka na.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "{target.name} held the line. We'll carry on.",
                ["realizationKey"] = "4",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.comrade.say.4.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "{target.name} held the line. We'll carry on.",
                    },
                    ["TL"] = {
                        "Hindi ka umatras, {target.name}. Itutuloy namin ito.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I hope {slot.faction.name} remembers what you gave.",
                ["realizationKey"] = "5",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.comrade.say.5.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I hope {slot.faction.name} remembers what you gave.",
                    },
                    ["TL"] = {
                        "Sana maalala ng {slot.faction.name} ang lahat ng ibinigay mo.",
                    },
                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "We were supposed to get through this together, {target.name}.",
                                    },
                                    ["TL"] = {
                                        "Dapat sabay nating nalagpasan ito, {target.name}.",
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
                                ["fallback"] = "You always had my back, {target.name}. I should've had yours.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.friend.say.2.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "You always had my back, {target.name}. I should've had yours.",
                                    },
                                    ["TL"] = {
                                        "Lagi mo akong ipinagtatanggol, {target.name}. Dapat ginawa ko rin iyon para sa'yo.",
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
                                ["fallback"] = "I won't let them forget you, {target.name}.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.friend.say.3.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I won't let them forget you, {target.name}.",
                                    },
                                    ["TL"] = {
                                        "Hindi kita hahayaang makalimutan nila, {target.name}.",
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
                                ["fallback"] = "Rest now, {target.name}. You did enough.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.friend.say.4.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Rest now, {target.name}. You did enough.",
                                    },
                                    ["TL"] = {
                                        "Magpahinga ka na, {target.name}. Sapat na ang ginawa mo.",
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
                                ["fallback"] = "We still owed each other a drink, {target.name}.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.friend.say.5.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "We still owed each other a drink, {target.name}.",
                                    },
                                    ["TL"] = {
                                        "May utang pa tayong inumin sa isa't isa, {target.name}.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "We were supposed to get through this together, {target.name}.",
                        },
                        ["TL"] = {
                            "Dapat sabay nating nalagpasan ito, {target.name}.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "You always had my back, {target.name}. I should've had yours.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.friend.say.2.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "You always had my back, {target.name}. I should've had yours.",
                        },
                        ["TL"] = {
                            "Lagi mo akong ipinagtatanggol, {target.name}. Dapat ginawa ko rin iyon para sa'yo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I won't let them forget you, {target.name}.",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.friend.say.3.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I won't let them forget you, {target.name}.",
                        },
                        ["TL"] = {
                            "Hindi kita hahayaang makalimutan nila, {target.name}.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Rest now, {target.name}. You did enough.",
                    ["realizationKey"] = "4",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.friend.say.4.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Rest now, {target.name}. You did enough.",
                        },
                        ["TL"] = {
                            "Magpahinga ka na, {target.name}. Sapat na ang ginawa mo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "We still owed each other a drink, {target.name}.",
                    ["realizationKey"] = "5",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.friend.say.5.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "We still owed each other a drink, {target.name}.",
                        },
                        ["TL"] = {
                            "May utang pa tayong inumin sa isa't isa, {target.name}.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "corpse.friend",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "friend",
            ["sourceId"] = "corpse.friend",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_ordinary/corpse_friend.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
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
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["key"] = "corpse.friend.01",
                        ["text"] = {
                            ["EN"] = "We were supposed to get through this together, {target.name}.",
                            ["TL"] = "Dapat sabay nating nalagpasan ito, {target.name}.",
                        },
                    },
                    {
                        ["key"] = "corpse.friend.02",
                        ["text"] = {
                            ["EN"] = "You always had my back, {target.name}. I should've had yours.",
                            ["TL"] = "Lagi mo akong ipinagtatanggol, {target.name}. Dapat ginawa ko rin iyon para sa'yo.",
                        },
                    },
                    {
                        ["key"] = "corpse.friend.03",
                        ["text"] = {
                            ["EN"] = "I won't let them forget you, {target.name}.",
                            ["TL"] = "Hindi kita hahayaang makalimutan nila, {target.name}.",
                        },
                    },
                    {
                        ["key"] = "corpse.friend.04",
                        ["text"] = {
                            ["EN"] = "Rest now, {target.name}. You did enough.",
                            ["TL"] = "Magpahinga ka na, {target.name}. Sapat na ang ginawa mo.",
                        },
                    },
                    {
                        ["key"] = "corpse.friend.05",
                        ["text"] = {
                            ["EN"] = "We still owed each other a drink, {target.name}.",
                            ["TL"] = "May utang pa tayong inumin sa isa't isa, {target.name}.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "We were supposed to get through this together, {target.name}.",
                                    },
                                    ["TL"] = {
                                        "Dapat sabay nating nalagpasan ito, {target.name}.",
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
                                        "You always had my back, {target.name}. I should've had yours.",
                                    },
                                    ["TL"] = {
                                        "Lagi mo akong ipinagtatanggol, {target.name}. Dapat ginawa ko rin iyon para sa'yo.",
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
                                        "I won't let them forget you, {target.name}.",
                                    },
                                    ["TL"] = {
                                        "Hindi kita hahayaang makalimutan nila, {target.name}.",
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
                                        "Rest now, {target.name}. You did enough.",
                                    },
                                    ["TL"] = {
                                        "Magpahinga ka na, {target.name}. Sapat na ang ginawa mo.",
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
                                        "We still owed each other a drink, {target.name}.",
                                    },
                                    ["TL"] = {
                                        "May utang pa tayong inumin sa isa't isa, {target.name}.",
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
                ["translations"] = {
                    ["EN"] = {
                        "We were supposed to get through this together, {target.name}.",
                    },
                    ["TL"] = {
                        "Dapat sabay nating nalagpasan ito, {target.name}.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "You always had my back, {target.name}. I should've had yours.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.friend.say.2.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "You always had my back, {target.name}. I should've had yours.",
                    },
                    ["TL"] = {
                        "Lagi mo akong ipinagtatanggol, {target.name}. Dapat ginawa ko rin iyon para sa'yo.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I won't let them forget you, {target.name}.",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.friend.say.3.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I won't let them forget you, {target.name}.",
                    },
                    ["TL"] = {
                        "Hindi kita hahayaang makalimutan nila, {target.name}.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Rest now, {target.name}. You did enough.",
                ["realizationKey"] = "4",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.friend.say.4.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Rest now, {target.name}. You did enough.",
                    },
                    ["TL"] = {
                        "Magpahinga ka na, {target.name}. Sapat na ang ginawa mo.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "We still owed each other a drink, {target.name}.",
                ["realizationKey"] = "5",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.friend.say.5.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "We still owed each other a drink, {target.name}.",
                    },
                    ["TL"] = {
                        "May utang pa tayong inumin sa isa't isa, {target.name}.",
                    },
                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "So this is how it ends for you, {target.name}.",
                                    },
                                    ["TL"] = {
                                        "Dito pala magtatapos para sa'yo, {target.name}.",
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
                                ["fallback"] = "You made plenty of enemies, {target.name}. I was one.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.hostile.say.2.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "You made plenty of enemies, {target.name}. I was one.",
                                    },
                                    ["TL"] = {
                                        "Marami kang naging kaaway, {target.name}. Isa ako roon.",
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
                                ["fallback"] = "I won't mourn you, {target.name}, but I won't forget this.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.hostile.say.3.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I won't mourn you, {target.name}, but I won't forget this.",
                                    },
                                    ["TL"] = {
                                        "Hindi kita ipagluluksa, {target.name}, pero hindi ko ito malilimutan.",
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
                                ["fallback"] = "The threat is gone. Keep moving.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.hostile.say.4.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "The threat is gone. Keep moving.",
                                    },
                                    ["TL"] = {
                                        "Wala na ang banta. Tuloy lang.",
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
                                ["fallback"] = "Maybe you finally found some peace, {target.name}.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.hostile.say.5.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Maybe you finally found some peace, {target.name}.",
                                    },
                                    ["TL"] = {
                                        "Baka nakahanap ka na rin ng katahimikan, {target.name}.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "So this is how it ends for you, {target.name}.",
                        },
                        ["TL"] = {
                            "Dito pala magtatapos para sa'yo, {target.name}.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "You made plenty of enemies, {target.name}. I was one.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.hostile.say.2.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "You made plenty of enemies, {target.name}. I was one.",
                        },
                        ["TL"] = {
                            "Marami kang naging kaaway, {target.name}. Isa ako roon.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I won't mourn you, {target.name}, but I won't forget this.",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.hostile.say.3.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I won't mourn you, {target.name}, but I won't forget this.",
                        },
                        ["TL"] = {
                            "Hindi kita ipagluluksa, {target.name}, pero hindi ko ito malilimutan.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "The threat is gone. Keep moving.",
                    ["realizationKey"] = "4",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.hostile.say.4.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "The threat is gone. Keep moving.",
                        },
                        ["TL"] = {
                            "Wala na ang banta. Tuloy lang.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Maybe you finally found some peace, {target.name}.",
                    ["realizationKey"] = "5",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.hostile.say.5.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Maybe you finally found some peace, {target.name}.",
                        },
                        ["TL"] = {
                            "Baka nakahanap ka na rin ng katahimikan, {target.name}.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "corpse.hostile",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "hostile",
            ["sourceId"] = "corpse.hostile",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_ordinary/corpse_hostile.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
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
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["key"] = "corpse.hostile.01",
                        ["text"] = {
                            ["EN"] = "So this is how it ends for you, {target.name}.",
                            ["TL"] = "Dito pala magtatapos para sa'yo, {target.name}.",
                        },
                    },
                    {
                        ["key"] = "corpse.hostile.02",
                        ["text"] = {
                            ["EN"] = "You made plenty of enemies, {target.name}. I was one.",
                            ["TL"] = "Marami kang naging kaaway, {target.name}. Isa ako roon.",
                        },
                    },
                    {
                        ["key"] = "corpse.hostile.03",
                        ["text"] = {
                            ["EN"] = "I won't mourn you, {target.name}, but I won't forget this.",
                            ["TL"] = "Hindi kita ipagluluksa, {target.name}, pero hindi ko ito malilimutan.",
                        },
                    },
                    {
                        ["key"] = "corpse.hostile.04",
                        ["text"] = {
                            ["EN"] = "The threat is gone. Keep moving.",
                            ["TL"] = "Wala na ang banta. Tuloy lang.",
                        },
                    },
                    {
                        ["key"] = "corpse.hostile.05",
                        ["text"] = {
                            ["EN"] = "Maybe you finally found some peace, {target.name}.",
                            ["TL"] = "Baka nakahanap ka na rin ng katahimikan, {target.name}.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "So this is how it ends for you, {target.name}.",
                                    },
                                    ["TL"] = {
                                        "Dito pala magtatapos para sa'yo, {target.name}.",
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
                                        "You made plenty of enemies, {target.name}. I was one.",
                                    },
                                    ["TL"] = {
                                        "Marami kang naging kaaway, {target.name}. Isa ako roon.",
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
                                        "I won't mourn you, {target.name}, but I won't forget this.",
                                    },
                                    ["TL"] = {
                                        "Hindi kita ipagluluksa, {target.name}, pero hindi ko ito malilimutan.",
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
                                        "The threat is gone. Keep moving.",
                                    },
                                    ["TL"] = {
                                        "Wala na ang banta. Tuloy lang.",
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
                                        "Maybe you finally found some peace, {target.name}.",
                                    },
                                    ["TL"] = {
                                        "Baka nakahanap ka na rin ng katahimikan, {target.name}.",
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
                ["translations"] = {
                    ["EN"] = {
                        "So this is how it ends for you, {target.name}.",
                    },
                    ["TL"] = {
                        "Dito pala magtatapos para sa'yo, {target.name}.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "You made plenty of enemies, {target.name}. I was one.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.hostile.say.2.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "You made plenty of enemies, {target.name}. I was one.",
                    },
                    ["TL"] = {
                        "Marami kang naging kaaway, {target.name}. Isa ako roon.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I won't mourn you, {target.name}, but I won't forget this.",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.hostile.say.3.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I won't mourn you, {target.name}, but I won't forget this.",
                    },
                    ["TL"] = {
                        "Hindi kita ipagluluksa, {target.name}, pero hindi ko ito malilimutan.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "The threat is gone. Keep moving.",
                ["realizationKey"] = "4",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.hostile.say.4.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "The threat is gone. Keep moving.",
                    },
                    ["TL"] = {
                        "Wala na ang banta. Tuloy lang.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Maybe you finally found some peace, {target.name}.",
                ["realizationKey"] = "5",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.hostile.say.5.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Maybe you finally found some peace, {target.name}.",
                    },
                    ["TL"] = {
                        "Baka nakahanap ka na rin ng katahimikan, {target.name}.",
                    },
                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "I didn't know you, {target.name}. You deserved better.",
                                    },
                                    ["TL"] = {
                                        "Hindi kita nakilala, {target.name}. Hindi mo dapat naranasan ito.",
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
                                ["fallback"] = "I hope someone remembers your name, {target.name}.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.neutral.say.2.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I hope someone remembers your name, {target.name}.",
                                    },
                                    ["TL"] = {
                                        "Sana may makaalala pa sa pangalan mo, {target.name}.",
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
                                ["fallback"] = "This place takes everyone, doesn't it?",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.neutral.say.3.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "This place takes everyone, doesn't it?",
                                    },
                                    ["TL"] = {
                                        "Nilalamon ng lugar na ito ang lahat, ano?",
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
                                ["fallback"] = "Someone should have found you sooner, {target.name}.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.neutral.say.4.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Someone should have found you sooner, {target.name}.",
                                    },
                                    ["TL"] = {
                                        "Sana may nakakita sa'yo nang mas maaga, {target.name}.",
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
                                ["fallback"] = "Rest now, {target.name}. I won't leave you unnamed.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.neutral.say.5.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "Rest now, {target.name}. I won't leave you unnamed.",
                                    },
                                    ["TL"] = {
                                        "Magpahinga ka, {target.name}. Hindi kita hahayaang mabaon nang walang pangalan.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "I didn't know you, {target.name}. You deserved better.",
                        },
                        ["TL"] = {
                            "Hindi kita nakilala, {target.name}. Hindi mo dapat naranasan ito.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I hope someone remembers your name, {target.name}.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.neutral.say.2.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I hope someone remembers your name, {target.name}.",
                        },
                        ["TL"] = {
                            "Sana may makaalala pa sa pangalan mo, {target.name}.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "This place takes everyone, doesn't it?",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.neutral.say.3.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "This place takes everyone, doesn't it?",
                        },
                        ["TL"] = {
                            "Nilalamon ng lugar na ito ang lahat, ano?",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Someone should have found you sooner, {target.name}.",
                    ["realizationKey"] = "4",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.neutral.say.4.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Someone should have found you sooner, {target.name}.",
                        },
                        ["TL"] = {
                            "Sana may nakakita sa'yo nang mas maaga, {target.name}.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Rest now, {target.name}. I won't leave you unnamed.",
                    ["realizationKey"] = "5",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.neutral.say.5.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Rest now, {target.name}. I won't leave you unnamed.",
                        },
                        ["TL"] = {
                            "Magpahinga ka, {target.name}. Hindi kita hahayaang mabaon nang walang pangalan.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "corpse.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "neutral",
            ["sourceId"] = "corpse.neutral",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_ordinary/corpse.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
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
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["key"] = "corpse.neutral.01",
                        ["text"] = {
                            ["EN"] = "I didn't know you, {target.name}. You deserved better.",
                            ["TL"] = "Hindi kita nakilala, {target.name}. Hindi mo dapat naranasan ito.",
                        },
                    },
                    {
                        ["key"] = "corpse.neutral.02",
                        ["text"] = {
                            ["EN"] = "I hope someone remembers your name, {target.name}.",
                            ["TL"] = "Sana may makaalala pa sa pangalan mo, {target.name}.",
                        },
                    },
                    {
                        ["key"] = "corpse.neutral.03",
                        ["text"] = {
                            ["EN"] = "This place takes everyone, doesn't it?",
                            ["TL"] = "Nilalamon ng lugar na ito ang lahat, ano?",
                        },
                    },
                    {
                        ["key"] = "corpse.neutral.04",
                        ["text"] = {
                            ["EN"] = "Someone should have found you sooner, {target.name}.",
                            ["TL"] = "Sana may nakakita sa'yo nang mas maaga, {target.name}.",
                        },
                    },
                    {
                        ["key"] = "corpse.neutral.05",
                        ["text"] = {
                            ["EN"] = "Rest now, {target.name}. I won't leave you unnamed.",
                            ["TL"] = "Magpahinga ka, {target.name}. Hindi kita hahayaang mabaon nang walang pangalan.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "I didn't know you, {target.name}. You deserved better.",
                                    },
                                    ["TL"] = {
                                        "Hindi kita nakilala, {target.name}. Hindi mo dapat naranasan ito.",
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
                                        "I hope someone remembers your name, {target.name}.",
                                    },
                                    ["TL"] = {
                                        "Sana may makaalala pa sa pangalan mo, {target.name}.",
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
                                        "This place takes everyone, doesn't it?",
                                    },
                                    ["TL"] = {
                                        "Nilalamon ng lugar na ito ang lahat, ano?",
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
                                        "Someone should have found you sooner, {target.name}.",
                                    },
                                    ["TL"] = {
                                        "Sana may nakakita sa'yo nang mas maaga, {target.name}.",
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
                                        "Rest now, {target.name}. I won't leave you unnamed.",
                                    },
                                    ["TL"] = {
                                        "Magpahinga ka, {target.name}. Hindi kita hahayaang mabaon nang walang pangalan.",
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
                ["translations"] = {
                    ["EN"] = {
                        "I didn't know you, {target.name}. You deserved better.",
                    },
                    ["TL"] = {
                        "Hindi kita nakilala, {target.name}. Hindi mo dapat naranasan ito.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I hope someone remembers your name, {target.name}.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.neutral.say.2.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I hope someone remembers your name, {target.name}.",
                    },
                    ["TL"] = {
                        "Sana may makaalala pa sa pangalan mo, {target.name}.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "This place takes everyone, doesn't it?",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.neutral.say.3.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "This place takes everyone, doesn't it?",
                    },
                    ["TL"] = {
                        "Nilalamon ng lugar na ito ang lahat, ano?",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Someone should have found you sooner, {target.name}.",
                ["realizationKey"] = "4",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.neutral.say.4.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Someone should have found you sooner, {target.name}.",
                    },
                    ["TL"] = {
                        "Sana may nakakita sa'yo nang mas maaga, {target.name}.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Rest now, {target.name}. I won't leave you unnamed.",
                ["realizationKey"] = "5",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.neutral.say.5.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Rest now, {target.name}. I won't leave you unnamed.",
                    },
                    ["TL"] = {
                        "Magpahinga ka, {target.name}. Hindi kita hahayaang mabaon nang walang pangalan.",
                    },
                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "No, {target.name}. You were family.",
                                    },
                                    ["TL"] = {
                                        "Hindi... si {target.name}. Pamilya tayo.",
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
                                ["fallback"] = "I thought we'd meet again, {target.name}.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.relative.say.2.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I thought we'd meet again, {target.name}.",
                                    },
                                    ["TL"] = {
                                        "Akala ko magkikita pa tayo, {target.name}.",
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
                                ["fallback"] = "You should have made it home, {target.name}.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.relative.say.3.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "You should have made it home, {target.name}.",
                                    },
                                    ["TL"] = {
                                        "Dapat nakauwi ka pa, {target.name}.",
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
                                ["fallback"] = "I'll carry you with me, {target.name}. I promise.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.relative.say.4.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'll carry you with me, {target.name}. I promise.",
                                    },
                                    ["TL"] = {
                                        "Dadalahin kita sa alaala ko, {target.name}. Pangako.",
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
                                ["fallback"] = "{target.name}, I'm sorry I wasn't there.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.corpse.relative.say.5.neutral",
                                ["textRole"] = "spoken_action",
                                ["translations"] = {
                                    ["EN"] = {
                                        "{target.name}, I'm sorry I wasn't there.",
                                    },
                                    ["TL"] = {
                                        "{target.name}, patawad at wala ako roon.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "No, {target.name}. You were family.",
                        },
                        ["TL"] = {
                            "Hindi... si {target.name}. Pamilya tayo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I thought we'd meet again, {target.name}.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.relative.say.2.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I thought we'd meet again, {target.name}.",
                        },
                        ["TL"] = {
                            "Akala ko magkikita pa tayo, {target.name}.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "You should have made it home, {target.name}.",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.relative.say.3.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "You should have made it home, {target.name}.",
                        },
                        ["TL"] = {
                            "Dapat nakauwi ka pa, {target.name}.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I'll carry you with me, {target.name}. I promise.",
                    ["realizationKey"] = "4",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.relative.say.4.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'll carry you with me, {target.name}. I promise.",
                        },
                        ["TL"] = {
                            "Dadalahin kita sa alaala ko, {target.name}. Pangako.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "{target.name}, I'm sorry I wasn't there.",
                    ["realizationKey"] = "5",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.corpse.relative.say.5.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "{target.name}, I'm sorry I wasn't there.",
                        },
                        ["TL"] = {
                            "{target.name}, patawad at wala ako roon.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "corpse.relative",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "relative",
            ["sourceId"] = "corpse.relative",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_ordinary/corpse_relative.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
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
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["key"] = "corpse.relative.01",
                        ["text"] = {
                            ["EN"] = "No, {target.name}. You were family.",
                            ["TL"] = "Hindi... si {target.name}. Pamilya tayo.",
                        },
                    },
                    {
                        ["key"] = "corpse.relative.02",
                        ["text"] = {
                            ["EN"] = "I thought we'd meet again, {target.name}.",
                            ["TL"] = "Akala ko magkikita pa tayo, {target.name}.",
                        },
                    },
                    {
                        ["key"] = "corpse.relative.03",
                        ["text"] = {
                            ["EN"] = "You should have made it home, {target.name}.",
                            ["TL"] = "Dapat nakauwi ka pa, {target.name}.",
                        },
                    },
                    {
                        ["key"] = "corpse.relative.04",
                        ["text"] = {
                            ["EN"] = "I'll carry you with me, {target.name}. I promise.",
                            ["TL"] = "Dadalahin kita sa alaala ko, {target.name}. Pangako.",
                        },
                    },
                    {
                        ["key"] = "corpse.relative.05",
                        ["text"] = {
                            ["EN"] = "{target.name}, I'm sorry I wasn't there.",
                            ["TL"] = "{target.name}, patawad at wala ako roon.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "No, {target.name}. You were family.",
                                    },
                                    ["TL"] = {
                                        "Hindi... si {target.name}. Pamilya tayo.",
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
                                        "I thought we'd meet again, {target.name}.",
                                    },
                                    ["TL"] = {
                                        "Akala ko magkikita pa tayo, {target.name}.",
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
                                        "You should have made it home, {target.name}.",
                                    },
                                    ["TL"] = {
                                        "Dapat nakauwi ka pa, {target.name}.",
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
                                        "I'll carry you with me, {target.name}. I promise.",
                                    },
                                    ["TL"] = {
                                        "Dadalahin kita sa alaala ko, {target.name}. Pangako.",
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
                                        "{target.name}, I'm sorry I wasn't there.",
                                    },
                                    ["TL"] = {
                                        "{target.name}, patawad at wala ako roon.",
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
                ["translations"] = {
                    ["EN"] = {
                        "No, {target.name}. You were family.",
                    },
                    ["TL"] = {
                        "Hindi... si {target.name}. Pamilya tayo.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I thought we'd meet again, {target.name}.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.relative.say.2.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I thought we'd meet again, {target.name}.",
                    },
                    ["TL"] = {
                        "Akala ko magkikita pa tayo, {target.name}.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "You should have made it home, {target.name}.",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.relative.say.3.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "You should have made it home, {target.name}.",
                    },
                    ["TL"] = {
                        "Dapat nakauwi ka pa, {target.name}.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I'll carry you with me, {target.name}. I promise.",
                ["realizationKey"] = "4",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.relative.say.4.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'll carry you with me, {target.name}. I promise.",
                    },
                    ["TL"] = {
                        "Dadalahin kita sa alaala ko, {target.name}. Pangako.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "{target.name}, I'm sorry I wasn't there.",
                ["realizationKey"] = "5",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.corpse.relative.say.5.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "{target.name}, I'm sorry I wasn't there.",
                    },
                    ["TL"] = {
                        "{target.name}, patawad at wala ako roon.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
