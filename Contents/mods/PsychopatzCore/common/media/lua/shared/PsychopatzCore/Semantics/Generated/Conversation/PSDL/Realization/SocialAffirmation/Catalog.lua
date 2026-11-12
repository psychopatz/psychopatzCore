-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_affirmation",
        ["id"] = "construction.social.acknowledge",
        ["kind"] = "realization",
        ["lineage"] = {
            ["sourceId"] = "construction.social.acknowledge",
            ["sourcePath"] = "psdl/realization/social_affirmation.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Realization/SocialAffirmation/Catalog",
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
        ["sourceShard"] = "psdl/realization/social_affirmation.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_affirmation",
        ["id"] = "construction.social.agree",
        ["kind"] = "realization",
        ["lineage"] = {
            ["sourceId"] = "construction.social.agree",
            ["sourcePath"] = "psdl/realization/social_affirmation.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Realization/SocialAffirmation/Catalog",
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
        ["sourceShard"] = "psdl/realization/social_affirmation.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_affirmation",
        ["id"] = "construction.social.apologize",
        ["kind"] = "realization",
        ["lineage"] = {
            ["sourceId"] = "construction.social.apologize",
            ["sourcePath"] = "psdl/realization/social_affirmation.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Realization/SocialAffirmation/Catalog",
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
        ["sourceShard"] = "psdl/realization/social_affirmation.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_affirmation",
        ["id"] = "construction.social.comfort",
        ["kind"] = "realization",
        ["lineage"] = {
            ["sourceId"] = "construction.social.comfort",
            ["sourcePath"] = "psdl/realization/social_affirmation.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Realization/SocialAffirmation/Catalog",
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
        ["sourceShard"] = "psdl/realization/social_affirmation.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_affirmation",
        ["id"] = "construction.social.deescalate",
        ["kind"] = "realization",
        ["lineage"] = {
            ["sourceId"] = "construction.social.deescalate",
            ["sourcePath"] = "psdl/realization/social_affirmation.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Realization/SocialAffirmation/Catalog",
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
        ["sourceShard"] = "psdl/realization/social_affirmation.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_affirmation",
        ["id"] = "construction.social.disagree",
        ["kind"] = "realization",
        ["lineage"] = {
            ["sourceId"] = "construction.social.disagree",
            ["sourcePath"] = "psdl/realization/social_affirmation.json#records[5]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Realization/SocialAffirmation/Catalog",
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
        ["sourceShard"] = "psdl/realization/social_affirmation.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
