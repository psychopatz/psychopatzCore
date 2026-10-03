PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Semantics = PsychopatzCore.Semantics
local Normalizer = Semantics.Normalizer
    or require "PsychopatzCore/Semantics/PsychopatzSemanticNormalizer"
local Support = require
    "PsychopatzCore/Semantics/PsychopatzSemanticPatternMatcher_Support"
local Rules = {}

function Rules.normalizeRule(rule)
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

    local output = Support.copyValue(rule)
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
        -- Phrase captures are deliberately bounded. They are intended for
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

function Rules.matchesRule(rule, symbol)
    if not rule or not symbol then return false end
    if rule.kind == "any" then
        return symbol.verbForm == nil or rule.allowVerbForms == true
    end
    if rule.kind == "any_concept" then
        return symbol.kind == "concept"
            and (symbol.verbForm == nil or rule.allowVerbForms == true)
    end
    if rule.kind == "concept" then
        if symbol.kind ~= "concept"
            or symbol.id == nil
            or tostring(symbol.id) ~= tostring(rule.id)
        then
            return false
        end

        if type(rule.verbForms) == "table" then
            if not symbol.verbForm then return rule.allowBaseVerb == true end
            local form = string.upper(tostring(symbol.verbForm.form or ""))
            local index
            for index = 1, #rule.verbForms do
                if form == string.upper(tostring(rule.verbForms[index] or "")) then
                    return true
                end
            end
            return false
        end
        return symbol.verbForm == nil
    end
    if rule.kind == "literal" then
        return symbol.text == rule.value
    end
    return false
end

return Rules
