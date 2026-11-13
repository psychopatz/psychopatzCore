-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_text_memory_gossip_corpse_ordinary",
        ["id"] = "text.corpse.comrade.01",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.comrade.01",
            ["sourcePath"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json#records[0]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__790002e8",
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
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.ordinary.comrade",
                ["sourcePath"] = "memory/gossip/corpse/ordinary/comrade.json",
                ["textKey"] = "corpse.comrade.01",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.comrade.01",
                        ["text"] = {
                            ["EN"] = "One less of us, {target.name}. Damn.",
                            ["TL"] = "Nabawasan na naman tayo, {target.name}. Nakakainis.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "One less of us, {target.name}. Damn.",
                },
                ["TL"] = {
                    "Nabawasan na naman tayo, {target.name}. Nakakainis.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.comrade.01",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "One less of us, {target.name}. Damn.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.comrade.01.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_ordinary",
        ["id"] = "text.corpse.comrade.02",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.comrade.02",
            ["sourcePath"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json#records[1]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__790002e8",
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
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.ordinary.comrade",
                ["sourcePath"] = "memory/gossip/corpse/ordinary/comrade.json",
                ["textKey"] = "corpse.comrade.02",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.comrade.02",
                        ["text"] = {
                            ["EN"] = "You stood with {slot.faction.name}, {target.name}. We won't forget.",
                            ["TL"] = "Kasama ka ng {slot.faction.name}, {target.name}. Hindi ka namin kalilimutan.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "You stood with {slot.faction.name}, {target.name}. We won't forget.",
                },
                ["TL"] = {
                    "Kasama ka ng {slot.faction.name}, {target.name}. Hindi ka namin kalilimutan.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.comrade.02",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "You stood with {slot.faction.name}, {target.name}. We won't forget.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.comrade.02.response",
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
        ["sourceShard"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_ordinary",
        ["id"] = "text.corpse.comrade.03",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.comrade.03",
            ["sourcePath"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json#records[2]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__790002e8",
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
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.ordinary.comrade",
                ["sourcePath"] = "memory/gossip/corpse/ordinary/comrade.json",
                ["textKey"] = "corpse.comrade.03",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.comrade.03",
                        ["text"] = {
                            ["EN"] = "We fought side by side, {target.name}. Rest easy.",
                            ["TL"] = "Magkatabi tayong lumaban, {target.name}. Pahinga ka na.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "We fought side by side, {target.name}. Rest easy.",
                },
                ["TL"] = {
                    "Magkatabi tayong lumaban, {target.name}. Pahinga ka na.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.comrade.03",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "We fought side by side, {target.name}. Rest easy.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.comrade.03.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_ordinary",
        ["id"] = "text.corpse.comrade.04",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.comrade.04",
            ["sourcePath"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json#records[3]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__790002e8",
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
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.ordinary.comrade",
                ["sourcePath"] = "memory/gossip/corpse/ordinary/comrade.json",
                ["textKey"] = "corpse.comrade.04",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.comrade.04",
                        ["text"] = {
                            ["EN"] = "{target.name} held the line. We'll carry on.",
                            ["TL"] = "Hindi ka umatras, {target.name}. Itutuloy namin ito.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "{target.name} held the line. We'll carry on.",
                },
                ["TL"] = {
                    "Hindi ka umatras, {target.name}. Itutuloy namin ito.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.comrade.04",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "{target.name} held the line. We'll carry on.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.comrade.04.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_ordinary",
        ["id"] = "text.corpse.comrade.05",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.comrade.05",
            ["sourcePath"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json#records[4]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__790002e8",
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
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.ordinary.comrade",
                ["sourcePath"] = "memory/gossip/corpse/ordinary/comrade.json",
                ["textKey"] = "corpse.comrade.05",
                ["textRows"] = {
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
            ["text"] = {
                ["EN"] = {
                    "I hope {slot.faction.name} remembers what you gave.",
                },
                ["TL"] = {
                    "Sana maalala ng {slot.faction.name} ang lahat ng ibinigay mo.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.comrade.05",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I hope {slot.faction.name} remembers what you gave.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.comrade.05.response",
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
        ["sourceShard"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_ordinary",
        ["id"] = "text.corpse.friend.01",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.friend.01",
            ["sourcePath"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json#records[5]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__790002e8",
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
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.ordinary.friend",
                ["sourcePath"] = "memory/gossip/corpse/ordinary/friend.json",
                ["textKey"] = "corpse.friend.01",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.friend.01",
                        ["text"] = {
                            ["EN"] = "We were supposed to get through this together, {target.name}.",
                            ["TL"] = "Dapat sabay nating nalagpasan ito, {target.name}.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "We were supposed to get through this together, {target.name}.",
                },
                ["TL"] = {
                    "Dapat sabay nating nalagpasan ito, {target.name}.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.friend.01",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "We were supposed to get through this together, {target.name}.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.friend.01.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_ordinary",
        ["id"] = "text.corpse.friend.02",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.friend.02",
            ["sourcePath"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json#records[6]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__790002e8",
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
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.ordinary.friend",
                ["sourcePath"] = "memory/gossip/corpse/ordinary/friend.json",
                ["textKey"] = "corpse.friend.02",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.friend.02",
                        ["text"] = {
                            ["EN"] = "You always had my back, {target.name}. I should've had yours.",
                            ["TL"] = "Lagi mo akong ipinagtatanggol, {target.name}. Dapat ginawa ko rin iyon para sa'yo.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "You always had my back, {target.name}. I should've had yours.",
                },
                ["TL"] = {
                    "Lagi mo akong ipinagtatanggol, {target.name}. Dapat ginawa ko rin iyon para sa'yo.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.friend.02",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "You always had my back, {target.name}. I should've had yours.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.friend.02.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_ordinary",
        ["id"] = "text.corpse.friend.03",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.friend.03",
            ["sourcePath"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json#records[7]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__790002e8",
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
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.ordinary.friend",
                ["sourcePath"] = "memory/gossip/corpse/ordinary/friend.json",
                ["textKey"] = "corpse.friend.03",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.friend.03",
                        ["text"] = {
                            ["EN"] = "I won't let them forget you, {target.name}.",
                            ["TL"] = "Hindi kita hahayaang makalimutan nila, {target.name}.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "I won't let them forget you, {target.name}.",
                },
                ["TL"] = {
                    "Hindi kita hahayaang makalimutan nila, {target.name}.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.friend.03",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I won't let them forget you, {target.name}.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.friend.03.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_ordinary",
        ["id"] = "text.corpse.friend.04",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.friend.04",
            ["sourcePath"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json#records[8]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__790002e8",
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
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.ordinary.friend",
                ["sourcePath"] = "memory/gossip/corpse/ordinary/friend.json",
                ["textKey"] = "corpse.friend.04",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.friend.04",
                        ["text"] = {
                            ["EN"] = "Rest now, {target.name}. You did enough.",
                            ["TL"] = "Magpahinga ka na, {target.name}. Sapat na ang ginawa mo.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "Rest now, {target.name}. You did enough.",
                },
                ["TL"] = {
                    "Magpahinga ka na, {target.name}. Sapat na ang ginawa mo.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.friend.04",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Rest now, {target.name}. You did enough.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.friend.04.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_ordinary",
        ["id"] = "text.corpse.friend.05",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.friend.05",
            ["sourcePath"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json#records[9]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__790002e8",
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
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.ordinary.friend",
                ["sourcePath"] = "memory/gossip/corpse/ordinary/friend.json",
                ["textKey"] = "corpse.friend.05",
                ["textRows"] = {
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
            ["text"] = {
                ["EN"] = {
                    "We still owed each other a drink, {target.name}.",
                },
                ["TL"] = {
                    "May utang pa tayong inumin sa isa't isa, {target.name}.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.friend.05",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "We still owed each other a drink, {target.name}.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.friend.05.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_ordinary",
        ["id"] = "text.corpse.hostile.01",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.hostile.01",
            ["sourcePath"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json#records[10]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__790002e8",
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
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.ordinary.hostile",
                ["sourcePath"] = "memory/gossip/corpse/ordinary/hostile.json",
                ["textKey"] = "corpse.hostile.01",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.hostile.01",
                        ["text"] = {
                            ["EN"] = "So this is how it ends for you, {target.name}.",
                            ["TL"] = "Dito pala magtatapos para sa'yo, {target.name}.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "So this is how it ends for you, {target.name}.",
                },
                ["TL"] = {
                    "Dito pala magtatapos para sa'yo, {target.name}.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.hostile.01",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "So this is how it ends for you, {target.name}.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.hostile.01.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_ordinary",
        ["id"] = "text.corpse.hostile.02",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.hostile.02",
            ["sourcePath"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json#records[11]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__790002e8",
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
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.ordinary.hostile",
                ["sourcePath"] = "memory/gossip/corpse/ordinary/hostile.json",
                ["textKey"] = "corpse.hostile.02",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.hostile.02",
                        ["text"] = {
                            ["EN"] = "You made plenty of enemies, {target.name}. I was one.",
                            ["TL"] = "Marami kang naging kaaway, {target.name}. Isa ako roon.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "You made plenty of enemies, {target.name}. I was one.",
                },
                ["TL"] = {
                    "Marami kang naging kaaway, {target.name}. Isa ako roon.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.hostile.02",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "You made plenty of enemies, {target.name}. I was one.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.hostile.02.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_ordinary",
        ["id"] = "text.corpse.hostile.03",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.hostile.03",
            ["sourcePath"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json#records[12]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__790002e8",
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
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.ordinary.hostile",
                ["sourcePath"] = "memory/gossip/corpse/ordinary/hostile.json",
                ["textKey"] = "corpse.hostile.03",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.hostile.03",
                        ["text"] = {
                            ["EN"] = "I won't mourn you, {target.name}, but I won't forget this.",
                            ["TL"] = "Hindi kita ipagluluksa, {target.name}, pero hindi ko ito malilimutan.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "I won't mourn you, {target.name}, but I won't forget this.",
                },
                ["TL"] = {
                    "Hindi kita ipagluluksa, {target.name}, pero hindi ko ito malilimutan.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.hostile.03",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I won't mourn you, {target.name}, but I won't forget this.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.hostile.03.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_ordinary",
        ["id"] = "text.corpse.hostile.04",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.hostile.04",
            ["sourcePath"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json#records[13]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__790002e8",
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
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.ordinary.hostile",
                ["sourcePath"] = "memory/gossip/corpse/ordinary/hostile.json",
                ["textKey"] = "corpse.hostile.04",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.hostile.04",
                        ["text"] = {
                            ["EN"] = "The threat is gone. Keep moving.",
                            ["TL"] = "Wala na ang banta. Tuloy lang.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "The threat is gone. Keep moving.",
                },
                ["TL"] = {
                    "Wala na ang banta. Tuloy lang.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.hostile.04",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "The threat is gone. Keep moving.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.hostile.04.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_ordinary",
        ["id"] = "text.corpse.hostile.05",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.hostile.05",
            ["sourcePath"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json#records[14]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__790002e8",
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
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.ordinary.hostile",
                ["sourcePath"] = "memory/gossip/corpse/ordinary/hostile.json",
                ["textKey"] = "corpse.hostile.05",
                ["textRows"] = {
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
            ["text"] = {
                ["EN"] = {
                    "Maybe you finally found some peace, {target.name}.",
                },
                ["TL"] = {
                    "Baka nakahanap ka na rin ng katahimikan, {target.name}.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.hostile.05",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Maybe you finally found some peace, {target.name}.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.hostile.05.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_ordinary",
        ["id"] = "text.corpse.neutral.01",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.neutral.01",
            ["sourcePath"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json#records[15]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__790002e8",
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
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.ordinary.neutral",
                ["sourcePath"] = "memory/gossip/corpse/ordinary/neutral.json",
                ["textKey"] = "corpse.neutral.01",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.neutral.01",
                        ["text"] = {
                            ["EN"] = "I didn't know you, {target.name}. You deserved better.",
                            ["TL"] = "Hindi kita nakilala, {target.name}. Hindi mo dapat naranasan ito.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "I didn't know you, {target.name}. You deserved better.",
                },
                ["TL"] = {
                    "Hindi kita nakilala, {target.name}. Hindi mo dapat naranasan ito.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.neutral.01",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I didn't know you, {target.name}. You deserved better.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.neutral.01.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_ordinary",
        ["id"] = "text.corpse.neutral.02",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.neutral.02",
            ["sourcePath"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json#records[16]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__790002e8",
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
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.ordinary.neutral",
                ["sourcePath"] = "memory/gossip/corpse/ordinary/neutral.json",
                ["textKey"] = "corpse.neutral.02",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.neutral.02",
                        ["text"] = {
                            ["EN"] = "I hope someone remembers your name, {target.name}.",
                            ["TL"] = "Sana may makaalala pa sa pangalan mo, {target.name}.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "I hope someone remembers your name, {target.name}.",
                },
                ["TL"] = {
                    "Sana may makaalala pa sa pangalan mo, {target.name}.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.neutral.02",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I hope someone remembers your name, {target.name}.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.neutral.02.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_ordinary",
        ["id"] = "text.corpse.neutral.03",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.neutral.03",
            ["sourcePath"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json#records[17]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__790002e8",
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
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.ordinary.neutral",
                ["sourcePath"] = "memory/gossip/corpse/ordinary/neutral.json",
                ["textKey"] = "corpse.neutral.03",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.neutral.03",
                        ["text"] = {
                            ["EN"] = "This place takes everyone, doesn't it?",
                            ["TL"] = "Nilalamon ng lugar na ito ang lahat, ano?",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "This place takes everyone, doesn't it?",
                },
                ["TL"] = {
                    "Nilalamon ng lugar na ito ang lahat, ano?",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.neutral.03",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "This place takes everyone, doesn't it?",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.neutral.03.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_ordinary",
        ["id"] = "text.corpse.neutral.04",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.neutral.04",
            ["sourcePath"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json#records[18]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__790002e8",
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
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.ordinary.neutral",
                ["sourcePath"] = "memory/gossip/corpse/ordinary/neutral.json",
                ["textKey"] = "corpse.neutral.04",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.neutral.04",
                        ["text"] = {
                            ["EN"] = "Someone should have found you sooner, {target.name}.",
                            ["TL"] = "Sana may nakakita sa'yo nang mas maaga, {target.name}.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "Someone should have found you sooner, {target.name}.",
                },
                ["TL"] = {
                    "Sana may nakakita sa'yo nang mas maaga, {target.name}.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.neutral.04",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Someone should have found you sooner, {target.name}.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.neutral.04.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_ordinary",
        ["id"] = "text.corpse.neutral.05",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.neutral.05",
            ["sourcePath"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json#records[19]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__790002e8",
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
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.ordinary.neutral",
                ["sourcePath"] = "memory/gossip/corpse/ordinary/neutral.json",
                ["textKey"] = "corpse.neutral.05",
                ["textRows"] = {
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
            ["text"] = {
                ["EN"] = {
                    "Rest now, {target.name}. I won't leave you unnamed.",
                },
                ["TL"] = {
                    "Magpahinga ka, {target.name}. Hindi kita hahayaang mabaon nang walang pangalan.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.neutral.05",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Rest now, {target.name}. I won't leave you unnamed.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.neutral.05.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_ordinary",
        ["id"] = "text.corpse.relative.01",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.relative.01",
            ["sourcePath"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json#records[20]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__790002e8",
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
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.ordinary.relative",
                ["sourcePath"] = "memory/gossip/corpse/ordinary/relative.json",
                ["textKey"] = "corpse.relative.01",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.relative.01",
                        ["text"] = {
                            ["EN"] = "No, {target.name}. You were family.",
                            ["TL"] = "Hindi... si {target.name}. Pamilya tayo.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "No, {target.name}. You were family.",
                },
                ["TL"] = {
                    "Hindi... si {target.name}. Pamilya tayo.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.relative.01",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "No, {target.name}. You were family.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.relative.01.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_ordinary",
        ["id"] = "text.corpse.relative.02",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.relative.02",
            ["sourcePath"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json#records[21]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__790002e8",
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
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.ordinary.relative",
                ["sourcePath"] = "memory/gossip/corpse/ordinary/relative.json",
                ["textKey"] = "corpse.relative.02",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.relative.02",
                        ["text"] = {
                            ["EN"] = "I thought we'd meet again, {target.name}.",
                            ["TL"] = "Akala ko magkikita pa tayo, {target.name}.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "I thought we'd meet again, {target.name}.",
                },
                ["TL"] = {
                    "Akala ko magkikita pa tayo, {target.name}.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.relative.02",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I thought we'd meet again, {target.name}.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.relative.02.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_ordinary",
        ["id"] = "text.corpse.relative.03",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.relative.03",
            ["sourcePath"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json#records[22]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__790002e8",
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
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.ordinary.relative",
                ["sourcePath"] = "memory/gossip/corpse/ordinary/relative.json",
                ["textKey"] = "corpse.relative.03",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.relative.03",
                        ["text"] = {
                            ["EN"] = "You should have made it home, {target.name}.",
                            ["TL"] = "Dapat nakauwi ka pa, {target.name}.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "You should have made it home, {target.name}.",
                },
                ["TL"] = {
                    "Dapat nakauwi ka pa, {target.name}.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.relative.03",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "You should have made it home, {target.name}.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.relative.03.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_ordinary",
        ["id"] = "text.corpse.relative.04",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.relative.04",
            ["sourcePath"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json#records[23]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__790002e8",
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
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.ordinary.relative",
                ["sourcePath"] = "memory/gossip/corpse/ordinary/relative.json",
                ["textKey"] = "corpse.relative.04",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.relative.04",
                        ["text"] = {
                            ["EN"] = "I'll carry you with me, {target.name}. I promise.",
                            ["TL"] = "Dadalahin kita sa alaala ko, {target.name}. Pangako.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "I'll carry you with me, {target.name}. I promise.",
                },
                ["TL"] = {
                    "Dadalahin kita sa alaala ko, {target.name}. Pangako.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.relative.04",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I'll carry you with me, {target.name}. I promise.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.relative.04.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_ordinary",
        ["id"] = "text.corpse.relative.05",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.relative.05",
            ["sourcePath"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json#records[24]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__790002e8",
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
                ["migration"] = "Core PSDL text record; translation catalog is downstream output",
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.ordinary.relative",
                ["sourcePath"] = "memory/gossip/corpse/ordinary/relative.json",
                ["textKey"] = "corpse.relative.05",
                ["textRows"] = {
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
            ["text"] = {
                ["EN"] = {
                    "{target.name}, I'm sorry I wasn't there.",
                },
                ["TL"] = {
                    "{target.name}, patawad at wala ako roon.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.relative.05",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "response",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "{target.name}, I'm sorry I wasn't there.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.relative.05.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_memory_gossip_corpse_ordinary.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["when"] = nil,
    },
}
