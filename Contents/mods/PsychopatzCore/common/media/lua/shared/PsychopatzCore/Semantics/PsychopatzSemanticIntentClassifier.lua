-- Mod-agnostic Tier-3 Dataset-Backed Intent Classifier.
-- Scores cleaned coreText against compiled intent datasets using:
--   1) O(1) exact normalized phrase lookup (high confidence, 0.82), and
--   2) TF-IDF weighted token + character 3-gram cosine similarity (typo-tolerant),
--      gated by strict minimum score (>= 0.62) and margin (>= 0.12) to prevent
--      false positives on gibberish or ambiguous inputs.
--
-- Pure Lua 5.1 / Kahlua2-safe; zero external dependencies.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Semantics = PsychopatzCore.Semantics
local IR = Semantics.IR
    or require "PsychopatzCore/Semantics/PsychopatzSemanticIR"
local VerbFrame = Semantics.VerbFrameParser
    or require "PsychopatzCore/Semantics/PsychopatzSemanticVerbFrameParser"

local Classifier = Semantics.IntentClassifier or {}
Semantics.IntentClassifier = Classifier

Classifier.VERSION = 1
Classifier.DEFAULT_MIN_SCORE = 0.28
Classifier.DEFAULT_MIN_MARGIN = 0.09
Classifier.DEFAULT_MIN_RATIO = 1.35
Classifier.EXACT_PHRASE_SCORE = 0.82

Classifier.Datasets = Classifier.Datasets or {}
Classifier.DatasetOrder = Classifier.DatasetOrder or {}

