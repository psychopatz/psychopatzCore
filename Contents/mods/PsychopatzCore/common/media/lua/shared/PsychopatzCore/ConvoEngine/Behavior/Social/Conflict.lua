-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social",
        ["domainPath"] = "social/conflict",
        ["id"] = "behavior.challenge",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "challenge",
            ["sourceId"] = "behavior.challenge",
            ["sourcePath"] = "behavior/social/conflict/challenge.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Behavior/Social/Conflict",
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
            ["act"] = "CHALLENGE",
            ["baseRelevance"] = 0.5,
            ["mode"] = "beat",
            ["modifiers"] = {
                {
                    ["delta"] = 0.12,
                    ["reason"] = "confidence_supports_challenge",
                    ["when"] = {
                        ["op"] = "gte",
                        ["path"] = "actor.disposition.confidence",
                        ["value"] = 0.55,
                    },
                },
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.first_contact.challenge",
                    ["dialogueAct"] = "CHALLENGE",
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
        ["sourceShard"] = "behavior/social/conflict/challenge.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "in",
            ["path"] = "stimulus.semantic.intent",
            ["values"] = {
                "GREET",
                "GOSSIP",
            },
        },
    },
    {
        ["domain"] = "social",
        ["domainPath"] = "social/conflict",
        ["id"] = "behavior.retaliate_verbally",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "retaliate_verbally",
            ["sourceId"] = "behavior.retaliate_verbally",
            ["sourcePath"] = "behavior/social/conflict/retaliate_verbally.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Behavior/Social/Conflict",
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
            ["act"] = "RETALIATE_VERBALLY",
            ["baseRelevance"] = 0.55,
            ["mode"] = "beat",
            ["modifiers"] = {
                {
                    ["delta"] = 0.2,
                    ["reason"] = "aggressive_personality",
                    ["when"] = {
                        ["op"] = "gte",
                        ["path"] = "actor.disposition.aggression",
                        ["value"] = 0.65,
                    },
                },
                {
                    ["delta"] = -0.3,
                    ["reason"] = "fear_suppresses_retaliation",
                    ["when"] = {
                        ["op"] = "gte",
                        ["path"] = "actor.condition.panic",
                        ["value"] = 0.6,
                    },
                },
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.argument.retaliate",
                    ["dialogueAct"] = "RETALIATE_VERBALLY",
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
        ["sourceShard"] = "behavior/social/conflict/retaliate_verbally.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "in",
            ["path"] = "stimulus.semantic.speechAct",
            ["values"] = {
                "INSULT",
                "HOSTILE_REMARK",
                "THREATEN",
            },
        },
    },
    {
        ["domain"] = "social",
        ["domainPath"] = "social/conflict",
        ["id"] = "behavior.warn",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "warn",
            ["sourceId"] = "behavior.warn",
            ["sourcePath"] = "behavior/social/conflict/warn.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Behavior/Social/Conflict",
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
            ["act"] = "WARN",
            ["baseRelevance"] = 0.65,
            ["mode"] = "beat",
            ["modifiers"] = {
                {
                    ["delta"] = 0.12,
                    ["reason"] = "low_approval",
                    ["when"] = {
                        ["op"] = "lt",
                        ["path"] = "relationship.approval",
                        ["value"] = 0,
                    },
                },
                {
                    ["delta"] = 0.08,
                    ["reason"] = "confident",
                    ["when"] = {
                        ["op"] = "gte",
                        ["path"] = "actor.disposition.confidence",
                        ["value"] = 0.6,
                    },
                },
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "social.hostile_boundary",
                    ["dialogueAct"] = "BOUNDARY_WARNING",
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
        ["sourceShard"] = "behavior/social/conflict/warn.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "in",
            ["path"] = "stimulus.semantic.speechAct",
            ["values"] = {
                "INSULT",
                "HOSTILE_REMARK",
                "THREATEN",
            },
        },
    },
}
