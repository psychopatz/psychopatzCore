-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_affirmation",
        ["domainPath"] = "social_affirmation",
        ["id"] = "construction.social.acknowledge",
        ["kind"] = "realization",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "acknowledge",
            ["sourceId"] = "construction.social.acknowledge",
            ["sourcePath"] = "realization/social_affirmation/social_acknowledge.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Realization/SocialAffirmation",
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
            ["dialogueAct"] = "ACKNOWLEDGE",
            ["strategy"] = "ACKNOWLEDGE",
            ["translations"] = {
                ["EN"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "I hear you.",
                    },
                },
                ["TL"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Naiintindihan ko.",
                    },
                },
            },
            ["type"] = "construction",
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "realization/social_affirmation/social_acknowledge.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_affirmation",
        ["domainPath"] = "social_affirmation",
        ["id"] = "construction.social.agree",
        ["kind"] = "realization",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "agree",
            ["sourceId"] = "construction.social.agree",
            ["sourcePath"] = "realization/social_affirmation/social_agree.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Realization/SocialAffirmation",
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
            ["dialogueAct"] = "AGREE",
            ["strategy"] = "AGREE",
            ["translations"] = {
                ["EN"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Yeah, I agree.",
                    },
                },
                ["TL"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Oo, sang-ayon ako.",
                    },
                },
            },
            ["type"] = "construction",
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "realization/social_affirmation/social_agree.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_affirmation",
        ["domainPath"] = "social_affirmation",
        ["id"] = "construction.social.apologize",
        ["kind"] = "realization",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "apologize",
            ["sourceId"] = "construction.social.apologize",
            ["sourcePath"] = "realization/social_affirmation/social_apologize.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Realization/SocialAffirmation",
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
            ["strategy"] = "APOLOGIZE",
            ["translations"] = {
                ["EN"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "I'm ",
                    },
                    {
                        ["kind"] = "lexeme",
                        ["slot"] = "primary",
                    },
                    {
                        ["kind"] = "literal",
                        ["value"] = ".",
                    },
                },
                ["TL"] = {
                    {
                        ["kind"] = "lexeme",
                        ["slot"] = "primary",
                    },
                    {
                        ["kind"] = "literal",
                        ["value"] = " na.",
                    },
                },
            },
            ["type"] = "construction",
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "realization/social_affirmation/social_apologize.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_affirmation",
        ["domainPath"] = "social_affirmation",
        ["id"] = "construction.social.comfort",
        ["kind"] = "realization",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "comfort",
            ["sourceId"] = "construction.social.comfort",
            ["sourcePath"] = "realization/social_affirmation/social_comfort.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Realization/SocialAffirmation",
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
            ["strategy"] = "COMFORT",
            ["translations"] = {
                ["EN"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "What's really bothering you?",
                    },
                },
                ["TL"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Ano ba talaga ang bumabagabag sa'yo?",
                    },
                },
            },
            ["type"] = "construction",
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "realization/social_affirmation/social_comfort.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_affirmation",
        ["domainPath"] = "social_affirmation",
        ["id"] = "construction.social.deescalate",
        ["kind"] = "realization",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "deescalate",
            ["sourceId"] = "construction.social.deescalate",
            ["sourcePath"] = "realization/social_affirmation/social_deescalate.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Realization/SocialAffirmation",
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
            ["dialogueAct"] = "DEESCALATE",
            ["strategy"] = "DEESCALATE",
            ["translations"] = {
                ["EN"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Let's calm down.",
                    },
                },
                ["TL"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Kumalma tayo.",
                    },
                },
            },
            ["type"] = "construction",
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "realization/social_affirmation/social_deescalate.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_affirmation",
        ["domainPath"] = "social_affirmation",
        ["id"] = "construction.social.disagree",
        ["kind"] = "realization",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "disagree",
            ["sourceId"] = "construction.social.disagree",
            ["sourcePath"] = "realization/social_affirmation/social_disagree.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Realization/SocialAffirmation",
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
            ["dialogueAct"] = "DISAGREE",
            ["strategy"] = "DISAGREE",
            ["translations"] = {
                ["EN"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "No, I don't agree.",
                    },
                },
                ["TL"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Hindi ako sang-ayon.",
                    },
                },
            },
            ["type"] = "construction",
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "realization/social_affirmation/social_disagree.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
