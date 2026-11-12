-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_identity",
        ["id"] = "social.core_identity",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "social.core_identity",
            ["sourcePath"] = "psdl/dialogue/core_identity.json",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CoreIdentity/Catalog",
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
            ["metadata"] = {
                ["textNamespace"] = "UI_PNC_Conversation_Suggestion",
            },
            ["offers"] = {
                {
                    ["consumers"] = {
                        "participant",
                    },
                    ["frame"] = {
                        ["intent"] = "QUESTION",
                        ["patternID"] = "pnc.question.identity",
                        ["speechAct"] = "QUESTION",
                        ["subject"] = "IDENTITY",
                        ["topic"] = "identity",
                    },
                    ["id"] = "question.identity",
                    ["label"] = {
                        ["EN"] = {
                            "Ask who they are",
                        },
                        ["TL"] = {
                            "Itanong kung sino siya",
                        },
                    },
                    ["metadata"] = {
                        ["domain"] = "identity",
                        ["order"] = 50,
                    },
                    ["utterance"] = {
                        ["EN"] = {
                            "Who are you?",
                        },
                        ["TL"] = {
                            "Sino ka?",
                        },
                    },
                },
                {
                    ["consumers"] = {
                        "participant",
                    },
                    ["frame"] = {
                        ["intent"] = "QUESTION",
                        ["patternID"] = "pnc.question.identity.faction",
                        ["speechAct"] = "QUESTION",
                        ["subject"] = "IDENTITY_FACTION",
                        ["topic"] = "identity_faction",
                    },
                    ["id"] = "question.identity_faction",
                    ["label"] = {
                        ["EN"] = {
                            "Ask who they are with",
                        },
                        ["TL"] = {
                            "Itanong kung kanino siya kasama",
                        },
                    },
                    ["metadata"] = {
                        ["domain"] = "identity_faction",
                        ["order"] = 53,
                    },
                    ["utterance"] = {
                        ["EN"] = {
                            "Who are you with?",
                        },
                        ["TL"] = {
                            "Sino ang kasama mo?",
                        },
                    },
                },
                {
                    ["consumers"] = {
                        "participant",
                    },
                    ["frame"] = {
                        ["intent"] = "QUESTION",
                        ["patternID"] = "pnc.question.identity.nickname",
                        ["speechAct"] = "QUESTION",
                        ["subject"] = "IDENTITY_NICKNAME",
                        ["topic"] = "identity_nickname",
                    },
                    ["id"] = "question.identity_nickname",
                    ["label"] = {
                        ["EN"] = {
                            "Ask what people call them",
                        },
                        ["TL"] = {
                            "Itanong kung ano ang tawag sa kanya",
                        },
                    },
                    ["metadata"] = {
                        ["domain"] = "identity_nickname",
                        ["order"] = 51,
                    },
                    ["utterance"] = {
                        ["EN"] = {
                            "What do people call you?",
                        },
                        ["TL"] = {
                            "Ano ang tawag sa iyo ng mga tao?",
                        },
                    },
                },
                {
                    ["consumers"] = {
                        "participant",
                    },
                    ["frame"] = {
                        ["intent"] = "QUESTION",
                        ["patternID"] = "pnc.question.identity.surname",
                        ["speechAct"] = "QUESTION",
                        ["subject"] = "IDENTITY_SURNAME",
                        ["topic"] = "identity_surname",
                    },
                    ["id"] = "question.identity_surname",
                    ["label"] = {
                        ["EN"] = {
                            "Ask their surname",
                        },
                        ["TL"] = {
                            "Itanong ang apelyido niya",
                        },
                    },
                    ["metadata"] = {
                        ["domain"] = "identity_surname",
                        ["order"] = 52,
                    },
                    ["utterance"] = {
                        ["EN"] = {
                            "What's your surname?",
                        },
                        ["TL"] = {
                            "Ano ang apelyido mo?",
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_identity.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
