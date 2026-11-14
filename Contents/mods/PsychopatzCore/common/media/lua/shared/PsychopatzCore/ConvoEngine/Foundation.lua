-- Core-owned generated semantic foundation.
--
-- This module is deliberately provider-neutral.  Project Hoomans and
-- Dynamic Trading may register additional packs, but neither adopter is
-- required for generic identity, conversation patterns, or static choices.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}
PsychopatzCore.ConvoEngine = PsychopatzCore.ConvoEngine or {}

local Semantics = PsychopatzCore.Semantics
local ConvoEngine = PsychopatzCore.ConvoEngine
local Foundation = ConvoEngine.Foundation or {}
ConvoEngine.Foundation = Foundation

local Registry = require
    "PsychopatzCore/ConvoEngine/FoundationRegistry"
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

local function stableIndex(seed, count)
    count = tonumber(count) or 0
    if count <= 0 then return nil end
    seed = tostring(seed or "")
    if seed == "" then return 1 end
    local total = 0
    for index = 1, #seed do
        total = total + (string.byte(seed, index) or 0)
    end
    return (total % count) + 1
end

local function selectedVariant(variants, options)
    if type(variants) ~= "table" or #variants == 0 then return nil end
    options = type(options) == "table" and options or {}
    local index = tonumber(options.index)
    if index == nil then
        index = stableIndex(options.seed, #variants)
    end
    index = math.floor(index or 1)
    if index < 1 then index = 1 end
    return variants[((index - 1) % #variants) + 1]
end

function Foundation.GetResponse(poolID, options)
    poolID = tostring(poolID or "")
    for _, pool in ipairs(Registry.RESPONSE_POOLS or {}) do
        if type(pool) == "table" and tostring(pool.id or "") == poolID then
            return clone(selectedVariant(pool.variants, options))
        end
    end
    return nil
end

local function resolvePlanAndOutcome(templateID, options)
    local registry = Registry
    local outcomeName = type(options) == "table" and options.outcome or nil
    local plan = registry.ConvoPlan(templateID)
    if type(plan) == "table" then
        return plan, outcomeName
    end
    if type(registry.ConvoOutcome) == "function" then
        local ref = registry.ConvoOutcome(templateID)
        if type(ref) == "table" and type(ref.plan) == "table" then
            return ref.plan, outcomeName or ref.outcome
        end
    end
    local baseID, suffix = string.match(tostring(templateID or ""), "^(.+)%.([^%.]+)$")
    if baseID and suffix then
        plan = registry.ConvoPlan(baseID)
        local family = type(plan) == "table" and plan.exchangeFamily or nil
        if type(family) == "table" and type(family.replies) == "table"
            and type(family.replies[suffix]) == "table"
        then
            return plan, outcomeName or suffix
        end
    end
    return nil, nil
end

local function selectPlanPhrase(templateID, style, options)
    if type(Registry.ConvoPlan) ~= "function" then return nil end
    local plan, outcomeName = resolvePlanAndOutcome(templateID, options)
    if type(plan) ~= "table" then return nil end
    local family = type(plan.exchangeFamily) == "table" and plan.exchangeFamily or nil
    local entry = nil
    if outcomeName ~= nil and outcomeName ~= "" then
        local branch = type(family) == "table" and type(family.replies) == "table"
            and family.replies[tostring(outcomeName)] or nil
        if type(branch) ~= "table" then return nil end
        if type(branch.say) == "table" and type(branch.say.realizations) == "table" then
            local key = tostring((type(options) == "table" and options.realizationKey) or "1")
            entry = branch.say.realizations[key] or branch.say.realizations["1"]
        elseif type(branch.variants) == "table" then
            entry = { variants = branch.variants }
        end
    else
        local say = (family and family.initiatingSay) or (type(plan.payload) == "table" and plan.payload.say) or nil
        if type(say) ~= "table" or type(say.realizations) ~= "table" then return nil end
        local key = tostring((type(options) == "table" and options.realizationKey) or "1")
        entry = say.realizations[key] or say.realizations["1"]
    end
    if type(entry) ~= "table" or type(entry.variants) ~= "table" then return nil end

    local wanted = tostring(style or "neutral")
    local chosen, neutralVar = nil, nil
    for _, v in ipairs(entry.variants) do
        if type(v) == "table" then
            if tostring(v.id or "") == wanted then chosen = v break end
            if neutralVar == nil and tostring(v.id or "") == "neutral" then neutralVar = v end
        end
    end
    chosen = chosen or neutralVar or entry.variants[1]
    if type(chosen) ~= "table" then return nil end

    local translations = type(chosen.translations) == "table" and chosen.translations or {}
    local enList = type(translations.EN) == "table" and translations.EN or nil
    local tlList = type(translations.TL) == "table" and translations.TL or nil
    local count = (enList and #enList > 0 and #enList) or (tlList and #tlList > 0 and #tlList) or 0
    local idx = 1
    if count > 0 then
        local explicit = type(options) == "table" and tonumber(options.index) or nil
        idx = explicit or stableIndex(type(options) == "table" and options.seed or "", count) or 1
        idx = ((math.floor(idx) - 1) % count) + 1
    end
    local enText = enList and enList[idx] or chosen.fallback
    local tlText = tlList and (tlList[idx] or tlList[1]) or nil
    return {
        id = chosen.id,
        templateID = chosen.templateID or templateID,
        style = tostring(chosen.id or wanted),
        familyID = plan.id,
        outcome = outcomeName,
        fallback = enText,
        translations = { EN = enText, TL = tlText },
    }
end

function Foundation.GetPhrase(templateID, style, options)
    local family, phrases, selectedStyle = Registry.FamilyFor(
        tostring(templateID or ""),
        style
    )
    if type(phrases) ~= "table" then
        return selectPlanPhrase(tostring(templateID or ""), style, options)
    end
    local phrase = selectedVariant(phrases, options)
    if type(phrase) ~= "table" then
        return selectPlanPhrase(tostring(templateID or ""), style, options)
    end
    local output = clone(phrase)
    output.templateID = output.templateID or templateID
    output.style = selectedStyle
    output.familyID = family and family.id
    return output
end

function Foundation.IsAvailable()
    return Foundation.Registered == true
        and type(Registry) == "table"
end

local function affordanceModule()
    return ConvoEngine.Affordance or require "PsychopatzCore/ConvoEngine/Affordance"
end

function Foundation.GetAffordances(consumer, context, options)
    return affordanceModule().Collect(consumer, context, options)
end

function Foundation.SelectNpcAffordance(context, options)
    return affordanceModule().SelectNpcAffordance(context, options)
end

function Foundation.SelectReplyOutcome(familyOrID, context, options)
    return affordanceModule().SelectReply(familyOrID, context, options)
end

function Foundation.ResolveAfter(familyOrID, outcomeName, context, options)
    return affordanceModule().ResolveAfter(familyOrID, outcomeName, context, options)
end

Foundation.Register()

return Foundation
