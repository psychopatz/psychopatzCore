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
                ["contentTemplateID"] = "semantic.interaction.memory.acknowledge_flavor",
                ["presentationAct"] = "AMBIENT_FLAVOR",
            },
            ["speech"] = {
                ["contentTemplateID"] = "semantic.interaction.memory.acknowledge",
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
}
