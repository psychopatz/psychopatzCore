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
    { phrase = "could we",            modality = "polite" },
    { phrase = "can we",              modality = "polite" },
    { phrase = "should we",           modality = "suggestion" },
    { phrase = "shall we",            modality = "suggestion" },
    { phrase = "we should",           modality = "suggestion" },
    { phrase = "we need to",          modality = "imperative" },
    { phrase = "we have to",          modality = "imperative" },
    { phrase = "ought to",            modality = "suggestion" },
    { phrase = "need to",             modality = "imperative" },
    { phrase = "have to",             modality = "imperative" },
    { phrase = "should",              modality = "suggestion" },
    { phrase = "better",              modality = "suggestion" },
    { phrase = "please",              modality = "polite" },
    { phrase = "let us",              modality = "suggestion" },
    { phrase = "let's",               modality = "suggestion" },
    { phrase = "lets",                modality = "suggestion" },
    { phrase = "just",                modality = "suggestion" },
    { phrase = "all right",           modality = "imperative" },
    { phrase = "alright",             modality = "imperative" },
    { phrase = "okay",                modality = "imperative" },
    { phrase = "ok",                  modality = "imperative" },
    { phrase = "well",                modality = "suggestion" },
    { phrase = "so",                  modality = "suggestion" },
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
    "i do not want you to",
    "i don't want you to",
    "i dont want you to",
    "i do not need you to",
    "i don't need you to",
    "i dont need you to",
    "you do not need to",
    "you don't need to",
    "you dont need to",
    "you do not have to",
    "you don't have to",
    "you dont have to",
    "there is no need to",
    "i do not want to",
    "i don't want to",
    "i dont want to",
    "do not need to",
    "don't need to",
    "dont need to",
    "do not have to",
    "don't have to",
    "dont have to",
    "no need to",
    "do not",
    "don't",
    "dont",
    "stop",
    "quit",
    "never",
    "no more",
}

PreParser.GenericVocatives = PreParser.GenericVocatives or {
    "man",
    "dude",
    "bro",
    "mate",
    "pal",
    "buddy",
    "friend",
    "partner",
    "boss",
    "chief",
}

local EXCLUSION_WORDS = { "except for", "except", "other than", "not", "but not" }

-- Words that typically take a following person name as a grammatical object,
-- predicate, or coordinate rather than an unpunctuated trailing vocative.
local NON_VOCATIVE_PREDECESSORS = {
    to = true, ["for"] = true, with = true, about = true, from = true,
    at = true, by = true, of = true, on = true, near = true,
    beside = true, behind = true, around = true, like = true,
    except = true, without = true, against = true, toward = true,
    towards = true, ["in"] = true, into = true, onto = true,
    is = true, am = true, are = true, was = true, were = true, be = true,
    im = true, ["i'm"] = true, thats = true, ["that's"] = true,
    hes = true, ["he's"] = true, shes = true, ["she's"] = true,
    its = true, ["it's"] = true, called = true, named = true, name = true,
    heal = true, bandage = true, help = true, patch = true, treat = true,
    revive = true, protect = true, guard = true, cover = true,
    defend = true, watch = true, follow = true, find = true,
    locate = true, check = true, ask = true, tell = true, call = true,
    give = true, hand = true, pass = true, bring = true, fetch = true,
    take = true, shoot = true, attack = true, kill = true, hit = true,
    stop = true, leave = true, drop = true, recruit = true,
    dismiss = true, wake = true, carry = true, meet = true, see = true,
    know = true, trust = true, remember = true, miss = true,
    hate = true, love = true,
    ["and"] = true, ["or"] = true, ["not"] = true, but = true,
    a = true, an = true, the = true, my = true, your = true,
    his = true, her = true, their = true, our = true,
    this = true, that = true,
}

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
    table.sort(out, function(a, b)
        if #a ~= #b then return #a > #b end
        return a < b
    end)
    return out
end

local function isSafeUnpunctuatedVocativeHead(headLower)
    local trimmed = trim(headLower)
    if trimmed == "" then return false end
    if trimmed == "call me" or string.sub(trimmed, -8) == " call me" then
        return false
    end
    local lastWord = string.match(trimmed, "([%a']+)$")
    if not lastWord then return false end
    return NON_VOCATIVE_PREDECESSORS[lastWord] ~= true
end

