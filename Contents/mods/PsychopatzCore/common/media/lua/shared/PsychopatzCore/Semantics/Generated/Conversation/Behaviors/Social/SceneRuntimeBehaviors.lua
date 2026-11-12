-- Generated; do not edit by hand.
return {
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
                ["contentTemplateID"] = "semantic.social.acknowledged",
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
                ["contentTemplateID"] = "semantic.interaction.scene.excursion_departing",
                ["dialogueAct"] = "INFORM",
            },
        },
        ["owner"] = "PsychopatzCore",
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
                ["contentTemplateID"] = "semantic.interaction.scene.excursion_failed",
                ["dialogueAct"] = "INFORM",
            },
        },
        ["owner"] = "PsychopatzCore",
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
                ["contentTemplateID"] = "semantic.interaction.scene.excursion_home",
                ["dialogueAct"] = "INFORM",
            },
        },
        ["owner"] = "PsychopatzCore",
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
                ["contentTemplateID"] = "semantic.interaction.scene.excursion_preparing",
                ["dialogueAct"] = "INFORM",
            },
        },
        ["owner"] = "PsychopatzCore",
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
                ["contentTemplateID"] = "semantic.interaction.scene.excursion_returning",
                ["dialogueAct"] = "INFORM",
            },
        },
        ["owner"] = "PsychopatzCore",
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
                ["contentTemplateID"] = "semantic.interaction.scene.grounded_news_share",
                ["dialogueAct"] = "DISCLOSE",
            },
        },
        ["owner"] = "PsychopatzCore",
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
                ["contentTemplateID"] = "semantic.interaction.scene.horde_prompt",
                ["dialogueAct"] = "WARN",
            },
        },
        ["owner"] = "PsychopatzCore",
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
                ["contentTemplateID"] = "semantic.interaction.scene.horde_reply_brave",
                ["dialogueAct"] = "PROPOSE_ENGAGE",
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
                ["contentTemplateID"] = "semantic.interaction.scene.horde_reply_cautious",
                ["dialogueAct"] = "PROPOSE_AVOID",
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
                ["contentTemplateID"] = "semantic.interaction.scene.horde_reply_steady",
                ["dialogueAct"] = "PROPOSE_HOLD",
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
                ["contentTemplateID"] = "semantic.interaction.memory.followup",
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
                ["contentTemplateID"] = "semantic.interaction.scene.grounded_news_answer",
                ["dialogueAct"] = "ANSWER",
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
            ["value"] = "ASK_NEWS_FOLLOWUP",
        },
    },
}
