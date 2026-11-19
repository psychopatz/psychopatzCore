-- Generated; do not edit by hand.
return {
    {
        ["dialogueAct"] = "INFORM",
        ["domain"] = "general",
        ["id"] = "construction.en.social.disclose_name",
        ["owner"] = "PsychopatzCore",
        ["strategy"] = "DISCLOSE_NAME",
        ["tokens"] = {
            {
                ["kind"] = "literal",
                ["value"] = "I'm ",
            },
            {
                ["kind"] = "slot",
                ["slot"] = "name",
            },
            {
                ["kind"] = "literal",
                ["value"] = ".",
            },
        },
        ["translationKey"] = "convo.construction.social.disclose_name",
        ["type"] = "construction",
    },
    {
        ["dialogueAct"] = "END_CONVERSATION",
        ["domain"] = "general",
        ["id"] = "construction.en.social.end_conversation_done",
        ["owner"] = "PsychopatzCore",
        ["strategy"] = "END_CONVERSATION",
        ["tokens"] = {
            {
                ["kind"] = "literal",
                ["value"] = "We're done here.",
            },
        },
        ["translationKey"] = "convo.construction.social.end_conversation_done",
        ["type"] = "construction",
    },
    {
        ["dialogueAct"] = "END_CONVERSATION",
        ["domain"] = "general",
        ["id"] = "construction.en.social.end_conversation_withdraw",
        ["owner"] = "PsychopatzCore",
        ["strategy"] = "END_CONVERSATION",
        ["tokens"] = {
            {
                ["kind"] = "literal",
                ["value"] = "I'm done with this.",
            },
        },
        ["translationKey"] = "convo.construction.social.end_conversation_withdraw",
        ["type"] = "construction",
    },
    {
        ["dialogueAct"] = "RETORT",
        ["domain"] = "general",
        ["id"] = "construction.en.social.mirror_retort",
        ["owner"] = "PsychopatzCore",
        ["strategy"] = "MIRROR",
        ["tokens"] = {
            {
                ["kind"] = "lexeme",
                ["slot"] = "primary",
            },
            {
                ["kind"] = "literal",
                ["value"] = " you too.",
            },
        },
        ["translationKey"] = "convo.construction.social.mirror_retort",
        ["type"] = "construction",
    },
    {
        ["dialogueAct"] = "RETORT",
        ["domain"] = "general",
        ["id"] = "construction.en.social.mirror_retort_challenge",
        ["owner"] = "PsychopatzCore",
        ["strategy"] = "MIRROR",
        ["tokens"] = {
            {
                ["kind"] = "literal",
                ["value"] = "Yeah? ",
            },
            {
                ["kind"] = "lexeme",
                ["slot"] = "primary",
            },
            {
                ["kind"] = "literal",
                ["value"] = " you too.",
            },
        },
        ["translationKey"] = "convo.construction.social.mirror_retort_challenge",
        ["type"] = "construction",
    },
    {
        ["dialogueAct"] = "REFUSE",
        ["domain"] = "general",
        ["id"] = "construction.en.social.refuse_identity",
        ["owner"] = "PsychopatzCore",
        ["strategy"] = "REFUSE_IDENTITY",
        ["tokens"] = {
            {
                ["kind"] = "literal",
                ["value"] = "I'd rather not say.",
            },
        },
        ["translationKey"] = "convo.construction.social.refuse_identity",
        ["type"] = "construction",
    },
}