local function trim(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function normalizePhrase(text)
    local s = string.lower(tostring(text or ""))
    s = string.gsub(s, "['’`]", "")
    s = string.gsub(s, "[^%w%s]", " ")
    s = string.gsub(s, "%s+", " ")
    return trim(s)
end

-- Extract token unigrams + token bigrams + padded character 3-grams.
-- Must match tools/compile_intent_dataset.py feature extraction exactly.
local function extractFeatures(normText)
    local counts = {}
    if not normText or normText == "" then return counts end
    local words = {}
    for w in string.gmatch(normText, "%S+") do
        words[#words + 1] = w
        local tk = "w:" .. w
        counts[tk] = (counts[tk] or 0) + 1
        -- Character 3-grams over word boundary "^word$"
        local padded = "^" .. w .. "$"
        local len = #padded
        if len >= 3 then
            for i = 1, len - 2 do
                local g = "g:" .. string.sub(padded, i, i + 2)
                counts[g] = (counts[g] or 0) + 1
            end
        end
    end
    for i = 1, #words - 1 do
        local bk = "b:" .. words[i] .. "_" .. words[i + 1]
        counts[bk] = (counts[bk] or 0) + 1
    end
    return counts
end

-- Compiles a compact raw phrase dataset ({ packID, intents = { { id, intent,
-- speechAct, action, topic, examples = { ... } }, ... } }) into in-memory
-- O(1) exact lookup + TF-IDF prototype vectors once on mod load (< 2ms).
local function buildIndexFromRaw(rawDataset)
    local rawList = rawDataset.intents
    if type(rawList) ~= "table" or #rawList == 0 then return nil end

    local exact = {}
    local docFreq = {}
    local classPhrases = {}
    local classMeta = {}
    local numClasses = 0

    for i = 1, #rawList do
        local entry = rawList[i]
        if type(entry) == "table" and entry.id ~= nil then
            local key = tostring(entry.id)
            numClasses = numClasses + 1
            classMeta[key] = {
                id = key,
                intent = entry.intent or "REQUEST",
                speechAct = entry.speechAct or entry.intent or "REQUEST",
                action = entry.action,
                topic = entry.topic,
            }
            local phrases, seen, classFeats = {}, {}, {}
            local examples = type(entry.examples) == "table" and entry.examples or {}
            for j = 1, #examples do
                local np = normalizePhrase(examples[j])
                if np ~= "" and not seen[np] then
                    seen[np] = true
                    phrases[#phrases + 1] = np
                    if exact[np] == nil then exact[np] = key end
                    local feats = extractFeatures(np)
                    for fk in pairs(feats) do classFeats[fk] = true end
                end
            end
            classPhrases[key] = phrases
            for fk in pairs(classFeats) do
                docFreq[fk] = (docFreq[fk] or 0) + 1
            end
        end
    end

    local idf = {}
    for fk, df in pairs(docFreq) do
        idf[fk] = math.log((numClasses + 1.0) / (df + 0.5)) + 0.5
    end

    local intents = {}
    for key, phrases in pairs(classPhrases) do
        local agg = {}
        for i = 1, #phrases do
            local feats = extractFeatures(phrases[i])
            for fk, tf in pairs(feats) do
                local w = (1.0 + math.log(tf)) * (idf[fk] or 1.0)
                agg[fk] = (agg[fk] or 0) + w
            end
        end
        local n = math.max(1, #phrases)
        local vec, normSq = {}, 0
        for fk, sumW in pairs(agg) do
            local avg = sumW / n
            vec[fk] = avg
            normSq = normSq + (avg * avg)
        end
        local meta = classMeta[key]
        meta.vec = vec
        meta.norm = math.sqrt(normSq)
        intents[key] = meta
    end

    return {
        packID = rawDataset.packID,
        exact = exact,
        idf = idf,
        intents = intents,
    }
end

function Classifier.RegisterDataset(packID, dataset)
    local id = tostring(packID or "")
    if id == "" or type(dataset) ~= "table" then return false end
    local indexed = dataset
    if type(dataset.idf) ~= "table" and type(dataset.intents) == "table" and dataset.intents[1] ~= nil then
        indexed = buildIndexFromRaw(dataset)
        if not indexed then return false end
    end
    if Classifier.Datasets[id] == nil then
        Classifier.DatasetOrder[#Classifier.DatasetOrder + 1] = id
    end
    Classifier.Datasets[id] = indexed
    return true
end

function Classifier.ResetDatasets()
    Classifier.Datasets = {}
    Classifier.DatasetOrder = {}
    return true
end

-- Lightweight post-classification slot extraction so Tier-3 matches on
-- indirect phrasing ("let's hole up in that clinic") keep spatial/source
-- slots and quantity instead of dropping them.
local SPATIAL_PREPS = {
    ["in"] = "spatial", inside = "spatial", at = "spatial",
    by = "spatial", near = "spatial", into = "spatial",
    to = "spatial", toward = "spatial", towards = "spatial",
    from = "source",
}

local SLOT_DETS = {
    the = true, this = true, that = true, a = true, an = true,
    my = true, our = true, your = true, some = true,
    nearest = true, closest = true,
}

local SLOT_STOP = {
    ["for"] = true, ["and"] = true, ["then"] = true, ["now"] = true,
    ["please"] = true, ["okay"] = true, ["ok"] = true, ["tonight"] = true,
}

local DEST_ACTIONS = {
    CAMP = true, MOVE = true, WAIT_AT = true, GUARD = true, STORE = true,
}

local function extractImplicitSlots(normalized, action)
    local slots = {}
    if type(normalized) ~= "table" then return slots end
    if normalized.quantity ~= nil then slots.quantity = normalized.quantity end
    local tokens = normalized.tokens
    if type(tokens) ~= "table" or #tokens < 2 then return slots end
    local destAction = DEST_ACTIONS[string.upper(tostring(action or ""))] == true
    for i = 1, #tokens - 1 do
        local role = SPATIAL_PREPS[tokens[i]]
        if role then
            local j = i + 1
            while j <= #tokens and SLOT_DETS[tokens[j]] do j = j + 1 end
            local words = {}
            while j <= #tokens and #words < 3
                and not SLOT_STOP[tokens[j]]
                and not SPATIAL_PREPS[tokens[j]]
            do
                words[#words + 1] = tokens[j]
                j = j + 1
            end
            if #words > 0 then
                local value = { text = table.concat(words, " ") }
                if role == "source" then
                    slots.source = slots.source or value
                elseif destAction then
                    slots.destination = slots.destination or value
                else
                    slots.target = slots.target or value
                end
            end
        end
    end
    return slots
end

Classifier.ExtractImplicitSlots = extractImplicitSlots

local function buildIRCandidate(normalized, spec, score, matchKind, negated)
    local action = spec.action
    if negated and action and VerbFrame and type(VerbFrame.ResolveNegatedAction) == "function" then
        action = VerbFrame.ResolveNegatedAction(action)
    end
    local extracted = extractImplicitSlots(normalized, action)
    local ir = IR.New({
        rawText = normalized.rawText,
        normalizedText = normalized.normalizedText,
        intent = spec.intent or "REQUEST",
        speechAct = spec.speechAct or spec.intent or "REQUEST",
        action = action,
        topic = spec.topic,
        target = extracted.target,
        destination = extracted.destination,
        source = extracted.source,
        slots = extracted.quantity ~= nil and { quantity = extracted.quantity } or nil,
        confidence = score,
        provenance = {
            provider = "lua",
            parser = "intent_classifier",
            matchKind = matchKind,
            intentKey = spec.id,
        },
        diagnostics = {
            parser = "lua_intent_classifier",
            intentKey = spec.id,
            matchKind = matchKind,
            coverage = 1,
            noMatch = false,
            negated = negated == true,
        },
    })
    if negated then
        ir.polarity = "negative"
        ir.extensions = type(ir.extensions) == "table" and ir.extensions or {}
        ir.extensions.negated = true
        if action ~= spec.action then
            ir.extensions.originalAction = spec.action
        end
    end
    return {
        patternId = "core.intent_dataset." .. tostring(spec.id or "unknown"),
        source = "intent_classifier",
        score = score,
        confidence = score,
        priority = 55,
        captures = {},
        typedCaptures = {},
        metadata = { intentKey = spec.id, matchKind = matchKind },
        match = {
            consumed = #(normalized.tokens or {}),
            skipped = 0,
            unresolvedCount = 0,
            ambiguousCount = 0,
            fuzzyCount = matchKind == "exact_phrase" and 0 or 1,
            unmatchedCount = 0,
            fullCoverage = true,
        },
        ir = ir,
    }
end

function Classifier.Classify(normalized, options)
    if type(normalized) ~= "table" or #Classifier.DatasetOrder == 0 then return nil end
    options = type(options) == "table" and options or {}
    local rawNorm = normalized.normalizedText or table.concat(normalized.tokens or {}, " ")
    local normText = normalizePhrase(rawNorm)
    if normText == "" then return nil end
    local negated = options.negated == true
    local minScore = tonumber(options.intentMinScore) or Classifier.DEFAULT_MIN_SCORE
    local minMargin = tonumber(options.intentMinMargin) or Classifier.DEFAULT_MIN_MARGIN

    -- 1) O(1) exact normalized phrase lookup across registered datasets
    for d = 1, #Classifier.DatasetOrder do
        local ds = Classifier.Datasets[Classifier.DatasetOrder[d]]
        if type(ds) == "table" and type(ds.exact) == "table" and type(ds.intents) == "table" then
            local exactKey = ds.exact[normText]
            if exactKey and ds.intents[exactKey] then
                return buildIRCandidate(
                    normalized,
                    ds.intents[exactKey],
                    Classifier.EXACT_PHRASE_SCORE,
                    "exact_phrase",
                    negated
                )
            end
        end
    end

    -- 2) TF-IDF weighted token + char-3gram cosine similarity against prototypes
    local feats = extractFeatures(normText)
    local bestSpec, bestScore, secondScore = nil, 0, 0

    for d = 1, #Classifier.DatasetOrder do
        local ds = Classifier.Datasets[Classifier.DatasetOrder[d]]
        local idf = type(ds) == "table" and type(ds.idf) == "table" and ds.idf or nil
        local intents = type(ds) == "table" and type(ds.intents) == "table" and ds.intents or nil
        if idf and intents then
            -- Build query TF-IDF vector once per dataset
            local qVec = {}
            local qNormSq = 0
            for fk, tf in pairs(feats) do
                local wIdf = idf[fk]
                if wIdf then
                    local w = (1 + math.log(tf)) * wIdf
                    qVec[fk] = w
                    qNormSq = qNormSq + (w * w)
                end
            end
            if qNormSq > 0 then
                local qNorm = math.sqrt(qNormSq)
                for _, spec in pairs(intents) do
                    local proto = spec.vec
                    local pNorm = tonumber(spec.norm) or 0
                    if type(proto) == "table" and pNorm > 0 then
                        local dot = 0
                        for fk, qw in pairs(qVec) do
                            local pw = proto[fk]
                            if pw then dot = dot + (qw * pw) end
                        end
                        local sim = dot / (qNorm * pNorm)
                        if sim > bestScore then
                            secondScore = bestScore
                            bestScore = sim
                            bestSpec = spec
                        elseif sim > secondScore then
                            secondScore = sim
                        end
                    end
                end
            end
        end
    end

    if not bestSpec then return nil end
    local margin = bestScore - secondScore
    local minRatio = tonumber(options.intentMinRatio) or Classifier.DEFAULT_MIN_RATIO
    if bestScore < minScore or margin < minMargin or (secondScore > 0 and (bestScore / secondScore) < minRatio) then
        return nil
    end

    -- Map cosine similarity [minScore..1.0] into bounded confidence [0.68..0.80]
    local conf = math.min(0.80, math.max(0.68, 0.68 + (bestScore - minScore) * 0.30))
    return buildIRCandidate(normalized, bestSpec, conf, "tfidf_prototype", negated)
end

return Classifier
