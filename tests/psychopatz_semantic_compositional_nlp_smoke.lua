-- Compositional NLP smoke test: ClausePreParser (GROUP / INDIVIDUAL / GROUP_EXCEPT
-- + modal stripping) and VerbFrameParser (spatial preposition + NP role binding).
package.path = "./Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua;./Contents/mods/PsychopatzCore/common/media/lua/shared/?/init.lua;" .. package.path

local function assertEqual(actual, expected, msg)
    if actual ~= expected then
        error(tostring(msg or "assertEqual") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local function assertTruthy(val, msg)
    if not val then
        error(tostring(msg or "assertTruthy") .. ": expected truthy", 2)
    end
end

local Registry = require "PsychopatzCore/Semantics/PsychopatzSemanticRegistry"
local Parser = require "PsychopatzCore/Semantics/PsychopatzSemanticParser"
local VerbFrame = require "PsychopatzCore/Semantics/PsychopatzSemanticVerbFrameParser"

Registry.Reset()
Registry.RegisterConcept("WAIT", { synonyms = { "wait", "stay", "hold", "remain" } })
Registry.RegisterConcept("FOLLOW", { synonyms = { "follow", "come" } })
Registry.RegisterPattern("test.wait_at", {
    match = {
        { kind = "concept", id = "WAIT" },
        { kind = "literal", value = "at" },
        { kind = "literal", value = "the", optional = true },
        { kind = "any_phrase", capture = "target", minTokens = 1, maxTokens = 4 },
    },
    output = { intent = "REQUEST", speechAct = "REQUEST", action = "WAIT_AT", target = "$capture.target" },
    confidence = 0.94,
    priority = 130,
})

local participants = {
    { id = "npc_meghan", name = "Meghan patz", firstName = "Meghan" },
    { id = "npc_rory", name = "Rory patz", firstName = "Rory" },
    { id = "npc_wilfredo", name = "Wilfredo patz", firstName = "Wilfredo" },
}

-- 1) Exact user screenshot sentence: "you all should stay at garbage"
local ir1 = Parser.Parse("you all should stay at garbage", { groupParticipants = participants })
assertEqual(ir1.intent, "REQUEST", "ir1 intent")
assertEqual(ir1.action, "WAIT_AT", "ir1 action")
assertEqual(ir1.target, "garbage", "ir1 target")
assertEqual(ir1.extensions.audienceScope.scope, "GROUP", "ir1 GROUP scope")
assertEqual(ir1.extensions.groupBroadcast, true, "ir1 groupBroadcast")
assertEqual(ir1.extensions.modality, "suggestion", "ir1 suggestion modality")

-- 2) Verb-frame fallback with non-"at" preposition + trailing softener:
local ir2 = Parser.Parse("you all should stay by the garbage for a bit", { groupParticipants = participants })
assertEqual(ir2.action, "WAIT_AT", "ir2 verb_frame WAIT_AT")
assertEqual(ir2.target, "garbage", "ir2 verb_frame cleaned target")
assertEqual(ir2.extensions.audienceScope.scope, "GROUP", "ir2 GROUP scope")

