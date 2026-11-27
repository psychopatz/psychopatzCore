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

-- 9) Trailing vocatives (with & without commas) and grammatical-object safety:
local ClausePreParser = require "PsychopatzCore/Semantics/PsychopatzSemanticClausePreParser"
local jordanParticipants = {
    { id = "npc_jordan", fullName = "Jordan Bennett", name = "Jordan Bennett", firstName = "Jordan" },
}
Registry.RegisterPattern({
    id = "test.nice_to_see_you",
    match = {
        { kind = "literal", value = "nice" },
        { kind = "literal", value = "to" },
        { kind = "literal", value = "see" },
        { kind = "literal", value = "you" },
    },
    emit = { intent = "GREET", speechAct = "GREET" },
    confidence = 0.98,
    priority = 120,
})
local ir14 = Parser.Parse("nice to see you jordan", { groupParticipants = jordanParticipants })
assertEqual(ir14.intent, "GREET", "ir14 unpunctuated trailing vocative GREET")
assertEqual(ir14.speechAct, "GREET", "ir14 speechAct GREET")
assertEqual(ir14.extensions.audienceScope.scope, "INDIVIDUAL", "ir14 INDIVIDUAL scope")
assertEqual(ir14.extensions.audienceScope.targetIDs[1], "npc_jordan", "ir14 targets Jordan")

local ir15 = Parser.Parse("nice to see you, Jordan!", { groupParticipants = jordanParticipants })
assertEqual(ir15.intent, "GREET", "ir15 comma trailing vocative GREET")
assertEqual(ir15.extensions.audienceScope.targetIDs[1], "npc_jordan", "ir15 targets Jordan")

local ir16 = Parser.Parse("nice to see you jordan bennett", { groupParticipants = jordanParticipants })
assertEqual(ir16.intent, "GREET", "ir16 full-name trailing vocative GREET")
assertEqual(ir16.extensions.audienceScope.targetIDs[1], "npc_jordan", "ir16 targets Jordan Bennett")

local ir17 = Parser.Parse("wait at the campfire jordan please", { groupParticipants = jordanParticipants })
assertEqual(ir17.action, "WAIT_AT", "ir17 trailing softener + trailing vocative WAIT_AT")
assertEqual(ir17.target, "campfire", "ir17 target campfire")
assertEqual(ir17.extensions.audienceScope.targetIDs[1], "npc_jordan", "ir17 targets Jordan")

-- Negative guards: trailing participant name as grammatical object/predicate must NOT be stripped.
local guardSentences = {
    "where is jordan",
    "my name is jordan",
    "call me jordan",
    "tell me about jordan",
    "give it to jordan",
    "bandage jordan",
}
for _, sentence in ipairs(guardSentences) do
    local frame = ClausePreParser.Analyze(sentence, jordanParticipants)
    assertEqual(frame.audienceScope.scope, "DEFAULT", "guard keeps DEFAULT scope for: " .. sentence)
    assertEqual(string.lower(frame.coreText), sentence, "guard preserves object name for: " .. sentence)
end

-- 10) ActorConversationService propagates 1-on-1 actor identity as participant for vocative stripping:
local ActorService = require "PsychopatzCore/Conversation/PsychopatzActorConversationService"
local service = ActorService.New({
    actor = {
        actorId = "npc_jordan",
        identity = {
            fullName = "Jordan Bennett",
            name = "Jordan Bennett",
            forename = "Jordan",
        },
    },
})
local preview = service:Preview("nice to see you jordan", { npcID = "npc_jordan" }, {})
assertEqual(preview.ir.intent, "GREET", "1-on-1 ActorService preview recognizes trailing vocative GREET")
assertEqual(preview.ir.extensions.audienceScope.targetIDs[1], "npc_jordan", "1-on-1 preview targets Jordan")

