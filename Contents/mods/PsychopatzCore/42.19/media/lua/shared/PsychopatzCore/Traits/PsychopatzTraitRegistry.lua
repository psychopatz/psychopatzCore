-- Reusable Build 42 trait registration and character-trait inspection.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Traits = PsychopatzCore.Traits or {}

local Traits = PsychopatzCore.Traits

Traits.Catalogs = Traits.Catalogs or {}
Traits.Definitions = Traits.Definitions or {}
Traits.EngineTraits = Traits.EngineTraits or {}
Traits.Aliases = Traits.Aliases or {}
Traits.Exclusions = Traits.Exclusions or {}

local function copy(value)
    local output = {}
    local key
    local item
    for key, item in pairs(value or {}) do
        output[key] = type(item) == "table" and copy(item) or item
    end
    return output
end

local function normalized(value)
    if type(value) ~= "string" or value == "" then return nil end
    return string.lower(value)
end

local function localized(value)
    if getText and type(value) == "string" then
        local ok
        local translated
        ok, translated = pcall(getText, value)
        if ok and translated and translated ~= "" then return translated end
    end
    return value
end

local function alias(owner, value, id)
    value = normalized(value)
    if not value then return end
    Traits.Aliases[value] = id
    Traits.Aliases[string.lower(owner) .. ":" .. value] = id
end

