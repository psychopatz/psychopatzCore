-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_identity_closure",
        ["id"] = "construction.social.disclose_name",
        ["kind"] = "realization",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "construction.social.disclose_name",
            ["sourcePath"] = "psdl/realization/social_identity_closure.json#records[0]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Realization/SocialIdentityClosure",
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
        ["sourceShard"] = "psdl/realization/social_identity_closure.json",
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
            ["migrationReadOnly"] = true,
            ["sourceId"] = "construction.social.end_conversation_done",
            ["sourcePath"] = "psdl/realization/social_identity_closure.json#records[1]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Realization/SocialIdentityClosure",
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
        ["sourceShard"] = "psdl/realization/social_identity_closure.json",
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
            ["migrationReadOnly"] = true,
            ["sourceId"] = "construction.social.end_conversation_withdraw",
            ["sourcePath"] = "psdl/realization/social_identity_closure.json#records[2]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Realization/SocialIdentityClosure",
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
        ["sourceShard"] = "psdl/realization/social_identity_closure.json",
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
            ["migrationReadOnly"] = true,
            ["sourceId"] = "construction.social.mirror_retort",
            ["sourcePath"] = "psdl/realization/social_identity_closure.json#records[3]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Realization/SocialIdentityClosure",
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
        ["sourceShard"] = "psdl/realization/social_identity_closure.json",
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
            ["migrationReadOnly"] = true,
            ["sourceId"] = "construction.social.mirror_retort_challenge",
            ["sourcePath"] = "psdl/realization/social_identity_closure.json#records[4]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Realization/SocialIdentityClosure",
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
        ["sourceShard"] = "psdl/realization/social_identity_closure.json",
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
            ["migrationReadOnly"] = true,
            ["sourceId"] = "construction.social.refuse_identity",
            ["sourcePath"] = "psdl/realization/social_identity_closure.json#records[5]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Realization/SocialIdentityClosure",
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
        ["sourceShard"] = "psdl/realization/social_identity_closure.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
