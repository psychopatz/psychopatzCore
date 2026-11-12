-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social",
        ["id"] = "semantic.interaction.world_event.warning.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.world_event.warning.warm",
            ["sourcePath"] = "psdl/dialogue/core_world_event_warning.json#records[1]",
        },
        ["module"] = "PsychopatzCore/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_world_event_warning_warm",
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
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "WORLD_WARNING",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.interaction.world_event.warning.warm.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Stay close. Something's wrong out there.",
                            },
                            ["TL"] = {
                                "Manatili kang malapit. May mali sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.interaction.world_event.warning.warm.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Stick by me, friend. We have trouble brewing outside.",
                            },
                            ["TL"] = {
                                "Dumikit ka sa akin, kaibigan. May namumuong gulo sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.interaction.world_event.warning.warm.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't wander off. Something bad is moving out there.",
                            },
                            ["TL"] = {
                                "Huwag kang lalayo. May masamang gumagalaw sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.interaction.world_event.warning.warm.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Keep close and stay low. I'll protect you.",
                            },
                            ["TL"] = {
                                "Manatiling malapit at yumuko. Poprotektahan kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.interaction.world_event.warning.warm.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Hey, stay behind me until we know what that was.",
                            },
                            ["TL"] = {
                                "Huy, manatili ka sa likod ko hanggang malaman natin 'yon.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.interaction.world_event.warning.warm.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Careful, everyone! Let's look out for one another.",
                            },
                            ["TL"] = {
                                "Mag-ingat ang lahat! Magbantayan tayo sa isa't isa.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.interaction.world_event.warning.warm.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Hold on to each other. Danger is nearby.",
                            },
                            ["TL"] = {
                                "Kumapit sa isa't isa. Malapit lang ang panganib.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.interaction.world_event.warning.warm.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Stay safe by my side. Trouble is coming.",
                            },
                            ["TL"] = {
                                "Manatiling ligtas sa tabi ko. Parating ang panganib.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.interaction.world_event.warning.warm.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Heads up, partner. Whatever happens, we stick together.",
                            },
                            ["TL"] = {
                                "Mag-ingat, kasama. Anuman ang mangyari, sama-sama tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.interaction.world_event.warning.warm.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Keep close. I don't want anyone getting separated.",
                            },
                            ["TL"] = {
                                "Dumikit ka. Ayokong may mahiwalay sa atin.",
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
