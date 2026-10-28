PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Semantics = PsychopatzCore.Semantics
local Normalizer = Semantics.Normalizer
    or require "PsychopatzCore/Semantics/PsychopatzSemanticNormalizer"
local Registry = Semantics.Registry
    or require "PsychopatzCore/Semantics/PsychopatzSemanticRegistry"

local Recovery = Semantics.SurfaceRecovery or {}
Semantics.SurfaceRecovery = Recovery

Recovery.VERSION = 1
Recovery.MAX_VARIANTS = 8
Recovery.MAX_SEGMENTS = 4
Recovery.MAX_SEGMENTATIONS = 4
Recovery.MIN_SEGMENTED_LENGTH = 6
Recovery.Revision = -1
Recovery.CompactAliases = {}
Recovery.SingleTokens = {}

Recovery.COSTS = {
    contraction = 0.04,
    compact_alias = 0.05,
    elongation = 0.07,
    elongated_compact_alias = 0.09,
    segmentation = 0.12,
}

local CONTRACTIONS = {
    im = "i'm",
    ive = "i've",
    id = "i'd",
    ill = "i'll",
    youre = "you're",
    youve = "you've",
    youll = "you'll",
    youd = "you'd",
    hes = "he's",
    shes = "she's",
    theyre = "they're",
    were = "we're",
    dont = "don't",
    doesnt = "doesn't",
    didnt = "didn't",
    cant = "can't",
    couldnt = "couldn't",
    wont = "won't",
    wouldnt = "wouldn't",
    isnt = "isn't",
    arent = "aren't",
    wasnt = "wasn't",
    werent = "weren't",
    havent = "haven't",
    hasnt = "hasn't",
    hadnt = "hadn't",
}

local function copyArray(source)
    local output = {}
    for index = 1, #(source or {}) do output[index] = source[index] end
    return output
end

