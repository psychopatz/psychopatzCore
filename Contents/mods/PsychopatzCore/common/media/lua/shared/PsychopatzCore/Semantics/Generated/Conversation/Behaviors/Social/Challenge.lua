-- Generated; do not edit by hand.
return {
    {
        ["act"] = "CHALLENGE",
        ["baseRelevance"] = 0.5,
        ["domain"] = "social",
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
                ["contentTemplateID"] = "semantic.interaction.first_contact.challenge",
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
}
