-- Modular Clause Pre-Parser: extracts structured audience scope (GROUP,
-- INDIVIDUAL, GROUP_EXCEPT) and strips natural-language modal / politeness
-- wrappers before pattern or verb-frame matching.
--
-- Data-driven and extensible: mods can register additional broadcast phrases,
-- modal prefixes, or trailing softeners without modifying parser logic.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local PreParser = PsychopatzCore.Semantics.ClausePreParser or {}
PsychopatzCore.Semantics.ClausePreParser = PreParser

PreParser.VERSION = 1

-- Ordered longest-first so multi-word phrases match before single words.
PreParser.BroadcastPhrases = PreParser.BroadcastPhrases or {
    "all of you guys",
    "every single one of you",
    "all of you",
    "both of you",
    "you all",
    "you guys",
    "y'all",
    "yall",
    "everyone",
    "everybody",
    "every one",
    "guys",
    "folks",
    "team",
    "squad",
    "crew",
    "people",
}

PreParser.ModalPrefixes = PreParser.ModalPrefixes or {
    { phrase = "i would like you to", modality = "polite" },
    { phrase = "i'd like you to",     modality = "polite" },
    { phrase = "i need you to",       modality = "imperative" },
    { phrase = "i want you to",       modality = "imperative" },
    { phrase = "would you please",    modality = "polite" },
    { phrase = "could you please",    modality = "polite" },
    { phrase = "can you please",      modality = "polite" },
    { phrase = "why don't you",       modality = "suggestion" },
    { phrase = "why dont you",        modality = "suggestion" },
    { phrase = "go ahead and",        modality = "suggestion" },
    { phrase = "you ought to",        modality = "suggestion" },
    { phrase = "you need to",         modality = "imperative" },
    { phrase = "you have to",         modality = "imperative" },
    { phrase = "you should",          modality = "suggestion" },
    { phrase = "you better",          modality = "suggestion" },
    { phrase = "would you",           modality = "polite" },
    { phrase = "could you",           modality = "polite" },
    { phrase = "can you",             modality = "polite" },
    { phrase = "will you",            modality = "polite" },
    { phrase = "ought to",            modality = "suggestion" },
    { phrase = "need to",             modality = "imperative" },
    { phrase = "have to",             modality = "imperative" },
    { phrase = "should",              modality = "suggestion" },
    { phrase = "better",              modality = "suggestion" },
    { phrase = "please",              modality = "polite" },
    { phrase = "just",                modality = "suggestion" },
    { phrase = "hey",                 modality = "imperative" },
    { phrase = "yo",                  modality = "imperative" },
    { phrase = "listen",              modality = "imperative" },
}

PreParser.TrailingModifiers = PreParser.TrailingModifiers or {
    "for a little while",
    "for a little bit",
    "for a minute",
    "for a second",
    "for a moment",
    "for a bit",
    "right now",
    "real quick",
    "for now",
    "please",
    "okay",
    "ok",
}

PreParser.NegationPrefixes = PreParser.NegationPrefixes or {
    "do not",
    "don't",
    "dont",
    "stop",
    "quit",
    "never",
    "no more",
}

local EXCLUSION_WORDS = { "except for", "except", "other than", "not", "but not" }

