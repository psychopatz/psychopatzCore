-- Core-owned semantic affordance contract.
--
-- Offers are executable meaning frames with presentation fallbacks. They do
-- not render UI, parse text, dispatch actions, or choose a participant.
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Semantics = PsychopatzCore.Semantics
local Predicate = Semantics.Predicate
    or require "PsychopatzCore/Semantics/PsychopatzSemanticPredicate"
local Offers = Semantics.Offer or {}
Semantics.Offer = Offers

Offers.VERSION = 1
Offers.MAX_OFFERS = 8
Offers.MAX_ID_LENGTH = 96
Offers.MAX_TEXT_LENGTH = 256
Offers.MAX_CONSUMERS = 3
Offers.CONSUMERS = {
    participant = true,
    player = true,
    npc = true,
}

local FRAME_FIELDS = {
    "intent", "speechAct", "action", "subject", "target", "reference",
    "identityClaim", "selfDirected", "stateType", "stateValue", "pattern",
}
local FRAME_FIELD_SET = {}
for index = 1, #FRAME_FIELDS do
    FRAME_FIELD_SET[FRAME_FIELDS[index]] = true
end

local function boundedText(value, limit)
    value = tostring(value or "")
    limit = tonumber(limit) or Offers.MAX_TEXT_LENGTH
    if #value > limit then return string.sub(value, 1, limit) end
    return value
end

local function validID(value)
    value = tostring(value or "")
    return value ~= ""
        and #value <= Offers.MAX_ID_LENGTH
        and string.find(value, "[^%w_%.%-:]") == nil
end

local function normalizeFrame(frame, label)
    if type(frame) ~= "table" then
        return nil, label .. "_must_be_object"
    end
    local output = {}
    local key
    local value
    local supported = false
    for key, value in pairs(frame) do
        if not FRAME_FIELD_SET[key] then
            return nil, label .. "_unsupported_field:" .. tostring(key)
        end
        if type(value) ~= "string"
            and type(value) ~= "number"
            and type(value) ~= "boolean"
        then
            return nil, label .. "_field_must_be_scalar:" .. tostring(key)
        end
        output[key] = value
        supported = true
    end
    if not supported then return nil, label .. "_empty" end
    return output
end

local function normalizeConsumers(value, label)
    if value == nil then return {"participant"} end
    if type(value) ~= "table" or #value == 0 or #value > Offers.MAX_CONSUMERS then
        return nil, label .. "_invalid"
    end
    local output = {}
    local seen = {}
    for index = 1, #value do
        local consumer = tostring(value[index] or "")
        if not Offers.CONSUMERS[consumer] or seen[consumer] then
            return nil, label .. "_unsupported_consumer"
        end
        seen[consumer] = true
        output[#output + 1] = consumer
    end
    return output
end

function Offers.Normalize(value, label)
    label = tostring(label or "semantic_offer")
    if type(value) ~= "table" then
        return nil, label .. "_must_be_object"
    end
    local id = tostring(value.id or "")
    if not validID(id) then return nil, label .. "_id_invalid" end

    local labelKey = tostring(value.labelKey or "")
    local labelFallback = boundedText(value.labelFallback)
    local utteranceKey = tostring(value.utteranceKey or "")
    local utteranceFallback = boundedText(value.utteranceFallback)
    if not validID(labelKey) or labelFallback == "" then
        return nil, label .. "_label_required"
    end
    if not validID(utteranceKey) or utteranceFallback == "" then
        return nil, label .. "_utterance_required"
    end

    local frame, reason = normalizeFrame(value.frame, label .. "_frame")
    if not frame then return nil, reason end
    local consumers
    consumers, reason = normalizeConsumers(value.consumers, label .. "_consumers")
    if not consumers then return nil, reason end
    local validConstraints = true
    if value.constraints ~= nil then
        validConstraints, reason = Predicate.Validate(value.constraints)
        if not validConstraints then return nil, label .. "_constraints_invalid:" .. tostring(reason) end
    end
    if value.visibility ~= nil and value.visibility ~= "player" then
        return nil, label .. "_visibility_invalid"
    end

    return {
        id = id,
        labelKey = labelKey,
        labelFallback = labelFallback,
        utteranceKey = utteranceKey,
        utteranceFallback = utteranceFallback,
        frame = frame,
        constraints = value.constraints,
        consumers = consumers,
        visibility = value.visibility == "player" and "player" or nil,
        priority = tonumber(value.priority) or 0,
    }
end

function Offers.NormalizeList(values, label, maximum)
    label = tostring(label or "semantic_offers")
    maximum = tonumber(maximum) or Offers.MAX_OFFERS
    if values == nil then return {} end
    if type(values) ~= "table" then
        return nil, label .. "_must_be_array"
    end
    if #values > maximum then return nil, label .. "_limit" end
    local output = {}
    local seen = {}
    for index = 1, #values do
        local offer, reason = Offers.Normalize(values[index], label .. "_item")
        if not offer then return nil, reason end
        if seen[offer.id] then return nil, label .. "_duplicate_id" end
        seen[offer.id] = true
        output[#output + 1] = offer
    end
    return output
end

return Offers
