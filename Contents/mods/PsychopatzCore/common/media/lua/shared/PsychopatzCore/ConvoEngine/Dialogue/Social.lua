-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social",
        ["domainPath"] = "social",
        ["exchangeFamily"] = {
            ["familyID"] = "interaction.world_event.warning",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "Heads up. Something's wrong out there.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.interaction.world_event.warning.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Stay sharp. We've got trouble.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.interaction.world_event.warning.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Heads up!",
                                ["id"] = "terse",
                                ["templateID"] = "convo.interaction.world_event.warning.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "Stay close. Something's wrong out there.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.interaction.world_event.warning.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "interaction.world_event",
            ["textRoles"] = {
                {
                    ["fallback"] = "Heads up. Something's wrong out there.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.world_event.warning.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Stay sharp. We've got trouble.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.world_event.warning.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "Heads up!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.world_event.warning.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "Stay close. Something's wrong out there.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.world_event.warning.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "interaction.world_event.warning",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "warning",
            ["sourceId"] = "interaction.world_event.warning",
            ["sourcePath"] = "dialogue/social/interaction_world_event_warning.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/Social",
        ["namespace"] = "interaction.world_event",
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
            ["domains"] = {
                {
                    ["domain"] = "world",
                    ["owner"] = "PsychopatzCore",
                },
            },
            ["events"] = {
                {
                    ["id"] = "world_event",
                    ["kind"] = "world_event",
                },
            },
            ["metadata"] = {
                ["category"] = "psychopatzcore:world_event",
                ["responseAct"] = "WORLD_WARNING",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "Heads up. Something's wrong out there.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "Stay sharp. We've got trouble.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "Heads up!",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "Stay close. Something's wrong out there.",
                                ["id"] = "warm",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "world",
                    ["id"] = "world_event",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "WORLD_WARNING",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "interaction.world_event.warning",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Heads up. Something's wrong out there.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.interaction.world_event.warning.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
            ["target"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "target",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/social/interaction_world_event_warning.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Heads up. Something's wrong out there.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.world_event.warning.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Stay sharp. We've got trouble.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.world_event.warning.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "Heads up!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.world_event.warning.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "Stay close. Something's wrong out there.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.world_event.warning.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "social",
        ["domainPath"] = "social",
        ["exchangeFamily"] = {
            ["familyID"] = "interaction.world_event.warning_flavor",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "The NPC snaps to attention and scans the area.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.interaction.world_event.warning_flavor.say.1.neutral",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "The NPC stiffens and watches the approaches.",
                                ["id"] = "guarded",
                                ["templateID"] = "convo.interaction.world_event.warning_flavor.say.1.guarded",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "The NPC jerks a warning gesture.",
                                ["id"] = "terse",
                                ["templateID"] = "convo.interaction.world_event.warning_flavor.say.1.terse",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                            {
                                ["fallback"] = "The NPC motions for the others to stay close.",
                                ["id"] = "warm",
                                ["templateID"] = "convo.interaction.world_event.warning_flavor.say.1.warm",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 10,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "interaction.world_event",
            ["textRoles"] = {
                {
                    ["fallback"] = "The NPC snaps to attention and scans the area.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.world_event.warning_flavor.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "The NPC stiffens and watches the approaches.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.world_event.warning_flavor.say.1.guarded",
                    ["variantID"] = "guarded",
                },
                {
                    ["fallback"] = "The NPC jerks a warning gesture.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.world_event.warning_flavor.say.1.terse",
                    ["variantID"] = "terse",
                },
                {
                    ["fallback"] = "The NPC motions for the others to stay close.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.interaction.world_event.warning_flavor.say.1.warm",
                    ["variantID"] = "warm",
                },
            },
        },
        ["id"] = "interaction.world_event.warning_flavor",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "warning_flavor",
            ["sourceId"] = "interaction.world_event.warning_flavor",
            ["sourcePath"] = "dialogue/social/interaction_world_event_warning_flavor.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/Social",
        ["namespace"] = "interaction.world_event",
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
            ["domains"] = {
                {
                    ["domain"] = "world",
                    ["owner"] = "PsychopatzCore",
                },
            },
            ["events"] = {
                {
                    ["id"] = "world_event",
                    ["kind"] = "world_event",
                },
            },
            ["metadata"] = {
                ["category"] = "psychopatzcore:world_event",
                ["responseAct"] = "AMBIENT_FLAVOR",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "The NPC snaps to attention and scans the area.",
                                ["id"] = "neutral",
                            },
                            {
                                ["fallback"] = "The NPC stiffens and watches the approaches.",
                                ["id"] = "guarded",
                            },
                            {
                                ["fallback"] = "The NPC jerks a warning gesture.",
                                ["id"] = "terse",
                            },
                            {
                                ["fallback"] = "The NPC motions for the others to stay close.",
                                ["id"] = "warm",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "world",
                    ["id"] = "world_event",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "AMBIENT_FLAVOR",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "interaction.world_event.warning_flavor",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "The NPC snaps to attention and scans the area.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.interaction.world_event.warning_flavor.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
            ["target"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "target",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/social/interaction_world_event_warning_flavor.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "The NPC snaps to attention and scans the area.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.world_event.warning_flavor.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "The NPC stiffens and watches the approaches.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.world_event.warning_flavor.say.1.guarded",
                ["variantID"] = "guarded",
            },
            {
                ["fallback"] = "The NPC jerks a warning gesture.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.world_event.warning_flavor.say.1.terse",
                ["variantID"] = "terse",
            },
            {
                ["fallback"] = "The NPC motions for the others to stay close.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.interaction.world_event.warning_flavor.say.1.warm",
                ["variantID"] = "warm",
            },
        },
        ["when"] = nil,
    },
}
