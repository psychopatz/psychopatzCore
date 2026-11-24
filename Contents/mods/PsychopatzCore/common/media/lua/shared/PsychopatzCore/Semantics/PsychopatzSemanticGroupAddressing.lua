-- Actor-agnostic multi-party addressing resolver:
-- detects vocatives ("Marcus, follow me"), group broadcasts ("everyone follow me"),
-- 3rd-party pronoun references ("is she okay?"), and implicit last-speaker targets.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Addressing = PsychopatzCore.Semantics.GroupAddressing or {}
PsychopatzCore.Semantics.GroupAddressing = Addressing

Addressing.VERSION = 1

local BROADCAST_PREFIXES = {
    "all of you",
    "you guys",
    "you all",
    "everyone",
    "everybody",
    "every one",
    "guys",
    "folks",
    "team",
    "squad",
    "people",
}

local GREETING_LEADERS = {
    hey = true,
    yo = true,
    oi = true,
    listen = true,
    uh = true,
    um = true,
}

local PRONOUN_GENDERS = {
    he = "male",
    him = "male",
    his = "male",
    himself = "male",
    she = "female",
    her = "female",
    hers = "female",
    herself = "female",
    they = "any",
    them = "any",
    their = "any",
}

local function trim(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function lowerClean(s)
    local out = string.lower(tostring(s or ""))
    out = out:gsub("[,!%?;:%.]+", " ")
    out = out:gsub("%s+", " ")
    return trim(out)
end

local function participantAliases(p)
    local aliases = {}
    if type(p) ~= "table" then return aliases end
    local function add(v)
        local c = lowerClean(v)
        if c ~= "" and #c >= 2 then aliases[#aliases + 1] = c end
    end
    add(p.fullName)
    add(p.name)
    add(p.nickname)
    add(p.forename)
    if type(p.name) == "string" then
        local first = string.match(p.name, "^(%S+)")
        if first and lowerClean(first) ~= lowerClean(p.name) then
            add(first)
        end
    end
    return aliases
end

local function stripBroadcast(raw)
    local lower = string.lower(raw)
    for i = 1, #BROADCAST_PREFIXES do
        local phrase = BROADCAST_PREFIXES[i]
        -- Leading: "hey everyone, follow me" or "everyone follow me"
        local p1 = "^%s*hey%s+" .. phrase .. "%s*[,:%-]*%s*(.*)$"
        local rest = string.match(lower, p1)
        if rest then
            local offset = #raw - #rest + 1
            return true, trim(string.sub(raw, offset)), phrase
        end
        local p2 = "^%s*" .. phrase .. "%s*[,:%-]*%s*(.*)$"
        rest = string.match(lower, p2)
        if rest then
            local offset = #raw - #rest + 1
            return true, trim(string.sub(raw, offset)), phrase
        end
        -- Trailing: "follow me, everyone"
        local p3 = "^(.-)%s*[,:%-]*%s*" .. phrase .. "%s*[!%?%.]*$"
        local head = string.match(lower, p3)
        if head and trim(head) ~= "" then
            return true, trim(string.sub(raw, 1, #head)), phrase
        end
    end
    return false, raw, nil
end

local function matchVocative(raw, participants)
    if type(participants) ~= "table" or #participants == 0 then return nil, raw end
    local lower = string.lower(raw)
    -- Strip optional casual leader ("hey ", "yo ") only for matching.
    local leadWord, afterLead = string.match(lower, "^%s*(%a+)%s+(.+)$")
    local hasLeader = leadWord ~= nil and GREETING_LEADERS[leadWord] == true
    local scanLower = hasLeader and afterLead or lower
    local scanOffset = hasLeader and (#lower - #afterLead) or 0

    for i = 1, #participants do
        local p = participants[i]
        local aliases = participantAliases(p)
        for j = 1, #aliases do
            local alias = aliases[j]
            -- Leading vocative: "marcus, follow me" / "marcus follow me"
            local rest = string.match(scanLower, "^" .. alias .. "%s*[,:%-]+%s*(.+)$")
                or string.match(scanLower, "^" .. alias .. "%s+(.+)$")
            if rest and trim(rest) ~= "" then
                local startIdx = scanOffset + (#scanLower - #rest) + 1
                return p, trim(string.sub(raw, startIdx))
            end
            -- Trailing vocative: "follow me, marcus"
            local head = string.match(lower, "^(.-)%s*,%s*" .. alias .. "%s*[!%?%.]*$")
            if head and trim(head) ~= "" then
                return p, trim(string.sub(raw, 1, #head))
            end
        end
    end
    return nil, raw
end

local function participantGender(p)
    if type(p) ~= "table" then return "any" end
    if p.isFemale == true or p.female == true then return "female" end
    if p.isFemale == false or p.female == false then return "male" end
    local g = string.lower(tostring(p.gender or p.sex or ""))
    if g == "female" or g == "f" or g == "woman" then return "female" end
    if g == "male" or g == "m" or g == "man" then return "male" end
    return "any"
end

local function resolveThirdPartyPronoun(raw, participants, floor, speakerID)
    if type(participants) ~= "table" or #participants == 0 then return nil, nil end
    local wantedGender = nil
    local matchedWord = nil
    for w in string.gmatch(string.lower(raw), "%a+") do
        local g = PRONOUN_GENDERS[w]
        if g then
            wantedGender = g
            matchedWord = w
            break
        end
    end
    if not wantedGender then return nil, nil end

    -- Prefer most recent non-speaker on the floor matching the pronoun gender.
    local recent = type(floor) == "table" and type(floor.recentSpeakers) == "table"
        and floor.recentSpeakers or {}
    local byID = {}
    for i = 1, #participants do
        local p = participants[i]
        if type(p) == "table" and p.id ~= nil then
            byID[tostring(p.id)] = p
        end
    end
    for i = #recent, 1, -1 do
        local rid = tostring(recent[i] or "")
        local p = byID[rid]
        if p and tostring(p.id) ~= tostring(speakerID or "") and p.isPlayer ~= true then
            local pg = participantGender(p)
            if wantedGender == "any" or pg == wantedGender then
                return p, matchedWord
            end
        end
    end
    -- Fallback: first non-speaker participant matching the pronoun gender.
    for i = 1, #participants do
        local p = participants[i]
        if type(p) == "table" and p.id ~= nil
            and tostring(p.id) ~= tostring(speakerID or "")
            and p.isPlayer ~= true
        then
            local pg = participantGender(p)
            if wantedGender == "any" or pg == wantedGender then
                return p, matchedWord
            end
        end
    end
    return nil, nil
end

function Addressing.Resolve(rawText, participants, floor, opts)
    opts = type(opts) == "table" and opts or {}
    local raw = trim(rawText)
    local out = {
        rawText = raw,
        cleanedText = raw,
        scope = "default",
        broadcast = false,
        vocative = false,
        targetID = nil,
        targetName = nil,
        implicitTargetID = nil,
        referencedActorID = nil,
        referencedActorName = nil,
        referencedPronoun = nil,
    }
    if raw == "" then return out end

    local isBroadcast, afterBroadcast = stripBroadcast(raw)
    if isBroadcast then
        out.scope = "group"
        out.broadcast = true
        if afterBroadcast ~= "" then out.cleanedText = afterBroadcast end
    else
        local vocTarget, afterVoc = matchVocative(raw, participants)
        if vocTarget then
            out.scope = "single"
            out.vocative = true
            out.targetID = vocTarget.id
            out.targetName = vocTarget.name or vocTarget.fullName
            if afterVoc ~= "" then out.cleanedText = afterVoc end
        end
    end

    local refActor, refPronoun = resolveThirdPartyPronoun(
        out.cleanedText, participants, floor, opts.speakerID
    )
    if refActor then
        out.referencedActorID = refActor.id
        out.referencedActorName = refActor.name or refActor.fullName
        out.referencedPronoun = refPronoun
    end

    if not out.vocative and not out.broadcast
        and type(floor) == "table" and floor.lastSpeakerID ~= nil
        and tostring(floor.lastSpeakerID) ~= tostring(opts.speakerID or "")
    then
        out.implicitTargetID = floor.lastSpeakerID
    end

    return out
end

return Addressing
