-- Shared deterministic content primitives.
--
-- A content result is derived from the current save/world seed, an actor or
-- identity seed, and a versioned namespace.  Nothing is written here: callers
-- may persist gameplay facts, but generated names, flavour and catalog picks
-- remain reproducible projections.
local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"

local Content = {}

Content.VERSION = 1
Content.DEFAULT_SAVE_SEED = "PNC_DEFAULT_SAVE_SEED"
Content.DEFAULT_NAMESPACE = "psychopatz.content"

local function text(value, fallback)
    return Util.text(value, fallback)
end

local function nativeSaveSeed()
    local params = rawget(_G, "WorldGenParams")
        and WorldGenParams.INSTANCE or nil
    if not params or type(params.getSeedString) ~= "function" then
        return nil
    end
    local ok, value = pcall(params.getSeedString, params)
    if ok then return text(value, nil) end
    return nil
end

function Content.ResolveSaveSeed(source)
    if type(source) == "string" or type(source) == "number" then
        return tostring(source)
    end
    if type(source) == "table" then
        local world = type(source.world) == "table" and source.world or {}
        local value = text(source.saveSeed, nil)
            or text(source.seedString, nil)
            or text(source.worldSeedString, nil)
            or text(world.seedString, nil)
            or text(world.worldSeedString, nil)
        if value then return value end
        if source.worldSeed ~= nil then
            return tostring(source.worldSeed)
        end
    end
    return nativeSaveSeed() or Content.DEFAULT_SAVE_SEED
end

local function canonicalPart(value)
    value = tostring(value or "")
    return tostring(#value) .. ":" .. value
end

function Content.CanonicalSeed(saveSeed, identitySeed, namespace, version)
    return table.concat({
        canonicalPart(version or Content.VERSION),
        canonicalPart(namespace or Content.DEFAULT_NAMESPACE),
        canonicalPart(Content.ResolveSaveSeed(saveSeed)),
        canonicalPart(identitySeed),
    }, "\31")
end

function Content.Hash(saveSeed, identitySeed, namespace, version)
    return Util.hash(Content.CanonicalSeed(
        saveSeed, identitySeed, namespace, version
    ))
end

function Content.Index(saveSeed, identitySeed, namespace, count, salt, version)
    count = math.floor(tonumber(count) or 0)
    if count <= 0 then return nil end
    local seed = Content.CanonicalSeed(
        saveSeed,
        identitySeed,
        tostring(namespace or Content.DEFAULT_NAMESPACE)
            .. ":" .. tostring(salt or "pick"),
        version
    )
    return (Util.hash(seed) % count) + 1
end

function Content.Range(
    saveSeed, identitySeed, namespace, minimum, maximum, salt, version
)
    local low = math.floor(tonumber(minimum) or 0)
    local high = math.floor(tonumber(maximum) or low)
    if high < low then high = low end
    local index = Content.Index(
        saveSeed, identitySeed, namespace, high - low + 1, salt, version
    )
    return low + (index or 1) - 1
end

function Content.Choose(values, saveSeed, identitySeed, namespace, salt, version)
    if type(values) ~= "table" or #values == 0 then return nil end
    local index = Content.Index(
        saveSeed, identitySeed, namespace, #values, salt, version
    )
    return values[index or 1], index
end

local DEFAULT_FEMALE = {
    "Alex", "Avery", "Casey", "Drew", "Jordan", "Morgan",
}
local DEFAULT_MALE = {
    "Alex", "Avery", "Casey", "Drew", "Jordan", "Morgan",
}
local DEFAULT_SURNAMES = {
    "Bennett", "Carter", "Hayes", "Marlow", "Parker", "Reed",
}

local function readNamePool(value)
    if type(value) == "table" then
        local output = {}
        for index = 1, #value do
            local item = tostring(value[index] or "")
            if item ~= "" then output[#output + 1] = item end
        end
        return #output > 0 and output or nil
    end
    if not value or not value.size or not value.get then return nil end
    local ok, size = pcall(function() return tonumber(value:size()) end)
    if not ok or not size or size <= 0 or size > 100000 then return nil end
    local output = {}
    for index = 0, size - 1 do
        local itemOK, item = pcall(function() return value:get(index) end)
        item = itemOK and tostring(item or "") or ""
        if item ~= "" then output[#output + 1] = item end
    end
    return #output > 0 and output or nil
end

function Content.DefaultNameCatalog()
    return {
        femaleFirst = DEFAULT_FEMALE,
        maleFirst = DEFAULT_MALE,
        surnames = DEFAULT_SURNAMES,
        source = "psychopatz_core_fallback",
    }
end

function Content.NativeNameCatalog()
    local factory = rawget(_G, "SurvivorFactory")
    if not factory then return nil end
    local female = readNamePool(factory.FemaleForenames)
    local male = readNamePool(factory.MaleForenames)
    local surnames = readNamePool(factory.Surnames)
    if not female or not male or not surnames then return nil end
    return {
        femaleFirst = female,
        maleFirst = male,
        surnames = surnames,
        source = "project_zomboid_survivor_factory",
    }
end

function Content.NameCatalogInfo(catalog)
    catalog = type(catalog) == "table" and catalog
        or Content.NativeNameCatalog()
        or Content.DefaultNameCatalog()
    return {
        source = catalog.source or "provided",
        femaleFirstCount = type(catalog.femaleFirst) == "table"
            and #catalog.femaleFirst or 0,
        maleFirstCount = type(catalog.maleFirst) == "table"
            and #catalog.maleFirst or 0,
        surnameCount = type(catalog.surnames) == "table"
            and #catalog.surnames or 0,
    }
end

function Content.GenerateName(options, catalog)
    options = type(options) == "table" and options or {}
    catalog = type(catalog) == "table" and catalog
        or Content.NativeNameCatalog()
        or Content.DefaultNameCatalog()
    local female = options.isFemale == true
        or tostring(options.gender or ""):lower() == "female"
    local firstPool = female and catalog.femaleFirst or catalog.maleFirst
    local surnamePool = catalog.surnames
    if type(firstPool) ~= "table" or #firstPool == 0 then
        firstPool = female and DEFAULT_FEMALE or DEFAULT_MALE
    end
    if type(surnamePool) ~= "table" or #surnamePool == 0 then
        surnamePool = DEFAULT_SURNAMES
    end
    local namespace = tostring(options.namespace or "name")
    local first = Content.Choose(
        firstPool,
        options.saveSeed,
        options.identitySeed,
        namespace,
        "first:" .. tostring(options.archetypeID or "General"),
        options.version
    )
    local surname = Content.Choose(
        surnamePool,
        options.saveSeed,
        options.identitySeed,
        namespace,
        "surname",
        options.version
    )
    return tostring(first or "Alex") .. " " .. tostring(surname or "Reed")
end

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Content = PsychopatzCore.Content or {}
PsychopatzCore.Content.Deterministic = Content
PsychopatzCore.DeterministicContent = Content

return Content
