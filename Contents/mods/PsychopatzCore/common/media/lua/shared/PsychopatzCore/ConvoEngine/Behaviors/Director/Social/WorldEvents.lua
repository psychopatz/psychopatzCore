-- Generated; do not edit by hand.
return {
    {
        ["act"] = "WARN_GROUP",
        ["baseRelevance"] = 0.8,
        ["domain"] = "social",
        ["domainPath"] = "social/world_events",
        ["domains"] = {
            {
                ["domain"] = "world_event",
                ["owner"] = "PsychopatzCore",
            },
        },
        ["events"] = {
            {
                ["id"] = "world_event",
                ["kind"] = "world_event",
            },
        },
        ["id"] = "behavior.world_event_warn",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["emote"] = {
                ["id"] = "emote.alert",
            },
            ["flavor"] = {
                ["contentTemplateID"] = "interaction.world_event.warning_flavor",
                ["presentationAct"] = "AMBIENT_FLAVOR",
            },
            ["speech"] = {
                ["contentTemplateID"] = "interaction.world_event.warning",
                ["dialogueAct"] = "WORLD_WARNING",
            },
        },
        ["owner"] = "PsychopatzCore",
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
}
