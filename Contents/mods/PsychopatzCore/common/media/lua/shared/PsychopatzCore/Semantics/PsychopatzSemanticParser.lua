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
local FollowUp = Semantics.FollowUp
    or require "PsychopatzCore/Semantics/PsychopatzSemanticFollowUp"
local GroupAddressing = Semantics.GroupAddressing
    or require "PsychopatzCore/Semantics/PsychopatzSemanticGroupAddressing"
local ClausePreParser = Semantics.ClausePreParser
    or require "PsychopatzCore/Semantics/PsychopatzSemanticClausePreParser"
local VerbFrameParser = Semantics.VerbFrameParser
    or require "PsychopatzCore/Semantics/PsychopatzSemanticVerbFrameParser"
local IntentClassifier = Semantics.IntentClassifier
    or require "PsychopatzCore/Semantics/PsychopatzSemanticIntentClassifier"
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
Parser.TelemetryEnabled = Parser.TelemetryEnabled == true
Parser.MAX_MISSED_TELEMETRY = 64
Parser._missedTelemetry = Parser._missedTelemetry or {}

function Parser.SetTelemetryEnabled(enabled)
    Parser.TelemetryEnabled = enabled == true
    return Parser.TelemetryEnabled
end

function Parser.GetMissedUtterances()
    local copy = {}
    for i = 1, #Parser._missedTelemetry do
        copy[i] = Parser._missedTelemetry[i]
    end
    return copy
end

function Parser.ResetMissedUtterances()
    Parser._missedTelemetry = {}
    return true
end

local function recordMissedTelemetry(rawText, coreText, result)
    if Parser.TelemetryEnabled ~= true then return end
    local sel = type(result) == "table" and result.selected or nil
    local conf = sel and (tonumber(sel.confidence) or 0) or 0
    if sel and conf >= 0.65 then return end
    local list = Parser._missedTelemetry
    if #list >= Parser.MAX_MISSED_TELEMETRY then
        table.remove(list, 1)
    end
    list[#list + 1] = {
        rawText = tostring(rawText or ""),
        coreText = coreText and tostring(coreText) or nil,
        confidence = conf,
        selectedPattern = sel and sel.patternID or nil,
        action = sel and sel.ir and sel.ir.action or nil,
        intent = sel and sel.ir and sel.ir.intent or nil,
    }
end

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

local function applyClauseFrameToIR(ir, clauseFrame)
    if type(ir) ~= "table" or type(clauseFrame) ~= "table" then return end
    ir.extensions = type(ir.extensions) == "table" and ir.extensions or {}
    if ir.extensions.modality == nil then
        ir.extensions.modality = clauseFrame.modality
    end
    if clauseFrame.negated == true and ir.extensions.negated ~= true then
        ir.polarity = "negative"
        ir.extensions.negated = true
        ir.extensions.negationCue = clauseFrame.negationCue
        if ir.action ~= nil
            and ir.extensions.originalAction == nil
            and type(VerbFrameParser) == "table"
            and type(VerbFrameParser.ResolveNegatedAction) == "function"
        then
            local inv = VerbFrameParser.ResolveNegatedAction(ir.action)
            if inv and inv ~= ir.action then
                ir.extensions.originalAction = ir.action
                ir.action = inv
            end
        end
    end
    if type(clauseFrame.audienceScope) == "table"
        and clauseFrame.audienceScope.scope ~= "DEFAULT"
        and ir.extensions.audienceScope == nil
    then
        ir.extensions.audienceScope = IR.Clone(clauseFrame.audienceScope)
        if clauseFrame.audienceScope.scope == "GROUP" then
            ir.extensions.groupBroadcast = true
        elseif clauseFrame.audienceScope.scope == "INDIVIDUAL"
            and type(clauseFrame.audienceScope.targetIDs) == "table"
            and #clauseFrame.audienceScope.targetIDs == 1
            and ir.extensions.vocativeTargetID == nil
        then
            ir.extensions.vocativeTargetID = clauseFrame.audienceScope.targetIDs[1]
        end
    end