local function trim(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function escapePattern(s)
    return (tostring(s or ""):gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"))
end

local function cleanAlias(s)
    local out = string.lower(tostring(s or ""))
    out = out:gsub("[,!%?;:%.]+", " ")
    out = out:gsub("%s+", " ")
    return trim(out)
end

local function participantID(p)
    if type(p) ~= "table" then return nil end
    local id = p.id or p.npcID or p.entityID or p.actorID
    return id ~= nil and tostring(id) or nil
end

local function participantAliases(p)
    local out, seen = {}, {}
    local function add(v)
        local c = cleanAlias(v)
        if c ~= "" and #c >= 2 and not seen[c] then
            seen[c] = true
            out[#out + 1] = c
        end
    end
    add(p.fullName)
    add(p.name)
    add(p.nickname)
    add(p.forename)
    add(p.firstName)
    if type(p.name) == "string" then
        local first = string.match(p.name, "^(%S+)")
        if first then add(first) end
    end
    return out
end

-- Match one or more participant names at the start of `text`, separated by
-- "and" / "&" / "," (e.g. "Meghan and Rory, stay here" or "Meghan stay here").
local function matchLeadingParticipantList(raw, participants)
    if type(participants) ~= "table" or #participants == 0 then
        return nil, raw
    end
    local current = trim(raw)
    -- Strip optional "just" / "only" / "hey" / "yo" before a name
    local lead, afterLead = string.match(string.lower(current), "^(hey|yo|oi|just|only)%s+(.+)$")
    if lead and afterLead then
        local offset = #current - #afterLead + 1
        current = trim(string.sub(current, offset))
    end

    local matchedIDs = {}
    local matchedSet = {}
    local safety = 0
    while safety < 6 do
        safety = safety + 1
        local lowerCur = string.lower(current)
        local hitID, restRaw = nil, nil
        for i = 1, #participants do
            local p = participants[i]
            local pid = participantID(p)
            if pid then
                local aliases = participantAliases(p)
                for j = 1, #aliases do
                    local pat = escapePattern(aliases[j])
                    local rest = string.match(lowerCur, "^" .. pat .. "%s*[,:%-]+%s*(.*)$")
                        or string.match(lowerCur, "^" .. pat .. "%s+(.*)$")
                        or (lowerCur == aliases[j] and "" or nil)
                    if rest ~= nil then
                        hitID = pid
                        if rest == "" then
                            restRaw = ""
                        else
                            local offset = #current - #rest + 1
                            restRaw = trim(string.sub(current, offset))
                        end
                        break
                    end
                end
            end
            if hitID then break end
        end
        if not hitID then break end
        if not matchedSet[hitID] then
            matchedSet[hitID] = true
            matchedIDs[#matchedIDs + 1] = hitID
        end
        current = restRaw or ""
        -- Check for conjunction ("and" / "&") continuing the actor list
        local afterConj = string.match(string.lower(current), "^and%s+(.+)$")
            or string.match(string.lower(current), "^&%s*(.+)$")
        if afterConj then
            local offset = #current - #afterConj + 1
            current = trim(string.sub(current, offset))
        else
            break
        end
    end

    if #matchedIDs == 0 or trim(current) == "" then
        return nil, raw
    end
    return matchedIDs, trim(current)
end

local function matchBroadcastPrefix(raw)
    local lower = string.lower(raw)
    for i = 1, #PreParser.BroadcastPhrases do
        local phrase = PreParser.BroadcastPhrases[i]
        local pat = escapePattern(phrase)
        local rest = string.match(lower, "^%s*hey%s+" .. pat .. "%s*[,:%-]*%s*(.+)$")
            or string.match(lower, "^%s*" .. pat .. "%s*[,:%-]*%s*(.+)$")
        if rest and trim(rest) ~= "" then
            local offset = #raw - #rest + 1
            return true, trim(string.sub(raw, offset)), phrase
        end
        local head = string.match(lower, "^(.-)%s*[,:%-]+%s*" .. pat .. "%s*[!%?%.]*$")
        if head and trim(head) ~= "" then
            return true, trim(string.sub(raw, 1, #head)), phrase
        end
    end
    return false, raw, nil
end

local function matchExclusionAfterBroadcast(raw, participants)
    if type(participants) ~= "table" or #participants == 0 then
        return nil, raw
    end
    local lower = string.lower(raw)
    for i = 1, #EXCLUSION_WORDS do
        local exPat = escapePattern(EXCLUSION_WORDS[i])
        local afterEx = string.match(lower, "^%s*" .. exPat .. "%s+(.+)$")
        if afterEx and trim(afterEx) ~= "" then
            local offset = #raw - #afterEx + 1
            local candidate = trim(string.sub(raw, offset))
            local excludedIDs, remainder = matchLeadingParticipantList(candidate, participants)
            if excludedIDs and #excludedIDs > 0 and trim(remainder) ~= "" then
                return excludedIDs, remainder
            end
        end
    end
    return nil, raw
end

local function stripModals(raw)
    local current = trim(raw)
    local stripped = {}
    local modality = "imperative"
    local safety = 0
    while safety < 5 do
        safety = safety + 1
        local lower = string.lower(current)
        local matched = false
        for i = 1, #PreParser.ModalPrefixes do
            local entry = PreParser.ModalPrefixes[i]
            local pat = escapePattern(entry.phrase)
            local rest = string.match(lower, "^" .. pat .. "%s*[,:%-]*%s+(.+)$")
            if rest and trim(rest) ~= "" then
                local offset = #current - #rest + 1
                current = trim(string.sub(current, offset))
                stripped[#stripped + 1] = entry.phrase
                if entry.modality == "suggestion" or entry.modality == "polite" then
                    modality = entry.modality
                end
                matched = true
                break
            end
        end
        if not matched then break end
    end
    return current, modality, stripped
end

local function stripTrailingModifiers(raw)
    local current = trim(raw)
    -- Preserve trailing question/exclamation? Keep core clean for verb matching.
    current = current:gsub("[!%.]+$", "")
    current = trim(current)
    local stripped = {}
    local safety = 0
    while safety < 3 do
        safety = safety + 1
        local lower = string.lower(current)
        local matched = false
        for i = 1, #PreParser.TrailingModifiers do
            local phrase = PreParser.TrailingModifiers[i]
            local pat = escapePattern(phrase)
            local head = string.match(lower, "^(.-)%s*[,]*%s+" .. pat .. "%s*$")
            if head and trim(head) ~= "" then
                current = trim(string.sub(current, 1, #head))
                stripped[#stripped + 1] = phrase
                matched = true
                break
            end
        end
        if not matched then break end
    end
    return current, stripped
end

local function stripNegation(raw)
    local current = trim(raw)
    local lower = string.lower(current)
    for i = 1, #PreParser.NegationPrefixes do
        local phrase = PreParser.NegationPrefixes[i]
        local pat = escapePattern(phrase)
        local rest = string.match(lower, "^" .. pat .. "%s+(.+)$")
        if rest and trim(rest) ~= "" then
            local offset = #current - #rest + 1
            return trim(string.sub(current, offset)), true, phrase
        end
    end
    return current, false, nil
end

function PreParser.RegisterNegationPrefix(phrase)
    local c = cleanAlias(phrase)
    if c == "" then return false end
    for i = 1, #PreParser.NegationPrefixes do
        if PreParser.NegationPrefixes[i] == c then return true end
    end
    table.insert(PreParser.NegationPrefixes, 1, c)
    return true
end

function PreParser.RegisterBroadcastPhrase(phrase)
    local c = cleanAlias(phrase)
    if c == "" then return false end
    for i = 1, #PreParser.BroadcastPhrases do
        if PreParser.BroadcastPhrases[i] == c then return true end
    end
    table.insert(PreParser.BroadcastPhrases, 1, c)
    return true
end

function PreParser.RegisterModalPrefix(phrase, modality)
    local c = cleanAlias(phrase)
    if c == "" then return false end
    table.insert(PreParser.ModalPrefixes, 1, {
        phrase = c,
        modality = tostring(modality or "suggestion"),
    })
    return true
end

function PreParser.Analyze(text, participants)
    local raw = trim(text)
    if raw == "" then
        return {
            rawText = raw,
            coreText = raw,
            audienceScope = { scope = "DEFAULT" },
            modality = "imperative",
            strippedModals = {},
            strippedTrailing = {},
            changed = false,
        }
    end

    local working = raw
    local audienceScope = { scope = "DEFAULT" }

    -- 1) Detect group broadcast ("you all", "everyone", ...) and optional exclusion ("except Meghan")
    local isBroadcast, afterBroadcast, bPhrase = matchBroadcastPrefix(working)
    if isBroadcast then
        working = afterBroadcast
        local excludedIDs, afterExclude = matchExclusionAfterBroadcast(working, participants)
        if excludedIDs and #excludedIDs > 0 then
            working = afterExclude
            audienceScope = {
                scope = "GROUP_EXCEPT",
                excludeIDs = excludedIDs,
                matchedPhrase = bPhrase,
            }
        else
            audienceScope = {
                scope = "GROUP",
                matchedPhrase = bPhrase,
            }
        end
    else
        -- 2) Detect named individual / subset addressing ("Meghan, ...", "Meghan and Rory, ...")
        local targetIDs, afterNames = matchLeadingParticipantList(working, participants)
        if targetIDs and #targetIDs > 0 then
            working = afterNames
            audienceScope = {
                scope = "INDIVIDUAL",
                targetIDs = targetIDs,
            }
        end
    end

    -- 3) Strip modal/politeness wrappers ("should", "could you", "please", "go ahead and", ...)
    local afterModals, modality, strippedModals = stripModals(working)
    -- 4) Detect leading negation ("don't", "do not", "stop", "never", ...)
    local afterNeg, negated, negationCue = stripNegation(afterModals)
    -- 5) Strip trailing softeners ("for a bit", "please", "right now", ...)
    local coreText, strippedTrailing = stripTrailingModifiers(afterNeg)

    return {
        rawText = raw,
        coreText = coreText ~= "" and coreText or raw,
        audienceScope = audienceScope,
        modality = modality,
        negated = negated == true,
        polarity = negated == true and "negative" or "positive",
        negationCue = negationCue,
        strippedModals = strippedModals,
        strippedTrailing = strippedTrailing,
        changed = (string.lower(coreText) ~= string.lower(raw))
            or audienceScope.scope ~= "DEFAULT"
            or negated == true,
    }
end

return PreParser
