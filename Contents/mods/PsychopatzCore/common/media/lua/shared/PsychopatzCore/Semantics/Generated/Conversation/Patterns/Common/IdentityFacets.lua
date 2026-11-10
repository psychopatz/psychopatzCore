-- Generated; do not edit by hand.
return {
    {
        ["confidence"] = 0.98,
        ["domain"] = "identity",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["socialContext"] = {
                ["directed"] = true,
                ["identityFacet"] = "faction",
            },
            ["speechAct"] = "QUESTION",
            ["subject"] = "IDENTITY_FACTION",
        },
        ["id"] = "pnc.question.identity.faction",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "who",
            },
            {
                ["kind"] = "literal",
                ["value"] = "are",
            },
            {
                ["kind"] = "literal",
                ["value"] = "you",
            },
            {
                ["kind"] = "literal",
                ["value"] = "with",
            },
        },
        ["priority"] = 122,
    },
    {
        ["confidence"] = 0.98,
        ["domain"] = "identity",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["socialContext"] = {
                ["directed"] = true,
                ["identityFacet"] = "nickname",
            },
            ["speechAct"] = "QUESTION",
            ["subject"] = "IDENTITY_NICKNAME",
        },
        ["id"] = "pnc.question.identity.nickname",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "what",
            },
            {
                ["kind"] = "literal",
                ["value"] = "do",
            },
            {
                ["kind"] = "literal",
                ["value"] = "people",
            },
            {
                ["kind"] = "literal",
                ["value"] = "call",
            },
            {
                ["kind"] = "literal",
                ["value"] = "you",
            },
        },
        ["priority"] = 122,
    },
    {
        ["confidence"] = 0.98,
        ["domain"] = "identity",
        ["emit"] = {
            ["intent"] = "QUESTION",
            ["socialContext"] = {
                ["directed"] = true,
                ["identityFacet"] = "surname",
            },
            ["speechAct"] = "QUESTION",
            ["subject"] = "IDENTITY_SURNAME",
        },
        ["id"] = "pnc.question.identity.surname",
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
                ["value"] = "your",
            },
            {
                ["kind"] = "literal",
                ["value"] = "surname",
            },
        },
        ["priority"] = 122,
    },
}
