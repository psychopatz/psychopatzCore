-- Generated; do not edit by hand.
return {
    {
        ["dialogueAct"] = "COMPOSE",
        ["domain"] = "general",
        ["id"] = "construction.en.clause_relations.add",
        ["owner"] = "PsychopatzCore",
        ["strategy"] = "RELATION_ADD",
        ["tokens"] = {
            {
                ["kind"] = "slot",
                ["slot"] = "clause_left",
            },
            {
                ["kind"] = "literal",
                ["value"] = ", and ",
            },
            {
                ["kind"] = "slot",
                ["slot"] = "clause_right",
            },
        },
        ["translationKey"] = "convo.construction.clause_relations.add",
        ["type"] = "construction",
    },
    {
        ["dialogueAct"] = "COMPOSE",
        ["domain"] = "general",
        ["id"] = "construction.en.clause_relations.cause",
        ["owner"] = "PsychopatzCore",
        ["strategy"] = "RELATION_CAUSE",
        ["tokens"] = {
            {
                ["kind"] = "slot",
                ["slot"] = "clause_left",
            },
            {
                ["kind"] = "literal",
                ["value"] = " because ",
            },
            {
                ["kind"] = "slot",
                ["slot"] = "clause_right",
            },
        },
        ["translationKey"] = "convo.construction.clause_relations.cause",
        ["type"] = "construction",
    },
    {
        ["dialogueAct"] = "COMPOSE",
        ["domain"] = "general",
        ["id"] = "construction.en.clause_relations.condition",
        ["owner"] = "PsychopatzCore",
        ["strategy"] = "RELATION_CONDITION",
        ["tokens"] = {
            {
                ["kind"] = "slot",
                ["slot"] = "clause_left",
            },
            {
                ["kind"] = "literal",
                ["value"] = " if ",
            },
            {
                ["kind"] = "slot",
                ["slot"] = "clause_right",
            },
        },
        ["translationKey"] = "convo.construction.clause_relations.condition",
        ["type"] = "construction",
    },
    {
        ["dialogueAct"] = "COMPOSE",
        ["domain"] = "general",
        ["id"] = "construction.en.clause_relations.consequence",
        ["owner"] = "PsychopatzCore",
        ["strategy"] = "RELATION_CONSEQUENCE",
        ["tokens"] = {
            {
                ["kind"] = "slot",
                ["slot"] = "clause_left",
            },
            {
                ["kind"] = "literal",
                ["value"] = ", so ",
            },
            {
                ["kind"] = "slot",
                ["slot"] = "clause_right",
            },
        },
        ["translationKey"] = "convo.construction.clause_relations.consequence",
        ["type"] = "construction",
    },
    {
        ["dialogueAct"] = "COMPOSE",
        ["domain"] = "general",
        ["id"] = "construction.en.clause_relations.contrast",
        ["owner"] = "PsychopatzCore",
        ["strategy"] = "RELATION_CONTRAST",
        ["tokens"] = {
            {
                ["kind"] = "slot",
                ["slot"] = "clause_left",
            },
            {
                ["kind"] = "literal",
                ["value"] = ", but ",
            },
            {
                ["kind"] = "slot",
                ["slot"] = "clause_right",
            },
        },
        ["translationKey"] = "convo.construction.clause_relations.contrast",
        ["type"] = "construction",
    },
    {
        ["dialogueAct"] = "COMPOSE",
        ["domain"] = "general",
        ["id"] = "construction.en.clause_relations.explanation",
        ["owner"] = "PsychopatzCore",
        ["strategy"] = "RELATION_EXPLANATION",
        ["tokens"] = {
            {
                ["kind"] = "slot",
                ["slot"] = "clause_left",
            },
            {
                ["kind"] = "literal",
                ["value"] = ". That means ",
            },
            {
                ["kind"] = "slot",
                ["slot"] = "clause_right",
            },
        },
        ["translationKey"] = "convo.construction.clause_relations.explanation",
        ["type"] = "construction",
    },
    {
        ["dialogueAct"] = "COMPOSE",
        ["domain"] = "general",
        ["id"] = "construction.en.clause_relations.sequence",
        ["owner"] = "PsychopatzCore",
        ["strategy"] = "RELATION_SEQUENCE",
        ["tokens"] = {
            {
                ["kind"] = "slot",
                ["slot"] = "clause_left",
            },
            {
                ["kind"] = "literal",
                ["value"] = ", then ",
            },
            {
                ["kind"] = "slot",
                ["slot"] = "clause_right",
            },
        },
        ["translationKey"] = "convo.construction.clause_relations.sequence",
        ["type"] = "construction",
    },
}
