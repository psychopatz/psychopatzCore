-- Generated; do not edit by hand.
return {
    {
        ["act"] = "ACKNOWLEDGE_NEWS",
        ["baseRelevance"] = 0.55,
        ["domain"] = "social",
        ["id"] = "behavior.acknowledge_news",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["emote"] = {
                ["id"] = "emote.nod",
            },
            ["speech"] = {
                ["contentTemplateID"] = "semantic.interaction.news.acknowledge",
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
            ["value"] = "SHARE_NEWS",
        },
    },
}
