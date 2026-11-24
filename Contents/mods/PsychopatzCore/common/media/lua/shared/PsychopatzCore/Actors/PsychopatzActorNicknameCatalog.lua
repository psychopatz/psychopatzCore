-- Logic-only gender-aware first-name & authored-nickname catalog for PsychopatzCore.
-- Data definitions live in PsychopatzCore/Actors/Definitions/{Male,Female}FirstNames.lua
-- where bare strings have no nicknames and keyed tables map Forename = { "Nick1", ... }.

local RAW_MALE = require "PsychopatzCore/Actors/Definitions/MaleFirstNames"
local RAW_FEMALE = require "PsychopatzCore/Actors/Definitions/FemaleFirstNames"

local Catalog = {}

local function normalizeKey(value)
    if value == nil then return nil end
    local text = string.gsub(tostring(value), "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    text = string.lower(text)
    return text ~= "" and text or nil
end

local function cleanText(value)
    if value == nil then return nil end
    local text = string.gsub(tostring(value), "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    text = string.gsub(text, "%s+", " ")
    return text ~= "" and text or nil
end

local function cleanAliasList(aliases)
    if type(aliases) ~= "table" then return nil end
    local list = {}
    local seen = {}
    for _, raw in ipairs(aliases) do
        local alias = cleanText(raw)
        if alias then
            local lower = string.lower(alias)
            if not seen[lower] then
                seen[lower] = true
                list[#list + 1] = alias
            end
        end
    end
    return #list > 0 and list or nil
end

local function parseFirstNameDefinitions(raw)
    local namesByLower = {}
    local aliases = {}
    if type(raw) == "table" then
        for k, v in pairs(raw) do
            if type(k) == "number" and type(v) == "string" then
                local name = cleanText(v)
                if name then
                    local lower = string.lower(name)
                    if not namesByLower[lower] then
                        namesByLower[lower] = name
                    end
                end
            elseif type(k) == "string" and type(v) == "table" then
                local name = cleanText(k)
                if name then
                    local lower = string.lower(name)
                    namesByLower[lower] = name
                    local cleaned = cleanAliasList(v)
                    if cleaned then
                        aliases[lower] = cleaned
                    end
                end
            end
        end
    end
    local names = {}
    for _, name in pairs(namesByLower) do
        names[#names + 1] = name
    end
    table.sort(names, function(a, b)
        local la, lb = string.lower(a), string.lower(b)
        if la ~= lb then return la < lb end
        return a < b
    end)
    return names, aliases
end

local MALE_NAMES, MALE_ALIASES = parseFirstNameDefinitions(RAW_MALE)
local FEMALE_NAMES, FEMALE_ALIASES = parseFirstNameDefinitions(RAW_FEMALE)

local function normalizeGender(genderOrIsFemale)
    if type(genderOrIsFemale) == "boolean" then
        return genderOrIsFemale and "female" or "male"
    end
    if type(genderOrIsFemale) == "string" then
        local g = string.lower(string.gsub(genderOrIsFemale, "%s+", ""))
        if g == "female" or g == "f" then return "female" end
        if g == "male" or g == "m" then return "male" end
    end
    return nil
end

local function mergeLists(first, second)
    local out = {}
    local seen = {}
    for _, list in ipairs({ first, second }) do
        if type(list) == "table" then
            for _, alias in ipairs(list) do
                local lower = string.lower(alias)
                if not seen[lower] then
                    seen[lower] = true
                    out[#out + 1] = alias
                end
            end
        end
    end
    return #out > 0 and out or nil
end

function Catalog.GetFirstNames(genderOrIsFemale)
    local gender = normalizeGender(genderOrIsFemale)
    if gender == "female" then return FEMALE_NAMES end
    return MALE_NAMES
end

function Catalog.Get(forename, genderOrIsFemale)
    local key = normalizeKey(forename)
    if not key then return nil end
    local gender = normalizeGender(genderOrIsFemale)
    if gender == "male" then
        return MALE_ALIASES[key]
    end
    if gender == "female" then
        return FEMALE_ALIASES[key]
    end
    local male = MALE_ALIASES[key]
    local female = FEMALE_ALIASES[key]
    if male and not female then return male end
    if female and not male then return female end
    if male and female then return mergeLists(male, female) end
    return nil
end

function Catalog.Has(forename, genderOrIsFemale)
    local list = Catalog.Get(forename, genderOrIsFemale)
    return type(list) == "table" and #list > 0
end

function Catalog.Register(forename, aliases, genderOrIsFemale)
    local key = normalizeKey(forename)
    if not key then return false end
    local list = cleanAliasList(aliases)
    if not list then return false end
    local gender = normalizeGender(genderOrIsFemale)
    if gender == "male" then
        MALE_ALIASES[key] = list
    elseif gender == "female" then
        FEMALE_ALIASES[key] = list
    else
        MALE_ALIASES[key] = list
        FEMALE_ALIASES[key] = list
    end
    return true
end

function Catalog.RegisterBatch(map, genderOrIsFemale)
    if type(map) ~= "table" then return 0 end
    local count = 0
    for forename, aliases in pairs(map) do
        if Catalog.Register(forename, aliases, genderOrIsFemale) then
            count = count + 1
        end
    end
    return count
end

return Catalog
