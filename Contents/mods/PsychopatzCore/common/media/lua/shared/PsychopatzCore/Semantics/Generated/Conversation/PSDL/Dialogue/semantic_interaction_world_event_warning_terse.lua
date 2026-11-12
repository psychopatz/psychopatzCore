-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social",
        ["id"] = "semantic.interaction.world_event.warning.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.world_event.warning.terse",
            ["sourcePath"] = "psdl/dialogue/core_world_event_warning.json#records[2]",
        },
        ["module"] = "PsychopatzCore/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_world_event_warning_terse",
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
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "WORLD_WARNING",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.interaction.world_event.warning.terse.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Heads up!",
                            },
                            ["TL"] = {
                                "Mag-ingat!",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.interaction.world_event.warning.terse.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Incoming!",
                            },
                            ["TL"] = {
                                "Paparating!",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.interaction.world_event.warning.terse.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Danger!",
                            },
                            ["TL"] = {
                                "Panganib!",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.interaction.world_event.warning.terse.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Look out!",
                            },
                            ["TL"] = {
                                "Mag-ingat ka!",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.interaction.world_event.warning.terse.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Alert!",
                            },
                            ["TL"] = {
                                "Alerto!",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.interaction.world_event.warning.terse.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Listen!",
                            },
                            ["TL"] = {
                                "Makinig!",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.interaction.world_event.warning.terse.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Trouble!",
                            },
                            ["TL"] = {
                                "Gulo!",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.interaction.world_event.warning.terse.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Ready weapons!",
                            },
                            ["TL"] = {
                                "Ihanda ang armas!",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.interaction.world_event.warning.terse.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Movement!",
                            },
                            ["TL"] = {
                                "May gumagalaw!",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.interaction.world_event.warning.terse.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Cover!",
                            },
                            ["TL"] = {
                                "Magtago!",
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
