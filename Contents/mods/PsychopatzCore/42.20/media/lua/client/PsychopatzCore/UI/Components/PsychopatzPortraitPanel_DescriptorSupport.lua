require "ISUI/ISUI3DModel"

local Model = ISUI3DModel:derive("PsychopatzPortraitModel")

function Model:prerender()
    if self.animateEnabled == false then
        if self.javaObject then self.javaObject:setAnimate(false) end
        return
    end
    ISUI3DModel.prerender(self)
end

local cache = {}
local clock = 0
local CACHE_LIMIT = 64
local FACE_LOCATION_HINTS = {
    "hat", "head", "eyes", "glasses", "mask", "neck", "scarf",
    "ears", "earring", "nose",
}

local function safeCall(target, methodName, ...)
    local method = target and target[methodName] or nil
    if type(method) ~= "function" then return false, nil end
    local ok, result = pcall(method, target, ...)
    return ok, result
end

local function stableMapSignature(values)
    local keys = {}
    local parts = {}
    for key, _ in pairs(type(values) == "table" and values or {}) do
        keys[#keys + 1] = key
    end
    table.sort(keys, function(left, right) return tostring(left) < tostring(right) end)
    for i = 1, #keys do
        parts[#parts + 1] = tostring(keys[i]) .. "=" .. tostring(values[keys[i]] or "")
    end
    return table.concat(parts, ";")
end

local function stableArraySignature(values)
    local parts = {}
    for i = 1, #(type(values) == "table" and values or {}) do
        parts[#parts + 1] = tostring(values[i] or "")
    end
    return table.concat(parts, ";")
end

local function stableValueSignature(value, depth)
    local keys = {}
    local parts = {}
    depth = tonumber(depth) or 0
    if type(value) ~= "table" then return tostring(value or "") end
    if depth > 4 then return "[depth]" end
    for key, _ in pairs(value) do keys[#keys + 1] = key end
    table.sort(keys, function(left, right)
        return tostring(left) < tostring(right)
    end)
    for i = 1, #keys do
        local key = keys[i]
        parts[#parts + 1] = tostring(key) .. "="
            .. stableValueSignature(value[key], depth + 1)
    end
    return "{" .. table.concat(parts, ";") .. "}"
end

local function isFaceLocation(location)
    local normalized = string.lower(tostring(location or ""))
    for i = 1, #FACE_LOCATION_HINTS do
        if string.find(normalized, FACE_LOCATION_HINTS[i], 1, true) then
            return true
        end
    end
    return false
end

local function wornItems(spec)
    local equipment = type(spec and spec.equipment) == "table"
        and spec.equipment or {}
    local worn = type(equipment.worn) == "table" and equipment.worn or {}
    if spec and (spec.includeCurrentClothing == true
        or spec.clothingMode == "current")
    then
        return worn
    end
    if spec and spec.faceOnly ~= true then return worn end
    local filtered = {}
    for location, fullType in pairs(worn) do
        if isFaceLocation(location) then filtered[location] = fullType end
    end
    return filtered
end

local function wornVisuals(spec)
    local equipment = type(spec and spec.equipment) == "table"
        and spec.equipment or {}
    return type(equipment.wornVisuals) == "table"
        and equipment.wornVisuals or {}
end

local function keyFor(spec)
    local appearance = type(spec and spec.appearance) == "table" and spec.appearance or {}
    local hairColor = type(appearance.hairColor) == "table" and appearance.hairColor or {}
    local skinColor = type(appearance.skinColor) == "table" and appearance.skinColor or {}
    return table.concat({
        tostring(spec and spec.id or ""),
        tostring(spec and spec.identitySeed or 1),
        tostring(spec and spec.isFemale == true),
        tostring(spec and spec.faceOnly == true),
        tostring(appearance.outfitMode or ""),
        tostring(appearance.outfit or ""),
        tostring(appearance.skinTexture or ""),
        tostring(skinColor.r or ""), tostring(skinColor.g or ""),
        tostring(skinColor.b or ""), tostring(appearance.hairModel or ""),
        tostring(appearance.beardModel or ""), tostring(hairColor.r or ""),
        tostring(hairColor.g or ""), tostring(hairColor.b or ""),
        spec and spec.faceOnly == true and spec.includeCurrentClothing ~= true
            and "" or stableArraySignature(appearance.outfitItems),
        stableValueSignature(appearance.outfitItemSpecs),
        stableMapSignature(wornItems(spec)),
        stableValueSignature(wornVisuals(spec)),
    }, "|")
end

local function store(key, descriptor)
    local count = 0
    local oldestKey
    local oldestAt
    clock = clock + 1
    cache[key] = { descriptor = descriptor, touchedAt = clock }
    for cacheKey, entry in pairs(cache) do
        count = count + 1
        if oldestAt == nil or (tonumber(entry.touchedAt) or 0) < oldestAt then
            oldestAt = tonumber(entry.touchedAt) or 0
            oldestKey = cacheKey
        end
    end
    if count > CACHE_LIMIT and oldestKey then cache[oldestKey] = nil end
end

local function lookup(key)
    local entry = cache[key]
    if not entry or not entry.descriptor then return nil end
    clock = clock + 1
    entry.touchedAt = clock
    return entry.descriptor
end

local function size()
    local count = 0
    for _, _ in pairs(cache) do count = count + 1 end
    return count
end

return {
    Model = Model,
    SafeCall = safeCall,
    Key = keyFor,
    WornItems = wornItems,
    WornVisuals = wornVisuals,
    CreateItem = function(fullType)
        if not fullType or fullType == "" then return nil end
        if type(instanceItem) == "function" then
            local ok, item = pcall(instanceItem, fullType)
            if ok and item then return item end
        end
        if InventoryItemFactory and type(InventoryItemFactory.CreateItem) == "function" then
            local ok, item = pcall(InventoryItemFactory.CreateItem, fullType)
            if ok and item then return item end
        end
        return nil
    end,
    Store = store,
    Lookup = lookup,
    Size = size,
}