end

local function candidatePassTier(candidate)
    if type(candidate) ~= "table" then return 0 end
    local pass = tostring(candidate.pass or "")
    if pass == "exact" then return 4 end
    if pass == "fuzzy" or pass == "recovered" then return 3 end
    if pass == "verb_frame" then return 2 end
    if pass == "intent_classifier" or pass == "followup" then return 1 end
    return 1
end

local function isWeakRawSelection(bundle)
    if type(bundle) ~= "table" or type(bundle.selected) ~= "table" then
        return true
    end
    local sel = bundle.selected
    if tostring(sel.pass or "") ~= "exact" then
        return true
    end
    local match = type(sel.match) == "table" and sel.match or nil
    if match and ((tonumber(match.unmatchedCount) or 0) > 0
        or (tonumber(match.unresolvedCount) or 0) > 0)
    then
        return true
    end
    if (tonumber(sel.confidence) or 0) < 0.90 then
        return true
    end
    return false
end

local function isBetterSelectedCandidate(coreSel, rawSel)
    if type(coreSel) ~= "table" then return false end
    if type(rawSel) ~= "table" then return true end
    local coreTier = candidatePassTier(coreSel)
    local rawTier = candidatePassTier(rawSel)
    if coreTier ~= rawTier then
        return coreTier > rawTier
    end
    local coreConf = tonumber(coreSel.confidence) or 0
    local rawConf = tonumber(rawSel.confidence) or 0
    if coreConf > rawConf + 0.02 then
        return true
    end
    if rawConf > coreConf + 0.02 then
        return false
    end
    local coreMatch = type(coreSel.match) == "table" and coreSel.match or {}
    local rawMatch = type(rawSel.match) == "table" and rawSel.match or {}
    local coreUnmatched = tonumber(coreMatch.unmatchedCount) or 0
    local rawUnmatched = tonumber(rawMatch.unmatchedCount) or 0
    if coreUnmatched ~= rawUnmatched then
        return coreUnmatched < rawUnmatched
    end
    local coreUnresolved = tonumber(coreMatch.unresolvedCount) or 0
    local rawUnresolved = tonumber(rawMatch.unresolvedCount) or 0
    if coreUnresolved ~= rawUnresolved then
        return coreUnresolved < rawUnresolved
    end
    return false
end

function Parser.Parse(text, options)
    options = type(options) == "table" and options or {}
    local addr = nil
    local parseText = text
    if (type(options.groupParticipants) == "table" or type(options.groupFloor) == "table")
        and type(GroupAddressing) == "table" and type(GroupAddressing.Resolve) == "function"
    then
        addr = GroupAddressing.Resolve(text, options.groupParticipants, options.groupFloor, options)
        if addr and type(addr.cleanedText) == "string" and addr.cleanedText ~= "" then
            parseText = addr.cleanedText
        end
    end
    local clauseFrame = type(ClausePreParser) == "table"
        and type(ClausePreParser.Analyze) == "function"
        and ClausePreParser.Analyze(parseText, options.groupParticipants)
        or nil
    local bundle = Parser.ParseCandidates(parseText, options)
    if type(bundle) == "table" and type(bundle.selected) == "table"
        and type(bundle.selected.ir) == "table"
    then
        local cloned = IR.Clone(bundle.selected.ir)
        if type(cloned) == "table" and (addr or clauseFrame) then
            cloned.extensions = type(cloned.extensions) == "table" and cloned.extensions or {}
            if addr then
                cloned.extensions.addressing = addr
                if addr.broadcast then cloned.extensions.groupBroadcast = true end
                if addr.targetID ~= nil then cloned.extensions.vocativeTargetID = addr.targetID end
                if addr.referencedActorID ~= nil then cloned.extensions.referencedActorID = addr.referencedActorID end
            end
            if clauseFrame then
                applyClauseFrameToIR(cloned, clauseFrame)
            end
        end
        return cloned
    end

    local normalized = Normalizer.Normalize(parseText, options)
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

