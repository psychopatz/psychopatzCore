-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_knowledge_activity",
        ["id"] = "semantic.question.activity.dataset.keep_moving.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.activity.dataset.keep_moving.guarded",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_activity.json#records[0]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CoreKnowledgeActivity/Catalog",
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
                ["category"] = "psychopatzcore:knowledge",
                ["responseTemplateID"] = "semantic.question.activity.dataset.keep_moving",
                ["sourceSurface"] = "content/knowledge/activity.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.guarded.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "We need to keep moving. Sitting still will get us killed.",
                            },
                            ["TL"] = {
                                "Kailangan nating magpatuloy sa paglakad. Mamamatay tayo kapag tumigil dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.guarded.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't loiter. The dead migrate toward stillness.",
                            },
                            ["TL"] = {
                                "Huwag tatambay. Dumarating ang mga patay kapag nanahimik.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.guarded.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Keep your boots moving. Danger is everywhere.",
                            },
                            ["TL"] = {
                                "Igalaw ang mga paa mo. Nasa paligid ang panganib.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.guarded.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "We stay on the road. Tarrying is suicide.",
                            },
                            ["TL"] = {
                                "Manatili tayo sa kalsada. Pagpapatiwakal ang pag-aaksaya ng oras.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.guarded.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Keep moving. Eyes on the woodline.",
                            },
                            ["TL"] = {
                                "Tuloy ang lakad. Tumingin sa kakahuyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.guarded.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No resting in the open. Walk.",
                            },
                            ["TL"] = {
                                "Walang pahinga sa lantad na lugar. Lakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.guarded.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Movement keeps us alive. Don't freeze up.",
                            },
                            ["TL"] = {
                                "Pagkilos ang bumubuhay sa atin. Huwag matulala.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.guarded.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Keep marching. We're too exposed right here.",
                            },
                            ["TL"] = {
                                "Magmartsa pa. Masyado tayong lantad dito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.guarded.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Keep going. Resting here is asking for trouble.",
                            },
                            ["TL"] = {
                                "Tuloy lang. Naghahanap ka ng gulo kapag nagpahinga ka rito.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.guarded.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Step lively. A static survivor is a dead survivor.",
                            },
                            ["TL"] = {
                                "Bilis-bilisan ang hakbang. Ang nakatayong survivor ay patay na survivor.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_knowledge_activity.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_knowledge_activity",
        ["id"] = "semantic.question.activity.dataset.keep_moving.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.activity.dataset.keep_moving.neutral",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_activity.json#records[1]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CoreKnowledgeActivity/Catalog",
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
                ["category"] = "psychopatzcore:knowledge",
                ["responseTemplateID"] = "semantic.question.activity.dataset.keep_moving",
                ["sourceSurface"] = "content/knowledge/activity.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "We should keep moving. It's not safe to linger.",
                            },
                            ["TL"] = {
                                "Dapat tayong magpatuloy sa paglakad. Hindi ligtas magtagal.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Staying mobile is our best option right now.",
                            },
                            ["TL"] = {
                                "Ang pananatiling gumagalaw ang pinakamagandang opsyon natin ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "We need to continue forward and find shelter.",
                            },
                            ["TL"] = {
                                "Kailangan nating magpatuloy pasulong at maghanap ng masisilungan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "It's best if we keep moving down this route.",
                            },
                            ["TL"] = {
                                "Pinakamabuti kung magpapatuloy tayo sa rutang ito.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Let's keep the pace. We have ground to cover.",
                            },
                            ["TL"] = {
                                "Panatilihin natin ang bilis. Marami pa tayong lalakarin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "We shouldn't remain stationary for too long.",
                            },
                            ["TL"] = {
                                "Hindi tayo dapat manatiling nakatigil nang matagal.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Keep walking. We need to reach our objective.",
                            },
                            ["TL"] = {
                                "Magpatuloy sa paglakad. Kailangan nating marating ang layunin natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Moving along is the safest strategy right now.",
                            },
                            ["TL"] = {
                                "Ang pag-usad ang pinakaligtas na stratehiya ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Let's continue on our way.",
                            },
                            ["TL"] = {
                                "Magpatuloy tayo sa ating daan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "We should maintain our momentum and keep moving.",
                            },
                            ["TL"] = {
                                "Dapat nating panatilihin ang ating bwelo at magpatuloy sa paglakad.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_knowledge_activity.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_knowledge_activity",
        ["id"] = "semantic.question.activity.dataset.keep_moving.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.activity.dataset.keep_moving.terse",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_activity.json#records[2]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CoreKnowledgeActivity/Catalog",
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
                ["category"] = "psychopatzcore:knowledge",
                ["responseTemplateID"] = "semantic.question.activity.dataset.keep_moving",
                ["sourceSurface"] = "content/knowledge/activity.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.terse.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Keep moving.",
                            },
                            ["TL"] = {
                                "Tuloy sa paglakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.terse.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Move.",
                            },
                            ["TL"] = {
                                "Galaw.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.terse.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't stop.",
                            },
                            ["TL"] = {
                                "Huwag hihinto.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.terse.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Walk.",
                            },
                            ["TL"] = {
                                "Lakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.terse.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Keep pace.",
                            },
                            ["TL"] = {
                                "Sumabay.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.terse.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Forward.",
                            },
                            ["TL"] = {
                                "Sulong.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.terse.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Keep going.",
                            },
                            ["TL"] = {
                                "Tuloy lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.terse.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Step up.",
                            },
                            ["TL"] = {
                                "Hakbang.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.terse.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't linger.",
                            },
                            ["TL"] = {
                                "Huwag magtagal.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.terse.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "On the move.",
                            },
                            ["TL"] = {
                                "Kilos.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_knowledge_activity.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_knowledge_activity",
        ["id"] = "semantic.question.activity.dataset.keep_moving.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.activity.dataset.keep_moving.warm",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_activity.json#records[3]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CoreKnowledgeActivity/Catalog",
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
                ["category"] = "psychopatzcore:knowledge",
                ["responseTemplateID"] = "semantic.question.activity.dataset.keep_moving",
                ["sourceSurface"] = "content/knowledge/activity.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.warm.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Let's keep moving together, friend. We'll find safety.",
                            },
                            ["TL"] = {
                                "Magpatuloy tayong maglakad nang magkasama, kaibigan. Makakahanap tayo ng kaligtasan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.warm.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "We should keep going. I'll stay right by your side.",
                            },
                            ["TL"] = {
                                "Dapat tayong magpatuloy. Mananatili ako sa tabi mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.warm.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Let's keep our feet moving. A warm fire awaits us eventually.",
                            },
                            ["TL"] = {
                                "Igalaw natin ang mga paa natin. May naghihintay na maaliwalas na apoy sa atin sa dulo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.warm.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Keep up the good pace. We're doing fine.",
                            },
                            ["TL"] = {
                                "Ipagpatuloy ang magandang bilis. Maayos ang lagay natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.warm.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Let's keep walking together. We're safer on the move.",
                            },
                            ["TL"] = {
                                "Sabay tayong maglakad. Mas ligtas tayo habang kumikilos.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.warm.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "We'll get through this path. Just keep moving with me.",
                            },
                            ["TL"] = {
                                "Malalampasan natin ang landas na 'to. Sumabay ka lang sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.warm.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Let's keep going, one step at a time.",
                            },
                            ["TL"] = {
                                "Magpatuloy tayo, bawat hakbang.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.warm.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm with you. Let's keep walking until we find shelter.",
                            },
                            ["TL"] = {
                                "Kasama mo ako. Tuloy lang sa paglakad hanggang makahanap ng silungan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.warm.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Keep moving forward. We've got this.",
                            },
                            ["TL"] = {
                                "Tuloy sa pagsulong. Kaya natin 'to.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.activity.dataset.keep_moving.warm.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Let's keep our spirits up and keep walking.",
                            },
                            ["TL"] = {
                                "Panatilihing mataas ang loob natin at magpatuloy sa paglakad.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_knowledge_activity.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_knowledge_activity",
        ["id"] = "semantic.question.activity.fishing.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.activity.fishing.guarded",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_activity.json#records[4]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CoreKnowledgeActivity/Catalog",
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
                ["category"] = "psychopatzcore:knowledge",
                ["responseTemplateID"] = "semantic.question.activity.fishing",
                ["sourceSurface"] = "content/knowledge/activity.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.fishing.guarded.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Fishing leaves you exposed by the water. Watch your back.",
                            },
                            ["TL"] = {
                                "Nakalantad ka sa tubig kapag nangingisda. Bantayan mo ang likod mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.fishing.guarded.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Water draws the dead. Keep your weapon close while casting.",
                            },
                            ["TL"] = {
                                "Umaakit ng patay ang tubig. Ihanda ang sandata habang naghahagis ng bingwit.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.fishing.guarded.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't get tunnel vision looking at the bobber.",
                            },
                            ["TL"] = {
                                "Huwag matutok sa lumulutang na pamingwit.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.fishing.guarded.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Fish fast and leave. Banks are ambush territory.",
                            },
                            ["TL"] = {
                                "Mangisda nang mabilis at umalis. Lugar ng tambangan ang pampang.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.fishing.guarded.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Quiet catches only. Splashing brings infected.",
                            },
                            ["TL"] = {
                                "Tahimik na huli lang. Ang tilamsik ng tubig ay umaakit ng infected.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.fishing.guarded.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Watch the treeline while you work the line.",
                            },
                            ["TL"] = {
                                "Bantayan ang kakahuyan habang humahawak ng tali.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.fishing.guarded.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "If something rustles in the reeds, drop the rod and draw.",
                            },
                            ["TL"] = {
                                "Kapag may kumaluskos sa talahiban, bitawan ang pamingwit at mag-armas.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.fishing.guarded.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Fishing is risky out here. Keep eyes peeled.",
                            },
                            ["TL"] = {
                                "Delikado ang pangingisda rito. Buksan ang mga mata.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.fishing.guarded.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Get the protein and get off the shore.",
                            },
                            ["TL"] = {
                                "Kunin ang isda at umalis agad sa pampang.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.activity.fishing.guarded.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't get dragged in. Watch the water.",
                            },
                            ["TL"] = {
                                "Huwag magpahila sa tubig. Bantayan ang paligid.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_knowledge_activity.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_knowledge_activity",
        ["id"] = "semantic.question.activity.fishing.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.activity.fishing.neutral",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_activity.json#records[5]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CoreKnowledgeActivity/Catalog",
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
                ["category"] = "psychopatzcore:knowledge",
                ["responseTemplateID"] = "semantic.question.activity.fishing",
                ["sourceSurface"] = "content/knowledge/activity.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.activity.fishing.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Fishing is a solid way to secure fresh food.",
                            },
                            ["TL"] = {
                                "Magandang paraan ang pangingisda para makakuha ng sariwang pagkain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.activity.fishing.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "We can catch fish here if we have rod and bait.",
                            },
                            ["TL"] = {
                                "Makakahuli tayo ng isda rito kung may pamingwit at pain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.activity.fishing.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "The water looks promising for catching dinner.",
                            },
                            ["TL"] = {
                                "Mukhang maganda ang tubig para makahuli ng hapunan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.activity.fishing.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Fishing requires patience, but it provides calories.",
                            },
                            ["TL"] = {
                                "Kailangan ng pasensya sa pangingisda, pero nagbibigay ito ng lakas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.activity.fishing.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "A good spot to cast a line and get some food.",
                            },
                            ["TL"] = {
                                "Magandang lugar para maghulog ng pamingwit at kumuha ng pagkain.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.activity.fishing.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "We should try fishing if our rations are running low.",
                            },
                            ["TL"] = {
                                "Dapat nating subukan ang pangingisda kung paubos na ang rasyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.activity.fishing.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Fish are clean protein out here in the wild.",
                            },
                            ["TL"] = {
                                "Malinis na protina ang isda rito sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.activity.fishing.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Check the line and bait. We could catch something good.",
                            },
                            ["TL"] = {
                                "Tignan ang pisi at pain. Baka makahuli tayo ng maganda.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.activity.fishing.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Fishing by the river is a viable survival task.",
                            },
                            ["TL"] = {
                                "Mabisang gawaing kaligtasan ang pangingisda sa ilog.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.activity.fishing.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "We can cast a line here while the area is clear.",
                            },
                            ["TL"] = {
                                "Pwede tayong maghagis ng pamingwit dito habang malinis ang lugar.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_knowledge_activity.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_knowledge_activity",
        ["id"] = "semantic.question.activity.fishing.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.activity.fishing.terse",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_activity.json#records[6]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CoreKnowledgeActivity/Catalog",
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
                ["category"] = "psychopatzcore:knowledge",
                ["responseTemplateID"] = "semantic.question.activity.fishing",
                ["sourceSurface"] = "content/knowledge/activity.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.activity.fishing.terse.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Fishing.",
                            },
                            ["TL"] = {
                                "Pangingisda.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.activity.fishing.terse.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Cast a line.",
                            },
                            ["TL"] = {
                                "Ihagis ang pamingwit.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.activity.fishing.terse.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Need bait.",
                            },
                            ["TL"] = {
                                "Kailangan ng pain.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.activity.fishing.terse.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Watch the water.",
                            },
                            ["TL"] = {
                                "Bantayan ang tubig.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.activity.fishing.terse.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Good food source.",
                            },
                            ["TL"] = {
                                "Magandang pagkain.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.activity.fishing.terse.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Fish quietly.",
                            },
                            ["TL"] = {
                                "Mangisda nang tahimik.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.activity.fishing.terse.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Cast here.",
                            },
                            ["TL"] = {
                                "Dito maghagis.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.activity.fishing.terse.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Rod and reel.",
                            },
                            ["TL"] = {
                                "Pamingwit at ikutan.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.activity.fishing.terse.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Catch dinner.",
                            },
                            ["TL"] = {
                                "Hulihin ang hapunan.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.activity.fishing.terse.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Fresh fish.",
                            },
                            ["TL"] = {
                                "Sariwang isda.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_knowledge_activity.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_knowledge_activity",
        ["id"] = "semantic.question.activity.fishing.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["sourceId"] = "semantic.question.activity.fishing.warm",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_activity.json#records[7]",
        },
        ["module"] = "PNC/Semantics/Generated/Conversation/PSDL/Dialogue/CoreKnowledgeActivity/Catalog",
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
                ["category"] = "psychopatzcore:knowledge",
                ["responseTemplateID"] = "semantic.question.activity.fishing",
                ["sourceSurface"] = "content/knowledge/activity.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.activity.fishing.warm.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Fishing by the water sounds peaceful right now.",
                            },
                            ["TL"] = {
                                "Mukhang mapayapa ang pangingisda sa tabi ng tubig ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.activity.fishing.warm.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'd love to catch some fresh fish for us to cook.",
                            },
                            ["TL"] = {
                                "Gusto kong makahuli ng sariwang isda para lutuin natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.activity.fishing.warm.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "A nice fresh catch would make a wonderful meal for us.",
                            },
                            ["TL"] = {
                                "Ang sariwang huli ay magiging napakagandang salu-salo para sa atin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.activity.fishing.warm.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "It feels good to take a moment by the water and fish.",
                            },
                            ["TL"] = {
                                "Masarap magpahinga sandali sa tabi ng tubig at mangisda.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.activity.fishing.warm.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Let's see if we can catch something tasty together.",
                            },
                            ["TL"] = {
                                "Tignan natin kung makakahuli tayo ng masarap nang magkasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.activity.fishing.warm.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Fishing reminds me of quieter times. Let's cast a line.",
                            },
                            ["TL"] = {
                                "Naaalala ko ang mga tahimik na panahon sa pangingisda. Maghagis tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.activity.fishing.warm.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "A warm fire and fresh fish would do wonders for our mood.",
                            },
                            ["TL"] = {
                                "Ang maaliwalas na apoy at sariwang isda ay magpapagaan ng loob natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.activity.fishing.warm.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'll keep watch while you fish, or we can take turns.",
                            },
                            ["TL"] = {
                                "Babantayan kita habang nangingisda ka, o magsalitan tayo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.activity.fishing.warm.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Fresh catch would be a real treat for both of us.",
                            },
                            ["TL"] = {
                                "Tunay na pabuya para sa atin ang sariwang huli.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.activity.fishing.warm.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Let's catch a good meal and share it tonight.",
                            },
                            ["TL"] = {
                                "Manghuli tayo ng masarap na pagkain at magsalu-salo ngayong gabi.",
                            },
                        },
                    },
                },
            },
        },
        ["references"] = {
        },
        ["slots"] = {
        },
        ["sourceShard"] = "psdl/dialogue/core_knowledge_activity.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
