-- Generated; do not edit by hand.
return {
    {
        ["act"] = "POST_COMBAT_REACTION",
        ["baseRelevance"] = 1,
        ["continuation"] = {
            ["inheritEventRefs"] = true,
            ["inheritFactRefs"] = true,
            ["mode"] = "terminate",
            ["target"] = "none",
        },
        ["domain"] = "social",
        ["id"] = "behavior.scene_post_combat_clear",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "semantic.interaction.scene.post_combat_clear",
                ["dialogueAct"] = "INFORM",
            },
        },
        ["owner"] = "PsychopatzCore",
        ["requiredCapabilities"] = {
            "speech",
        },
        ["stimuli"] = {
            "DANGER_CHANGED",
        },
        ["version"] = 1,
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "POST_COMBAT_CLEAR",
        },
    },
    {
        ["act"] = "TASK_WORK_STATUS",
        ["baseRelevance"] = 1,
        ["continuation"] = {
            ["inheritEventRefs"] = true,
            ["inheritFactRefs"] = true,
            ["mode"] = "terminate",
            ["target"] = "none",
        },
        ["domain"] = "social",
        ["id"] = "behavior.scene_task_work_assigned",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "semantic.interaction.scene.task_work_assigned",
                ["dialogueAct"] = "INFORM",
            },
        },
        ["owner"] = "PsychopatzCore",
        ["requiredCapabilities"] = {
            "speech",
        },
        ["stimuli"] = {
            "TASK_EVENT",
        },
        ["version"] = 1,
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "TASK_WORK_ASSIGNED",
        },
    },
    {
        ["act"] = "TASK_WORK_STATUS",
        ["baseRelevance"] = 1,
        ["continuation"] = {
            ["inheritEventRefs"] = true,
            ["inheritFactRefs"] = true,
            ["mode"] = "terminate",
            ["target"] = "none",
        },
        ["domain"] = "social",
        ["id"] = "behavior.scene_task_work_completed",
        ["mode"] = "one_shot",
        ["modifiers"] = {
        },
        ["outputs"] = {
            ["speech"] = {
                ["contentTemplateID"] = "semantic.interaction.scene.task_work_completed",
                ["dialogueAct"] = "INFORM",
            },
        },
        ["owner"] = "PsychopatzCore",
        ["requiredCapabilities"] = {
            "speech",
        },
        ["stimuli"] = {
            "TASK_EVENT",
        },
        ["version"] = 1,
        ["when"] = {
            ["op"] = "eq",
            ["path"] = "stimulus.semantic.intent",
            ["value"] = "TASK_WORK_COMPLETED",
        },
    },
}
