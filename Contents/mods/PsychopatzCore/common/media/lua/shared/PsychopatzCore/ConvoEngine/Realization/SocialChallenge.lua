-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_challenge",
        ["id"] = "construction.social.ask_followup",
        ["kind"] = "realization",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "construction.social.ask_followup",
            ["sourcePath"] = "psdl/realization/social_challenge.json#records[0]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Realization/SocialChallenge",
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
            ["dialogueAct"] = "QUESTION",
            ["strategy"] = "ASK_FOLLOWUP",
            ["translations"] = {
                ["EN"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "What do you mean?",
                    },
                },
                ["TL"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Ano'ng ibig mong sabihin?",
                    },
                },
            },
            ["type"] = "construction",
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/realization/social_challenge.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_challenge",
        ["id"] = "construction.social.ask_why",
        ["kind"] = "realization",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "construction.social.ask_why",
            ["sourcePath"] = "psdl/realization/social_challenge.json#records[1]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Realization/SocialChallenge",
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
            ["dialogueAct"] = "QUESTION",
            ["strategy"] = "ASK_WHY",
            ["translations"] = {
                ["EN"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Why would you say that?",
                    },
                },
                ["TL"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Bakit mo sinabi 'yan?",
                    },
                },
            },
            ["type"] = "construction",
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/realization/social_challenge.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_challenge",
        ["id"] = "construction.social.call_bluff",
        ["kind"] = "realization",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "construction.social.call_bluff",
            ["sourcePath"] = "psdl/realization/social_challenge.json#records[2]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Realization/SocialChallenge",
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
            ["dialogueAct"] = "HOSTILE_REMARK",
            ["strategy"] = "CALL_BLUFF",
            ["translations"] = {
                ["EN"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "You're all talk.",
                    },
                },
                ["TL"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Puro salita ka lang.",
                    },
                },
            },
            ["type"] = "construction",
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/realization/social_challenge.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_challenge",
        ["id"] = "construction.social.challenge",
        ["kind"] = "realization",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "construction.social.challenge",
            ["sourcePath"] = "psdl/realization/social_challenge.json#records[3]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Realization/SocialChallenge",
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
            ["dialogueAct"] = "CHALLENGE",
            ["strategy"] = "CHALLENGE",
            ["translations"] = {
                ["EN"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Say that again.",
                    },
                },
                ["TL"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Ulitin mo nga.",
                    },
                },
            },
            ["type"] = "construction",
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/realization/social_challenge.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_challenge",
        ["id"] = "construction.social.claim_joke",
        ["kind"] = "realization",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "construction.social.claim_joke",
            ["sourcePath"] = "psdl/realization/social_challenge.json#records[4]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Realization/SocialChallenge",
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
            ["dialogueAct"] = "APOLOGIZE",
            ["strategy"] = "CLAIM_JOKE",
            ["translations"] = {
                ["EN"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "I was joking.",
                    },
                },
                ["TL"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Nagbibiro lang ako.",
                    },
                },
            },
            ["type"] = "construction",
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/realization/social_challenge.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_challenge",
        ["id"] = "construction.social.dismiss",
        ["kind"] = "realization",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "construction.social.dismiss",
            ["sourcePath"] = "psdl/realization/social_challenge.json#records[5]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Realization/SocialChallenge",
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
            ["dialogueAct"] = "DISMISS",
            ["strategy"] = "DISMISS",
            ["translations"] = {
                ["EN"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Whatever.",
                    },
                },
                ["TL"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Bahala ka.",
                    },
                },
            },
            ["type"] = "construction",
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/realization/social_challenge.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_challenge",
        ["id"] = "construction.social.double_down",
        ["kind"] = "realization",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "construction.social.double_down",
            ["sourcePath"] = "psdl/realization/social_challenge.json#records[6]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Realization/SocialChallenge",
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
            ["dialogueAct"] = "HOSTILE_REMARK",
            ["strategy"] = "DOUBLE_DOWN",
            ["translations"] = {
                ["EN"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Yeah, I meant it.",
                    },
                },
                ["TL"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Oo, sinadya ko 'yon.",
                    },
                },
            },
            ["type"] = "construction",
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/realization/social_challenge.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_challenge",
        ["id"] = "construction.social.double_down_direct",
        ["kind"] = "realization",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "construction.social.double_down_direct",
            ["sourcePath"] = "psdl/realization/social_challenge.json#records[7]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Realization/SocialChallenge",
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
            ["dialogueAct"] = "HOSTILE_REMARK",
            ["strategy"] = "DOUBLE_DOWN",
            ["translations"] = {
                ["EN"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "I meant what I said.",
                    },
                },
                ["TL"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Sinadya ko talaga 'yon.",
                    },
                },
            },
            ["type"] = "construction",
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/realization/social_challenge.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_challenge",
        ["id"] = "construction.social.double_down_stand",
        ["kind"] = "realization",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "construction.social.double_down_stand",
            ["sourcePath"] = "psdl/realization/social_challenge.json#records[8]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Realization/SocialChallenge",
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
            ["dialogueAct"] = "HOSTILE_REMARK",
            ["strategy"] = "DOUBLE_DOWN",
            ["translations"] = {
                ["EN"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "I stand by it.",
                    },
                },
                ["TL"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Paninindigan ko 'yon.",
                    },
                },
            },
            ["type"] = "construction",
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/realization/social_challenge.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
