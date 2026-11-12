-- Generated; do not edit by hand.
return {
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
                ["contentTemplateID"] = "semantic.social.apology.friendly",
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
}
