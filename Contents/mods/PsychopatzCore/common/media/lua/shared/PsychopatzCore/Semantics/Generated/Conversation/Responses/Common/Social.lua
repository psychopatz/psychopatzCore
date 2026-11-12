-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "accept",
        ["id"] = "semantic.accept",
        ["variants"] = {
            {
                ["fallback"] = "Okay, I'll get started.",
                ["id"] = "semantic.accept.dataset.pending_started",
                ["metadata"] = {
                    ["translationKey"] = "semantic.accept.dataset.pending_started",
                },
                ["priority"] = 1,
                ["templateID"] = "semantic.accept.dataset.pending_started",
                ["when"] = {
                    ["hasPendingRequest"] = true,
                },
            },
            {
                ["fallback"] = "All right. I can take care of that.",
                ["id"] = "semantic.accept.dataset.pending_care",
                ["metadata"] = {
                    ["translationKey"] = "semantic.accept.dataset.pending_care",
                },
                ["priority"] = 1,
                ["templateID"] = "semantic.accept.dataset.pending_care",
                ["when"] = {
                    ["hasPendingRequest"] = true,
                },
            },
        },
    },
    {
        ["domain"] = "compliment",
        ["id"] = "semantic.compliment",
        ["variants"] = {
            {
                ["fallback"] = "That's kind of you. I appreciate it.",
                ["id"] = "semantic.compliment.dataset.kind_of_you",
                ["metadata"] = {
                    ["translationKey"] = "semantic.compliment.dataset.kind_of_you",
                },
                ["templateID"] = "semantic.compliment.dataset.kind_of_you",
            },
            {
                ["fallback"] = "Aw, thank you. That means a lot.",
                ["id"] = "semantic.compliment.dataset.means_a_lot",
                ["metadata"] = {
                    ["translationKey"] = "semantic.compliment.dataset.means_a_lot",
                },
                ["templateID"] = "semantic.compliment.dataset.means_a_lot",
            },
        },
    },
    {
        ["domain"] = "greeting",
        ["id"] = "semantic.greeting",
        ["variants"] = {
            {
                ["fallback"] = "Hey. How are you holding up?",
                ["id"] = "semantic.greeting.dataset.holding_up",
                ["metadata"] = {
                    ["translationKey"] = "semantic.greeting.dataset.holding_up",
                },
                ["templateID"] = "semantic.greeting.dataset.holding_up",
            },
            {
                ["fallback"] = "Good to see you again.",
                ["id"] = "semantic.greeting.dataset.good_to_see",
                ["metadata"] = {
                    ["translationKey"] = "semantic.greeting.dataset.good_to_see",
                },
                ["templateID"] = "semantic.greeting.dataset.good_to_see",
            },
            {
                ["fallback"] = "Hey. How are things going?",
                ["id"] = "semantic.greeting.dataset.how_things",
                ["metadata"] = {
                    ["translationKey"] = "semantic.greeting.dataset.how_things",
                },
                ["templateID"] = "semantic.greeting.dataset.how_things",
            },
        },
    },
    {
        ["domain"] = "offer",
        ["id"] = "semantic.offer",
        ["variants"] = {
            {
                ["fallback"] = "That would help a lot. Could I have some?",
                ["id"] = "semantic.offer.dataset.hungry_share",
                ["metadata"] = {
                    ["translationKey"] = "semantic.offer.dataset.hungry_share",
                },
                ["priority"] = 2,
                ["templateID"] = "semantic.offer.dataset.hungry_share",
                ["when"] = {
                    ["needType"] = "hunger",
                    ["needUrgency"] = {
                        "moderate",
                        "severe",
                        "emergency",
                        "critical",
                    },
                },
            },
            {
                ["fallback"] = "I'd appreciate a bite. Would you share?",
                ["id"] = "semantic.offer.dataset.hungry_appreciate",
                ["metadata"] = {
                    ["translationKey"] = "semantic.offer.dataset.hungry_appreciate",
                },
                ["priority"] = 2,
                ["templateID"] = "semantic.offer.dataset.hungry_appreciate",
                ["when"] = {
                    ["needType"] = "hunger",
                    ["needUrgency"] = {
                        "moderate",
                        "severe",
                        "emergency",
                        "critical",
                    },
                },
            },
        },
    },
    {
        ["domain"] = "refuse",
        ["id"] = "semantic.refuse",
        ["variants"] = {
            {
                ["fallback"] = "I can't take that on right now.",
                ["id"] = "semantic.refuse.dataset.pending_unavailable",
                ["metadata"] = {
                    ["translationKey"] = "semantic.refuse.dataset.pending_unavailable",
                },
                ["priority"] = 1,
                ["templateID"] = "semantic.refuse.dataset.pending_unavailable",
                ["when"] = {
                    ["hasPendingRequest"] = true,
                },
            },
            {
                ["fallback"] = "Not this time. I have enough to manage.",
                ["id"] = "semantic.refuse.dataset.pending_enough",
                ["metadata"] = {
                    ["translationKey"] = "semantic.refuse.dataset.pending_enough",
                },
                ["priority"] = 1,
                ["templateID"] = "semantic.refuse.dataset.pending_enough",
                ["when"] = {
                    ["hasPendingRequest"] = true,
                },
            },
        },
    },
    {
        ["domain"] = "thanks",
        ["id"] = "semantic.thanks",
        ["variants"] = {
            {
                ["fallback"] = "No problem at all.",
                ["id"] = "semantic.thanks.dataset.no_problem",
                ["metadata"] = {
                    ["translationKey"] = "semantic.thanks.dataset.no_problem",
                },
                ["templateID"] = "semantic.thanks.dataset.no_problem",
            },
            {
                ["fallback"] = "Anytime.",
                ["id"] = "semantic.thanks.dataset.anytime",
                ["metadata"] = {
                    ["translationKey"] = "semantic.thanks.dataset.anytime",
                },
                ["templateID"] = "semantic.thanks.dataset.anytime",
            },
            {
                ["fallback"] = "Glad I could help.",
                ["id"] = "semantic.thanks.dataset.glady",
                ["metadata"] = {
                    ["translationKey"] = "semantic.thanks.dataset.glady",
                },
                ["templateID"] = "semantic.thanks.dataset.glady",
            },
        },
    },
}
