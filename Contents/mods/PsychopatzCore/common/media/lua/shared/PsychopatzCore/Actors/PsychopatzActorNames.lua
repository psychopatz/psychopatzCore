-- Provider-neutral deterministic actor name primitives.
--
-- Core owns the reusable mechanics: name parts, display formatting, and
-- identity-seed-derived nicknames. Adopters own knowledge/disclosure policy
-- and may provide their own name catalogs through the options table.

PsychopatzCore = PsychopatzCore or {}

local Content = require "PsychopatzCore/Content/PsychopatzDeterministicContent"

local Names = {}

Names.VERSION = 1
Names.NICKNAME_GENERATOR_VERSION = 1

local DEFAULT_MALE = {
    "Adam", "Aaron", "Ben", "Caleb", "Derek", "Eli", "Felix", "Grant",
    "Harvey", "Isaac", "Jonah", "Liam", "Marcus", "Noah", "Owen",
    "Peter", "Quinn", "Rory", "Samuel", "Victor",
}

local DEFAULT_FEMALE = {
    "Alice", "Beth", "Cara", "Diana", "Elise", "Faith", "Grace",
    "Hannah", "Ivy", "Julia", "Kara", "Lena", "Maya", "Nina",
    "Olive", "Paige", "Ruby", "Sara", "Tessa", "Wren",
}

local DEFAULT_SURNAMES = {
    "Bennett", "Carter", "Dalton", "Ellis", "Foster", "Griffin",
    "Hayes", "Irwin", "Keller", "Lang", "Morris", "Nolan", "Owens",
    "Parker", "Quincy", "Reed", "Sawyer", "Turner", "Vance", "Walker",
}

-- These are relationship-neutral conventional aliases. They are deliberately
-- keyed by the actor's own forename so a seed never invents an unrelated name.
local NICKNAME_ALIASES = {
    alexander = { "Alex", "Xander" },
    alexandra = { "Alex", "Lexi" },
    benjamin = { "Ben", "Benny" },
    elizabeth = { "Liz", "Beth", "Lizzy" },
    patrick = { "Pat", "Paddy", "Rick" },
    patricia = { "Pat", "Patty", "Trish" },
    rebecca = { "Becca", "Becky" },
    samantha = { "Sam", "Sammy" },
    samuel = { "Sam", "Sammy" },
    william = { "Will", "Billy" },
}

local function clean(value)
    if value == nil then return nil end
    value = tostring(value)
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    value = string.gsub(value, "%s+", " ")
    return value ~= "" and value or nil
end

local function normalized(value)
    return string.lower(clean(value) or "")
end

local function nameCatalog(options)
    options = type(options) == "table" and options or {}
    if type(options.catalog) == "table" then return options.catalog end
    if type(Content.NativeNameCatalog) == "function" then
        local native = Content.NativeNameCatalog()
        if type(native) == "table" then return native end
    end
    return {
        femaleFirst = DEFAULT_FEMALE,
        maleFirst = DEFAULT_MALE,
        surnames = DEFAULT_SURNAMES,
        source = "psychopatz_core_fallback",
    }
end

function Names.CatalogInfo(catalog)
    catalog = type(catalog) == "table" and catalog or nameCatalog({})
    return Content.NameCatalogInfo(catalog)
end

function Names.Normalize(value)
    return clean(value)
end

function Names.Split(fullName)
    fullName = clean(fullName)
    if not fullName then return nil, nil end
    return string.match(fullName, "^(%S+)"),
        string.match(fullName, "^%S+%s+(.+)$")
end

function Names.Compose(forename, surname)
    local first = clean(forename)
    local last = clean(surname)
    if first and last then return first .. " " .. last end
    return first or last
end

function Names.FormatDisplayName(fullName, nickname)
    fullName = clean(fullName)
    nickname = clean(nickname)
    if not fullName then return nickname end
    if not nickname or normalized(fullName) == normalized(nickname) then
        return fullName
    end
    return fullName .. " (" .. nickname .. ")"
end

