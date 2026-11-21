-- Generated Conversation Director index; do not edit by hand.
return {
    ["byActivity"] = {
    },
    ["byDomain"] = {
        ["memory"] = {
            "behavior.acknowledge_memory",
            "behavior.ask_memory_followup",
        },
        ["social"] = {
            "beat.argument_escalation",
            "beat.reconciliation",
            "beat.suspicious_first_contact",
            "behavior.acknowledge_memory",
            "behavior.acknowledge_news",
            "behavior.acknowledge_repair",
            "behavior.acknowledge_reply",
            "behavior.acknowledge_thanks",
            "behavior.ask_memory_followup",
            "behavior.challenge",
            "behavior.clarify_context",
            "behavior.deescalate",
            "behavior.end_conversation",
            "behavior.reconcile",
            "behavior.retaliate_verbally",
            "behavior.warn",
            "behavior.world_event_warn",
        },
        ["world_event"] = {
            "behavior.world_event_warn",
        },
    },
    ["byEventType"] = {
        ["world_event"] = {
            "behavior.world_event_warn",
        },
    },
    ["byKind"] = {
        ["beat"] = {
            "beat.argument_escalation",
            "beat.reconciliation",
            "beat.suspicious_first_contact",
        },
        ["behavior"] = {
            "behavior.acknowledge_memory",
            "behavior.acknowledge_news",
            "behavior.acknowledge_repair",
            "behavior.acknowledge_reply",
            "behavior.acknowledge_thanks",
            "behavior.ask_memory_followup",
            "behavior.challenge",
            "behavior.clarify_context",
            "behavior.deescalate",
            "behavior.end_conversation",
            "behavior.reconcile",
            "behavior.retaliate_verbally",
            "behavior.warn",
            "behavior.world_event_warn",
        },
    },
    ["byRequiredFact"] = {
        ["actor.condition.panic"] = {
            "behavior.deescalate",
            "behavior.retaliate_verbally",
        },
        ["actor.disposition.aggression"] = {
            "behavior.retaliate_verbally",
        },
        ["actor.disposition.confidence"] = {
            "behavior.challenge",
            "behavior.warn",
        },
        ["actor.disposition.empathy"] = {
            "behavior.acknowledge_memory",
        },
        ["actor.disposition.forgiveness"] = {
            "behavior.end_conversation",
            "behavior.reconcile",
        },
        ["actor.disposition.sociability"] = {
            "behavior.acknowledge_memory",
            "behavior.acknowledge_thanks",
            "behavior.ask_memory_followup",
        },
        ["beat.turnsInBeat"] = {
            "beat.argument_escalation",
            "beat.reconciliation",
            "beat.suspicious_first_contact",
        },
        ["history.hostilityCount"] = {
            "beat.argument_escalation",
        },
        ["pragmatic.contextualAdmission.admitted"] = {
            "beat.reconciliation",
            "behavior.acknowledge_repair",
            "behavior.acknowledge_reply",
            "behavior.acknowledge_thanks",
            "behavior.reconcile",
        },
        ["pragmatic.contextualAdmission.selected.relation"] = {
            "beat.reconciliation",
            "behavior.acknowledge_repair",
            "behavior.acknowledge_reply",
            "behavior.acknowledge_thanks",
        },
        ["pragmatic.contextualAdmission.status"] = {
            "behavior.clarify_context",
        },
        ["relationship.approval"] = {
            "behavior.reconcile",
            "behavior.warn",
        },
        ["relationship.familiarity"] = {
            "beat.suspicious_first_contact",
            "behavior.ask_memory_followup",
        },
        ["scene.ended"] = {
            "beat.argument_escalation",
            "beat.reconciliation",
            "beat.suspicious_first_contact",
        },
        ["scene.firstContact"] = {
            "beat.suspicious_first_contact",
        },
        ["stimulus.semantic.intent"] = {
            "beat.argument_escalation",
            "beat.reconciliation",
            "beat.suspicious_first_contact",
            "behavior.acknowledge_memory",
            "behavior.acknowledge_news",
            "behavior.acknowledge_thanks",
            "behavior.ask_memory_followup",
            "behavior.challenge",
            "behavior.end_conversation",
            "behavior.reconcile",
        },
        ["stimulus.semantic.speechAct"] = {
            "beat.argument_escalation",
            "behavior.deescalate",
            "behavior.end_conversation",
            "behavior.retaliate_verbally",
            "behavior.warn",
        },
        ["world.immediateDanger"] = {
            "beat.argument_escalation",
            "beat.reconciliation",
            "beat.suspicious_first_contact",
            "behavior.deescalate",
            "behavior.end_conversation",
            "behavior.world_event_warn",
        },
    },
    ["byStimulus"] = {
        ["DANGER_CHANGED"] = {
            "behavior.world_event_warn",
        },
        ["HUMAN_UTTERANCE"] = {
            "beat.argument_escalation",
            "beat.reconciliation",
            "beat.suspicious_first_contact",
            "behavior.acknowledge_repair",
            "behavior.acknowledge_reply",
            "behavior.acknowledge_thanks",
            "behavior.challenge",
            "behavior.clarify_context",
            "behavior.deescalate",
            "behavior.end_conversation",
            "behavior.reconcile",
            "behavior.retaliate_verbally",
            "behavior.warn",
        },
        ["NPC_SEMANTIC_ACT"] = {
            "beat.argument_escalation",
            "beat.reconciliation",
            "beat.suspicious_first_contact",
            "behavior.acknowledge_memory",
            "behavior.acknowledge_news",
            "behavior.acknowledge_repair",
            "behavior.acknowledge_reply",
            "behavior.acknowledge_thanks",
            "behavior.ask_memory_followup",
            "behavior.challenge",
            "behavior.clarify_context",
            "behavior.deescalate",
            "behavior.end_conversation",
            "behavior.reconcile",
            "behavior.retaliate_verbally",
            "behavior.warn",
        },
        ["WORLD_EVENT"] = {
            "behavior.world_event_warn",
        },
    },
    ["byTopic"] = {
        ["conflict"] = {
            "beat.argument_escalation",
            "behavior.challenge",
            "behavior.retaliate_verbally",
            "behavior.warn",
        },
        ["first_contact"] = {
            "beat.suspicious_first_contact",
        },
        ["news"] = {
            "behavior.acknowledge_news",
        },
        ["repair"] = {
            "beat.reconciliation",
            "behavior.acknowledge_repair",
            "behavior.deescalate",
            "behavior.reconcile",
        },
    },
    ["entries"] = {
        ["beat.argument_escalation"] = {
            ["activities"] = {
            },
            ["baseRelevance"] = 0.7,
            ["cooldownTurns"] = 3,
            ["domain"] = "social",
            ["domainPath"] = "social/conflict",
            ["domains"] = {
                "social",
            },
            ["events"] = {
            },
            ["group"] = "beat_group.social_primary",
            ["id"] = "beat.argument_escalation",
            ["kind"] = "beat",
            ["maxTurns"] = 6,
            ["memories"] = {
            },
            ["module"] = "PsychopatzCore/ConvoEngine/Beat/Social/Conflict",
            ["owner"] = "PsychopatzCore",
            ["requiredFacts"] = {
                "beat.turnsInBeat",
                "history.hostilityCount",
                "scene.ended",
                "stimulus.semantic.intent",
                "stimulus.semantic.speechAct",
                "world.immediateDanger",
            },
            ["roleSpec"] = {
                ["maxParticipants"] = 2,
                ["minParticipants"] = 2,
                ["roleKinds"] = {
                    ["addressee"] = {
                        "participant",
                    },
                    ["speaker"] = {
                        "participant",
                    },
                },
                ["roles"] = {
                    "addressee",
                    "speaker",
                },
                ["target"] = {
                    ["multiple"] = false,
                    ["required"] = false,
                    ["type"] = "entity.any",
                },
            },
            ["stimuli"] = {
                "HUMAN_UTTERANCE",
                "NPC_SEMANTIC_ACT",
            },
            ["topics"] = {
                "conflict",
            },
        },
        ["beat.reconciliation"] = {
            ["activities"] = {
            },
            ["baseRelevance"] = 0.85,
            ["cooldownTurns"] = 4,
            ["domain"] = "social",
            ["domainPath"] = "social/repair",
            ["domains"] = {
                "social",
            },
            ["events"] = {
            },
            ["group"] = "beat_group.social_primary",
            ["id"] = "beat.reconciliation",
            ["kind"] = "beat",
            ["maxTurns"] = 2,
            ["memories"] = {
            },
            ["module"] = "PsychopatzCore/ConvoEngine/Beat/Social/Repair",
            ["owner"] = "PsychopatzCore",
            ["requiredFacts"] = {
                "beat.turnsInBeat",
                "pragmatic.contextualAdmission.admitted",
                "pragmatic.contextualAdmission.selected.relation",
                "scene.ended",
                "stimulus.semantic.intent",
                "world.immediateDanger",
            },
            ["roleSpec"] = {
                ["maxParticipants"] = 2,
                ["minParticipants"] = 2,
                ["roleKinds"] = {
                    ["addressee"] = {
                        "participant",
                    },
                    ["speaker"] = {
                        "participant",
                    },
                },
                ["roles"] = {
                    "addressee",
                    "speaker",
                },
                ["target"] = {
                    ["multiple"] = false,
                    ["required"] = false,
                    ["type"] = "entity.any",
                },
            },
            ["stimuli"] = {
                "HUMAN_UTTERANCE",
                "NPC_SEMANTIC_ACT",
            },
            ["topics"] = {
                "repair",
            },
        },
        ["beat.suspicious_first_contact"] = {
            ["activities"] = {
            },
            ["baseRelevance"] = 0.55,
            ["cooldownTurns"] = 2,
            ["domain"] = "social",
            ["domainPath"] = "social/first_contact",
            ["domains"] = {
                "social",
            },
            ["events"] = {
            },
            ["group"] = "beat_group.social_primary",
            ["id"] = "beat.suspicious_first_contact",
            ["kind"] = "beat",
            ["maxTurns"] = 3,
            ["memories"] = {
            },
            ["module"] = "PsychopatzCore/ConvoEngine/Beat/Social/FirstContact",
            ["owner"] = "PsychopatzCore",
            ["requiredFacts"] = {
                "beat.turnsInBeat",
                "relationship.familiarity",
                "scene.ended",
                "scene.firstContact",
                "stimulus.semantic.intent",
                "world.immediateDanger",
            },
            ["roleSpec"] = {
                ["maxParticipants"] = 2,
                ["minParticipants"] = 2,
                ["roleKinds"] = {
                    ["addressee"] = {
                        "participant",
                    },
                    ["speaker"] = {
                        "participant",
                    },
                },
                ["roles"] = {
                    "addressee",
                    "speaker",
                },
                ["target"] = {
                    ["multiple"] = false,
                    ["required"] = false,
                    ["type"] = "entity.any",
                },
            },
            ["stimuli"] = {
                "HUMAN_UTTERANCE",
                "NPC_SEMANTIC_ACT",
            },
            ["topics"] = {
                "first_contact",
            },
        },
        ["behavior.acknowledge_memory"] = {
            ["act"] = "ACKNOWLEDGE_MEMORY",
            ["activities"] = {
            },
            ["baseRelevance"] = 0.5,
            ["domain"] = "social",
            ["domainPath"] = "social/acknowledgement",
            ["domains"] = {
                "memory",
                "social",
            },
            ["events"] = {
            },
            ["id"] = "behavior.acknowledge_memory",
            ["kind"] = "behavior",
            ["memories"] = {
                "shared_memory",
            },
            ["mode"] = "one_shot",
            ["module"] = "PsychopatzCore/ConvoEngine/Behavior/Social/Acknowledgement",
            ["owner"] = "PsychopatzCore",
            ["requiredFacts"] = {
                "actor.disposition.empathy",
                "actor.disposition.sociability",
                "stimulus.semantic.intent",
            },
            ["roleSpec"] = {
                ["maxParticipants"] = 2,
                ["minParticipants"] = 2,
                ["roleKinds"] = {
                    ["addressee"] = {
                        "participant",
                    },
                    ["speaker"] = {
                        "participant",
                    },
                },
                ["roles"] = {
                    "addressee",
                    "speaker",
                },
                ["target"] = {
                    ["multiple"] = false,
                    ["required"] = false,
                    ["type"] = "entity.any",
                },
            },
            ["stimuli"] = {
                "NPC_SEMANTIC_ACT",
            },
            ["topics"] = {
            },
        },
        ["behavior.acknowledge_news"] = {
            ["act"] = "ACKNOWLEDGE_NEWS",
            ["activities"] = {
            },
            ["baseRelevance"] = 0.55,
            ["domain"] = "social",
            ["domainPath"] = "social/acknowledgement",
            ["domains"] = {
                "social",
            },
            ["events"] = {
            },
            ["id"] = "behavior.acknowledge_news",
            ["kind"] = "behavior",
            ["memories"] = {
            },
            ["mode"] = "one_shot",
            ["module"] = "PsychopatzCore/ConvoEngine/Behavior/Social/Acknowledgement",
            ["owner"] = "PsychopatzCore",
            ["requiredFacts"] = {
                "stimulus.semantic.intent",
            },
            ["roleSpec"] = {
                ["maxParticipants"] = 2,
                ["minParticipants"] = 2,
                ["roleKinds"] = {
                    ["addressee"] = {
                        "participant",
                    },
                    ["speaker"] = {
                        "participant",
                    },
                },
                ["roles"] = {
                    "addressee",
                    "speaker",
                },
                ["target"] = {
                    ["multiple"] = false,
                    ["required"] = false,
                    ["type"] = "entity.any",
                },
            },
            ["stimuli"] = {
                "NPC_SEMANTIC_ACT",
            },
            ["topics"] = {
                "news",
            },
        },
        ["behavior.acknowledge_repair"] = {
            ["act"] = "ACKNOWLEDGE_REPAIR",
            ["activities"] = {
            },
            ["baseRelevance"] = 0.55,
            ["domain"] = "social",
            ["domainPath"] = "social/repair",
            ["domains"] = {
                "social",
            },
            ["events"] = {
            },
            ["id"] = "behavior.acknowledge_repair",
            ["kind"] = "behavior",
            ["memories"] = {
            },
            ["mode"] = "one_shot",
            ["module"] = "PsychopatzCore/ConvoEngine/Behavior/Social/Repair",
            ["owner"] = "PsychopatzCore",
            ["requiredFacts"] = {
                "pragmatic.contextualAdmission.admitted",
                "pragmatic.contextualAdmission.selected.relation",
            },
            ["roleSpec"] = {
                ["maxParticipants"] = 2,
                ["minParticipants"] = 2,
                ["roleKinds"] = {
                    ["addressee"] = {
                        "participant",
                    },
                    ["speaker"] = {
                        "participant",
                    },
                },
                ["roles"] = {
                    "addressee",
                    "speaker",
                },
                ["target"] = {
                    ["multiple"] = false,
                    ["required"] = false,
                    ["type"] = "entity.any",
                },
            },
            ["stimuli"] = {
                "HUMAN_UTTERANCE",
                "NPC_SEMANTIC_ACT",
            },
            ["topics"] = {
                "repair",
            },
        },
        ["behavior.acknowledge_reply"] = {
            ["act"] = "ACKNOWLEDGE_REPLY",
            ["activities"] = {
            },
            ["baseRelevance"] = 0.65,
            ["domain"] = "social",
            ["domainPath"] = "social/acknowledgement",
            ["domains"] = {
                "social",
            },
            ["events"] = {
            },
            ["id"] = "behavior.acknowledge_reply",
            ["kind"] = "behavior",
            ["memories"] = {
            },
            ["mode"] = "one_shot",
            ["module"] = "PsychopatzCore/ConvoEngine/Behavior/Social/Acknowledgement",
            ["owner"] = "PsychopatzCore",
            ["requiredFacts"] = {
                "pragmatic.contextualAdmission.admitted",
                "pragmatic.contextualAdmission.selected.relation",
            },
            ["roleSpec"] = {
                ["maxParticipants"] = 2,
                ["minParticipants"] = 2,
                ["roleKinds"] = {
                    ["addressee"] = {
                        "participant",
                    },
                    ["speaker"] = {
                        "participant",
                    },
                },
                ["roles"] = {
                    "addressee",
                    "speaker",
                },
                ["target"] = {
                    ["multiple"] = false,
                    ["required"] = false,
                    ["type"] = "entity.any",
                },
            },
            ["stimuli"] = {
                "HUMAN_UTTERANCE",
                "NPC_SEMANTIC_ACT",
            },
            ["topics"] = {
            },
        },
        ["behavior.acknowledge_thanks"] = {
            ["act"] = "ACKNOWLEDGE_THANKS",
            ["activities"] = {
            },
            ["baseRelevance"] = 0.55,
            ["domain"] = "social",
            ["domainPath"] = "social/acknowledgement",
            ["domains"] = {
                "social",
            },
            ["events"] = {
            },
            ["id"] = "behavior.acknowledge_thanks",
            ["kind"] = "behavior",
            ["memories"] = {
            },
            ["mode"] = "one_shot",
            ["module"] = "PsychopatzCore/ConvoEngine/Behavior/Social/Acknowledgement",
            ["owner"] = "PsychopatzCore",
            ["requiredFacts"] = {
                "actor.disposition.sociability",
                "pragmatic.contextualAdmission.admitted",
                "pragmatic.contextualAdmission.selected.relation",
                "stimulus.semantic.intent",
            },
            ["roleSpec"] = {
                ["maxParticipants"] = 2,
                ["minParticipants"] = 2,
                ["roleKinds"] = {
                    ["addressee"] = {
                        "participant",
                    },
                    ["speaker"] = {
                        "participant",
                    },
                },
                ["roles"] = {
                    "addressee",
                    "speaker",
                },
                ["target"] = {
                    ["multiple"] = false,
                    ["required"] = false,
                    ["type"] = "entity.any",
                },
            },
            ["stimuli"] = {
                "HUMAN_UTTERANCE",
                "NPC_SEMANTIC_ACT",
            },
            ["topics"] = {
            },
        },
        ["behavior.ask_memory_followup"] = {
            ["act"] = "ASK_MEMORY_FOLLOWUP",
            ["activities"] = {
            },
            ["baseRelevance"] = 0.45,
            ["domain"] = "social",
            ["domainPath"] = "social/context",
            ["domains"] = {
                "memory",
                "social",
            },
            ["events"] = {
            },
            ["id"] = "behavior.ask_memory_followup",
            ["kind"] = "behavior",
            ["memories"] = {
                "shared_memory",
            },
            ["mode"] = "one_shot",
            ["module"] = "PsychopatzCore/ConvoEngine/Behavior/Social/Context",
            ["owner"] = "PsychopatzCore",
            ["requiredFacts"] = {
                "actor.disposition.sociability",
                "relationship.familiarity",
                "stimulus.semantic.intent",
            },
            ["roleSpec"] = {
                ["maxParticipants"] = 2,
                ["minParticipants"] = 2,
                ["roleKinds"] = {
                    ["addressee"] = {
                        "participant",
                    },
                    ["speaker"] = {
                        "participant",
                    },
                },
                ["roles"] = {
                    "addressee",
                    "speaker",
                },
                ["target"] = {
                    ["multiple"] = false,
                    ["required"] = false,
                    ["type"] = "entity.any",
                },
            },
            ["stimuli"] = {
                "NPC_SEMANTIC_ACT",
            },
            ["topics"] = {
            },
        },
        ["behavior.challenge"] = {
            ["act"] = "CHALLENGE",
            ["activities"] = {
            },
            ["baseRelevance"] = 0.5,
            ["domain"] = "social",
            ["domainPath"] = "social/conflict",
            ["domains"] = {
                "social",
            },
            ["events"] = {
            },
            ["id"] = "behavior.challenge",
            ["kind"] = "behavior",
            ["memories"] = {
            },
            ["mode"] = "beat",
            ["module"] = "PsychopatzCore/ConvoEngine/Behavior/Social/Conflict",
            ["owner"] = "PsychopatzCore",
            ["requiredFacts"] = {
                "actor.disposition.confidence",
                "stimulus.semantic.intent",
            },
            ["roleSpec"] = {
                ["maxParticipants"] = 2,
                ["minParticipants"] = 2,
                ["roleKinds"] = {
                    ["addressee"] = {
                        "participant",
                    },
                    ["speaker"] = {
                        "participant",
                    },
                },
                ["roles"] = {
                    "addressee",
                    "speaker",
                },
                ["target"] = {
                    ["multiple"] = false,
                    ["required"] = false,
                    ["type"] = "entity.any",
                },
            },
            ["stimuli"] = {
                "HUMAN_UTTERANCE",
                "NPC_SEMANTIC_ACT",
            },
            ["topics"] = {
                "conflict",
            },
        },
        ["behavior.clarify_context"] = {
            ["act"] = "ASK_CLARIFICATION",
            ["activities"] = {
            },
            ["baseRelevance"] = 0.95,
            ["domain"] = "social",
            ["domainPath"] = "social/context",
            ["domains"] = {
                "social",
            },
            ["events"] = {
            },
            ["id"] = "behavior.clarify_context",
            ["kind"] = "behavior",
            ["memories"] = {
            },
            ["mode"] = "one_shot",
            ["module"] = "PsychopatzCore/ConvoEngine/Behavior/Social/Context",
            ["owner"] = "PsychopatzCore",
            ["requiredFacts"] = {
                "pragmatic.contextualAdmission.status",
            },
            ["roleSpec"] = {
                ["maxParticipants"] = 2,
                ["minParticipants"] = 2,
                ["roleKinds"] = {
                    ["addressee"] = {
                        "participant",
                    },
                    ["speaker"] = {
                        "participant",
                    },
                },
                ["roles"] = {
                    "addressee",
                    "speaker",
                },
                ["target"] = {
                    ["multiple"] = false,
                    ["required"] = false,
                    ["type"] = "entity.any",
                },
            },
            ["stimuli"] = {
                "HUMAN_UTTERANCE",
                "NPC_SEMANTIC_ACT",
            },
            ["topics"] = {
            },
        },
        ["behavior.deescalate"] = {
            ["act"] = "DEESCALATE",
            ["activities"] = {
            },
            ["baseRelevance"] = 0.35,
            ["domain"] = "social",
            ["domainPath"] = "social/repair",
            ["domains"] = {
                "social",
            },
            ["events"] = {
            },
            ["id"] = "behavior.deescalate",
            ["kind"] = "behavior",
            ["memories"] = {
            },
            ["mode"] = "beat",
            ["module"] = "PsychopatzCore/ConvoEngine/Behavior/Social/Repair",
            ["owner"] = "PsychopatzCore",
            ["requiredFacts"] = {
                "actor.condition.panic",
                "stimulus.semantic.speechAct",
                "world.immediateDanger",
            },
            ["roleSpec"] = {
                ["maxParticipants"] = 2,
                ["minParticipants"] = 2,
                ["roleKinds"] = {
                    ["addressee"] = {
                        "participant",
                    },
                    ["speaker"] = {
                        "participant",
                    },
                },
                ["roles"] = {
                    "addressee",
                    "speaker",
                },
                ["target"] = {
                    ["multiple"] = false,
                    ["required"] = false,
                    ["type"] = "entity.any",
                },
            },
            ["stimuli"] = {
                "HUMAN_UTTERANCE",
                "NPC_SEMANTIC_ACT",
            },
            ["topics"] = {
                "repair",
            },
        },
        ["behavior.end_conversation"] = {
            ["act"] = "END_INTERACTION",
            ["activities"] = {
            },
            ["baseRelevance"] = 0.2,
            ["domain"] = "social",
            ["domainPath"] = "social/repair",
            ["domains"] = {
                "social",
            },
            ["events"] = {
            },
            ["id"] = "behavior.end_conversation",
            ["kind"] = "behavior",
            ["memories"] = {
            },
            ["mode"] = "beat",
            ["module"] = "PsychopatzCore/ConvoEngine/Behavior/Social/Repair",
            ["owner"] = "PsychopatzCore",
            ["requiredFacts"] = {
                "actor.disposition.forgiveness",
                "stimulus.semantic.intent",
                "stimulus.semantic.speechAct",
                "world.immediateDanger",
            },
            ["roleSpec"] = {
                ["maxParticipants"] = 2,
                ["minParticipants"] = 2,
                ["roleKinds"] = {
                    ["addressee"] = {
                        "participant",
                    },
                    ["speaker"] = {
                        "participant",
                    },
                },
                ["roles"] = {
                    "addressee",
                    "speaker",
                },
                ["target"] = {
                    ["multiple"] = false,
                    ["required"] = false,
                    ["type"] = "entity.any",
                },
            },
            ["stimuli"] = {
                "HUMAN_UTTERANCE",
                "NPC_SEMANTIC_ACT",
            },
            ["topics"] = {
            },
        },
        ["behavior.reconcile"] = {
            ["act"] = "RECONCILE",
            ["activities"] = {
            },
            ["baseRelevance"] = 0.6,
            ["domain"] = "social",
            ["domainPath"] = "social/repair",
            ["domains"] = {
                "social",
            },
            ["events"] = {
            },
            ["id"] = "behavior.reconcile",
            ["kind"] = "behavior",
            ["memories"] = {
            },
            ["mode"] = "beat",
            ["module"] = "PsychopatzCore/ConvoEngine/Behavior/Social/Repair",
            ["owner"] = "PsychopatzCore",
            ["requiredFacts"] = {
                "actor.disposition.forgiveness",
                "pragmatic.contextualAdmission.admitted",
                "relationship.approval",
                "stimulus.semantic.intent",
            },
            ["roleSpec"] = {
                ["maxParticipants"] = 2,
                ["minParticipants"] = 2,
                ["roleKinds"] = {
                    ["addressee"] = {
                        "participant",
                    },
                    ["speaker"] = {
                        "participant",
                    },
                },
                ["roles"] = {
                    "addressee",
                    "speaker",
                },
                ["target"] = {
                    ["multiple"] = false,
                    ["required"] = false,
                    ["type"] = "entity.any",
                },
            },
            ["stimuli"] = {
                "HUMAN_UTTERANCE",
                "NPC_SEMANTIC_ACT",
            },
            ["topics"] = {
                "repair",
            },
        },
        ["behavior.retaliate_verbally"] = {
            ["act"] = "RETALIATE_VERBALLY",
            ["activities"] = {
            },
            ["baseRelevance"] = 0.55,
            ["domain"] = "social",
            ["domainPath"] = "social/conflict",
            ["domains"] = {
                "social",
            },
            ["events"] = {
            },
            ["id"] = "behavior.retaliate_verbally",
            ["kind"] = "behavior",
            ["memories"] = {
            },
            ["mode"] = "beat",
            ["module"] = "PsychopatzCore/ConvoEngine/Behavior/Social/Conflict",
            ["owner"] = "PsychopatzCore",
            ["requiredFacts"] = {
                "actor.condition.panic",
                "actor.disposition.aggression",
                "stimulus.semantic.speechAct",
            },
            ["roleSpec"] = {
                ["maxParticipants"] = 2,
                ["minParticipants"] = 2,
                ["roleKinds"] = {
                    ["addressee"] = {
                        "participant",
                    },
                    ["speaker"] = {
                        "participant",
                    },
                },
                ["roles"] = {
                    "addressee",
                    "speaker",
                },
                ["target"] = {
                    ["multiple"] = false,
                    ["required"] = false,
                    ["type"] = "entity.any",
                },
            },
            ["stimuli"] = {
                "HUMAN_UTTERANCE",
                "NPC_SEMANTIC_ACT",
            },
            ["topics"] = {
                "conflict",
            },
        },
        ["behavior.warn"] = {
            ["act"] = "WARN",
            ["activities"] = {
            },
            ["baseRelevance"] = 0.65,
            ["domain"] = "social",
            ["domainPath"] = "social/conflict",
            ["domains"] = {
                "social",
            },
            ["events"] = {
            },
            ["id"] = "behavior.warn",
            ["kind"] = "behavior",
            ["memories"] = {
            },
            ["mode"] = "beat",
            ["module"] = "PsychopatzCore/ConvoEngine/Behavior/Social/Conflict",
            ["owner"] = "PsychopatzCore",
            ["requiredFacts"] = {
                "actor.disposition.confidence",
                "relationship.approval",
                "stimulus.semantic.speechAct",
            },
            ["roleSpec"] = {
                ["maxParticipants"] = 2,
                ["minParticipants"] = 2,
                ["roleKinds"] = {
                    ["addressee"] = {
                        "participant",
                    },
                    ["speaker"] = {
                        "participant",
                    },
                },
                ["roles"] = {
                    "addressee",
                    "speaker",
                },
                ["target"] = {
                    ["multiple"] = false,
                    ["required"] = false,
                    ["type"] = "entity.any",
                },
            },
            ["stimuli"] = {
                "HUMAN_UTTERANCE",
                "NPC_SEMANTIC_ACT",
            },
            ["topics"] = {
                "conflict",
            },
        },
        ["behavior.world_event_warn"] = {
            ["act"] = "WARN_GROUP",
            ["activities"] = {
            },
            ["baseRelevance"] = 0.8,
            ["domain"] = "social",
            ["domainPath"] = "social/world_events",
            ["domains"] = {
                "social",
                "world_event",
            },
            ["events"] = {
                "world_event",
            },
            ["id"] = "behavior.world_event_warn",
            ["kind"] = "behavior",
            ["memories"] = {
            },
            ["mode"] = "one_shot",
            ["module"] = "PsychopatzCore/ConvoEngine/Behavior/Social/WorldEvents",
            ["owner"] = "PsychopatzCore",
            ["requiredFacts"] = {
                "world.immediateDanger",
            },
            ["roleSpec"] = {
                ["maxParticipants"] = 2,
                ["minParticipants"] = 2,
                ["roleKinds"] = {
                    ["addressee"] = {
                        "participant",
                    },
                    ["speaker"] = {
                        "participant",
                    },
                },
                ["roles"] = {
                    "addressee",
                    "speaker",
                },
                ["target"] = {
                    ["multiple"] = false,
                    ["required"] = false,
                    ["type"] = "entity.any",
                },
            },
            ["stimuli"] = {
                "DANGER_CHANGED",
                "WORLD_EVENT",
            },
            ["topics"] = {
            },
        },
    },
    ["schema"] = "psychopatz.convo-engine.director-index.v1",
    ["version"] = 1,
}
