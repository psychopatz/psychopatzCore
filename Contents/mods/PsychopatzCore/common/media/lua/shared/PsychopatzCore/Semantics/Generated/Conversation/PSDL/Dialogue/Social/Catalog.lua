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
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/Social/Catalog",
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
    {
        ["domain"] = "social",
        ["id"] = "semantic.interaction.world_event.warning.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.world_event.warning.neutral",
            ["sourcePath"] = "psdl/dialogue/core_world_event_warning.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/Social/Catalog",
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
    {
        ["domain"] = "social",
        ["id"] = "semantic.interaction.world_event.warning.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.world_event.warning.terse",
            ["sourcePath"] = "psdl/dialogue/core_world_event_warning.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/Social/Catalog",
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
    {
        ["domain"] = "social",
        ["id"] = "semantic.interaction.world_event.warning.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.world_event.warning.warm",
            ["sourcePath"] = "psdl/dialogue/core_world_event_warning.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/Social/Catalog",
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
    {
        ["domain"] = "social",
        ["id"] = "semantic.interaction.world_event.warning_flavor.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.world_event.warning_flavor.guarded",
            ["sourcePath"] = "psdl/dialogue/core_world_event_warning_flavor.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/Social/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.world_event.warning_flavor",
                ["sourceSurface"] = "content/social/interaction/world_event/warning_flavor.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "AMBIENT_FLAVOR",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.guarded.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC stiffens and watches the approaches.",
                            },
                            ["TL"] = {
                                "Nanigas ang NPC at binantayan ang mga posibleng lapitan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.guarded.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC drops behind cover, weapon ready.",
                            },
                            ["TL"] = {
                                "Bumaba sa kublihan ang NPC, handa ang armas.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.guarded.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC checks their weapon chamber with a grim expression.",
                            },
                            ["TL"] = {
                                "Tiningnan ng NPC ang karga ng armas na may madilim na mukha.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.guarded.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC scans every window and doorway with cold vigilance.",
                            },
                            ["TL"] = {
                                "Sinuri ng NPC ang bawat bintana at pintuan nang may malamig na pag-iingat.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.guarded.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC backs slowly into a defensive choke point.",
                            },
                            ["TL"] = {
                                "Mabagal na umatras ang NPC sa isang depensibong posisyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.guarded.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC eyes their companions to ensure everyone is armed.",
                            },
                            ["TL"] = {
                                "Tiningnan ng NPC ang mga kasama para tiyaking may armas ang lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.guarded.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "A calculating glare fixes on the direction of the noise.",
                            },
                            ["TL"] = {
                                "Isang mapanuring titig ang ibinaling sa direksyon ng ingay.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.guarded.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC prepares for an immediate fight with grim resolve.",
                            },
                            ["TL"] = {
                                "Naghahanda ang NPC sa agarang laban kalakip ang matinding kapasyahan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.guarded.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC's posture turns deadly and guarded.",
                            },
                            ["TL"] = {
                                "Naging mabangis at maingat ang tindig ng NPC.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.guarded.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC remains motionless, waiting for the first sign of hostiles.",
                            },
                            ["TL"] = {
                                "Nanatiling walang katinag-tinag ang NPC, naghihintay sa unang banta.",
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
        ["sourceShard"] = "psdl/dialogue/core_world_event_warning_flavor.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social",
        ["id"] = "semantic.interaction.world_event.warning_flavor.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.world_event.warning_flavor.neutral",
            ["sourcePath"] = "psdl/dialogue/core_world_event_warning_flavor.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/Social/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.world_event.warning_flavor",
                ["sourceSurface"] = "content/social/interaction/world_event/warning_flavor.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "AMBIENT_FLAVOR",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC snaps to attention and scans the area.",
                            },
                            ["TL"] = {
                                "Biglang naging alerto ang NPC at sinuri ang paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC pauses and listens intently to distant noise.",
                            },
                            ["TL"] = {
                                "Huminto ang NPC at taimtim na nakinig sa malayong ingay.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC raises a hand to signal sudden awareness.",
                            },
                            ["TL"] = {
                                "Itinaas ng NPC ang kamay bilang senyas ng biglaang pagka-alerto.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC turns sharply toward the source of the disturbance.",
                            },
                            ["TL"] = {
                                "Mabilis na lumingon ang NPC sa pinagmulan ng kaguluhan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "A tense hush falls as the NPC monitors the perimeter.",
                            },
                            ["TL"] = {
                                "Isang tensiyonadong katahimikan ang bumalot habang nagbabantay ang NPC.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC shifts their stance, ready to react.",
                            },
                            ["TL"] = {
                                "Nagbago ng tindig ang NPC, handang rumesponde.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC points toward the horizon with furrowed brows.",
                            },
                            ["TL"] = {
                                "Itinuro ng NPC ang abot-tanaw habang nakakunot ang noo.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC squints into the distance, assessing the threat.",
                            },
                            ["TL"] = {
                                "Nanliit ang mata ng NPC sa malayo, tinitimbang ang banta.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC signals caution to everyone nearby.",
                            },
                            ["TL"] = {
                                "Nagsenyas ng pag-iingat ang NPC sa lahat ng nasa malapit.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC's posture straightens instantly at the sound.",
                            },
                            ["TL"] = {
                                "Agad na naituwid ang tindig ng NPC nang marinig ang tunog.",
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
        ["sourceShard"] = "psdl/dialogue/core_world_event_warning_flavor.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social",
        ["id"] = "semantic.interaction.world_event.warning_flavor.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.world_event.warning_flavor.terse",
            ["sourcePath"] = "psdl/dialogue/core_world_event_warning_flavor.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/Social/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.world_event.warning_flavor",
                ["sourceSurface"] = "content/social/interaction/world_event/warning_flavor.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "AMBIENT_FLAVOR",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.terse.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC jerks a warning gesture.",
                            },
                            ["TL"] = {
                                "Biglang nagsenyas ng babala ang NPC.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.terse.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "A sharp signal cuts the air.",
                            },
                            ["TL"] = {
                                "Isang mabilis na senyas ang pumunit sa hangin.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.terse.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC stiffens instantly.",
                            },
                            ["TL"] = {
                                "Agad na nanigas ang NPC.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.terse.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "A hand shoots up in alarm.",
                            },
                            ["TL"] = {
                                "Biglang itinaas ang kamay sa pagkaalarma.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.terse.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC's head snaps toward the danger.",
                            },
                            ["TL"] = {
                                "Mabilis na lumingon ang ulo ng NPC sa panganib.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.terse.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "A low hiss demands silence.",
                            },
                            ["TL"] = {
                                "Isang mahinang pahiwatig ang humingi ng katahimikan.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.terse.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC drops into a crouch.",
                            },
                            ["TL"] = {
                                "Bumaba sa pagkakayuko ang NPC.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.terse.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "A quick wave commands cover.",
                            },
                            ["TL"] = {
                                "Isang mabilis na kumpas ang nag-utos na magtago.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.terse.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC draws their weapon in one motion.",
                            },
                            ["TL"] = {
                                "Binunot ng NPC ang armas sa iisang kilos.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.terse.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Eyes wide, the NPC freezes.",
                            },
                            ["TL"] = {
                                "Nanlalaki ang mata, tumigil ang NPC.",
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
        ["sourceShard"] = "psdl/dialogue/core_world_event_warning_flavor.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social",
        ["id"] = "semantic.interaction.world_event.warning_flavor.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.interaction.world_event.warning_flavor.warm",
            ["sourcePath"] = "psdl/dialogue/core_world_event_warning_flavor.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/Social/Catalog",
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
                ["responseTemplateID"] = "semantic.interaction.world_event.warning_flavor",
                ["sourceSurface"] = "content/social/interaction/world_event/warning_flavor.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "AMBIENT_FLAVOR",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.warm.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC motions for the others to stay close.",
                            },
                            ["TL"] = {
                                "Sinenyasan ng NPC ang iba na manatiling malapit.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.warm.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC places a protective hand out, urging allies to gather.",
                            },
                            ["TL"] = {
                                "Inilahad ng NPC ang protektibong kamay, pinapalapit ang mga kasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.warm.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC steps forward to shield their companions from view.",
                            },
                            ["TL"] = {
                                "Humakbang pasulong ang NPC upang harangan sa paningin ang mga kasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.warm.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC gives an urgent, reassuring glance to their partners.",
                            },
                            ["TL"] = {
                                "Nagbigay ng mabilis at nakapagpapanatag na tingin ang NPC sa mga kasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.warm.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC whispers a quiet encouragement while staying watchful.",
                            },
                            ["TL"] = {
                                "Bumulong ng pampalakas ng loob ang NPC habang nananatiling mapagmatyag.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.warm.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC gestures for the group to huddle together safely.",
                            },
                            ["TL"] = {
                                "Nagsenyas ang NPC sa grupo na magsama-sama nang ligtas.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.warm.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC keeps one eye on the threat and one on their friends.",
                            },
                            ["TL"] = {
                                "Bantay ng NPC ang banta habang tinitingnan din ang mga kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.warm.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC gently pulls their ally behind solid cover.",
                            },
                            ["TL"] = {
                                "Marahang hinila ng NPC ang kasama sa likod ng matibay na kublihan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.warm.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC nods determinedly to protect those nearby.",
                            },
                            ["TL"] = {
                                "Determinado at matatag na tumango ang NPC para protektahan ang iba.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.interaction.world_event.warning_flavor.warm.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The NPC stays tightly flanked with their companions.",
                            },
                            ["TL"] = {
                                "Nanatiling nakadikit ang NPC sa tabi ng mga kasama.",
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
        ["sourceShard"] = "psdl/dialogue/core_world_event_warning_flavor.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
