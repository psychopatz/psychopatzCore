-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_text_social_greetings",
        ["id"] = "text.response.ambient_visit.accepted.1",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "text.response.ambient_visit.accepted.1",
            ["sourcePath"] = "psdl/dialogue/core_text_social_greetings.json",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CoreTextSocialGreetings/Catalog",
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
                ["sourceCatalog"] = "conversation.social.greetings.ambient_visit.arrival",
                ["sourcePath"] = "social/greetings/ambient_visit/arrival.json",
                ["textKey"] = "response.ambient_visit.accepted.1",
                ["textRows"] = {
                    {
                        ["key"] = "response.ambient_visit.accepted.1",
                        ["text"] = {
                            ["EN"] = "Thank you. I could use somewhere safe to rest for a while.",
                            ["TL"] = "Salamat. Kailangan ko muna ng ligtas na lugar para makapagpahinga.",
                        },
                    },
                },
                ["textTarget"] = "social/greetings/ambient_visit/arrival",
            },
            ["text"] = {
                ["EN"] = {
                    "Thank you. I could use somewhere safe to rest for a while.",
                },
                ["TL"] = {
                    "Salamat. Kailangan ko muna ng ligtas na lugar para makapagpahinga.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.response.ambient_visit.accepted.1",
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
                            ["fallback"] = "Thank you. I could use somewhere safe to rest for a while.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.response.ambient_visit.accepted.1.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_text_social_greetings.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
