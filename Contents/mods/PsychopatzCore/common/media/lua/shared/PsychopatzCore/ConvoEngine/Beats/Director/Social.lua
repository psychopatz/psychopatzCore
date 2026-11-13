-- Generated; do not edit by hand.
return {
    {
        ["baseRelevance"] = 0.7,
        ["candidates"] = {
            {
                ["behavior"] = "behavior.warn",
                ["relevance"] = 0.65,
            },
            {
                ["behavior"] = "behavior.retaliate_verbally",
                ["relevance"] = 0.55,
            },
            {
                ["behavior"] = "behavior.deescalate",
                ["relevance"] = 0.35,
            },
            {
                ["behavior"] = "behavior.end_conversation",
                ["relevance"] = 0.2,
            },
        },
        ["cooldownTurns"] = 3,
        ["domain"] = "social",
        ["entry"] = {
            ["op"] = "in",
            ["path"] = "stimulus.semantic.speechAct",
            ["values"] = {
                "INSULT",
                "HOSTILE_REMARK",
                "THREATEN",
            },
        },
        ["exit"] = {
            ["any"] = {
                {
                    ["op"] = "eq",
                    ["path"] = "stimulus.semantic.intent",
                    ["value"] = "APOLOGIZE",
                },
                {
                    ["op"] = "truthy",
                    ["path"] = "scene.ended",
                },
                {
                    ["op"] = "gte",
                    ["path"] = "beat.turnsInBeat",
                    ["value"] = 6,
                },
                {
                    ["op"] = "truthy",
                    ["path"] = "world.immediateDanger",
                },
            },
        },
        ["group"] = "beat_group.social_primary",
        ["id"] = "beat.argument_escalation",
        ["maintain"] = {
            ["op"] = "gt",
            ["path"] = "history.hostilityCount",
            ["value"] = 0,
        },
        ["maxTurns"] = 6,
        ["owner"] = "PsychopatzCore",
        ["stimuli"] = {
            "HUMAN_UTTERANCE",
            "NPC_SEMANTIC_ACT",
        },
        ["version"] = 1,
    },
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
        ["version"] = 1,
    },
}
