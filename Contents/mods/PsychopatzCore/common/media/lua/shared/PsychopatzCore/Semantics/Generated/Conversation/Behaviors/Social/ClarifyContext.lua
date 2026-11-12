-- Generated; do not edit by hand.
return {
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
                ["contentTemplateID"] = "semantic.interaction.context.clarify",
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
}
