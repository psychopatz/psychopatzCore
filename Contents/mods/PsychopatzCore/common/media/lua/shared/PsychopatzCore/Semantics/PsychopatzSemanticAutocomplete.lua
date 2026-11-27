-- Schema-driven, confidence-scored predictive text & autocorrect for Kahlua2.
-- Piggybacks directly on Normalizer, ConceptMatcher, Registry patterns,
-- PatternMatcher rules, Parser.ParseCandidates, and Confidence — zero hardcoded
-- cue tables and zero split grammar. Any new mod pack or nested schema registered
-- with Semantics.Registry is automatically discovered and scored by real parser
-- confidence.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Semantics = PsychopatzCore.Semantics
local Registry = Semantics.Registry
    or require "PsychopatzCore/Semantics/PsychopatzSemanticRegistry"
local Normalizer = Semantics.Normalizer
    or require "PsychopatzCore/Semantics/PsychopatzSemanticNormalizer"
local ConceptMatcher = Semantics.ConceptMatcher
    or require "PsychopatzCore/Semantics/PsychopatzSemanticConceptMatcher"
local Rules = require "PsychopatzCore/Semantics/PsychopatzSemanticPatternMatcher_Rules"
local Fuzzy = Semantics.FuzzyMatcher
    or require "PsychopatzCore/Semantics/PsychopatzSemanticFuzzyMatcher"
local Parser = Semantics.Parser
    or require "PsychopatzCore/Semantics/PsychopatzSemanticParser"
local Confidence = Semantics.Confidence
    or require "PsychopatzCore/Semantics/PsychopatzSemanticConfidence"
local IntentClassifier = Semantics.IntentClassifier
    or require "PsychopatzCore/Semantics/PsychopatzSemanticIntentClassifier"

local Autocomplete = Semantics.Autocomplete or {}
Semantics.Autocomplete = Autocomplete

Autocomplete.VERSION = 2
Autocomplete.DEFAULT_LIMIT = 4
Autocomplete.MAX_LIMIT = 6
Autocomplete.MAX_PROPOSALS = 10
Autocomplete.MAX_INVENTORY_ITEMS = 32
Autocomplete.INVENTORY_CACHE_MS = 2000

-- Slot / capture names that denote item-like or actor-like dynamic fillers.
local ITEM_SLOT_NAMES = {
    item = true, object = true, gift = true, supply = true,
    food = true, weapon = true, medicine = true, resource = true,
}
local ITEM_ACTIONS = {
    GIVE = true, OFFER = true, FETCH = true, STORE = true,
    DROP = true, USE = true, TRADE = true,
}
local ACTOR_SLOT_NAMES = {
    recipient = true, actor = true, person = true, npc = true,
    ally = true, addressee = true,
}

local indexState = {
    rev = -1,
    datasetCount = -1,
    phrasesByP2 = {},
    wordsByP1 = {},
    knownWords = {},
}

local inventoryCache = {
    at = -99999,
    items = {},
}

