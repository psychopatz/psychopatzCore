PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Semantics = PsychopatzCore.Semantics
local Normalizer = Semantics.Normalizer
    or require "PsychopatzCore/Semantics/PsychopatzSemanticNormalizer"
local PatternMatcher = Semantics.PatternMatcher or {}
Semantics.PatternMatcher = PatternMatcher

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

local function normalizeRule(rule)
    if type(rule) == "string" then
        if string.sub(rule, 1, 1) == "@" then
            return { kind = "concept", id = string.sub(rule, 2) }
        end
        return {
            kind = "literal",
            value = Normalizer.NormalizePhrase(rule),
        }
    end
    if type(rule) ~= "table" then return nil end

    local output = copyValue(rule)
    if not output.kind then
        if output.concept or output.id then
            output.kind = "concept"
            output.id = output.concept or output.id
        elseif output.literal or output.value then
            output.kind = "literal"
            output.value = output.literal or output.value
        elseif output.any_concept then
            output.kind = "any_concept"
        elseif output.any then
            output.kind = "any"
        end
    end
    if output.kind == "literal" then
        output.value = Normalizer.NormalizePhrase(output.value)
    end
    return output
end

local function matchesRule(rule, symbol)
    if not rule or not symbol then return false end
    if rule.kind == "any" then return true end
    if rule.kind == "any_concept" then return symbol.kind == "concept" end
    if rule.kind == "concept" then
        return symbol.kind == "concept"
            and symbol.id ~= nil
            and tostring(symbol.id) == tostring(rule.id)
    end
    if rule.kind == "literal" then
        return symbol.text == rule.value
    end
    return false
end

local function captureValue(symbol)
    local unresolved = symbol.kind ~= "concept" or symbol.id == nil
    local output = {
        kind = symbol.kind,
        id = symbol.id,
        concept = symbol.id,
        category = symbol.id,
        value = symbol.value or symbol.text,
        text = symbol.text,
        unresolved = unresolved,
    }
    if type(symbol.candidates) == "table" then
        output.candidates = copyValue(symbol.candidates)
    end

    local lowered = string.lower(tostring(output.value or ""))
    if lowered == "this" or lowered == "that"
        or lowered == "it" or lowered == "him" or lowered == "her"
        or lowered == "them"
    then
        output.reference = string.upper(lowered)
    end
    return output
end

local function cloneCaptures(captures)
    local output = {}
    local key
    local value
    for key, value in pairs(captures) do output[key] = copyValue(value) end
    return output
end

function PatternMatcher.Match(pattern, symbols, normalized)
    local rules = pattern.match or {}

    local function search(ruleIndex, symbolIndex, captures, consumed,
        skipped, unresolved, ambiguous, fuzzy)
        if ruleIndex > #rules then
            local remaining = #symbols - symbolIndex + 1
            if remaining > 0 and pattern.allowUnmatched ~= true then
                return nil
            end
            return {
                captures = captures,
                consumed = consumed,
                skipped = skipped,
                unresolvedCount = unresolved,
                ambiguousCount = ambiguous,
                fuzzyCount = fuzzy,
                unmatchedCount = math.max(0, remaining),
                fullCoverage = remaining == 0,
                truncated = normalized.truncated == true,
            }
        end

        local rule = normalizeRule(rules[ruleIndex])
        if not rule then return nil end

        -- Consume first so optional words are retained when they actually
        -- match. Backtracking handles optional grammar without hardcoding
        -- sentence-specific branches in the parser.
        if symbolIndex <= #symbols
            and matchesRule(rule, symbols[symbolIndex])
        then
            local nextCaptures = cloneCaptures(captures)
            if rule.capture then
                nextCaptures[rule.capture] = captureValue(symbols[symbolIndex])
            end
            local nextUnresolved = unresolved
            if rule.capture and (symbols[symbolIndex].kind ~= "concept"
                or symbols[symbolIndex].id == nil)
            then
                nextUnresolved = nextUnresolved + 1
            end
            local nextAmbiguous = ambiguous
            if symbols[symbolIndex].kind == "concept"
                and (not symbols[symbolIndex].id)
            then
                nextAmbiguous = nextAmbiguous + 1
            end
            local nextFuzzy = fuzzy
            if symbols[symbolIndex].fuzzy == true then
                nextFuzzy = nextFuzzy + 1
            end
            local result = search(
                ruleIndex + 1,
                symbolIndex + 1,
                nextCaptures,
                consumed + 1,
                skipped,
                nextUnresolved,
                nextAmbiguous,
                nextFuzzy
            )
            if result then return result end
        end

        if rule.optional == true then
            return search(
                ruleIndex + 1,
                symbolIndex,
                cloneCaptures(captures),
                consumed,
                skipped + 1,
                unresolved,
                ambiguous,
                fuzzy
            )
        end
        return nil
    end

    return search(1, 1, {}, 0, 0, 0, 0, 0)
end

local function resolveReference(value, captures)
    if type(value) ~= "string"
        or string.sub(value, 1, 9) ~= "$capture."
    then
        return value
    end

    local current = captures
    local path = string.sub(value, 10)
    local part
    for part in string.gmatch(path, "[^%.]+") do
        if type(current) ~= "table" then return nil end
        current = current[part]
    end
    return copyValue(current)
end

function PatternMatcher.ResolveEmit(value, captures)
    if type(value) == "string" then return resolveReference(value, captures) end
    if type(value) ~= "table" then return value end

    local output = {}
    local key
    local item
    for key, item in pairs(value) do
        output[key] = PatternMatcher.ResolveEmit(item, captures)
    end
    return output
end

return PatternMatcher
