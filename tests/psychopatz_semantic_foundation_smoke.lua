local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

PsychopatzCore = {}

local Foundation = require
    "PsychopatzCore/Semantics/PsychopatzSemanticFoundation"

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

truthy(Foundation.IsAvailable(), "Core semantic foundation unavailable")
truthy(#(Foundation.Registry.PATTERNS or {}) > 0,
    "Core foundation did not load generated patterns")

local unknown = Foundation.GetStaticSuggestions({
    nameKnown = false,
    nicknameKnown = false,
    surnameKnown = false,
    factionKnown = false,
})
local hasNickname = false
local hasSurname = false
local hasFaction = false
for _, suggestion in ipairs(unknown) do
    hasNickname = hasNickname or suggestion.id == "question.identity_nickname"
    hasSurname = hasSurname or suggestion.id == "question.identity_surname"
    hasFaction = hasFaction or suggestion.id == "question.identity_faction"
end
truthy(hasNickname and hasSurname and hasFaction,
    "identity facet suggestions missing from Core foundation")

local known = Foundation.GetStaticSuggestions({
    nameKnown = true,
    nicknameKnown = true,
    surnameKnown = true,
    factionKnown = true,
})
for _, suggestion in ipairs(known) do
    truthy(suggestion.subject ~= "IDENTITY"
        and suggestion.subject ~= "IDENTITY_NICKNAME"
        and suggestion.subject ~= "IDENTITY_SURNAME"
        and suggestion.subject ~= "IDENTITY_FACTION",
        "known identity facet remained available")
end

print("psychopatz_semantic_foundation_smoke: PASS")
