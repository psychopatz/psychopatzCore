-- Generated; do not edit by hand.
return {
    {
        ["confidence"] = 0.99,
        ["domain"] = "follow_up",
        ["emit"] = {
            ["extensions"] = {
                ["contextQuestion"] = "BACKSTORY_MISS",
                ["dialogueFollowUp"] = "CONTEXT_REFERENCE",
                ["topic"] = "conversation",
            },
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "CONTEXT_REFERENCE",
            ["target"] = "$capture.reference",
        },
        ["id"] = "pnc.backstory.follow_up.do_you_miss_it",
        ["match"] = {
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
                ["value"] = "miss",
            },
            {
                ["capture"] = "reference",
                ["kind"] = "literal",
                ["value"] = "it",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "CONTEXT_REFERENCE",
                ["dialogueState"] = "BACKSTORY_FOLLOW_UP",
                ["sourceRefs"] = {
                    "Project Hoomans Authoring Review",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "Project Hoomans Authoring Review",
            },
        },
        ["priority"] = 129,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "follow_up",
        ["emit"] = {
            ["extensions"] = {
                ["contextQuestion"] = "BACKSTORY_LOCATION",
                ["dialogueFollowUp"] = "CONTEXT_REFERENCE",
                ["topic"] = "conversation",
            },
            ["intent"] = "QUESTION",
            ["speechAct"] = "QUESTION",
            ["subject"] = "CONTEXT_REFERENCE",
            ["target"] = "$capture.reference",
        },
        ["id"] = "pnc.backstory.follow_up.where",
        ["match"] = {
            {
                ["capture"] = "reference",
                ["kind"] = "literal",
                ["value"] = "where",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "CONTEXT_REFERENCE",
                ["dialogueState"] = "BACKSTORY_FOLLOW_UP",
                ["sourceRefs"] = {
                    "Project Hoomans Authoring Review",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "Project Hoomans Authoring Review",
            },
        },
        ["priority"] = 129,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["extensions"] = {
                ["disclosure"] = "server_authorized",
                ["factProvider"] = "npc_backstory",
                ["topicID"] = "backstory.fear",
            },
            ["intent"] = "QUESTION",
            ["slots"] = {
                ["backstoryKind"] = "fear",
            },
            ["speechAct"] = "QUESTION",
            ["subject"] = "NPC_BACKSTORY",
        },
        ["id"] = "pnc.backstory.question.fear.private",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "what",
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
                ["value"] = "afraid",
            },
            {
                ["kind"] = "literal",
                ["value"] = "of",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "NPC_BACKSTORY",
                ["dialogueState"] = "BACKSTORY_QUESTION",
                ["sourceRefs"] = {
                    "Project Hoomans Authoring Review",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "Project Hoomans Authoring Review",
            },
        },
        ["priority"] = 150,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["extensions"] = {
                ["disclosure"] = "server_authorized",
                ["factProvider"] = "npc_backstory",
                ["topicID"] = "backstory.former_job",
            },
            ["intent"] = "QUESTION",
            ["slots"] = {
                ["backstoryKind"] = "former_job",
            },
            ["speechAct"] = "QUESTION",
            ["subject"] = "NPC_BACKSTORY",
        },
        ["id"] = "pnc.backstory.question.former_job.before_all_this",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "what",
            },
            {
                ["kind"] = "literal",
                ["value"] = "did",
            },
            {
                ["kind"] = "literal",
                ["value"] = "you",
            },
            {
                ["kind"] = "literal",
                ["value"] = "do",
            },
            {
                ["kind"] = "literal",
                ["value"] = "before",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "NPC_BACKSTORY",
                ["dialogueState"] = "BACKSTORY_QUESTION",
                ["sourceRefs"] = {
                    "Project Hoomans Authoring Review",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "Project Hoomans Authoring Review",
            },
        },
        ["priority"] = 150,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["extensions"] = {
                ["disclosure"] = "server_authorized",
                ["factProvider"] = "npc_backstory",
                ["topicID"] = "backstory.former_job",
            },
            ["intent"] = "QUESTION",
            ["slots"] = {
                ["backstoryKind"] = "former_job",
            },
            ["speechAct"] = "QUESTION",
            ["subject"] = "NPC_BACKSTORY",
        },
        ["id"] = "pnc.backstory.question.former_job.old_job",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "what",
            },
            {
                ["kind"] = "literal",
                ["value"] = "was",
            },
            {
                ["kind"] = "literal",
                ["value"] = "your",
            },
            {
                ["kind"] = "literal",
                ["value"] = "old",
            },
            {
                ["kind"] = "literal",
                ["value"] = "job",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "NPC_BACKSTORY",
                ["dialogueState"] = "BACKSTORY_QUESTION",
                ["sourceRefs"] = {
                    "Project Hoomans Authoring Review",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "Project Hoomans Authoring Review",
            },
        },
        ["priority"] = 151,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["extensions"] = {
                ["disclosure"] = "server_authorized",
                ["factProvider"] = "npc_backstory",
                ["topicID"] = "backstory.hobby",
            },
            ["intent"] = "QUESTION",
            ["slots"] = {
                ["backstoryKind"] = "hobby",
            },
            ["speechAct"] = "QUESTION",
            ["subject"] = "NPC_BACKSTORY",
        },
        ["id"] = "pnc.backstory.question.hobby.interest",
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
                ["value"] = "hobby",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "NPC_BACKSTORY",
                ["dialogueState"] = "BACKSTORY_QUESTION",
                ["sourceRefs"] = {
                    "Project Hoomans Authoring Review",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "Project Hoomans Authoring Review",
            },
        },
        ["priority"] = 150,
    },
    {
        ["confidence"] = 0.99,
        ["domain"] = "question",
        ["emit"] = {
            ["extensions"] = {
                ["disclosure"] = "server_authorized",
                ["factProvider"] = "npc_backstory",
                ["topicID"] = "backstory.hometown",
            },
            ["intent"] = "QUESTION",
            ["slots"] = {
                ["backstoryKind"] = "hometown",
            },
            ["speechAct"] = "QUESTION",
            ["subject"] = "NPC_BACKSTORY",
        },
        ["id"] = "pnc.backstory.question.hometown.grew_up",
        ["match"] = {
            {
                ["kind"] = "literal",
                ["value"] = "where",
            },
            {
                ["kind"] = "literal",
                ["value"] = "did",
            },
            {
                ["kind"] = "literal",
                ["value"] = "you",
            },
            {
                ["kind"] = "literal",
                ["value"] = "grow",
            },
            {
                ["kind"] = "literal",
                ["value"] = "up",
            },
        },
        ["metadata"] = {
            ["mapping"] = {
                ["canonicalConcept"] = "NPC_BACKSTORY",
                ["dialogueState"] = "BACKSTORY_QUESTION",
                ["sourceRefs"] = {
                    "Project Hoomans Authoring Review",
                },
            },
            ["reviewed"] = true,
            ["sourceRefs"] = {
                "Project Hoomans Authoring Review",
            },
        },
        ["priority"] = 150,
    },
}
