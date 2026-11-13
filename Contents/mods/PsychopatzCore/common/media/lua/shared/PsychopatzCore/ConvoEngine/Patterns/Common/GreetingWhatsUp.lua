-- Generated; do not edit by hand.
return {
    {
        ["confidence"] = 0.97,
        ["domain"] = "greeting",
        ["emit"] = {
            ["intent"] = "GREET",
            ["speechAct"] = "GREET",
        },
        ["id"] = "pnc.dataset.greeting.glad_to_see_you_again",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "glad",
            },
            {
                ["kind"] = "literal",
                ["value"] = "to",
            },
            {
                ["kind"] = "literal",
                ["value"] = "see",
            },
            {
                ["kind"] = "literal",
                ["value"] = "you",
            },
            {
                ["kind"] = "literal",
                ["value"] = "again",
            },
        },
        ["priority"] = 120,
    },
    {
        ["confidence"] = 0.98,
        ["domain"] = "greeting",
        ["emit"] = {
            ["intent"] = "GREET",
            ["speechAct"] = "GREET",
        },
        ["id"] = "pnc.dataset.greeting.good_to_see_you_again",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "good",
            },
            {
                ["kind"] = "literal",
                ["value"] = "to",
            },
            {
                ["kind"] = "literal",
                ["value"] = "see",
            },
            {
                ["kind"] = "literal",
                ["value"] = "you",
            },
            {
                ["kind"] = "literal",
                ["value"] = "again",
            },
        },
        ["priority"] = 120,
    },
    {
        ["confidence"] = 0.98,
        ["domain"] = "greeting",
        ["emit"] = {
            ["intent"] = "GREET",
            ["speechAct"] = "GREET",
        },
        ["id"] = "pnc.dataset.greeting.long_time_no_see",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "long",
            },
            {
                ["kind"] = "literal",
                ["value"] = "time",
            },
            {
                ["kind"] = "literal",
                ["value"] = "no",
            },
            {
                ["kind"] = "literal",
                ["value"] = "see",
            },
        },
        ["priority"] = 120,
    },
    {
        ["confidence"] = 0.98,
        ["domain"] = "greeting",
        ["emit"] = {
            ["intent"] = "GREET",
            ["speechAct"] = "GREET",
        },
        ["id"] = "pnc.dataset.greeting.nice_to_see_you_again",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "nice",
            },
            {
                ["kind"] = "literal",
                ["value"] = "to",
            },
            {
                ["kind"] = "literal",
                ["value"] = "see",
            },
            {
                ["kind"] = "literal",
                ["value"] = "you",
            },
            {
                ["kind"] = "literal",
                ["value"] = "again",
            },
        },
        ["priority"] = 120,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["extensions"] = {
                ["hubID"] = "whats_up",
                ["route"] = "semantic_hub",
                ["topic"] = "whats_up",
            },
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "CONVERSATION_TOPIC",
        },
        ["id"] = "pnc.dataset.question.whats_up.anything_going_on",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "anything",
            },
            {
                ["kind"] = "literal",
                ["value"] = "going",
            },
            {
                ["kind"] = "literal",
                ["value"] = "on",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "WHATS_UP",
                ["dialogueState"] = "WHATS_UP_HUB",
                ["sourceRefs"] = {
                    "DailyDialog",
                    "EmpatheticDialogues",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "DailyDialog",
                "EmpatheticDialogues",
            },
        },
        ["priority"] = 155,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["extensions"] = {
                ["hubID"] = "whats_up",
                ["route"] = "semantic_hub",
                ["topic"] = "whats_up",
            },
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "CONVERSATION_TOPIC",
        },
        ["id"] = "pnc.dataset.question.whats_up.anything_new",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "anything",
            },
            {
                ["kind"] = "literal",
                ["value"] = "new",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "WHATS_UP",
                ["dialogueState"] = "WHATS_UP_HUB",
                ["sourceRefs"] = {
                    "DailyDialog",
                    "EmpatheticDialogues",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "DailyDialog",
                "EmpatheticDialogues",
            },
        },
        ["priority"] = 155,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["extensions"] = {
                ["hubID"] = "whats_up",
                ["route"] = "semantic_hub",
                ["topic"] = "whats_up",
            },
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "CONVERSATION_TOPIC",
        },
        ["id"] = "pnc.dataset.question.whats_up.what_is_up",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "what",
            },
            {
                ["kind"] = "literal",
                ["value"] = "is",
            },
            {
                ["kind"] = "literal",
                ["value"] = "up",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "WHATS_UP",
                ["dialogueState"] = "WHATS_UP_HUB",
                ["sourceRefs"] = {
                    "DailyDialog",
                    "EmpatheticDialogues",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "DailyDialog",
                "EmpatheticDialogues",
            },
        },
        ["priority"] = 155,
    },
    {
        ["confidence"] = 0.97,
        ["domain"] = "question",
        ["emit"] = {
            ["extensions"] = {
                ["hubID"] = "whats_up",
                ["route"] = "semantic_hub",
                ["topic"] = "whats_up",
            },
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "CONVERSATION_TOPIC",
        },
        ["id"] = "pnc.dataset.question.whats_up.what_up",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "what",
            },
            {
                ["kind"] = "literal",
                ["value"] = "up",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "WHATS_UP",
                ["dialogueState"] = "WHATS_UP_HUB",
                ["sourceRefs"] = {
                    "DailyDialog",
                    "EmpatheticDialogues",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "DailyDialog",
                "EmpatheticDialogues",
            },
        },
        ["priority"] = 155,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["extensions"] = {
                ["hubID"] = "whats_up",
                ["route"] = "semantic_hub",
                ["topic"] = "whats_up",
            },
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "CONVERSATION_TOPIC",
        },
        ["id"] = "pnc.dataset.question.whats_up.whats_happening",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "what's",
            },
            {
                ["kind"] = "literal",
                ["value"] = "happening",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "WHATS_UP",
                ["dialogueState"] = "WHATS_UP_HUB",
                ["sourceRefs"] = {
                    "DailyDialog",
                    "EmpatheticDialogues",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "DailyDialog",
                "EmpatheticDialogues",
            },
        },
        ["priority"] = 155,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["extensions"] = {
                ["hubID"] = "whats_up",
                ["route"] = "semantic_hub",
                ["topic"] = "whats_up",
            },
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "CONVERSATION_TOPIC",
        },
        ["id"] = "pnc.dataset.question.whats_up.whats_happening_ascii",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "whats",
            },
            {
                ["kind"] = "literal",
                ["value"] = "happening",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "WHATS_UP",
                ["dialogueState"] = "WHATS_UP_HUB",
                ["sourceRefs"] = {
                    "DailyDialog",
                    "EmpatheticDialogues",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "DailyDialog",
                "EmpatheticDialogues",
            },
        },
        ["priority"] = 155,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["extensions"] = {
                ["hubID"] = "whats_up",
                ["route"] = "semantic_hub",
                ["topic"] = "whats_up",
            },
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "CONVERSATION_TOPIC",
        },
        ["id"] = "pnc.dataset.question.whats_up.whats_new",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "what's",
            },
            {
                ["kind"] = "literal",
                ["value"] = "new",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "WHATS_UP",
                ["dialogueState"] = "WHATS_UP_HUB",
                ["sourceRefs"] = {
                    "DailyDialog",
                    "EmpatheticDialogues",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "DailyDialog",
                "EmpatheticDialogues",
            },
        },
        ["priority"] = 155,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["extensions"] = {
                ["hubID"] = "whats_up",
                ["route"] = "semantic_hub",
                ["topic"] = "whats_up",
            },
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "CONVERSATION_TOPIC",
        },
        ["id"] = "pnc.dataset.question.whats_up.whats_new_ascii",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "whats",
            },
            {
                ["kind"] = "literal",
                ["value"] = "new",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "WHATS_UP",
                ["dialogueState"] = "WHATS_UP_HUB",
                ["sourceRefs"] = {
                    "DailyDialog",
                    "EmpatheticDialogues",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "DailyDialog",
                "EmpatheticDialogues",
            },
        },
        ["priority"] = 155,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["extensions"] = {
                ["hubID"] = "whats_up",
                ["route"] = "semantic_hub",
                ["topic"] = "whats_up",
            },
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "CONVERSATION_TOPIC",
        },
        ["id"] = "pnc.dataset.question.whats_up.whats_up",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "what's",
            },
            {
                ["kind"] = "literal",
                ["value"] = "up",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "WHATS_UP",
                ["dialogueState"] = "WHATS_UP_HUB",
                ["sourceRefs"] = {
                    "DailyDialog",
                    "EmpatheticDialogues",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "DailyDialog",
                "EmpatheticDialogues",
            },
        },
        ["priority"] = 155,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["extensions"] = {
                ["hubID"] = "whats_up",
                ["route"] = "semantic_hub",
                ["topic"] = "whats_up",
            },
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "CONVERSATION_TOPIC",
        },
        ["id"] = "pnc.dataset.question.whats_up.whats_up_ascii",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "whats",
            },
            {
                ["kind"] = "literal",
                ["value"] = "up",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "WHATS_UP",
                ["dialogueState"] = "WHATS_UP_HUB",
                ["sourceRefs"] = {
                    "DailyDialog",
                    "EmpatheticDialogues",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "DailyDialog",
                "EmpatheticDialogues",
            },
        },
        ["priority"] = 155,
    },
    {
        ["confidence"] = 0.98,
        ["domain"] = "question",
        ["emit"] = {
            ["extensions"] = {
                ["hubID"] = "whats_up",
                ["route"] = "semantic_hub",
                ["topic"] = "whats_up",
            },
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "CONVERSATION_TOPIC",
        },
        ["id"] = "pnc.dataset.question.whats_up.whatsup_compact",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "whatsup",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "WHATS_UP",
                ["dialogueState"] = "WHATS_UP_HUB",
                ["sourceRefs"] = {
                    "DailyDialog",
                    "EmpatheticDialogues",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "DailyDialog",
                "EmpatheticDialogues",
            },
        },
        ["priority"] = 155,
    },
}
