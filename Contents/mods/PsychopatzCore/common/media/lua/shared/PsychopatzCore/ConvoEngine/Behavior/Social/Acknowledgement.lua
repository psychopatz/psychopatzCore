-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social",
        ["domainPath"] = "social/acknowledgement",
        ["id"] = "behavior.acknowledge_memory",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "acknowledge_memory",
            ["sourceId"] = "behavior.acknowledge_memory",
            ["sourcePath"] = "behavior/social/acknowledgement/acknowledge_memory.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Behavior/Social/Acknowledgement",
        ["namespace"] = "behavior",
        ["owner"] = "PsychopatzCore",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["act"] = "ACKNOWLEDGE_MEMORY",
            ["baseRelevance"] = 0.5,
            ["domains"] = {
                {
                    ["domain"] = "memory",
                    ["owner"] = "PsychopatzCore",
                },
            },
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
            ["requiredCapabilities"] = {
            },
            ["stimuli"] = {
                "NPC_SEMANTIC_ACT",
            },
            ["version"] = 1,
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/social/acknowledgement/acknowledge_memory.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "SHARE_MEMORY",
        },
    },
    {
        ["domain"] = "social",
        ["domainPath"] = "social/acknowledgement",
        ["id"] = "behavior.acknowledge_news",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "acknowledge_news",
            ["sourceId"] = "behavior.acknowledge_news",
            ["sourcePath"] = "behavior/social/acknowledgement/acknowledge_news.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Behavior/Social/Acknowledgement",
        ["namespace"] = "behavior",
        ["owner"] = "PsychopatzCore",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["act"] = "ACKNOWLEDGE_NEWS",
            ["baseRelevance"] = 0.55,
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "PsychopatzCore",
                },
            },
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
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/social/acknowledgement/acknowledge_news.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "SHARE_NEWS",
        },
    },
    {
        ["domain"] = "social",
        ["domainPath"] = "social/acknowledgement",
        ["id"] = "behavior.acknowledge_reply",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "acknowledge_reply",
            ["sourceId"] = "behavior.acknowledge_reply",
            ["sourcePath"] = "behavior/social/acknowledgement/acknowledge_reply.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Behavior/Social/Acknowledgement",
        ["namespace"] = "behavior",
        ["owner"] = "PsychopatzCore",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["act"] = "ACKNOWLEDGE_REPLY",
            ["baseRelevance"] = 0.65,
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
            ["requiredCapabilities"] = {
                "speech",
            },
            ["stimuli"] = {
                "HUMAN_UTTERANCE",
                "NPC_SEMANTIC_ACT",
            },
            ["version"] = 1,
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/social/acknowledgement/acknowledge_reply.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
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
        ["domain"] = "social",
        ["domainPath"] = "social/acknowledgement",
        ["id"] = "behavior.acknowledge_thanks",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "acknowledge_thanks",
            ["sourceId"] = "behavior.acknowledge_thanks",
            ["sourcePath"] = "behavior/social/acknowledgement/acknowledge_thanks.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Behavior/Social/Acknowledgement",
        ["namespace"] = "behavior",
        ["owner"] = "PsychopatzCore",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["act"] = "ACKNOWLEDGE_THANKS",
            ["baseRelevance"] = 0.55,
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
            ["requiredCapabilities"] = {
                "speech",
            },
            ["stimuli"] = {
                "HUMAN_UTTERANCE",
                "NPC_SEMANTIC_ACT",
            },
            ["version"] = 1,
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "behavior/social/acknowledgement/acknowledge_thanks.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
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
