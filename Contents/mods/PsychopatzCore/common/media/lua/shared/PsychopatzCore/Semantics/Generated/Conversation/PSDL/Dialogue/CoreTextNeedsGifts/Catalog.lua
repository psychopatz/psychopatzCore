-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_text_needs_gifts",
        ["id"] = "text.gift.preference.dislike",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "text.gift.preference.dislike",
            ["sourcePath"] = "psdl/dialogue/core_text_needs_gifts.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CoreTextNeedsGifts/Catalog",
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
                ["sourceCatalog"] = "conversation.needs.gifts.preference",
                ["sourcePath"] = "needs/gifts/preference.json",
                ["textKey"] = "gift.preference.dislike",
                ["textRows"] = {
                    {
                        ["key"] = "gift.preference.dislike",
                        ["text"] = {
                            ["EN"] = "I don't like that.",
                            ["TL"] = "Ayaw ko niyan.",
                        },
                    },
                },
                ["textTarget"] = "needs/gifts/preference",
            },
            ["text"] = {
                ["EN"] = {
                    "I don't like that.",
                },
                ["TL"] = {
                    "Ayaw ko niyan.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.gift.preference.dislike",
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
                            ["fallback"] = "I don't like that.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.gift.preference.dislike.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_needs_gifts.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_needs_gifts",
        ["id"] = "text.gift.preference.like",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "text.gift.preference.like",
            ["sourcePath"] = "psdl/dialogue/core_text_needs_gifts.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CoreTextNeedsGifts/Catalog",
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
                ["sourceCatalog"] = "conversation.needs.gifts.preference",
                ["sourcePath"] = "needs/gifts/preference.json",
                ["textKey"] = "gift.preference.like",
                ["textRows"] = {
                    {
                        ["key"] = "gift.preference.like",
                        ["text"] = {
                            ["EN"] = "I like that.",
                            ["TL"] = "Gusto ko iyan.",
                        },
                    },
                },
                ["textTarget"] = "needs/gifts/preference",
            },
            ["text"] = {
                ["EN"] = {
                    "I like that.",
                },
                ["TL"] = {
                    "Gusto ko iyan.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.gift.preference.like",
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
                            ["fallback"] = "I like that.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.gift.preference.like.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_needs_gifts.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_needs_gifts",
        ["id"] = "text.gift.preference.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "text.gift.preference.neutral",
            ["sourcePath"] = "psdl/dialogue/core_text_needs_gifts.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CoreTextNeedsGifts/Catalog",
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
                ["sourceCatalog"] = "conversation.needs.gifts.preference",
                ["sourcePath"] = "needs/gifts/preference.json",
                ["textKey"] = "gift.preference.neutral",
                ["textRows"] = {
                    {
                        ["key"] = "gift.preference.neutral",
                        ["text"] = {
                            ["EN"] = "I don't have a strong preference.",
                            ["TL"] = "Wala akong matinding kagustuhan tungkol diyan.",
                        },
                    },
                },
                ["textTarget"] = "needs/gifts/preference",
            },
            ["text"] = {
                ["EN"] = {
                    "I don't have a strong preference.",
                },
                ["TL"] = {
                    "Wala akong matinding kagustuhan tungkol diyan.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.gift.preference.neutral",
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
                            ["fallback"] = "I don't have a strong preference.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.gift.preference.neutral.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_needs_gifts.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_needs_gifts",
        ["id"] = "text.gift.preference.unknown",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "text.gift.preference.unknown",
            ["sourcePath"] = "psdl/dialogue/core_text_needs_gifts.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CoreTextNeedsGifts/Catalog",
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
                ["sourceCatalog"] = "conversation.needs.gifts.preference",
                ["sourcePath"] = "needs/gifts/preference.json",
                ["textKey"] = "gift.preference.unknown",
                ["textRows"] = {
                    {
                        ["key"] = "gift.preference.unknown",
                        ["text"] = {
                            ["EN"] = "I'm not sure which item you mean.",
                            ["TL"] = "Hindi ko alam kung anong gamit ang tinutukoy mo.",
                        },
                    },
                },
                ["textTarget"] = "needs/gifts/preference",
            },
            ["text"] = {
                ["EN"] = {
                    "I'm not sure which item you mean.",
                },
                ["TL"] = {
                    "Hindi ko alam kung anong gamit ang tinutukoy mo.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.gift.preference.unknown",
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
                            ["fallback"] = "I'm not sure which item you mean.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.gift.preference.unknown.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_needs_gifts.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
