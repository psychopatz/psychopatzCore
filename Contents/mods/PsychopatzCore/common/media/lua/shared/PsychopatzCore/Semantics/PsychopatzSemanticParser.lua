PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Semantics = PsychopatzCore.Semantics
local IR = Semantics.IR
    or require "PsychopatzCore/Semantics/PsychopatzSemanticIR"
local Normalizer = Semantics.Normalizer
    or require "PsychopatzCore/Semantics/PsychopatzSemanticNormalizer"
local Registry = Semantics.Registry
    or require "PsychopatzCore/Semantics/PsychopatzSemanticRegistry"
local Confidence = Semantics.Confidence
    or require "PsychopatzCore/Semantics/PsychopatzSemanticConfidence"
local ConceptMatcher = Semantics.ConceptMatcher
    or require "PsychopatzCore/Semantics/PsychopatzSemanticConceptMatcher"
local PatternMatcher = Semantics.PatternMatcher
    or require "PsychopatzCore/Semantics/PsychopatzSemanticPatternMatcher"
local Parser = Semantics.Parser or {}
Semantics.Parser = Parser

local function baseDiagnostics(normalized, symbols)
    local diagnostics = {
        parser = "lua_deterministic",
        registryRevision = Registry.GetRevision(),
        noMatch = true,
        ambiguousIntent = false,
        ambiguousConcept = false,
        unresolvedEntity = false,
        fuzzyMatch = false,
        correctedTokens = {},
        unmatchedTokens = {},
    }
    local index
    local symbol
    for index = 1, #symbols do
        symbol = symbols[index]
        diagnostics.unmatchedTokens[#diagnostics.unmatchedTokens + 1] = symbol.text
        if symbol.kind == "concept" and not symbol.id then
            diagnostics.ambiguousConcept = true
        end
    end
    if normalized.truncated then diagnostics.inputTruncated = true end
    return diagnostics
end

function Parser.Parse(text, options)
    options = type(options) == "table" and options or {}
    local normalized = Normalizer.Normalize(text, options)
    local best
    local tie
    local symbols
    local analysis
    local diagnostics
    local exactOptions = { enableFuzzy = false }

    local function findBest(candidateSymbols)
        local candidateBest
        local candidateScore = -1
        local candidateTie = false
        for _, candidatePattern in ipairs(Registry.GetPatterns()) do
            local match = PatternMatcher.Match(
                candidatePattern, candidateSymbols, normalized
            )
            if match then
                local score
                local details
                score, details = Confidence.Score(candidatePattern, match)
                if score > candidateScore + 0.0001 then
                    candidateBest = {
                        pattern = candidatePattern,
                        match = match,
                        score = score,
                        details = details,
                    }
                    candidateScore = score
                    candidateTie = false
                elseif math.abs(score - candidateScore) <= 0.0001 then
                    candidateTie = true
                end
            end
        end
        return candidateBest, candidateTie
    end

    -- Preserve grammar literals and exact phrase matches.  Fuzzy concept
    -- recognition is a fallback pass, never the first interpretation.
    symbols = ConceptMatcher.Build(normalized, exactOptions)
    analysis = ConceptMatcher.Analysis(normalized, symbols)
    best, tie = findBest(symbols)
    if not best and options.enableFuzzy ~= false then
        symbols = ConceptMatcher.Build(normalized, options)
        analysis = ConceptMatcher.Analysis(normalized, symbols)
        best, tie = findBest(symbols)
    end
    diagnostics = baseDiagnostics(normalized, symbols)
    diagnostics.fuzzyMatch = analysis.fuzzyMatch == true
    diagnostics.correctedTokens = analysis.fuzzyMatches or {}

    if not best then
        diagnostics.recommendedRoute = Confidence.Route(0, options.thresholds)
        diagnostics.coverage = 0
        return IR.New({
            rawText = normalized.rawText,
            normalizedText = normalized.normalizedText,
            confidence = 0,
            diagnostics = diagnostics,
            analysis = analysis,
            provenance = {
                provider = "lua",
                parser = "deterministic",
            },
        })
    end

    local score = best.score
    if tie then
        score = Confidence.Clamp(score - 0.15)
        diagnostics.ambiguousIntent = true
    end

    local emitted = PatternMatcher.ResolveEmit(
        best.pattern.emit or {},
        best.match.captures
    )
    emitted.rawText = normalized.rawText
    emitted.normalizedText = normalized.normalizedText
    emitted.confidence = score
    emitted.analysis = analysis
    emitted.provenance = {
        provider = "lua",
        parser = "deterministic",
        pattern = best.pattern.id,
    }

    diagnostics.noMatch = false
    diagnostics.matchedPattern = best.pattern.id
    diagnostics.coverage = best.match.fullCoverage and 1
        or (best.match.consumed / math.max(1, #symbols))
    diagnostics.unresolvedEntity = best.match.unresolvedCount > 0
    diagnostics.ambiguousConcept = best.match.ambiguousCount > 0
    diagnostics.fuzzyMatch = best.match.fuzzyCount > 0
    diagnostics.unmatchedTokens = {}
    diagnostics.confidenceDetails = best.details
    diagnostics.recommendedRoute = Confidence.Route(score, options.thresholds)
    emitted.diagnostics = diagnostics

    return IR.New(emitted)
end

function Parser.RecognizeConcepts(text, options)
    local normalized = Normalizer.Normalize(text, options)
    local symbols = ConceptMatcher.Build(normalized, options)
    return ConceptMatcher.Analysis(normalized, symbols)
end

return Parser