local function trim(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function addPhrase(phrasesByP2, seenPhrases, raw)
    if type(raw) ~= "string" then return end
    local norm = Normalizer.NormalizePhrase(raw)
    if #norm < 3 or #norm > 48 or seenPhrases[norm] then return end
    seenPhrases[norm] = true
    local p2 = string.sub(norm, 1, 2)
    local bucket = phrasesByP2[p2]
    if not bucket then
        bucket = {}
        phrasesByP2[p2] = bucket
    end
    if #bucket < 96 then
        bucket[#bucket + 1] = norm
    end
end

local function addWord(wordsByP1, knownWords, raw)
    if type(raw) ~= "string" then return end
    local w = string.lower(trim(raw))
    if #w < 2 or #w > 24 or knownWords[w] then return end
    if not string.match(w, "^[%a][%a'%-]*$") then return end
    knownWords[w] = true
    local p1 = string.sub(w, 1, 1)
    local bucket = wordsByP1[p1]
    if not bucket then
        bucket = {}
        wordsByP1[p1] = bucket
    end
    if #bucket < 256 then
        bucket[#bucket + 1] = w
    end
end

local function ensureIndex()
    local rev = Registry.GetRevision and Registry.GetRevision() or 0
    local dsCount = IntentClassifier and IntentClassifier.DatasetOrder
        and #IntentClassifier.DatasetOrder or 0
    if indexState.rev == rev and indexState.datasetCount == dsCount then
        return indexState
    end

    local phrasesByP2 = {}
    local wordsByP1 = {}
    local knownWords = {}
    local seenPhrases = {}

    local patterns = Registry.GetPatterns and Registry.GetPatterns() or {}
    for i = 1, #patterns do
        local pat = patterns[i]
        if type(pat) == "table" and type(pat.match) == "table" then
            local allLit = true
            local parts = {}
            for j = 1, #pat.match do
                local r = Rules.normalizeRule(pat.match[j])
                if r and r.kind == "literal" and r.optional ~= true and r.capture == nil and r.value then
                    parts[#parts + 1] = r.value
                else
                    allLit = false
                    if r and r.kind == "literal" and r.value then
                        addWord(wordsByP1, knownWords, r.value)
                    end
                end
            end
            if allLit and #parts > 0 then
                local phrase = table.concat(parts, " ")
                addPhrase(phrasesByP2, seenPhrases, phrase)
                for j = 1, #parts do
                    addWord(wordsByP1, knownWords, parts[j])
                end
            end
        end
    end

    if IntentClassifier and type(IntentClassifier.Datasets) == "table" then
        for _, ds in pairs(IntentClassifier.Datasets) do
            if type(ds) == "table" and type(ds.exact) == "table" then
                for phrase, _ in pairs(ds.exact) do
                    addPhrase(phrasesByP2, seenPhrases, phrase)
                    for w in string.gmatch(phrase, "%S+") do
                        addWord(wordsByP1, knownWords, w)
                    end
                end
            end
        end
    end

    local concepts = Registry.Concepts or {}
    for _, def in pairs(concepts) do
        if type(def) == "table" and type(def.aliases) == "table" then
            for i = 1, #def.aliases do
                local alias = def.aliases[i]
                if type(alias) == "string" then
                    if string.find(alias, " ", 1, true) then
                        addPhrase(phrasesByP2, seenPhrases, alias)
                    else
                        addWord(wordsByP1, knownWords, alias)
                    end
                end
            end
        end
    end

    for _, bucket in pairs(phrasesByP2) do
        table.sort(bucket, function(a, b)
            if #a ~= #b then return #a < #b end
            return a < b
        end)
    end
    for _, bucket in pairs(wordsByP1) do
        table.sort(bucket, function(a, b)
            if #a ~= #b then return #a < #b end
            return a < b
        end)
    end

    indexState.rev = rev
    indexState.datasetCount = dsCount
    indexState.phrasesByP2 = phrasesByP2
    indexState.wordsByP1 = wordsByP1
    indexState.knownWords = knownWords
    return indexState
end

local function nowMs()
    if type(getTimeInMillis) == "function" then return tonumber(getTimeInMillis()) or 0 end
    if type(getTimestampMs) == "function" then return tonumber(getTimestampMs()) or 0 end
    return 0
end

local function collectLiveInventoryItems(player)
    local now = nowMs()
    if now > 0 and (now - inventoryCache.at) < Autocomplete.INVENTORY_CACHE_MS
        and #inventoryCache.items > 0
    then
        return inventoryCache.items
    end
    local p = player or (type(getSpecificPlayer) == "function" and getSpecificPlayer(0) or nil)
    if not p or type(p.getInventory) ~= "function" then return {} end
    local okInv, inv = pcall(p.getInventory, p)
    if not okInv or not inv or type(inv.getItems) ~= "function" then return {} end
    local okItems, list = pcall(inv.getItems, inv)
    if not okItems or not list or type(list.size) ~= "function" then return {} end
    local out = {}
    local seen = {}
    local size = math.min(tonumber(list:size()) or 0, 200)
    for i = 0, size - 1 do
        local item = list:get(i)
        if item then
            local name = (type(item.getDisplayName) == "function" and item:getDisplayName())
                or (type(item.getName) == "function" and item:getName())
                or nil
            if type(name) == "string" then
                name = trim(name)
                local key = string.lower(name)
                if name ~= "" and not seen[key] then
                    seen[key] = true
                    out[#out + 1] = name
                    if #out >= Autocomplete.MAX_INVENTORY_ITEMS then break end
                end
            end
        end
    end
    table.sort(out)
    inventoryCache.at = now
    inventoryCache.items = out
    return out
end

local function extractParticipantNames(participants)
    local out = {}
    local seen = {}
    if type(participants) ~= "table" then return out end
    local function add(v)
        if type(v) ~= "string" then return end
        local cleaned = trim(v)
        local key = string.lower(cleaned)
        if cleaned == "" or #cleaned < 2 or seen[key]
            or key == "stranger" or key == "unknown"
        then
            return
        end
        seen[key] = true
        out[#out + 1] = cleaned
    end
    for i = 1, #participants do
        local p = participants[i]
        if type(p) == "table" then
            add(p.firstName or p.forename)
            add(p.nickname)
            add(p.name or p.fullName)
            if type(p.name) == "string" then
                local first = string.match(p.name, "^(%S+)")
                if first then add(first) end
            end
        end
    end
    return out
end

-- Check if a pattern's leading rules match `prefixSymbols` and return the next
-- expected rule (skipping optional rules as needed). Completely schema-agnostic.
local function nextExpectedRule(pattern, prefixSymbols)
    local rawRules = type(pattern) == "table" and pattern.match or nil
    if type(rawRules) ~= "table" or #rawRules == 0 then return nil end
    local rIdx = 1
    local sIdx = 1
    while sIdx <= #prefixSymbols and rIdx <= #rawRules do
        local rule = Rules.normalizeRule(rawRules[rIdx])
        if not rule then return nil end
        if Rules.matchesRule(rule, prefixSymbols[sIdx]) then
            rIdx = rIdx + 1
            sIdx = sIdx + 1
        elseif rule.optional == true then
            rIdx = rIdx + 1
        else
            return nil
        end
    end
    if sIdx <= #prefixSymbols then return nil end
    -- Skip leading optional rules to surface the next meaningful expectation,
    -- returning both the first optional (if literal/concept) or the required rule.
    while rIdx <= #rawRules do
        local rule = Rules.normalizeRule(rawRules[rIdx])
        if rule then return rule end
        rIdx = rIdx + 1
    end
    return nil
end

local function ruleExpectsItem(rule, pattern)
    if type(rule) ~= "table" then return false end
    local cap = string.lower(tostring(rule.capture or ""))
    if ITEM_SLOT_NAMES[cap] then return true end
    local emit = type(pattern) == "table" and (pattern.emit or pattern.output) or nil
    local act = type(emit) == "table" and string.upper(tostring(emit.action or "")) or ""
    if (rule.kind == "any_phrase" or rule.kind == "any_concept" or rule.kind == "any")
        and ITEM_ACTIONS[act]
    then
        return true
    end
    return false
end

local function ruleExpectsActor(rule)
    if type(rule) ~= "table" then return false end
    local cap = string.lower(tostring(rule.capture or ""))
    return ACTOR_SLOT_NAMES[cap] == true
end

function Autocomplete.ResetCache()
    indexState.rev = -1
    indexState.datasetCount = -1
    inventoryCache.at = -99999
    inventoryCache.items = {}
    return true
end

-- Score a candidate completion using the real Parser.ParseCandidates + Confidence
-- pipeline so rankings reflect true semantic understanding and expose live
-- confidence diagnostics.
local function scoreWithParser(proposal, parseOptions)
    local bundle = Parser and type(Parser.ParseCandidates) == "function"
        and Parser.ParseCandidates(proposal.replacement, parseOptions)
        or nil
    local sel = type(bundle) == "table" and bundle.selected or nil
    local ir = type(sel) == "table" and sel.ir or nil
    local conf = sel and (tonumber(sel.confidence) or 0) or 0
    local band = Confidence and type(Confidence.Band) == "function"
        and Confidence.Band(conf) or "NONE"
    proposal.confidence = conf
    proposal.confidenceBand = band
    proposal.intent = ir and ir.intent or nil
    proposal.speechAct = ir and ir.speechAct or nil
    proposal.action = ir and ir.action or nil
    proposal.patternID = sel and sel.patternID or nil
    -- Real parser confidence is the primary rank signal; contextual prior breaks ties.
    proposal.rankScore = conf + (proposal.priorBoost or 0)
    return proposal
end

function Autocomplete.Suggest(rawText, options)
    options = type(options) == "table" and options or {}
    local raw = tostring(rawText or "")
    local trimmed = trim(raw)
    if trimmed == "" then return {} end

    local limit = math.max(1, math.min(
        Autocomplete.MAX_LIMIT,
        math.floor(tonumber(options.limit) or Autocomplete.DEFAULT_LIMIT)
    ))
    local idx = ensureIndex()
    local lowerTrimmed = string.lower(trimmed)
    local endsWithSpace = string.sub(raw, -1) == " "

    local headBeforeWord, lastWord = "", ""
    if endsWithSpace then
        headBeforeWord = raw
        lastWord = ""
    else
        local h, w = string.match(raw, "^(.-)(%S+)$")
        headBeforeWord = h or ""
        lastWord = string.lower(w or "")
    end

    local proposals = {}
    local seenReplacements = {}
    local function propose(label, replacement, kind, priorBoost)
        if #proposals >= Autocomplete.MAX_PROPOSALS then return end
        local cleanRep = trim(replacement)
        local key = string.lower(cleanRep)
        if key == "" or key == lowerTrimmed or seenReplacements[key] then return end
        seenReplacements[key] = true
        proposals[#proposals + 1] = {
            label = tostring(label),
            replacement = tostring(replacement),
            kind = kind,
            priorBoost = priorBoost or 0,
        }
    end

    -- 1) Schema-driven next-rule discovery from ALL registered Registry patterns!
    --    When the user has typed at least one completed token (`headBeforeWord`),
    --    ask the registered grammar what rule comes next (item slot, actor slot,
    --    concept, or literal) — zero hardcoded cue tables.
    local prefixTrimmed = trim(headBeforeWord)
    local expectsItemSlot = false
    local expectsActorSlot = false
    if prefixTrimmed ~= "" then
        local preNorm = Normalizer.Normalize(prefixTrimmed, options)
        local preSyms = ConceptMatcher.Build(preNorm, { enableFuzzy = false })
        local candPats = Registry.GetCandidatePatterns
            and Registry.GetCandidatePatterns(preSyms, preNorm)
            or Registry.GetPatterns()
        for i = 1, #candPats do
            local pat = candPats[i]
            local nextRule = nextExpectedRule(pat, preSyms)
            if nextRule then
                if ruleExpectsItem(nextRule, pat) then
                    expectsItemSlot = true
                elseif ruleExpectsActor(nextRule) then
                    expectsActorSlot = true
                elseif nextRule.kind == "literal" and nextRule.value then
                    local lit = nextRule.value
                    if lastWord == "" or (string.sub(lit, 1, #lastWord) == lastWord and lit ~= lastWord) then
                        propose(lit, headBeforeWord .. lit .. " ", "schema", 0.08)
                    end
                elseif nextRule.kind == "concept" and nextRule.id then
                    local cDef = Registry.GetConcept and Registry.GetConcept(nextRule.id) or nil
                    if type(cDef) == "table" and type(cDef.aliases) == "table" then
                        for j = 1, math.min(4, #cDef.aliases) do
                            local al = string.lower(tostring(cDef.aliases[j] or ""))
                            if al ~= "" and (lastWord == "" or (string.sub(al, 1, #lastWord) == lastWord and al ~= lastWord)) then
                                propose(al, headBeforeWord .. al, "schema", 0.06)
                            end
                        end
                    end
                end
            end
        end
    end

    -- 0) Active semantic beat/choice spoken utterances (actual spoken content
    -- like "I'm Patrick", never button labels like "Say your real name").
    if type(options.activeSuggestions) == "table" and #options.activeSuggestions > 0 then
        local editDist = Fuzzy and Fuzzy.EditDistance
        local probeClean = string.gsub(lowerTrimmed, "'", "")
        local lastClean = string.gsub(lastWord, "'", "")
        for i = 1, #options.activeSuggestions do
            local entry = options.activeSuggestions[i]
            local utterance = type(entry) == "table"
                and tostring(entry.utterance or entry.spokenText or "")
                or tostring(entry or "")
            utterance = trim(utterance)
            if utterance ~= "" then
                local ul = string.lower(utterance)
                local ulClean = string.gsub(ul, "'", "")
                if ul ~= lowerTrimmed and ulClean ~= probeClean then
                    if string.sub(ul, 1, #lowerTrimmed) == lowerTrimmed
                        or (#probeClean >= 2 and string.sub(ulClean, 1, #probeClean) == probeClean)
                    then
                        propose(utterance, utterance, "suggestion", 0.35)
                    elseif #lastClean >= 2 then
                        local matched = false
                        for w in string.gmatch(ulClean, "[%a%-]+") do
                            if string.sub(w, 1, #lastClean) == lastClean then
                                matched = true
                                break
                            elseif #lastClean >= 3 and type(editDist) == "function" then
                                local maxDist = (#lastClean >= 5 and #w >= 5) and 2 or 1
                                if math.abs(#w - #lastClean) <= maxDist then
                                    local d = editDist(lastClean, w, maxDist)
                                    if d and d <= maxDist then
                                        matched = true
                                        break
                                    end
                                end
                            end
                        end
                        if matched then
                            propose(utterance, utterance, "suggestion", 0.28)
                        end
                    end
                end
            end
        end
    end

    -- 2) If any matching schema expects an item/object slot, populate live inventory items!
    if expectsItemSlot then
        local items = type(options.inventoryItems) == "table"
            and options.inventoryItems
            or collectLiveInventoryItems(options.player)
        local editDist = Fuzzy and Fuzzy.EditDistance
        for i = 1, #items do
            local itemName = tostring(items[i] or "")
            local itemLower = string.lower(itemName)
            if lastWord == "" then
                propose(itemName, headBeforeWord .. itemLower, "inventory", 0.15)
            elseif string.sub(itemLower, 1, #lastWord) == lastWord then
                propose(itemName, headBeforeWord .. itemLower, "inventory", 0.18)
            elseif string.find(itemLower, lastWord, 1, true) then
                propose(itemName, headBeforeWord .. itemLower, "inventory", 0.14)
            elseif #lastWord >= 3 and type(editDist) == "function" then
                local firstW = string.match(itemLower, "^(%S+)") or itemLower
                local d = editDist(lastWord, firstW, 1)
                if d and d <= 1 then
                    propose(itemName, headBeforeWord .. itemLower, "inventory", 0.12)
                end
            end
        end
    end

    -- 3) Known conversation participant completion (when schema expects actor or trailing vocative)
    if (expectsActorSlot or #lastWord >= 2) and type(options.groupParticipants) == "table" then
        local names = extractParticipantNames(options.groupParticipants)
        local editDist = Fuzzy and Fuzzy.EditDistance
        for i = 1, #names do
            local name = names[i]
            local nl = string.lower(name)
            if lastWord == "" and expectsActorSlot then
                propose(name, headBeforeWord .. name .. " ", "participant", 0.12)
            elseif lastWord ~= "" and string.sub(nl, 1, #lastWord) == lastWord and nl ~= lastWord then
                propose(name, headBeforeWord .. name, "participant", 0.12)
            elseif #lastWord >= 3 and type(editDist) == "function" then
                local d = editDist(lastWord, nl, 1)
                if d and d == 1 then
                    propose(name, headBeforeWord .. name, "participant", 0.10)
                end
            end
        end
    end

    -- 4) Whole-phrase prefix completion from registered patterns & datasets
    if #lowerTrimmed >= 2 then
        local p2 = string.sub(lowerTrimmed, 1, 2)
        local bucket = idx.phrasesByP2[p2]
        if type(bucket) == "table" then
            local probe = endsWithSpace and (lowerTrimmed .. " ") or lowerTrimmed
            for i = 1, #bucket do
                local phrase = bucket[i]
                if string.sub(phrase, 1, #probe) == probe and phrase ~= lowerTrimmed then
                    propose(phrase, phrase, "phrase", 0.05)
                    if #proposals >= Autocomplete.MAX_PROPOSALS then break end
                end
            end
        end
    end

    -- 5) Damerau-Levenshtein typo autocorrect on unknown trailing word
    if lastWord ~= "" and #lastWord >= 3 and not idx.knownWords[lastWord]
        and Fuzzy and type(Fuzzy.EditDistance) == "function"
    then
        local p1 = string.sub(lastWord, 1, 1)
        local bucket = idx.wordsByP1[p1]
        if type(bucket) == "table" then
            local bestWord, bestDist = nil, 2
            for i = 1, #bucket do
                local cand = bucket[i]
                if math.abs(#cand - #lastWord) <= 1 then
                    local d = Fuzzy.EditDistance(lastWord, cand, 1)
                    if d and d < bestDist then
                        bestDist = d
                        bestWord = cand
                        if d == 1 then break end
                    end
                end
            end
            if bestWord then
                propose(bestWord, headBeforeWord .. bestWord .. " ", "autocorrect", 0.09)
            end
        end
    end

    -- 6) Word prefix fallback
    if lastWord ~= "" and #lastWord >= 2 and #proposals < Autocomplete.MAX_PROPOSALS then
        local p1 = string.sub(lastWord, 1, 1)
        local bucket = idx.wordsByP1[p1]
        if type(bucket) == "table" then
            for i = 1, #bucket do
                local cand = bucket[i]
                if string.sub(cand, 1, #lastWord) == lastWord and cand ~= lastWord then
                    propose(cand, headBeforeWord .. cand .. " ", "word", 0.02)
                    if #proposals >= Autocomplete.MAX_PROPOSALS then break end
                end
            end
        end
    end

    -- Score every proposal through the real Parser + Confidence engine!
    local parseOptions = {
        groupParticipants = options.groupParticipants,
        capabilities = options.capabilities,
        context = options.context,
        maxCandidates = 2,
        enableSurfaceRecovery = false,
    }
    for i = 1, #proposals do
        scoreWithParser(proposals[i], parseOptions)
    end

    table.sort(proposals, function(a, b)
        if math.abs((a.rankScore or 0) - (b.rankScore or 0)) > 0.001 then
            return (a.rankScore or 0) > (b.rankScore or 0)
        end
        if (a.confidence or 0) ~= (b.confidence or 0) then
            return (a.confidence or 0) > (b.confidence or 0)
        end
        return tostring(a.label) < tostring(b.label)
    end)

    local output = {}
    local seenLabels = {}
    for i = 1, #proposals do
        if #output >= limit then break end
        local p = proposals[i]
        local lk = string.lower(p.label)
        if not seenLabels[lk] then
            seenLabels[lk] = true
            output[#output + 1] = p
        end
    end
    return output
end

return Autocomplete
