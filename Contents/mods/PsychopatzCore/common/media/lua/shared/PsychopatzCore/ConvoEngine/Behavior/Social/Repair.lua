-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social",
        ["domainPath"] = "social/repair",
        ["id"] = "behavior.acknowledge_repair",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "acknowledge_repair",
            ["sourceId"] = "behavior.acknowledge_repair",
            ["sourcePath"] = "behavior/social/repair/acknowledge_repair.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Behavior/Social/Repair",
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
            ["act"] = "ACKNOWLEDGE_REPAIR",
            ["baseRelevance"] = 0.55,
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "social.apology.friendly",
                    ["dialogueAct"] = "ACKNOWLEDGE_REPAIR",
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
        ["sourceShard"] = "behavior/social/repair/acknowledge_repair.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["all"] = {
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
    },
    {
        ["domain"] = "social",
        ["domainPath"] = "social/repair",
        ["id"] = "behavior.deescalate",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "deescalate",
            ["sourceId"] = "behavior.deescalate",
            ["sourcePath"] = "behavior/social/repair/deescalate.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Behavior/Social/Repair",
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
            ["act"] = "DEESCALATE",
            ["baseRelevance"] = 0.35,
            ["mode"] = "beat",
            ["modifiers"] = {
                {
                    ["delta"] = 0.4,
                    ["reason"] = "fear_favors_deescalation",
                    ["when"] = {
                        ["op"] = "gte",
                        ["path"] = "actor.condition.panic",
                        ["value"] = 0.6,
                    },
                },
                {
                    ["delta"] = 0.2,
                    ["reason"] = "danger_favors_deescalation",
                    ["when"] = {
                        ["op"] = "truthy",
                        ["path"] = "world.immediateDanger",
                    },
                },
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.argument.deescalate",
                    ["dialogueAct"] = "DEESCALATE",
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
        ["sourceShard"] = "behavior/social/repair/deescalate.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["any"] = {
                {
                    ["op"] = "in",
                    ["path"] = "stimulus.semantic.speechAct",
                    ["values"] = {
                        "INSULT",
                        "HOSTILE_REMARK",
                        "THREATEN",
                    },
                },
                {
                    ["op"] = "truthy",
                    ["path"] = "world.immediateDanger",
                },
            },
        },
    },
    {
        ["domain"] = "social",
        ["domainPath"] = "social/repair",
        ["id"] = "behavior.end_conversation",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "end_conversation",
            ["sourceId"] = "behavior.end_conversation",
            ["sourcePath"] = "behavior/social/repair/end_conversation.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Behavior/Social/Repair",
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
            ["act"] = "END_INTERACTION",
            ["baseRelevance"] = 0.2,
            ["mode"] = "beat",
            ["modifiers"] = {
                {
                    ["delta"] = 0.3,
                    ["reason"] = "danger_favors_exit",
                    ["when"] = {
                        ["op"] = "truthy",
                        ["path"] = "world.immediateDanger",
                    },
                },
                {
                    ["delta"] = 0.45,
                    ["reason"] = "low_forgiveness_favors_exit",
                    ["when"] = {
                        ["op"] = "lt",
                        ["path"] = "actor.disposition.forgiveness",
                        ["value"] = 0.25,
                    },
                },
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "social.hostile_withdrawn",
                    ["dialogueAct"] = "END_CONVERSATION",
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
        ["sourceShard"] = "behavior/social/repair/end_conversation.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["any"] = {
                {
                    ["op"] = "in",
                    ["path"] = "stimulus.semantic.speechAct",
                    ["values"] = {
                        "INSULT",
                        "HOSTILE_REMARK",
                        "THREATEN",
                    },
                },
                {
                    ["op"] = "eq",
                    ["path"] = "stimulus.semantic.intent",
                    ["value"] = "APOLOGIZE",
                },
                {
                    ["op"] = "truthy",
                    ["path"] = "world.immediateDanger",
                },
            },
        },
    },
    {
        ["domain"] = "social",
        ["domainPath"] = "social/repair",
        ["id"] = "behavior.reconcile",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "reconcile",
            ["sourceId"] = "behavior.reconcile",
            ["sourcePath"] = "behavior/social/repair/reconcile.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Behavior/Social/Repair",
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
            ["act"] = "RECONCILE",
            ["baseRelevance"] = 0.6,
            ["mode"] = "beat",
            ["modifiers"] = {
                {
                    ["delta"] = 0.15,
                    ["reason"] = "relationship_recoverable",
                    ["when"] = {
                        ["op"] = "gte",
                        ["path"] = "relationship.approval",
                        ["value"] = -20,
                    },
                },
                {
                    ["delta"] = -0.2,
                    ["reason"] = "low_forgiveness",
                    ["when"] = {
                        ["op"] = "lt",
                        ["path"] = "actor.disposition.forgiveness",
                        ["value"] = 0.35,
                    },
                },
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "social.apology.friendly",
                    ["dialogueAct"] = "RECONCILE",
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
        ["sourceShard"] = "behavior/social/repair/reconcile.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
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
            },
        },
    },
}
