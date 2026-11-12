-- Generated; do not edit by hand.
return {
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
                ["contentTemplateID"] = "semantic.social.hostile_boundary",
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
