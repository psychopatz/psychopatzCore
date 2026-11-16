-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social_warning_wellbeing",
        ["domainPath"] = "social_warning_wellbeing",
        ["id"] = "construction.social.contextual_accept",
        ["kind"] = "realization",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "contextual_accept",
            ["sourceId"] = "construction.social.contextual_accept",
            ["sourcePath"] = "realization/social_warning_wellbeing/social_contextual_accept.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Realization/SocialWarningWellbeing",
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
            ["dialogueAct"] = "ACCEPT",
            ["strategy"] = "ACCEPT",
            ["translations"] = {
                ["EN"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Yes, I accept.",
                    },
                },
                ["TL"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Oo, pumapayag ako.",
                    },
                },
            },
            ["type"] = "construction",
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "realization/social_warning_wellbeing/social_contextual_accept.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_warning_wellbeing",
        ["domainPath"] = "social_warning_wellbeing",
        ["id"] = "construction.social.contextual_refuse",
        ["kind"] = "realization",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "contextual_refuse",
            ["sourceId"] = "construction.social.contextual_refuse",
            ["sourcePath"] = "realization/social_warning_wellbeing/social_contextual_refuse.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Realization/SocialWarningWellbeing",
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
            ["strategy"] = "REFUSE",
            ["translations"] = {
                ["EN"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "No, I'll pass.",
                    },
                },
                ["TL"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Hindi, salamat na lang.",
                    },
                },
            },
            ["type"] = "construction",
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "realization/social_warning_wellbeing/social_contextual_refuse.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_warning_wellbeing",
        ["domainPath"] = "social_warning_wellbeing",
        ["id"] = "construction.social.contextual_thank",
        ["kind"] = "realization",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "contextual_thank",
            ["sourceId"] = "construction.social.contextual_thank",
            ["sourcePath"] = "realization/social_warning_wellbeing/social_contextual_thank.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Realization/SocialWarningWellbeing",
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
            ["dialogueAct"] = "THANK",
            ["strategy"] = "THANK",
            ["translations"] = {
                ["EN"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Thank you.",
                    },
                },
                ["TL"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Salamat.",
                    },
                },
            },
            ["type"] = "construction",
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "realization/social_warning_wellbeing/social_contextual_thank.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_warning_wellbeing",
        ["domainPath"] = "social_warning_wellbeing",
        ["id"] = "construction.social.warn_consequence",
        ["kind"] = "realization",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "warn_consequence",
            ["sourceId"] = "construction.social.warn_consequence",
            ["sourcePath"] = "realization/social_warning_wellbeing/social_warn_consequence.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Realization/SocialWarningWellbeing",
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
            ["dialogueAct"] = "BOUNDARY_WARNING",
            ["strategy"] = "WARN",
            ["translations"] = {
                ["EN"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Keep talking like that and we're going to have a problem.",
                    },
                },
                ["TL"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Kapag itinuloy mo 'yan, magkakaproblema tayo.",
                    },
                },
            },
            ["type"] = "construction",
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "realization/social_warning_wellbeing/social_warn_consequence.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_warning_wellbeing",
        ["domainPath"] = "social_warning_wellbeing",
        ["id"] = "construction.social.warn_direct",
        ["kind"] = "realization",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "warn_direct",
            ["sourceId"] = "construction.social.warn_direct",
            ["sourcePath"] = "realization/social_warning_wellbeing/social_warn_direct.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Realization/SocialWarningWellbeing",
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
            ["dialogueAct"] = "BOUNDARY_WARNING",
            ["strategy"] = "WARN",
            ["translations"] = {
                ["EN"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Don't talk to me like that.",
                    },
                },
                ["TL"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Huwag mo akong kausapin nang ganyan.",
                    },
                },
            },
            ["type"] = "construction",
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "realization/social_warning_wellbeing/social_warn_direct.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_warning_wellbeing",
        ["domainPath"] = "social_warning_wellbeing",
        ["id"] = "construction.social.warn_mouth",
        ["kind"] = "realization",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "warn_mouth",
            ["sourceId"] = "construction.social.warn_mouth",
            ["sourcePath"] = "realization/social_warning_wellbeing/social_warn_mouth.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Realization/SocialWarningWellbeing",
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
            ["dialogueAct"] = "BOUNDARY_WARNING",
            ["strategy"] = "WARN",
            ["translations"] = {
                ["EN"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Watch your mouth.",
                    },
                },
                ["TL"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Ayusin mo ang pananalita mo.",
                    },
                },
            },
            ["type"] = "construction",
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "realization/social_warning_wellbeing/social_warn_mouth.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_warning_wellbeing",
        ["domainPath"] = "social_warning_wellbeing",
        ["id"] = "construction.social.warn_stop",
        ["kind"] = "realization",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "warn_stop",
            ["sourceId"] = "construction.social.warn_stop",
            ["sourcePath"] = "realization/social_warning_wellbeing/social_warn_stop.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Realization/SocialWarningWellbeing",
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
            ["dialogueAct"] = "BOUNDARY_WARNING",
            ["strategy"] = "WARN",
            ["translations"] = {
                ["EN"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Cut that out.",
                    },
                },
                ["TL"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Tigilan mo 'yan.",
                    },
                },
            },
            ["type"] = "construction",
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "realization/social_warning_wellbeing/social_warn_stop.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_warning_wellbeing",
        ["domainPath"] = "social_warning_wellbeing",
        ["id"] = "construction.social.wellbeing_negative",
        ["kind"] = "realization",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "wellbeing_negative",
            ["sourceId"] = "construction.social.wellbeing_negative",
            ["sourcePath"] = "realization/social_warning_wellbeing/social_wellbeing_negative.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Realization/SocialWarningWellbeing",
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
            ["strategy"] = "WELLBEING_NEGATIVE",
            ["translations"] = {
                ["EN"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "I've had better days.",
                    },
                },
                ["TL"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Medyo mahirap ngayon.",
                    },
                },
            },
            ["type"] = "construction",
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "realization/social_warning_wellbeing/social_wellbeing_negative.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_warning_wellbeing",
        ["domainPath"] = "social_warning_wellbeing",
        ["id"] = "construction.social.wellbeing_neutral",
        ["kind"] = "realization",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "wellbeing_neutral",
            ["sourceId"] = "construction.social.wellbeing_neutral",
            ["sourcePath"] = "realization/social_warning_wellbeing/social_wellbeing_neutral.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Realization/SocialWarningWellbeing",
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
            ["strategy"] = "WELLBEING_NEUTRAL",
            ["translations"] = {
                ["EN"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "I'm doing okay.",
                    },
                },
                ["TL"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Kinakaya ko.",
                    },
                },
            },
            ["type"] = "construction",
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "realization/social_warning_wellbeing/social_wellbeing_neutral.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social_warning_wellbeing",
        ["domainPath"] = "social_warning_wellbeing",
        ["id"] = "construction.social.wellbeing_positive",
        ["kind"] = "realization",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.psdl.v2",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "wellbeing_positive",
            ["sourceId"] = "construction.social.wellbeing_positive",
            ["sourcePath"] = "realization/social_warning_wellbeing/social_wellbeing_positive.json",
            ["sourceSchema"] = "psychopatz.psdl.v2",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Realization/SocialWarningWellbeing",
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
            ["strategy"] = "WELLBEING_POSITIVE",
            ["translations"] = {
                ["EN"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "I'm doing pretty good.",
                    },
                },
                ["TL"] = {
                    {
                        ["kind"] = "literal",
                        ["value"] = "Okay naman ako.",
                    },
                },
            },
            ["type"] = "construction",
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "realization/social_warning_wellbeing/social_wellbeing_positive.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
