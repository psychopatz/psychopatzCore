local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"

local Archetype = {}

Archetype.SCHEMA_VERSION = 1
Archetype.MAX_ID_LENGTH = 128
Archetype.MAX_TAGS = 32
Archetype.MAX_ALIASES = 16
Archetype.MAX_ITEMS = 128

local function text(value, fallback)
    return Util.text(value, fallback)
end

local function validID(value)
    return type(value) == "string"
        and #value <= Archetype.MAX_ID_LENGTH
        and string.match(value, "^[%w_%.:%-]+$") ~= nil
end

local function normalizeList(value, limit)
    local output = {}
    local seen = {}
    local index
    local item
    if type(value) ~= "table" then return output end
    for index = 1, math.min(#value, limit) do
        item = text(value[index], nil)
        if item and not seen[item] then
            seen[item] = true
            output[#output + 1] = item
        end
    end
    return output
end

local function normalizeExtensions(value)
    local output = {}
    local key
    local item
    if type(value) ~= "table" then return output end
    for key, item in pairs(value) do
        if not Util.isNamespacedKey(key) then
            return nil, "extension_namespace_invalid"
        end
        if not Util.isSerializable(item) then
            return nil, "extension_not_serializable"
        end
        output[key] = Util.clone(item)
    end
    return output
end

local function normalizeItem(value, index)
    local output
    local fullType
    local quantity
    if type(value) ~= "table" then
        return nil, "item_invalid:" .. tostring(index)
    end
    fullType = text(value.fullType, text(value.type, nil))
    if not fullType then
        return nil, "item_full_type_required:" .. tostring(index)
    end
    quantity = tonumber(value.quantity or value.stack) or 1
    if quantity ~= quantity or quantity == math.huge
        or quantity == -math.huge or quantity < 1
    then
        return nil, "item_quantity_invalid:" .. tostring(index)
    end
    output = Util.clone(value)
    output.fullType = fullType
    output.type = fullType
    output.quantity = math.max(1, math.floor(quantity))
    output.stack = math.max(1, math.floor(
        tonumber(value.stack) or output.quantity
    ))
    output.key = text(value.key or value.templateKey, nil)
    if not Util.isSerializable(output) then
        return nil, "item_not_serializable:" .. tostring(index)
    end
    return output
end

local function normalizeItems(source)
    local output = {}
    local index
    local item
    local reason
    if type(source) ~= "table" then return output end
    if #source > Archetype.MAX_ITEMS then
        return nil, "too_many_items"
    end
    for index = 1, #source do
        item, reason = normalizeItem(source[index], index)
        if not item then return nil, reason end
        output[index] = item
    end
    return output
end

local function normalizeSkillBias(value)
    local output = {}
    local skillID
    local bias
    local minLevel
    local maxLevel
    if type(value) ~= "table" then return output end
    for skillID, bias in pairs(value) do
        if type(bias) == "table" then
            minLevel = tonumber(bias.min) or 0
            maxLevel = tonumber(bias.max) or minLevel
        else
            minLevel = tonumber(bias)
            maxLevel = minLevel
        end
        if minLevel == nil or maxLevel == nil
            or minLevel ~= minLevel or maxLevel ~= maxLevel
        then
            return nil, "skill_bias_invalid:" .. tostring(skillID)
        end
        output[tostring(skillID)] = {
            min = math.max(0, math.floor(minLevel)),
            max = math.max(0, math.floor(maxLevel)),
        }
        if output[tostring(skillID)].max
            < output[tostring(skillID)].min
        then
            output[tostring(skillID)].max = output[tostring(skillID)].min
        end
    end
    return output
end

function Archetype.Normalize(source)
    local input
    local inventorySource
    local itemSource
    local normalizedItems
    local skillBias
    local extensions
    local aliases
    local normalizedAliases
    local id
    local aliasIndex
    local alias
    local reason

    if type(source) ~= "table" then return nil, "archetype_required" end
    input = source
    id = text(input.id or input.archetypeID, nil)
    if not validID(id) then return nil, "archetype_id_invalid" end

    inventorySource = type(input.inventory) == "table"
        and input.inventory or input.loadout
    inventorySource = type(inventorySource) == "table"
        and inventorySource or {}
    itemSource = inventorySource.items
        or inventorySource.supplies
        or input.items
        or input.startingItems
        or {}
    normalizedItems, reason = normalizeItems(itemSource)
    if not normalizedItems then return nil, reason end

    skillBias, reason = normalizeSkillBias(
        input.skillBias or input.skills
    )
    if not skillBias then return nil, reason end

    extensions, reason = normalizeExtensions(input.extensions)
    if not extensions then return nil, reason end

    aliases = normalizeList(input.aliases, Archetype.MAX_ALIASES)
    normalizedAliases = {}
    for aliasIndex = 1, #aliases do
        alias = aliases[aliasIndex]
        if not validID(alias) then return nil, "archetype_alias_invalid" end
        if alias ~= id then normalizedAliases[#normalizedAliases + 1] = alias end
    end
    aliases = normalizedAliases

    local output = {
        schemaVersion = Archetype.SCHEMA_VERSION,
        id = id,
        label = text(input.label or input.name, id),
        sourceMod = text(input.sourceMod or input.ownerMod, "unknown"),
        tags = normalizeList(input.tags, Archetype.MAX_TAGS),
        visualProfile = text(input.visualProfile, nil),
        role = text(input.role, nil),
        identity = Util.clone(input.identity or input.identityProfile or {}),
        skillBias = skillBias,
        appearance = Util.clone(input.appearance or input.looks or {}),
        inventory = {
            bagChoices = normalizeList(inventorySource.bagChoices, 16),
            attached = Util.clone(inventorySource.attached or {}),
            items = normalizedItems,
            equipment = Util.clone(inventorySource.equipment or {}),
        },
        aliases = aliases,
        extensions = extensions,
    }
    if not Util.isSerializable(output) then
        return nil, "archetype_not_serializable"
    end
    return output
end

function Archetype.Validate(value)
    local normalized, reason = Archetype.Normalize(value)
    if not normalized then return false, reason end
    return true
end

return Archetype