-- 3) Individual named addressing with polite modal + 2-word preposition:
local ir3 = Parser.Parse("Meghan, could you wait next to the campfire please", { groupParticipants = participants })
assertEqual(ir3.action, "WAIT_AT", "ir3 WAIT_AT")
assertEqual(ir3.target, "campfire", "ir3 target campfire")
assertEqual(ir3.extensions.audienceScope.scope, "INDIVIDUAL", "ir3 INDIVIDUAL scope")
assertEqual(#ir3.extensions.audienceScope.targetIDs, 1, "ir3 1 target")
assertEqual(ir3.extensions.audienceScope.targetIDs[1], "npc_meghan", "ir3 targets Meghan")
assertEqual(ir3.extensions.modality, "polite", "ir3 polite modality")

-- 4) Multi-individual subset addressing ("Meghan and Rory, ..."):
local ir4 = Parser.Parse("Meghan and Rory, hold near the door", { groupParticipants = participants })
assertEqual(ir4.action, "WAIT_AT", "ir4 WAIT_AT")
assertEqual(ir4.target, "door", "ir4 target door")
assertEqual(ir4.extensions.audienceScope.scope, "INDIVIDUAL", "ir4 INDIVIDUAL subset scope")
assertEqual(#ir4.extensions.audienceScope.targetIDs, 2, "ir4 2 targets")
assertEqual(ir4.extensions.audienceScope.targetIDs[1], "npc_meghan", "ir4 target 1 Meghan")
assertEqual(ir4.extensions.audienceScope.targetIDs[2], "npc_rory", "ir4 target 2 Rory")

-- 5) Group exclusion addressing ("everyone except Meghan follow me"):
local ir5 = Parser.Parse("everyone except Meghan follow me", { groupParticipants = participants })
assertEqual(ir5.action, "FOLLOW", "ir5 FOLLOW")
assertEqual(ir5.extensions.audienceScope.scope, "GROUP_EXCEPT", "ir5 GROUP_EXCEPT scope")
assertEqual(#ir5.extensions.audienceScope.excludeIDs, 1, "ir5 1 excluded")
assertEqual(ir5.extensions.audienceScope.excludeIDs[1], "npc_meghan", "ir5 excludes Meghan")

-- 6) Extensible VerbFrame registration:
assertTruthy(VerbFrame.RegisterVerbFrame("PATROL", {
    verbs = { "patrol", "sweep" },
    intent = "REQUEST",
    speechAct = "REQUEST",
    bareAction = "PATROL",
    spatialAction = "PATROL_AT",
    confidence = 0.85,
}), "custom verb frame registers cleanly")
local ir6 = Parser.Parse("could you patrol around the perimeter", { groupParticipants = participants })
assertEqual(ir6.action, "PATROL_AT", "ir6 custom verb frame PATROL_AT")
assertEqual(ir6.target, "perimeter", "ir6 target perimeter")

-- 7) Negation & prohibition inversions:
local ir7 = Parser.Parse("don't follow me", { groupParticipants = participants })
assertEqual(ir7.action, "STAY", "ir7 don't follow me -> STAY")
assertEqual(ir7.polarity, "negative", "ir7 negative polarity")
assertEqual(ir7.extensions.negated, true, "ir7 extensions.negated")

local ir8 = Parser.Parse("Meghan, stop shooting", { groupParticipants = participants })
assertEqual(ir8.action, "HOLD_FIRE", "ir8 stop shooting -> HOLD_FIRE")
assertEqual(ir8.polarity, "negative", "ir8 negative polarity")
assertEqual(ir8.extensions.audienceScope.scope, "INDIVIDUAL", "ir8 targets Meghan")
assertEqual(ir8.extensions.audienceScope.targetIDs[1], "npc_meghan", "ir8 targetID Meghan")

local ir9 = Parser.Parse("you all don't sit down", { groupParticipants = participants })
assertEqual(ir9.action, "STAND", "ir9 don't sit down -> STAND")
assertEqual(ir9.extensions.audienceScope.scope, "GROUP", "ir9 GROUP scope")

-- 8) Transitive & ditransitive verb frames:
local ir10 = Parser.Parse("give Meghan a bandage", { groupParticipants = participants })
assertEqual(ir10.action, "GIVE", "ir10 GIVE")
assertEqual(ir10.recipient, "npc_meghan", "ir10 ditransitive recipient Meghan")
assertEqual(ir10.object, "bandage", "ir10 object bandage")

local ir11 = Parser.Parse("put the canned beans in the fridge", { groupParticipants = participants })
assertEqual(ir11.action, "STORE", "ir11 STORE")
assertEqual(ir11.object, "canned beans", "ir11 object canned beans")
assertEqual(ir11.destination, "fridge", "ir11 destination fridge")

local ir12 = Parser.Parse("could you grab some water from the sink", { groupParticipants = participants })
assertEqual(ir12.action, "FETCH", "ir12 FETCH")
assertEqual(ir12.object, "water", "ir12 object water")
assertEqual(ir12.source, "sink", "ir12 source sink")

local ir13 = Parser.Parse("Meghan, bandage Rory", { groupParticipants = participants })
assertEqual(ir13.action, "HEAL", "ir13 HEAL")
assertEqual(ir13.target, "rory", "ir13 target rory")
assertEqual(ir13.extensions.audienceScope.targetIDs[1], "npc_meghan", "ir13 speaker target Meghan")

print("psychopatz_semantic_compositional_nlp_smoke: OK")
