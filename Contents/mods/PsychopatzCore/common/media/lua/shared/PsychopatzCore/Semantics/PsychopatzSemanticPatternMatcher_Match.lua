local Match = {}
local search

local function terminalResult(state, symbolIndex, captures, consumed,
    skipped, unresolved, ambiguous, fuzzy)
    local remaining = #state.symbols - symbolIndex + 1
    if remaining > 0 and state.pattern.allowUnmatched ~= true then
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
        truncated = state.normalized.truncated == true,
    }
end

local function skipOptional(state, ruleIndex, symbolIndex, captures, consumed,
    skipped, unresolved, ambiguous, fuzzy)
    return search(
        state,
        ruleIndex + 1,
        symbolIndex,
        state.Captures.clone(captures),
        consumed,
        skipped + 1,
        unresolved,
        ambiguous,
        fuzzy
    )
end

local function tryPhraseSpan(state, rule, ruleIndex, symbolIndex, captures,
    consumed, skipped, unresolved, ambiguous, fuzzy, last)
    local nextCaptures = state.Captures.clone(captures)
    if rule.capture then
        nextCaptures[rule.capture] = state.Captures.capturePhraseValue(
            state.symbols, symbolIndex, last)
    end
    local spanUnresolved, spanAmbiguous, spanFuzzy = state.Support.spanMetrics(
        state.symbols, symbolIndex, last)
    return search(
        state,
        ruleIndex + 1,
        last + 1,
        nextCaptures,
        consumed + (last - symbolIndex + 1),
        skipped,
        unresolved + spanUnresolved,
        ambiguous + spanAmbiguous,
        fuzzy + spanFuzzy
    )
end

local function matchPhraseRule(state, ruleIndex, rule, symbolIndex, captures,
    consumed, skipped, unresolved, ambiguous, fuzzy)
    local firstToken = state.symbols[symbolIndex]
        and state.symbols[symbolIndex].startToken or nil
    local last
    for last = #state.symbols, symbolIndex, -1 do
        local endToken = state.symbols[last]
            and state.symbols[last].endToken or nil
        local tokenCount = endToken and firstToken
            and endToken - firstToken + 1 or 0
        if tokenCount < rule.minTokens then break end
        if tokenCount <= rule.maxTokens
            and (rule.allowVerbForms == true
                or not state.Support.containsVerbForm(
                    state.symbols, symbolIndex, last))
            and not state.Support.hasStopWord(
                state.symbols, symbolIndex, last, rule.stopWords)
        then
            local result = tryPhraseSpan(
                state,
                rule,
                ruleIndex,
                symbolIndex,
                captures,
                consumed,
                skipped,
                unresolved,
                ambiguous,
                fuzzy,
                last
            )
            if result then return result end
        end
    end
    if rule.optional == true then
        return skipOptional(
            state,
            ruleIndex,
            symbolIndex,
            captures,
            consumed,
            skipped,
            unresolved,
            ambiguous,
            fuzzy
        )
    end
    return nil
end

local function matchRegularRule(state, ruleIndex, rule, symbolIndex, captures,
    consumed, skipped, unresolved, ambiguous, fuzzy)
    -- Consume first so optional words are retained when they actually match.
    -- Backtracking handles optional grammar without hardcoding sentence paths.
    if symbolIndex <= #state.symbols
        and state.Rules.matchesRule(rule, state.symbols[symbolIndex])
    then
        local nextCaptures = state.Captures.clone(captures)
        if rule.capture then
            nextCaptures[rule.capture] = state.Captures.captureValue(
                state.symbols[symbolIndex])
        end
        local nextUnresolved = unresolved
        if rule.capture and (state.symbols[symbolIndex].kind ~= "concept"
            or state.symbols[symbolIndex].id == nil)
        then
            nextUnresolved = nextUnresolved + 1
        end
        local nextAmbiguous = ambiguous
        if state.symbols[symbolIndex].kind == "concept"
            and (not state.symbols[symbolIndex].id)
        then
            nextAmbiguous = nextAmbiguous + 1
        end
        local nextFuzzy = fuzzy
        if state.symbols[symbolIndex].fuzzy == true then
            nextFuzzy = nextFuzzy + 1
        end
        local result = search(
            state,
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
        return skipOptional(
            state,
            ruleIndex,
            symbolIndex,
            captures,
            consumed,
            skipped,
            unresolved,
            ambiguous,
            fuzzy
        )
    end
    return nil
end

search = function(state, ruleIndex, symbolIndex, captures, consumed, skipped,
    unresolved, ambiguous, fuzzy)
    if ruleIndex > #state.rules then
        return terminalResult(
            state,
            symbolIndex,
            captures,
            consumed,
            skipped,
            unresolved,
            ambiguous,
            fuzzy
        )
    end

    local rule = state.Rules.normalizeRule(state.rules[ruleIndex])
    if not rule then return nil end
    if rule.kind == "any_phrase" then
        return matchPhraseRule(
            state,
            ruleIndex,
            rule,
            symbolIndex,
            captures,
            consumed,
            skipped,
            unresolved,
            ambiguous,
            fuzzy
        )
    end
    return matchRegularRule(
        state,
        ruleIndex,
        rule,
        symbolIndex,
        captures,
        consumed,
        skipped,
        unresolved,
        ambiguous,
        fuzzy
    )
end

function Match.Install(PatternMatcher, Rules, Captures, Support)
    function PatternMatcher.Match(pattern, symbols, normalized)
        local state = {
            pattern = pattern,
            rules = pattern.match or {},
            symbols = symbols,
            normalized = normalized,
            Rules = Rules,
            Captures = Captures,
            Support = Support,
        }
        return search(state, 1, 1, {}, 0, 0, 0, 0, 0)
    end
end

return Match
