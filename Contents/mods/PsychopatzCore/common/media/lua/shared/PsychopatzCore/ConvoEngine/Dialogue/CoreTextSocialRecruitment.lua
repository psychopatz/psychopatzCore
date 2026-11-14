-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_text_social_recruitment",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "All right. I can see the sense in following someone who has earned my trust.",
                                    },
                                    ["TL"] = {
                                        "Sige. Nakikita ko ang kahulugan sa pagsunod sa isang taong nakakuha ng aking tiwala.",
                                    },
                                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "I was hoping you would ask. Give me a place in your group and I will pull my weight.",
                                    },
                                    ["TL"] = {
                                        "Sana magtanong ka. Bigyan mo ako ng lugar sa iyong grupo at hihilahin ko ang aking timbang.",
                                    },
                                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Yes. I respect what you are building, and I would rather help than stand outside it.",
                                    },
                                    ["TL"] = {
                                        "Oo. Nirerespeto ko ang itinatayo mo, at mas gusto kong tumulong kaysa manatili sa labas nito.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "All right. I can see the sense in following someone who has earned my trust.",
                        },
                        ["TL"] = {
                            "Sige. Nakikita ko ang kahulugan sa pagsunod sa isang taong nakakuha ng aking tiwala.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I was hoping you would ask. Give me a place in your group and I will pull my weight.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.admire.say.2.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I was hoping you would ask. Give me a place in your group and I will pull my weight.",
                        },
                        ["TL"] = {
                            "Sana magtanong ka. Bigyan mo ako ng lugar sa iyong grupo at hihilahin ko ang aking timbang.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Yes. I respect what you are building, and I would rather help than stand outside it.",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.admire.say.3.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Yes. I respect what you are building, and I would rather help than stand outside it.",
                        },
                        ["TL"] = {
                            "Oo. Nirerespeto ko ang itinatayo mo, at mas gusto kong tumulong kaysa manatili sa labas nito.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "recruitment.admire",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "admire",
            ["sourceId"] = "recruitment.admire",
            ["sourcePath"] = "dialogue/core_text_social_recruitment/recruitment_admire.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextSocialRecruitment",
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
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["key"] = "recruitment.admire.1",
                        ["text"] = {
                            ["EN"] = "All right. I can see the sense in following someone who has earned my trust.",
                            ["TL"] = "Sige. Nakikita ko ang kahulugan sa pagsunod sa isang taong nakakuha ng aking tiwala.",
                        },
                    },
                    {
                        ["key"] = "recruitment.admire.2",
                        ["text"] = {
                            ["EN"] = "I was hoping you would ask. Give me a place in your group and I will pull my weight.",
                            ["TL"] = "Sana magtanong ka. Bigyan mo ako ng lugar sa iyong grupo at hihilahin ko ang aking timbang.",
                        },
                    },
                    {
                        ["key"] = "recruitment.admire.3",
                        ["text"] = {
                            ["EN"] = "Yes. I respect what you are building, and I would rather help than stand outside it.",
                            ["TL"] = "Oo. Nirerespeto ko ang itinatayo mo, at mas gusto kong tumulong kaysa manatili sa labas nito.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "All right. I can see the sense in following someone who has earned my trust.",
                                    },
                                    ["TL"] = {
                                        "Sige. Nakikita ko ang kahulugan sa pagsunod sa isang taong nakakuha ng aking tiwala.",
                                    },
                                },
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "I was hoping you would ask. Give me a place in your group and I will pull my weight.",
                                    },
                                    ["TL"] = {
                                        "Sana magtanong ka. Bigyan mo ako ng lugar sa iyong grupo at hihilahin ko ang aking timbang.",
                                    },
                                },
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Yes. I respect what you are building, and I would rather help than stand outside it.",
                                    },
                                    ["TL"] = {
                                        "Oo. Nirerespeto ko ang itinatayo mo, at mas gusto kong tumulong kaysa manatili sa labas nito.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
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
                ["translations"] = {
                    ["EN"] = {
                        "All right. I can see the sense in following someone who has earned my trust.",
                    },
                    ["TL"] = {
                        "Sige. Nakikita ko ang kahulugan sa pagsunod sa isang taong nakakuha ng aking tiwala.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I was hoping you would ask. Give me a place in your group and I will pull my weight.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.admire.say.2.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I was hoping you would ask. Give me a place in your group and I will pull my weight.",
                    },
                    ["TL"] = {
                        "Sana magtanong ka. Bigyan mo ako ng lugar sa iyong grupo at hihilahin ko ang aking timbang.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Yes. I respect what you are building, and I would rather help than stand outside it.",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.admire.say.3.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Yes. I respect what you are building, and I would rather help than stand outside it.",
                    },
                    ["TL"] = {
                        "Oo. Nirerespeto ko ang itinatayo mo, at mas gusto kong tumulong kaysa manatili sa labas nito.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_recruitment",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "I do not like being cornered, but I know when I am outmatched. I will come with you.",
                                    },
                                    ["TL"] = {
                                        "Hindi ako mahilig ma-corner, pero alam ko kapag outmatched ako. sasama ako sayo.",
                                    },
                                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Fine. I will follow for now. Keep your word and we will not have a problem.",
                                    },
                                    ["TL"] = {
                                        "ayos lang. Susundan ko muna. Panatilihin ang iyong salita at hindi kami magkakaroon ng problema.",
                                    },
                                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "You have made your point. I will join, but do not mistake caution for friendship yet.",
                                    },
                                    ["TL"] = {
                                        "Nagawa mo na ang punto mo. Sasama ako, pero huwag mong mapagkamalang pagkakaibigan ang pag-iingat ko.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "I do not like being cornered, but I know when I am outmatched. I will come with you.",
                        },
                        ["TL"] = {
                            "Hindi ako mahilig ma-corner, pero alam ko kapag outmatched ako. sasama ako sayo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Fine. I will follow for now. Keep your word and we will not have a problem.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.fear.say.2.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Fine. I will follow for now. Keep your word and we will not have a problem.",
                        },
                        ["TL"] = {
                            "ayos lang. Susundan ko muna. Panatilihin ang iyong salita at hindi kami magkakaroon ng problema.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "You have made your point. I will join, but do not mistake caution for friendship yet.",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.fear.say.3.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "You have made your point. I will join, but do not mistake caution for friendship yet.",
                        },
                        ["TL"] = {
                            "Nagawa mo na ang punto mo. Sasama ako, pero huwag mong mapagkamalang pagkakaibigan ang pag-iingat ko.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "recruitment.fear",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "fear",
            ["sourceId"] = "recruitment.fear",
            ["sourcePath"] = "dialogue/core_text_social_recruitment/recruitment_fear.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextSocialRecruitment",
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
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["key"] = "recruitment.fear.1",
                        ["text"] = {
                            ["EN"] = "I do not like being cornered, but I know when I am outmatched. I will come with you.",
                            ["TL"] = "Hindi ako mahilig ma-corner, pero alam ko kapag outmatched ako. sasama ako sayo.",
                        },
                    },
                    {
                        ["key"] = "recruitment.fear.2",
                        ["text"] = {
                            ["EN"] = "Fine. I will follow for now. Keep your word and we will not have a problem.",
                            ["TL"] = "ayos lang. Susundan ko muna. Panatilihin ang iyong salita at hindi kami magkakaroon ng problema.",
                        },
                    },
                    {
                        ["key"] = "recruitment.fear.3",
                        ["text"] = {
                            ["EN"] = "You have made your point. I will join, but do not mistake caution for friendship yet.",
                            ["TL"] = "Nagawa mo na ang punto mo. Sasama ako, pero huwag mong mapagkamalang pagkakaibigan ang pag-iingat ko.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "I do not like being cornered, but I know when I am outmatched. I will come with you.",
                                    },
                                    ["TL"] = {
                                        "Hindi ako mahilig ma-corner, pero alam ko kapag outmatched ako. sasama ako sayo.",
                                    },
                                },
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Fine. I will follow for now. Keep your word and we will not have a problem.",
                                    },
                                    ["TL"] = {
                                        "ayos lang. Susundan ko muna. Panatilihin ang iyong salita at hindi kami magkakaroon ng problema.",
                                    },
                                },
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "You have made your point. I will join, but do not mistake caution for friendship yet.",
                                    },
                                    ["TL"] = {
                                        "Nagawa mo na ang punto mo. Sasama ako, pero huwag mong mapagkamalang pagkakaibigan ang pag-iingat ko.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
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
                ["translations"] = {
                    ["EN"] = {
                        "I do not like being cornered, but I know when I am outmatched. I will come with you.",
                    },
                    ["TL"] = {
                        "Hindi ako mahilig ma-corner, pero alam ko kapag outmatched ako. sasama ako sayo.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Fine. I will follow for now. Keep your word and we will not have a problem.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.fear.say.2.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Fine. I will follow for now. Keep your word and we will not have a problem.",
                    },
                    ["TL"] = {
                        "ayos lang. Susundan ko muna. Panatilihin ang iyong salita at hindi kami magkakaroon ng problema.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "You have made your point. I will join, but do not mistake caution for friendship yet.",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.fear.say.3.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "You have made your point. I will join, but do not mistake caution for friendship yet.",
                    },
                    ["TL"] = {
                        "Nagawa mo na ang punto mo. Sasama ako, pero huwag mong mapagkamalang pagkakaibigan ang pag-iingat ko.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_recruitment",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "We already had this conversation today. Give me time to think before you press me again.",
                                    },
                                    ["TL"] = {
                                        "Napag-usapan na natin ito ngayon. Bigyan mo ako ng oras mag-isip bago mo ako muling pilitin.",
                                    },
                                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Not again today. Let us see how things stand tomorrow.",
                                    },
                                    ["TL"] = {
                                        "Hindi na ulit ngayon. Tingnan natin kung ano ang mangyayari bukas.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "We already had this conversation today. Give me time to think before you press me again.",
                        },
                        ["TL"] = {
                            "Napag-usapan na natin ito ngayon. Bigyan mo ako ng oras mag-isip bago mo ako muling pilitin.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Not again today. Let us see how things stand tomorrow.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.cooldown.say.2.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Not again today. Let us see how things stand tomorrow.",
                        },
                        ["TL"] = {
                            "Hindi na ulit ngayon. Tingnan natin kung ano ang mangyayari bukas.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "recruitment.reject.cooldown",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "cooldown",
            ["sourceId"] = "recruitment.reject.cooldown",
            ["sourcePath"] = "dialogue/core_text_social_recruitment/recruitment_reject_cooldown.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextSocialRecruitment",
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
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["key"] = "recruitment.reject.cooldown.1",
                        ["text"] = {
                            ["EN"] = "We already had this conversation today. Give me time to think before you press me again.",
                            ["TL"] = "Napag-usapan na natin ito ngayon. Bigyan mo ako ng oras mag-isip bago mo ako muling pilitin.",
                        },
                    },
                    {
                        ["key"] = "recruitment.reject.cooldown.2",
                        ["text"] = {
                            ["EN"] = "Not again today. Let us see how things stand tomorrow.",
                            ["TL"] = "Hindi na ulit ngayon. Tingnan natin kung ano ang mangyayari bukas.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "We already had this conversation today. Give me time to think before you press me again.",
                                    },
                                    ["TL"] = {
                                        "Napag-usapan na natin ito ngayon. Bigyan mo ako ng oras mag-isip bago mo ako muling pilitin.",
                                    },
                                },
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Not again today. Let us see how things stand tomorrow.",
                                    },
                                    ["TL"] = {
                                        "Hindi na ulit ngayon. Tingnan natin kung ano ang mangyayari bukas.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
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
                ["translations"] = {
                    ["EN"] = {
                        "We already had this conversation today. Give me time to think before you press me again.",
                    },
                    ["TL"] = {
                        "Napag-usapan na natin ito ngayon. Bigyan mo ako ng oras mag-isip bago mo ako muling pilitin.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Not again today. Let us see how things stand tomorrow.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.cooldown.say.2.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Not again today. Let us see how things stand tomorrow.",
                    },
                    ["TL"] = {
                        "Hindi na ulit ngayon. Tingnan natin kung ano ang mangyayari bukas.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_recruitment",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "I cannot make that decision right now. There is too much working against it.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko magawa ang desisyong iyon sa ngayon. Masyadong maraming nagtatrabaho laban dito.",
                                    },
                                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "No. I appreciate the offer, but joining you is not possible at the moment.",
                                    },
                                    ["TL"] = {
                                        "Hindi. Pinahahalagahan ko ang alok, ngunit hindi posible ang pagsali sa iyo sa ngayon.",
                                    },
                                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "I need to sort out a few things before I can even consider leaving with you.",
                                    },
                                    ["TL"] = {
                                        "Kailangan kong ayusin ang ilang bagay bago ko maisipang umalis kasama ka.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "I cannot make that decision right now. There is too much working against it.",
                        },
                        ["TL"] = {
                            "Hindi ko magawa ang desisyong iyon sa ngayon. Masyadong maraming nagtatrabaho laban dito.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "No. I appreciate the offer, but joining you is not possible at the moment.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.general.say.2.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "No. I appreciate the offer, but joining you is not possible at the moment.",
                        },
                        ["TL"] = {
                            "Hindi. Pinahahalagahan ko ang alok, ngunit hindi posible ang pagsali sa iyo sa ngayon.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I need to sort out a few things before I can even consider leaving with you.",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.general.say.3.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I need to sort out a few things before I can even consider leaving with you.",
                        },
                        ["TL"] = {
                            "Kailangan kong ayusin ang ilang bagay bago ko maisipang umalis kasama ka.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "recruitment.reject.general",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "general",
            ["sourceId"] = "recruitment.reject.general",
            ["sourcePath"] = "dialogue/core_text_social_recruitment/recruitment_reject_general.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextSocialRecruitment",
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
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["key"] = "recruitment.reject.general.1",
                        ["text"] = {
                            ["EN"] = "I cannot make that decision right now. There is too much working against it.",
                            ["TL"] = "Hindi ko magawa ang desisyong iyon sa ngayon. Masyadong maraming nagtatrabaho laban dito.",
                        },
                    },
                    {
                        ["key"] = "recruitment.reject.general.2",
                        ["text"] = {
                            ["EN"] = "No. I appreciate the offer, but joining you is not possible at the moment.",
                            ["TL"] = "Hindi. Pinahahalagahan ko ang alok, ngunit hindi posible ang pagsali sa iyo sa ngayon.",
                        },
                    },
                    {
                        ["key"] = "recruitment.reject.general.3",
                        ["text"] = {
                            ["EN"] = "I need to sort out a few things before I can even consider leaving with you.",
                            ["TL"] = "Kailangan kong ayusin ang ilang bagay bago ko maisipang umalis kasama ka.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "I cannot make that decision right now. There is too much working against it.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko magawa ang desisyong iyon sa ngayon. Masyadong maraming nagtatrabaho laban dito.",
                                    },
                                },
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "No. I appreciate the offer, but joining you is not possible at the moment.",
                                    },
                                    ["TL"] = {
                                        "Hindi. Pinahahalagahan ko ang alok, ngunit hindi posible ang pagsali sa iyo sa ngayon.",
                                    },
                                },
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "I need to sort out a few things before I can even consider leaving with you.",
                                    },
                                    ["TL"] = {
                                        "Kailangan kong ayusin ang ilang bagay bago ko maisipang umalis kasama ka.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
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
                ["translations"] = {
                    ["EN"] = {
                        "I cannot make that decision right now. There is too much working against it.",
                    },
                    ["TL"] = {
                        "Hindi ko magawa ang desisyong iyon sa ngayon. Masyadong maraming nagtatrabaho laban dito.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "No. I appreciate the offer, but joining you is not possible at the moment.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.general.say.2.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "No. I appreciate the offer, but joining you is not possible at the moment.",
                    },
                    ["TL"] = {
                        "Hindi. Pinahahalagahan ko ang alok, ngunit hindi posible ang pagsali sa iyo sa ngayon.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I need to sort out a few things before I can even consider leaving with you.",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.general.say.3.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I need to sort out a few things before I can even consider leaving with you.",
                    },
                    ["TL"] = {
                        "Kailangan kong ayusin ang ilang bagay bago ko maisipang umalis kasama ka.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_recruitment",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "You want me to join you? Keep your distance.",
                                    },
                                    ["TL"] = {
                                        "Gusto mong sumama ako sa iyo? Lumayo ka.",
                                    },
                                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "I am not joining you. Do not mistake this conversation for trust.",
                                    },
                                    ["TL"] = {
                                        "Hindi ako sasama sa iyo. Huwag mong ipagkamali ang pag-uusap na ito sa tiwala.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "You want me to join you? Keep your distance.",
                        },
                        ["TL"] = {
                            "Gusto mong sumama ako sa iyo? Lumayo ka.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I am not joining you. Do not mistake this conversation for trust.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.hostile.say.2.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I am not joining you. Do not mistake this conversation for trust.",
                        },
                        ["TL"] = {
                            "Hindi ako sasama sa iyo. Huwag mong ipagkamali ang pag-uusap na ito sa tiwala.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "recruitment.reject.hostile",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "hostile",
            ["sourceId"] = "recruitment.reject.hostile",
            ["sourcePath"] = "dialogue/core_text_social_recruitment/recruitment_reject_hostile.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextSocialRecruitment",
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
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["key"] = "recruitment.reject.hostile.1",
                        ["text"] = {
                            ["EN"] = "You want me to join you? Keep your distance.",
                            ["TL"] = "Gusto mong sumama ako sa iyo? Lumayo ka.",
                        },
                    },
                    {
                        ["key"] = "recruitment.reject.hostile.2",
                        ["text"] = {
                            ["EN"] = "I am not joining you. Do not mistake this conversation for trust.",
                            ["TL"] = "Hindi ako sasama sa iyo. Huwag mong ipagkamali ang pag-uusap na ito sa tiwala.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "You want me to join you? Keep your distance.",
                                    },
                                    ["TL"] = {
                                        "Gusto mong sumama ako sa iyo? Lumayo ka.",
                                    },
                                },
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "I am not joining you. Do not mistake this conversation for trust.",
                                    },
                                    ["TL"] = {
                                        "Hindi ako sasama sa iyo. Huwag mong ipagkamali ang pag-uusap na ito sa tiwala.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
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
                ["translations"] = {
                    ["EN"] = {
                        "You want me to join you? Keep your distance.",
                    },
                    ["TL"] = {
                        "Gusto mong sumama ako sa iyo? Lumayo ka.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I am not joining you. Do not mistake this conversation for trust.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.hostile.say.2.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I am not joining you. Do not mistake this conversation for trust.",
                    },
                    ["TL"] = {
                        "Hindi ako sasama sa iyo. Huwag mong ipagkamali ang pag-uusap na ito sa tiwala.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_recruitment",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "I already have people depending on me. I cannot walk away from them for your group.",
                                    },
                                    ["TL"] = {
                                        "May mga tao na akong umaasa sa akin. Hindi ako maaaring lumayo sa kanila para sa iyong grupo.",
                                    },
                                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "I am responsible for this shelter. Until that changes, I am staying here.",
                                    },
                                    ["TL"] = {
                                        "Ako ang may pananagutan sa kanlungang ito. Hanggang sa magbago iyon, nananatili ako rito.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "I already have people depending on me. I cannot walk away from them for your group.",
                        },
                        ["TL"] = {
                            "May mga tao na akong umaasa sa akin. Hindi ako maaaring lumayo sa kanila para sa iyong grupo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I am responsible for this shelter. Until that changes, I am staying here.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.leader.say.2.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I am responsible for this shelter. Until that changes, I am staying here.",
                        },
                        ["TL"] = {
                            "Ako ang may pananagutan sa kanlungang ito. Hanggang sa magbago iyon, nananatili ako rito.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "recruitment.reject.leader",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "leader",
            ["sourceId"] = "recruitment.reject.leader",
            ["sourcePath"] = "dialogue/core_text_social_recruitment/recruitment_reject_leader.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextSocialRecruitment",
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
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["key"] = "recruitment.reject.leader.1",
                        ["text"] = {
                            ["EN"] = "I already have people depending on me. I cannot walk away from them for your group.",
                            ["TL"] = "May mga tao na akong umaasa sa akin. Hindi ako maaaring lumayo sa kanila para sa iyong grupo.",
                        },
                    },
                    {
                        ["key"] = "recruitment.reject.leader.2",
                        ["text"] = {
                            ["EN"] = "I am responsible for this shelter. Until that changes, I am staying here.",
                            ["TL"] = "Ako ang may pananagutan sa kanlungang ito. Hanggang sa magbago iyon, nananatili ako rito.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "I already have people depending on me. I cannot walk away from them for your group.",
                                    },
                                    ["TL"] = {
                                        "May mga tao na akong umaasa sa akin. Hindi ako maaaring lumayo sa kanila para sa iyong grupo.",
                                    },
                                },
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "I am responsible for this shelter. Until that changes, I am staying here.",
                                    },
                                    ["TL"] = {
                                        "Ako ang may pananagutan sa kanlungang ito. Hanggang sa magbago iyon, nananatili ako rito.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
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
                ["translations"] = {
                    ["EN"] = {
                        "I already have people depending on me. I cannot walk away from them for your group.",
                    },
                    ["TL"] = {
                        "May mga tao na akong umaasa sa akin. Hindi ako maaaring lumayo sa kanila para sa iyong grupo.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I am responsible for this shelter. Until that changes, I am staying here.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.leader.say.2.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I am responsible for this shelter. Until that changes, I am staying here.",
                    },
                    ["TL"] = {
                        "Ako ang may pananagutan sa kanlungang ito. Hanggang sa magbago iyon, nananatili ako rito.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_recruitment",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "You are already with us. Ask me about orders instead of recruiting me again.",
                                    },
                                    ["TL"] = {
                                        "Kasama na kita. Magtanong ka na lang tungkol sa mga utos kaysa i-recruit akong muli.",
                                    },
                                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "I am already part of this group.",
                                    },
                                    ["TL"] = {
                                        "Bahagi na ako ng grupong ito.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "You are already with us. Ask me about orders instead of recruiting me again.",
                        },
                        ["TL"] = {
                            "Kasama na kita. Magtanong ka na lang tungkol sa mga utos kaysa i-recruit akong muli.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I am already part of this group.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.member.say.2.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I am already part of this group.",
                        },
                        ["TL"] = {
                            "Bahagi na ako ng grupong ito.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "recruitment.reject.member",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "member",
            ["sourceId"] = "recruitment.reject.member",
            ["sourcePath"] = "dialogue/core_text_social_recruitment/recruitment_reject_member.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextSocialRecruitment",
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
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["key"] = "recruitment.reject.member.1",
                        ["text"] = {
                            ["EN"] = "You are already with us. Ask me about orders instead of recruiting me again.",
                            ["TL"] = "Kasama na kita. Magtanong ka na lang tungkol sa mga utos kaysa i-recruit akong muli.",
                        },
                    },
                    {
                        ["key"] = "recruitment.reject.member.2",
                        ["text"] = {
                            ["EN"] = "I am already part of this group.",
                            ["TL"] = "Bahagi na ako ng grupong ito.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "You are already with us. Ask me about orders instead of recruiting me again.",
                                    },
                                    ["TL"] = {
                                        "Kasama na kita. Magtanong ka na lang tungkol sa mga utos kaysa i-recruit akong muli.",
                                    },
                                },
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "I am already part of this group.",
                                    },
                                    ["TL"] = {
                                        "Bahagi na ako ng grupong ito.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
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
                ["translations"] = {
                    ["EN"] = {
                        "You are already with us. Ask me about orders instead of recruiting me again.",
                    },
                    ["TL"] = {
                        "Kasama na kita. Magtanong ka na lang tungkol sa mga utos kaysa i-recruit akong muli.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I am already part of this group.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.member.say.2.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I am already part of this group.",
                    },
                    ["TL"] = {
                        "Bahagi na ako ng grupong ito.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_recruitment",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "I am not ready to put my life in your hands. We need more time before you ask that again.",
                                    },
                                    ["TL"] = {
                                        "Hindi pa ako handang ibigay ang buhay ko sa iyong mga kamay. Kailangan namin ng mas maraming oras bago mo itanong iyon muli.",
                                    },
                                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Let's keep talking and see how we manage before making any commitments.",
                                    },
                                    ["TL"] = {
                                        "Mag-usap muna tayo at tingnan kung paano tayo magkakasundo bago magdesisyon.",
                                    },
                                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "You seem capable, but I do not know you well enough to join your group.",
                                    },
                                    ["TL"] = {
                                        "Mukhang may kakayahan ka, pero hindi pa kita gaanong kilala para sumama sa grupo mo.",
                                    },
                                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "That is a serious promise. We have not built enough trust for me to make it.",
                                    },
                                    ["TL"] = {
                                        "Seryosong pangako 'yan. Wala pa tayong sapat na tiwala para pumayag ako.",
                                    },
                                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Out here, joining up takes real trust. We aren't there yet.",
                                    },
                                    ["TL"] = {
                                        "Sa panahong ito, kailangan ng matibay na tiwala bago sumama. Hindi pa tayo ganoon kalapit.",
                                    },
                                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'm not looking to tie myself to people I barely know.",
                                    },
                                    ["TL"] = {
                                        "Hindi ako basta-basta sumasama sa taong kakikilala ko pa lang.",
                                    },
                                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "We haven't been through enough together for me to make that call.",
                                    },
                                    ["TL"] = {
                                        "Wala pa tayong pinagsamahan para makapagdesisyon ako nang ganoon kabilis.",
                                    },
                                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "Give it time. Asking someone to join your group isn't a small thing.",
                                    },
                                    ["TL"] = {
                                        "Bigyan muna natin ng oras. Hindi biro ang sumama sa isang grupo.",
                                    },
                                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "I appreciate the thought, but I need to see how you operate first.",
                                    },
                                    ["TL"] = {
                                        "Salamat sa alok, pero gusto ko munang makita kung paano ka kumilos sa labas.",
                                    },
                                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "I'm surviving on my own for now until I'm certain about who has my back.",
                                    },
                                    ["TL"] = {
                                        "Kaya ko pa namang mag-isa sa ngayon habang hindi ko pa nasisigurado kung sino ang maaasahan ko.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "I am not ready to put my life in your hands. We need more time before you ask that again.",
                        },
                        ["TL"] = {
                            "Hindi pa ako handang ibigay ang buhay ko sa iyong mga kamay. Kailangan namin ng mas maraming oras bago mo itanong iyon muli.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "You seem capable, but I do not know you well enough to join your group.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.relationship.say.2.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "You seem capable, but I do not know you well enough to join your group.",
                        },
                        ["TL"] = {
                            "Mukhang may kakayahan ka, pero hindi pa kita gaanong kilala para sumama sa grupo mo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "That is a serious promise. We have not built enough trust for me to make it.",
                    ["realizationKey"] = "3",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.relationship.say.3.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "That is a serious promise. We have not built enough trust for me to make it.",
                        },
                        ["TL"] = {
                            "Seryosong pangako 'yan. Wala pa tayong sapat na tiwala para pumayag ako.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Out here, joining up takes real trust. We aren't there yet.",
                    ["realizationKey"] = "4",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.relationship.say.4.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Out here, joining up takes real trust. We aren't there yet.",
                        },
                        ["TL"] = {
                            "Sa panahong ito, kailangan ng matibay na tiwala bago sumama. Hindi pa tayo ganoon kalapit.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I'm not looking to tie myself to people I barely know.",
                    ["realizationKey"] = "5",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.relationship.say.5.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'm not looking to tie myself to people I barely know.",
                        },
                        ["TL"] = {
                            "Hindi ako basta-basta sumasama sa taong kakikilala ko pa lang.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "We haven't been through enough together for me to make that call.",
                    ["realizationKey"] = "6",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.relationship.say.6.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "We haven't been through enough together for me to make that call.",
                        },
                        ["TL"] = {
                            "Wala pa tayong pinagsamahan para makapagdesisyon ako nang ganoon kabilis.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Give it time. Asking someone to join your group isn't a small thing.",
                    ["realizationKey"] = "7",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.relationship.say.7.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Give it time. Asking someone to join your group isn't a small thing.",
                        },
                        ["TL"] = {
                            "Bigyan muna natin ng oras. Hindi biro ang sumama sa isang grupo.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I appreciate the thought, but I need to see how you operate first.",
                    ["realizationKey"] = "8",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.relationship.say.8.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I appreciate the thought, but I need to see how you operate first.",
                        },
                        ["TL"] = {
                            "Salamat sa alok, pero gusto ko munang makita kung paano ka kumilos sa labas.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "I'm surviving on my own for now until I'm certain about who has my back.",
                    ["realizationKey"] = "9",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.relationship.say.9.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "I'm surviving on my own for now until I'm certain about who has my back.",
                        },
                        ["TL"] = {
                            "Kaya ko pa namang mag-isa sa ngayon habang hindi ko pa nasisigurado kung sino ang maaasahan ko.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "Let's keep talking and see how we manage before making any commitments.",
                    ["realizationKey"] = "10",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.relationship.say.10.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "Let's keep talking and see how we manage before making any commitments.",
                        },
                        ["TL"] = {
                            "Mag-usap muna tayo at tingnan kung paano tayo magkakasundo bago magdesisyon.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "recruitment.reject.relationship",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "relationship",
            ["sourceId"] = "recruitment.reject.relationship",
            ["sourcePath"] = "dialogue/core_text_social_recruitment/recruitment_reject_relationship.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextSocialRecruitment",
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
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["key"] = "recruitment.reject.relationship.1",
                        ["text"] = {
                            ["EN"] = "I am not ready to put my life in your hands. We need more time before you ask that again.",
                            ["TL"] = "Hindi pa ako handang ibigay ang buhay ko sa iyong mga kamay. Kailangan namin ng mas maraming oras bago mo itanong iyon muli.",
                        },
                    },
                    {
                        ["key"] = "recruitment.reject.relationship.2",
                        ["text"] = {
                            ["EN"] = "You seem capable, but I do not know you well enough to join your group.",
                            ["TL"] = "Mukhang may kakayahan ka, pero hindi pa kita gaanong kilala para sumama sa grupo mo.",
                        },
                    },
                    {
                        ["key"] = "recruitment.reject.relationship.3",
                        ["text"] = {
                            ["EN"] = "That is a serious promise. We have not built enough trust for me to make it.",
                            ["TL"] = "Seryosong pangako 'yan. Wala pa tayong sapat na tiwala para pumayag ako.",
                        },
                    },
                    {
                        ["key"] = "recruitment.reject.relationship.4",
                        ["text"] = {
                            ["EN"] = "Out here, joining up takes real trust. We aren't there yet.",
                            ["TL"] = "Sa panahong ito, kailangan ng matibay na tiwala bago sumama. Hindi pa tayo ganoon kalapit.",
                        },
                    },
                    {
                        ["key"] = "recruitment.reject.relationship.5",
                        ["text"] = {
                            ["EN"] = "I'm not looking to tie myself to people I barely know.",
                            ["TL"] = "Hindi ako basta-basta sumasama sa taong kakikilala ko pa lang.",
                        },
                    },
                    {
                        ["key"] = "recruitment.reject.relationship.6",
                        ["text"] = {
                            ["EN"] = "We haven't been through enough together for me to make that call.",
                            ["TL"] = "Wala pa tayong pinagsamahan para makapagdesisyon ako nang ganoon kabilis.",
                        },
                    },
                    {
                        ["key"] = "recruitment.reject.relationship.7",
                        ["text"] = {
                            ["EN"] = "Give it time. Asking someone to join your group isn't a small thing.",
                            ["TL"] = "Bigyan muna natin ng oras. Hindi biro ang sumama sa isang grupo.",
                        },
                    },
                    {
                        ["key"] = "recruitment.reject.relationship.8",
                        ["text"] = {
                            ["EN"] = "I appreciate the thought, but I need to see how you operate first.",
                            ["TL"] = "Salamat sa alok, pero gusto ko munang makita kung paano ka kumilos sa labas.",
                        },
                    },
                    {
                        ["key"] = "recruitment.reject.relationship.9",
                        ["text"] = {
                            ["EN"] = "I'm surviving on my own for now until I'm certain about who has my back.",
                            ["TL"] = "Kaya ko pa namang mag-isa sa ngayon habang hindi ko pa nasisigurado kung sino ang maaasahan ko.",
                        },
                    },
                    {
                        ["key"] = "recruitment.reject.relationship.10",
                        ["text"] = {
                            ["EN"] = "Let's keep talking and see how we manage before making any commitments.",
                            ["TL"] = "Mag-usap muna tayo at tingnan kung paano tayo magkakasundo bago magdesisyon.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "I am not ready to put my life in your hands. We need more time before you ask that again.",
                                    },
                                    ["TL"] = {
                                        "Hindi pa ako handang ibigay ang buhay ko sa iyong mga kamay. Kailangan namin ng mas maraming oras bago mo itanong iyon muli.",
                                    },
                                },
                            },
                        },
                    },
                    ["10"] = {
                        ["key"] = "10",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Let's keep talking and see how we manage before making any commitments.",
                                    },
                                    ["TL"] = {
                                        "Mag-usap muna tayo at tingnan kung paano tayo magkakasundo bago magdesisyon.",
                                    },
                                },
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "You seem capable, but I do not know you well enough to join your group.",
                                    },
                                    ["TL"] = {
                                        "Mukhang may kakayahan ka, pero hindi pa kita gaanong kilala para sumama sa grupo mo.",
                                    },
                                },
                            },
                        },
                    },
                    ["3"] = {
                        ["key"] = "3",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "That is a serious promise. We have not built enough trust for me to make it.",
                                    },
                                    ["TL"] = {
                                        "Seryosong pangako 'yan. Wala pa tayong sapat na tiwala para pumayag ako.",
                                    },
                                },
                            },
                        },
                    },
                    ["4"] = {
                        ["key"] = "4",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Out here, joining up takes real trust. We aren't there yet.",
                                    },
                                    ["TL"] = {
                                        "Sa panahong ito, kailangan ng matibay na tiwala bago sumama. Hindi pa tayo ganoon kalapit.",
                                    },
                                },
                            },
                        },
                    },
                    ["5"] = {
                        ["key"] = "5",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "I'm not looking to tie myself to people I barely know.",
                                    },
                                    ["TL"] = {
                                        "Hindi ako basta-basta sumasama sa taong kakikilala ko pa lang.",
                                    },
                                },
                            },
                        },
                    },
                    ["6"] = {
                        ["key"] = "6",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "We haven't been through enough together for me to make that call.",
                                    },
                                    ["TL"] = {
                                        "Wala pa tayong pinagsamahan para makapagdesisyon ako nang ganoon kabilis.",
                                    },
                                },
                            },
                        },
                    },
                    ["7"] = {
                        ["key"] = "7",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "Give it time. Asking someone to join your group isn't a small thing.",
                                    },
                                    ["TL"] = {
                                        "Bigyan muna natin ng oras. Hindi biro ang sumama sa isang grupo.",
                                    },
                                },
                            },
                        },
                    },
                    ["8"] = {
                        ["key"] = "8",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "I appreciate the thought, but I need to see how you operate first.",
                                    },
                                    ["TL"] = {
                                        "Salamat sa alok, pero gusto ko munang makita kung paano ka kumilos sa labas.",
                                    },
                                },
                            },
                        },
                    },
                    ["9"] = {
                        ["key"] = "9",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "I'm surviving on my own for now until I'm certain about who has my back.",
                                    },
                                    ["TL"] = {
                                        "Kaya ko pa namang mag-isa sa ngayon habang hindi ko pa nasisigurado kung sino ang maaasahan ko.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
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
                ["translations"] = {
                    ["EN"] = {
                        "I am not ready to put my life in your hands. We need more time before you ask that again.",
                    },
                    ["TL"] = {
                        "Hindi pa ako handang ibigay ang buhay ko sa iyong mga kamay. Kailangan namin ng mas maraming oras bago mo itanong iyon muli.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "You seem capable, but I do not know you well enough to join your group.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.relationship.say.2.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "You seem capable, but I do not know you well enough to join your group.",
                    },
                    ["TL"] = {
                        "Mukhang may kakayahan ka, pero hindi pa kita gaanong kilala para sumama sa grupo mo.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "That is a serious promise. We have not built enough trust for me to make it.",
                ["realizationKey"] = "3",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.relationship.say.3.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "That is a serious promise. We have not built enough trust for me to make it.",
                    },
                    ["TL"] = {
                        "Seryosong pangako 'yan. Wala pa tayong sapat na tiwala para pumayag ako.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Out here, joining up takes real trust. We aren't there yet.",
                ["realizationKey"] = "4",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.relationship.say.4.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Out here, joining up takes real trust. We aren't there yet.",
                    },
                    ["TL"] = {
                        "Sa panahong ito, kailangan ng matibay na tiwala bago sumama. Hindi pa tayo ganoon kalapit.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I'm not looking to tie myself to people I barely know.",
                ["realizationKey"] = "5",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.relationship.say.5.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'm not looking to tie myself to people I barely know.",
                    },
                    ["TL"] = {
                        "Hindi ako basta-basta sumasama sa taong kakikilala ko pa lang.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "We haven't been through enough together for me to make that call.",
                ["realizationKey"] = "6",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.relationship.say.6.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "We haven't been through enough together for me to make that call.",
                    },
                    ["TL"] = {
                        "Wala pa tayong pinagsamahan para makapagdesisyon ako nang ganoon kabilis.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Give it time. Asking someone to join your group isn't a small thing.",
                ["realizationKey"] = "7",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.relationship.say.7.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Give it time. Asking someone to join your group isn't a small thing.",
                    },
                    ["TL"] = {
                        "Bigyan muna natin ng oras. Hindi biro ang sumama sa isang grupo.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I appreciate the thought, but I need to see how you operate first.",
                ["realizationKey"] = "8",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.relationship.say.8.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I appreciate the thought, but I need to see how you operate first.",
                    },
                    ["TL"] = {
                        "Salamat sa alok, pero gusto ko munang makita kung paano ka kumilos sa labas.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "I'm surviving on my own for now until I'm certain about who has my back.",
                ["realizationKey"] = "9",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.relationship.say.9.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "I'm surviving on my own for now until I'm certain about who has my back.",
                    },
                    ["TL"] = {
                        "Kaya ko pa namang mag-isa sa ngayon habang hindi ko pa nasisigurado kung sino ang maaasahan ko.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "Let's keep talking and see how we manage before making any commitments.",
                ["realizationKey"] = "10",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.relationship.say.10.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "Let's keep talking and see how we manage before making any commitments.",
                    },
                    ["TL"] = {
                        "Mag-usap muna tayo at tingnan kung paano tayo magkakasundo bago magdesisyon.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_text_social_recruitment",
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "I cannot make that decision while I am unavailable.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko magagawa ang desisyong iyon habang hindi ako available.",
                                    },
                                },
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
                                ["translations"] = {
                                    ["EN"] = {
                                        "This is not a conversation I can have right now.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko maaaring pag-usapan iyan ngayon.",
                                    },
                                },
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
                    ["translations"] = {
                        ["EN"] = {
                            "I cannot make that decision while I am unavailable.",
                        },
                        ["TL"] = {
                            "Hindi ko magagawa ang desisyong iyon habang hindi ako available.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
                {
                    ["fallback"] = "This is not a conversation I can have right now.",
                    ["realizationKey"] = "2",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.recruitment.reject.unavailable.say.2.neutral",
                    ["translations"] = {
                        ["EN"] = {
                            "This is not a conversation I can have right now.",
                        },
                        ["TL"] = {
                            "Hindi ko maaaring pag-usapan iyan ngayon.",
                        },
                    },
                    ["variantID"] = "neutral",
                },
            },
        },
        ["id"] = "recruitment.reject.unavailable",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "unavailable",
            ["sourceId"] = "recruitment.reject.unavailable",
            ["sourcePath"] = "dialogue/core_text_social_recruitment/recruitment_reject_unavailable.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreTextSocialRecruitment",
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
            ["metadata"] = {
                ["textRows"] = {
                    {
                        ["key"] = "recruitment.reject.unavailable.1",
                        ["text"] = {
                            ["EN"] = "I cannot make that decision while I am unavailable.",
                            ["TL"] = "Hindi ko magagawa ang desisyong iyon habang hindi ako available.",
                        },
                    },
                    {
                        ["key"] = "recruitment.reject.unavailable.2",
                        ["text"] = {
                            ["EN"] = "This is not a conversation I can have right now.",
                            ["TL"] = "Hindi ko maaaring pag-usapan iyan ngayon.",
                        },
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
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "I cannot make that decision while I am unavailable.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko magagawa ang desisyong iyon habang hindi ako available.",
                                    },
                                },
                            },
                        },
                    },
                    ["2"] = {
                        ["key"] = "2",
                        ["shorthand"] = false,
                        ["variants"] = {
                            {
                                ["id"] = "neutral",
                                ["text"] = {
                                    ["EN"] = {
                                        "This is not a conversation I can have right now.",
                                    },
                                    ["TL"] = {
                                        "Hindi ko maaaring pag-usapan iyan ngayon.",
                                    },
                                },
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
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
                ["translations"] = {
                    ["EN"] = {
                        "I cannot make that decision while I am unavailable.",
                    },
                    ["TL"] = {
                        "Hindi ko magagawa ang desisyong iyon habang hindi ako available.",
                    },
                },
                ["variantID"] = "neutral",
            },
            {
                ["fallback"] = "This is not a conversation I can have right now.",
                ["realizationKey"] = "2",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.recruitment.reject.unavailable.say.2.neutral",
                ["translations"] = {
                    ["EN"] = {
                        "This is not a conversation I can have right now.",
                    },
                    ["TL"] = {
                        "Hindi ko maaaring pag-usapan iyan ngayon.",
                    },
                },
                ["variantID"] = "neutral",
            },
        },
        ["when"] = nil,
    },
}
