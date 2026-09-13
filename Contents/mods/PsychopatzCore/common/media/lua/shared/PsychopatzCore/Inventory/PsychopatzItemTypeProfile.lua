-- Static item capabilities used by every Core inventory consumer.
--
-- A capability is a definition-level fact (for example, "this full type is
-- a fluid container").  It is deliberately kept out of item state and
-- network payloads.  Per-instance values such as fluid amount, condition,
-- age, and durability remain in the existing state/codec contracts.
local Profile = {}

local CAPABILITY_NAMES = {
    "fluid", "food", "ammo", "weapon", "clothing", "drainable",
    "uses", "condition", "conditionAlways", "conditionWhenDamaged",
    "conditionShowAlways",
}

local providers = {}
local registered = {}
local cache = {}
local revision = 0

local function call(object, method, ...)
    local value
    local ok
    if not object or type(object[method]) ~= "function" then return nil end
    ok, value = pcall(object[method], object, ...)
    return ok and value or nil
end

local function kind(item, className)
    local ok
    local value
    local matcher = rawget(_G, "instanceof")
    if not matcher then return false end
    ok, value = pcall(matcher, item, className)
    return ok and value == true
end

local function booleanMethod(item, first, second)
    local value = call(item, first)
    if value == nil and second then value = call(item, second) end
    return value == true
end

local function normalizeCapabilities(source)
    local capabilities = {}
    local index
    local name
    source = type(source) == "table" and source or {}
    if type(source.capabilities) == "table" then
        source = source.capabilities
    end
    for index = 1, #CAPABILITY_NAMES do
        name = CAPABILITY_NAMES[index]
        if source[name] == true then capabilities[name] = true end
    end
    return capabilities
end

local function normalize(fullType, source)
    local output
    local capabilities
    local key = fullType and tostring(fullType) or ""
    if type(source) ~= "table" then return nil end
    if type(source.profile) == "table" then source = source.profile end
    capabilities = normalizeCapabilities(source)
    output = {
        fullType = key ~= "" and key or source.fullType,
        capabilities = capabilities,
        revision = revision,
    }
    return output
end

local function conditionCapabilities(item, capabilities)
    local max = tonumber(call(item, "getConditionMax")) or 0
    if max > 0 then
        capabilities.condition = true
        capabilities.conditionWhenDamaged = true
    end
    if capabilities.weapon or capabilities.clothing then
        capabilities.condition = true
        capabilities.conditionAlways = true
    end
    local mechanicType = tonumber(call(item, "getMechanicType")) or 0
    if mechanicType > 0 then capabilities.conditionShowAlways = true end
    local itemTag = rawget(_G, "ItemTag")
    if itemTag and itemTag.SHOW_CONDITION ~= nil
        and call(item, "hasTag", itemTag.SHOW_CONDITION) == true
    then
        capabilities.conditionShowAlways = true
    end
    return max
end

-- Classifies a native PZ item without reading or allocating instance state.
-- Base InventoryItem getters intentionally return neutral values for many
-- unrelated item types, so component/class checks must precede display use.
function Profile.ClassifyNative(item)
    local capabilities = {}
    local maxAmmo
    local fluidContainer
    local clothing
    local drainable
    local food
    local weapon
    if not item then return { capabilities = {}, revision = revision } end

    food = kind(item, "Food") or booleanMethod(item, "isFood", "IsFood")
        or item.isFood == true
    weapon = kind(item, "HandWeapon") or item.isWeapon == true
    clothing = kind(item, "Clothing") or item.isClothing == true
    drainable = kind(item, "DrainableComboItem")
        or item.isDrainable == true
        or booleanMethod(item, "isDrainable", "IsDrainable")
    fluidContainer = call(item, "getFluidContainer")
    capabilities.food = food
    capabilities.weapon = weapon
    capabilities.clothing = clothing
    capabilities.drainable = drainable
    capabilities.uses = drainable

    if clothing then
        -- Clothing can own filter/tank usage without being a generic
        -- DrainableComboItem.  Preserve that state, but let the tooltip
        -- render it through the clothing section only.
        capabilities.uses = call(item, "getFilterType") ~= nil
            or call(item, "getTankType") ~= nil
    end
    capabilities.fluid = fluidContainer ~= nil
        or booleanMethod(item, "isFluidContainer", "IsFluidContainer")
    -- Fluid containers commonly expose both a fluid amount and a native
    -- used-delta seed.  Keep that definition baseline for compact storage;
    -- the tooltip still suppresses generic Remaining for fluid items.
    if capabilities.fluid then capabilities.uses = true end
    maxAmmo = tonumber(call(item, "getMaxAmmo"))
    capabilities.ammo = maxAmmo ~= nil and maxAmmo > 0
    conditionCapabilities(item, capabilities)
    return {
        fullType = tostring(call(item, "getFullType") or item.fullType
            or item.type or ""),
        capabilities = capabilities,
        revision = revision,
    }
end

function Profile.Normalize(fullType, source)
    return normalize(fullType, source)
end

function Profile.Register(fullType, source)
    local key = fullType and tostring(fullType) or ""
    if key == "" then return false end
    registered[key] = normalize(key, source) or { fullType = key,
        capabilities = {}, revision = revision }
    cache[key] = nil
    return true
end

function Profile.RegisterProvider(callback, priority)
    if type(callback) ~= "function" then return false end
    providers[#providers + 1] = {
        callback = callback, priority = tonumber(priority) or 0,
        order = #providers + 1,
    }
    table.sort(providers, function(left, right)
        if left.priority == right.priority then
            return left.order < right.order
        end
        return left.priority > right.priority
    end)
    revision = revision + 1
    cache = {}
    return true
end

function Profile.Get(fullType)
    local key = fullType and tostring(fullType) or ""
    local entry
    local index
    local provided
    local ok
    if key == "" then return nil end
    if cache[key] ~= nil then
        return cache[key] or nil
    end
    if registered[key] then
        cache[key] = registered[key]
        return registered[key]
    end
    for index = 1, #providers do
        ok, provided = pcall(providers[index].callback, key)
        if ok and type(provided) == "table" then
            entry = normalize(key, provided)
            if entry then
                cache[key] = entry
                return entry
            end
        end
    end
    cache[key] = false
    return nil
end

function Profile.ForRow(row)
    if type(row) ~= "table" then return nil end
    if row.nativeItem then return Profile.ClassifyNative(row.nativeItem) end
    if type(row.itemProfile) == "table" then
        return normalize(row.fullType, row.itemProfile)
    end
    if type(row.capabilities) == "table" then
        return normalize(row.fullType, row.capabilities)
    end
    return Profile.Get(row.fullType or row.type)
end

function Profile.Capabilities(fullType)
    local entry = Profile.Get(fullType)
    return entry and entry.capabilities or {}
end

function Profile.Signature(profile)
    local capabilities = profile and profile.capabilities or profile
    local parts = {}
    local index
    local name
    if type(capabilities) ~= "table" then return "" end
    for index = 1, #CAPABILITY_NAMES do
        name = CAPABILITY_NAMES[index]
        parts[#parts + 1] = name .. "=" .. tostring(capabilities[name] == true)
    end
    return table.concat(parts, ",")
end

Profile.CapabilityNames = CAPABILITY_NAMES

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Inventory = PsychopatzCore.Inventory or {}
PsychopatzCore.Inventory.ItemTypeProfile = Profile

return Profile