function Traits.RegisterCatalog(owner, definitions, exclusions)
    if type(owner) ~= "string" or owner == "" then
        return false, "invalid_owner"
    end
    if type(definitions) ~= "table" then
        return false, "invalid_definitions"
    end
    if Traits.Catalogs[owner] then
        return Traits.RegisterAll()
    end
    local catalog = Traits.Catalogs[owner] or {
        owner = owner,
        definitions = {},
        exclusions = {},
    }
    local index
    local source
    local spec
    for index = 1, #definitions do
        source = definitions[index]
        if type(source) ~= "table"
            or type(source.id) ~= "string" or source.id == ""
            or type(source.resource) ~= "string" or source.resource == ""
        then
            return false, "invalid_definition:" .. tostring(index)
        end
        spec = copy(source)
        spec.owner = owner
        spec.cost = tonumber(spec.cost) or 0
        catalog.definitions[#catalog.definitions + 1] = spec
        Traits.Definitions[spec.id] = spec
        alias(owner, spec.id, spec.id)
        alias(owner, spec.resource, spec.id)
        alias(owner, string.match(spec.resource, ":(.+)$"), spec.id)
    end
    for index = 1, #(exclusions or {}) do
        local pair = exclusions[index]
        if type(pair) == "table" and pair[1] and pair[2] then
            catalog.exclusions[#catalog.exclusions + 1] = {
                pair[1], pair[2],
            }
            Traits.Exclusions[#Traits.Exclusions + 1] = {
                pair[1], pair[2],
            }
        end
    end
    Traits.Catalogs[owner] = catalog
    return Traits.RegisterAll()
end

function Traits.NormalizeID(value, owner)
    value = normalized(value)
    if not value then return nil end
    if owner then
        return Traits.Aliases[string.lower(owner) .. ":" .. value]
            or Traits.Aliases[value]
    end
    return Traits.Aliases[value]
end

function Traits.GetDefinition(value, owner)
    local id = Traits.NormalizeID(value, owner) or value
    local spec = Traits.Definitions[id]
    return spec and copy(spec) or nil
end

function Traits.GetDefinitions(owner)
    local output = {}
    local catalog = owner and Traits.Catalogs[owner] or nil
    local source = catalog and catalog.definitions or Traits.Definitions
    local index
    local _, spec
    if catalog then
        for index = 1, #source do output[index] = copy(source[index]) end
    else
        for _, spec in pairs(source) do output[#output + 1] = copy(spec) end
        table.sort(output, function(left, right)
            return tostring(left.resource) < tostring(right.resource)
        end)
    end
    return output
end

local function engineTraitFor(resource)
    local ok
    local location
    local trait
    if not CharacterTrait or not ResourceLocation or not ResourceLocation.of then
        return nil
    end
    ok, location = pcall(ResourceLocation.of, resource)
    if not ok or not location then return nil end
    if CharacterTrait.get then
        ok, trait = pcall(CharacterTrait.get, location)
        if not ok then trait = nil end
    end
    if not trait and CharacterTrait.register then
        ok, trait = pcall(CharacterTrait.register, resource)
        if not ok then trait = nil end
    end
    return trait
end

function Traits.RegisterAll()
    if not CharacterTrait or not CharacterTraitDefinition
        or not CharacterTraitDefinition.addCharacterTraitDefinition
    then
        return false, "api_unavailable"
    end
    local id
    local spec
    local trait
    local existing
    local ok
    for id, spec in pairs(Traits.Definitions) do
        trait = Traits.EngineTraits[id] or engineTraitFor(spec.resource)
        if not trait then return false, "trait_registration_failed:" .. id end
        Traits.EngineTraits[id] = trait
        existing = CharacterTraitDefinition.getCharacterTraitDefinition
            and CharacterTraitDefinition.getCharacterTraitDefinition(trait)
            or nil
        if not existing then
            ok, existing = pcall(
                CharacterTraitDefinition.addCharacterTraitDefinition,
                trait,
                localized(spec.uiName),
                spec.cost,
                localized(spec.uiDescription),
                false,
                false
            )
            if not ok or not existing then
                return false, "definition_registration_failed:" .. id
            end
        end
    end
    local index
    local pair
    for index = 1, #Traits.Exclusions do
        pair = Traits.Exclusions[index]
        if Traits.EngineTraits[pair[1]] and Traits.EngineTraits[pair[2]]
            and CharacterTraitDefinition.setMutualExclusive
        then
            CharacterTraitDefinition.setMutualExclusive(
                Traits.EngineTraits[pair[1]], Traits.EngineTraits[pair[2]]
            )
        end
    end
    return true, "registered"
end

local function call(target, methodName, argument)
    local method = target and target[methodName] or nil
    if not method then return nil end
    local ok
    local result
    if argument ~= nil then
        ok, result = pcall(method, target, argument)
    else
        ok, result = pcall(method, target)
    end
    return ok and result or nil
end

local function traitID(value, owner)
    if type(value) == "string" then return Traits.NormalizeID(value, owner) end
    local text = call(value, "toString")
    local id = text and Traits.NormalizeID(tostring(text), owner) or nil
    if id then return id end
    text = call(value, "getName")
    return text and Traits.NormalizeID(tostring(text), owner) or nil
end

-- Returns nil when the engine has not synchronized a character's trait
-- container yet. Callers can safely retry later without treating that as an
-- empty selection.
function Traits.ReadPlayer(player, owner)
    local characterTraits = call(player, "getCharacterTraits")
    local known = call(characterTraits, "getKnownTraits")
    if not known then return nil, "traits_not_ready" end
    local output = {}
    local size = call(known, "size")
    local index
    local value
    local id
    if size ~= nil and known.get then
        for index = 0, math.max(0, tonumber(size) or 0) - 1 do
            value = call(known, "get", index)
            id = traitID(value, owner)
            if id then output[id] = true end
        end
    else
        for _, value in pairs(known) do
            id = traitID(value, owner)
            if id then output[id] = true end
        end
    end
    return output, "ready"
end

function Traits.PlayerHas(player, value, owner)
    local selected, reason = Traits.ReadPlayer(player, owner)
    if not selected then return nil, reason end
    local id = Traits.NormalizeID(value, owner) or value
    return selected[id] == true, "ready"
end

Traits.RegisterAll()
if Events and Events.OnGameBoot and not Traits.GameBootHookRegistered then
    Events.OnGameBoot.Add(Traits.RegisterAll)
    Traits.GameBootHookRegistered = true
end

return Traits
