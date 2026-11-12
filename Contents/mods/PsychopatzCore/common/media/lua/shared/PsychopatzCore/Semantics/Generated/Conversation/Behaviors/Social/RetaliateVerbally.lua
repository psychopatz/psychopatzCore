-- Generated; do not edit by hand.
return {
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
                ["contentTemplateID"] = "semantic.interaction.argument.retaliate",
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
}
