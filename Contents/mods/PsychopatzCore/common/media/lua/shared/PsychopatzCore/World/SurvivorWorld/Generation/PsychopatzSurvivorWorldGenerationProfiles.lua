local Generation = require
    "PsychopatzCore/World/SurvivorWorld/Generation/PsychopatzSurvivorWorldGenerationCore"
local I = Generation.Internal

local Profiles = {}

local NAME_POOLS = {
    settler = {
        first = {
            "Ashwood", "Cedar", "Clearwater", "Fairview",
            "Greenfield", "Maple", "Oakridge", "Pinecrest",
            "Riverside", "Stonebridge", "Westhaven", "Willow",
        },
        second = {
            "Community", "Enclave", "Haven", "Homestead",
            "Refuge", "Settlement",
        },
        site = { "Haven", "Homestead", "Settlement" },
    },
    looter = {
        first = {
            "Ash", "Black", "Broken", "Burning", "Cold",
            "Crimson", "Iron", "Ragged", "Red", "Rust",
            "Scar", "Vulture",
        },
        second = {
            "Crows", "Fangs", "Hand", "Hounds", "Jackals",
            "Knives", "Raiders", "Ravens", "Reavers", "Wolves",
        },
        site = { "Den", "Hideout", "Hold", "Lair" },
        article = true,
    },
    trader = {
        first = {
            "Bluegrass", "Bridgeway", "Crossroads", "Frontier",
            "Iron Road", "Long Haul", "Northstar", "Riverside",
            "Safe Passage", "Three Rivers", "Westbound",
        },
        second = {
            "Caravan", "Exchange Caravan", "Mercantile Caravan",
            "Supply Caravan", "Trading Caravan",
        },
        site = { "Depot", "Exchange", "Market", "Waystation" },
    },
    refugee = {
        first = {
            "Dawn", "Eastbound", "Hope", "Lantern", "New Day",
            "Northbound", "Open Road", "Safe Harbor", "Westward",
        },
        second = {
            "Caravan", "Collective", "Refugees", "Sanctuary",
            "Survivors",
        },
        site = { "Camp", "Refuge", "Sanctuary", "Shelter" },
    },
}

Profiles.DEFAULT = {
    id = "core.default.v1",
    communitySize = { minimum = 4, maximum = 7 },
    groupSize = { minimum = 2, maximum = 4 },
    communityFactionWeights = {
        settler = 0.55,
        trader = 0.18,
        refugee = 0.17,
        looter = 0.10,
    },
    groupTypeWeights = {
        REFUGEE = 0.28,
        LOOTER = 0.20,
        SCAVENGER = 0.30,
        WANDERER = 0.22,
    },
    groupFactionArchetypes = {
        REFUGEE = "refugee",
        LOOTER = "looter",
        SCAVENGER = "refugee",
        WANDERER = "refugee",
    },
}

local function integer(value, minimum, maximum, fallback)
    local number = math.floor(tonumber(value) or fallback)
    return math.max(minimum, math.min(maximum, number))
end

local function normalizeRange(value, default)
    value = type(value) == "table" and value or {}
    local minimum = integer(
        value.minimum or value.min,
        1,
        128,
        default.minimum
    )
    local maximum = integer(
        value.maximum or value.max,
        minimum,
        128,
        default.maximum
    )
    if maximum < minimum then maximum = minimum end
    return { minimum = minimum, maximum = maximum }
end

local function normalizeWeights(value, fallback)
    local source = type(value) == "table" and value or fallback
    local output = {}
    local hasWeight = false
    for key, weight in pairs(source) do
        weight = math.max(0, tonumber(weight) or 0)
        if weight > 0 then
            output[tostring(key)] = weight
            hasWeight = true
        end
    end
    if not hasWeight then
        for key, weight in pairs(fallback) do
            output[key] = weight
        end
    end
    return output
end

function Profiles.Normalize(value)
    value = type(value) == "table" and value or {}
    local output = I.Copy(Profiles.DEFAULT)
    output.id = tostring(value.id or output.id)
    if #output.id > Generation.MAX_PROFILE_NAME then
        output.id = string.sub(output.id, 1, Generation.MAX_PROFILE_NAME)
    end
    output.communitySize = normalizeRange(
        value.communitySize,
        Profiles.DEFAULT.communitySize
    )
    output.groupSize = normalizeRange(
        value.groupSize,
        Profiles.DEFAULT.groupSize
    )
    output.communityFactionWeights = normalizeWeights(
        value.communityFactionWeights,
        Profiles.DEFAULT.communityFactionWeights
    )
    output.groupTypeWeights = normalizeWeights(
        value.groupTypeWeights,
        Profiles.DEFAULT.groupTypeWeights
    )
    output.groupFactionArchetypes = {}
    local mappings = type(value.groupFactionArchetypes) == "table"
        and value.groupFactionArchetypes
        or Profiles.DEFAULT.groupFactionArchetypes
    for key, archetype in pairs(mappings) do
        output.groupFactionArchetypes[tostring(key)] =
            tostring(archetype)
    end
    return output
end

local function poolFor(archetypeID)
    return NAME_POOLS[tostring(archetypeID or "")]
        or NAME_POOLS.settler
end

local function pick(values, seed, salt)
    local index = (
        Generation.SeedText(
            tostring(seed) .. ":" .. tostring(salt)
        ) % #values
    ) + 1
    return values[index]
end

local function stripArticle(value)
    value = tostring(value or "")
    if string.sub(value, 1, 4) == "The " then
        return string.sub(value, 5)
    end
    return value
end

function Profiles.FactionName(archetypeID, seed)
    local pool = poolFor(archetypeID)
    local first = pick(pool.first, seed, "first")
    local second = pick(pool.second, seed, "second")
    local name = first .. " " .. second
    if pool.article == true then name = "The " .. name end
    return name
end

function Profiles.CommunityName(archetypeID, factionName, seed)
    local pool = poolFor(archetypeID)
    local base = stripArticle(factionName)
    local suffix = pick(pool.site, seed, "site")
    if string.lower(string.sub(base, -#suffix))
        == string.lower(suffix)
    then
        for index = 1, #pool.site do
            if string.lower(pool.site[index])
                ~= string.lower(suffix)
            then
                suffix = pool.site[index]
                break
            end
        end
    end
    return base .. " " .. suffix
end

Generation.Profiles = Profiles

return Profiles
