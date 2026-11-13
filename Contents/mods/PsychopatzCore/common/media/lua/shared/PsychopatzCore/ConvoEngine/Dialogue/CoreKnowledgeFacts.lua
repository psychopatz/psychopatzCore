-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_knowledge_facts",
        ["id"] = "semantic.question.knowledge.known.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.question.knowledge.known.guarded",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_facts.json#records[0]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreKnowledgeFacts",
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
                ["responseTemplateID"] = "semantic.question.knowledge.known",
                ["sourceSurface"] = "content/knowledge/knowledge.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.known.guarded.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I know enough about {target.name}.",
                            },
                            ["TL"] = {
                                "Sapat ang alam ko tungkol sa {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.known.guarded.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm aware of {target.name}, but keep it quiet.",
                            },
                            ["TL"] = {
                                "Alam ko ang {target.name}, pero huwag mong ipagsabi.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.known.guarded.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I know about {target.name}. Don't shout it out.",
                            },
                            ["TL"] = {
                                "May alam ako sa {target.name}. Huwag mong ipagsigawan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.known.guarded.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Yes, I know {target.name}. What of it?",
                            },
                            ["TL"] = {
                                "Oo, alam ko ang {target.name}. Ano naman?",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.known.guarded.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I have information on {target.name}. Keep your voice down.",
                            },
                            ["TL"] = {
                                "Nasa akin ang impormasyon sa {target.name}. Hinaan mo ang boses mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.known.guarded.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I know what {target.name} is. Be cautious.",
                            },
                            ["TL"] = {
                                "Alam ko kung ano ang {target.name}. Mag-ingat ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.known.guarded.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm familiar with {target.name}. Don't spread it around.",
                            },
                            ["TL"] = {
                                "Pamilyar ako sa {target.name}. Huwag mong ikalat.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.known.guarded.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Yes, I know {target.name}. It's dangerous knowledge.",
                            },
                            ["TL"] = {
                                "Oo, alam ko ang {target.name}. Delikadong kaalaman 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.known.guarded.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I know about {target.name}. Keep it between us.",
                            },
                            ["TL"] = {
                                "May alam ako tungkol sa {target.name}. Atin-atin lang 'to.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.known.guarded.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Yes, I'm aware of {target.name}. Don't bring trouble our way.",
                            },
                            ["TL"] = {
                                "Oo, alam ko ang tungkol sa {target.name}. Huwag kang magdala ng gulo sa atin.",
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
        ["sourceShard"] = "psdl/dialogue/core_knowledge_facts.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_knowledge_facts",
        ["id"] = "semantic.question.knowledge.known.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.question.knowledge.known.neutral",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_facts.json#records[1]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreKnowledgeFacts",
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
                ["responseTemplateID"] = "semantic.question.knowledge.known",
                ["sourceSurface"] = "content/knowledge/knowledge.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.known.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I know about {target.name}.",
                            },
                            ["TL"] = {
                                "May alam ako tungkol sa {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.known.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Yes, I know about {target.name}.",
                            },
                            ["TL"] = {
                                "Oo, may alam ako tungkol sa {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.known.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm familiar with {target.name}.",
                            },
                            ["TL"] = {
                                "Pamilyar ako sa {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.known.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I have knowledge of {target.name}.",
                            },
                            ["TL"] = {
                                "May kaalaman ako sa {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.known.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Yes, I understand about {target.name}.",
                            },
                            ["TL"] = {
                                "Oo, nauunawaan ko ang tungkol sa {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.known.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm aware of {target.name}.",
                            },
                            ["TL"] = {
                                "Batid ko ang tungkol sa {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.known.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I know the situation with {target.name}.",
                            },
                            ["TL"] = {
                                "Alam ko ang sitwasyon sa {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.known.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Information on {target.name} is known to me.",
                            },
                            ["TL"] = {
                                "Batid ko ang impormasyon sa {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.known.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Yes, I've learned about {target.name} already.",
                            },
                            ["TL"] = {
                                "Oo, nalaman ko na ang tungkol sa {target.name} noon pa.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.known.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I have reliable word on {target.name}.",
                            },
                            ["TL"] = {
                                "Maaasahan ang balita ko tungkol sa {target.name}.",
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
        ["sourceShard"] = "psdl/dialogue/core_knowledge_facts.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_knowledge_facts",
        ["id"] = "semantic.question.knowledge.known.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.question.knowledge.known.terse",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_facts.json#records[2]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreKnowledgeFacts",
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
                ["responseTemplateID"] = "semantic.question.knowledge.known",
                ["sourceSurface"] = "content/knowledge/knowledge.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.known.terse.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I know {target.name}.",
                            },
                            ["TL"] = {
                                "Alam ko ang {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.known.terse.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Know it: {target.name}.",
                            },
                            ["TL"] = {
                                "Alam ko: {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.known.terse.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Aware of {target.name}.",
                            },
                            ["TL"] = {
                                "Batid ang {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.known.terse.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Familiar with {target.name}.",
                            },
                            ["TL"] = {
                                "Pamilyar sa {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.known.terse.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Yes, {target.name}.",
                            },
                            ["TL"] = {
                                "Oo, {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.known.terse.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Heard of {target.name}.",
                            },
                            ["TL"] = {
                                "Narinig ang {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.known.terse.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Got info on {target.name}.",
                            },
                            ["TL"] = {
                                "May balita sa {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.known.terse.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Understood: {target.name}.",
                            },
                            ["TL"] = {
                                "Naintindihan: {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.known.terse.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Already know {target.name}.",
                            },
                            ["TL"] = {
                                "Alam na ang {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.known.terse.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Clear on {target.name}.",
                            },
                            ["TL"] = {
                                "Malinaw sa {target.name}.",
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
        ["sourceShard"] = "psdl/dialogue/core_knowledge_facts.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_knowledge_facts",
        ["id"] = "semantic.question.knowledge.known.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.question.knowledge.known.warm",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_facts.json#records[3]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreKnowledgeFacts",
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
                ["responseTemplateID"] = "semantic.question.knowledge.known",
                ["sourceSurface"] = "content/knowledge/knowledge.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.known.warm.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I know about {target.name}.",
                            },
                            ["TL"] = {
                                "May alam ako tungkol sa {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.known.warm.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Yes, I know about {target.name}! Glad you asked.",
                            },
                            ["TL"] = {
                                "Oo, may alam ako tungkol sa {target.name}! Mabuti at nagtanong ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.known.warm.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm happy to share what I know about {target.name}.",
                            },
                            ["TL"] = {
                                "Masaya akong ibahagi sa'yo kung ano ang nalalaman ko sa {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.known.warm.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I do know about {target.name}, friend. Let's discuss it.",
                            },
                            ["TL"] = {
                                "May alam ako sa {target.name}, kaibigan. Pag-usapan natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.known.warm.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm quite familiar with {target.name}. What would you like to know?",
                            },
                            ["TL"] = {
                                "Pamilyar ako sa {target.name}. Ano'ng gusto mong malaman?",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.known.warm.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Yes, I've got good knowledge on {target.name}.",
                            },
                            ["TL"] = {
                                "Oo, may magandang kaalaman ako tungkol sa {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.known.warm.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I know {target.name} well! Always happy to talk it through.",
                            },
                            ["TL"] = {
                                "Alam na alam ko ang {target.name}! Laging masayang pag-usapan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.known.warm.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I can definitely fill you in on {target.name}.",
                            },
                            ["TL"] = {
                                "Tiyak na matutulungan kita tungkol sa {target.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.known.warm.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I know about {target.name}, happy to answer your questions.",
                            },
                            ["TL"] = {
                                "May alam ako sa {target.name}, masayang sagutin ang mga tanong mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.known.warm.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Yes, I'm well acquainted with {target.name}, my friend.",
                            },
                            ["TL"] = {
                                "Oo, kabisado ko ang {target.name}, kaibigan.",
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
        ["sourceShard"] = "psdl/dialogue/core_knowledge_facts.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_knowledge_facts",
        ["id"] = "semantic.question.knowledge.unknown.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.question.knowledge.unknown.guarded",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_facts.json#records[4]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreKnowledgeFacts",
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
                ["responseTemplateID"] = "semantic.question.knowledge.unknown",
                ["sourceSurface"] = "content/knowledge/knowledge.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.unknown.guarded.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I don't know anything about that.",
                            },
                            ["TL"] = {
                                "Wala akong alam tungkol diyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.unknown.guarded.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Haven't heard of it. Don't waste time on wild goose chases.",
                            },
                            ["TL"] = {
                                "Hindi ko narinig 'yan. Huwag magsayang ng oras sa walang kabuluhan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.unknown.guarded.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No idea. Keep your thoughts on what's in front of us.",
                            },
                            ["TL"] = {
                                "Walang ideya. Ituon ang isip sa kung ano ang nasa harap natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.unknown.guarded.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I know nothing about that topic. Drop it.",
                            },
                            ["TL"] = {
                                "Wala akong alam sa paksang 'yan. Kalimutan mo na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.unknown.guarded.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Never crossed my path. Stay alert.",
                            },
                            ["TL"] = {
                                "Hindi pa dumaan sa akin 'yan. Maging alerto.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.unknown.guarded.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can't help you there. Don't get distracted.",
                            },
                            ["TL"] = {
                                "Hindi kita matutulungan diyan. Huwag mawala sa pokus.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.unknown.guarded.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm in the dark on that. Watch the road.",
                            },
                            ["TL"] = {
                                "Wala akong alam diyan. Bantayan ang daan.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.unknown.guarded.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No clue. Don't go looking for things that aren't there.",
                            },
                            ["TL"] = {
                                "Walang ideya. Huwag maghanap ng mga bagay na wala naman.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.unknown.guarded.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Nothing I've ever encountered. Move along.",
                            },
                            ["TL"] = {
                                "Hindi ko pa kailanman nakaharap 'yan. Tuloy sa lakad.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.question.knowledge.unknown.guarded.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I don't know and I don't care to guess.",
                            },
                            ["TL"] = {
                                "Hindi ko alam at ayaw kong manghula.",
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
        ["sourceShard"] = "psdl/dialogue/core_knowledge_facts.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_knowledge_facts",
        ["id"] = "semantic.question.knowledge.unknown.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.question.knowledge.unknown.neutral",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_facts.json#records[5]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreKnowledgeFacts",
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
                ["responseTemplateID"] = "semantic.question.knowledge.unknown",
                ["sourceSurface"] = "content/knowledge/knowledge.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.unknown.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I don't have reliable information about that.",
                            },
                            ["TL"] = {
                                "Wala akong maaasahang impormasyon tungkol diyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.unknown.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm not familiar with that subject.",
                            },
                            ["TL"] = {
                                "Hindi ako pamilyar sa paksang iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.unknown.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I haven't encountered that information before.",
                            },
                            ["TL"] = {
                                "Hindi ko pa nalaman ang impormasyong iyon noon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.unknown.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I have no knowledge on that matter.",
                            },
                            ["TL"] = {
                                "Wala akong kaalaman sa bagay na iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.unknown.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "That's unfamiliar to me, sorry.",
                            },
                            ["TL"] = {
                                "Bago 'yan sa akin, pasensya na.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.unknown.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I can't answer that. I simply don't know.",
                            },
                            ["TL"] = {
                                "Hindi ko masasagot 'yan. Talagang hindi ko alam.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.unknown.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Haven't come across that in my travels.",
                            },
                            ["TL"] = {
                                "Hindi ko pa 'yan nasalubong sa paglalakbay ko.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.unknown.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I don't have the answers on that one.",
                            },
                            ["TL"] = {
                                "Wala sa akin ang mga sagot tungkol diyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.unknown.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm unaware of that topic.",
                            },
                            ["TL"] = {
                                "Wala akong kamalayan sa paksang iyon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.question.knowledge.unknown.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Sorry, that's outside my knowledge.",
                            },
                            ["TL"] = {
                                "Pasensya na, labas 'yan sa kaalaman ko.",
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
        ["sourceShard"] = "psdl/dialogue/core_knowledge_facts.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_knowledge_facts",
        ["id"] = "semantic.question.knowledge.unknown.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.question.knowledge.unknown.terse",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_facts.json#records[6]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreKnowledgeFacts",
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
                ["responseTemplateID"] = "semantic.question.knowledge.unknown",
                ["sourceSurface"] = "content/knowledge/knowledge.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.unknown.terse.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't know.",
                            },
                            ["TL"] = {
                                "Hindi alam.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.unknown.terse.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No idea.",
                            },
                            ["TL"] = {
                                "Walang ideya.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.unknown.terse.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Unfamiliar.",
                            },
                            ["TL"] = {
                                "Hindi pamilyar.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.04",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.unknown.terse.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Never heard of it.",
                            },
                            ["TL"] = {
                                "Hindi narinig.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.unknown.terse.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Can't say.",
                            },
                            ["TL"] = {
                                "Hindi masabi.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.unknown.terse.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Unknown.",
                            },
                            ["TL"] = {
                                "Hindi batid.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.unknown.terse.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No clue.",
                            },
                            ["TL"] = {
                                "Walang muwang.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.unknown.terse.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Not a clue.",
                            },
                            ["TL"] = {
                                "Wala talaga.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.unknown.terse.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Nothing.",
                            },
                            ["TL"] = {
                                "Wala.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.question.knowledge.unknown.terse.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Blank on that.",
                            },
                            ["TL"] = {
                                "Walang alam.",
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
        ["sourceShard"] = "psdl/dialogue/core_knowledge_facts.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_knowledge_facts",
        ["id"] = "semantic.question.knowledge.unknown.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["migrationReadOnly"] = true,
            ["sourceId"] = "semantic.question.knowledge.unknown.warm",
            ["sourcePath"] = "psdl/dialogue/core_knowledge_facts.json#records[7]",
            ["sourceSchema"] = "psychopatz.semantic.dialogue-language.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreKnowledgeFacts",
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
                ["responseTemplateID"] = "semantic.question.knowledge.unknown",
                ["sourceSurface"] = "content/knowledge/knowledge.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.unknown.warm.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I wish I knew, but I don't know anything about that.",
                            },
                            ["TL"] = {
                                "Sana may alam ako, pero wala akong alam tungkol diyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.unknown.warm.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'm sorry, friend, I haven't heard about that.",
                            },
                            ["TL"] = {
                                "Pasensya na, kaibigan, wala akong narinig tungkol diyan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.unknown.warm.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I wish I could help you with that, but I'm unfamiliar.",
                            },
                            ["TL"] = {
                                "Gusto sana kitang tulungan diyan, pero hindi ako pamilyar.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.unknown.warm.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I don't know, but we can try to find out together.",
                            },
                            ["TL"] = {
                                "Hindi ko alam, pero pwede nating alamin nang magkasama.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.unknown.warm.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Sorry I can't be more helpful on that topic.",
                            },
                            ["TL"] = {
                                "Pasensya na kung hindi ako masyadong makatulong sa paksang 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.unknown.warm.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "That's new to me! I wish I had more answers for you.",
                            },
                            ["TL"] = {
                                "Bago 'yan sa akin! Sana may mga sagot ako para sa'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.unknown.warm.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I haven't learned about that yet, my friend.",
                            },
                            ["TL"] = {
                                "Hindi ko pa natututunan 'yan, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.unknown.warm.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Wish I could answer that, but I'm in the dark too.",
                            },
                            ["TL"] = {
                                "Sana masasagot ko 'yan, pero wala rin akong alam.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.unknown.warm.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I don't know about that, but let's keep learning together.",
                            },
                            ["TL"] = {
                                "Hindi ko alam 'yan, pero magkasama tayong mag-aral.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.question.knowledge.unknown.warm.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Sorry to disappoint, but that's unfamiliar to me.",
                            },
                            ["TL"] = {
                                "Pasensya na kung mabigo kita, pero hindi ako pamilyar diyan.",
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
        ["sourceShard"] = "psdl/dialogue/core_knowledge_facts.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
