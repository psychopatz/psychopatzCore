-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_identity_closure",
        ["id"] = "construction.social.disclose_name",
        ["kind"] = "realization",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "disclose_name",
            ["sourceId"] = "construction.social.disclose_name",
            ["sourcePath"] = "realization/social_identity_closure/social_disclose_name.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Realization/SocialIdentityClosure",
        ["namespace"] = "construction.social",
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
            ["dialogueAct"] = "INFORM",
            ["strategy"] = "DISCLOSE_NAME",
            ["translations"] = {
                ["EN"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "I'm ",
                    },
                    {
                        ["kind"] = "slot",
                        ["slot"] = "name",
                    },
                    {
                        ["kind"] = "literal",
                        ["value"] = ".",
                    },
                },
                ["TL"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Ako si ",
                    },
                    {
                        ["kind"] = "slot",
                        ["slot"] = "name",
                    },
                    {
                        ["kind"] = "literal",
                        ["value"] = ".",
                    },
                },
            },
            ["type"] = "construction",
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "realization/social_identity_closure/social_disclose_name.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_identity_closure",
        ["id"] = "construction.social.end_conversation_done",
        ["kind"] = "realization",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "end_conversation_done",
            ["sourceId"] = "construction.social.end_conversation_done",
            ["sourcePath"] = "realization/social_identity_closure/social_end_conversation_done.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Realization/SocialIdentityClosure",
        ["namespace"] = "construction.social",
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
            ["dialogueAct"] = "END_CONVERSATION",
            ["strategy"] = "END_CONVERSATION",
            ["translations"] = {
                ["EN"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "We're done here.",
                    },
                },
                ["TL"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Tapos na tayo rito.",
                    },
                },
            },
            ["type"] = "construction",
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "realization/social_identity_closure/social_end_conversation_done.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_identity_closure",
        ["id"] = "construction.social.end_conversation_withdraw",
        ["kind"] = "realization",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "end_conversation_withdraw",
            ["sourceId"] = "construction.social.end_conversation_withdraw",
            ["sourcePath"] = "realization/social_identity_closure/social_end_conversation_withdraw.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Realization/SocialIdentityClosure",
        ["namespace"] = "construction.social",
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
            ["dialogueAct"] = "END_CONVERSATION",
            ["strategy"] = "END_CONVERSATION",
            ["translations"] = {
                ["EN"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "I'm done with this.",
                    },
                },
                ["TL"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Ayoko na nito.",
                    },
                },
            },
            ["type"] = "construction",
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "realization/social_identity_closure/social_end_conversation_withdraw.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_identity_closure",
        ["id"] = "construction.social.mirror_retort",
        ["kind"] = "realization",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "mirror_retort",
            ["sourceId"] = "construction.social.mirror_retort",
            ["sourcePath"] = "realization/social_identity_closure/social_mirror_retort.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Realization/SocialIdentityClosure",
        ["namespace"] = "construction.social",
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
            ["dialogueAct"] = "RETORT",
            ["strategy"] = "MIRROR",
            ["translations"] = {
                ["EN"] = {
                    {
                        ["kind"] = "lexeme",
                        ["slot"] = "primary",
                    },
                    {
                        ["kind"] = "literal",
                        ["value"] = " you too.",
                    },
                },
                ["TL"] = {
                    {
                        ["kind"] = "lexeme",
                        ["slot"] = "primary",
                    },
                    {
                        ["kind"] = "literal",
                        ["value"] = " rin.",
                    },
                },
            },
            ["type"] = "construction",
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "realization/social_identity_closure/social_mirror_retort.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_identity_closure",
        ["id"] = "construction.social.mirror_retort_challenge",
        ["kind"] = "realization",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "mirror_retort_challenge",
            ["sourceId"] = "construction.social.mirror_retort_challenge",
            ["sourcePath"] = "realization/social_identity_closure/social_mirror_retort_challenge.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Realization/SocialIdentityClosure",
        ["namespace"] = "construction.social",
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
            ["dialogueAct"] = "RETORT",
            ["strategy"] = "MIRROR",
            ["translations"] = {
                ["EN"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Yeah? ",
                    },
                    {
                        ["kind"] = "lexeme",
                        ["slot"] = "primary",
                    },
                    {
                        ["kind"] = "literal",
                        ["value"] = " you too.",
                    },
                },
                ["TL"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Ha? ",
                    },
                    {
                        ["kind"] = "lexeme",
                        ["slot"] = "primary",
                    },
                    {
                        ["kind"] = "literal",
                        ["value"] = " rin.",
                    },
                },
            },
            ["type"] = "construction",
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "realization/social_identity_closure/social_mirror_retort_challenge.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_identity_closure",
        ["id"] = "construction.social.refuse_identity",
        ["kind"] = "realization",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "refuse_identity",
            ["sourceId"] = "construction.social.refuse_identity",
            ["sourcePath"] = "realization/social_identity_closure/social_refuse_identity.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PNC/ConvoEngine/Realization/SocialIdentityClosure",
        ["namespace"] = "construction.social",
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
            ["dialogueAct"] = "REFUSE",
            ["strategy"] = "REFUSE_IDENTITY",
            ["translations"] = {
                ["EN"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "I'd rather not say.",
                    },
                },
                ["TL"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Ayoko munang sabihin.",
                    },
                },
            },
            ["type"] = "construction",
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "realization/social_identity_closure/social_refuse_identity.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
