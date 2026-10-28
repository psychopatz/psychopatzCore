PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Semantics = PsychopatzCore.Semantics
local IR = Semantics.IR
    or require "PsychopatzCore/Semantics/PsychopatzSemanticIR"
local Normalizer = Semantics.Normalizer
    or require "PsychopatzCore/Semantics/PsychopatzSemanticNormalizer"
local Registry = Semantics.Registry
    or require "PsychopatzCore/Semantics/PsychopatzSemanticRegistry"
local SurfaceRecovery = Semantics.SurfaceRecovery
    or require "PsychopatzCore/Semantics/PsychopatzSemanticSurfaceRecovery"
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
    local bundle = Parser.ParseCandidates(text, options)
    if type(bundle) == "table" and type(bundle.selected) == "table"
        and type(bundle.selected.ir) == "table"
    then
        return IR.Clone(bundle.selected.ir)
    end

    local normalized = Normalizer.Normalize(text, options)
    -- Preserve the exact-pass analysis for a no-match result. Fuzzy symbols
    -- that never participate in a matching grammar must not make an unrelated
    -- exact morphology/literal report look like fuzzy semantic recognition.
    local symbols = ConceptMatcher.Build(normalized, {
        enableFuzzy = false,
    })
    local analysis = ConceptMatcher.Analysis(normalized, symbols)
    local diagnostics = baseDiagnostics(normalized, symbols)
    diagnostics.fuzzyMatch = analysis.fuzzyMatch == true
    diagnostics.correctedTokens = analysis.fuzzyMatches or {}
    diagnostics.recommendedRoute = Confidence.Route(0, options.thresholds)
    diagnostics.coverage = 0
    if type(bundle) == "table" then
        diagnostics.candidateSelection = IR.Clone(bundle.diagnostics) or {}
    end

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

local function collectCandidates(
    patterns,
    symbols,
    normalized,
    pass,
    analysis,
    recovery
)
    local output = {}
    local pattern
    local match
    local score
    local details
    local recoveryPenalty = recovery and tonumber(recovery.cost) or 0
    for _, candidatePattern in ipairs(patterns) do
        pattern = candidatePattern
        match = PatternMatcher.Match(pattern, symbols, normalized)
        if match then
            score, details = Confidence.Score(pattern, match)
            if recoveryPenalty > 0 then
                score = Confidence.Clamp(score - recoveryPenalty)
                details.recoveryPenalty = recoveryPenalty
            end
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
                recovered = recovery ~= nil,
                recovery = recovery,
                normalized = normalized,
                symbols = symbols,
                analysis = analysis,
            }
        end
    end
    return output
end

local function candidateQuality(candidate)
    local match = candidate and candidate.match or {}
    return {
        unresolved = tonumber(match.unresolvedCount) or 0,
        ambiguous = tonumber(match.ambiguousCount) or 0,
        unmatched = tonumber(match.unmatchedCount) or 0,
        fuzzy = tonumber(match.fuzzyCount) or 0,
    }
end

local function betterEqualScore(candidate, best)
    if not best then return true end
    local left = candidateQuality(candidate)
    local right = candidateQuality(best)
    if left.unresolved ~= right.unresolved then
        return left.unresolved < right.unresolved
    end
    if left.ambiguous ~= right.ambiguous then
        return left.ambiguous < right.ambiguous
    end
    if left.unmatched ~= right.unmatched then
        return left.unmatched < right.unmatched
    end
    -- Once semantic completeness is equal, preserve the exact-pass preference.
    if candidate.exact ~= best.exact then return candidate.exact == true end
    if left.fuzzy ~= right.fuzzy then return left.fuzzy < right.fuzzy end
    return false
end

local function bestCandidate(candidates)
    local best
    local bestScore = -1
    local tie = false
    local tiedPatterns = {}
    for _, candidate in ipairs(candidates) do
        if candidate.score > bestScore + 0.0001 then
            best = candidate
            bestScore = candidate.score
            tie = false
            tiedPatterns = {
                [tostring(candidate.pattern and candidate.pattern.id or "")] = true,
            }
        elseif math.abs(candidate.score - bestScore) <= 0.0001 then
            local patternID = tostring(
                candidate.pattern and candidate.pattern.id or ""
            )
            local bestPatternID = tostring(
                best and best.pattern and best.pattern.id or ""
            )
            if patternID == bestPatternID
                and betterEqualScore(candidate, best)
            then
                best = candidate
            elseif patternID ~= bestPatternID then
                if betterEqualScore(candidate, best) then
                    best = candidate
                    tie = false
                    tiedPatterns = { [patternID] = true }
                elseif not betterEqualScore(best, candidate) then
                    tiedPatterns[patternID] = true
                    tie = true
                end
            end
        end
    end
    return best, tie
end

local function candidateComparator(left, right)
    if math.abs(left.score - right.score) > 0.0001 then
        return left.score > right.score
    end
    if left.exact ~= right.exact then return left.exact end
    if left.fuzzy ~= right.fuzzy then return left.fuzzy ~= true end
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

local function recoveryProjection(recovery)
    if type(recovery) ~= "table" then return nil end
    return {
        kind = recovery.kind,
        cost = recovery.cost,
        originalNormalizedText = recovery.originalNormalizedText,
        recoveredNormalizedText = recovery.recoveredNormalizedText,
        tokenIndex = recovery.tokenIndex,
        originalToken = recovery.originalToken,
        recoveredSurface = recovery.recoveredSurface,
        conceptID = recovery.conceptID,
        sourceAlias = recovery.sourceAlias,
        mutationSafe = recovery.mutationSafe == true,
    }
