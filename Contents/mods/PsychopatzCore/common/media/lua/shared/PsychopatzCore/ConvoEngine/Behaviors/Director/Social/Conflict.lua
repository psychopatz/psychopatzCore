-- Generated; do not edit by hand.
return {
    {
        ["act"] = "CHALLENGE",
        ["baseRelevance"] = 0.5,
        ["domain"] = "social",
        ["domainPath"] = "social/conflict",
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
        ["act"] = "RETALIATE_VERBALLY",
        ["baseRelevance"] = 0.55,
        ["domain"] = "social",
        ["domainPath"] = "social/conflict",
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
        ["act"] = "WARN",
        ["baseRelevance"] = 0.65,
        ["domain"] = "social",
        ["domainPath"] = "social/conflict",
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
}
