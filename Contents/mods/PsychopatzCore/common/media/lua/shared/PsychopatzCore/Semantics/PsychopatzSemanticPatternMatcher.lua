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
        elseif output.any_phrase or output.span then
            output.kind = "any_phrase"
        elseif output.any then
            output.kind = "any"
        end
    end
    if output.kind == "literal" then
        output.value = Normalizer.NormalizePhrase(output.value)
    end
    if output.kind == "any_phrase" then
        -- Phrase captures are deliberately bounded.  They are intended for
        -- game-world names ("recycle bin", "medical supplies"), not for
        -- arbitrary-English parsing or unbounded backtracking.
        output.minTokens = math.max(1, math.floor(
            tonumber(output.minTokens) or 1))
        output.maxTokens = math.max(output.minTokens, math.min(8, math.floor(
            tonumber(output.maxTokens) or 4)))
        if type(output.stopWords) == "string" then
            output.stopWords = { output.stopWords }
        end
        if type(output.stopWords) == "table" then
            local normalized = {}
            for index = 1, #output.stopWords do
                normalized[#normalized + 1] = Normalizer.NormalizePhrase(
                    output.stopWords[index])
            end
            output.stopWords = normalized
        end
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

local function symbolText(symbol)
    return tostring(symbol and (symbol.text or symbol.value) or "")
end

local function phraseText(symbols, first, last)
    local values = {}
    local index
    for index = first, last do
        values[#values + 1] = symbolText(symbols[index])
    end
    return table.concat(values, " ")
end

local function hasStopWord(symbols, first, last, stopWords)
    if type(stopWords) ~= "table" or #stopWords < 1 then return false end
    local index
    local stopIndex
    local text
    for index = first, last do
        text = " " .. symbolText(symbols[index]) .. " "
        for stopIndex = 1, #stopWords do
            local stop = tostring(stopWords[stopIndex] or "")
            if stop ~= "" and string.find(
                text, " " .. stop .. " ", 1, true)
            then
                return true
            end
        end
    end
    return false
end

local function capturePhraseValue(symbols, first, last)
    -- Preserve the richer concept capture when a phrase is exactly one known
    -- concept.  This keeps existing emit contracts stable while allowing an
    -- unresolved multi-word world/item name to travel as one value.
    if first == last and symbols[first].kind == "concept"
        and symbols[first].id ~= nil
    then
        local output = captureValue(symbols[first])
        output.startToken = symbols[first].startToken
        output.endToken = symbols[first].endToken
        output.tokens = { symbolText(symbols[first]) }
        return output
    end

    local output = {
        kind = "phrase",
        value = phraseText(symbols, first, last),
        text = phraseText(symbols, first, last),
        unresolved = true,
        startToken = symbols[first] and symbols[first].startToken or nil,
        endToken = symbols[last] and symbols[last].endToken or nil,
        tokens = {},
    }
    local index
    for index = first, last do
        output.tokens[#output.tokens + 1] = symbolText(symbols[index])
    end
    local lowered = string.lower(output.text)
    if lowered == "this" or lowered == "that"
        or lowered == "it" or lowered == "him" or lowered == "her"
        or lowered == "them"
    then
        output.reference = string.upper(lowered)
    end
    return output
end

local function spanMetrics(symbols, first, last)
    local unresolved = first ~= last and 1 or 0
    local ambiguous = 0
    local fuzzy = 0
    local index
    local symbol
    for index = first, last do
        symbol = symbols[index]
        if symbol.kind ~= "concept" or symbol.id == nil then
            -- A captured phrase is one unresolved semantic slot even when
            -- its display name contains several literal tokens.
            unresolved = 1
        end
        if symbol.kind == "concept" and not symbol.id then
            ambiguous = ambiguous + 1
        end
        if symbol.fuzzy == true then fuzzy = fuzzy + 1 end
    end
    return unresolved, ambiguous, fuzzy
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

        if rule.kind == "any_phrase" then
            local first = symbolIndex
            local last
            local firstToken = symbols[first]
                and symbols[first].startToken or nil
            local spanFirst
            local spanLast
            -- Try longer spans first so names such as "medical supplies"
            -- remain intact.  Recursive backtracking still permits a later
            -- grammar rule to consume a terminator such as "to" or "yet".
            for last = #symbols, first, -1 do
                local endToken = symbols[last]
                    and symbols[last].endToken or nil
                local tokenCount = endToken and firstToken
                    and endToken - firstToken + 1 or 0
                if tokenCount < rule.minTokens then break end
                if tokenCount <= rule.maxTokens
                    and not hasStopWord(
                        symbols, first, last, rule.stopWords)
                then
                    spanFirst = first
                    spanLast = last
                    local nextCaptures = cloneCaptures(captures)
                    if rule.capture then
                        nextCaptures[rule.capture] = capturePhraseValue(
                            symbols, spanFirst, spanLast)
                    end
                    local spanUnresolved, spanAmbiguous, spanFuzzy =
                        spanMetrics(symbols, spanFirst, spanLast)
                    local result = search(
                        ruleIndex + 1,
                        last + 1,
                        nextCaptures,
                        consumed + (last - first + 1),
                        skipped,
                        unresolved + spanUnresolved,
                        ambiguous + spanAmbiguous,
                        fuzzy + spanFuzzy
                    )
                    if result then return result end
                end
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
