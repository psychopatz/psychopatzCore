-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social",
        ["id"] = "behavior.acknowledge_memory",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "acknowledge_memory",
            ["sourceId"] = "behavior.acknowledge_memory",
            ["sourcePath"] = "behavior/social/acknowledge_memory.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social__d6475647",
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
            ["act"] = "ACKNOWLEDGE_MEMORY",
            ["baseRelevance"] = 0.5,
            ["mode"] = "one_shot",
            ["modifiers"] = {
                {
                    ["delta"] = 0.25,
                    ["reason"] = "empathy_favors_acknowledgement",
                    ["when"] = {
                        ["op"] = "gte",
                        ["path"] = "actor.disposition.empathy",
                        ["value"] = 0.6,
                    },
                },
                {
                    ["delta"] = 0.1,
                    ["reason"] = "low_sociability_favors_acknowledgement",
                    ["when"] = {
                        ["op"] = "lt",
                        ["path"] = "actor.disposition.sociability",
                        ["value"] = 0.4,
                    },
                },
            },
            ["outputs"] = {
                ["emote"] = {
                    ["id"] = "emote.nod",
                },
                ["flavor"] = {
                    ["contentTemplateID"] = "interaction.memory.acknowledge_flavor",
                    ["presentationAct"] = "AMBIENT_FLAVOR",
                },
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.memory.acknowledge",
                    ["dialogueAct"] = "ACKNOWLEDGE",
                },
            },
            ["requiredCapabilities"] = {
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
        ["sourceShard"] = "behavior/social/acknowledge_memory.json",
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
        ["id"] = "behavior.acknowledge_news",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "acknowledge_news",
            ["sourceId"] = "behavior.acknowledge_news",
            ["sourcePath"] = "behavior/social/acknowledge_news.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social__d6475647",
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
            ["act"] = "ACKNOWLEDGE_NEWS",
            ["baseRelevance"] = 0.55,
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["emote"] = {
                    ["id"] = "emote.nod",
                },
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.news.acknowledge",
                    ["dialogueAct"] = "ACKNOWLEDGE",
                },
            },
            ["requiredCapabilities"] = {
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
        ["sourceShard"] = "behavior/social/acknowledge_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "SHARE_NEWS",
        },
    },
    {
        ["domain"] = "social",
        ["id"] = "behavior.acknowledge_repair",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "acknowledge_repair",
            ["sourceId"] = "behavior.acknowledge_repair",
            ["sourcePath"] = "behavior/social/acknowledge_repair.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social__d6475647",
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
        ["sourceShard"] = "behavior/social/acknowledge_repair.json",
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
        ["id"] = "behavior.acknowledge_reply",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "acknowledge_reply",
            ["sourceId"] = "behavior.acknowledge_reply",
            ["sourcePath"] = "behavior/social/acknowledge_reply.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social__d6475647",
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
            ["act"] = "ACKNOWLEDGE_REPLY",
            ["baseRelevance"] = 0.65,
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "social.acknowledged",
                    ["dialogueAct"] = "ACKNOWLEDGE",
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
        ["sourceShard"] = "behavior/social/acknowledge_reply.json",
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
                    ["value"] = "response",
                },
            },
        },
    },
    {
        ["domain"] = "social",
        ["id"] = "behavior.acknowledge_thanks",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "acknowledge_thanks",
            ["sourceId"] = "behavior.acknowledge_thanks",
            ["sourcePath"] = "behavior/social/acknowledge_thanks.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social__d6475647",
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
            ["act"] = "ACKNOWLEDGE_THANKS",
            ["baseRelevance"] = 0.55,
            ["mode"] = "one_shot",
            ["modifiers"] = {
                {
                    ["delta"] = 0.1,
                    ["reason"] = "sociable_acknowledgement",
                    ["when"] = {
                        ["op"] = "gte",
                        ["path"] = "actor.disposition.sociability",
                        ["value"] = 0.65,
                    },
                },
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "social.acknowledged",
                    ["dialogueAct"] = "ACKNOWLEDGE",
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
        ["sourceShard"] = "behavior/social/acknowledge_thanks.json",
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
                    ["value"] = "THANK",
                },
                {
                    ["op"] = "truthy",
                    ["path"] = "pragmatic.contextualAdmission.admitted",
                },
                {
                    ["op"] = "eq",
                    ["path"] = "pragmatic.contextualAdmission.selected.relation",
                    ["value"] = "gratitude",
                },
            },
        },
    },
    {
        ["domain"] = "social",
        ["id"] = "behavior.ask_memory_followup",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "ask_memory_followup",
            ["sourceId"] = "behavior.ask_memory_followup",
            ["sourcePath"] = "behavior/social/ask_memory_followup.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social__d6475647",
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
        ["sourceShard"] = "behavior/social/ask_memory_followup.json",
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
        ["id"] = "behavior.challenge",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "challenge",
            ["sourceId"] = "behavior.challenge",
            ["sourcePath"] = "behavior/social/challenge.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social__d6475647",
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
        ["sourceShard"] = "behavior/social/challenge.json",
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
        ["id"] = "behavior.clarify_context",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "clarify_context",
            ["sourceId"] = "behavior.clarify_context",
            ["sourcePath"] = "behavior/social/clarify_context.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social__d6475647",
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
        ["sourceShard"] = "behavior/social/clarify_context.json",
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
    {
        ["domain"] = "social",
        ["id"] = "behavior.deescalate",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "deescalate",
            ["sourceId"] = "behavior.deescalate",
            ["sourcePath"] = "behavior/social/deescalate.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social__d6475647",
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
        ["sourceShard"] = "behavior/social/deescalate.json",
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
        ["id"] = "behavior.end_conversation",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "end_conversation",
            ["sourceId"] = "behavior.end_conversation",
            ["sourcePath"] = "behavior/social/end_conversation.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social__d6475647",
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
        ["sourceShard"] = "behavior/social/end_conversation.json",
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
        ["id"] = "behavior.reconcile",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "reconcile",
            ["sourceId"] = "behavior.reconcile",
            ["sourcePath"] = "behavior/social/reconcile.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social__d6475647",
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
        ["sourceShard"] = "behavior/social/reconcile.json",
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
    {
        ["domain"] = "social",
        ["id"] = "behavior.retaliate_verbally",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "retaliate_verbally",
            ["sourceId"] = "behavior.retaliate_verbally",
            ["sourcePath"] = "behavior/social/retaliate_verbally.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social__d6475647",
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
        ["sourceShard"] = "behavior/social/retaliate_verbally.json",
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
        ["id"] = "behavior.warn",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "warn",
            ["sourceId"] = "behavior.warn",
            ["sourcePath"] = "behavior/social/warn.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social__d6475647",
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
        ["sourceShard"] = "behavior/social/warn.json",
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
        ["id"] = "behavior.world_event_warn",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "world_event_warn",
            ["sourceId"] = "behavior.world_event_warn",
            ["sourcePath"] = "behavior/social/world_event_warn.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social__d6475647",
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
            ["act"] = "WARN_GROUP",
            ["baseRelevance"] = 0.8,
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["emote"] = {
                    ["id"] = "emote.alert",
                },
                ["flavor"] = {
                    ["contentTemplateID"] = "interaction.world_event.warning_flavor",
                    ["presentationAct"] = "AMBIENT_FLAVOR",
                },
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.world_event.warning",
                    ["dialogueAct"] = "WORLD_WARNING",
                },
            },
            ["requiredCapabilities"] = {
            },
            ["stimuli"] = {
                "WORLD_EVENT",
                "DANGER_CHANGED",
            },
            ["version"] = 1,
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/social/world_event_warn.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "truthy",
            ["path"] = "world.immediateDanger",
        },
    },
}