local function splitWords(value)
    local output = {}
    for token in string.gmatch(tostring(value or ""), "%S+") do
        output[#output + 1] = token
    end
    return output
end

local function tokenCount(value)
    local count = 0
    for _ in string.gmatch(tostring(value or ""), "%S+") do
        count = count + 1
    end
    return count
end

local function compactKey(value)
    local normalized = Normalizer.NormalizePhrase(value)
    normalized = string.gsub(normalized, "%s+", "")
    normalized = string.gsub(normalized, "'", "")
    normalized = string.gsub(normalized, "%-", "")
    return normalized
end

local function addCompact(index, key, entry)
    if key == "" then return end
    local bucket = index[key] or {}
    local signature = tostring(entry.phrase) .. "\0" .. tostring(entry.id)
    for _, existing in ipairs(bucket) do
        if existing.signature == signature then return end
    end
    entry.signature = signature
    bucket[#bucket + 1] = entry
    table.sort(bucket, function(left, right)
        if left.priority ~= right.priority then
            return left.priority > right.priority
        end
        if left.phrase ~= right.phrase then return left.phrase < right.phrase end
        return tostring(left.id) < tostring(right.id)
    end)
    index[key] = bucket
end

local function rebuild()
    local compact = {}
    local singles = {}
    for _, conceptID in ipairs(Registry.ListConcepts()) do
        local concept = Registry.GetConcept(conceptID)
        if type(concept) == "table" then
            for _, alias in ipairs(concept.aliases or {}) do
                local normalized = Normalizer.NormalizePhrase(alias)
                local count = tokenCount(normalized)
                local entry = {
                    phrase = normalized,
                    id = concept.id,
                    priority = tonumber(concept.priority) or 0,
                    tokenCount = count,
                }
                if count >= 2 or string.find(normalized, "'", 1, true) then
                    addCompact(compact, compactKey(normalized), entry)
                end
                if count == 1 and #normalized >= 1 then
                    local bucket = singles[normalized] or {}
                    bucket[#bucket + 1] = entry
                    singles[normalized] = bucket
                end
            end
        end
    end
    Recovery.CompactAliases = compact
    Recovery.SingleTokens = singles
    Recovery.Revision = Registry.GetRevision()
end

local function ensureIndex()
    if Recovery.Revision ~= Registry.GetRevision() then rebuild() end
end

function Recovery.Rebuild()
    rebuild()
    return Recovery.Revision
end

local function collapseRuns(value, maximumRun)
    value = tostring(value or "")
    local output = {}
    local index = 1
    while index <= #value do
        local char = string.sub(value, index, index)
        local ending = index
        while ending + 1 <= #value
            and string.sub(value, ending + 1, ending + 1) == char
        do
            ending = ending + 1
        end
        local runLength = ending - index + 1
        local keep = runLength
        -- Treat only expressive runs of 3+ as elongation. Natural doubles
        -- such as the "ll" in "hello" are preserved.
        if runLength >= 3 then keep = math.min(runLength, maximumRun) end
        for _ = 1, keep do output[#output + 1] = char end
        index = ending + 1
    end
    return table.concat(output)
end

local function knownSingleToken(value)
    return type(Recovery.SingleTokens[value]) == "table"
        and #Recovery.SingleTokens[value] > 0
end

local function segmentToken(value)
    if #value < Recovery.MIN_SEGMENTED_LENGTH then return {} end

    local results = {}
    local function walk(offset, segments)
        if #results >= Recovery.MAX_SEGMENTATIONS then return end
        if offset > #value then
            if #segments >= 2 and #segments <= Recovery.MAX_SEGMENTS then
                results[#results + 1] = table.concat(segments, " ")
            end
            return
        end
        if #segments >= Recovery.MAX_SEGMENTS then return end

        -- Longer semantic vocabulary wins first; this also bounds branching.
        for ending = #value, offset, -1 do
            local piece = string.sub(value, offset, ending)
            if knownSingleToken(piece) then
                segments[#segments + 1] = piece
                walk(ending + 1, segments)
                segments[#segments] = nil
                if #results >= Recovery.MAX_SEGMENTATIONS then return end
            end
        end
    end

    walk(1, {})
    table.sort(results)
    return results
end

local function appendAlternative(output, seen, spec)
    local surface = Normalizer.NormalizePhrase(spec.surface)
    if surface == "" or seen[surface] then return end
    seen[surface] = true
    spec.surface = surface
    output[#output + 1] = spec
end

local function compactAlternatives(token, kind, cost)
    ensureIndex()
    local output = {}
    local key = compactKey(token)
    local bucket = Recovery.CompactAliases[key] or {}
    for _, entry in ipairs(bucket) do
        output[#output + 1] = {
            surface = entry.phrase,
            kind = kind,
            cost = cost,
            conceptID = entry.id,
            sourceAlias = entry.phrase,
        }
    end
    return output
end

local function tokenAlternatives(token)
    ensureIndex()
    local output = {}
    local seen = {}

    local contraction = CONTRACTIONS[token]
    if contraction then
        appendAlternative(output, seen, {
            surface = contraction,
            kind = "contraction",
            cost = Recovery.COSTS.contraction,
        })
    end

    for _, alternative in ipairs(compactAlternatives(
        token, "compact_alias", Recovery.COSTS.compact_alias
    )) do
        appendAlternative(output, seen, alternative)
    end

    local collapsedOne = collapseRuns(token, 1)
    local collapsedTwo = collapseRuns(token, 2)
    for _, collapsed in ipairs({ collapsedOne, collapsedTwo }) do
        if collapsed ~= token then
            appendAlternative(output, seen, {
                surface = collapsed,
                kind = "elongation",
                cost = Recovery.COSTS.elongation,
            })
            for _, alternative in ipairs(compactAlternatives(
                collapsed,
                "elongated_compact_alias",
                Recovery.COSTS.elongated_compact_alias
            )) do
                appendAlternative(output, seen, alternative)
            end
        end
    end

    if #output == 0 then
        local segmentations = segmentToken(token)
        -- Segmentation is accepted only when there is one deterministic
        -- vocabulary decomposition. Ambiguous decompositions remain unknown.
        if #segmentations == 1 then
            appendAlternative(output, seen, {
                surface = segmentations[1],
                kind = "segmentation",
                cost = Recovery.COSTS.segmentation,
            })
        end
    end

    table.sort(output, function(left, right)
        if left.cost ~= right.cost then return left.cost < right.cost end
        if left.kind ~= right.kind then return left.kind < right.kind end
        return left.surface < right.surface
    end)
    return output
end

local function recoveredNormalized(original, tokenIndex, alternative)
    local tokens = {}
    for index = 1, #(original.tokens or {}) do
        if index == tokenIndex then
            for _, word in ipairs(splitWords(alternative.surface)) do
                tokens[#tokens + 1] = word
            end
        else
            tokens[#tokens + 1] = original.tokens[index]
        end
    end
    return {
        rawText = original.rawText,
        normalizedText = table.concat(tokens, " "),
        tokens = tokens,
        truncated = original.truncated == true,
    }
end

function Recovery.Generate(normalized, options)
    options = type(options) == "table" and options or {}
    if options.enableSurfaceRecovery == false then return {} end
    ensureIndex()

    local maximum = math.floor(
        tonumber(options.maxRecoveryVariants) or Recovery.MAX_VARIANTS
    )
    if maximum < 1 then return {} end
    if maximum > Recovery.MAX_VARIANTS then maximum = Recovery.MAX_VARIANTS end

    local output = {}
    local seen = {}
    for tokenIndex = 1, #(normalized.tokens or {}) do
        local token = normalized.tokens[tokenIndex]
        for _, alternative in ipairs(tokenAlternatives(token)) do
            local recovered = recoveredNormalized(
                normalized, tokenIndex, alternative
            )
            if recovered.normalizedText ~= normalized.normalizedText
                and not seen[recovered.normalizedText]
            then
                seen[recovered.normalizedText] = true
                output[#output + 1] = {
                    kind = alternative.kind,
                    cost = alternative.cost,
                    originalNormalizedText = normalized.normalizedText,
                    recoveredNormalizedText = recovered.normalizedText,
                    tokenIndex = tokenIndex,
                    originalToken = token,
                    recoveredSurface = alternative.surface,
                    conceptID = alternative.conceptID,
                    sourceAlias = alternative.sourceAlias,
                    normalized = recovered,
                    mutationSafe = false,
                }
                if #output >= maximum then return output end
            end
        end
    end
    return output
end

Recovery.Rebuild()

return Recovery
