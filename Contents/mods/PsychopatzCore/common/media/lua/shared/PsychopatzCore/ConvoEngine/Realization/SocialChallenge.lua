-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_challenge",
        ["domainPath"] = "social_challenge",
        ["id"] = "construction.social.ask_followup",
        ["kind"] = "realization",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "ask_followup",
            ["sourceId"] = "construction.social.ask_followup",
            ["sourcePath"] = "realization/social_challenge/social_ask_followup.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Realization/SocialChallenge",
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
        ["sourceShard"] = "realization/social_challenge/social_ask_followup.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_challenge",
        ["domainPath"] = "social_challenge",
        ["id"] = "construction.social.ask_why",
        ["kind"] = "realization",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "ask_why",
            ["sourceId"] = "construction.social.ask_why",
            ["sourcePath"] = "realization/social_challenge/social_ask_why.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Realization/SocialChallenge",
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
        ["sourceShard"] = "realization/social_challenge/social_ask_why.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_challenge",
        ["domainPath"] = "social_challenge",
        ["id"] = "construction.social.call_bluff",
        ["kind"] = "realization",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "call_bluff",
            ["sourceId"] = "construction.social.call_bluff",
            ["sourcePath"] = "realization/social_challenge/social_call_bluff.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Realization/SocialChallenge",
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
        ["sourceShard"] = "realization/social_challenge/social_call_bluff.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_challenge",
        ["domainPath"] = "social_challenge",
        ["id"] = "construction.social.challenge",
        ["kind"] = "realization",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "challenge",
            ["sourceId"] = "construction.social.challenge",
            ["sourcePath"] = "realization/social_challenge/social_challenge.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Realization/SocialChallenge",
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
        ["sourceShard"] = "realization/social_challenge/social_challenge.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_challenge",
        ["domainPath"] = "social_challenge",
        ["id"] = "construction.social.claim_joke",
        ["kind"] = "realization",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "claim_joke",
            ["sourceId"] = "construction.social.claim_joke",
            ["sourcePath"] = "realization/social_challenge/social_claim_joke.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Realization/SocialChallenge",
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
        ["sourceShard"] = "realization/social_challenge/social_claim_joke.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_challenge",
        ["domainPath"] = "social_challenge",
        ["id"] = "construction.social.dismiss",
        ["kind"] = "realization",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "dismiss",
            ["sourceId"] = "construction.social.dismiss",
            ["sourcePath"] = "realization/social_challenge/social_dismiss.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Realization/SocialChallenge",
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
        ["sourceShard"] = "realization/social_challenge/social_dismiss.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_challenge",
        ["domainPath"] = "social_challenge",
        ["id"] = "construction.social.double_down",
        ["kind"] = "realization",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "double_down",
            ["sourceId"] = "construction.social.double_down",
            ["sourcePath"] = "realization/social_challenge/social_double_down.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Realization/SocialChallenge",
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
        ["sourceShard"] = "realization/social_challenge/social_double_down.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_challenge",
        ["domainPath"] = "social_challenge",
        ["id"] = "construction.social.double_down_direct",
        ["kind"] = "realization",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "double_down_direct",
            ["sourceId"] = "construction.social.double_down_direct",
            ["sourcePath"] = "realization/social_challenge/social_double_down_direct.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Realization/SocialChallenge",
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
        ["sourceShard"] = "realization/social_challenge/social_double_down_direct.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_challenge",
        ["domainPath"] = "social_challenge",
        ["id"] = "construction.social.double_down_stand",
        ["kind"] = "realization",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "double_down_stand",
            ["sourceId"] = "construction.social.double_down_stand",
            ["sourcePath"] = "realization/social_challenge/social_double_down_stand.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Realization/SocialChallenge",
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
        ["sourceShard"] = "realization/social_challenge/social_double_down_stand.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
