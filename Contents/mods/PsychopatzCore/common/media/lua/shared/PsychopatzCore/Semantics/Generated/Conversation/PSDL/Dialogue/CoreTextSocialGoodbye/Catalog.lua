-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_text_social_goodbye",
        ["id"] = "text.choice.goodbye",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "text.choice.goodbye",
            ["sourcePath"] = "psdl/dialogue/core_text_social_goodbye.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CoreTextSocialGoodbye/Catalog",
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
                ["sourceCatalog"] = "conversation.social.goodbye.closing",
                ["sourcePath"] = "social/goodbye/closing.json",
                ["textKey"] = "choice.goodbye",
                ["textRows"] = {
                    {
                        ["key"] = "choice.goodbye",
                        ["text"] = {
                            ["EN"] = "That's all. Stay safe.",
                            ["TL"] = "Iyon lang. Manatiling ligtas.",
                        },
                    },
                },
                ["textTarget"] = "social/goodbye/closing",
            },
            ["text"] = {
                ["EN"] = {
                    "That's all. Stay safe.",
                },
                ["TL"] = {
                    "Iyon lang. Manatiling ligtas.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.choice.goodbye",
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
                            ["fallback"] = "That's all. Stay safe.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.choice.goodbye.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_social_goodbye.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_goodbye",
        ["id"] = "text.response.goodbye",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "text.response.goodbye",
            ["sourcePath"] = "psdl/dialogue/core_text_social_goodbye.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CoreTextSocialGoodbye/Catalog",
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
                ["sourceCatalog"] = "conversation.social.goodbye.closing",
                ["sourcePath"] = "social/goodbye/closing.json",
                ["textKey"] = "response.goodbye",
                ["textRows"] = {
                    {
                        ["key"] = "response.goodbye",
                        ["text"] = {
                            ["EN"] = "You too.",
                            ["TL"] = "Ikaw rin.",
                        },
                    },
                },
                ["textTarget"] = "social/goodbye/closing",
            },
            ["text"] = {
                ["EN"] = {
                    "You too.",
                },
                ["TL"] = {
                    "Ikaw rin.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.response.goodbye",
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
                            ["fallback"] = "You too.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.response.goodbye.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_social_goodbye.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_goodbye",
        ["id"] = "text.response.goodbye.1",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "text.response.goodbye.1",
            ["sourcePath"] = "psdl/dialogue/core_text_social_goodbye.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CoreTextSocialGoodbye/Catalog",
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
                ["sourceCatalog"] = "conversation.social.goodbye.closing",
                ["sourcePath"] = "social/goodbye/closing.json",
                ["textKey"] = "response.goodbye.1",
                ["textRows"] = {
                    {
                        ["key"] = "response.goodbye.1",
                        ["text"] = {
                            ["EN"] = "You too.",
                            ["TL"] = "Ikaw rin.",
                        },
                    },
                },
                ["textTarget"] = "social/goodbye/closing",
            },
            ["text"] = {
                ["EN"] = {
                    "You too.",
                },
                ["TL"] = {
                    "Ikaw rin.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.response.goodbye.1",
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
                            ["fallback"] = "You too.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.response.goodbye.1.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_social_goodbye.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_goodbye",
        ["id"] = "text.response.goodbye.10",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "text.response.goodbye.10",
            ["sourcePath"] = "psdl/dialogue/core_text_social_goodbye.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CoreTextSocialGoodbye/Catalog",
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
                ["sourceCatalog"] = "conversation.social.goodbye.closing",
                ["sourcePath"] = "social/goodbye/closing.json",
                ["textKey"] = "response.goodbye.10",
                ["textRows"] = {
                    {
                        ["key"] = "response.goodbye.10",
                        ["text"] = {
                            ["EN"] = "Be careful on the roads.",
                            ["TL"] = "Maging maingat ka palagi sa labas.",
                        },
                    },
                },
                ["textTarget"] = "social/goodbye/closing",
            },
            ["text"] = {
                ["EN"] = {
                    "Be careful on the roads.",
                },
                ["TL"] = {
                    "Maging maingat ka palagi sa labas.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.response.goodbye.10",
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
                            ["fallback"] = "Be careful on the roads.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.response.goodbye.10.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_social_goodbye.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_goodbye",
        ["id"] = "text.response.goodbye.2",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "text.response.goodbye.2",
            ["sourcePath"] = "psdl/dialogue/core_text_social_goodbye.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CoreTextSocialGoodbye/Catalog",
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
                ["sourceCatalog"] = "conversation.social.goodbye.closing",
                ["sourcePath"] = "social/goodbye/closing.json",
                ["textKey"] = "response.goodbye.2",
                ["textRows"] = {
                    {
                        ["key"] = "response.goodbye.2",
                        ["text"] = {
                            ["EN"] = "Watch your back out there.",
                            ["TL"] = "Mag-ingat ka sa labas.",
                        },
                    },
                },
                ["textTarget"] = "social/goodbye/closing",
            },
            ["text"] = {
                ["EN"] = {
                    "Watch your back out there.",
                },
                ["TL"] = {
                    "Mag-ingat ka sa labas.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.response.goodbye.2",
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
                            ["fallback"] = "Watch your back out there.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.response.goodbye.2.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_social_goodbye.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_goodbye",
        ["id"] = "text.response.goodbye.3",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "text.response.goodbye.3",
            ["sourcePath"] = "psdl/dialogue/core_text_social_goodbye.json#records[5]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CoreTextSocialGoodbye/Catalog",
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
                ["sourceCatalog"] = "conversation.social.goodbye.closing",
                ["sourcePath"] = "social/goodbye/closing.json",
                ["textKey"] = "response.goodbye.3",
                ["textRows"] = {
                    {
                        ["key"] = "response.goodbye.3",
                        ["text"] = {
                            ["EN"] = "Take care. See you around.",
                            ["TL"] = "Ingat. Magkikita pa tayo.",
                        },
                    },
                },
                ["textTarget"] = "social/goodbye/closing",
            },
            ["text"] = {
                ["EN"] = {
                    "Take care. See you around.",
                },
                ["TL"] = {
                    "Ingat. Magkikita pa tayo.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.response.goodbye.3",
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
                            ["fallback"] = "Take care. See you around.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.response.goodbye.3.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_social_goodbye.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_goodbye",
        ["id"] = "text.response.goodbye.4",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "text.response.goodbye.4",
            ["sourcePath"] = "psdl/dialogue/core_text_social_goodbye.json#records[6]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CoreTextSocialGoodbye/Catalog",
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
                ["sourceCatalog"] = "conversation.social.goodbye.closing",
                ["sourcePath"] = "social/goodbye/closing.json",
                ["textKey"] = "response.goodbye.4",
                ["textRows"] = {
                    {
                        ["key"] = "response.goodbye.4",
                        ["text"] = {
                            ["EN"] = "Keep your eyes open.",
                            ["TL"] = "Bantayan mo ang likod mo.",
                        },
                    },
                },
                ["textTarget"] = "social/goodbye/closing",
            },
            ["text"] = {
                ["EN"] = {
                    "Keep your eyes open.",
                },
                ["TL"] = {
                    "Bantayan mo ang likod mo.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.response.goodbye.4",
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
                            ["fallback"] = "Keep your eyes open.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.response.goodbye.4.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_social_goodbye.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_goodbye",
        ["id"] = "text.response.goodbye.5",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "text.response.goodbye.5",
            ["sourcePath"] = "psdl/dialogue/core_text_social_goodbye.json#records[7]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CoreTextSocialGoodbye/Catalog",
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
                ["sourceCatalog"] = "conversation.social.goodbye.closing",
                ["sourcePath"] = "social/goodbye/closing.json",
                ["textKey"] = "response.goodbye.5",
                ["textRows"] = {
                    {
                        ["key"] = "response.goodbye.5",
                        ["text"] = {
                            ["EN"] = "Stay safe. Don't take unnecessary risks.",
                            ["TL"] = "Manatiling ligtas. Huwag sumuong sa panganib.",
                        },
                    },
                },
                ["textTarget"] = "social/goodbye/closing",
            },
            ["text"] = {
                ["EN"] = {
                    "Stay safe. Don't take unnecessary risks.",
                },
                ["TL"] = {
                    "Manatiling ligtas. Huwag sumuong sa panganib.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.response.goodbye.5",
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
                            ["fallback"] = "Stay safe. Don't take unnecessary risks.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.response.goodbye.5.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_social_goodbye.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_goodbye",
        ["id"] = "text.response.goodbye.6",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "text.response.goodbye.6",
            ["sourcePath"] = "psdl/dialogue/core_text_social_goodbye.json#records[8]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CoreTextSocialGoodbye/Catalog",
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
                ["sourceCatalog"] = "conversation.social.goodbye.closing",
                ["sourcePath"] = "social/goodbye/closing.json",
                ["textKey"] = "response.goodbye.6",
                ["textRows"] = {
                    {
                        ["key"] = "response.goodbye.6",
                        ["text"] = {
                            ["EN"] = "Until next time. Stay sharp.",
                            ["TL"] = "Hanggang sa muli. Maging alerto.",
                        },
                    },
                },
                ["textTarget"] = "social/goodbye/closing",
            },
            ["text"] = {
                ["EN"] = {
                    "Until next time. Stay sharp.",
                },
                ["TL"] = {
                    "Hanggang sa muli. Maging alerto.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.response.goodbye.6",
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
                            ["fallback"] = "Until next time. Stay sharp.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.response.goodbye.6.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_social_goodbye.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_goodbye",
        ["id"] = "text.response.goodbye.7",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "text.response.goodbye.7",
            ["sourcePath"] = "psdl/dialogue/core_text_social_goodbye.json#records[9]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CoreTextSocialGoodbye/Catalog",
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
                ["sourceCatalog"] = "conversation.social.goodbye.closing",
                ["sourcePath"] = "social/goodbye/closing.json",
                ["textKey"] = "response.goodbye.7",
                ["textRows"] = {
                    {
                        ["key"] = "response.goodbye.7",
                        ["text"] = {
                            ["EN"] = "Yeah. Catch you later.",
                            ["TL"] = "Sige. Magkita na lang tayo mamaya.",
                        },
                    },
                },
                ["textTarget"] = "social/goodbye/closing",
            },
            ["text"] = {
                ["EN"] = {
                    "Yeah. Catch you later.",
                },
                ["TL"] = {
                    "Sige. Magkita na lang tayo mamaya.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.response.goodbye.7",
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
                            ["fallback"] = "Yeah. Catch you later.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.response.goodbye.7.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_social_goodbye.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_goodbye",
        ["id"] = "text.response.goodbye.8",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "text.response.goodbye.8",
            ["sourcePath"] = "psdl/dialogue/core_text_social_goodbye.json#records[10]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CoreTextSocialGoodbye/Catalog",
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
                ["sourceCatalog"] = "conversation.social.goodbye.closing",
                ["sourcePath"] = "social/goodbye/closing.json",
                ["textKey"] = "response.goodbye.8",
                ["textRows"] = {
                    {
                        ["key"] = "response.goodbye.8",
                        ["text"] = {
                            ["EN"] = "Take it easy out there.",
                            ["TL"] = "Dahan-dahan ka lang sa daan.",
                        },
                    },
                },
                ["textTarget"] = "social/goodbye/closing",
            },
            ["text"] = {
                ["EN"] = {
                    "Take it easy out there.",
                },
                ["TL"] = {
                    "Dahan-dahan ka lang sa daan.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.response.goodbye.8",
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
                            ["fallback"] = "Take it easy out there.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.response.goodbye.8.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_social_goodbye.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_goodbye",
        ["id"] = "text.response.goodbye.9",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "text.response.goodbye.9",
            ["sourcePath"] = "psdl/dialogue/core_text_social_goodbye.json#records[11]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CoreTextSocialGoodbye/Catalog",
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
                ["sourceCatalog"] = "conversation.social.goodbye.closing",
                ["sourcePath"] = "social/goodbye/closing.json",
                ["textKey"] = "response.goodbye.9",
                ["textRows"] = {
                    {
                        ["key"] = "response.goodbye.9",
                        ["text"] = {
                            ["EN"] = "See you. Keep your head down.",
                            ["TL"] = "Sige na. Huwag kang papakita sa mga 'yun.",
                        },
                    },
                },
                ["textTarget"] = "social/goodbye/closing",
            },
            ["text"] = {
                ["EN"] = {
                    "See you. Keep your head down.",
                },
                ["TL"] = {
                    "Sige na. Huwag kang papakita sa mga 'yun.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.response.goodbye.9",
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
                            ["fallback"] = "See you. Keep your head down.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.response.goodbye.9.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_social_goodbye.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
