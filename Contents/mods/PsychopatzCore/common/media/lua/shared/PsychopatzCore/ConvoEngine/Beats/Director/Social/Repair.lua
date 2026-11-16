-- Generated; do not edit by hand.
return {
    {
        ["baseRelevance"] = 0.85,
        ["candidates"] = {
            {
                ["behavior"] = "behavior.reconcile",
                ["relevance"] = 0.65,
            },
            {
                ["behavior"] = "behavior.warn",
                ["relevance"] = 0.3,
            },
            {
                ["behavior"] = "behavior.end_conversation",
                ["relevance"] = 0.15,
            },
        },
        ["cooldownTurns"] = 4,
        ["domain"] = "social",
        ["domainPath"] = "social/repair",
        ["entry"] = {
            ["all"] = {
                {
                    ["op"] = "eq",
                    ["path"] = "stimulus.semantic.intent",
                    ["value"] = "APOLOGIZE",
                },
                {
                    ["op"] = "truthy",
                    ["path"] = "pragmatic.contextualAdmission.admitted",
                },
                {
                    ["op"] = "eq",
                    ["path"] = "pragmatic.contextualAdmission.selected.relation",
                    ["value"] = "repair",
                },
            },
        },
        ["exit"] = {
            ["any"] = {
                {
                    ["op"] = "gte",
                    ["path"] = "beat.turnsInBeat",
                    ["value"] = 2,
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
        ["id"] = "beat.reconciliation",
        ["maintain"] = {
            ["op"] = "falsy",
            ["path"] = "scene.ended",
        },
        ["maxTurns"] = 2,
        ["owner"] = "PsychopatzCore",
        ["stimuli"] = {
            "HUMAN_UTTERANCE",
            "NPC_SEMANTIC_ACT",
        },
        ["version"] = 1,
    },
}
