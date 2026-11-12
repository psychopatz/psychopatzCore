-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social",
        ["id"] = "semantic.interaction.world_event.warning.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.world_event.warning.guarded",
            ["sourcePath"] = "psdl/dialogue/core_world_event_warning.json#records[3]",
        },
        ["module"] = "PsychopatzCore/Semantics/Generated/Conversation/PSDL/Dialogue/semantic_interaction_world_event_warning_guarded",
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
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "WORLD_WARNING",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.interaction.world_event.warning.guarded.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Stay sharp. We've got trouble.",
                            },
                            ["TL"] = {
                                "Mag-ingat ka. May problema tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.interaction.world_event.warning.guarded.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Weapons drawn, now. Danger outside.",
                            },
                            ["TL"] = {
                                "Ibunot ang armas, ngayon na. May panganib sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.interaction.world_event.warning.guarded.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Shut up and listen. Something is coming.",
                            },
                            ["TL"] = {
                                "Tumahimik at makinig. May paparating.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.interaction.world_event.warning.guarded.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Lock the doors and watch every angle.",
                            },
                            ["TL"] = {
                                "Ikandado ang pinto at bantayan ang bawat sulok.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.interaction.world_event.warning.guarded.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "If it moves through that entrance, put it down.",
                            },
                            ["TL"] = {
                                "Kapag may gumalaw sa lagusang 'yan, patumbahin mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.interaction.world_event.warning.guarded.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Trouble's coming. Don't freeze up on me.",
                            },
                            ["TL"] = {
                                "Parating ang gulo. Huwag kang tatanga-tanga.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.interaction.world_event.warning.guarded.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Get into defensive positions immediately.",
                            },
                            ["TL"] = {
                                "Pumwesto sa depensa agad-agad.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.interaction.world_event.warning.guarded.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Keep quiet. You don't want to draw them here.",
                            },
                            ["TL"] = {
                                "Manahimik ka. Ayaw mong maakit sila rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.interaction.world_event.warning.guarded.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Threat incoming. Expect the worst.",
                            },
                            ["TL"] = {
                                "Banta parating. Asahan ang pinakamasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.interaction.world_event.warning.guarded.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Eyes on the perimeter. Shoot on sight.",
                            },
                            ["TL"] = {
                                "Bantayan ang paligid. Barilin agad kapag nakita.",
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
