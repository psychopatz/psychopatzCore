-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "core_knowledge_gossip",
        ["id"] = "semantic.gossip.unknown.bond_guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "bond_guarded",
            ["sourceId"] = "semantic.gossip.unknown.bond_guarded",
            ["sourcePath"] = "dialogue/core_knowledge_gossip/gossip_unknown_bond_guarded.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreKnowledgeGossip",
        ["namespace"] = "semantic.gossip.unknown",
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
                ["responseTemplateID"] = "semantic.gossip.unknown",
                ["sourceSurface"] = "content/knowledge/gossip.json",
                ["style"] = "bond_guarded",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "bond_guarded.01",
                        ["metadata"] = {
                            ["style"] = "bond_guarded",
                            ["textKey"] = "semantic.gossip.unknown.bond_guarded.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, I don't have anything to share.",
                            },
                            ["TL"] = {
                                "{addressee.name}, wala akong maibabahagi sa'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.02",
                        ["metadata"] = {
                            ["style"] = "bond_guarded",
                            ["textKey"] = "semantic.gossip.unknown.bond_guarded.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, haven't heard any reliable rumors.",
                            },
                            ["TL"] = {
                                "{addressee.name}, wala akong naririnig na maaasahang balita.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.03",
                        ["metadata"] = {
                            ["style"] = "bond_guarded",
                            ["textKey"] = "semantic.gossip.unknown.bond_guarded.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Keep your head down, {addressee.name}. No news out there.",
                            },
                            ["TL"] = {
                                "Mag-ingat ka, {addressee.name}. Walang balita sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.04",
                        ["metadata"] = {
                            ["style"] = "bond_guarded",
                            ["textKey"] = "semantic.gossip.unknown.bond_guarded.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, nothing trustworthy has reached my ears.",
                            },
                            ["TL"] = {
                                "{addressee.name}, walang mapagkakatiwalaang balitang nakarating sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.05",
                        ["metadata"] = {
                            ["style"] = "bond_guarded",
                            ["textKey"] = "semantic.gossip.unknown.bond_guarded.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Not much word going around, {addressee.name}.",
                            },
                            ["TL"] = {
                                "{addressee.name}, walang gaanong kumakalat na balita.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.06",
                        ["metadata"] = {
                            ["style"] = "bond_guarded",
                            ["textKey"] = "semantic.gossip.unknown.bond_guarded.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, gossip gets people killed. I have none.",
                            },
                            ["TL"] = {
                                "{addressee.name}, ang tsismis ay nakakamatay. Wala ako no'n.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.07",
                        ["metadata"] = {
                            ["style"] = "bond_guarded",
                            ["textKey"] = "semantic.gossip.unknown.bond_guarded.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Nothing to report, {addressee.name}. Stay on your guard.",
                            },
                            ["TL"] = {
                                "Walang maiuulat, {addressee.name}. Manatiling alerto.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.08",
                        ["metadata"] = {
                            ["style"] = "bond_guarded",
                            ["textKey"] = "semantic.gossip.unknown.bond_guarded.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, nobody's talking about anything useful.",
                            },
                            ["TL"] = {
                                "{addressee.name}, walang nag-uusap ng anumang kapaki-pakinabang.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.09",
                        ["metadata"] = {
                            ["style"] = "bond_guarded",
                            ["textKey"] = "semantic.gossip.unknown.bond_guarded.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I haven't heard any safe news, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Wala akong naririnig na ligtas na balita, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_guarded.10",
                        ["metadata"] = {
                            ["style"] = "bond_guarded",
                            ["textKey"] = "semantic.gossip.unknown.bond_guarded.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, keep to our business. No rumors here.",
                            },
                            ["TL"] = {
                                "{addressee.name}, magpokus tayo sa sarili natin. Walang tsismis dito.",
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
        ["sourceShard"] = "dialogue/core_knowledge_gossip/gossip_unknown_bond_guarded.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_knowledge_gossip",
        ["id"] = "semantic.gossip.unknown.bond_neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "bond_neutral",
            ["sourceId"] = "semantic.gossip.unknown.bond_neutral",
            ["sourcePath"] = "dialogue/core_knowledge_gossip/gossip_unknown_bond_neutral.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreKnowledgeGossip",
        ["namespace"] = "semantic.gossip.unknown",
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
                ["responseTemplateID"] = "semantic.gossip.unknown",
                ["sourceSurface"] = "content/knowledge/gossip.json",
                ["style"] = "bond_neutral",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "bond_neutral.01",
                        ["metadata"] = {
                            ["style"] = "bond_neutral",
                            ["textKey"] = "semantic.gossip.unknown.bond_neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, I haven't heard any news lately.",
                            },
                            ["TL"] = {
                                "{addressee.name}, wala akong narinig na balita kamakailan.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.02",
                        ["metadata"] = {
                            ["style"] = "bond_neutral",
                            ["textKey"] = "semantic.gossip.unknown.bond_neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, things have been quiet on the gossip front.",
                            },
                            ["TL"] = {
                                "{addressee.name}, tahimik ang paligid pagdating sa mga balita.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.03",
                        ["metadata"] = {
                            ["style"] = "bond_neutral",
                            ["textKey"] = "semantic.gossip.unknown.bond_neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Nothing new to pass along, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Walang bagong maipapasa sa'yo, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.04",
                        ["metadata"] = {
                            ["style"] = "bond_neutral",
                            ["textKey"] = "semantic.gossip.unknown.bond_neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, haven't picked up any fresh word.",
                            },
                            ["TL"] = {
                                "{addressee.name}, wala akong nasagap na bagong balita.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.05",
                        ["metadata"] = {
                            ["style"] = "bond_neutral",
                            ["textKey"] = "semantic.gossip.unknown.bond_neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I don't have any updates right now, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Wala akong anumang balita ngayon, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.06",
                        ["metadata"] = {
                            ["style"] = "bond_neutral",
                            ["textKey"] = "semantic.gossip.unknown.bond_neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, no recent rumors to speak of.",
                            },
                            ["TL"] = {
                                "{addressee.name}, walang kamakailang tsismis na masasabi.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.07",
                        ["metadata"] = {
                            ["style"] = "bond_neutral",
                            ["textKey"] = "semantic.gossip.unknown.bond_neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Haven't caught any news from the others, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Walang nasagap na balita mula sa iba, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.08",
                        ["metadata"] = {
                            ["style"] = "bond_neutral",
                            ["textKey"] = "semantic.gossip.unknown.bond_neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, it's been quiet around here lately.",
                            },
                            ["TL"] = {
                                "{addressee.name}, naging tahimik dito kamakailan.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.09",
                        ["metadata"] = {
                            ["style"] = "bond_neutral",
                            ["textKey"] = "semantic.gossip.unknown.bond_neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No rumors have reached me yet, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Wala pang nakakarating na tsismis sa akin, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_neutral.10",
                        ["metadata"] = {
                            ["style"] = "bond_neutral",
                            ["textKey"] = "semantic.gossip.unknown.bond_neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, I'll let you know if I hear anything.",
                            },
                            ["TL"] = {
                                "{addressee.name}, sasabihan kita kapag may narinig ako.",
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
        ["sourceShard"] = "dialogue/core_knowledge_gossip/gossip_unknown_bond_neutral.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_knowledge_gossip",
        ["id"] = "semantic.gossip.unknown.bond_terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "bond_terse",
            ["sourceId"] = "semantic.gossip.unknown.bond_terse",
            ["sourcePath"] = "dialogue/core_knowledge_gossip/gossip_unknown_bond_terse.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreKnowledgeGossip",
        ["namespace"] = "semantic.gossip.unknown",
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
                ["responseTemplateID"] = "semantic.gossip.unknown",
                ["sourceSurface"] = "content/knowledge/gossip.json",
                ["style"] = "bond_terse",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "bond_terse.01",
                        ["metadata"] = {
                            ["style"] = "bond_terse",
                            ["textKey"] = "semantic.gossip.unknown.bond_terse.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, no news.",
                            },
                            ["TL"] = {
                                "{addressee.name}, walang balita.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.02",
                        ["metadata"] = {
                            ["style"] = "bond_terse",
                            ["textKey"] = "semantic.gossip.unknown.bond_terse.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Nothing, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Wala, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.03",
                        ["metadata"] = {
                            ["style"] = "bond_terse",
                            ["textKey"] = "semantic.gossip.unknown.bond_terse.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, heard nothing.",
                            },
                            ["TL"] = {
                                "{addressee.name}, walang narinig.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.04",
                        ["metadata"] = {
                            ["style"] = "bond_terse",
                            ["textKey"] = "semantic.gossip.unknown.bond_terse.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Quiet, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Tahimik, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.05",
                        ["metadata"] = {
                            ["style"] = "bond_terse",
                            ["textKey"] = "semantic.gossip.unknown.bond_terse.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, no rumors.",
                            },
                            ["TL"] = {
                                "{addressee.name}, walang tsismis.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.06",
                        ["metadata"] = {
                            ["style"] = "bond_terse",
                            ["textKey"] = "semantic.gossip.unknown.bond_terse.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No word, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Walang balita, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.07",
                        ["metadata"] = {
                            ["style"] = "bond_terse",
                            ["textKey"] = "semantic.gossip.unknown.bond_terse.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, all quiet.",
                            },
                            ["TL"] = {
                                "{addressee.name}, tahimik lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.08",
                        ["metadata"] = {
                            ["style"] = "bond_terse",
                            ["textKey"] = "semantic.gossip.unknown.bond_terse.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Nothing to share, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Walang maibabahagi, {addressee.name}.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.09",
                        ["metadata"] = {
                            ["style"] = "bond_terse",
                            ["textKey"] = "semantic.gossip.unknown.bond_terse.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, zero news.",
                            },
                            ["TL"] = {
                                "{addressee.name}, walang balita.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_terse.10",
                        ["metadata"] = {
                            ["style"] = "bond_terse",
                            ["textKey"] = "semantic.gossip.unknown.bond_terse.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Blank slate, {addressee.name}.",
                            },
                            ["TL"] = {
                                "Walang anuman, {addressee.name}.",
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
        ["sourceShard"] = "dialogue/core_knowledge_gossip/gossip_unknown_bond_terse.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_knowledge_gossip",
        ["id"] = "semantic.gossip.unknown.bond_warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "bond_warm",
            ["sourceId"] = "semantic.gossip.unknown.bond_warm",
            ["sourcePath"] = "dialogue/core_knowledge_gossip/gossip_unknown_bond_warm.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreKnowledgeGossip",
        ["namespace"] = "semantic.gossip.unknown",
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
                ["responseTemplateID"] = "semantic.gossip.unknown",
                ["sourceSurface"] = "content/knowledge/gossip.json",
                ["style"] = "bond_warm",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "bond_warm.01",
                        ["metadata"] = {
                            ["style"] = "bond_warm",
                            ["textKey"] = "semantic.gossip.unknown.bond_warm.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, I haven't heard any news, sorry.",
                            },
                            ["TL"] = {
                                "{addressee.name}, wala akong narinig na balita, pasensya na.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.02",
                        ["metadata"] = {
                            ["style"] = "bond_warm",
                            ["textKey"] = "semantic.gossip.unknown.bond_warm.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Wish I had something to tell you, {addressee.name}, but it's quiet.",
                            },
                            ["TL"] = {
                                "Sana may maikwento ako sa'yo, {addressee.name}, pero tahimik ang paligid.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.03",
                        ["metadata"] = {
                            ["style"] = "bond_warm",
                            ["textKey"] = "semantic.gossip.unknown.bond_warm.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, haven't heard a peep from the other camps.",
                            },
                            ["TL"] = {
                                "{addressee.name}, wala akong narinig kahit kaunti mula sa ibang kampo.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.04",
                        ["metadata"] = {
                            ["style"] = "bond_warm",
                            ["textKey"] = "semantic.gossip.unknown.bond_warm.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Sorry, {addressee.name}, no interesting stories today.",
                            },
                            ["TL"] = {
                                "Pasensya na, {addressee.name}, walang magagandang kwento ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.05",
                        ["metadata"] = {
                            ["style"] = "bond_warm",
                            ["textKey"] = "semantic.gossip.unknown.bond_warm.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, I'll definitely share the moment I hear anything.",
                            },
                            ["TL"] = {
                                "{addressee.name}, ibabahagi ko agad kapag may narinig ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.06",
                        ["metadata"] = {
                            ["style"] = "bond_warm",
                            ["textKey"] = "semantic.gossip.unknown.bond_warm.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Nothing new reaching my ears, {addressee.name}. Hope you're well.",
                            },
                            ["TL"] = {
                                "Walang bagong dumarating sa akin, {addressee.name}. Sana ayos ka lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.07",
                        ["metadata"] = {
                            ["style"] = "bond_warm",
                            ["textKey"] = "semantic.gossip.unknown.bond_warm.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, all's quiet on my end, my friend.",
                            },
                            ["TL"] = {
                                "{addressee.name}, tahimik ang lahat sa panig ko, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.08",
                        ["metadata"] = {
                            ["style"] = "bond_warm",
                            ["textKey"] = "semantic.gossip.unknown.bond_warm.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Haven't caught any rumors, {addressee.name}, but I'll keep listening.",
                            },
                            ["TL"] = {
                                "Walang nasagap na tsismis, {addressee.name}, pero patuloy akong makikinig.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.09",
                        ["metadata"] = {
                            ["style"] = "bond_warm",
                            ["textKey"] = "semantic.gossip.unknown.bond_warm.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "{addressee.name}, nothing yet, but stay safe out there.",
                            },
                            ["TL"] = {
                                "{addressee.name}, wala pa sa ngayon, pero mag-ingat ka sa labas.",
                            },
                        },
                    },
                    {
                        ["id"] = "bond_warm.10",
                        ["metadata"] = {
                            ["style"] = "bond_warm",
                            ["textKey"] = "semantic.gossip.unknown.bond_warm.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'd love to share news with you, {addressee.name}, but nothing yet.",
                            },
                            ["TL"] = {
                                "Gusto ko sanang magbahagi ng balita sa'yo, {addressee.name}, pero wala pa.",
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
        ["sourceShard"] = "dialogue/core_knowledge_gossip/gossip_unknown_bond_warm.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_knowledge_gossip",
        ["id"] = "semantic.gossip.unknown.guarded",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "guarded",
            ["sourceId"] = "semantic.gossip.unknown.guarded",
            ["sourcePath"] = "dialogue/core_knowledge_gossip/gossip_unknown.json#records[0]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreKnowledgeGossip",
        ["namespace"] = "semantic.gossip.unknown",
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
                ["responseTemplateID"] = "semantic.gossip.unknown",
                ["sourceSurface"] = "content/knowledge/gossip.json",
                ["style"] = "guarded",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "guarded.01",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.gossip.unknown.guarded.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I don't have anything to share.",
                            },
                            ["TL"] = {
                                "Wala akong maibabahagi sa'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.02",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.gossip.unknown.guarded.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I don't traffic in rumors. Keep moving.",
                            },
                            ["TL"] = {
                                "Hindi ako nakikipagtsismisan. Lakad na.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.03",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.gossip.unknown.guarded.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No news worth risking our necks over.",
                            },
                            ["TL"] = {
                                "Walang balitang karapat-dapat ipagsapalaran ang buhay natin.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.04",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.gossip.unknown.guarded.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I keep my ears open for danger, not talk.",
                            },
                            ["TL"] = {
                                "Bukas ang tenga ko sa panganib, hindi sa kwento.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.05",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.gossip.unknown.guarded.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Haven't heard anything reliable. Watch yourself.",
                            },
                            ["TL"] = {
                                "Wala akong narinig na mapagkakatiwalaan. Mag-ingat ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.06",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.gossip.unknown.guarded.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Rumors are cheap and usually wrong. Nothing to say.",
                            },
                            ["TL"] = {
                                "Mura ang tsismis at kadalasang mali. Walang masasabi.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.07",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.gossip.unknown.guarded.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I don't listen to chatter. Mind your business.",
                            },
                            ["TL"] = {
                                "Hindi ako nakikinig sa daldalan. Asikasuhin mo ang sarili mo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.08",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.gossip.unknown.guarded.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No word that concerns you.",
                            },
                            ["TL"] = {
                                "Walang balitang may kinalaman sa'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.09",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.gossip.unknown.guarded.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Nothing to share. Keep your guard up.",
                            },
                            ["TL"] = {
                                "Walang maibabahagi. Panatilihing mataas ang depensa.",
                            },
                        },
                    },
                    {
                        ["id"] = "guarded.10",
                        ["metadata"] = {
                            ["style"] = "guarded",
                            ["textKey"] = "semantic.gossip.unknown.guarded.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Don't ask me for gossip.",
                            },
                            ["TL"] = {
                                "Huwag kang magtanong sa akin ng tsismis.",
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
        ["sourceShard"] = "dialogue/core_knowledge_gossip/gossip_unknown.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_knowledge_gossip",
        ["id"] = "semantic.gossip.unknown.neutral",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "neutral",
            ["sourceId"] = "semantic.gossip.unknown.neutral",
            ["sourcePath"] = "dialogue/core_knowledge_gossip/gossip_unknown.json#records[1]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreKnowledgeGossip",
        ["namespace"] = "semantic.gossip.unknown",
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
                ["responseTemplateID"] = "semantic.gossip.unknown",
                ["sourceSurface"] = "content/knowledge/gossip.json",
                ["style"] = "neutral",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "neutral.01",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.gossip.unknown.neutral.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I haven't heard any news lately.",
                            },
                            ["TL"] = {
                                "Wala akong narinig na balita kamakailan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.02",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.gossip.unknown.neutral.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Things have been fairly quiet on that front.",
                            },
                            ["TL"] = {
                                "Medyo tahimik ang mga bagay sa bahaging 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.03",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.gossip.unknown.neutral.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No recent rumors have reached me.",
                            },
                            ["TL"] = {
                                "Walang kamakailang tsismis ang nakarating sa akin.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.04",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.gossip.unknown.neutral.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Haven't picked up any word from other survivors.",
                            },
                            ["TL"] = {
                                "Walang nasagap na balita mula sa ibang survivor.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.05",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.gossip.unknown.neutral.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I don't have any updates to share right now.",
                            },
                            ["TL"] = {
                                "Wala akong anumang balita na maibabahagi ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.06",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.gossip.unknown.neutral.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Nothing new to report on that topic.",
                            },
                            ["TL"] = {
                                "Walang bagong maiuulat sa paksang 'yan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.07",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.gossip.unknown.neutral.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Word travels slow. Haven't heard anything.",
                            },
                            ["TL"] = {
                                "Mabagal kumalat ang balita. Wala akong narinig.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.08",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.gossip.unknown.neutral.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I haven't caught any talk recently.",
                            },
                            ["TL"] = {
                                "Wala akong nasagap na usapan kamakailan.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.09",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.gossip.unknown.neutral.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No gossip on my radar at the moment.",
                            },
                            ["TL"] = {
                                "Walang tsismis sa akin sa ngayon.",
                            },
                        },
                    },
                    {
                        ["id"] = "neutral.10",
                        ["metadata"] = {
                            ["style"] = "neutral",
                            ["textKey"] = "semantic.gossip.unknown.neutral.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Haven't heard much of anything lately.",
                            },
                            ["TL"] = {
                                "Halos wala akong narinig na anuman kamakailan.",
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
        ["sourceShard"] = "dialogue/core_knowledge_gossip/gossip_unknown.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_knowledge_gossip",
        ["id"] = "semantic.gossip.unknown.terse",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "terse",
            ["sourceId"] = "semantic.gossip.unknown.terse",
            ["sourcePath"] = "dialogue/core_knowledge_gossip/gossip_unknown.json#records[2]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreKnowledgeGossip",
        ["namespace"] = "semantic.gossip.unknown",
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
                ["responseTemplateID"] = "semantic.gossip.unknown",
                ["sourceSurface"] = "content/knowledge/gossip.json",
                ["style"] = "terse",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "terse.01",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.gossip.unknown.terse.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No news.",
                            },
                            ["TL"] = {
                                "Walang balita.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.02",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.gossip.unknown.terse.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Heard nothing.",
                            },
                            ["TL"] = {
                                "Walang narinig.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.03",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.gossip.unknown.terse.03",
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
                        ["id"] = "terse.04",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.gossip.unknown.terse.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Quiet.",
                            },
                            ["TL"] = {
                                "Tahimik.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.05",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.gossip.unknown.terse.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No rumors.",
                            },
                            ["TL"] = {
                                "Walang tsismis.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.06",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.gossip.unknown.terse.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "No word.",
                            },
                            ["TL"] = {
                                "Walang balita.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.07",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.gossip.unknown.terse.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Nothing new.",
                            },
                            ["TL"] = {
                                "Walang bago.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.08",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.gossip.unknown.terse.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "All quiet.",
                            },
                            ["TL"] = {
                                "Tahimik lahat.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.09",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.gossip.unknown.terse.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Zero news.",
                            },
                            ["TL"] = {
                                "Walang balita.",
                            },
                        },
                    },
                    {
                        ["id"] = "terse.10",
                        ["metadata"] = {
                            ["style"] = "terse",
                            ["textKey"] = "semantic.gossip.unknown.terse.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Blank.",
                            },
                            ["TL"] = {
                                "Wala.",
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
        ["sourceShard"] = "dialogue/core_knowledge_gossip/gossip_unknown.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "core_knowledge_gossip",
        ["id"] = "semantic.gossip.unknown.warm",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["localId"] = "warm",
            ["sourceId"] = "semantic.gossip.unknown.warm",
            ["sourcePath"] = "dialogue/core_knowledge_gossip/gossip_unknown.json#records[3]",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/CoreKnowledgeGossip",
        ["namespace"] = "semantic.gossip.unknown",
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
                ["responseTemplateID"] = "semantic.gossip.unknown",
                ["sourceSurface"] = "content/knowledge/gossip.json",
                ["style"] = "warm",
            },
            ["response"] = {
                ["act"] = "KNOWLEDGE_RESPONSE",
                ["variants"] = {
                    {
                        ["id"] = "warm.01",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.gossip.unknown.warm.01",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I haven't heard any news, sorry.",
                            },
                            ["TL"] = {
                                "Wala akong narinig na balita, pasensya na.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.02",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.gossip.unknown.warm.02",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Wish I had something interesting to tell you.",
                            },
                            ["TL"] = {
                                "Sana may magandang balita akong maikwento sa'yo.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.03",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.gossip.unknown.warm.03",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Haven't heard any rumors, but I'll let you know.",
                            },
                            ["TL"] = {
                                "Walang narinig na tsismis, pero sasabihan kita.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.04",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.gossip.unknown.warm.04",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "All quiet on my side, but I'll keep an ear out.",
                            },
                            ["TL"] = {
                                "Tahimik sa panig ko, pero makikinig ako.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.05",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.gossip.unknown.warm.05",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Sorry, no fresh news today, my friend.",
                            },
                            ["TL"] = {
                                "Pasensya na, walang bagong balita ngayon, kaibigan.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.06",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.gossip.unknown.warm.06",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Nothing reaching my ears lately. Hope all is well.",
                            },
                            ["TL"] = {
                                "Walang dumarating sa akin kamakailan. Sana ayos ka lang.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.07",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.gossip.unknown.warm.07",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I'll be sure to tell you if I hear anything new.",
                            },
                            ["TL"] = {
                                "Tiyak na sasabihin ko sa'yo kapag may narinig akong bago.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.08",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.gossip.unknown.warm.08",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Quiet days out there. No rumors to report.",
                            },
                            ["TL"] = {
                                "Tahimik ang mga araw sa labas. Walang maiuulat na tsismis.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.09",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.gossip.unknown.warm.09",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "Nothing to share right now, but stay safe.",
                            },
                            ["TL"] = {
                                "Walang maibabahagi ngayon, pero mag-ingat ka.",
                            },
                        },
                    },
                    {
                        ["id"] = "warm.10",
                        ["metadata"] = {
                            ["style"] = "warm",
                            ["textKey"] = "semantic.gossip.unknown.warm.10",
                        },
                        ["text"] = {
                            ["EN"] = {
                                "I haven't heard any stories, but I'm glad you asked.",
                            },
                            ["TL"] = {
                                "Wala akong narinig na kwento, pero salamat sa pagtatanong.",
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
        ["sourceShard"] = "dialogue/core_knowledge_gossip/gossip_unknown.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["when"] = nil,
    },
}
