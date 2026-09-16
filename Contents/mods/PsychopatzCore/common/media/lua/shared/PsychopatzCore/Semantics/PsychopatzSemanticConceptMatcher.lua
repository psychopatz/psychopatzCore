PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Semantics = PsychopatzCore.Semantics
local Registry = Semantics.Registry
    or require "PsychopatzCore/Semantics/PsychopatzSemanticRegistry"
local FuzzyMatcher = Semantics.FuzzyMatcher
    or require "PsychopatzCore/Semantics/PsychopatzSemanticFuzzyMatcher"
local Matcher = Semantics.ConceptMatcher or {}
Semantics.ConceptMatcher = Matcher

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

local function phrase(tokens, first, last)
    local values = {}
    local index
    for index = first, last do values[#values + 1] = tokens[index] end
    return table.concat(values, " ")
end

local function bestConcept(matches)
    local highestPriority = nil
    local candidateIDs = {}
    local seen = {}
    local index
    local entry
    for index = 1, #matches do
        entry = matches[index]
        if highestPriority == nil or entry.priority > highestPriority then
            highestPriority = entry.priority
            candidateIDs = { entry.id }
            seen = { [entry.id] = true }
        elseif entry.priority == highestPriority and not seen[entry.id] then
            candidateIDs[#candidateIDs + 1] = entry.id
            seen[entry.id] = true
        end
    end
    return #candidateIDs == 1 and candidateIDs[1] or nil, candidateIDs
end

local function bestFuzzyConcept(matches)
    local highestPriority = nil
    local candidateIDs = {}
    local seen = {}
    local index
    local entry
    for index = 1, #matches do
        entry = matches[index]
        if highestPriority == nil or entry.priority > highestPriority then
            highestPriority = entry.priority
            candidateIDs = { entry.id }
            seen = { [entry.id] = true }
        elseif entry.priority == highestPriority and not seen[entry.id] then
            candidateIDs[#candidateIDs + 1] = entry.id
            seen[entry.id] = true
        end
    end
    return #candidateIDs == 1 and candidateIDs[1] or nil, candidateIDs
end

function Matcher.Build(normalized, options)
    local tokens = normalized.tokens or {}
    local symbols = {}
    local maxPhraseTokens = math.max(1, Registry.GetMaxPhraseTokens())
    local fuzzyEnabled = not (
        type(options) == "table" and options.enableFuzzy == false
    )
    local tokenIndex = 1

    while tokenIndex <= #tokens do
        local selected
        local length
        for length = maxPhraseTokens, 1, -1 do
            local last = tokenIndex + length - 1
            if last <= #tokens then
                local candidatePhrase = phrase(tokens, tokenIndex, last)
                local matches = Registry.LookupAlias(candidatePhrase)
                if #matches > 0 then
                    local id
                    local candidates
                    id, candidates = bestConcept(matches)
                    selected = {
                        kind = "concept",
                        id = id,
                        candidates = candidates,
                        text = candidatePhrase,
                        matchedAlias = candidatePhrase,
                        matchType = "exact",
                        fuzzy = false,
                        editDistance = 0,
                        startToken = tokenIndex,
                        endToken = last,
                    }
                    break
                end

                local fuzzy = fuzzyEnabled
                    and FuzzyMatcher.Find(candidatePhrase, options) or nil
                if fuzzy and #fuzzy.matches > 0 then
                    local id
                    local candidates
                    id, candidates = bestFuzzyConcept(fuzzy.matches)
                    selected = {
                        kind = "concept",
                        id = id,
                        candidates = candidates,
                        text = candidatePhrase,
                        matchedAlias = fuzzy.matches[1].alias,
                        matchType = "fuzzy",
                        fuzzy = true,
                        editDistance = fuzzy.distance,
                        fuzzyScanTruncated = fuzzy.truncated,
                        startToken = tokenIndex,
                        endToken = last,
                    }
                    break
                end
            end
        end

        if selected then
            symbols[#symbols + 1] = selected
            tokenIndex = selected.endToken + 1
        else
            symbols[#symbols + 1] = {
                kind = "literal",
                value = tokens[tokenIndex],
                text = tokens[tokenIndex],
                matchType = "literal",
                fuzzy = false,
                startToken = tokenIndex,
                endToken = tokenIndex,
            }
            tokenIndex = tokenIndex + 1
        end
    end
    return symbols
end

function Matcher.Analysis(normalized, symbols)
    local compact = {}
    local ambiguous = {}
    local fuzzyMatches = {}
    local index
    local symbol
    for index = 1, #symbols do
        symbol = symbols[index]
        compact[index] = {
            kind = symbol.kind,
            id = symbol.id,
            value = symbol.value,
            text = symbol.text,
            candidates = copyValue(symbol.candidates),
            matchedAlias = symbol.matchedAlias,
            matchType = symbol.matchType,
            fuzzy = symbol.fuzzy == true,
            editDistance = symbol.editDistance,
            startToken = symbol.startToken,
            endToken = symbol.endToken,
        }
        if symbol.kind == "concept" and not symbol.id then
            ambiguous[#ambiguous + 1] = {
                text = symbol.text,
                candidates = copyValue(symbol.candidates),
            }
        end
        if symbol.fuzzy == true then
            fuzzyMatches[#fuzzyMatches + 1] = {
                text = symbol.text,
                matchedAlias = symbol.matchedAlias,
                editDistance = symbol.editDistance,
                candidates = copyValue(symbol.candidates),
            }
        end
    end
    return {
        tokens = copyValue(normalized.tokens),
        symbols = compact,
        ambiguousConcepts = ambiguous,
        fuzzyMatch = #fuzzyMatches > 0,
        fuzzyMatches = fuzzyMatches,
        truncated = normalized.truncated == true,
    }
end

return Matcher
