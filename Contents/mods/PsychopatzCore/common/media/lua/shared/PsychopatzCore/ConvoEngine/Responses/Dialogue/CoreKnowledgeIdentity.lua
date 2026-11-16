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
                ["translations"] = {
                    ["EN"] = {
                        "I keep my name to myself until I know someone better. What should I call you?",
                    },
                    ["TL"] = {
                        "I keep my name to myself until I know someone better. What should I call you?",
                    },
                },
            },
            {
                ["dialogueAct"] = "IDENTITY",
                ["fallback"] = "Let's get to know each other first. What do people call you?",
                ["id"] = "question.identity.dataset.stranger_alt_2",
                ["templateID"] = "question.identity.stranger_alt_2",
                ["translations"] = {
                    ["EN"] = {
                        "Let's get to know each other first. What do people call you?",
                    },
                    ["TL"] = {
                        "Let's get to know each other first. What do people call you?",
                    },
                },
            },
            {
                ["dialogueAct"] = "IDENTITY",
                ["fallback"] = "I don't trust you enough to share my name. Who are you, really?",
                ["id"] = "question.identity.dataset.wary_alt_1",
                ["priority"] = 2,
                ["templateID"] = "question.identity.wary_alt_1",
                ["translations"] = {
                    ["EN"] = {
                        "I don't trust you enough to share my name. Who are you, really?",
                    },
                    ["TL"] = {
                        "I don't trust you enough to share my name. Who are you, really?",
                    },
                },
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
                ["translations"] = {
                    ["EN"] = {
                        "After that lie, I'm not telling you my name. Tell me the truth about yours.",
                    },
                    ["TL"] = {
                        "After that lie, I'm not telling you my name. Tell me the truth about yours.",
                    },
                },
                ["when"] = {
                    ["identityTrust"] = "untrustworthy",
                },
            },
        },
    },
}
