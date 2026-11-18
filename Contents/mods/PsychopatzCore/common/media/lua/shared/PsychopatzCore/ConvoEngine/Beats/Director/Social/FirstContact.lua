-- Generated; do not edit by hand.
return {
    {
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
        ["domain"] = "social",
        ["domainPath"] = "social/first_contact",
        ["domains"] = {
            {
                ["domain"] = "social",
                ["owner"] = "PsychopatzCore",
            },
        },
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
        ["id"] = "beat.suspicious_first_contact",
        ["maintain"] = {
            ["op"] = "falsy",
            ["path"] = "scene.ended",
        },
        ["maxTurns"] = 3,
        ["owner"] = "PsychopatzCore",
        ["stimuli"] = {
            "HUMAN_UTTERANCE",
            "NPC_SEMANTIC_ACT",
        },
        ["topics"] = {
            {
                ["domain"] = "social",
                ["id"] = "first_contact",
            },
        },
        ["version"] = 1,
    },
}
