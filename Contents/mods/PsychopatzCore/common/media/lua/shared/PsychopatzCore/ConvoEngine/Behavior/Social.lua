-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social",
        ["id"] = "behavior.acknowledge_memory",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["localId"] = "acknowledge_memory",
            ["sourceId"] = "behavior.acknowledge_memory",
            ["sourcePath"] = "behavior/social/acknowledge_memory.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social",
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
            ["when"] = {
                ["op"] = "eq",
                ["path"] = "stimulus.semantic.intent",
                ["value"] = "SHARE_MEMORY",
            },
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
            ["localId"] = "acknowledge_news",
            ["sourceId"] = "behavior.acknowledge_news",
            ["sourcePath"] = "behavior/social/acknowledge_news.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social",
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
            ["when"] = {
                ["op"] = "eq",
                ["path"] = "stimulus.semantic.intent",
                ["value"] = "SHARE_NEWS",
            },
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
            ["localId"] = "acknowledge_repair",
            ["sourceId"] = "behavior.acknowledge_repair",
            ["sourcePath"] = "behavior/social/acknowledge_repair.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social",
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
            ["localId"] = "acknowledge_reply",
            ["sourceId"] = "behavior.acknowledge_reply",
            ["sourcePath"] = "behavior/social/acknowledge_reply.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social",
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
            ["localId"] = "acknowledge_thanks",
            ["sourceId"] = "behavior.acknowledge_thanks",
            ["sourcePath"] = "behavior/social/acknowledge_thanks.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social",
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
            ["localId"] = "ask_memory_followup",
            ["sourceId"] = "behavior.ask_memory_followup",
            ["sourcePath"] = "behavior/social/ask_memory_followup.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social",
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
            ["when"] = {
                ["op"] = "eq",
                ["path"] = "stimulus.semantic.intent",
                ["value"] = "SHARE_MEMORY",
            },
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
            ["localId"] = "challenge",
            ["sourceId"] = "behavior.challenge",
            ["sourcePath"] = "behavior/social/challenge.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social",
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
            ["when"] = {
                ["op"] = "in",
                ["path"] = "stimulus.semantic.intent",
                ["values"] = {
                    "GREET",
                    "GOSSIP",
                },
            },
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
            ["localId"] = "clarify_context",
            ["sourceId"] = "behavior.clarify_context",
            ["sourcePath"] = "behavior/social/clarify_context.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social",
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
            ["localId"] = "deescalate",
            ["sourceId"] = "behavior.deescalate",
            ["sourcePath"] = "behavior/social/deescalate.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social",
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
            ["localId"] = "end_conversation",
            ["sourceId"] = "behavior.end_conversation",
            ["sourcePath"] = "behavior/social/end_conversation.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social",
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
            ["localId"] = "reconcile",
            ["sourceId"] = "behavior.reconcile",
            ["sourcePath"] = "behavior/social/reconcile.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social",
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
            ["localId"] = "retaliate_verbally",
            ["sourceId"] = "behavior.retaliate_verbally",
            ["sourcePath"] = "behavior/social/retaliate_verbally.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social",
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
        ["id"] = "behavior.scene_excursion_acknowledge",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["localId"] = "scene_excursion_acknowledge",
            ["sourceId"] = "behavior.scene_excursion_acknowledge",
            ["sourcePath"] = "behavior/social/scene_excursion_acknowledge.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social",
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
            ["act"] = "ACKNOWLEDGE",
            ["baseRelevance"] = 1,
            ["continuation"] = {
                ["inheritEventRefs"] = true,
                ["inheritFactRefs"] = true,
                ["mode"] = "terminate",
                ["target"] = "none",
            },
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["emote"] = {
                    ["id"] = "emote.nod",
                },
                ["speech"] = {
                    ["contentTemplateID"] = "social.acknowledged",
                    ["dialogueAct"] = "ACKNOWLEDGE",
                },
            },
            ["requiredCapabilities"] = {
            },
            ["stimuli"] = {
                "NPC_SEMANTIC_ACT",
            },
            ["version"] = 1,
            ["when"] = {
                ["op"] = "eq",
                ["path"] = "stimulus.semantic.intent",
                ["value"] = "ACKNOWLEDGE_EXCURSION",
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/social/scene_excursion_acknowledge.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "ACKNOWLEDGE_EXCURSION",
        },
    },
    {
        ["domain"] = "social",
        ["id"] = "behavior.scene_excursion_departing",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["localId"] = "scene_excursion_departing",
            ["sourceId"] = "behavior.scene_excursion_departing",
            ["sourcePath"] = "behavior/social/scene_excursion_departing.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social",
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
            ["act"] = "EXCURSION_STATUS_REPORT",
            ["baseRelevance"] = 1,
            ["continuation"] = {
                ["inheritEventRefs"] = true,
                ["inheritFactRefs"] = true,
                ["intent"] = "ACKNOWLEDGE_EXCURSION",
                ["mode"] = "emit",
                ["speechAct"] = "ACKNOWLEDGE",
                ["target"] = "other",
            },
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.scene.excursion_departing",
                    ["dialogueAct"] = "INFORM",
                },
            },
            ["requiredCapabilities"] = {
                "speech",
            },
            ["stimuli"] = {
                "TASK_EVENT",
            },
            ["version"] = 1,
            ["when"] = {
                ["op"] = "eq",
                ["path"] = "stimulus.semantic.intent",
                ["value"] = "EXCURSION_DEPARTING",
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/social/scene_excursion_departing.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "EXCURSION_DEPARTING",
        },
    },
    {
        ["domain"] = "social",
        ["id"] = "behavior.scene_excursion_failed",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["localId"] = "scene_excursion_failed",
            ["sourceId"] = "behavior.scene_excursion_failed",
            ["sourcePath"] = "behavior/social/scene_excursion_failed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social",
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
            ["act"] = "EXCURSION_STATUS_REPORT",
            ["baseRelevance"] = 1,
            ["continuation"] = {
                ["inheritEventRefs"] = true,
                ["inheritFactRefs"] = true,
                ["intent"] = "ACKNOWLEDGE_EXCURSION",
                ["mode"] = "emit",
                ["speechAct"] = "ACKNOWLEDGE",
                ["target"] = "other",
            },
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.scene.excursion_failed",
                    ["dialogueAct"] = "INFORM",
                },
            },
            ["requiredCapabilities"] = {
                "speech",
            },
            ["stimuli"] = {
                "TASK_EVENT",
            },
            ["version"] = 1,
            ["when"] = {
                ["op"] = "eq",
                ["path"] = "stimulus.semantic.intent",
                ["value"] = "EXCURSION_FAILED",
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/social/scene_excursion_failed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "EXCURSION_FAILED",
        },
    },
    {
        ["domain"] = "social",
        ["id"] = "behavior.scene_excursion_home",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["localId"] = "scene_excursion_home",
            ["sourceId"] = "behavior.scene_excursion_home",
            ["sourcePath"] = "behavior/social/scene_excursion_home.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social",
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
            ["act"] = "EXCURSION_STATUS_REPORT",
            ["baseRelevance"] = 1,
            ["continuation"] = {
                ["inheritEventRefs"] = true,
                ["inheritFactRefs"] = true,
                ["intent"] = "ACKNOWLEDGE_EXCURSION",
                ["mode"] = "emit",
                ["speechAct"] = "ACKNOWLEDGE",
                ["target"] = "other",
            },
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.scene.excursion_home",
                    ["dialogueAct"] = "INFORM",
                },
            },
            ["requiredCapabilities"] = {
                "speech",
            },
            ["stimuli"] = {
                "TASK_EVENT",
            },
            ["version"] = 1,
            ["when"] = {
                ["op"] = "eq",
                ["path"] = "stimulus.semantic.intent",
                ["value"] = "EXCURSION_HOME",
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/social/scene_excursion_home.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "EXCURSION_HOME",
        },
    },
    {
        ["domain"] = "social",
        ["id"] = "behavior.scene_excursion_preparing",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["localId"] = "scene_excursion_preparing",
            ["sourceId"] = "behavior.scene_excursion_preparing",
            ["sourcePath"] = "behavior/social/scene_excursion_preparing.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social",
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
            ["act"] = "EXCURSION_STATUS_REPORT",
            ["baseRelevance"] = 1,
            ["continuation"] = {
                ["inheritEventRefs"] = true,
                ["inheritFactRefs"] = true,
                ["intent"] = "ACKNOWLEDGE_EXCURSION",
                ["mode"] = "emit",
                ["speechAct"] = "ACKNOWLEDGE",
                ["target"] = "other",
            },
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.scene.excursion_preparing",
                    ["dialogueAct"] = "INFORM",
                },
            },
            ["requiredCapabilities"] = {
                "speech",
            },
            ["stimuli"] = {
                "TASK_EVENT",
            },
            ["version"] = 1,
            ["when"] = {
                ["op"] = "eq",
                ["path"] = "stimulus.semantic.intent",
                ["value"] = "EXCURSION_PREPARING",
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/social/scene_excursion_preparing.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "EXCURSION_PREPARING",
        },
    },
    {
        ["domain"] = "social",
        ["id"] = "behavior.scene_excursion_returning",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["localId"] = "scene_excursion_returning",
            ["sourceId"] = "behavior.scene_excursion_returning",
            ["sourcePath"] = "behavior/social/scene_excursion_returning.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social",
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
            ["act"] = "EXCURSION_STATUS_REPORT",
            ["baseRelevance"] = 1,
            ["continuation"] = {
                ["inheritEventRefs"] = true,
                ["inheritFactRefs"] = true,
                ["intent"] = "ACKNOWLEDGE_EXCURSION",
                ["mode"] = "emit",
                ["speechAct"] = "ACKNOWLEDGE",
                ["target"] = "other",
            },
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.scene.excursion_returning",
                    ["dialogueAct"] = "INFORM",
                },
            },
            ["requiredCapabilities"] = {
                "speech",
            },
            ["stimuli"] = {
                "TASK_EVENT",
            },
            ["version"] = 1,
            ["when"] = {
                ["op"] = "eq",
                ["path"] = "stimulus.semantic.intent",
                ["value"] = "EXCURSION_RETURNING",
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/social/scene_excursion_returning.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "EXCURSION_RETURNING",
        },
    },
    {
        ["domain"] = "social",
        ["id"] = "behavior.scene_grounded_news_share",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["localId"] = "scene_grounded_news_share",
            ["sourceId"] = "behavior.scene_grounded_news_share",
            ["sourcePath"] = "behavior/social/scene_grounded_news_share.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social",
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
            ["act"] = "SHARE_NEWS",
            ["baseRelevance"] = 1,
            ["continuation"] = {
                ["inheritEventRefs"] = true,
                ["inheritFactRefs"] = true,
                ["intent"] = "SHARE_GROUNDED_NEWS",
                ["mode"] = "emit",
                ["speechAct"] = "INFORM",
                ["target"] = "other",
            },
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.scene.grounded_news_share",
                    ["dialogueAct"] = "DISCLOSE",
                },
            },
            ["requiredCapabilities"] = {
                "speech",
            },
            ["stimuli"] = {
                "AMBIENT_SOCIAL_OPPORTUNITY",
            },
            ["version"] = 1,
            ["when"] = {
                ["op"] = "eq",
                ["path"] = "stimulus.semantic.intent",
                ["value"] = "SHARE_GROUNDED_NEWS",
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/social/scene_grounded_news_share.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "SHARE_GROUNDED_NEWS",
        },
    },
    {
        ["domain"] = "social",
        ["id"] = "behavior.scene_horde_prompt",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["localId"] = "scene_horde_prompt",
            ["sourceId"] = "behavior.scene_horde_prompt",
            ["sourcePath"] = "behavior/social/scene_horde_prompt.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social",
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
            ["act"] = "COMBAT_HORDE_PROMPT",
            ["baseRelevance"] = 1,
            ["continuation"] = {
                ["inheritEventRefs"] = true,
                ["inheritFactRefs"] = true,
                ["intent"] = "COMBAT_HORDE_REPLY",
                ["mode"] = "emit",
                ["speechAct"] = "REPLY",
                ["target"] = "other",
            },
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["emote"] = {
                    ["id"] = "emote.alert",
                },
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.scene.horde_prompt",
                    ["dialogueAct"] = "WARN",
                },
            },
            ["requiredCapabilities"] = {
                "speech",
            },
            ["stimuli"] = {
                "DANGER_CHANGED",
            },
            ["version"] = 1,
            ["when"] = {
                ["op"] = "eq",
                ["path"] = "stimulus.semantic.intent",
                ["value"] = "COMBAT_HORDE_ALERT",
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/social/scene_horde_prompt.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "COMBAT_HORDE_ALERT",
        },
    },
    {
        ["domain"] = "social",
        ["id"] = "behavior.scene_horde_reply_brave",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["localId"] = "scene_horde_reply_brave",
            ["sourceId"] = "behavior.scene_horde_reply_brave",
            ["sourcePath"] = "behavior/social/scene_horde_reply_brave.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social",
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
            ["act"] = "COMBAT_HORDE_REPLY",
            ["baseRelevance"] = 1,
            ["continuation"] = {
                ["inheritEventRefs"] = true,
                ["inheritFactRefs"] = true,
                ["mode"] = "terminate",
                ["target"] = "none",
            },
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.scene.horde_reply_brave",
                    ["dialogueAct"] = "PROPOSE_ENGAGE",
                },
            },
            ["requiredCapabilities"] = {
                "speech",
            },
            ["stimuli"] = {
                "NPC_SEMANTIC_ACT",
            },
            ["version"] = 1,
            ["when"] = {
                ["all"] = {
                    {
                        ["op"] = "eq",
                        ["path"] = "stimulus.semantic.intent",
                        ["value"] = "COMBAT_HORDE_REPLY",
                    },
                    {
                        ["op"] = "gte",
                        ["path"] = "actor.disposition.confidence",
                        ["value"] = 0.65,
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/social/scene_horde_reply_brave.json",
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
                    ["value"] = "COMBAT_HORDE_REPLY",
                },
                {
                    ["op"] = "gte",
                    ["path"] = "actor.disposition.confidence",
                    ["value"] = 0.65,
                },
            },
        },
    },
    {
        ["domain"] = "social",
        ["id"] = "behavior.scene_horde_reply_cautious",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["localId"] = "scene_horde_reply_cautious",
            ["sourceId"] = "behavior.scene_horde_reply_cautious",
            ["sourcePath"] = "behavior/social/scene_horde_reply_cautious.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social",
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
            ["act"] = "COMBAT_HORDE_REPLY",
            ["baseRelevance"] = 1,
            ["continuation"] = {
                ["inheritEventRefs"] = true,
                ["inheritFactRefs"] = true,
                ["mode"] = "terminate",
                ["target"] = "none",
            },
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.scene.horde_reply_cautious",
                    ["dialogueAct"] = "PROPOSE_AVOID",
                },
            },
            ["requiredCapabilities"] = {
                "speech",
            },
            ["stimuli"] = {
                "NPC_SEMANTIC_ACT",
            },
            ["version"] = 1,
            ["when"] = {
                ["all"] = {
                    {
                        ["op"] = "eq",
                        ["path"] = "stimulus.semantic.intent",
                        ["value"] = "COMBAT_HORDE_REPLY",
                    },
                    {
                        ["op"] = "lt",
                        ["path"] = "actor.disposition.confidence",
                        ["value"] = 0.35,
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/social/scene_horde_reply_cautious.json",
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
                    ["value"] = "COMBAT_HORDE_REPLY",
                },
                {
                    ["op"] = "lt",
                    ["path"] = "actor.disposition.confidence",
                    ["value"] = 0.35,
                },
            },
        },
    },
    {
        ["domain"] = "social",
        ["id"] = "behavior.scene_horde_reply_steady",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["localId"] = "scene_horde_reply_steady",
            ["sourceId"] = "behavior.scene_horde_reply_steady",
            ["sourcePath"] = "behavior/social/scene_horde_reply_steady.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social",
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
            ["act"] = "COMBAT_HORDE_REPLY",
            ["baseRelevance"] = 0.65,
            ["continuation"] = {
                ["inheritEventRefs"] = true,
                ["inheritFactRefs"] = true,
                ["mode"] = "terminate",
                ["target"] = "none",
            },
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.scene.horde_reply_steady",
                    ["dialogueAct"] = "PROPOSE_HOLD",
                },
            },
            ["requiredCapabilities"] = {
                "speech",
            },
            ["stimuli"] = {
                "NPC_SEMANTIC_ACT",
            },
            ["version"] = 1,
            ["when"] = {
                ["op"] = "eq",
                ["path"] = "stimulus.semantic.intent",
                ["value"] = "COMBAT_HORDE_REPLY",
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/social/scene_horde_reply_steady.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "COMBAT_HORDE_REPLY",
        },
    },
    {
        ["domain"] = "social",
        ["id"] = "behavior.scene_news_followup",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["localId"] = "scene_news_followup",
            ["sourceId"] = "behavior.scene_news_followup",
            ["sourcePath"] = "behavior/social/scene_news_followup.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social",
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
            ["act"] = "ASK_NEWS_FOLLOWUP",
            ["baseRelevance"] = 0.45,
            ["continuation"] = {
                ["inheritEventRefs"] = true,
                ["inheritFactRefs"] = true,
                ["intent"] = "ASK_NEWS_FOLLOWUP",
                ["mode"] = "emit",
                ["speechAct"] = "ASK_FOLLOWUP",
                ["target"] = "source",
            },
            ["mode"] = "one_shot",
            ["modifiers"] = {
                {
                    ["delta"] = 0.25,
                    ["reason"] = "sociability_favors_news_followup",
                    ["when"] = {
                        ["op"] = "gte",
                        ["path"] = "actor.disposition.sociability",
                        ["value"] = 0.6,
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
            ["when"] = {
                ["op"] = "eq",
                ["path"] = "stimulus.semantic.intent",
                ["value"] = "SHARE_GROUNDED_NEWS",
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/social/scene_news_followup.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "SHARE_GROUNDED_NEWS",
        },
    },
    {
        ["domain"] = "social",
        ["id"] = "behavior.scene_news_followup_answer",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["localId"] = "scene_news_followup_answer",
            ["sourceId"] = "behavior.scene_news_followup_answer",
            ["sourcePath"] = "behavior/social/scene_news_followup_answer.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social",
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
            ["act"] = "ANSWER_NEWS",
            ["baseRelevance"] = 1,
            ["continuation"] = {
                ["inheritEventRefs"] = true,
                ["inheritFactRefs"] = true,
                ["mode"] = "terminate",
                ["target"] = "none",
            },
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.scene.grounded_news_answer",
                    ["dialogueAct"] = "ANSWER",
                },
            },
            ["requiredCapabilities"] = {
                "speech",
            },
            ["stimuli"] = {
                "NPC_SEMANTIC_ACT",
            },
            ["version"] = 1,
            ["when"] = {
                ["op"] = "eq",
                ["path"] = "stimulus.semantic.intent",
                ["value"] = "ASK_NEWS_FOLLOWUP",
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/social/scene_news_followup_answer.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "ASK_NEWS_FOLLOWUP",
        },
    },
    {
        ["domain"] = "social",
        ["id"] = "behavior.scene_post_combat_clear",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["localId"] = "scene_post_combat_clear",
            ["sourceId"] = "behavior.scene_post_combat_clear",
            ["sourcePath"] = "behavior/social/scene_post_combat_clear.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social",
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
            ["act"] = "POST_COMBAT_REACTION",
            ["baseRelevance"] = 1,
            ["continuation"] = {
                ["inheritEventRefs"] = true,
                ["inheritFactRefs"] = true,
                ["mode"] = "terminate",
                ["target"] = "none",
            },
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.scene.post_combat_clear",
                    ["dialogueAct"] = "INFORM",
                },
            },
            ["requiredCapabilities"] = {
                "speech",
            },
            ["stimuli"] = {
                "DANGER_CHANGED",
            },
            ["version"] = 1,
            ["when"] = {
                ["op"] = "eq",
                ["path"] = "stimulus.semantic.intent",
                ["value"] = "POST_COMBAT_CLEAR",
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/social/scene_post_combat_clear.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "POST_COMBAT_CLEAR",
        },
    },
    {
        ["domain"] = "social",
        ["id"] = "behavior.scene_task_work_assigned",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["localId"] = "scene_task_work_assigned",
            ["sourceId"] = "behavior.scene_task_work_assigned",
            ["sourcePath"] = "behavior/social/scene_task_work_assigned.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social",
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
            ["act"] = "TASK_WORK_STATUS",
            ["baseRelevance"] = 1,
            ["continuation"] = {
                ["inheritEventRefs"] = true,
                ["inheritFactRefs"] = true,
                ["mode"] = "terminate",
                ["target"] = "none",
            },
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.scene.task_work_assigned",
                    ["dialogueAct"] = "INFORM",
                },
            },
            ["requiredCapabilities"] = {
                "speech",
            },
            ["stimuli"] = {
                "TASK_EVENT",
            },
            ["version"] = 1,
            ["when"] = {
                ["op"] = "eq",
                ["path"] = "stimulus.semantic.intent",
                ["value"] = "TASK_WORK_ASSIGNED",
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/social/scene_task_work_assigned.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "TASK_WORK_ASSIGNED",
        },
    },
    {
        ["domain"] = "social",
        ["id"] = "behavior.scene_task_work_completed",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["localId"] = "scene_task_work_completed",
            ["sourceId"] = "behavior.scene_task_work_completed",
            ["sourcePath"] = "behavior/social/scene_task_work_completed.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social",
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
            ["act"] = "TASK_WORK_STATUS",
            ["baseRelevance"] = 1,
            ["continuation"] = {
                ["inheritEventRefs"] = true,
                ["inheritFactRefs"] = true,
                ["mode"] = "terminate",
                ["target"] = "none",
            },
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["speech"] = {
                    ["contentTemplateID"] = "interaction.scene.task_work_completed",
                    ["dialogueAct"] = "INFORM",
                },
            },
            ["requiredCapabilities"] = {
                "speech",
            },
            ["stimuli"] = {
                "TASK_EVENT",
            },
            ["version"] = 1,
            ["when"] = {
                ["op"] = "eq",
                ["path"] = "stimulus.semantic.intent",
                ["value"] = "TASK_WORK_COMPLETED",
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/social/scene_task_work_completed.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "TASK_WORK_COMPLETED",
        },
    },
    {
        ["domain"] = "social",
        ["id"] = "behavior.warn",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["localId"] = "warn",
            ["sourceId"] = "behavior.warn",
            ["sourcePath"] = "behavior/social/warn.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social",
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
            ["localId"] = "world_event_warn",
            ["sourceId"] = "behavior.world_event_warn",
            ["sourcePath"] = "behavior/social/world_event_warn.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Behavior/Social",
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
            ["when"] = {
                ["op"] = "truthy",
                ["path"] = "world.immediateDanger",
            },
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
