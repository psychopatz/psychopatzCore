-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_text_social_recruitment",
        ["domainPath"] = "core_text_social_recruitment",
        ["exchangeFamily"] = {
            ["familyID"] = "recruitment.admire",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "All right. I can see the sense in following someone who has earned my trust.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.recruitment.admire.say.1.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I was hoping you would ask. Give me a place in your group and I will pull my weight.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.recruitment.admire.say.2.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Yes. I respect what you are building, and I would rather help than stand outside it.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.recruitment.admire.say.3.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "recruitment",
            ["textRoles"] = {
                {
                    ["fallback"] = "All right. I can see the sense in following someone who has earned my trust.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.admire.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I was hoping you would ask. Give me a place in your group and I will pull my weight.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.admire.say.2.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Yes. I respect what you are building, and I would rather help than stand outside it.",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.admire.say.3.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "recruitment.admire",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "admire",
            ["sourceId"] = "recruitment.admire",
            ["sourcePath"] = "dialogue/core_text_social_recruitment/recruitment_admire.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextSocialRecruitment",
        ["namespace"] = "recruitment",
        ["owner"] = "PsychopatzCore",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "PsychopatzCore",
                },
            },
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["fallback"] = "All right. I can see the sense in following someone who has earned my trust.",
                        ["key"] = "recruitment.admire.1",
                    },
                    {
                        ["fallback"] = "I was hoping you would ask. Give me a place in your group and I will pull my weight.",
                        ["key"] = "recruitment.admire.2",
                    },
                    {
                        ["fallback"] = "Yes. I respect what you are building, and I would rather help than stand outside it.",
                        ["key"] = "recruitment.admire.3",
                    },
                },
                ["textTarget"] = "social/recruitment/response",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "All right. I can see the sense in following someone who has earned my trust.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I was hoping you would ask. Give me a place in your group and I will pull my weight.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Yes. I respect what you are building, and I would rather help than stand outside it.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "recruitment",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "recruitment.admire",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "All right. I can see the sense in following someone who has earned my trust.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.recruitment.admire.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
            ["subject"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "subject",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_text_social_recruitment/recruitment_admire.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "All right. I can see the sense in following someone who has earned my trust.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.admire.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I was hoping you would ask. Give me a place in your group and I will pull my weight.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.admire.say.2.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Yes. I respect what you are building, and I would rather help than stand outside it.",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.admire.say.3.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_recruitment",
        ["domainPath"] = "core_text_social_recruitment",
        ["exchangeFamily"] = {
            ["familyID"] = "recruitment.fear",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I do not like being cornered, but I know when I am outmatched. I will come with you.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.recruitment.fear.say.1.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Fine. I will follow for now. Keep your word and we will not have a problem.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.recruitment.fear.say.2.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "You have made your point. I will join, but do not mistake caution for friendship yet.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.recruitment.fear.say.3.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "recruitment",
            ["textRoles"] = {
                {
                    ["fallback"] = "I do not like being cornered, but I know when I am outmatched. I will come with you.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.fear.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Fine. I will follow for now. Keep your word and we will not have a problem.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.fear.say.2.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "You have made your point. I will join, but do not mistake caution for friendship yet.",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.fear.say.3.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "recruitment.fear",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "fear",
            ["sourceId"] = "recruitment.fear",
            ["sourcePath"] = "dialogue/core_text_social_recruitment/recruitment_fear.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextSocialRecruitment",
        ["namespace"] = "recruitment",
        ["owner"] = "PsychopatzCore",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "PsychopatzCore",
                },
            },
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["fallback"] = "I do not like being cornered, but I know when I am outmatched. I will come with you.",
                        ["key"] = "recruitment.fear.1",
                    },
                    {
                        ["fallback"] = "Fine. I will follow for now. Keep your word and we will not have a problem.",
                        ["key"] = "recruitment.fear.2",
                    },
                    {
                        ["fallback"] = "You have made your point. I will join, but do not mistake caution for friendship yet.",
                        ["key"] = "recruitment.fear.3",
                    },
                },
                ["textTarget"] = "social/recruitment/response",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I do not like being cornered, but I know when I am outmatched. I will come with you.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Fine. I will follow for now. Keep your word and we will not have a problem.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "You have made your point. I will join, but do not mistake caution for friendship yet.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "recruitment",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "recruitment.fear",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I do not like being cornered, but I know when I am outmatched. I will come with you.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.recruitment.fear.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
            ["subject"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "subject",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_text_social_recruitment/recruitment_fear.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I do not like being cornered, but I know when I am outmatched. I will come with you.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.fear.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Fine. I will follow for now. Keep your word and we will not have a problem.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.fear.say.2.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "You have made your point. I will join, but do not mistake caution for friendship yet.",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.fear.say.3.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_recruitment",
        ["domainPath"] = "core_text_social_recruitment",
        ["exchangeFamily"] = {
            ["familyID"] = "recruitment.reject.cooldown",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "We already had this conversation today. Give me time to think before you press me again.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.recruitment.reject.cooldown.say.1.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Not again today. Let us see how things stand tomorrow.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.recruitment.reject.cooldown.say.2.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "recruitment.reject",
            ["textRoles"] = {
                {
                    ["fallback"] = "We already had this conversation today. Give me time to think before you press me again.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.cooldown.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Not again today. Let us see how things stand tomorrow.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.cooldown.say.2.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "recruitment.reject.cooldown",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "cooldown",
            ["sourceId"] = "recruitment.reject.cooldown",
            ["sourcePath"] = "dialogue/core_text_social_recruitment/recruitment_reject_cooldown.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextSocialRecruitment",
        ["namespace"] = "recruitment.reject",
        ["owner"] = "PsychopatzCore",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "PsychopatzCore",
                },
            },
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["fallback"] = "We already had this conversation today. Give me time to think before you press me again.",
                        ["key"] = "recruitment.reject.cooldown.1",
                    },
                    {
                        ["fallback"] = "Not again today. Let us see how things stand tomorrow.",
                        ["key"] = "recruitment.reject.cooldown.2",
                    },
                },
                ["textTarget"] = "social/recruitment/response",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "We already had this conversation today. Give me time to think before you press me again.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Not again today. Let us see how things stand tomorrow.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "recruitment",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "recruitment.reject.cooldown",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "We already had this conversation today. Give me time to think before you press me again.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.recruitment.reject.cooldown.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
            ["subject"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "subject",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_text_social_recruitment/recruitment_reject_cooldown.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "We already had this conversation today. Give me time to think before you press me again.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.cooldown.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Not again today. Let us see how things stand tomorrow.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.cooldown.say.2.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_recruitment",
        ["domainPath"] = "core_text_social_recruitment",
        ["exchangeFamily"] = {
            ["familyID"] = "recruitment.reject.general",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I cannot make that decision right now. There is too much working against it.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.recruitment.reject.general.say.1.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "No. I appreciate the offer, but joining you is not possible at the moment.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.recruitment.reject.general.say.2.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I need to sort out a few things before I can even consider leaving with you.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.recruitment.reject.general.say.3.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "recruitment.reject",
            ["textRoles"] = {
                {
                    ["fallback"] = "I cannot make that decision right now. There is too much working against it.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.general.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "No. I appreciate the offer, but joining you is not possible at the moment.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.general.say.2.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I need to sort out a few things before I can even consider leaving with you.",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.general.say.3.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "recruitment.reject.general",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "general",
            ["sourceId"] = "recruitment.reject.general",
            ["sourcePath"] = "dialogue/core_text_social_recruitment/recruitment_reject_general.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextSocialRecruitment",
        ["namespace"] = "recruitment.reject",
        ["owner"] = "PsychopatzCore",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "PsychopatzCore",
                },
            },
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["fallback"] = "I cannot make that decision right now. There is too much working against it.",
                        ["key"] = "recruitment.reject.general.1",
                    },
                    {
                        ["fallback"] = "No. I appreciate the offer, but joining you is not possible at the moment.",
                        ["key"] = "recruitment.reject.general.2",
                    },
                    {
                        ["fallback"] = "I need to sort out a few things before I can even consider leaving with you.",
                        ["key"] = "recruitment.reject.general.3",
                    },
                },
                ["textTarget"] = "social/recruitment/response",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I cannot make that decision right now. There is too much working against it.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "No. I appreciate the offer, but joining you is not possible at the moment.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I need to sort out a few things before I can even consider leaving with you.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "recruitment",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "recruitment.reject.general",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I cannot make that decision right now. There is too much working against it.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.recruitment.reject.general.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
            ["subject"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "subject",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_text_social_recruitment/recruitment_reject_general.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I cannot make that decision right now. There is too much working against it.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.general.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "No. I appreciate the offer, but joining you is not possible at the moment.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.general.say.2.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I need to sort out a few things before I can even consider leaving with you.",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.general.say.3.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_recruitment",
        ["domainPath"] = "core_text_social_recruitment",
        ["exchangeFamily"] = {
            ["familyID"] = "recruitment.reject.hostile",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "You want me to join you? Keep your distance.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.recruitment.reject.hostile.say.1.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I am not joining you. Do not mistake this conversation for trust.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.recruitment.reject.hostile.say.2.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "recruitment.reject",
            ["textRoles"] = {
                {
                    ["fallback"] = "You want me to join you? Keep your distance.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.hostile.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I am not joining you. Do not mistake this conversation for trust.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.hostile.say.2.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "recruitment.reject.hostile",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "hostile",
            ["sourceId"] = "recruitment.reject.hostile",
            ["sourcePath"] = "dialogue/core_text_social_recruitment/recruitment_reject_hostile.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextSocialRecruitment",
        ["namespace"] = "recruitment.reject",
        ["owner"] = "PsychopatzCore",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "PsychopatzCore",
                },
            },
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["fallback"] = "You want me to join you? Keep your distance.",
                        ["key"] = "recruitment.reject.hostile.1",
                    },
                    {
                        ["fallback"] = "I am not joining you. Do not mistake this conversation for trust.",
                        ["key"] = "recruitment.reject.hostile.2",
                    },
                },
                ["textTarget"] = "social/recruitment/response",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "You want me to join you? Keep your distance.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I am not joining you. Do not mistake this conversation for trust.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "recruitment",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "recruitment.reject.hostile",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "You want me to join you? Keep your distance.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.recruitment.reject.hostile.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
            ["subject"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "subject",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_text_social_recruitment/recruitment_reject_hostile.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "You want me to join you? Keep your distance.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.hostile.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I am not joining you. Do not mistake this conversation for trust.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.hostile.say.2.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_recruitment",
        ["domainPath"] = "core_text_social_recruitment",
        ["exchangeFamily"] = {
            ["familyID"] = "recruitment.reject.leader",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I already have people depending on me. I cannot walk away from them for your group.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.recruitment.reject.leader.say.1.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I am responsible for this shelter. Until that changes, I am staying here.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.recruitment.reject.leader.say.2.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "recruitment.reject",
            ["textRoles"] = {
                {
                    ["fallback"] = "I already have people depending on me. I cannot walk away from them for your group.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.leader.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I am responsible for this shelter. Until that changes, I am staying here.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.leader.say.2.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "recruitment.reject.leader",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "leader",
            ["sourceId"] = "recruitment.reject.leader",
            ["sourcePath"] = "dialogue/core_text_social_recruitment/recruitment_reject_leader.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextSocialRecruitment",
        ["namespace"] = "recruitment.reject",
        ["owner"] = "PsychopatzCore",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "PsychopatzCore",
                },
            },
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["fallback"] = "I already have people depending on me. I cannot walk away from them for your group.",
                        ["key"] = "recruitment.reject.leader.1",
                    },
                    {
                        ["fallback"] = "I am responsible for this shelter. Until that changes, I am staying here.",
                        ["key"] = "recruitment.reject.leader.2",
                    },
                },
                ["textTarget"] = "social/recruitment/response",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I already have people depending on me. I cannot walk away from them for your group.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I am responsible for this shelter. Until that changes, I am staying here.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "recruitment",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "recruitment.reject.leader",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I already have people depending on me. I cannot walk away from them for your group.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.recruitment.reject.leader.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
            ["subject"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "subject",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_text_social_recruitment/recruitment_reject_leader.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I already have people depending on me. I cannot walk away from them for your group.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.leader.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I am responsible for this shelter. Until that changes, I am staying here.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.leader.say.2.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_recruitment",
        ["domainPath"] = "core_text_social_recruitment",
        ["exchangeFamily"] = {
            ["familyID"] = "recruitment.reject.member",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "You are already with us. Ask me about orders instead of recruiting me again.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.recruitment.reject.member.say.1.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I am already part of this group.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.recruitment.reject.member.say.2.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "recruitment.reject",
            ["textRoles"] = {
                {
                    ["fallback"] = "You are already with us. Ask me about orders instead of recruiting me again.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.member.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I am already part of this group.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.member.say.2.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "recruitment.reject.member",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "member",
            ["sourceId"] = "recruitment.reject.member",
            ["sourcePath"] = "dialogue/core_text_social_recruitment/recruitment_reject_member.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextSocialRecruitment",
        ["namespace"] = "recruitment.reject",
        ["owner"] = "PsychopatzCore",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "PsychopatzCore",
                },
            },
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["fallback"] = "You are already with us. Ask me about orders instead of recruiting me again.",
                        ["key"] = "recruitment.reject.member.1",
                    },
                    {
                        ["fallback"] = "I am already part of this group.",
                        ["key"] = "recruitment.reject.member.2",
                    },
                },
                ["textTarget"] = "social/recruitment/response",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "You are already with us. Ask me about orders instead of recruiting me again.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I am already part of this group.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "recruitment",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "recruitment.reject.member",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "You are already with us. Ask me about orders instead of recruiting me again.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.recruitment.reject.member.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
            ["subject"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "subject",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_text_social_recruitment/recruitment_reject_member.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "You are already with us. Ask me about orders instead of recruiting me again.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.member.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I am already part of this group.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.member.say.2.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_recruitment",
        ["domainPath"] = "core_text_social_recruitment",
        ["exchangeFamily"] = {
            ["familyID"] = "recruitment.reject.relationship",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                    "4",
                    "5",
                    "6",
                    "7",
                    "8",
                    "9",
                    "10",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I am not ready to put my life in your hands. We need more time before you ask that again.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.recruitment.reject.relationship.say.1.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["10"] = {
                        ["key"] = "10",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Let's keep talking and see how we manage before making any commitments.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.recruitment.reject.relationship.say.10.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "You seem capable, but I do not know you well enough to join your group.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.recruitment.reject.relationship.say.2.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "That is a serious promise. We have not built enough trust for me to make it.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.recruitment.reject.relationship.say.3.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["4"] = {
                        ["key"] = "4",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Out here, joining up takes real trust. We aren't there yet.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.recruitment.reject.relationship.say.4.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["5"] = {
                        ["key"] = "5",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I'm not looking to tie myself to people I barely know.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.recruitment.reject.relationship.say.5.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["6"] = {
                        ["key"] = "6",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "We haven't been through enough together for me to make that call.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.recruitment.reject.relationship.say.6.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["7"] = {
                        ["key"] = "7",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Give it time. Asking someone to join your group isn't a small thing.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.recruitment.reject.relationship.say.7.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["8"] = {
                        ["key"] = "8",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I appreciate the thought, but I need to see how you operate first.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.recruitment.reject.relationship.say.8.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["9"] = {
                        ["key"] = "9",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I'm surviving on my own for now until I'm certain about who has my back.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.recruitment.reject.relationship.say.9.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "recruitment.reject",
            ["textRoles"] = {
                {
                    ["fallback"] = "I am not ready to put my life in your hands. We need more time before you ask that again.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.relationship.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "You seem capable, but I do not know you well enough to join your group.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.relationship.say.2.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "That is a serious promise. We have not built enough trust for me to make it.",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.relationship.say.3.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Out here, joining up takes real trust. We aren't there yet.",
                    ["realizationKey"] = "4",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.relationship.say.4.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I'm not looking to tie myself to people I barely know.",
                    ["realizationKey"] = "5",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.relationship.say.5.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "We haven't been through enough together for me to make that call.",
                    ["realizationKey"] = "6",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.relationship.say.6.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Give it time. Asking someone to join your group isn't a small thing.",
                    ["realizationKey"] = "7",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.relationship.say.7.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I appreciate the thought, but I need to see how you operate first.",
                    ["realizationKey"] = "8",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.relationship.say.8.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I'm surviving on my own for now until I'm certain about who has my back.",
                    ["realizationKey"] = "9",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.relationship.say.9.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Let's keep talking and see how we manage before making any commitments.",
                    ["realizationKey"] = "10",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.relationship.say.10.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "recruitment.reject.relationship",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "relationship",
            ["sourceId"] = "recruitment.reject.relationship",
            ["sourcePath"] = "dialogue/core_text_social_recruitment/recruitment_reject_relationship.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextSocialRecruitment",
        ["namespace"] = "recruitment.reject",
        ["owner"] = "PsychopatzCore",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "PsychopatzCore",
                },
            },
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["fallback"] = "I am not ready to put my life in your hands. We need more time before you ask that again.",
                        ["key"] = "recruitment.reject.relationship.1",
                    },
                    {
                        ["fallback"] = "You seem capable, but I do not know you well enough to join your group.",
                        ["key"] = "recruitment.reject.relationship.2",
                    },
                    {
                        ["fallback"] = "That is a serious promise. We have not built enough trust for me to make it.",
                        ["key"] = "recruitment.reject.relationship.3",
                    },
                    {
                        ["fallback"] = "Out here, joining up takes real trust. We aren't there yet.",
                        ["key"] = "recruitment.reject.relationship.4",
                    },
                    {
                        ["fallback"] = "I'm not looking to tie myself to people I barely know.",
                        ["key"] = "recruitment.reject.relationship.5",
                    },
                    {
                        ["fallback"] = "We haven't been through enough together for me to make that call.",
                        ["key"] = "recruitment.reject.relationship.6",
                    },
                    {
                        ["fallback"] = "Give it time. Asking someone to join your group isn't a small thing.",
                        ["key"] = "recruitment.reject.relationship.7",
                    },
                    {
                        ["fallback"] = "I appreciate the thought, but I need to see how you operate first.",
                        ["key"] = "recruitment.reject.relationship.8",
                    },
                    {
                        ["fallback"] = "I'm surviving on my own for now until I'm certain about who has my back.",
                        ["key"] = "recruitment.reject.relationship.9",
                    },
                    {
                        ["fallback"] = "Let's keep talking and see how we manage before making any commitments.",
                        ["key"] = "recruitment.reject.relationship.10",
                    },
                },
                ["textTarget"] = "social/recruitment/response",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                    "3",
                    "4",
                    "5",
                    "6",
                    "7",
                    "8",
                    "9",
                    "10",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I am not ready to put my life in your hands. We need more time before you ask that again.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["10"] = {
                        ["key"] = "10",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Let's keep talking and see how we manage before making any commitments.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "You seem capable, but I do not know you well enough to join your group.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "That is a serious promise. We have not built enough trust for me to make it.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["4"] = {
                        ["key"] = "4",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Out here, joining up takes real trust. We aren't there yet.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["5"] = {
                        ["key"] = "5",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I'm not looking to tie myself to people I barely know.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["6"] = {
                        ["key"] = "6",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "We haven't been through enough together for me to make that call.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["7"] = {
                        ["key"] = "7",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "Give it time. Asking someone to join your group isn't a small thing.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["8"] = {
                        ["key"] = "8",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I appreciate the thought, but I need to see how you operate first.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["9"] = {
                        ["key"] = "9",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I'm surviving on my own for now until I'm certain about who has my back.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "recruitment",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "recruitment.reject.relationship",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I am not ready to put my life in your hands. We need more time before you ask that again.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.recruitment.reject.relationship.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
            ["subject"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "subject",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_text_social_recruitment/recruitment_reject_relationship.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I am not ready to put my life in your hands. We need more time before you ask that again.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.relationship.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "You seem capable, but I do not know you well enough to join your group.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.relationship.say.2.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "That is a serious promise. We have not built enough trust for me to make it.",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.relationship.say.3.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Out here, joining up takes real trust. We aren't there yet.",
                ["realizationKey"] = "4",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.relationship.say.4.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I'm not looking to tie myself to people I barely know.",
                ["realizationKey"] = "5",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.relationship.say.5.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "We haven't been through enough together for me to make that call.",
                ["realizationKey"] = "6",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.relationship.say.6.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Give it time. Asking someone to join your group isn't a small thing.",
                ["realizationKey"] = "7",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.relationship.say.7.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I appreciate the thought, but I need to see how you operate first.",
                ["realizationKey"] = "8",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.relationship.say.8.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I'm surviving on my own for now until I'm certain about who has my back.",
                ["realizationKey"] = "9",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.relationship.say.9.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Let's keep talking and see how we manage before making any commitments.",
                ["realizationKey"] = "10",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.relationship.say.10.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_recruitment",
        ["domainPath"] = "core_text_social_recruitment",
        ["exchangeFamily"] = {
            ["familyID"] = "recruitment.reject.unavailable",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I cannot make that decision while I am unavailable.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.recruitment.reject.unavailable.say.1.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "This is not a conversation I can have right now.",
                                ["id"] = "neutral",
                                ["templateID"] = "convo.recruitment.reject.unavailable.say.2.neutral",
                                ["textRole"] = "spoken_action",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "recruitment.reject",
            ["textRoles"] = {
                {
                    ["fallback"] = "I cannot make that decision while I am unavailable.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.unavailable.say.1.neutral",
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "This is not a conversation I can have right now.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.unavailable.say.2.neutral",
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "recruitment.reject.unavailable",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "unavailable",
            ["sourceId"] = "recruitment.reject.unavailable",
            ["sourcePath"] = "dialogue/core_text_social_recruitment/recruitment_reject_unavailable.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PsychopatzCore/ConvoEngine/Dialogue/CoreTextSocialRecruitment",
        ["namespace"] = "recruitment.reject",
        ["owner"] = "PsychopatzCore",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "PsychopatzCore",
                },
            },
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["fallback"] = "I cannot make that decision while I am unavailable.",
                        ["key"] = "recruitment.reject.unavailable.1",
                    },
                    {
                        ["fallback"] = "This is not a conversation I can have right now.",
                        ["key"] = "recruitment.reject.unavailable.2",
                    },
                },
                ["textTarget"] = "social/recruitment/response",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                    "2",
                },
                ["mode"] = "keyed",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "I cannot make that decision while I am unavailable.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["fallback"] = "This is not a conversation I can have right now.",
                                ["id"] = "neutral",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "recruitment",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = nil,
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "recruitment.reject.unavailable",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "I cannot make that decision while I am unavailable.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.recruitment.reject.unavailable.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
            ["subject"] = {
                ["cardinality"] = "OPTIONAL_ONE",
                ["kinds"] = {
                    "actor",
                    "entity",
                },
                ["role"] = "subject",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/core_text_social_recruitment/recruitment_reject_unavailable.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "I cannot make that decision while I am unavailable.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.unavailable.say.1.neutral",
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "This is not a conversation I can have right now.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.unavailable.say.2.neutral",
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