end

local function candidateDiagnostics(normalized, symbols, analysis, candidate)
    local diagnostics = baseDiagnostics(normalized, symbols)
    diagnostics.noMatch = false
    diagnostics.matchedPattern = candidate.pattern.id
    diagnostics.candidatePass = candidate.pass
    diagnostics.exactMatch = candidate.exact == true
    diagnostics.fuzzyMatch = candidate.fuzzy == true
    diagnostics.recoveredMatch = candidate.recovered == true
    diagnostics.coverage = candidate.match.fullCoverage and 1
        or (candidate.match.consumed / math.max(1, #symbols))
    diagnostics.unresolvedEntity = candidate.match.unresolvedCount > 0
    diagnostics.ambiguousConcept = candidate.match.ambiguousCount > 0
    diagnostics.unmatchedTokens = {}
    diagnostics.correctedTokens = analysis.fuzzyMatches or {}
    diagnostics.confidenceDetails = candidate.details
    diagnostics.surfaceRecovery = recoveryProjection(candidate.recovery)
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

local function buildCandidateIR(candidate)
    local normalized = candidate.normalized
    local symbols = candidate.symbols
    local analysis = IR.Clone(candidate.analysis) or {}
    local recovery = recoveryProjection(candidate.recovery)
    if recovery then analysis.surfaceRecovery = recovery end

    local emitted = PatternMatcher.ResolveEmit(
        candidate.pattern.emit or {}, candidate.match.captures
    )
    emitted.rawText = normalized.rawText
    emitted.normalizedText = recovery
        and recovery.originalNormalizedText or normalized.normalizedText
    emitted.confidence = candidate.score
    emitted.analysis = analysis
    emitted.provenance = {
        provider = "lua",
        parser = "deterministic",
        pattern = candidate.pattern.id,
        candidatePass = candidate.pass,
        surfaceRecovery = recovery,
    }
    emitted.diagnostics = candidateDiagnostics(
        normalized, symbols, candidate.analysis, candidate
    )
    return IR.New(emitted)
end

local function candidateDescriptor(candidate)
    local ir = buildCandidateIR(candidate)
    local match = candidate.match
    return {
        patternID = candidate.pattern.id,
        pass = candidate.pass,
        exact = candidate.exact == true,
        fuzzy = candidate.fuzzy == true,
        recovered = candidate.recovered == true,
        surfaceRecovery = recoveryProjection(candidate.recovery),
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
    local exactBest = bestCandidate(exactMatches)

    local fuzzyMatches = {}
    local fuzzyCapture = exactBest and exactBest.pattern
        and exactBest.pattern.allowFuzzyCapture == true
        and exactBest.match and exactBest.match.unresolvedCount > 0
    if options.enableFuzzy ~= false and (not exactBest or fuzzyCapture) then
        local fuzzySymbols = ConceptMatcher.Build(normalized, options)
        local fuzzyAnalysis = ConceptMatcher.Analysis(normalized, fuzzySymbols)
        fuzzyMatches = collectCandidates(
            patterns, fuzzySymbols, normalized, "fuzzy", fuzzyAnalysis
        )
    end

    local recoveryVariants = {}
    local recoveryMatches = {}
    if not exactBest and options.enableSurfaceRecovery ~= false
        and SurfaceRecovery
        and type(SurfaceRecovery.Generate) == "function"
    then
        recoveryVariants = SurfaceRecovery.Generate(normalized, options)
        for _, recovery in ipairs(recoveryVariants) do
            local recovered = recovery.normalized
            local recoveredSymbols = ConceptMatcher.Build(
                recovered, exactOptions
            )
            local recoveredAnalysis = ConceptMatcher.Analysis(
                recovered, recoveredSymbols
            )
            local matches = collectCandidates(
                patterns,
                recoveredSymbols,
                recovered,
                "recovered",
                recoveredAnalysis,
                recovery
            )
            for _, candidate in ipairs(matches) do
                recoveryMatches[#recoveryMatches + 1] = candidate
            end
        end
    end

    local rawCandidates = {}
    for _, candidate in ipairs(exactMatches) do
        appendCandidate(rawCandidates, candidate)
    end
    for _, candidate in ipairs(fuzzyMatches) do
        appendCandidate(rawCandidates, candidate)
    end
    for _, candidate in ipairs(recoveryMatches) do
        appendCandidate(rawCandidates, candidate)
    end

    local selectedRaw, selectedTie = bestCandidate(rawCandidates)
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
            recoveredCandidateCount = #recoveryMatches,
            recoveryVariantCount = #recoveryVariants,
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
        descriptor = candidateDescriptor(raw)
        result.candidates[#result.candidates + 1] = descriptor
        if raw == selectedRaw then
            result.selected = descriptor
            result.selectedIndex = #result.candidates
        end
    end

    -- The selected candidate must remain inspectable even when a caller asks
    -- for a very small result window.
    if selectedRaw and not result.selected then
        descriptor = candidateDescriptor(selectedRaw)
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
        result.diagnostics.selectedRecovered =
            result.selected.recovered == true
        result.diagnostics.selectedRecovery =
            IR.Clone(result.selected.surfaceRecovery)
    end
    return result
end

function Parser.RecognizeConcepts(text, options)
    local normalized = Normalizer.Normalize(text, options)
    local symbols = ConceptMatcher.Build(normalized, options)
    return ConceptMatcher.Analysis(normalized, symbols)
end

return Parser
