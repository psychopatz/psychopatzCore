-- Generated; do not edit by hand.
return {
    {
        ["act"] = "ACKNOWLEDGE_MEMORY",
        ["baseRelevance"] = 0.5,
        ["domain"] = "social",
        ["domainPath"] = "social/acknowledgement",
        ["domains"] = {
            {
                ["domain"] = "memory",
                ["owner"] = "PsychopatzCore",
            },
        },
        ["id"] = "behavior.acknowledge_memory",
        ["memories"] = {
            {
                ["id"] = "shared_memory",
                ["kind"] = "episodic",
            },
        },
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
                ["contentTemplateID"] = "interaction.memory.acknowledge_flavor",
                ["presentationAct"] = "AMBIENT_FLAVOR",
            },
            ["speech"] = {
                ["contentTemplateID"] = "interaction.memory.acknowledge",
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
    {
        ["act"] = "ACKNOWLEDGE_NEWS",
        ["baseRelevance"] = 0.55,
        ["domain"] = "social",
        ["domainPath"] = "social/acknowledgement",
        ["domains"] = {
            {
                ["domain"] = "social",
                ["owner"] = "PsychopatzCore",
            },
        },
        ["id"] = "behavior.acknowledge_news",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["emote"] = {
                ["id"] = "emote.nod",
            },
            ["speech"] = {
                ["contentTemplateID"] = "interaction.news.acknowledge",
                ["dialogueAct"] = "ACKNOWLEDGE",
            },
        },
        ["owner"] = "PsychopatzCore",
        ["requiredCapabilities"] = {
        },
        ["stimuli"] = {
            "NPC_SEMANTIC_ACT",
        },
        ["topics"] = {
            {
                ["domain"] = "social",
                ["id"] = "news",
            },
        },
        ["version"] = 1,
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "SHARE_NEWS",
        },
    },
    {
        ["act"] = "ACKNOWLEDGE_REPLY",
        ["baseRelevance"] = 0.65,
        ["domain"] = "social",
        ["domainPath"] = "social/acknowledgement",
        ["id"] = "behavior.acknowledge_reply",
        ["metadata"] = {
            ["compositionHooksNotApplicableReason"] = "Domain-agnostic conversational reply acknowledgement strategy",
        },
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "social.acknowledged",
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
    {
        ["act"] = "ACKNOWLEDGE_THANKS",
        ["baseRelevance"] = 0.55,
        ["domain"] = "social",
        ["domainPath"] = "social/acknowledgement",
        ["id"] = "behavior.acknowledge_thanks",
        ["metadata"] = {
            ["compositionHooksNotApplicableReason"] = "Domain-agnostic gratitude acknowledgement strategy",
        },
        ["mode"] = "one_shot",
        ["modifiers"] = {
            {
                ["delta"] = 0.1,
                ["reason"] = "sociable_acknowledgement",
                ["when"] = {
                    ["op"] = "gte",
                    ["path"] = "actor.disposition.sociability",
                    ["value"] = 0.65,
                },
            },
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "social.acknowledged",
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
                    ["op"] = "eq",
                    ["path"] = "stimulus.semantic.intent",
                    ["value"] = "THANK",
                },
                {
                    ["op"] = "truthy",
                    ["path"] = "pragmatic.contextualAdmission.admitted",
                },
                {
                    ["op"] = "eq",
                    ["path"] = "pragmatic.contextualAdmission.selected.relation",
                    ["value"] = "gratitude",
                },
            },
        },
    },
}
