-- Generated; do not edit by hand.
return {
    {
        ["act"] = "ACKNOWLEDGE_MEMORY",
        ["baseRelevance"] = 0.5,
        ["domain"] = "social",
        ["id"] = "behavior.acknowledge_memory",
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
        ["owner"] = "PsychopatzCore",
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
    {
        ["act"] = "ACKNOWLEDGE_NEWS",
        ["baseRelevance"] = 0.55,
        ["domain"] = "social",
        ["id"] = "behavior.acknowledge_news",
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
        ["owner"] = "PsychopatzCore",
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
    {
        ["act"] = "ACKNOWLEDGE_REPAIR",
        ["baseRelevance"] = 0.55,
        ["domain"] = "social",
        ["id"] = "behavior.acknowledge_repair",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "social.apology.friendly",
                ["dialogueAct"] = "ACKNOWLEDGE_REPAIR",
            },
        },
        ["owner"] = "PsychopatzCore",
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
    {
        ["act"] = "ACKNOWLEDGE_REPLY",
        ["baseRelevance"] = 0.65,
        ["domain"] = "social",
        ["id"] = "behavior.acknowledge_reply",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "social.acknowledged",
                ["dialogueAct"] = "ACKNOWLEDGE",
            },
        },
        ["owner"] = "PsychopatzCore",
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
    {
        ["act"] = "ACKNOWLEDGE_THANKS",
        ["baseRelevance"] = 0.55,
        ["domain"] = "social",
        ["id"] = "behavior.acknowledge_thanks",
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
        ["owner"] = "PsychopatzCore",
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
    {
        ["act"] = "ASK_MEMORY_FOLLOWUP",
        ["baseRelevance"] = 0.45,
        ["domain"] = "social",
        ["id"] = "behavior.ask_memory_followup",
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
        ["owner"] = "PsychopatzCore",
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
    {
        ["act"] = "CHALLENGE",
        ["baseRelevance"] = 0.5,
        ["domain"] = "social",
        ["id"] = "behavior.challenge",
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
        ["owner"] = "PsychopatzCore",
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
    {
        ["act"] = "ASK_CLARIFICATION",
        ["baseRelevance"] = 0.95,
        ["domain"] = "social",
        ["id"] = "behavior.clarify_context",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "interaction.context.clarify",
                ["dialogueAct"] = "ASK_CLARIFICATION",
            },
        },
        ["owner"] = "PsychopatzCore",
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
    {
        ["act"] = "DEESCALATE",
        ["baseRelevance"] = 0.35,
        ["domain"] = "social",
        ["id"] = "behavior.deescalate",
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
        ["owner"] = "PsychopatzCore",
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
    {
        ["act"] = "END_INTERACTION",
        ["baseRelevance"] = 0.2,
        ["domain"] = "social",
        ["id"] = "behavior.end_conversation",
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
        ["owner"] = "PsychopatzCore",
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
    {
        ["act"] = "RECONCILE",
        ["baseRelevance"] = 0.6,
        ["domain"] = "social",
        ["id"] = "behavior.reconcile",
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
        ["owner"] = "PsychopatzCore",
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
    {
        ["act"] = "RETALIATE_VERBALLY",
        ["baseRelevance"] = 0.55,
        ["domain"] = "social",
        ["id"] = "behavior.retaliate_verbally",
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
        ["owner"] = "PsychopatzCore",
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
    {
        ["act"] = "ACKNOWLEDGE",
        ["baseRelevance"] = 1,
        ["continuation"] = {
            ["inheritEventRefs"] = true,
            ["inheritFactRefs"] = true,
            ["mode"] = "terminate",
            ["target"] = "none",
        },
        ["domain"] = "social",
        ["id"] = "behavior.scene_excursion_acknowledge",
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
        ["owner"] = "ProjectHoomans",
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
    {
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
        ["domain"] = "social",
        ["id"] = "behavior.scene_excursion_departing",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "interaction.scene.excursion_departing",
                ["dialogueAct"] = "INFORM",
            },
        },
        ["owner"] = "ProjectHoomans",
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
    {
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
        ["domain"] = "social",
        ["id"] = "behavior.scene_excursion_failed",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "interaction.scene.excursion_failed",
                ["dialogueAct"] = "INFORM",
            },
        },
        ["owner"] = "ProjectHoomans",
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
    {
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
        ["domain"] = "social",
        ["id"] = "behavior.scene_excursion_home",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "interaction.scene.excursion_home",
                ["dialogueAct"] = "INFORM",
            },
        },
        ["owner"] = "ProjectHoomans",
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
    {
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
        ["domain"] = "social",
        ["id"] = "behavior.scene_excursion_preparing",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "interaction.scene.excursion_preparing",
                ["dialogueAct"] = "INFORM",
            },
        },
        ["owner"] = "ProjectHoomans",
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
    {
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
        ["domain"] = "social",
        ["id"] = "behavior.scene_excursion_returning",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "interaction.scene.excursion_returning",
                ["dialogueAct"] = "INFORM",
            },
        },
        ["owner"] = "ProjectHoomans",
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
    {
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
        ["domain"] = "social",
        ["id"] = "behavior.scene_grounded_news_share",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "interaction.scene.grounded_news_share",
                ["dialogueAct"] = "DISCLOSE",
            },
        },
        ["owner"] = "ProjectHoomans",
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
    {
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
        ["domain"] = "social",
        ["id"] = "behavior.scene_horde_prompt",
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
        ["owner"] = "ProjectHoomans",
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
    {
        ["act"] = "COMBAT_HORDE_REPLY",
        ["baseRelevance"] = 1,
        ["continuation"] = {
            ["inheritEventRefs"] = true,
            ["inheritFactRefs"] = true,
            ["mode"] = "terminate",
            ["target"] = "none",
        },
        ["domain"] = "social",
        ["id"] = "behavior.scene_horde_reply_brave",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "interaction.scene.horde_reply_brave",
                ["dialogueAct"] = "PROPOSE_ENGAGE",
            },
        },
        ["owner"] = "ProjectHoomans",
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
    {
        ["act"] = "COMBAT_HORDE_REPLY",
        ["baseRelevance"] = 1,
        ["continuation"] = {
            ["inheritEventRefs"] = true,
            ["inheritFactRefs"] = true,
            ["mode"] = "terminate",
            ["target"] = "none",
        },
        ["domain"] = "social",
        ["id"] = "behavior.scene_horde_reply_cautious",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "interaction.scene.horde_reply_cautious",
                ["dialogueAct"] = "PROPOSE_AVOID",
            },
        },
        ["owner"] = "ProjectHoomans",
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
    {
        ["act"] = "COMBAT_HORDE_REPLY",
        ["baseRelevance"] = 0.65,
        ["continuation"] = {
            ["inheritEventRefs"] = true,
            ["inheritFactRefs"] = true,
            ["mode"] = "terminate",
            ["target"] = "none",
        },
        ["domain"] = "social",
        ["id"] = "behavior.scene_horde_reply_steady",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "interaction.scene.horde_reply_steady",
                ["dialogueAct"] = "PROPOSE_HOLD",
            },
        },
        ["owner"] = "ProjectHoomans",
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
    {
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
        ["domain"] = "social",
        ["id"] = "behavior.scene_news_followup",
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
        ["owner"] = "ProjectHoomans",
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
    {
        ["act"] = "ANSWER_NEWS",
        ["baseRelevance"] = 1,
        ["continuation"] = {
            ["inheritEventRefs"] = true,
            ["inheritFactRefs"] = true,
            ["mode"] = "terminate",
            ["target"] = "none",
        },
        ["domain"] = "social",
        ["id"] = "behavior.scene_news_followup_answer",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "interaction.scene.grounded_news_answer",
                ["dialogueAct"] = "ANSWER",
            },
        },
        ["owner"] = "ProjectHoomans",
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
    {
        ["act"] = "POST_COMBAT_REACTION",
        ["baseRelevance"] = 1,
        ["continuation"] = {
            ["inheritEventRefs"] = true,
            ["inheritFactRefs"] = true,
            ["mode"] = "terminate",
            ["target"] = "none",
        },
        ["domain"] = "social",
        ["id"] = "behavior.scene_post_combat_clear",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "interaction.scene.post_combat_clear",
                ["dialogueAct"] = "INFORM",
            },
        },
        ["owner"] = "ProjectHoomans",
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
    {
        ["act"] = "TASK_WORK_STATUS",
        ["baseRelevance"] = 1,
        ["continuation"] = {
            ["inheritEventRefs"] = true,
            ["inheritFactRefs"] = true,
            ["mode"] = "terminate",
            ["target"] = "none",
        },
        ["domain"] = "social",
        ["id"] = "behavior.scene_task_work_assigned",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "interaction.scene.task_work_assigned",
                ["dialogueAct"] = "INFORM",
            },
        },
        ["owner"] = "ProjectHoomans",
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
    {
        ["act"] = "TASK_WORK_STATUS",
        ["baseRelevance"] = 1,
        ["continuation"] = {
            ["inheritEventRefs"] = true,
            ["inheritFactRefs"] = true,
            ["mode"] = "terminate",
            ["target"] = "none",
        },
        ["domain"] = "social",
        ["id"] = "behavior.scene_task_work_completed",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "interaction.scene.task_work_completed",
                ["dialogueAct"] = "INFORM",
            },
        },
        ["owner"] = "ProjectHoomans",
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
    {
        ["act"] = "WARN",
        ["baseRelevance"] = 0.65,
        ["domain"] = "social",
        ["id"] = "behavior.warn",
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
        ["owner"] = "PsychopatzCore",
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
    {
        ["act"] = "WARN_GROUP",
        ["baseRelevance"] = 0.8,
        ["domain"] = "social",
        ["id"] = "behavior.world_event_warn",
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
        ["owner"] = "PsychopatzCore",
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
}
