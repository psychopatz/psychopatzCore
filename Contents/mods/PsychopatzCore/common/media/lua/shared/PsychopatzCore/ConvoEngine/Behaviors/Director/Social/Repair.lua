-- Generated; do not edit by hand.
return {
    {
        ["act"] = "ACKNOWLEDGE_REPAIR",
        ["baseRelevance"] = 0.55,
        ["domain"] = "social",
        ["domainPath"] = "social/repair",
        ["domains"] = {
            {
                ["domain"] = "social",
                ["owner"] = "PsychopatzCore",
            },
        },
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
        ["topics"] = {
            {
                ["domain"] = "social",
                ["id"] = "repair",
            },
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
        ["act"] = "DEESCALATE",
        ["baseRelevance"] = 0.35,
        ["domain"] = "social",
        ["domainPath"] = "social/repair",
        ["domains"] = {
            {
                ["domain"] = "social",
                ["owner"] = "PsychopatzCore",
            },
        },
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
        ["topics"] = {
            {
                ["domain"] = "social",
                ["id"] = "repair",
            },
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
        ["domainPath"] = "social/repair",
        ["id"] = "behavior.end_conversation",
        ["metadata"] = {
            ["compositionHooksNotApplicableReason"] = "Domain-agnostic conversation closing strategy",
        },
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
        ["domainPath"] = "social/repair",
        ["domains"] = {
            {
                ["domain"] = "social",
                ["owner"] = "PsychopatzCore",
            },
        },
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
        ["topics"] = {
            {
                ["domain"] = "social",
                ["id"] = "repair",
            },
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
}
