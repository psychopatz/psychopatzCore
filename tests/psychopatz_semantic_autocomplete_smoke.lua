-- Schema-driven, confidence-scored predictive text & autocorrect smoke test.
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

local Semantics = require "PsychopatzCore/Semantics/PsychopatzSemantic"
local Registry = Semantics.Registry
local Autocomplete = Semantics.Autocomplete

Registry.Reset()
Autocomplete.ResetCache()

Registry.RegisterConcept({ id = "THANK", aliases = { "thanks", "thank you" } })
Registry.RegisterConcept({ id = "FOLLOW", aliases = { "follow", "come" } })
Registry.RegisterConcept({ id = "GIVE", aliases = { "give", "offer" } })
Registry.RegisterConcept({ id = "ITEM", aliases = { "bandage", "water" } })
Registry.RegisterPattern({
    id = "test.nice_to_see_you",
    match = { { kind = "literal", value = "nice" }, { kind = "literal", value = "to" }, { kind = "literal", value = "see" }, { kind = "literal", value = "you" } },
    emit = { intent = "GREET", speechAct = "GREET" },
    confidence = 0.98,
})
Registry.RegisterPattern({
    id = "test.nice_to_meet_you",
    match = { { kind = "literal", value = "nice" }, { kind = "literal", value = "to" }, { kind = "literal", value = "meet" }, { kind = "literal", value = "you" } },
    emit = { intent = "GREET", speechAct = "GREET" },
    confidence = 0.98,
})
Registry.RegisterPattern({
    id = "test.follow_me",
    match = { { kind = "literal", value = "follow" }, { kind = "literal", value = "me" } },
    emit = { intent = "REQUEST", speechAct = "REQUEST", action = "FOLLOW" },
    confidence = 0.96,
})
Registry.RegisterPattern({
    id = "test.give_item",
    match = { { kind = "concept", id = "GIVE" }, { kind = "any_phrase", capture = "item", minTokens = 1, maxTokens = 3 } },
    emit = { intent = "OFFER", speechAct = "OFFER", action = "GIVE", object = "$capture.item" },
    confidence = 0.94,
})

local inventory = { "Bandage", "Canned Beans", "Water Bottle", "Crowbar" }
local participants = {
    { id = "npc_jordan", fullName = "Jordan Bennett", name = "Jordan Bennett", firstName = "Jordan" },
}

