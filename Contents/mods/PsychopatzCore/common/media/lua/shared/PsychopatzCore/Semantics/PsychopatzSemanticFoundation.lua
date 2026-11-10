-- Core-owned generated semantic foundation.
--
-- This module is deliberately provider-neutral.  Project Hoomans and
-- Dynamic Trading may register additional packs, but neither adopter is
-- required for generic identity, conversation patterns, or static choices.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Semantics = PsychopatzCore.Semantics
local Foundation = Semantics.Foundation or {}
Semantics.Foundation = Foundation

local Registry = require
    "PsychopatzCore/Semantics/Generated/Conversation/FoundationRegistry"
local SemanticRegistry = Semantics.Registry
    or require "PsychopatzCore/Semantics/PsychopatzSemanticRegistry"

Foundation.VERSION = 1
Foundation.Registry = Registry
Foundation.PACK_ID = "pack.core.interaction_foundation"

local function clone(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 8 then return nil end
    local output = {}
    for key, item in pairs(value) do
        output[key] = clone(item, depth + 1)
    end
    return output
end

local function nonEmpty(value)
    return value ~= nil and tostring(value) ~= ""
end

function Foundation.Register()
    local registered = 0
    local skipped = 0
    for _, pattern in ipairs(Registry.PATTERNS or {}) do
        if type(pattern) == "table" and type(pattern.id) == "string" then
            if SemanticRegistry.Patterns[pattern.id] == nil then
                local definition = clone(pattern)
                definition.owner = Foundation.PACK_ID
                local ok, reason = SemanticRegistry.RegisterPattern(definition)
                if not ok then return false, reason or pattern.id end
                registered = registered + 1
            else
                skipped = skipped + 1
            end
        end
    end
    Foundation.Registered = true
    Foundation.RegisteredCount = registered
    Foundation.SkippedCount = skipped
    return true
end

local function identityKnowledge(context)
    context = type(context) == "table" and context or {}
    return context.identityKnowledge
        or context.knowledge
        or context.identityState
        or context
end

local function facetKnown(knowledge, facet)
    if facet == "identity" then
        return knowledge.nameKnown == true
            or nonEmpty(knowledge.knownName)
    elseif facet == "nickname" then
        return knowledge.nicknameKnown == true
            or nonEmpty(knowledge.knownNickname)
    elseif facet == "surname" then
        return knowledge.surnameKnown == true
            or nonEmpty(knowledge.knownSurname)
    elseif facet == "faction" then
        return knowledge.factionKnown == true
            or nonEmpty(knowledge.factionID)
            or nonEmpty(knowledge.factionName)
    end
    return false
end

local function available(definition, context)
    local subject = tostring(definition.subject or "")
    local knowledge = identityKnowledge(context)
    if subject == "IDENTITY" then
        return not facetKnown(knowledge, "identity")
    elseif subject == "IDENTITY_NICKNAME" then
        return not facetKnown(knowledge, "nickname")
    elseif subject == "IDENTITY_SURNAME" then
        return not facetKnown(knowledge, "surname")
    elseif subject == "IDENTITY_FACTION" then
        return not facetKnown(knowledge, "faction")
    end
    return true
end

function Foundation.GetStaticSuggestions(context)
    local output = {}
    for _, definition in ipairs(Registry.UI or {}) do
        if type(definition) == "table" and available(definition, context) then
            output[#output + 1] = clone(definition)
        end
    end
    table.sort(output, function(left, right)
        local leftOrder = tonumber(left.order) or 100
        local rightOrder = tonumber(right.order) or 100
        if leftOrder ~= rightOrder then return leftOrder < rightOrder end
        return tostring(left.id) < tostring(right.id)
    end)
    return output
end

function Foundation.IsAvailable()
    return Foundation.Registered == true
        and type(Registry) == "table"
end

Foundation.Register()

return Foundation