-- Match a trailing participant vocative ("nice to see you, Jordan" or
-- "nice to see you Jordan"), while refusing to strip grammatical objects
-- ("where is Jordan", "bandage Rory", "tell me about Jordan", "call me Jordan").
local function matchTrailingParticipant(raw, participants)
    if type(participants) ~= "table" or #participants == 0 then
        return nil, raw
    end
    local current = trim(raw)
    if current == "" then return nil, raw end
    local lower = string.lower(current)

    for i = 1, #participants do
        local p = participants[i]
        local pid = participantID(p)
        if pid then
            local aliases = participantAliases(p)
            for j = 1, #aliases do
                local pat = escapePattern(aliases[j])
                -- Explicitly punctuated trailing vocative: "nice to see you, jordan"
                local head, trailingPunct = string.match(
                    lower, "^(.-)%s*[,:;%-]+%s*" .. pat .. "%s*([!%?%.]*)$"
                )
                if head and trim(head) ~= "" then
                    local cleaned = trim(string.sub(current, 1, #head))
                    if trailingPunct == "?" and string.sub(cleaned, -1) ~= "?" then
                        cleaned = cleaned .. "?"
                    end
                    return { pid }, cleaned
                end
                -- Unpunctuated trailing vocative: "nice to see you jordan"
                head, trailingPunct = string.match(
                    lower, "^(.-)%s+" .. pat .. "%s*([!%?%.]*)$"
                )
                if head and isSafeUnpunctuatedVocativeHead(head) then
                    local cleaned = trim(string.sub(current, 1, #head))
                    if trailingPunct == "?" and string.sub(cleaned, -1) ~= "?" then
                        cleaned = cleaned .. "?"
                    end
                    return { pid }, cleaned
                end
            end
        end
    end
    return nil, raw
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
    -- Mid-clause copula negation ("i am not hungry", "i'm not tired", "you are not hurt"):
    -- preserve coreText so exact patterns still match while marking negative polarity.
    local padded = " " .. lower .. " "
    if string.find(padded, " am not ", 1, true)
        or string.find(padded, "'m not ", 1, true)
        or string.find(padded, " im not ", 1, true)
        or string.find(padded, " are not ", 1, true)
        or string.find(padded, " is not ", 1, true)
    then
        return current, true, "not"
    end
    return current, false, nil
end

local function stripGenericTrailingVocative(raw)
    local current = trim(raw)
    if current == "" then return current, nil end
    local lower = string.lower(current)
    for i = 1, #PreParser.GenericVocatives do
        local word = PreParser.GenericVocatives[i]
        local pat = escapePattern(word)
        local head, trailingPunct = string.match(
            lower, "^(.-)%s*[,:;%-]+%s*" .. pat .. "%s*([!%?%.]*)$"
        )
        if head and trim(head) ~= "" then
            local cleaned = trim(string.sub(current, 1, #head))
            if trailingPunct == "?" and string.sub(cleaned, -1) ~= "?" then
                cleaned = cleaned .. "?"
            end
            return cleaned, word
        end
        head, trailingPunct = string.match(
            lower, "^(.-)%s+" .. pat .. "%s*([!%?%.]*)$"
        )
        if head and isSafeUnpunctuatedVocativeHead(head) then
            local cleaned = trim(string.sub(current, 1, #head))
            if trailingPunct == "?" and string.sub(cleaned, -1) ~= "?" then
                cleaned = cleaned .. "?"
            end
            return cleaned, word
        end
    end
    return current, nil
end

function PreParser.RegisterGenericVocative(word)
    local c = cleanAlias(word)
    if c == "" then return false end
    for i = 1, #PreParser.GenericVocatives do
        if PreParser.GenericVocatives[i] == c then return true end
    end
    table.insert(PreParser.GenericVocatives, 1, c)
    return true
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
        else
            local trailingIDs, beforeName = matchTrailingParticipant(working, participants)
            if trailingIDs and #trailingIDs > 0 then
                working = beforeName
                audienceScope = {
                    scope = "INDIVIDUAL",
                    targetIDs = trailingIDs,
                }
            end
        end
    end

    -- 3) Strip modal/politeness wrappers ("should", "could you", "please", "go ahead and", ...)
    local afterModals, modality, strippedModals = stripModals(working)
    -- 3b) If a leading discourse opener ("alright", "okay", "well", ...) was stripped
    --     and audience scope was not yet detected, retry broadcast / vocative extraction
    --     so wrappers like "alright guys, can we camp here" peel cleanly.
    if #strippedModals > 0 and audienceScope.scope == "DEFAULT" then
        local retryBroadcast, retryAfterBroadcast, retryPhrase = matchBroadcastPrefix(afterModals)
        if retryBroadcast then
            afterModals = retryAfterBroadcast
            local retryExcluded, retryAfterExclude = matchExclusionAfterBroadcast(afterModals, participants)
            if retryExcluded and #retryExcluded > 0 then
                afterModals = retryAfterExclude
                audienceScope = {
                    scope = "GROUP_EXCEPT",
                    excludeIDs = retryExcluded,
                    matchedPhrase = retryPhrase,
                }
            else
                audienceScope = {
                    scope = "GROUP",
                    matchedPhrase = retryPhrase,
                }
            end
            local moreText, moreModality, moreStripped = stripModals(afterModals)
            afterModals = moreText
            if #moreStripped > 0 then
                modality = moreModality
                for i = 1, #moreStripped do
                    strippedModals[#strippedModals + 1] = moreStripped[i]
                end
            end
        else
            local retryTargets, retryAfterNames = matchLeadingParticipantList(afterModals, participants)
            if retryTargets and #retryTargets > 0 then
                afterModals = retryAfterNames
                audienceScope = {
                    scope = "INDIVIDUAL",
                    targetIDs = retryTargets,
                }
                local moreText, moreModality, moreStripped = stripModals(afterModals)
                afterModals = moreText
                if #moreStripped > 0 then
                    modality = moreModality
                    for i = 1, #moreStripped do
                        strippedModals[#strippedModals + 1] = moreStripped[i]
                    end
                end
            end
        end
    end
    -- 4) Detect leading negation ("don't", "do not", "stop", "never", ...)
    local afterNeg, negated, negationCue = stripNegation(afterModals)
    -- 5) Strip trailing softeners ("for a bit", "please", "right now", ...)
    local coreText, strippedTrailing = stripTrailingModifiers(afterNeg)
    if audienceScope.scope == "DEFAULT" then
        local lateTrailingIDs, beforeLateName = matchTrailingParticipant(coreText, participants)
        if lateTrailingIDs and #lateTrailingIDs > 0 then
            coreText = beforeLateName
            audienceScope = {
                scope = "INDIVIDUAL",
                targetIDs = lateTrailingIDs,
            }
        else
            local withoutGeneric, genericWord = stripGenericTrailingVocative(coreText)
            if genericWord and withoutGeneric ~= "" then
                coreText = withoutGeneric
                strippedTrailing[#strippedTrailing + 1] = genericWord
            end
        end
    end

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
