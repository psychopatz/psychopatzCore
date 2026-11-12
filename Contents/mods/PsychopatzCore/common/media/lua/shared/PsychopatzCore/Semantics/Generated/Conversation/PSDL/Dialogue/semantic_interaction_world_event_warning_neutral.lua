-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social",
        ["id"] = "semantic.interaction.world_event.warning.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.world_event.warning.neutral",
            ["sourcePath"] = "psdl/dialogue/core_world_event_warning.json#records[0]",
        },
        ["module"] = "PsychopatzCore/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_world_event_warning_neutral",
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
                ["category"] = "psychopatzcore:world_event",
                ["responseTemplateID"] = "semantic.interaction.world_event.warning",
                ["sourceSurface"] = "content/social/interaction/world_event/warning.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "WORLD_WARNING",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.interaction.world_event.warning.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Heads up. Something's wrong out there.",
                            },
                            ["TL"] = {
                                "Mag-ingat. May mali sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.interaction.world_event.warning.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Look alive. The situation outside is shifting.",
                            },
                            ["TL"] = {
                                "Maging alerto. Nagbabago ang sitwasyon sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.interaction.world_event.warning.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Pay attention. We have unexpected movement outside.",
                            },
                            ["TL"] = {
                                "Makinig ka. May di-inaasahang galaw sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.interaction.world_event.warning.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Warning. Something big is happening nearby.",
                            },
                            ["TL"] = {
                                "Babala. May malaking nangyayari sa malapit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.interaction.world_event.warning.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Heads up, everyone. Check your gear.",
                            },
                            ["TL"] = {
                                "Mag-ingat ang lahat. Suriin ang mga gamit niyo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.interaction.world_event.warning.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Listen close. An event is unfolding out there.",
                            },
                            ["TL"] = {
                                "Makinig nang mabuti. May kaganapan sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.interaction.world_event.warning.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Alert. We need to be ready for trouble.",
                            },
                            ["TL"] = {
                                "Alerto. Kailangan nating maging handa sa gulo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.interaction.world_event.warning.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Keep your eyes open. That sound wasn't normal.",
                            },
                            ["TL"] = {
                                "Buksan ang mga mata. Hindi karaniwan ang tunog na 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.interaction.world_event.warning.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Stay sharp. The perimeter is showing activity.",
                            },
                            ["TL"] = {
                                "Maging alerto. May aktibidad sa paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.interaction.world_event.warning.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Heads up. Let's not get caught unprepared.",
                            },
                            ["TL"] = {
                                "Mag-ingat. Huwag tayong mahuling walang paghahanda.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_world_event_warning.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
