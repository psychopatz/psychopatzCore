local T = require "tests/support/test"
T.addPackagePaths()

local ROOT = T.layerRoot("common_shared")
package.path = ROOT .. "?.lua;" .. package.path

PsychopatzCore = {}

local Foundation = require "PsychopatzCore/ConvoEngine/Foundation"
local Affordance = require "PsychopatzCore/ConvoEngine/Affordance"

local function eq(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s",
            tostring(label or "assertion"), tostring(expected), tostring(actual)))
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

local mockAskPerson = {
    id = "social.ask_person",
    kind = "dialogue",
    exchangeFamily = {
        familyID = "social.ask_person",
        slots = {
            person = { type = "entity.person", required = true, suggest = "known_people", limit = 2 },
        },
        affordance = {
            textRole = "button_label",
            labelFallback = "Ask about {slot.person.name}",
            translations = { EN = { "Ask about {slot.person.name}" } },
            consumers = { "player", "npc" },
            groups = { "social", "knowledge" },
            priority = 10,
            utility = { curiosity = 2.0 },
        },
        initiatingSay = {
            keyOrder = { "1" },
            realizations = {
                ["1"] = {
                    variants = {
                        {
                            id = "neutral",
                            textRole = "spoken_action",
                            fallback = "Have you seen {slot.person.name}?",
                            translations = { EN = { "Have you seen {slot.person.name}?" } },
                        },
                    },
                },
            },
        },
        replies = {
            known = {
                outcome = "known",
                when = { path = "knowledge.person", op = "eq", value = "known" },
                act = "INFORM",
                say = {
                    keyOrder = { "1" },
                    realizations = {
                        ["1"] = {
                            variants = {
                                {
                                    id = "neutral",
                                    textRole = "response",
                                    fallback = "{slot.person.name} was by the clinic.",
                                    translations = { EN = { "{slot.person.name} was by the clinic." } },
                                },
                            },
                        },
                    },
                },
                after = { recommend = { "social.follow_up" } },
            },
            unknown = {
                outcome = "unknown",
                act = "ADMIT_IGNORANCE",
                say = {
                    keyOrder = { "1" },
                    realizations = {
                        ["1"] = {
                            variants = {
                                {
                                    id = "neutral",
                                    textRole = "response",
                                    fallback = "I haven't seen {slot.person.name}.",
                                    translations = { EN = { "I haven't seen {slot.person.name}." } },
                                },
                            },
                        },
                    },
                },
                after = { ["goto"] = { target = "social.ask_rumor" } },
            },
        },
    },
}

local mockFollowUp = {
    id = "social.follow_up",
    kind = "dialogue",
    exchangeFamily = {
        familyID = "social.follow_up",
        affordance = {
            textRole = "button_label",
            labelFallback = "Thank them",
            translations = { EN = { "Thank them" } },
            consumers = { "player" },
            groups = { "social" },
            priority = 5,
        },
        initiatingSay = {
            keyOrder = { "1" },
            realizations = {
                ["1"] = {
                    variants = {
                        {
                            id = "neutral",
                            textRole = "spoken_action",
                            fallback = "Thanks for letting me know.",
                            translations = { EN = { "Thanks for letting me know." } },
                        },
                    },
                },
            },
        },
    },
}

local mockNpcOnly = {
    id = "npc.need_check",
    kind = "dialogue",
    exchangeFamily = {
        familyID = "npc.need_check",
        affordance = {
            textRole = "button_label",
            labelFallback = "Check food supplies",
            translations = { EN = { "Check food supplies" } },
            consumers = { "npc" },
            groups = { "survival" },
            priority = 20,
            utility = { hunger = 3.0 },
        },
        initiatingSay = {
            keyOrder = { "1" },
            realizations = {
                ["1"] = {
                    variants = {
                        {
                            id = "neutral",
                            textRole = "spoken_action",
                            fallback = "Do we have any food left?",
                            translations = { EN = { "Do we have any food left?" } },
                        },
                    },
                },
            },
        },
    },
}

