-- Generated; do not edit by hand.
return {
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
            ["value"] = "SHARE_MEMORY",
        },
    },
}
