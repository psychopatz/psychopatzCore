-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_text_memory_gossip_corpse_revenge",
        ["id"] = "text.corpse.revenge.comrade.01",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.revenge.comrade.01",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_comrade.json#records[0]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__21ee73f7",
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
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.revenge.comrade",
                ["sourcePath"] = "memory/gossip/corpse/revenge/comrade.json",
                ["textKey"] = "corpse.revenge.comrade.01",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.revenge.comrade.01",
                        ["text"] = {
                            ["EN"] = "Damn {slot.killer.name}. {target.name} stood with {slot.faction.name}; we will answer for this.",
                            ["TL"] = "Putang ina, {slot.killer.name}. Kasama ni {target.name} ang {slot.faction.name}; gaganti kami.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "Damn {slot.killer.name}. {target.name} stood with {slot.faction.name}; we will answer for this.",
                },
                ["TL"] = {
                    "Putang ina, {slot.killer.name}. Kasama ni {target.name} ang {slot.faction.name}; gaganti kami.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.revenge.comrade.01",
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
                            ["fallback"] = "Damn {slot.killer.name}. {target.name} stood with {slot.faction.name}; we will answer for this.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.revenge.comrade.01.response",
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
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_revenge",
        ["id"] = "text.corpse.revenge.comrade.02",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.revenge.comrade.02",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_comrade.json#records[1]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__21ee73f7",
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
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.revenge.comrade",
                ["sourcePath"] = "memory/gossip/corpse/revenge/comrade.json",
                ["textKey"] = "corpse.revenge.comrade.02",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.revenge.comrade.02",
                        ["text"] = {
                            ["EN"] = "One of ours is down, {target.name}. {slot.killer.name} made enemies of all of us.",
                            ["TL"] = "Nawalan kami ng kasama, {target.name}. Ginawang kaaway ni {slot.killer.name} ang lahat sa amin.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "One of ours is down, {target.name}. {slot.killer.name} made enemies of all of us.",
                },
                ["TL"] = {
                    "Nawalan kami ng kasama, {target.name}. Ginawang kaaway ni {slot.killer.name} ang lahat sa amin.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.revenge.comrade.02",
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
                            ["fallback"] = "One of ours is down, {target.name}. {slot.killer.name} made enemies of all of us.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.revenge.comrade.02.response",
                        },
                    },
                },
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
        ["sourceShard"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_comrade.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_revenge",
        ["id"] = "text.corpse.revenge.comrade.03",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.revenge.comrade.03",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_comrade.json#records[2]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__21ee73f7",
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
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.revenge.comrade",
                ["sourcePath"] = "memory/gossip/corpse/revenge/comrade.json",
                ["textKey"] = "corpse.revenge.comrade.03",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.revenge.comrade.03",
                        ["text"] = {
                            ["EN"] = "We saw {slot.killer.name} take {target.name}. This is not finished.",
                            ["TL"] = "Nakita naming pinatay ni {slot.killer.name} si {target.name}. Hindi pa tapos ito.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "We saw {slot.killer.name} take {target.name}. This is not finished.",
                },
                ["TL"] = {
                    "Nakita naming pinatay ni {slot.killer.name} si {target.name}. Hindi pa tapos ito.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.revenge.comrade.03",
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
                            ["fallback"] = "We saw {slot.killer.name} take {target.name}. This is not finished.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.revenge.comrade.03.response",
                        },
                    },
                },
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
        ["sourceShard"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_comrade.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_revenge",
        ["id"] = "text.corpse.revenge.comrade.04",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.revenge.comrade.04",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_comrade.json#records[3]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__21ee73f7",
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
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.revenge.comrade",
                ["sourcePath"] = "memory/gossip/corpse/revenge/comrade.json",
                ["textKey"] = "corpse.revenge.comrade.04",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.revenge.comrade.04",
                        ["text"] = {
                            ["EN"] = "{slot.killer.name} killed a member of {slot.faction.name}. We will remember.",
                            ["TL"] = "Pinatay ni {slot.killer.name} ang kasapi ng {slot.faction.name}. Tatandaan namin ito.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "{slot.killer.name} killed a member of {slot.faction.name}. We will remember.",
                },
                ["TL"] = {
                    "Pinatay ni {slot.killer.name} ang kasapi ng {slot.faction.name}. Tatandaan namin ito.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.revenge.comrade.04",
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
                            ["fallback"] = "{slot.killer.name} killed a member of {slot.faction.name}. We will remember.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.revenge.comrade.04.response",
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
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_revenge",
        ["id"] = "text.corpse.revenge.comrade.05",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.revenge.comrade.05",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_comrade.json#records[4]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__21ee73f7",
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
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.revenge.comrade",
                ["sourcePath"] = "memory/gossip/corpse/revenge/comrade.json",
                ["textKey"] = "corpse.revenge.comrade.05",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.revenge.comrade.05",
                        ["text"] = {
                            ["EN"] = "Run while you can, {slot.killer.name}. We will not forget what happened to {target.name}.",
                            ["TL"] = "Tumakbo ka habang may oras pa, {slot.killer.name}. Hindi namin kalilimutan ang nangyari kay {target.name}.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "Run while you can, {slot.killer.name}. We will not forget what happened to {target.name}.",
                },
                ["TL"] = {
                    "Tumakbo ka habang may oras pa, {slot.killer.name}. Hindi namin kalilimutan ang nangyari kay {target.name}.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.revenge.comrade.05",
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
                            ["fallback"] = "Run while you can, {slot.killer.name}. We will not forget what happened to {target.name}.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.revenge.comrade.05.response",
                        },
                    },
                },
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
        ["sourceShard"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_comrade.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_revenge",
        ["id"] = "text.corpse.revenge.comrade.06",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.revenge.comrade.06",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_comrade.json#records[5]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__21ee73f7",
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
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.revenge.comrade",
                ["sourcePath"] = "memory/gossip/corpse/revenge/comrade.json",
                ["textKey"] = "corpse.revenge.comrade.06",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.revenge.comrade.06",
                        ["text"] = {
                            ["EN"] = "Hell, {target.name}. {slot.killer.name} will pay for making us weaker.",
                            ["TL"] = "Lintik, {target.name}. Magbabayad si {slot.killer.name} dahil pinahina niya kami.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "Hell, {target.name}. {slot.killer.name} will pay for making us weaker.",
                },
                ["TL"] = {
                    "Lintik, {target.name}. Magbabayad si {slot.killer.name} dahil pinahina niya kami.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.revenge.comrade.06",
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
                            ["fallback"] = "Hell, {target.name}. {slot.killer.name} will pay for making us weaker.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.revenge.comrade.06.response",
                        },
                    },
                },
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
        ["sourceShard"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_comrade.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_revenge",
        ["id"] = "text.corpse.revenge.comrade.07",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.revenge.comrade.07",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_comrade.json#records[6]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__21ee73f7",
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
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.revenge.comrade",
                ["sourcePath"] = "memory/gossip/corpse/revenge/comrade.json",
                ["textKey"] = "corpse.revenge.comrade.07",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.revenge.comrade.07",
                        ["text"] = {
                            ["EN"] = "{slot.faction.name} lost one today. {slot.killer.name} started something they cannot finish.",
                            ["TL"] = "May nawala sa {slot.faction.name} ngayon. Sinimulan ito ni {slot.killer.name} at hindi niya matatapos.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "{slot.faction.name} lost one today. {slot.killer.name} started something they cannot finish.",
                },
                ["TL"] = {
                    "May nawala sa {slot.faction.name} ngayon. Sinimulan ito ni {slot.killer.name} at hindi niya matatapos.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.revenge.comrade.07",
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
                            ["fallback"] = "{slot.faction.name} lost one today. {slot.killer.name} started something they cannot finish.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.revenge.comrade.07.response",
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
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_revenge",
        ["id"] = "text.corpse.revenge.comrade.08",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.revenge.comrade.08",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_comrade.json#records[7]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__21ee73f7",
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
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.revenge.comrade",
                ["sourcePath"] = "memory/gossip/corpse/revenge/comrade.json",
                ["textKey"] = "corpse.revenge.comrade.08",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.revenge.comrade.08",
                        ["text"] = {
                            ["EN"] = "We do not forget our own, {target.name}. {slot.killer.name} will answer for this.",
                            ["TL"] = "Hindi namin kinakalimutan ang mga kasama namin, {target.name}. Mananagot si {slot.killer.name}.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "We do not forget our own, {target.name}. {slot.killer.name} will answer for this.",
                },
                ["TL"] = {
                    "Hindi namin kinakalimutan ang mga kasama namin, {target.name}. Mananagot si {slot.killer.name}.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.revenge.comrade.08",
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
                            ["fallback"] = "We do not forget our own, {target.name}. {slot.killer.name} will answer for this.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.revenge.comrade.08.response",
                        },
                    },
                },
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
        ["sourceShard"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_comrade.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = true,
            ["type"] = "entity.person",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_revenge",
        ["id"] = "text.corpse.revenge.friend.01",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.revenge.friend.01",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_friend.json#records[0]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__21ee73f7",
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
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.revenge.friend",
                ["sourcePath"] = "memory/gossip/corpse/revenge/friend.json",
                ["textKey"] = "corpse.revenge.friend.01",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.revenge.friend.01",
                        ["text"] = {
                            ["EN"] = "Damn {slot.killer.name}. {target.name} was my friend, and this will cost you.",
                            ["TL"] = "Bwisit ka, {slot.killer.name}. Kaibigan ko si {target.name}; pagbabayaran mo ito.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "Damn {slot.killer.name}. {target.name} was my friend, and this will cost you.",
                },
                ["TL"] = {
                    "Bwisit ka, {slot.killer.name}. Kaibigan ko si {target.name}; pagbabayaran mo ito.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.revenge.friend.01",
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
                            ["fallback"] = "Damn {slot.killer.name}. {target.name} was my friend, and this will cost you.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.revenge.friend.01.response",
                        },
                    },
                },
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
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_revenge",
        ["id"] = "text.corpse.revenge.friend.02",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.revenge.friend.02",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_friend.json#records[1]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__21ee73f7",
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
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.revenge.friend",
                ["sourcePath"] = "memory/gossip/corpse/revenge/friend.json",
                ["textKey"] = "corpse.revenge.friend.02",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.revenge.friend.02",
                        ["text"] = {
                            ["EN"] = "I saw {target.name} fall. {slot.killer.name} will answer for it.",
                            ["TL"] = "Nakita kong bumagsak si {target.name}. Mananagot si {slot.killer.name}.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "I saw {target.name} fall. {slot.killer.name} will answer for it.",
                },
                ["TL"] = {
                    "Nakita kong bumagsak si {target.name}. Mananagot si {slot.killer.name}.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.revenge.friend.02",
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
                            ["fallback"] = "I saw {target.name} fall. {slot.killer.name} will answer for it.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.revenge.friend.02.response",
                        },
                    },
                },
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
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_revenge",
        ["id"] = "text.corpse.revenge.friend.03",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.revenge.friend.03",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_friend.json#records[2]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__21ee73f7",
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
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.revenge.friend",
                ["sourcePath"] = "memory/gossip/corpse/revenge/friend.json",
                ["textKey"] = "corpse.revenge.friend.03",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.revenge.friend.03",
                        ["text"] = {
                            ["EN"] = "Hell, {target.name}. What {slot.killer.name} did will not be forgotten.",
                            ["TL"] = "Lintik, {target.name}. Hindi malilimutan ang ginawa ni {slot.killer.name}.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "Hell, {target.name}. What {slot.killer.name} did will not be forgotten.",
                },
                ["TL"] = {
                    "Lintik, {target.name}. Hindi malilimutan ang ginawa ni {slot.killer.name}.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.revenge.friend.03",
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
                            ["fallback"] = "Hell, {target.name}. What {slot.killer.name} did will not be forgotten.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.revenge.friend.03.response",
                        },
                    },
                },
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
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_revenge",
        ["id"] = "text.corpse.revenge.friend.04",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.revenge.friend.04",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_friend.json#records[3]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__21ee73f7",
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
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.revenge.friend",
                ["sourcePath"] = "memory/gossip/corpse/revenge/friend.json",
                ["textKey"] = "corpse.revenge.friend.04",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.revenge.friend.04",
                        ["text"] = {
                            ["EN"] = "I will not let {target.name} be forgotten, and {slot.killer.name} will not get away with it.",
                            ["TL"] = "Hindi ko hahayaang makalimutan si {target.name}, at hindi makakatakas si {slot.killer.name}.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "I will not let {target.name} be forgotten, and {slot.killer.name} will not get away with it.",
                },
                ["TL"] = {
                    "Hindi ko hahayaang makalimutan si {target.name}, at hindi makakatakas si {slot.killer.name}.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.revenge.friend.04",
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
                            ["fallback"] = "I will not let {target.name} be forgotten, and {slot.killer.name} will not get away with it.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.revenge.friend.04.response",
                        },
                    },
                },
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
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_revenge",
        ["id"] = "text.corpse.revenge.friend.05",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.revenge.friend.05",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_friend.json#records[4]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__21ee73f7",
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
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.revenge.friend",
                ["sourcePath"] = "memory/gossip/corpse/revenge/friend.json",
                ["textKey"] = "corpse.revenge.friend.05",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.revenge.friend.05",
                        ["text"] = {
                            ["EN"] = "{target.name} always had my back. Today, I am coming for {slot.killer.name}.",
                            ["TL"] = "Lagi akong ipinagtatanggol ni {target.name}. Ngayon, ako naman ang hahabol kay {slot.killer.name}.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "{target.name} always had my back. Today, I am coming for {slot.killer.name}.",
                },
                ["TL"] = {
                    "Lagi akong ipinagtatanggol ni {target.name}. Ngayon, ako naman ang hahabol kay {slot.killer.name}.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.revenge.friend.05",
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
                            ["fallback"] = "{target.name} always had my back. Today, I am coming for {slot.killer.name}.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.revenge.friend.05.response",
                        },
                    },
                },
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
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_revenge",
        ["id"] = "text.corpse.revenge.friend.06",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.revenge.friend.06",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_friend.json#records[5]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__21ee73f7",
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
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.revenge.friend",
                ["sourcePath"] = "memory/gossip/corpse/revenge/friend.json",
                ["textKey"] = "corpse.revenge.friend.06",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.revenge.friend.06",
                        ["text"] = {
                            ["EN"] = "Damn {slot.killer.name}. {target.name} mattered to us.",
                            ["TL"] = "Putang ina, {slot.killer.name}. Mahalaga sa amin si {target.name}.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "Damn {slot.killer.name}. {target.name} mattered to us.",
                },
                ["TL"] = {
                    "Putang ina, {slot.killer.name}. Mahalaga sa amin si {target.name}.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.revenge.friend.06",
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
                            ["fallback"] = "Damn {slot.killer.name}. {target.name} mattered to us.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.revenge.friend.06.response",
                        },
                    },
                },
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
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_revenge",
        ["id"] = "text.corpse.revenge.friend.07",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.revenge.friend.07",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_friend.json#records[6]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__21ee73f7",
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
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.revenge.friend",
                ["sourcePath"] = "memory/gossip/corpse/revenge/friend.json",
                ["textKey"] = "corpse.revenge.friend.07",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.revenge.friend.07",
                        ["text"] = {
                            ["EN"] = "I hope {slot.killer.name} knows what they took from us when they killed {target.name}.",
                            ["TL"] = "Sana alam ni {slot.killer.name} ang inagaw niya sa amin nang pinatay niya si {target.name}.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "I hope {slot.killer.name} knows what they took from us when they killed {target.name}.",
                },
                ["TL"] = {
                    "Sana alam ni {slot.killer.name} ang inagaw niya sa amin nang pinatay niya si {target.name}.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.revenge.friend.07",
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
                            ["fallback"] = "I hope {slot.killer.name} knows what they took from us when they killed {target.name}.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.revenge.friend.07.response",
                        },
                    },
                },
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
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_revenge",
        ["id"] = "text.corpse.revenge.friend.08",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.revenge.friend.08",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_friend.json#records[7]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__21ee73f7",
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
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.revenge.friend",
                ["sourcePath"] = "memory/gossip/corpse/revenge/friend.json",
                ["textKey"] = "corpse.revenge.friend.08",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.revenge.friend.08",
                        ["text"] = {
                            ["EN"] = "No more warnings. {slot.killer.name} killed one of ours, {target.name}.",
                            ["TL"] = "Wala nang babala. Pinatay ni {slot.killer.name} ang isa sa amin, si {target.name}.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "No more warnings. {slot.killer.name} killed one of ours, {target.name}.",
                },
                ["TL"] = {
                    "Wala nang babala. Pinatay ni {slot.killer.name} ang isa sa amin, si {target.name}.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.revenge.friend.08",
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
                            ["fallback"] = "No more warnings. {slot.killer.name} killed one of ours, {target.name}.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.revenge.friend.08.response",
                        },
                    },
                },
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
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_revenge",
        ["id"] = "text.corpse.revenge.relative.01",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.revenge.relative.01",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_relative.json#records[0]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__21ee73f7",
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
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.revenge.relative",
                ["sourcePath"] = "memory/gossip/corpse/revenge/relative.json",
                ["textKey"] = "corpse.revenge.relative.01",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.revenge.relative.01",
                        ["text"] = {
                            ["EN"] = "Damn it, {slot.killer.name}. You took {target.name} from their family. This will not go unanswered.",
                            ["TL"] = "Putang ina, {slot.killer.name}. Inagaw mo si {target.name} sa pamilya niya. Hindi ito palalampasin.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "Damn it, {slot.killer.name}. You took {target.name} from their family. This will not go unanswered.",
                },
                ["TL"] = {
                    "Putang ina, {slot.killer.name}. Inagaw mo si {target.name} sa pamilya niya. Hindi ito palalampasin.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.revenge.relative.01",
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
                            ["fallback"] = "Damn it, {slot.killer.name}. You took {target.name} from their family. This will not go unanswered.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.revenge.relative.01.response",
                        },
                    },
                },
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
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_revenge",
        ["id"] = "text.corpse.revenge.relative.02",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.revenge.relative.02",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_relative.json#records[1]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__21ee73f7",
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
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.revenge.relative",
                ["sourcePath"] = "memory/gossip/corpse/revenge/relative.json",
                ["textKey"] = "corpse.revenge.relative.02",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.revenge.relative.02",
                        ["text"] = {
                            ["EN"] = "I saw {target.name} fall. {slot.killer.name} will answer for this, I swear it.",
                            ["TL"] = "Nakita kong bumagsak si {target.name}. Mananagot si {slot.killer.name} sa ginawa niya, isinusumpa ko.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "I saw {target.name} fall. {slot.killer.name} will answer for this, I swear it.",
                },
                ["TL"] = {
                    "Nakita kong bumagsak si {target.name}. Mananagot si {slot.killer.name} sa ginawa niya, isinusumpa ko.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.revenge.relative.02",
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
                            ["fallback"] = "I saw {target.name} fall. {slot.killer.name} will answer for this, I swear it.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.revenge.relative.02.response",
                        },
                    },
                },
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
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_revenge",
        ["id"] = "text.corpse.revenge.relative.03",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.revenge.relative.03",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_relative.json#records[2]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__21ee73f7",
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
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.revenge.relative",
                ["sourcePath"] = "memory/gossip/corpse/revenge/relative.json",
                ["textKey"] = "corpse.revenge.relative.03",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.revenge.relative.03",
                        ["text"] = {
                            ["EN"] = "What {slot.killer.name} did to {target.name} will never be forgiven.",
                            ["TL"] = "Hindi ko mapapatawad ang ginawa ni {slot.killer.name} kay {target.name}.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "What {slot.killer.name} did to {target.name} will never be forgiven.",
                },
                ["TL"] = {
                    "Hindi ko mapapatawad ang ginawa ni {slot.killer.name} kay {target.name}.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.revenge.relative.03",
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
                            ["fallback"] = "What {slot.killer.name} did to {target.name} will never be forgiven.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.revenge.relative.03.response",
                        },
                    },
                },
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
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_revenge",
        ["id"] = "text.corpse.revenge.relative.04",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.revenge.relative.04",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_relative.json#records[3]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__21ee73f7",
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
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.revenge.relative",
                ["sourcePath"] = "memory/gossip/corpse/revenge/relative.json",
                ["textKey"] = "corpse.revenge.relative.04",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.revenge.relative.04",
                        ["text"] = {
                            ["EN"] = "Hell, {target.name}. {slot.killer.name} is going to pay for this.",
                            ["TL"] = "Lintik, {target.name}. Magbabayad si {slot.killer.name} sa ginawa niya.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "Hell, {target.name}. {slot.killer.name} is going to pay for this.",
                },
                ["TL"] = {
                    "Lintik, {target.name}. Magbabayad si {slot.killer.name} sa ginawa niya.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.revenge.relative.04",
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
                            ["fallback"] = "Hell, {target.name}. {slot.killer.name} is going to pay for this.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.revenge.relative.04.response",
                        },
                    },
                },
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
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_revenge",
        ["id"] = "text.corpse.revenge.relative.05",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.revenge.relative.05",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_relative.json#records[4]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__21ee73f7",
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
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.revenge.relative",
                ["sourcePath"] = "memory/gossip/corpse/revenge/relative.json",
                ["textKey"] = "corpse.revenge.relative.05",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.revenge.relative.05",
                        ["text"] = {
                            ["EN"] = "I will not let {target.name}'s death go unanswered. {slot.killer.name} started this.",
                            ["TL"] = "Hindi ko hahayaang walang hustisya ang pagkamatay ni {target.name}. Sinimulan ito ni {slot.killer.name}.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "I will not let {target.name}'s death go unanswered. {slot.killer.name} started this.",
                },
                ["TL"] = {
                    "Hindi ko hahayaang walang hustisya ang pagkamatay ni {target.name}. Sinimulan ito ni {slot.killer.name}.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.revenge.relative.05",
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
                            ["fallback"] = "I will not let {target.name}'s death go unanswered. {slot.killer.name} started this.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.revenge.relative.05.response",
                        },
                    },
                },
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
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_revenge",
        ["id"] = "text.corpse.revenge.relative.06",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.revenge.relative.06",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_relative.json#records[5]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__21ee73f7",
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
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.revenge.relative",
                ["sourcePath"] = "memory/gossip/corpse/revenge/relative.json",
                ["textKey"] = "corpse.revenge.relative.06",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.revenge.relative.06",
                        ["text"] = {
                            ["EN"] = "No. Not {target.name}. {slot.killer.name} just made this personal.",
                            ["TL"] = "Hindi. Hindi si {target.name}. Ginawa itong personal ni {slot.killer.name}.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "No. Not {target.name}. {slot.killer.name} just made this personal.",
                },
                ["TL"] = {
                    "Hindi. Hindi si {target.name}. Ginawa itong personal ni {slot.killer.name}.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.revenge.relative.06",
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
                            ["fallback"] = "No. Not {target.name}. {slot.killer.name} just made this personal.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.revenge.relative.06.response",
                        },
                    },
                },
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
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_revenge",
        ["id"] = "text.corpse.revenge.relative.07",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.revenge.relative.07",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_relative.json#records[6]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__21ee73f7",
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
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.revenge.relative",
                ["sourcePath"] = "memory/gossip/corpse/revenge/relative.json",
                ["textKey"] = "corpse.revenge.relative.07",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.revenge.relative.07",
                        ["text"] = {
                            ["EN"] = "{target.name} was family. {slot.killer.name} will regret this.",
                            ["TL"] = "Pamilya si {target.name}. Pagsisisihan ito ni {slot.killer.name}.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "{target.name} was family. {slot.killer.name} will regret this.",
                },
                ["TL"] = {
                    "Pamilya si {target.name}. Pagsisisihan ito ni {slot.killer.name}.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.revenge.relative.07",
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
                            ["fallback"] = "{target.name} was family. {slot.killer.name} will regret this.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.revenge.relative.07.response",
                        },
                    },
                },
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
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_memory_gossip_corpse_revenge",
        ["id"] = "text.corpse.revenge.relative.08",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "text.corpse.revenge.relative.08",
            ["sourcePath"] = "dialogue/core_text_memory_gossip_corpse_revenge/corpse_revenge_relative.json#records[7]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextMemoryGossipCo__21ee73f7",
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
                ["sourceCatalog"] = "conversation.memory.gossip.corpse.revenge.relative",
                ["sourcePath"] = "memory/gossip/corpse/revenge/relative.json",
                ["textKey"] = "corpse.revenge.relative.08",
                ["textRows"] = {
                    {
                        ["key"] = "corpse.revenge.relative.08",
                        ["text"] = {
                            ["EN"] = "Rest now, {target.name}. I hope {slot.killer.name} runs, because I am coming.",
                            ["TL"] = "Magpahinga ka muna, {target.name}. Sana tumakbo si {slot.killer.name}, dahil hahabulin ko siya.",
                        },
                    },
                },
                ["textTarget"] = "memory/gossip",
            },
            ["text"] = {
                ["EN"] = {
                    "Rest now, {target.name}. I hope {slot.killer.name} runs, because I am coming.",
                },
                ["TL"] = {
                    "Magpahinga ka muna, {target.name}. Sana tumakbo si {slot.killer.name}, dahil hahabulin ko siya.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.corpse.revenge.relative.08",
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
                            ["fallback"] = "Rest now, {target.name}. I hope {slot.killer.name} runs, because I am coming.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.corpse.revenge.relative.08.response",
                        },
                    },
                },
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
        ["when"] = nil,
    },
}