local mockRegistry = {
    CONVO_PLANS = {
        ["social.ask_person"] = mockAskPerson,
        ["social.follow_up"] = mockFollowUp,
        ["npc.need_check"] = mockNpcOnly,
    },
    ConvoPlan = function(id)
        return ({
            ["social.ask_person"] = mockAskPerson,
            ["social.follow_up"] = mockFollowUp,
            ["npc.need_check"] = mockNpcOnly,
        })[tostring(id or "")]
    end,
}

-- 1. Strict text role separation: missing initiatingSay must NOT fall back to affordance.label.
local missingSay = {
    familyID = "broken.no_say",
    affordance = {
        textRole = "button_label",
        labelFallback = "Label Only",
        translations = { EN = { "Label Only" } },
        consumers = { "player" },
    },
}
local badSpeech, badErr = Affordance.RenderRoleText(missingSay, "spoken_action", {})
eq(badSpeech, nil, "missing spoken_action must not fall back to button_label")
eq(badErr, "spoken_action_missing", "missing spoken_action error code")

-- 2. Single-slot expansion + limit cap + bound {slot.person.name}.
local playerOffers = Affordance.Collect("player", {
    slots = {
        person = {
            { id = "p1", name = "Marcus" },
            { id = "p2", name = "Elena" },
            { id = "p3", name = "IgnoredThird" },
        },
    },
}, { registry = mockRegistry })
-- Expect 2 expanded person offers + 1 follow_up (npc.need_check excluded because consumer=npc only)
eq(#playerOffers, 3, "player affordance expansion with slot limit=2")
eq(playerOffers[1].label, "Ask about Marcus", "rendered button_label slot")
eq(playerOffers[1].utterance, "Have you seen Marcus?", "rendered spoken_action slot")
eq(playerOffers[2].label, "Ask about Elena", "second expanded slot label")

-- 3. Shared player/NPC affordance + deterministic utility scoring.
local npcBest = Affordance.SelectNpcAffordance({
    utility = { curiosity = 1.0, hunger = 5.0 },
    slots = { person = { { id = "p1", name = "Marcus" } } },
}, { registry = mockRegistry })
truthy(npcBest ~= nil, "npc affordance should resolve")
eq(npcBest.familyID, "npc.need_check", "higher utility+priority wins NPC selection")

-- 4. Independent reply outcomes + after.recommend + after.goto cycle guard.
local replyCtx = {
    slot = { person = { name = "Marcus" } },
    knowledge = { person = "known" },
}
local knownReply = Affordance.SelectReply("social.ask_person", replyCtx, { registry = mockRegistry })
truthy(knownReply ~= nil, "known reply resolves")
eq(knownReply.outcome, "known", "predicate selected known outcome")
eq(knownReply.text, "Marcus was by the clinic.", "rendered response outcome text")

local afterKnown = Affordance.ResolveAfter("social.ask_person", "known", replyCtx, {
    registry = mockRegistry,
    consumer = "player",
})
eq(afterKnown.mode, "recommend", "after.recommend resolves recommendations")
eq(afterKnown.recommendations[1].familyID, "social.follow_up", "recommended target family")

local unknownCtx = {
    slot = { person = { name = "Marcus" } },
    knowledge = { person = "unknown" },
}
local unknownReply = Affordance.SelectReply("social.ask_person", unknownCtx, { registry = mockRegistry })
eq(unknownReply.outcome, "unknown", "fallback unknown outcome")
local afterUnknown = Affordance.ResolveAfter("social.ask_person", "unknown", unknownCtx, {
    registry = mockRegistry,
    visited = { ["social.ask_rumor"] = true },
})
eq(afterUnknown.mode, "blocked", "after.goto blocks cycles")
eq(afterUnknown.reason, "after_cycle_detected", "after.goto cycle reason")

print("convo_engine_s6m5_affordance_smoke: PASS")
