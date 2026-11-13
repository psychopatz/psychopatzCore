-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_text_social_identity",
        ["id"] = "text.identity.introduction",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "introduction",
            ["sourceId"] = "text.identity.introduction",
            ["sourcePath"] = "dialogue/core_text_social_identity/identity_introduction.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextSocialIdentity",
        ["namespace"] = "text.identity",
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
                ["sourceCatalog"] = "conversation.social.identity.response",
                ["sourcePath"] = "social/identity/response.json",
                ["textKey"] = "identity.introduction",
                ["textRows"] = {
                    {
                        ["key"] = "identity.introduction",
                        ["text"] = {
                            ["EN"] = "They introduce themselves.",
                            ["TL"] = "Nagpakilala sila.",
                        },
                    },
                },
                ["textTarget"] = "social/identity/response",
            },
            ["text"] = {
                ["EN"] = {
                    "They introduce themselves.",
                },
                ["TL"] = {
                    "Nagpakilala sila.",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "text.identity.introduction",
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
                            ["fallback"] = "They introduce themselves.",
                            ["kind"] = "translation",
                            ["templateID"] = "psdl.text.identity.introduction.response",
                        },
                    },
                },
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_text_social_identity/identity_introduction.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