local function hasCapability(caps, capName)
    if not caps then return false end
    if caps[capName] == true then return true end
    for _, c in ipairs(caps) do
        if c == capName then return true end
    end
    return false
end

local function collectCandidates(
    patterns,
    symbols,
    normalized,
    pass,
    analysis,
    recovery,
    options
)
    local output = {}
    local pattern
    local match
    local score
    local details
    local recoveryPenalty = recovery and tonumber(recovery.cost) or 0
    local caps = options and (options.capabilities or (options.context and options.context.capabilities))
    for _, candidatePattern in ipairs(patterns) do
        pattern = candidatePattern
        local allowed = true
        local req = pattern.capabilityRequired or pattern.capabilitiesRequired
        if req then
            if type(req) == "string" then
                if caps ~= nil then
                    allowed = hasCapability(caps, req)
                elseif options and options.strictCapabilities == true then
                    allowed = false
                end
            elseif type(req) == "table" then
                for _, capName in ipairs(req) do
                    if caps ~= nil then
                        if not hasCapability(caps, capName) then
                            allowed = false
                            break
                        end
                    elseif options and options.strictCapabilities == true then
                        allowed = false
                        break
                    end
                end
            end
        end

        if allowed then
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
    end
    return output
end

local function candidateQuality(candidate)
    local match = candidate and candidate.match or {}
    return {
        unresolved = tonumber(match.unresolvedCount) or 0,
        ambiguous = tonumber(match.ambiguousCount) or 0,
        unmatched = tonumber(match.unmatchedCount) or 0,
        secondary = tonumber(match.secondaryCount) or 0,
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
    if left.secondary ~= right.secondary then
        return left.secondary < right.secondary
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
    local leftSecondary = tonumber(left.match and left.match.secondaryCount) or 0
    local rightSecondary = tonumber(right.match and right.match.secondaryCount) or 0
    if leftSecondary ~= rightSecondary then
        return leftSecondary < rightSecondary
    end
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

local PARSE_CACHE_MAX = 64
local parseCache = {}
local parseCacheOrder = {}
local parseCacheHead = 1
local parseCacheCount = 0
local parseCacheRev = -1

local function clearParseCache(rev)
    parseCache = {}
    parseCacheOrder = {}
    parseCacheHead = 1
    parseCacheCount = 0
    parseCacheRev = rev
end

local function parseCacheKey(text, options, limit)
    if options.bypassCache == true
        or options.context ~= nil
        or options.groupParticipants ~= nil
        or options._clauseCorePass == true
    then
        return nil
    end
    local raw = tostring(text or "")
    if #raw > 256 then return nil end
    return raw .. "|" .. tostring(limit)
        .. "|" .. (options.enableFuzzy == false and "0" or "1")
        .. "|" .. (options.enableSurfaceRecovery == false and "0" or "1")
        .. "|" .. (options.enableVerbFrames == false and "0" or "1")
        .. "|" .. (options.enableClausePreParser == false and "0" or "1")
        .. "|" .. (options.negated == true and "1" or "0")
end

local function storeParseCache(key, value)
    if not key then return end
    if parseCache[key] == nil then
        if parseCacheCount >= PARSE_CACHE_MAX then
            local oldest = parseCacheOrder[parseCacheHead]
            if oldest ~= nil then parseCache[oldest] = nil end
            parseCacheOrder[parseCacheHead] = key
            parseCacheHead = (parseCacheHead % PARSE_CACHE_MAX) + 1
        else
            local slot = ((parseCacheHead + parseCacheCount - 1) % PARSE_CACHE_MAX) + 1
            parseCacheOrder[slot] = key
            parseCacheCount = parseCacheCount + 1
        end
    end
    parseCache[key] = value
end

function Parser.ResetCache()
    clearParseCache(-1)
    return true
end

function Parser.ParseCandidates(text, options)
    options = type(options) == "table" and options or {}
    local rev = Registry.GetRevision()
    if parseCacheRev ~= rev then clearParseCache(rev) end
    local limit = candidateLimit(options)
    local cacheKey = parseCacheKey(text, options, limit)
    if cacheKey and parseCache[cacheKey] ~= nil then
        return IR.Clone(parseCache[cacheKey])
    end

    local reusedNormalized = nil
    if options._clauseCorePass ~= true
        and options.enableClausePreParser ~= false
        and type(ClausePreParser) == "table"
        and type(ClausePreParser.Analyze) == "function"
    then
        local clauseInput = text
        local preNorm = nil
        if type(Normalizer) == "table" and type(Normalizer.Normalize) == "function" then
            preNorm = Normalizer.Normalize(text, options)
            if type(preNorm) == "table"
                and (preNorm.expandedShorthand == true or preNorm.collapsedElongation == true)
                and type(preNorm.normalizedText) == "string"
                and preNorm.normalizedText ~= ""
            then
                clauseInput = preNorm.normalizedText
            end
        end
        local clauseFrame = ClausePreParser.Analyze(clauseInput, options.groupParticipants)
        local hasCleanCore = type(clauseFrame) == "table"
            and clauseFrame.changed == true
            and type(clauseFrame.coreText) == "string"
            and clauseFrame.coreText ~= ""
            and string.lower(clauseFrame.coreText) ~= string.lower(tostring(text or ""))
        if hasCleanCore then
            local rawOpts = {}
            for k, v in pairs(options) do rawOpts[k] = v end
            rawOpts._clauseCorePass = true
            rawOpts._preNormalized = preNorm
            rawOpts.enableVerbFrames = false
            local rawBundle = Parser.ParseCandidates(text, rawOpts)
            local chosen = rawBundle
            if isWeakRawSelection(rawBundle) then
                local coreOpts = {}
                for k, v in pairs(options) do coreOpts[k] = v end
                coreOpts._clauseCorePass = true
                if clauseFrame.negated == true then
                    coreOpts.negated = true
                end
                local coreBundle = Parser.ParseCandidates(clauseFrame.coreText, coreOpts)
                if type(coreBundle) == "table" and type(coreBundle.selected) == "table"
                    and (type(rawBundle) ~= "table"
                        or type(rawBundle.selected) ~= "table"
                        or isBetterSelectedCandidate(coreBundle.selected, rawBundle.selected))
                then
                    coreBundle.rawText = tostring(text or "")
                    coreBundle.diagnostics = type(coreBundle.diagnostics) == "table"
                        and coreBundle.diagnostics or {}
                    coreBundle.diagnostics.clausePreParsed = true
                    coreBundle.diagnostics.clauseCoreText = clauseFrame.coreText
                    for i = 1, #(coreBundle.candidates or {}) do
                        local cand = coreBundle.candidates[i]
                        if type(cand) == "table" and type(cand.ir) == "table" then
                            cand.ir.rawText = tostring(text or "")
                            applyClauseFrameToIR(cand.ir, clauseFrame)
                        end
                    end
                    chosen = coreBundle
                end
            end
            recordMissedTelemetry(text, clauseFrame.coreText, chosen)
            if cacheKey and type(chosen) == "table" then
                storeParseCache(cacheKey, IR.Clone(chosen))
            end
            return chosen
        end
        -- Reuse the already-normalized result for this exact text without
        -- mutating the caller-owned options table.
        reusedNormalized = preNorm
    end

    local normalized = reusedNormalized
        or options._preNormalized
        or Normalizer.Normalize(text, options)
    local function candidatePatternsFor(symbols, norm)
        if type(Registry.GetCandidatePatterns) == "function" then
            return Registry.GetCandidatePatterns(symbols, norm)
        end
        return Registry.GetPatterns()
    end
    local exactOptions = { enableFuzzy = false }

    local exactSymbols = ConceptMatcher.Build(normalized, exactOptions)
    local exactAnalysis = ConceptMatcher.Analysis(normalized, exactSymbols)
    local exactMatches = collectCandidates(
        candidatePatternsFor(exactSymbols, normalized),
        exactSymbols, normalized, "exact", exactAnalysis, nil, options
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
            candidatePatternsFor(fuzzySymbols, normalized),
            fuzzySymbols, normalized, "fuzzy", fuzzyAnalysis, nil, options
        )
    end

    local recoveryVariants = {}
    local recoveryMatches = {}
    if not exactBest and #fuzzyMatches == 0
        and type(normalized.cleanTokens) == "table"
        and #normalized.cleanTokens > 0
        and #normalized.cleanTokens < #(normalized.tokens or {})
    then
        local strippedNormalized = {
            rawText = normalized.rawText,
            normalizedText = table.concat(normalized.cleanTokens, " "),
            tokens = normalized.cleanTokens,
            lemmas = normalized.lemmas,
            cleanTokens = normalized.cleanTokens,
            playerTone = normalized.playerTone,
            truncated = normalized.truncated,
        }
        local strippedSymbols = ConceptMatcher.Build(strippedNormalized, options)
        local strippedAnalysis = ConceptMatcher.Analysis(strippedNormalized, strippedSymbols)
        local strippedCandidates = collectCandidates(
            candidatePatternsFor(strippedSymbols, strippedNormalized),
            strippedSymbols, strippedNormalized, "fuzzy", strippedAnalysis, nil, options
        )
        for _, candidate in ipairs(strippedCandidates) do
            fuzzyMatches[#fuzzyMatches + 1] = candidate
        end
    end
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
                candidatePatternsFor(recoveredSymbols, recovered),
                recoveredSymbols,
                recovered,
                "recovered",
                recoveredAnalysis,
                recovery,
                options
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

    if #rawCandidates == 0
        and options.enableVerbFrames ~= false
        and type(VerbFrameParser) == "table"
        and type(VerbFrameParser.Parse) == "function"
    then
        local vfCandidate = VerbFrameParser.Parse(normalized, exactSymbols, options)
        if not vfCandidate
            and options.enableIntentClassifier ~= false
            and type(IntentClassifier) == "table"
            and type(IntentClassifier.Classify) == "function"
        then
            vfCandidate = IntentClassifier.Classify(normalized, options)
        end
        if type(vfCandidate) == "table" and type(vfCandidate.ir) == "table" then
            vfCandidate.pass = vfCandidate.pass or vfCandidate.source or "verb_frame"
            vfCandidate.patternID = vfCandidate.patternID or vfCandidate.patternId
            vfCandidate.selected = true
            vfCandidate.ir.confidenceBand = Confidence.Band(vfCandidate.confidence)
            vfCandidate.ir.diagnostics.recommendedRoute =
                Confidence.Route(vfCandidate.confidence, options.thresholds)
            local vfResult = {
                schemaVersion = Parser.CANDIDATE_VERSION,
                kind = "semantic_parse_candidates",
                rawText = normalized.rawText,
                normalizedText = normalized.normalizedText,
                candidates = { vfCandidate },
                selected = vfCandidate,
                selectedIndex = 1,
                diagnostics = {
                    parser = "lua_verb_frame",
                    registryRevision = Registry.GetRevision(),
                    candidateLimit = limit,
                    candidateCount = 1,
                    exactCandidateCount = 0,
                    fuzzyCandidateCount = 0,
                    recoveredCandidateCount = 0,
                    verbFrameCandidateCount = 1,
                    recoveryVariantCount = #recoveryVariants,
                    truncated = normalized.truncated == true,
                    ambiguous = false,
                    noMatch = false,
                },
            }
            storeParseCache(cacheKey, IR.Clone(vfResult))
            return vfResult
        end
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
        -- Multi-tier candidate fusion: when pattern matching only produced a weak
        -- or partial match, allow VerbFrameParser / IntentClassifier to vote too
        -- instead of letting a low-confidence fuzzy pattern short-circuit them.
        local sel = result.selected
        local selUnmatched = type(sel.match) == "table"
            and (tonumber(sel.match.unmatchedCount) or 0) or 0
        local weakPattern = sel.pass ~= "exact"
            or (tonumber(sel.confidence) or 0) < 0.80
            or selUnmatched > 0
        if weakPattern
            and options.enableVerbFrames ~= false
            and type(VerbFrameParser) == "table"
            and type(VerbFrameParser.Parse) == "function"
        then
            local fused = VerbFrameParser.Parse(normalized, exactSymbols, options)
            if not fused
                and options.enableIntentClassifier ~= false
                and type(IntentClassifier) == "table"
                and type(IntentClassifier.Classify) == "function"
            then
                fused = IntentClassifier.Classify(normalized, options)
            end
            if type(fused) == "table" and type(fused.ir) == "table" then
                fused.pass = fused.pass or fused.source or "verb_frame"
                fused.patternID = fused.patternID or fused.patternId
                fused.ir.confidenceBand = Confidence.Band(fused.confidence)
                fused.ir.diagnostics = type(fused.ir.diagnostics) == "table"
                    and fused.ir.diagnostics or {}
                fused.ir.diagnostics.recommendedRoute =
                    Confidence.Route(fused.confidence, options.thresholds)
                if #result.candidates < limit then
                    result.candidates[#result.candidates + 1] = fused
                else
                    result.candidates[#result.candidates] = fused
                end
                result.diagnostics.candidateCount = #result.candidates
                result.diagnostics.multiTierFused = true
                if (tonumber(fused.confidence) or 0) > (tonumber(sel.confidence) or 0) + 0.05
                    and (sel.pass ~= "exact" or selUnmatched > 0)
                then
                    sel.selected = false
                    fused.selected = true
                    result.selected = fused
                    result.selectedIndex = #result.candidates
                    selectedTie = false
                end
            end
        end
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
        if normalized.playerTone and normalized.playerTone ~= "neutral"
            and type(result.selected.ir) == "table"
        then
            result.selected.ir.socialContext = result.selected.ir.socialContext or {}
            result.selected.ir.socialContext.playerTone = normalized.playerTone
            result.selected.ir.socialContext.playerRude = normalized.playerRude == true
            result.selected.ir.socialContext.playerShouting = normalized.playerShouting == true
            result.selected.ir.socialContext.playerPolite = normalized.playerPolite == true
        end
        if normalized.quantity ~= nil and type(result.selected.ir) == "table" then
            result.selected.ir.slots = result.selected.ir.slots or {}
            if result.selected.ir.slots.quantity == nil then
                result.selected.ir.slots.quantity = normalized.quantity
            end
        end
    elseif options.context ~= nil and FollowUp and type(FollowUp.Resolve) == "function" then
        local fuIR = FollowUp.Resolve(normalized, options.context)
        if type(fuIR) == "table" then
            local desc = {
                patternID = "core.followup." .. tostring(fuIR.slots and fuIR.slots.dialogueAct or "generic"),
                pass = "followup",
                score = fuIR.confidence or 0.82,
                confidence = fuIR.confidence or 0.82,
                selected = true,
                recovered = false,
                ir = fuIR,
            }
            result.candidates[#result.candidates + 1] = desc
            result.selected = desc
            result.selectedIndex = #result.candidates
            result.diagnostics.candidateCount = #result.candidates
            result.diagnostics.noMatch = false
            result.diagnostics.selectedPattern = desc.patternID
            result.diagnostics.selectedPass = "followup"
            result.diagnostics.selectedConfidence = desc.confidence
            result.diagnostics.ellipticalFollowUp = true
        end
    end
    result.diagnostics.playerTone = normalized.playerTone or "neutral"
    result.diagnostics.quantity = normalized.quantity
    if options._clauseCorePass ~= true then
        recordMissedTelemetry(text, nil, result)
    end
    if cacheKey then
        storeParseCache(cacheKey, IR.Clone(result))
    end
    return result
end

function Parser.RecognizeConcepts(text, options)
    local normalized = Normalizer.Normalize(text, options)
    local symbols = ConceptMatcher.Build(normalized, options)
    return ConceptMatcher.Analysis(normalized, symbols)
end

return Parser
