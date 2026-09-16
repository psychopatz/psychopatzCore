PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Semantics = PsychopatzCore.Semantics
local Normalizer = Semantics.Normalizer or {}
Semantics.Normalizer = Normalizer

Normalizer.MAX_INPUT_LENGTH = 4096
Normalizer.MAX_TOKENS = 64

local function trim(value)
    value = string.gsub(value, "^%s+", "")
    return string.gsub(value, "%s+$", "")
end

local function cleanPunctuation(value)
    -- Keep apostrophes inside words (don't) because negation patterns use
    -- them. Other sentence punctuation is only a token boundary.
    value = string.gsub(value, ",", " ")
    value = string.gsub(value, "%.", " ")
    value = string.gsub(value, "!", " ")
    value = string.gsub(value, "?", " ")
    value = string.gsub(value, ";", " ")
    value = string.gsub(value, ":", " ")
    value = string.gsub(value, "%(", " ")
    value = string.gsub(value, "%)", " ")
    value = string.gsub(value, "%[", " ")
    value = string.gsub(value, "%]", " ")
    value = string.gsub(value, "{", " ")
    value = string.gsub(value, "}", " ")
    value = string.gsub(value, "\"", " ")
    return value
end

function Normalizer.NormalizeText(value, options)
    options = type(options) == "table" and options or {}
    value = tostring(value or "")

    local maximum = tonumber(options.maxLength)
        or Normalizer.MAX_INPUT_LENGTH
    local truncated = #value > maximum
    if truncated then value = string.sub(value, 1, maximum) end

    value = string.lower(value)
    value = string.gsub(value, "[%c]", " ")
    value = cleanPunctuation(value)
    value = string.gsub(value, "%s+", " ")
    return trim(value), truncated
end

function Normalizer.Tokenize(value, options)
    options = type(options) == "table" and options or {}
    local maximum = tonumber(options.maxTokens) or Normalizer.MAX_TOKENS
    local tokens = {}
    local truncated = false
    local token

    for token in string.gmatch(tostring(value or ""), "%S+") do
        if #tokens >= maximum then
            truncated = true
        else
            tokens[#tokens + 1] = token
        end
    end

    return tokens, truncated
end

function Normalizer.Normalize(value, options)
    options = type(options) == "table" and options or {}
    local normalized, lengthTruncated = Normalizer.NormalizeText(value, options)
    local tokens, tokenTruncated = Normalizer.Tokenize(normalized, options)
    return {
        rawText = tostring(value or ""),
        normalizedText = normalized,
        tokens = tokens,
        truncated = lengthTruncated or tokenTruncated,
    }
end

function Normalizer.NormalizePhrase(value)
    local normalized = Normalizer.NormalizeText(value, {
        maxLength = Normalizer.MAX_INPUT_LENGTH,
    })
    return normalized
end

return Normalizer
