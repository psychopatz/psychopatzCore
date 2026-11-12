-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_director",
        ["id"] = "behavior.acknowledge_memory",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["sourceId"] = "behavior.acknowledge_memory",
            ["sourcePath"] = "psdl/director/social.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Behavior/SocialDirector/Catalog",
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
                    ["contentTemplateID"] = "semantic.interaction.memory.acknowledge_flavor",
                    ["presentationAct"] = "AMBIENT_FLAVOR",
                },
                ["speech"] = {
                    ["contentTemplateID"] = "semantic.interaction.memory.acknowledge",
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
        ["sourceShard"] = "psdl/director/social.json",
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
        ["domain"] = "social_director",
        ["id"] = "behavior.acknowledge_news",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["sourceId"] = "behavior.acknowledge_news",
            ["sourcePath"] = "psdl/director/social.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Behavior/SocialDirector/Catalog",
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
                    ["contentTemplateID"] = "semantic.interaction.news.acknowledge",
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
        ["sourceShard"] = "psdl/director/social.json",
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
        ["domain"] = "social_director",
        ["id"] = "behavior.acknowledge_repair",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["sourceId"] = "behavior.acknowledge_repair",
            ["sourcePath"] = "psdl/director/social.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Behavior/SocialDirector/Catalog",
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
                    ["contentTemplateID"] = "semantic.social.apology.friendly",
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
        ["sourceShard"] = "psdl/director/social.json",
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
        ["domain"] = "social_director",
        ["id"] = "behavior.acknowledge_reply",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["sourceId"] = "behavior.acknowledge_reply",
            ["sourcePath"] = "psdl/director/social.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Behavior/SocialDirector/Catalog",
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
                    ["contentTemplateID"] = "semantic.social.acknowledged",
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
        ["sourceShard"] = "psdl/director/social.json",
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
        ["domain"] = "social_director",
        ["id"] = "behavior.acknowledge_thanks",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["sourceId"] = "behavior.acknowledge_thanks",
            ["sourcePath"] = "psdl/director/social.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Behavior/SocialDirector/Catalog",
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
                    ["contentTemplateID"] = "semantic.social.acknowledged",
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
        ["sourceShard"] = "psdl/director/social.json",
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
        ["domain"] = "social_director",
        ["id"] = "behavior.ask_memory_followup",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["sourceId"] = "behavior.ask_memory_followup",
            ["sourcePath"] = "psdl/director/social.json#records[5]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Behavior/SocialDirector/Catalog",
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
                    ["contentTemplateID"] = "semantic.interaction.memory.followup",
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
        ["sourceShard"] = "psdl/director/social.json",
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
        ["domain"] = "social_director",
        ["id"] = "behavior.challenge",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["sourceId"] = "behavior.challenge",
            ["sourcePath"] = "psdl/director/social.json#records[6]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Behavior/SocialDirector/Catalog",
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
                    ["contentTemplateID"] = "semantic.interaction.first_contact.challenge",
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
        ["sourceShard"] = "psdl/director/social.json",
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
        ["domain"] = "social_director",
        ["id"] = "behavior.clarify_context",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["sourceId"] = "behavior.clarify_context",
            ["sourcePath"] = "psdl/director/social.json#records[7]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Behavior/SocialDirector/Catalog",
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
                    ["contentTemplateID"] = "semantic.interaction.context.clarify",
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
        ["sourceShard"] = "psdl/director/social.json",
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
        ["domain"] = "social_director",
        ["id"] = "behavior.deescalate",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["sourceId"] = "behavior.deescalate",
            ["sourcePath"] = "psdl/director/social.json#records[8]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Behavior/SocialDirector/Catalog",
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
                    ["contentTemplateID"] = "semantic.interaction.argument.deescalate",
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
        ["sourceShard"] = "psdl/director/social.json",
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
        ["domain"] = "social_director",
        ["id"] = "behavior.end_conversation",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["sourceId"] = "behavior.end_conversation",
            ["sourcePath"] = "psdl/director/social.json#records[9]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Behavior/SocialDirector/Catalog",
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
                    ["contentTemplateID"] = "semantic.social.hostile_withdrawn",
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
        ["sourceShard"] = "psdl/director/social.json",
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
        ["domain"] = "social_director",
        ["id"] = "behavior.reconcile",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["sourceId"] = "behavior.reconcile",
            ["sourcePath"] = "psdl/director/social.json#records[10]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Behavior/SocialDirector/Catalog",
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
                    ["contentTemplateID"] = "semantic.social.apology.friendly",
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
        ["sourceShard"] = "psdl/director/social.json",
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
        ["domain"] = "social_director",
        ["id"] = "behavior.retaliate_verbally",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["sourceId"] = "behavior.retaliate_verbally",
            ["sourcePath"] = "psdl/director/social.json#records[11]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Behavior/SocialDirector/Catalog",
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
                    ["contentTemplateID"] = "semantic.interaction.argument.retaliate",
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
        ["sourceShard"] = "psdl/director/social.json",
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
        ["domain"] = "social_director",
        ["id"] = "behavior.scene_excursion_acknowledge",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["sourceId"] = "behavior.scene_excursion_acknowledge",
            ["sourcePath"] = "psdl/director/social.json#records[24]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Behavior/SocialDirector/Catalog",
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
                    ["contentTemplateID"] = "semantic.social.acknowledged",
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
        ["sourceShard"] = "psdl/director/social.json",
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
        ["domain"] = "social_director",
        ["id"] = "behavior.scene_excursion_departing",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["sourceId"] = "behavior.scene_excursion_departing",
            ["sourcePath"] = "psdl/director/social.json#records[20]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Behavior/SocialDirector/Catalog",
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
                    ["contentTemplateID"] = "semantic.interaction.scene.excursion_departing",
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
        ["sourceShard"] = "psdl/director/social.json",
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
        ["domain"] = "social_director",
        ["id"] = "behavior.scene_excursion_failed",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["sourceId"] = "behavior.scene_excursion_failed",
            ["sourcePath"] = "psdl/director/social.json#records[23]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Behavior/SocialDirector/Catalog",
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
                    ["contentTemplateID"] = "semantic.interaction.scene.excursion_failed",
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
        ["sourceShard"] = "psdl/director/social.json",
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
        ["domain"] = "social_director",
        ["id"] = "behavior.scene_excursion_home",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["sourceId"] = "behavior.scene_excursion_home",
            ["sourcePath"] = "psdl/director/social.json#records[22]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Behavior/SocialDirector/Catalog",
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
                    ["contentTemplateID"] = "semantic.interaction.scene.excursion_home",
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
        ["sourceShard"] = "psdl/director/social.json",
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
        ["domain"] = "social_director",
        ["id"] = "behavior.scene_excursion_preparing",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["sourceId"] = "behavior.scene_excursion_preparing",
            ["sourcePath"] = "psdl/director/social.json#records[19]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Behavior/SocialDirector/Catalog",
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
                    ["contentTemplateID"] = "semantic.interaction.scene.excursion_preparing",
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
        ["sourceShard"] = "psdl/director/social.json",
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
        ["domain"] = "social_director",
        ["id"] = "behavior.scene_excursion_returning",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["sourceId"] = "behavior.scene_excursion_returning",
            ["sourcePath"] = "psdl/director/social.json#records[21]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Behavior/SocialDirector/Catalog",
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
                    ["contentTemplateID"] = "semantic.interaction.scene.excursion_returning",
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
        ["sourceShard"] = "psdl/director/social.json",
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
        ["domain"] = "social_director",
        ["id"] = "behavior.scene_grounded_news_share",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["sourceId"] = "behavior.scene_grounded_news_share",
            ["sourcePath"] = "psdl/director/social.json#records[16]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Behavior/SocialDirector/Catalog",
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
                    ["contentTemplateID"] = "semantic.interaction.scene.grounded_news_share",
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
        ["sourceShard"] = "psdl/director/social.json",
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
        ["domain"] = "social_director",
        ["id"] = "behavior.scene_horde_prompt",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["sourceId"] = "behavior.scene_horde_prompt",
            ["sourcePath"] = "psdl/director/social.json#records[12]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Behavior/SocialDirector/Catalog",
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
                    ["contentTemplateID"] = "semantic.interaction.scene.horde_prompt",
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
        ["sourceShard"] = "psdl/director/social.json",
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
        ["domain"] = "social_director",
        ["id"] = "behavior.scene_horde_reply_brave",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["sourceId"] = "behavior.scene_horde_reply_brave",
            ["sourcePath"] = "psdl/director/social.json#records[13]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Behavior/SocialDirector/Catalog",
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
                    ["contentTemplateID"] = "semantic.interaction.scene.horde_reply_brave",
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
        ["sourceShard"] = "psdl/director/social.json",
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
        ["domain"] = "social_director",
        ["id"] = "behavior.scene_horde_reply_cautious",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["sourceId"] = "behavior.scene_horde_reply_cautious",
            ["sourcePath"] = "psdl/director/social.json#records[14]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Behavior/SocialDirector/Catalog",
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
                    ["contentTemplateID"] = "semantic.interaction.scene.horde_reply_cautious",
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
        ["sourceShard"] = "psdl/director/social.json",
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
        ["domain"] = "social_director",
        ["id"] = "behavior.scene_horde_reply_steady",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["sourceId"] = "behavior.scene_horde_reply_steady",
            ["sourcePath"] = "psdl/director/social.json#records[15]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Behavior/SocialDirector/Catalog",
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
                    ["contentTemplateID"] = "semantic.interaction.scene.horde_reply_steady",
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
        ["sourceShard"] = "psdl/director/social.json",
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
        ["domain"] = "social_director",
        ["id"] = "behavior.scene_news_followup",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["sourceId"] = "behavior.scene_news_followup",
            ["sourcePath"] = "psdl/director/social.json#records[17]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Behavior/SocialDirector/Catalog",
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
                    ["contentTemplateID"] = "semantic.interaction.memory.followup",
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
        ["sourceShard"] = "psdl/director/social.json",
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
        ["domain"] = "social_director",
        ["id"] = "behavior.scene_news_followup_answer",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["sourceId"] = "behavior.scene_news_followup_answer",
            ["sourcePath"] = "psdl/director/social.json#records[18]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Behavior/SocialDirector/Catalog",
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
                    ["contentTemplateID"] = "semantic.interaction.scene.grounded_news_answer",
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
        ["sourceShard"] = "psdl/director/social.json",
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
        ["domain"] = "social_director",
        ["id"] = "behavior.scene_post_combat_clear",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["sourceId"] = "behavior.scene_post_combat_clear",
            ["sourcePath"] = "psdl/director/social.json#records[27]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Behavior/SocialDirector/Catalog",
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
                    ["contentTemplateID"] = "semantic.interaction.scene.post_combat_clear",
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
        ["sourceShard"] = "psdl/director/social.json",
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
        ["domain"] = "social_director",
        ["id"] = "behavior.scene_task_work_assigned",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["sourceId"] = "behavior.scene_task_work_assigned",
            ["sourcePath"] = "psdl/director/social.json#records[25]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Behavior/SocialDirector/Catalog",
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
                    ["contentTemplateID"] = "semantic.interaction.scene.task_work_assigned",
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
        ["sourceShard"] = "psdl/director/social.json",
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
        ["domain"] = "social_director",
        ["id"] = "behavior.scene_task_work_completed",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["sourceId"] = "behavior.scene_task_work_completed",
            ["sourcePath"] = "psdl/director/social.json#records[26]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Behavior/SocialDirector/Catalog",
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
                    ["contentTemplateID"] = "semantic.interaction.scene.task_work_completed",
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
        ["sourceShard"] = "psdl/director/social.json",
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
        ["domain"] = "social_director",
        ["id"] = "behavior.warn",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["sourceId"] = "behavior.warn",
            ["sourcePath"] = "psdl/director/social.json#records[28]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Behavior/SocialDirector/Catalog",
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
                    ["contentTemplateID"] = "semantic.social.hostile_boundary",
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
        ["sourceShard"] = "psdl/director/social.json",
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
