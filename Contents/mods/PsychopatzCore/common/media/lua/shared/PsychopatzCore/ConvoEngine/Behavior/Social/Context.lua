-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social",
        ["domainPath"] = "social/context",
        ["id"] = "behavior.ask_memory_followup",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "ask_memory_followup",
            ["sourceId"] = "behavior.ask_memory_followup",
            ["sourcePath"] = "behavior/social/context/ask_memory_followup.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Behavior/Social/Context",
        ["namespace"] = "behavior",
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
            ["act"] = "ASK_MEMORY_FOLLOWUP",
            ["baseRelevance"] = 0.45,
            ["domains"] = {
                {
                    ["domain"] = "memory",
                    ["owner"] = "PsychopatzCore",
                },
            },
            ["memories"] = {
                {
                    ["id"] = "shared_memory",
                    ["kind"] = "episodic",
                },
            },
            ["mode"] = "one_shot",
            ["modifiers"] = {
                {
                    ["delta"] = 0.25,
                    ["reason"] = "sociability_favors_followup",
                    ["when"] = {
                        ["op"] = "gte",
                        ["path"] = "actor.disposition.sociability",
                        ["value"] = 0.6,
                    },
                },
                {
                    ["delta"] = 0.1,
                    ["reason"] = "familiarity_favors_followup",
                    ["when"] = {
                        ["op"] = "gte",
                        ["path"] = "relationship.familiarity",
                        ["value"] = 2,
                    },
                },
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.memory.followup",
                    ["dialogueAct"] = "ASK_FOLLOWUP",
                },
            },
            ["requiredCapabilities"] = {
                "speech",
            },
            ["stimuli"] = {
                "NPC_SEMANTIC_ACT",
            },
            ["version"] = 1,
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/social/context/ask_memory_followup.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "SHARE_MEMORY",
        },
    },
    {
        ["domain"] = "social",
        ["domainPath"] = "social/context",
        ["id"] = "behavior.clarify_context",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "clarify_context",
            ["sourceId"] = "behavior.clarify_context",
            ["sourcePath"] = "behavior/social/context/clarify_context.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Behavior/Social/Context",
        ["namespace"] = "behavior",
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
            ["act"] = "ASK_CLARIFICATION",
            ["baseRelevance"] = 0.95,
            ["metadata"] = {
                ["compositionHooksNotApplicableReason"] = "Domain-agnostic conversational context clarification strategy",
            },
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.context.clarify",
                    ["dialogueAct"] = "ASK_CLARIFICATION",
                },
            },
            ["requiredCapabilities"] = {
                "speech",
            },
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
        ["sourceShard"] = "behavior/social/context/clarify_context.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["any"] = {
                {
                    ["op"] = "eq",
                    ["path"] = "pragmatic.contextualAdmission.status",
                    ["value"] = "unresolved",
                },
                {
                    ["op"] = "eq",
                    ["path"] = "pragmatic.contextualAdmission.status",
                    ["value"] = "ambiguous",
                },
            },
        },
    },
}