function Names.ResolveNickname(forename, identitySeed, options)
    options = type(options) == "table" and options or {}
    local explicit = clean(options.nickname or options.alias)
    if explicit then return explicit end

    forename = clean(forename)
    if not forename then return nil end

    local candidates = NICKNAME_ALIASES[normalized(forename)]
    if type(candidates) ~= "table" or #candidates == 0 then
        candidates = { #forename <= 4 and forename or string.sub(forename, 1, 3) }
    end

    -- Use a wide deterministic index before reducing to a small authored alias
    -- list so identitySeed materially affects the result.
    local wideIndex = Content.Index(
        "identity",
        identitySeed,
        "psychopatz.identity.nickname:" .. normalized(forename),
        1000000,
        tostring(options.salt or "nickname"),
        options.version or Names.NICKNAME_GENERATOR_VERSION
    ) or 1
    return candidates[((wideIndex - 1) % #candidates) + 1]
end

function Names.Generate(identitySeed, isFemale, archetypeID, options)
    options = type(options) == "table" and options or {}
    local catalog = nameCatalog(options)
    if type(Content.GenerateName) == "function" then
        return Content.GenerateName({
            saveSeed = options.saveSeed or Content.ResolveSaveSeed(options),
            identitySeed = identitySeed,
            namespace = options.namespace or "psychopatz.identity.name",
            version = options.version,
            isFemale = isFemale == true,
            archetypeID = archetypeID or "General",
            firstName = options.firstName or options.forename,
            surname = options.surname or options.lastName,
        }, catalog)
    end

    local firstPool = isFemale and catalog.femaleFirst or catalog.maleFirst
    local surnamePool = catalog.surnames
    local first = clean(options.firstName or options.forename)
        or firstPool[Content.Index(
            "identity", identitySeed, "psychopatz.identity.first", #firstPool,
            tostring(archetypeID or "General"), options.version
        ) or 1]
    local surname = clean(options.surname or options.lastName)
        or surnamePool[Content.Index(
            "identity", identitySeed, "psychopatz.identity.surname",
            #surnamePool, "surname", options.version
        ) or 1]
    return Names.Compose(first, surname)
end

-- Resolve already-authored identity fields without applying knowledge policy.
-- Callers that need generated nickname data must opt in explicitly.
function Names.ResolveParts(source, options)
    source = type(source) == "table" and source or {}
    options = type(options) == "table" and options or {}
    local identity = type(source.identity) == "table" and source.identity or {}
    local survivor = type(identity.survivor) == "table" and identity.survivor or {}
    local fullName = clean(
        source.fullName or source.displayName or source.name
            or identity.fullName or identity.displayName
    )
    local forename = clean(
        source.forename or source.firstName or identity.forename
            or identity.firstName or survivor.forename or survivor.firstName
    )
    local surname = clean(
        source.surname or source.lastName or identity.surname
            or identity.lastName or survivor.surname or survivor.lastName
    )
    local nickname = clean(
        source.nickname or source.alias or identity.nickname or identity.alias
            or survivor.nickname
    )
    local seed = source.identitySeed or source.actorSeed or source.npcIdentitySeed
        or identity.identitySeed or identity.seed or source.id or source.actorID

    if fullName then
        local baseName, parenthetical = string.match(
            fullName, "^(.-)%s*%(([^()]+)%)$"
        )
        if baseName and parenthetical then
            fullName = clean(baseName)
            nickname = nickname or clean(parenthetical)
        end
    end
    if fullName and (not forename or not surname) then
        local parsedFirst, parsedSurname = Names.Split(fullName)
        forename = forename or parsedFirst
        surname = surname or parsedSurname
    end
    if not fullName then fullName = Names.Compose(forename, surname) end
    if not nickname and options.resolveNickname == true then
        nickname = Names.ResolveNickname(forename, seed, options)
    end
    local displayNickname = options.includeNickname == true
        and nickname or nil
    return {
        identitySeed = seed,
        fullName = fullName,
        forename = forename,
        firstName = forename,
        surname = surname,
        lastName = surname,
        nickname = nickname,
        displayName = Names.FormatDisplayName(fullName, displayNickname),
    }
end

PsychopatzCore.ActorNames = Names
PsychopatzCore.Actors = PsychopatzCore.Actors or {}
PsychopatzCore.Actors.Names = Names

return Names
