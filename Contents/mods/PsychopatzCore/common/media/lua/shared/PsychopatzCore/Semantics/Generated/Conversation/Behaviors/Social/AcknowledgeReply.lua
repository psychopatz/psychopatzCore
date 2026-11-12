-- Generated; do not edit by hand.
return {
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
                ["contentTemplateID"] = "semantic.social.acknowledged",
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
}
