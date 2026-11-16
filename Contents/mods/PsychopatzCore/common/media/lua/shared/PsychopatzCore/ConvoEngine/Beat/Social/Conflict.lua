-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social",
        ["domainPath"] = "social/conflict",
        ["id"] = "beat.argument_escalation",
        ["kind"] = "beat",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "argument_escalation",
            ["sourceId"] = "beat.argument_escalation",
            ["sourcePath"] = "beat/social/conflict/argument_escalation.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Beat/Social/Conflict",
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
            ["maintain"] = {
                ["op"] = "gt",
                ["path"] = "history.hostilityCount",
                ["value"] = 0,
            },
            ["maxTurns"] = 6,
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
        ["sourceShard"] = "beat/social/conflict/argument_escalation.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