-- 1) Empty input -> no chips
assertEqual(#Autocomplete.Suggest(""), 0, "empty input returns no suggestions")

-- 2) Schema-driven inventory suggestions (discovered from test.give_item's capture="item")
local invPrefix = Autocomplete.Suggest("give ban", { inventoryItems = inventory })
assertTruthy(#invPrefix >= 1, "give ban suggests Bandage")
assertEqual(invPrefix[1].kind, "inventory", "give ban kind is inventory")
assertEqual(invPrefix[1].label, "Bandage", "give ban label is Bandage")
assertEqual(invPrefix[1].replacement, "give bandage", "give ban replacement")
assertTruthy(invPrefix[1].confidence >= 0.80, "give bandage carries real parser confidence")
assertEqual(invPrefix[1].action, "GIVE", "give bandage exposes parsed action GIVE")

local invBare = Autocomplete.Suggest("give ", { inventoryItems = inventory, limit = 3 })
assertEqual(#invBare, 3, "give <space> suggests top 3 inventory items from schema")
assertEqual(invBare[1].kind, "inventory", "bare give suggests inventory items")

local invTypo = Autocomplete.Suggest("give wtaer", { inventoryItems = inventory })
local hasWaterBottle = false
for i = 1, #invTypo do
    if invTypo[i].label == "Water Bottle" and invTypo[i].kind == "inventory" then
        hasWaterBottle = true
    end
end
assertTruthy(hasWaterBottle,
    "give wtaer typo suggests Water Bottle via Damerau-Levenshtein")

-- 3) Dynamic zero-hardcoding schema discovery: register brand-new addon patterns at runtime!
Registry.RegisterPattern({
    id = "addon.barter_item",
    match = { { kind = "literal", value = "barter" }, { kind = "any_phrase", capture = "item", minTokens = 1, maxTokens = 3 } },
    emit = { intent = "REQUEST", speechAct = "REQUEST", action = "TRADE", object = "$capture.item" },
    confidence = 0.95,
})
Registry.RegisterPattern({
    id = "addon.escort_actor",
    match = { { kind = "literal", value = "escort" }, { kind = "any_phrase", capture = "actor", minTokens = 1, maxTokens = 2 } },
    emit = { intent = "REQUEST", speechAct = "REQUEST", action = "ESCORT", target = "$capture.actor" },
    confidence = 0.95,
})
local barterHit = Autocomplete.Suggest("barter ban", { inventoryItems = inventory })
assertTruthy(#barterHit >= 1 and barterHit[1].label == "Bandage",
    "brand-new 'barter <item>' schema automatically triggers inventory autocomplete")
assertEqual(barterHit[1].action, "TRADE", "barter bandage carries real parser action TRADE")
assertTruthy(barterHit[1].confidence >= 0.80, "barter bandage carries real parser confidence")

local escortHit = Autocomplete.Suggest("escort ", { groupParticipants = participants })
assertTruthy(#escortHit >= 1 and escortHit[1].label == "Jordan",
    "brand-new 'escort <actor>' schema automatically triggers participant autocomplete")
assertEqual(escortHit[1].action, "ESCORT", "escort Jordan carries real parser action ESCORT")

-- 4) Participant name completion on trailing vocative
local partHit = Autocomplete.Suggest("nice to see you jor", { groupParticipants = participants })
assertTruthy(#partHit >= 1, "trailing participant prefix suggests Jordan")
assertEqual(partHit[1].kind, "participant", "participant kind")
assertEqual(partHit[1].label, "Jordan", "participant label Jordan")
assertEqual(partHit[1].intent, "GREET", "nice to see you Jordan scores as GREET via real parser")
assertTruthy(partHit[1].confidence >= 0.90, "nice to see you Jordan has HIGH real confidence")

-- 5) Phrase prefix completion ranked by real parser confidence
local phraseHits = Autocomplete.Suggest("nice to ", {})
assertTruthy(#phraseHits >= 2, "nice to <space> suggests both nice to meet/see you")
assertEqual(phraseHits[1].intent, "GREET", "phrase completion carries real GREET intent")
assertTruthy(phraseHits[1].confidence >= 0.95, "phrase completion carries real >=0.95 confidence")

-- 6) Word typo autocorrect (adjacent swap = 1 edit)
local typoHit = Autocomplete.Suggest("follwo", {})
assertTruthy(#typoHit >= 1 and typoHit[1].kind == "autocorrect", "follwo triggers autocorrect")
assertEqual(typoHit[1].label, "follow", "follwo autocorrects to follow")

local thanksTypo = Autocomplete.Suggest("thnaks", {})
assertTruthy(#thanksTypo >= 1 and thanksTypo[1].label == "thanks", "thnaks autocorrects to thanks")

-- 7) Active semantic beat spoken utterances (actual spoken content, not button labels)
local activeBeat = { "I'm Patrick", "Call me Alex Reed", "I'd rather not say." }
local beatPrefix = Autocomplete.Suggest("im pat", { activeSuggestions = activeBeat })
assertTruthy(#beatPrefix >= 1, "im pat matches active spoken suggestion I'm Patrick")
assertEqual(beatPrefix[1].kind, "suggestion", "active suggestion kind is suggestion")
assertEqual(beatPrefix[1].label, "I'm Patrick", "displays spoken utterance, not button label")
assertEqual(beatPrefix[1].replacement, "I'm Patrick", "replaces with spoken utterance")

local beatTypo = Autocomplete.Suggest("i'm patrk", { activeSuggestions = activeBeat })
assertTruthy(#beatTypo >= 1 and beatTypo[1].label == "I'm Patrick",
    "fuzzy typo matches active spoken utterance I'm Patrick")

print("psychopatz_semantic_autocomplete_smoke: OK")
