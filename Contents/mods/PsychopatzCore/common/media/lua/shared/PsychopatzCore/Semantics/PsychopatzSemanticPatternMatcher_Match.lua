local Match = {}
local search

local function terminalResult(state, symbolIndex, captures, consumed,
    skipped, unresolved, ambiguous, fuzzy, secondary)
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
        secondaryCount = secondary,
        unmatchedCount = math.max(0, remaining),
        fullCoverage = remaining == 0,
        truncated = state.normalized.truncated == true,
    }
end

local function skipOptional(state, ruleIndex, symbolIndex, captures, consumed,
    skipped, unresolved, ambiguous, fuzzy, secondary)
    return search(
        state,
        ruleIndex + 1,
        symbolIndex,
        state.Captures.clone(captures),
        consumed,
        skipped + 1,
        unresolved,
        ambiguous,
        fuzzy,
        secondary
    )
end

local function tryPhraseSpan(state, rule, ruleIndex, symbolIndex, captures,
    consumed, skipped, unresolved, ambiguous, fuzzy, secondary, last)
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
        fuzzy + spanFuzzy,
        secondary
    )
end

local function matchPhraseRule(state, ruleIndex, rule, symbolIndex, captures,
    consumed, skipped, unresolved, ambiguous, fuzzy, secondary)
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
                secondary,
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
            fuzzy,
            secondary
        )
    end
    return nil
end

local function matchRegularRule(state, ruleIndex, rule, symbolIndex, captures,
    consumed, skipped, unresolved, ambiguous, fuzzy, secondary)
    -- Consume first so optional words are retained when they actually match.
    -- Backtracking handles optional grammar without hardcoding sentence paths.
    if symbolIndex <= #state.symbols
        and state.Rules.matchesRule(rule, state.symbols[symbolIndex])
    then
        local sym = state.symbols[symbolIndex]
        local nextCaptures = state.Captures.clone(captures)
        if rule.capture then
            nextCaptures[rule.capture] = state.Captures.captureValue(sym)
        end
        local nextUnresolved = unresolved
        if rule.capture and (sym.kind ~= "concept" or sym.id == nil) then
            nextUnresolved = nextUnresolved + 1
        end
        local nextAmbiguous = ambiguous
        if sym.kind == "concept" and (not sym.id) then
            nextAmbiguous = nextAmbiguous + 1
        end
        local nextFuzzy = fuzzy
        if sym.fuzzy == true then
            nextFuzzy = nextFuzzy + 1
        end
        local nextSecondary = secondary
        if rule.kind == "concept"
            and sym.kind == "concept"
            and sym.id ~= nil
            and tostring(sym.id) ~= tostring(rule.id)
        then
            nextSecondary = nextSecondary + 1
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
            nextFuzzy,
            nextSecondary
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
            fuzzy,
            secondary
        )
    end
    return nil
end

search = function(state, ruleIndex, symbolIndex, captures, consumed, skipped,
    unresolved, ambiguous, fuzzy, secondary)
    if ruleIndex > #state.rules then
        return terminalResult(
            state,
            symbolIndex,
            captures,
            consumed,
            skipped,
            unresolved,
            ambiguous,
            fuzzy,
            secondary
        )
    end

    local rule = state.rules[ruleIndex]
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
            fuzzy,
            secondary
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
        fuzzy,
        secondary
    )
end

local function compilePatternRules(pattern, Rules)
    local rawRules = pattern.match or {}
    local compiled = {}
    local minRequired = 0
    local maxSymbols = 0
    local unboundedMax = pattern.allowUnmatched == true
    for i = 1, #rawRules do
        local rule = Rules.normalizeRule(rawRules[i])
        compiled[i] = rule
        if rule then
            if rule.optional ~= true then
                minRequired = minRequired
                    + (rule.kind == "any_phrase" and (rule.minTokens or 1) or 1)
            end
            if not unboundedMax then
                if rule.kind == "any_phrase" then
                    maxSymbols = maxSymbols + (rule.maxTokens or 4)
                else
                    maxSymbols = maxSymbols + 1
                end
            end
        end
    end
    pattern._compiledRules = compiled
    pattern._compiledRuleCount = #rawRules
    pattern._minRequiredSymbols = minRequired
    pattern._maxSymbols = unboundedMax and nil or maxSymbols
    return compiled
end

function Match.Install(PatternMatcher, Rules, Captures, Support)
    function PatternMatcher.Match(pattern, symbols, normalized)
        local rawRules = pattern.match or {}
        local compiled = pattern._compiledRules
        if compiled == nil or pattern._compiledRuleCount ~= #rawRules then
            compiled = compilePatternRules(pattern, Rules)
        end
        local symCount = #symbols
        if symCount < (pattern._minRequiredSymbols or 0) then
            return nil
        end
        if pattern._maxSymbols ~= nil and symCount > pattern._maxSymbols then
            return nil
        end
        local state = {
            pattern = pattern,
            rules = compiled,
            symbols = symbols,
            normalized = normalized,
            Rules = Rules,
            Captures = Captures,
            Support = Support,
        }
        return search(state, 1, 1, {}, 0, 0, 0, 0, 0, 0)
    end
end

return Match
