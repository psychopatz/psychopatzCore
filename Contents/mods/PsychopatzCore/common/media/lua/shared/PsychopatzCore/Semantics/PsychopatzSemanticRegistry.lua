PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Semantics = PsychopatzCore.Semantics
local Normalizer = Semantics.Normalizer
    or require "PsychopatzCore/Semantics/PsychopatzSemanticNormalizer"
local Registry = Semantics.Registry or {}
Semantics.Registry = Registry

Registry.VERSION = 1
Registry.Concepts = Registry.Concepts or {}
Registry.Aliases = Registry.Aliases or {}
Registry.SpeechActs = Registry.SpeechActs or {}
Registry.Patterns = Registry.Patterns or {}
Registry.PatternOrder = Registry.PatternOrder or {}
Registry.OrderedPatterns = Registry.OrderedPatterns or {}
Registry.Revision = tonumber(Registry.Revision) or 0
Registry.MaxPhraseTokens = tonumber(Registry.MaxPhraseTokens) or 1

local function copyValue(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 12 then return nil end
    local output = {}
    local key
    local item
    for key, item in pairs(value) do
        output[key] = copyValue(item, depth + 1)
    end
    return output
end

local function bumpRevision()
    Registry.Revision = Registry.Revision + 1
end

local function removeAlias(alias, conceptID)
    local entries = Registry.Aliases[alias]
    if type(entries) ~= "table" then return end

    local retained = {}
    local index
    local entry
    for index = 1, #entries do
        entry = entries[index]
        if entry.id ~= conceptID then retained[#retained + 1] = entry end
    end

    if #retained == 0 then
        Registry.Aliases[alias] = nil
    else
        Registry.Aliases[alias] = retained
    end
end

local function aliasesFrom(definition)
    local source = definition.aliases or definition.phrases
    if type(source) == "string" then return { source } end
    if type(source) ~= "table" then return {} end

    local output = {}
    local seen = {}
    local index
    local phrase
    for index = 1, #source do
        phrase = Normalizer.NormalizePhrase(source[index])
        if phrase ~= "" and not seen[phrase] then
            seen[phrase] = true
            output[#output + 1] = phrase
        end
    end
    if #output > 0 then return output end

    -- Also accept a keyed vocabulary table for callers that organize aliases
    -- by a human-readable label instead of an array.
    for _, phraseValue in pairs(source) do
        phrase = Normalizer.NormalizePhrase(phraseValue)
        if phrase ~= "" and not seen[phrase] then
            seen[phrase] = true
            output[#output + 1] = phrase
        end
    end
    table.sort(output)
    return output
end

local function addAlias(alias, definition)
    local entries = Registry.Aliases[alias] or {}
    entries[#entries + 1] = {
        id = definition.id,
        priority = definition.priority,
    }
    Registry.Aliases[alias] = entries
    local tokenCount = 0
    for _ in string.gmatch(alias, "%S+") do tokenCount = tokenCount + 1 end
    if tokenCount > Registry.MaxPhraseTokens then
        Registry.MaxPhraseTokens = tokenCount
    end
end

function Registry.RegisterConcept(definition)
    if type(definition) ~= "table"
        or type(definition.id) ~= "string"
        or definition.id == ""
    then
        return false, "invalid_concept"
    end

    local aliases = aliasesFrom(definition)
    if #aliases == 0 then return false, "concept_requires_aliases" end

    local existing = Registry.Concepts[definition.id]
    local oldAlias
    if existing then
        for _, oldAlias in ipairs(existing.aliases) do
            removeAlias(oldAlias, definition.id)
        end
    end

    local normalized = {
        id = definition.id,
        aliases = aliases,
        priority = tonumber(definition.priority) or 0,
        kind = definition.kind or "concept",
        owner = definition.owner,
        metadata = copyValue(definition.metadata) or {},
    }
    Registry.Concepts[normalized.id] = normalized
    local alias
    for _, alias in ipairs(aliases) do addAlias(alias, normalized) end
    bumpRevision()
    return true, normalized
end

function Registry.GetConcept(id)
    return Registry.Concepts[id]
end

function Registry.GetAliasMatches(phrase)
    phrase = Normalizer.NormalizePhrase(phrase)
    local entries = Registry.Aliases[phrase] or {}
    local output = {}
    local index
    local entry
    for index = 1, #entries do
        entry = entries[index]
        output[index] = {
            id = entry.id,
            priority = entry.priority,
        }
    end
    return output
end

-- Internal hot-path lookup for already-normalized phrases. Callers should not
-- mutate the returned entries.
function Registry.LookupAlias(phrase)
    return Registry.Aliases[phrase] or {}
end

function Registry.GetMaxPhraseTokens()
    return Registry.MaxPhraseTokens
end

function Registry.RegisterSpeechAct(definition, metadata)
    if type(definition) == "string" then
        definition = { id = definition, metadata = metadata }
    end
    if type(definition) ~= "table"
        or type(definition.id) ~= "string"
        or definition.id == ""
    then
        return false, "invalid_speech_act"
    end

    local normalized = {
        id = definition.id,
        owner = definition.owner,
        metadata = copyValue(definition.metadata) or {},
    }
    Registry.SpeechActs[normalized.id] = normalized
    bumpRevision()
    return true, normalized
end

function Registry.GetSpeechAct(id)
    return Registry.SpeechActs[id]
end

function Registry.ListSpeechActs()
    local output = {}
    local id
    for id in pairs(Registry.SpeechActs) do output[#output + 1] = id end
    table.sort(output)
    return output
end

local function refreshOrderedPatterns()
    Registry.OrderedPatterns = {}
    local index
    local id
    for index = 1, #Registry.PatternOrder do
        id = Registry.PatternOrder[index]
        if Registry.Patterns[id] then
            Registry.OrderedPatterns[#Registry.OrderedPatterns + 1] =
                Registry.Patterns[id]
        end
    end
end

function Registry.RegisterPattern(definition)
    if type(definition) ~= "table"
        or type(definition.id) ~= "string"
        or definition.id == ""
        or type(definition.match) ~= "table"
    then
        return false, "invalid_pattern"
    end

    local pattern = copyValue(definition)
    pattern.priority = tonumber(pattern.priority) or 0
    pattern.confidence = tonumber(pattern.confidence) or 0.70
    Registry.Patterns[pattern.id] = pattern

    local found = false
    local index
    for index = 1, #Registry.PatternOrder do
        if Registry.PatternOrder[index] == pattern.id then
            found = true
            break
        end
    end
    if not found then Registry.PatternOrder[#Registry.PatternOrder + 1] = pattern.id end

    table.sort(Registry.PatternOrder, function(left, right)
        local leftPattern = Registry.Patterns[left]
        local rightPattern = Registry.Patterns[right]
        local leftPriority = leftPattern and leftPattern.priority or 0
        local rightPriority = rightPattern and rightPattern.priority or 0
        if leftPriority ~= rightPriority then return leftPriority > rightPriority end
        return tostring(left) < tostring(right)
    end)
    refreshOrderedPatterns()
    bumpRevision()
    return true, pattern
end

function Registry.GetPatterns()
    return Registry.OrderedPatterns
end

function Registry.ListConcepts()
    local output = {}
    local id
    for id in pairs(Registry.Concepts) do output[#output + 1] = id end
    table.sort(output)
    return output
end

function Registry.GetRevision()
    return Registry.Revision
end

function Registry.Reset()
    Registry.Concepts = {}
    Registry.Aliases = {}
    Registry.SpeechActs = {}
    Registry.Patterns = {}
    Registry.PatternOrder = {}
    Registry.OrderedPatterns = {}
    Registry.MaxPhraseTokens = 1
    bumpRevision()
end

refreshOrderedPatterns()

return Registry
