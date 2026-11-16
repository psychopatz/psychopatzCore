-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social",
        ["domainPath"] = "social/first_contact",
        ["id"] = "beat.suspicious_first_contact",
        ["kind"] = "beat",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "suspicious_first_contact",
            ["sourceId"] = "beat.suspicious_first_contact",
            ["sourcePath"] = "beat/social/first_contact/suspicious_first_contact.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Beat/Social/FirstContact",
        ["namespace"] = "beat",
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
            ["baseRelevance"] = 0.55,
            ["candidates"] = {
                {
                    ["behavior"] = "behavior.challenge",
                    ["relevance"] = 0.6,
                },
                {
                    ["behavior"] = "behavior.warn",
                    ["relevance"] = 0.45,
                },
                {
                    ["behavior"] = "behavior.deescalate",
                    ["relevance"] = 0.35,
                },
            },
            ["cooldownTurns"] = 2,
            ["entry"] = {
                ["all"] = {
                    {
                        ["op"] = "truthy",
                        ["path"] = "scene.firstContact",
                    },
                    {
                        ["op"] = "lte",
                        ["path"] = "relationship.familiarity",
                        ["value"] = 0,
                    },
                    {
                        ["op"] = "eq",
                        ["path"] = "stimulus.semantic.intent",
                        ["value"] = "GREET",
                    },
                },
            },
            ["exit"] = {
                ["any"] = {
                    {
                        ["op"] = "gte",
                        ["path"] = "beat.turnsInBeat",
                        ["value"] = 3,
                    },
                    {
                        ["op"] = "truthy",
                        ["path"] = "scene.ended",
                    },
                    {
                        ["op"] = "truthy",
                        ["path"] = "world.immediateDanger",
                    },
                },
            },
            ["group"] = "beat_group.social_primary",
            ["maintain"] = {
                ["op"] = "falsy",
                ["path"] = "scene.ended",
            },
            ["maxTurns"] = 3,
            ["stimuli"] = {
                "HUMAN_UTTERANCE",
                "NPC_SEMANTIC_ACT",
            },
            ["version"] = 1,
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "beat/social/first_contact/suspicious_first_contact.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
