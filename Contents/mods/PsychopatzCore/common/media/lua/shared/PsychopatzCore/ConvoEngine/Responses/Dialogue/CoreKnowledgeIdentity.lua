-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "identity",
        ["id"] = "question.identity",
        ["owner"] = "PsychopatzCore",
        ["variants"] = {
            {
                ["dialogueAct"] = "IDENTITY",
                ["fallback"] = "I keep my name to myself until I know someone better. What should I call you?",
                ["id"] = "question.identity.dataset.stranger_alt_1",
                ["templateID"] = "question.identity.stranger_alt_1",
            },
            {
                ["dialogueAct"] = "IDENTITY",
                ["fallback"] = "Let's get to know each other first. What do people call you?",
                ["id"] = "question.identity.dataset.stranger_alt_2",
                ["templateID"] = "question.identity.stranger_alt_2",
            },
            {
                ["dialogueAct"] = "IDENTITY",
                ["fallback"] = "I don't trust you enough to share my name. Who are you, really?",
                ["id"] = "question.identity.dataset.wary_alt_1",
                ["priority"] = 2,
                ["templateID"] = "question.identity.wary_alt_1",
                ["when"] = {
                    ["identityTrust"] = "untrustworthy",
                },
            },
            {
                ["dialogueAct"] = "IDENTITY",
                ["fallback"] = "After that lie, I'm not telling you my name. Tell me the truth about yours.",
                ["id"] = "question.identity.dataset.wary_alt_2",
                ["priority"] = 2,
                ["templateID"] = "question.identity.wary_alt_2",
                ["when"] = {
                    ["identityTrust"] = "untrustworthy",
                },
            },
        },
    },
}
