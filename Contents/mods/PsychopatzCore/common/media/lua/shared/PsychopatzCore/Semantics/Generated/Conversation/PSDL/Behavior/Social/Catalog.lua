-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "social",
        ["id"] = "behavior.world_event_warn",
        ["kind"] = "behavior",
        ["lineage"] = {
            ["sourceId"] = "behavior.world_event_warn",
            ["sourcePath"] = "psdl/behavior/core_world_event_warn.json",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Behavior/Social/Catalog",
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
            ["act"] = "WARN_GROUP",
            ["baseRelevance"] = 0.8,
            ["mode"] = "one_shot",
            ["modifiers"] = {
            },
            ["outputs"] = {
                ["emote"] = {
                    ["id"] = "emote.alert",
                },
                ["flavor"] = {
                    ["contentTemplateID"] = "semantic.interaction.world_event.warning_flavor",
                    ["presentationAct"] = "AMBIENT_FLAVOR",
                },
                ["speech"] = {
                    ["contentTemplateID"] = "semantic.interaction.world_event.warning",
                    ["dialogueAct"] = "WORLD_WARNING",
                },
            },
            ["requiredCapabilities"] = {
            },
            ["stimuli"] = {
                "WORLD_EVENT",
                "DANGER_CHANGED",
            },
            ["version"] = 1,
            ["when"] = {
                ["op"] = "truthy",
                ["path"] = "world.immediateDanger",
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/behavior/core_world_event_warn.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = {
            ["op"] = "truthy",
            ["path"] = "world.immediateDanger",
        },
    },
}
