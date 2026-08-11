local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local Metrics = require "PsychopatzCore/Inventory/PsychopatzInventoryMetrics"

local Registry = { ordered = {}, byId = {}, byName = {} }

function Registry.register(definition)
    if type(definition) ~= "table" or type(definition.id) ~= "number"
        or type(definition.name) ~= "string" or type(definition.matches) ~= "function"
        or type(definition.encode) ~= "function" or type(definition.decode) ~= "function"
    then
        return false, "invalid_codec"
    end
    if Registry.byId[definition.id] or Registry.byName[definition.name] then
        return false, "duplicate_codec"
    end
    Registry.byId[definition.id] = definition
    Registry.byName[definition.name] = definition
    Registry.ordered[#Registry.ordered + 1] = definition
    table.sort(Registry.ordered, function(a, b)
        return (tonumber(a.priority) or 0) > (tonumber(b.priority) or 0)
    end)
    return true
end

function Registry.resolve(item)
    for i = 1, #Registry.ordered do
        local codec = Registry.ordered[i]
        local ok, matches = pcall(codec.matches, item)
        if ok and matches then
            if codec.id == C.CODEC_FALLBACK then Metrics.increment("codecFallbackCount") end
            return codec
        end
    end
    return Registry.byId[C.CODEC_FALLBACK]
end

function Registry.get(id)
    return Registry.byId[math.floor(tonumber(id) or C.CODEC_FALLBACK)]
        or Registry.byId[C.CODEC_FALLBACK]
end

PsychopatzCore.Inventory.ItemCodecRegistry = Registry
return Registry
