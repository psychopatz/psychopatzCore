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

Parser.CANDIDATE_VERSION = 1
Parser.DEFAULT_MAX_CANDIDATES = 8
Parser.MAX_CANDIDATES = 16

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
    local fuzzyCapture = best and best.pattern
        and best.pattern.allowFuzzyCapture == true
        and best.match and best.match.unresolvedCount > 0
    if options.enableFuzzy ~= false and (not best or fuzzyCapture) then
        local fuzzySymbols = ConceptMatcher.Build(normalized, options)
        local fuzzyAnalysis = ConceptMatcher.Analysis(
            normalized, fuzzySymbols)
        local fuzzyBest
        local fuzzyTie
        fuzzyBest, fuzzyTie = findBest(fuzzySymbols)
        if fuzzyBest and (not best or fuzzyBest.score >= best.score) then
            symbols = fuzzySymbols
            analysis = fuzzyAnalysis
            best = fuzzyBest
            tie = fuzzyTie
        end
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

-- Candidate inspection is deliberately additive.  Parser.Parse above keeps
-- its original single-winner contract for existing consumers; this API lets a
-- dialogue owner inspect a small, deterministic set of alternatives before it
-- applies speaker/context eligibility.  It never mutates the registry or
-- dialogue state.
local function candidateLimit(options)
    local limit = math.floor(
        tonumber(options.maxCandidates) or Parser.DEFAULT_MAX_CANDIDATES
    )
    if limit < 1 then return 1 end
    if limit > Parser.MAX_CANDIDATES then return Parser.MAX_CANDIDATES end
    return limit
end

local function collectCandidates(patterns, symbols, normalized, pass, analysis)
    local output = {}
    local pattern
    local match
    local score
    local details
    for _, candidatePattern in ipairs(patterns) do
        pattern = candidatePattern
        match = PatternMatcher.Match(pattern, symbols, normalized)
        if match then
            score, details = Confidence.Score(pattern, match)
            output[#output + 1] = {
                pattern = pattern,
                match = match,
                score = score,
                details = details,
                pass = pass,
                exact = pass == "exact",
                fuzzy = pass == "fuzzy"
                    or (tonumber(match.fuzzyCount) or 0) > 0
                    or analysis.fuzzyMatch == true,
            }
        end
    end
    return output
end

local function bestCandidate(candidates)
    local best
    local bestScore = -1
    local tie = false
    for _, candidate in ipairs(candidates) do
        if candidate.score > bestScore + 0.0001 then
            best = candidate
            bestScore = candidate.score
            tie = false
        elseif math.abs(candidate.score - bestScore) <= 0.0001 then
            tie = true
        end
    end
    return best, tie
end

local function candidateComparator(left, right)
    if math.abs(left.score - right.score) > 0.0001 then
        return left.score > right.score
    end
    if left.exact ~= right.exact then return left.exact end
    local leftPriority = tonumber(left.pattern.priority) or 0
    local rightPriority = tonumber(right.pattern.priority) or 0
    if leftPriority ~= rightPriority then
        return leftPriority > rightPriority
    end
    if left.pattern.id ~= right.pattern.id then
        return tostring(left.pattern.id) < tostring(right.pattern.id)
    end
    return tostring(left.pass) < tostring(right.pass)
end

