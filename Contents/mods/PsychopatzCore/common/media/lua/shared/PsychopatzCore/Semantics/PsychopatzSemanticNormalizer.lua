PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Semantics = PsychopatzCore.Semantics
local Normalizer = Semantics.Normalizer or {}
Semantics.Normalizer = Normalizer

local EnglishNLP = Semantics.EnglishNLP
    or require "PsychopatzCore/Semantics/PsychopatzSemanticEnglishNLP"
local EnglishGrammar = Semantics.EnglishGrammar
    or require "PsychopatzCore/Semantics/PsychopatzSemanticEnglishGrammar"

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
    local rawText = tostring(value or "")
    local normalized, lengthTruncated = Normalizer.NormalizeText(rawText, options)
    local rawTokens, tokenTruncated = Normalizer.Tokenize(normalized, options)
    local lang = options.language or "EN"

    local tokens = rawTokens
    local expandedShorthand = false
    local collapsedElongation = false
    if options.expandShorthand ~= false and EnglishNLP and type(EnglishNLP.ExpandTokens) == "function" then
        tokens, expandedShorthand, collapsedElongation = EnglishNLP.ExpandTokens(rawTokens, lang)
        if expandedShorthand or collapsedElongation then
            normalized = table.concat(tokens, " ")
        end
    end

    local lemmas = (EnglishNLP and type(EnglishNLP.LemmatizeTokens) == "function")
        and EnglishNLP.LemmatizeTokens(tokens, lang) or tokens
    local cleanTokens = (EnglishNLP and type(EnglishNLP.StripFillers) == "function")
        and EnglishNLP.StripFillers(tokens, lang) or tokens
    local playerTone, isQuestion, isExclamation, toneFlags = "neutral", false, false, nil
    if EnglishNLP and type(EnglishNLP.DetectTone) == "function" then
        playerTone, isQuestion, isExclamation, toneFlags = EnglishNLP.DetectTone(rawText, tokens, lang)
    end
    toneFlags = type(toneFlags) == "table" and toneFlags or {}
    local dialogueAct = (EnglishNLP and type(EnglishNLP.ClassifyDialogueAct) == "function")
        and EnglishNLP.ClassifyDialogueAct(cleanTokens, rawText, lang) or nil
    local quantity = (EnglishNLP and type(EnglishNLP.ExtractQuantity) == "function")
        and EnglishNLP.ExtractQuantity(tokens, lang) or nil
    local grammar = (EnglishGrammar and type(EnglishGrammar.AnalyzeTokens) == "function")
        and EnglishGrammar.AnalyzeTokens(tokens) or nil

    return {
        rawText = rawText,
        normalizedText = normalized,
        tokens = tokens,
        lemmas = lemmas,
        cleanTokens = cleanTokens,
        grammar = grammar,
        playerTone = playerTone,
        playerRude = toneFlags.isRude == true,
        playerShouting = toneFlags.isShouting == true,
        playerPolite = toneFlags.isPolite == true,
        playerSkeptical = toneFlags.isSkeptical == true,
        dialogueAct = dialogueAct,
        quantity = quantity,
        isQuestion = isQuestion,
        isExclamation = isExclamation,
        expandedShorthand = expandedShorthand,
        collapsedElongation = collapsedElongation,
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
