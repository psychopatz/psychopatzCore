-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social",
        ["domainPath"] = "social/repair",
        ["id"] = "beat.reconciliation",
        ["kind"] = "beat",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "reconciliation",
            ["sourceId"] = "beat.reconciliation",
            ["sourcePath"] = "beat/social/repair/reconciliation.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Beat/Social/Repair",
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
            ["maintain"] = {
                ["op"] = "falsy",
                ["path"] = "scene.ended",
            },
            ["maxTurns"] = 2,
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
        ["sourceShard"] = "beat/social/repair/reconciliation.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