local function candidateDiagnostics(normalized, symbols, analysis, candidate)
    local diagnostics = baseDiagnostics(normalized, symbols)
    diagnostics.noMatch = false
    diagnostics.matchedPattern = candidate.pattern.id
    diagnostics.candidatePass = candidate.pass
    diagnostics.exactMatch = candidate.exact == true
    diagnostics.fuzzyMatch = candidate.fuzzy == true
    diagnostics.coverage = candidate.match.fullCoverage and 1
        or (candidate.match.consumed / math.max(1, #symbols))
    diagnostics.unresolvedEntity = candidate.match.unresolvedCount > 0
    diagnostics.ambiguousConcept = candidate.match.ambiguousCount > 0
    diagnostics.unmatchedTokens = {}
    diagnostics.correctedTokens = analysis.fuzzyMatches or {}
    diagnostics.confidenceDetails = candidate.details
    diagnostics.recommendedRoute = Confidence.Route(
        candidate.score, nil
    )
    diagnostics.matchMetrics = {
        consumed = candidate.match.consumed,
        skipped = candidate.match.skipped,
        unresolvedCount = candidate.match.unresolvedCount,
        ambiguousCount = candidate.match.ambiguousCount,
        fuzzyCount = candidate.match.fuzzyCount,
        unmatchedCount = candidate.match.unmatchedCount,
        fullCoverage = candidate.match.fullCoverage == true,
    }
    return diagnostics
end

local function buildCandidateIR(normalized, symbols, analysis, candidate)
    local emitted = PatternMatcher.ResolveEmit(
        candidate.pattern.emit or {}, candidate.match.captures
    )
    emitted.rawText = normalized.rawText
    emitted.normalizedText = normalized.normalizedText
    emitted.confidence = candidate.score
    emitted.analysis = analysis
    emitted.provenance = {
        provider = "lua",
        parser = "deterministic",
        pattern = candidate.pattern.id,
        candidatePass = candidate.pass,
    }
    emitted.diagnostics = candidateDiagnostics(
        normalized, symbols, analysis, candidate
    )
    return IR.New(emitted)
end

local function candidateDescriptor(normalized, symbols, analysis, candidate)
    local ir = buildCandidateIR(normalized, symbols, analysis, candidate)
    local match = candidate.match
    return {
        patternID = candidate.pattern.id,
        pass = candidate.pass,
        exact = candidate.exact == true,
        fuzzy = candidate.fuzzy == true,
        score = candidate.score,
        confidence = candidate.score,
        priority = tonumber(candidate.pattern.priority) or 0,
        captures = IR.Clone(match.captures) or {},
        -- typedCaptures is an explicit name for consumers that do not want to
        -- infer the capture contract from the older captures field.
        typedCaptures = IR.Clone(match.captures) or {},
        metadata = IR.Clone(candidate.pattern.metadata) or {},
        match = {
            consumed = match.consumed,
            skipped = match.skipped,
            unresolvedCount = match.unresolvedCount,
            ambiguousCount = match.ambiguousCount,
            fuzzyCount = match.fuzzyCount,
            unmatchedCount = match.unmatchedCount,
            fullCoverage = match.fullCoverage == true,
        },
        ir = ir,
    }
end

local function appendCandidate(list, candidate)
    list[#list + 1] = candidate
end

function Parser.ParseCandidates(text, options)
    options = type(options) == "table" and options or {}
    local normalized = Normalizer.Normalize(text, options)
    local patterns = Registry.GetPatterns()
    local limit = candidateLimit(options)
    local exactOptions = { enableFuzzy = false }
    local exactSymbols = ConceptMatcher.Build(normalized, exactOptions)
    local exactAnalysis = ConceptMatcher.Analysis(normalized, exactSymbols)
    local exactMatches = collectCandidates(
        patterns, exactSymbols, normalized, "exact", exactAnalysis
    )
    local exactBest, exactTie = bestCandidate(exactMatches)
    local fuzzyMatches = {}
    local fuzzySymbols
    local fuzzyAnalysis
    local fuzzyBest
    local fuzzyTie = false
    local fuzzyCapture = exactBest and exactBest.pattern
        and exactBest.pattern.allowFuzzyCapture == true
        and exactBest.match and exactBest.match.unresolvedCount > 0

    if options.enableFuzzy ~= false and (not exactBest or fuzzyCapture) then
        fuzzySymbols = ConceptMatcher.Build(normalized, options)
        fuzzyAnalysis = ConceptMatcher.Analysis(normalized, fuzzySymbols)
        fuzzyMatches = collectCandidates(
            patterns, fuzzySymbols, normalized, "fuzzy", fuzzyAnalysis
        )
        fuzzyBest, fuzzyTie = bestCandidate(fuzzyMatches)
    end

    local selectedRaw = exactBest
    local selectedTie = exactTie
    if fuzzyBest and (not exactBest or fuzzyBest.score >= exactBest.score) then
        selectedRaw = fuzzyBest
        selectedTie = fuzzyTie
    end

    local rawCandidates = {}
    local index
    for index = 1, #exactMatches do
        appendCandidate(rawCandidates, exactMatches[index])
    end
    for index = 1, #fuzzyMatches do
        appendCandidate(rawCandidates, fuzzyMatches[index])
    end
    table.sort(rawCandidates, candidateComparator)

    local result = {
        schemaVersion = Parser.CANDIDATE_VERSION,
        kind = "semantic_parse_candidates",
        rawText = normalized.rawText,
        normalizedText = normalized.normalizedText,
        candidates = {},
        selected = nil,
        selectedIndex = nil,
        diagnostics = {
            parser = "lua_deterministic",
            registryRevision = Registry.GetRevision(),
            candidateLimit = limit,
            candidateCount = #rawCandidates,
            exactCandidateCount = #exactMatches,
            fuzzyCandidateCount = #fuzzyMatches,
            truncated = normalized.truncated == true,
            ambiguous = selectedTie == true,
            noMatch = selectedRaw == nil,
        },
    }

    local raw
    local descriptor
    for index = 1, #rawCandidates do
        if #result.candidates >= limit then break end
        raw = rawCandidates[index]
        descriptor = candidateDescriptor(
            normalized,
            raw.pass == "fuzzy" and fuzzySymbols or exactSymbols,
            raw.pass == "fuzzy" and fuzzyAnalysis or exactAnalysis,
            raw
        )
        result.candidates[#result.candidates + 1] = descriptor
        if raw == selectedRaw then
            result.selected = descriptor
            result.selectedIndex = #result.candidates
        end
    end

    -- The selected candidate must remain inspectable even when a caller asks
    -- for a very small result window.
    if selectedRaw and not result.selected then
        descriptor = candidateDescriptor(
            normalized,
            selectedRaw.pass == "fuzzy" and fuzzySymbols or exactSymbols,
            selectedRaw.pass == "fuzzy" and fuzzyAnalysis or exactAnalysis,
            selectedRaw
        )
        if #result.candidates >= limit then
            result.candidates[#result.candidates] = descriptor
            result.selectedIndex = #result.candidates
        else
            result.candidates[#result.candidates + 1] = descriptor
            result.selectedIndex = #result.candidates
        end
        result.selected = descriptor
    end

    if result.selected then
        result.selected.selected = true
        if selectedTie then
            local confidence = Confidence.Clamp(result.selected.score - 0.15)
            result.selected.confidence = confidence
            result.selected.ir.confidence = confidence
            result.selected.ir.confidenceBand = Confidence.Band(confidence)
            result.selected.ir.diagnostics.ambiguousIntent = true
            result.selected.ir.diagnostics.candidateTie = true
        end
        result.diagnostics.selectedPattern = result.selected.patternID
        result.diagnostics.selectedPass = result.selected.pass
        result.diagnostics.selectedConfidence = result.selected.confidence
    end
    return result
end

function Parser.RecognizeConcepts(text, options)
    local normalized = Normalizer.Normalize(text, options)
    local symbols = ConceptMatcher.Build(normalized, options)
    return ConceptMatcher.Analysis(normalized, symbols)
end

return Parser
