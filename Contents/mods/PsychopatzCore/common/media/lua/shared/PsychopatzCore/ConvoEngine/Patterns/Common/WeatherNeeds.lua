-- Generated; do not edit by hand.
return {
    {
        ["confidence"] = 0.99,
        ["domain"] = "clarify",
        ["emit"] = {
            ["extensions"] = {
                ["dialogueFollowUp"] = "NEEDS_QUANTITY",
                ["topic"] = "NEEDS",
            },
            ["intent"] = "CLARIFY",
            ["speechAct"] = "CLARIFY",
            ["subject"] = "NEEDS",
        },
        ["id"] = "pnc.dataset.clarify.needs.what_item_do_you_mean",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "what",
            },
            {
                ["kind"] = "literal",
                ["value"] = "item",
            },
            {
                ["kind"] = "literal",
                ["value"] = "do",
            },
            {
                ["kind"] = "literal",
                ["value"] = "you",
            },
            {
                ["kind"] = "literal",
                ["value"] = "mean",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "ANY_ITEM",
                ["dialogueState"] = "NEEDS_QUANTITY",
                ["sourceRefs"] = {
                    "MASSIVE",
                    "SGD",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "MASSIVE",
                "SGD",
            },
        },
        ["priority"] = 167,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "clarify",
        ["emit"] = {
            ["extensions"] = {
                ["dialogueFollowUp"] = "NEEDS_QUANTITY",
                ["topic"] = "NEEDS",
            },
            ["intent"] = "CLARIFY",
            ["speechAct"] = "CLARIFY",
            ["subject"] = "NEEDS",
        },
        ["id"] = "pnc.dataset.clarify.needs.which_item_do_you_mean",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "which",
            },
            {
                ["kind"] = "literal",
                ["value"] = "item",
            },
            {
                ["kind"] = "literal",
                ["value"] = "do",
            },
            {
                ["kind"] = "literal",
                ["value"] = "you",
            },
            {
                ["kind"] = "literal",
                ["value"] = "mean",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "ANY_ITEM",
                ["dialogueState"] = "NEEDS_QUANTITY",
                ["sourceRefs"] = {
                    "MASSIVE",
                    "SGD",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "MASSIVE",
                "SGD",
            },
        },
        ["priority"] = 167,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "massive",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "WEATHER",
        },
        ["id"] = "pnc.dataset.massive.weather.is_it_currently_snowing",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "is",
            },
            {
                ["kind"] = "literal",
                ["value"] = "it",
            },
            {
                ["kind"] = "literal",
                ["value"] = "currently",
            },
            {
                ["kind"] = "literal",
                ["value"] = "snowing",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "WEATHER",
                ["dialogueState"] = "WEATHER_TOPIC",
                ["sourceRefs"] = {
                    "MASSIVE",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "MASSIVE",
            },
        },
        ["priority"] = 166,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "massive",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "WEATHER",
        },
        ["id"] = "pnc.dataset.massive.weather.is_it_still_snowing",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "is",
            },
            {
                ["kind"] = "literal",
                ["value"] = "it",
            },
            {
                ["kind"] = "literal",
                ["value"] = "still",
            },
            {
                ["kind"] = "literal",
                ["value"] = "snowing",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "WEATHER",
                ["dialogueState"] = "WEATHER_TOPIC",
                ["sourceRefs"] = {
                    "MASSIVE",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "MASSIVE",
            },
        },
        ["priority"] = 166,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "massive",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "WEATHER",
        },
        ["id"] = "pnc.dataset.massive.weather.what_is_the_weather_like",
        ["match"] = {
            {
                ["id"] = "WEATHER",
                ["kind"] = "concept",
            },
            {
                ["kind"] = "literal",
                ["value"] = "like",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "WEATHER",
                ["dialogueState"] = "WEATHER_TOPIC",
                ["sourceRefs"] = {
                    "MASSIVE",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "MASSIVE",
            },
        },
        ["priority"] = 166,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "promise",
        ["emit"] = {
            ["extensions"] = {
                ["dialogueFollowUp"] = "NEEDS_PROPOSAL",
                ["topic"] = "NEEDS",
            },
            ["intent"] = "PROMISE",
            ["speechAct"] = "PROMISE",
            ["subject"] = "NEEDS",
        },
        ["id"] = "pnc.dataset.promise.needs.i_ll_pick_some_up",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "i'll",
            },
            {
                ["kind"] = "literal",
                ["value"] = "pick",
            },
            {
                ["kind"] = "literal",
                ["value"] = "some",
            },
            {
                ["kind"] = "literal",
                ["value"] = "up",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "FETCH",
                ["dialogueState"] = "NEEDS_PROPOSAL",
                ["sourceRefs"] = {
                    "WordNet 3.0",
                    "MASSIVE",
                    "SGD",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "WordNet 3.0",
                "MASSIVE",
                "SGD",
            },
        },
        ["priority"] = 166,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "WEATHER",
        },
        ["id"] = "pnc.dataset.question.weather.can_we_talk_about_the_weather",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "can",
            },
            {
                ["kind"] = "literal",
                ["value"] = "we",
            },
            {
                ["kind"] = "literal",
                ["value"] = "talk",
            },
            {
                ["kind"] = "literal",
                ["value"] = "about",
            },
            {
                ["kind"] = "literal",
                ["value"] = "the",
            },
            {
                ["kind"] = "literal",
                ["value"] = "weather",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "WEATHER",
                ["dialogueState"] = "WEATHER_TOPIC",
                ["sourceRefs"] = {
                    "MASSIVE",
                    "SGD",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "MASSIVE",
                "SGD",
            },
        },
        ["priority"] = 165,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "sgd",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "WEATHER",
        },
        ["id"] = "pnc.dataset.sgd.weather.how_is_the_weather_on_9th_of_march",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "how",
            },
            {
                ["kind"] = "literal",
                ["value"] = "is",
            },
            {
                ["kind"] = "literal",
                ["value"] = "the",
            },
            {
                ["kind"] = "literal",
                ["value"] = "weather",
            },
            {
                ["kind"] = "literal",
                ["value"] = "on",
            },
            {
                ["kind"] = "literal",
                ["value"] = "9th",
            },
            {
                ["kind"] = "literal",
                ["value"] = "of",
            },
            {
                ["kind"] = "literal",
                ["value"] = "march",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "WEATHER",
                ["dialogueState"] = "WEATHER_TOPIC",
                ["sourceRefs"] = {
                    "SGD",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "SGD",
            },
        },
        ["priority"] = 166,
    },
}
