-- Generated; do not edit by hand.
return {
    {
        ["dialogueAct"] = "INFORM",
        ["domain"] = "general",
        ["id"] = "construction.en.social.disclose_name",
        ["locale"] = "EN",
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
        ["type"] = "construction",
    },
    {
        ["dialogueAct"] = "END_CONVERSATION",
        ["domain"] = "general",
        ["id"] = "construction.en.social.end_conversation_done",
        ["locale"] = "EN",
        ["owner"] = "PsychopatzCore",
        ["strategy"] = "END_CONVERSATION",
        ["tokens"] = {
            {
                ["kind"] = "literal",
                ["value"] = "We're done here.",
            },
        },
        ["type"] = "construction",
    },
    {
        ["dialogueAct"] = "END_CONVERSATION",
        ["domain"] = "general",
        ["id"] = "construction.en.social.end_conversation_withdraw",
        ["locale"] = "EN",
        ["owner"] = "PsychopatzCore",
        ["strategy"] = "END_CONVERSATION",
        ["tokens"] = {
            {
                ["kind"] = "literal",
                ["value"] = "I'm done with this.",
            },
        },
        ["type"] = "construction",
    },
    {
        ["dialogueAct"] = "RETORT",
        ["domain"] = "general",
        ["id"] = "construction.en.social.mirror_retort",
        ["locale"] = "EN",
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
        ["type"] = "construction",
    },
    {
        ["dialogueAct"] = "RETORT",
        ["domain"] = "general",
        ["id"] = "construction.en.social.mirror_retort_challenge",
        ["locale"] = "EN",
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
        ["type"] = "construction",
    },
    {
        ["dialogueAct"] = "REFUSE",
        ["domain"] = "general",
        ["id"] = "construction.en.social.refuse_identity",
        ["locale"] = "EN",
        ["owner"] = "PsychopatzCore",
        ["strategy"] = "REFUSE_IDENTITY",
        ["tokens"] = {
            {
                ["kind"] = "literal",
                ["value"] = "I'd rather not say.",
            },
        },
        ["type"] = "construction",
    },
    {
        ["dialogueAct"] = "INFORM",
        ["domain"] = "general",
        ["id"] = "construction.tl.social.disclose_name",
        ["locale"] = "TL",
        ["owner"] = "PsychopatzCore",
        ["strategy"] = "DISCLOSE_NAME",
        ["tokens"] = {
            {
                ["kind"] = "literal",
                ["value"] = "Ako si ",
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
        ["type"] = "construction",
    },
    {
        ["dialogueAct"] = "END_CONVERSATION",
        ["domain"] = "general",
        ["id"] = "construction.tl.social.end_conversation_done",
        ["locale"] = "TL",
        ["owner"] = "PsychopatzCore",
        ["strategy"] = "END_CONVERSATION",
        ["tokens"] = {
            {
                ["kind"] = "literal",
                ["value"] = "Tapos na tayo rito.",
            },
        },
        ["type"] = "construction",
    },
    {
        ["dialogueAct"] = "END_CONVERSATION",
        ["domain"] = "general",
        ["id"] = "construction.tl.social.end_conversation_withdraw",
        ["locale"] = "TL",
        ["owner"] = "PsychopatzCore",
        ["strategy"] = "END_CONVERSATION",
        ["tokens"] = {
            {
                ["kind"] = "literal",
                ["value"] = "Ayoko na nito.",
            },
        },
        ["type"] = "construction",
    },
    {
        ["dialogueAct"] = "RETORT",
        ["domain"] = "general",
        ["id"] = "construction.tl.social.mirror_retort",
        ["locale"] = "TL",
        ["owner"] = "PsychopatzCore",
        ["strategy"] = "MIRROR",
        ["tokens"] = {
            {
                ["kind"] = "lexeme",
                ["slot"] = "primary",
            },
            {
                ["kind"] = "literal",
                ["value"] = " rin.",
            },
        },
        ["type"] = "construction",
    },
    {
        ["dialogueAct"] = "RETORT",
        ["domain"] = "general",
        ["id"] = "construction.tl.social.mirror_retort_challenge",
        ["locale"] = "TL",
        ["owner"] = "PsychopatzCore",
        ["strategy"] = "MIRROR",
        ["tokens"] = {
            {
                ["kind"] = "literal",
                ["value"] = "Ha? ",
            },
            {
                ["kind"] = "lexeme",
                ["slot"] = "primary",
            },
            {
                ["kind"] = "literal",
                ["value"] = " rin.",
            },
        },
        ["type"] = "construction",
    },
    {
        ["dialogueAct"] = "REFUSE",
        ["domain"] = "general",
        ["id"] = "construction.tl.social.refuse_identity",
        ["locale"] = "TL",
        ["owner"] = "PsychopatzCore",
        ["strategy"] = "REFUSE_IDENTITY",
        ["tokens"] = {
            {
                ["kind"] = "literal",
                ["value"] = "Ayoko munang sabihin.",
            },
        },
        ["type"] = "construction",
    },
}
