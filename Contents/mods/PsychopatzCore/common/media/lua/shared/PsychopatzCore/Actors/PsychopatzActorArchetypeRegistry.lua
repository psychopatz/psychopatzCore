local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Json = require "PsychopatzCore/Serialization/PsychopatzJson"
local Archetype = require "PsychopatzCore/Actors/PsychopatzActorArchetype"

local Registry = {}
Registry.__index = Registry

local function fingerprint(value)
    return Json.Fingerprint(Json.Encode(value))
end

local function sameDefinition(left, right)
    return fingerprint(left) == fingerprint(right)
end

local function normalizeAlias(value)
    return Util.text(value, nil)
end

local function itemType(value)
    if type(value) == "table" then
        return Util.text(value.fullType, Util.text(value.type, nil))
    end
    return Util.text(value, nil)
end

local function copyAppearanceItem(value)
    local fullType = itemType(value)
    if not fullType then return nil end
    if type(value) == "table" then
        local output = Util.clone(value)
        output.fullType = fullType
        output.type = fullType
        return output
    end
    return {
        fullType = fullType,
        type = fullType,
    }
end

local function appearancePlan(source, gender, seed, archetypeID)
    local input = type(source) == "table" and source or {}
    local variants = input.variants or input.looks
    local pool
    local variant
    local values
    local items = {}
    local specs = {}
    local index
    local value
    local item
    local fullType
    local spawnOutfit

    if type(variants) ~= "table" then
        local resolved = type(input.resolved) == "table"
            and input.resolved or {}
        values = resolved.outfitItemSpecs or resolved.outfitItems or {}
        for index = 1, #values do
            item = copyAppearanceItem(values[index])
            if item then
                items[#items + 1] = item
                specs[#specs + 1] = item
            end
        end
        return Util.clone(input), specs, Util.clone(input.spawnOutfit or {})
    end

    gender = tostring(gender or "male"):lower()
    pool = variants[gender] or variants.male or variants.female
    if type(pool) ~= "table" then pool = {} end
    variant = Util.pick(pool, tostring(seed) .. ":appearance:" .. archetypeID, 7)
    if type(variant) == "table" and type(variant.items) == "table" then
        values = variant.items
    else
        values = type(variant) == "table" and variant or {}
    end

    for index = 1, #values do
        value = values[index]
        item = copyAppearanceItem(value)
        if item then
            fullType = item.fullType
            items[#items + 1] = item
            specs[#specs + 1] = item
        end
    end

    spawnOutfit = Util.clone(input.spawnOutfit or {})
    return {
        schemaVersion = 2,
        mode = "authored",
        authority = "authored",
        policy = {
            schemaVersion = 2,
            mode = "authored",
            authority = "authored",
            outfit = { mode = "random" },
            slots = {},
        },
        resolved = {
            outfitMode = "random",
            outfitItems = items,
            outfitItemSpecs = specs,
            gender = gender,
        },
    }, specs, spawnOutfit
end

local function selectedIdentity(definition, options, seed)
    local source = type(options.identity) == "table"
        and Util.clone(options.identity) or {}
    local profile
    local profileIndex
    local profiles = type(definition.identity) == "table"
        and definition.identity.profiles or nil
    local survivor = type(source.survivor) == "table"
        and source.survivor or {}
    local gender = Util.text(source.gender, nil)
        or (source.isFemale == true and "female" or nil)
        or Util.text(definition.identity and definition.identity.gender, nil)
        or "male"
    local forename
    local surname

    local sourceHasValue = false
    local sourceKey
    for sourceKey in pairs(source) do
        sourceHasValue = true
        break
    end

    if type(profiles) == "table" and #profiles > 0
        and not sourceHasValue
    then
        profileIndex = tonumber(options.identityIndex)
        if profileIndex then
            profileIndex = math.max(1, math.floor(profileIndex))
            profile = profiles[((profileIndex - 1) % #profiles) + 1]
        else
            profile = Util.pick(profiles, tostring(seed) .. ":identity", 17)
        end
        if type(profile) == "table" then source = Util.clone(profile) end
        survivor = type(source.survivor) == "table"
            and source.survivor or {}
        gender = Util.text(source.gender, gender)
    end

    forename = Util.text(source.forename, Util.text(survivor.forename, nil))
    surname = Util.text(source.surname, Util.text(survivor.surname, nil))
    source.schemaVersion = tonumber(source.schemaVersion) or 1
    source.identitySeed = seed
    source.archetypeID = definition.id
    source.gender = gender
    source.survivor = Util.clone(survivor)
    source.survivor.gender = gender
    if forename then source.survivor.forename = forename end
    if surname then source.survivor.surname = surname end
    if not source.displayName and forename and surname then
        source.displayName = forename .. " " .. surname
    end
    return source
end

local function hasItem(items, fullType)
    for _, value in ipairs(items or {}) do
        if itemType(value) == fullType then return true end
    end
    return false
end

function Registry.new()
    return setmetatable({
        definitions = {},
        aliases = {},
        errors = {},
        revision = 0,
    }, Registry)
end

function Registry:ResolveID(value)
    local id = normalizeAlias(value)
    if not id then return nil end
    if self.aliases[id] then return self.aliases[id] end
    if self.definitions[id] then return id end
    return nil
end

function Registry:Register(source)
    local definition
    local reason
    local existing
    local alias
    local aliasIndex
    local resolved

    definition, reason = Archetype.Normalize(source)
    if not definition then
        self.errors[#self.errors + 1] = {
            id = type(source) == "table" and source.id or nil,
            reason = reason,
        }
        return false, reason
    end

    existing = self.definitions[definition.id]
    if existing then
        if sameDefinition(existing, definition) then
            return true, "already_registered"
        end
        self.errors[#self.errors + 1] = {
            id = definition.id,
            reason = "archetype_id_conflict",
        }
        return false, "archetype_id_conflict"
    end

    for aliasIndex = 1, #definition.aliases do
        alias = definition.aliases[aliasIndex]
        resolved = self:ResolveID(alias)
        if resolved and resolved ~= definition.id then
            self.errors[#self.errors + 1] = {
                id = definition.id,
                reason = "archetype_alias_conflict:" .. tostring(alias),
            }
            return false, "archetype_alias_conflict"
        end
    end

    self.definitions[definition.id] = definition
    self.aliases[definition.id] = definition.id
    for aliasIndex = 1, #definition.aliases do
        self.aliases[definition.aliases[aliasIndex]] = definition.id
    end
    self.revision = self.revision + 1
    return true, "registered"
end

function Registry:Get(value)
    local id = self:ResolveID(value)
    local definition = id and self.definitions[id] or nil
    return definition and Util.clone(definition) or nil
end

function Registry:Has(value)
    return self:Get(value) ~= nil
end

-- Resolve one authored archetype into the provider-neutral actor inputs used by
-- Core Factory/Inventory and by physical adapters.  This is a query only: the
-- registry remains the owner of definitions and callers receive fresh tables.
function Registry:ResolvePlan(value, options)
    options = type(options) == "table" and options or {}
    local definition = self:Get(value)
    local seed = options.seed or options.identitySeed or options.actorId
    local identity
    local appearance
    local appearanceItems
    local spawnOutfit
    local items
    local bagType
    local starterItems
    local bagItem

    if not definition then return nil, "archetype_not_found" end
    seed = seed or definition.id
    identity = selectedIdentity(definition, options, seed)
    appearance, appearanceItems, spawnOutfit = appearancePlan(
        definition.appearance,
        identity.gender,
        seed,
        definition.id
    )
    if type(appearance) == "table"
        and type(appearance.resolved) == "table"
    then
        for _, key in ipairs({
            "skinTone", "skinTexture", "skinColor", "hairModel",
            "hairColor", "beardModel",
        }) do
            if identity.survivor[key] == nil then
                identity.survivor[key] = Util.clone(
                    appearance.resolved[key]
                )
            end
        end
    end
    items = Util.clone(definition.inventory.items or {})
    bagType = Util.pick(
        definition.inventory.bagChoices or {},
        tostring(seed) .. ":bag:" .. definition.id,
        11
    )
    starterItems = Util.clone(items)
    if bagType and not hasItem(starterItems, bagType) then
        bagItem = {
            fullType = bagType,
            type = bagType,
            quantity = 1,
            stack = 1,
        }
        starterItems[#starterItems + 1] = bagItem
    end

    return {
        schemaVersion = 1,
        archetypeID = definition.id,
        sourceID = normalizeAlias(value),
        definition = definition,
        identity = identity,
        appearance = appearance,
        appearanceItems = appearanceItems,
        spawnOutfit = spawnOutfit,
        inventory = Util.clone(definition.inventory),
        bagType = bagType,
        starterItems = starterItems,
        equipment = Util.clone(definition.inventory.equipment or {}),
    }
end

function Registry:List()
    local output = {}
    local ids = {}
    local id
    for id in pairs(self.definitions) do ids[#ids + 1] = id end
    table.sort(ids)
    for _, id in ipairs(ids) do
        output[#output + 1] = Util.clone(self.definitions[id])
    end
    return output
end

function Registry:ListErrors()
    return Util.clone(self.errors)
end

function Registry:Count()
    local count = 0
    for _ in pairs(self.definitions) do count = count + 1 end
    return count
end

return Registry
