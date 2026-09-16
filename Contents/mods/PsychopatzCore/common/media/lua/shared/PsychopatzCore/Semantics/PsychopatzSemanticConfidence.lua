PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Semantics = PsychopatzCore.Semantics
local Confidence = Semantics.Confidence or {}
Semantics.Confidence = Confidence

Confidence.DEFAULT_HIGH_THRESHOLD = 0.85
Confidence.DEFAULT_MEDIUM_THRESHOLD = 0.60

function Confidence.Clamp(value)
    value = tonumber(value) or 0
    if value < 0 then return 0 end
    if value > 1 then return 1 end
    return value
end

function Confidence.Band(value, thresholds)
    thresholds = type(thresholds) == "table" and thresholds or {}
    local high = tonumber(thresholds.high) or Confidence.DEFAULT_HIGH_THRESHOLD
    local medium = tonumber(thresholds.medium)
        or Confidence.DEFAULT_MEDIUM_THRESHOLD
    value = Confidence.Clamp(value)
    if value >= high then return "high" end
    if value >= medium then return "medium" end
    return "low"
end

function Confidence.Route(value, thresholds)
    local band = Confidence.Band(value, thresholds)
    if band == "high" then return "deterministic" end
    if band == "medium" then return "clarify_or_llm" end
    return "llm_fallback"
end

function Confidence.Score(pattern, match)
    pattern = type(pattern) == "table" and pattern or {}
    match = type(match) == "table" and match or {}

    local base = tonumber(pattern.confidence) or 0.70
    local coverageBonus = match.fullCoverage and 0.03 or 0
    local ambiguityPenalty = (tonumber(match.ambiguousCount) or 0) * 0.12
    local unresolvedPenalty = (tonumber(match.unresolvedCount) or 0) * 0.08
    local fuzzyPenalty = (tonumber(match.fuzzyCount) or 0) * 0.08
    local missingPenalty = (tonumber(match.missingCount) or 0) * 0.20
    local truncationPenalty = match.truncated and 0.20 or 0
    local score = Confidence.Clamp(
        base + coverageBonus - ambiguityPenalty - unresolvedPenalty
            - fuzzyPenalty - missingPenalty - truncationPenalty
    )

    return score, {
        base = base,
        coverageBonus = coverageBonus,
        ambiguityPenalty = ambiguityPenalty,
        unresolvedPenalty = unresolvedPenalty,
        fuzzyPenalty = fuzzyPenalty,
        missingPenalty = missingPenalty,
        truncationPenalty = truncationPenalty,
    }
end

return Confidence