-- 11) Generic casual vocatives + object-safety guards:
local ir18 = Parser.Parse("nice to see you buddy", {})
assertEqual(ir18.intent, "GREET", "ir18 generic vocative 'buddy' stripped -> GREET")
local ir19 = Parser.Parse("wait at the campfire pal", {})
assertEqual(ir19.action, "WAIT_AT", "ir19 generic vocative 'pal' stripped -> WAIT_AT")
assertEqual(ir19.target, "campfire", "ir19 target campfire")
for _, guarded in ipairs({ "he is my friend", "help a buddy", "where is the boss" }) do
    local frame = ClausePreParser.Analyze(guarded, {})
    assertEqual(string.lower(frame.coreText), guarded, "generic vocative guard preserves: " .. guarded)
end

-- 12) Contraction & chat shorthand normalization:
local Normalizer = require "PsychopatzCore/Semantics/PsychopatzSemanticNormalizer"
assertEqual(Normalizer.Normalize("it's nice to see you").normalizedText, "it is nice to see you", "it's expands to it is")
assertEqual(Normalizer.Normalize("sup").normalizedText, "what is up", "sup expands to what is up")
assertEqual(Normalizer.Normalize("cya").normalizedText, "see you", "cya expands to see you")
assertEqual(Normalizer.Normalize("gm").normalizedText, "good morning", "gm expands to good morning")

-- 13) Reciprocal elliptical follow-ups ("you too", "same here", "likewise"):
local irRecipGreet = Parser.Parse("same here", { context = { lastBranch = "GREET_ACKNOWLEDGED", currentTopic = "greeting" } })
assertEqual(irRecipGreet.intent, "GREET", "same here after greeting -> GREET")
local irRecipBye = Parser.Parse("you too", { context = { lastBranch = "FAREWELL_ACKNOWLEDGED", currentTopic = "farewell" } })
assertEqual(irRecipBye.intent, "FAREWELL", "you too after farewell -> FAREWELL")
local irRecipThanks = Parser.Parse("likewise", { context = { lastBranch = "COMPLIMENT_RECEIVED" } })
assertEqual(irRecipThanks.intent, "THANK", "likewise after compliment -> THANK")

-- 14) Mid-clause negation cues ("no need to ...", "you don't have to ...", "i'm not ..."):
local irMidNeg1 = Parser.Parse("no need to follow me", { groupParticipants = participants })
assertEqual(irMidNeg1.action, "STAY", "no need to follow me -> inverted STAY")
assertEqual(irMidNeg1.polarity, "negative", "no need to follow me -> negative polarity")
local irMidNeg2 = Parser.Parse("you don't have to follow me", { groupParticipants = participants })
assertEqual(irMidNeg2.action, "STAY", "you don't have to follow me -> inverted STAY")
local midCopula = ClausePreParser.Analyze("i'm not hungry", {})
assertEqual(midCopula.negated, true, "mid-clause copula negation sets negated=true")
assertEqual(midCopula.polarity, "negative", "mid-clause copula negation sets polarity=negative")

-- 15) Obligation-aware bare identity answer ("Psycho" when NPC just asked player's name):
local pendingIdCtx = { pendingIdentityExchange = { kind = "PLAYER_NAME" } }
local irBareName = Parser.Parse("Psycho", { context = pendingIdCtx })
assertEqual(irBareName.intent, "INFORM", "bare name with pendingIdentityExchange -> INFORM")
assertEqual(irBareName.subject, "IDENTITY", "bare name subject -> IDENTITY")
assertEqual(irBareName.socialContext.identityClaim, true, "bare name marks identityClaim=true")
assertEqual(irBareName.slots.identityClaim.name, "Psycho", "bare name captures claimed name")

local irBareNoPending = Parser.Parse("Psycho", { context = {} })
assertEqual(irBareNoPending.intent, nil, "bare name WITHOUT pendingIdentityExchange does not false-trigger")
local irBareQuestion = Parser.Parse("who?", { context = pendingIdCtx })
assertEqual(irBareQuestion.socialContext and irBareQuestion.socialContext.identityClaim, nil,
    "question during pendingIdentityExchange is not treated as bare name")

-- 16) O(1) exact-phrase index & fast-path check:
local patObj = Registry.Patterns["test.nice_to_see_you"]
assertEqual(patObj._exactPhrase, "nice to see you", "pure-literal pattern precomputes _exactPhrase")

print("psychopatz_semantic_compositional_nlp_smoke: OK")
