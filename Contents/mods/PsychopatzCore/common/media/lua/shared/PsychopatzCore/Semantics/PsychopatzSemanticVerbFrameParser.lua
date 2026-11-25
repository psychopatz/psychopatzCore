-- Modular Verb-Frame Semantic Role Parser (compositional fallback).
-- Runs only when exact/fuzzy/surface-recovery templates produce no match.
-- Supports intransitive, spatial, transitive (VERB + <object>), and ditransitive
-- (VERB + <recipient> + <object> / VERB + <object> + PREP + <target|source|recipient>)
-- frames, plus canonical negation inversions.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Semantics = PsychopatzCore.Semantics
local IR = Semantics.IR
    or require "PsychopatzCore/Semantics/PsychopatzSemanticIR"

local VerbFrame = Semantics.VerbFrameParser or {}
Semantics.VerbFrameParser = VerbFrame

VerbFrame.VERSION = 2
VerbFrame.Frames = VerbFrame.Frames or {}
VerbFrame.VerbAliases = VerbFrame.VerbAliases or {}

-- Canonical action inversions when ClausePreParser detects negative polarity
-- (e.g. "don't follow me" -> STAY, "stop shooting" -> HOLD_FIRE, "don't sit" -> STAND).
VerbFrame.NegatedActionMap = VerbFrame.NegatedActionMap or {
    FOLLOW  = "STAY",
    ATTACK  = "HOLD_FIRE",
    SIT     = "STAND",
    POSTURE = "STAND",
    MOVE    = "STAY",
    WAIT_AT = "STAY",
}

local TWO_WORD_PREPS = {
    ["next to"]   = "spatial",
    ["over by"]   = "spatial",
    ["over at"]   = "spatial",
    ["close to"]  = "spatial",
    ["front of"]  = "spatial",
    ["in front"]  = "spatial",
    ["out of"]    = "source",
}

local ONE_WORD_PREPS = {
    at      = "spatial",
    by      = "spatial",
    near    = "spatial",
    beside  = "spatial",
    around  = "spatial",
    ["in"]  = "spatial",
    inside  = "spatial",
    on      = "spatial",
    onto    = "spatial",
    to      = "to",      -- disambiguated per frame (recipient for GIVE, spatial for MOVE/WAIT)
    toward  = "spatial",
    towards = "spatial",
    into    = "spatial",
    behind  = "spatial",
    from    = "source",
    ["for"] = "recipient",
}

local LEADING_DETERMINERS = {
    the = true, a = true, an = true, some = true, any = true,
    this = true, that = true, these = true, those = true,
    nearest = true, closest = true, my = true, our = true, your = true,
}

local RECIPIENT_PRONOUNS = {
    me = true, us = true, him = true, her = true, them = true,
}

local DEICTIC_THERE = {
    there = true,
    ["over there"] = true,
}

local DEICTIC_HERE = {
    here = true,
    ["right here"] = true,
    put = true,
}

local function trim(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function cleanNounPhrase(tokens, startIdx, endIdx)
    local out = {}
    local idx = startIdx
    while idx <= endIdx and LEADING_DETERMINERS[tokens[idx]] do
        idx = idx + 1
    end
    for i = idx, endIdx do
        if tokens[i] and tokens[i] ~= "" then
            out[#out + 1] = tokens[i]
        end
    end
    return trim(table.concat(out, " "))
end

function VerbFrame.RegisterNegatedAction(action, invertedAction)
    local a = string.upper(tostring(action or ""))
    local inv = string.upper(tostring(invertedAction or ""))
    if a == "" or inv == "" then return false end
    VerbFrame.NegatedActionMap[a] = inv
    return true
end

function VerbFrame.ResolveNegatedAction(action)
    local a = string.upper(tostring(action or ""))
    return VerbFrame.NegatedActionMap[a] or action
end

function VerbFrame.RegisterVerbFrame(frameID, spec)
    local id = string.upper(tostring(frameID or ""))
    if id == "" or type(spec) ~= "table" then return false end
    VerbFrame.Frames[id] = spec
    if type(spec.concepts) == "table" then
        for i = 1, #spec.concepts do
            VerbFrame.VerbAliases["concept:" .. string.upper(tostring(spec.concepts[i]))] = id
        end
    end
    if type(spec.verbs) == "table" then
        for i = 1, #spec.verbs do
            VerbFrame.VerbAliases["word:" .. string.lower(tostring(spec.verbs[i]))] = id
        end
    end
    return true
end

-- Built-in verb frames (extensible by mods via VerbFrame.RegisterVerbFrame).
VerbFrame.RegisterVerbFrame("WAIT", {
    concepts = { "WAIT", "STAY" },
    verbs = { "stay", "staying", "wait", "waiting", "hold", "holding", "stand", "standing", "remain", "stop", "camp", "hang" },
    intent = "REQUEST",
    speechAct = "REQUEST",
    bareAction = "STAY",
    spatialAction = "WAIT_AT",
    confidence = 0.86,
})

VerbFrame.RegisterVerbFrame("MOVE", {
    concepts = { "MOVE", "GO" },
    verbs = { "go", "going", "head", "heading", "walk", "walking", "move", "moving", "run", "running" },
    intent = "REQUEST",
    speechAct = "REQUEST",
    bareAction = nil,
    spatialAction = "WAIT_AT",
    confidence = 0.84,
})

VerbFrame.RegisterVerbFrame("FOLLOW", {
    concepts = { "FOLLOW" },
    verbs = { "follow", "following", "come", "coming", "stick", "accompany" },
    intent = "REQUEST",
    speechAct = "REQUEST",
    bareAction = "FOLLOW",
    spatialAction = "FOLLOW",
    confidence = 0.86,
})

VerbFrame.RegisterVerbFrame("GUARD", {
    concepts = { "GUARD" },
    verbs = { "guard", "guarding", "watch", "watching", "defend", "defending", "protect", "cover" },
    intent = "REQUEST",
    speechAct = "REQUEST",
    bareAction = "GUARD",
    spatialAction = "GUARD",
    objectAction = "GUARD",
    objectAsTarget = true,
    confidence = 0.85,
})

VerbFrame.RegisterVerbFrame("SIT", {
    concepts = { "SIT", "REST", "STAND", "SNEAK", "SLEEP" },
    verbs = { "sit", "sitting", "rest", "resting", "stand", "standing", "crouch", "sneak", "sneaking", "sleep", "sleeping" },
    intent = "REQUEST",
    speechAct = "REQUEST",
    bareAction = "POSTURE",
    spatialAction = "POSTURE",
    confidence = 0.84,
})

VerbFrame.RegisterVerbFrame("INTERACT", {
    concepts = { "OPEN", "CLOSE", "BARRICADE", "TOGGLE", "LOCK" },
    verbs = { "open", "close", "shut", "lock", "unlock", "barricade", "unbarricade", "turn", "switch", "toggle", "extinguish" },
    intent = "REQUEST",
    speechAct = "REQUEST",
    objectAction = "INTERACT",
    spatialAction = "INTERACT",
    objectAsTarget = true,
    confidence = 0.85,
})

VerbFrame.RegisterVerbFrame("EQUIP", {
    concepts = { "EQUIP", "WIELD", "WEAR" },
    verbs = { "equip", "wield", "wear", "arm", "holster", "unequip" },
    intent = "REQUEST",
    speechAct = "REQUEST",
    objectAction = "EQUIP",
    confidence = 0.85,
})

VerbFrame.RegisterVerbFrame("USE_ITEM", {
    concepts = { "EAT", "DRINK", "READ", "RELOAD", "USE" },
    verbs = { "eat", "drink", "consume", "read", "smoke", "reload", "use" },
    intent = "REQUEST",
    speechAct = "REQUEST",
    bareAction = "USE_ITEM",
    objectAction = "USE_ITEM",
    confidence = 0.85,
})

-- Transitive & ditransitive frames
VerbFrame.RegisterVerbFrame("FETCH", {
    concepts = { "FETCH", "GET", "GRAB", "PICKUP", "LOOT", "SCAVENGE" },
    verbs = {
        "grab", "get", "fetch", "bring", "take", "pick", "pickup",
        "collect", "gather", "loot", "scavenge", "search", "ransack", "empty",
    },
    intent = "REQUEST",
    speechAct = "REQUEST",
    bareAction = "FETCH",
    objectAction = "FETCH",
    spatialAction = "FETCH",
    ditransitive = true,
    toRole = "recipient",
    confidence = 0.85,
})

VerbFrame.RegisterVerbFrame("EMOTE", {
    concepts = { "DANCE", "EMOTE" },
    verbs = { "dance", "wave", "salute", "clap", "cheer" },
    intent = "REQUEST",
    speechAct = "REQUEST",
    bareAction = "EMOTE",
    spatialAction = "EMOTE",
    confidence = 0.84,
})

VerbFrame.RegisterVerbFrame("GIVE", {
    concepts = { "GIVE", "HAND" },
    verbs = { "give", "hand", "pass", "share", "toss" },
    intent = "REQUEST",
    speechAct = "REQUEST",
    objectAction = "GIVE",
    ditransitive = true,
    toRole = "recipient",
    confidence = 0.85,
})

VerbFrame.RegisterVerbFrame("PUT", {
    concepts = { "STORE", "PUT" },
    verbs = { "put", "store", "stash", "place", "pack", "stow" },
    intent = "REQUEST",
    speechAct = "REQUEST",
    objectAction = "STORE",
    spatialAction = "STORE",
    confidence = 0.85,
})

VerbFrame.RegisterVerbFrame("DROP", {
    concepts = { "DROP" },
    verbs = { "drop", "dump", "leave" },
    intent = "REQUEST",
    speechAct = "REQUEST",
    objectAction = "DROP",
    confidence = 0.85,
})

VerbFrame.RegisterVerbFrame("HEAL", {
    concepts = { "HEAL", "BANDAGE" },
    verbs = { "heal", "bandage", "patch", "treat", "fix" },
    intent = "REQUEST",
    speechAct = "REQUEST",
    bareAction = "HEAL",
    objectAction = "HEAL",
    objectAsTarget = true,
    confidence = 0.86,
})

VerbFrame.RegisterVerbFrame("ATTACK", {
    concepts = { "ATTACK", "SHOOT" },
    verbs = { "attack", "attacking", "shoot", "shooting", "kill", "killing", "fight", "fighting", "engage", "fire", "firing" },
    intent = "REQUEST",
    speechAct = "REQUEST",
    bareAction = "ATTACK",
    objectAction = "ATTACK",
    objectAsTarget = true,
    confidence = 0.85,
})

local function resolveFrameAt(symbols, tokens, index)
    local sym = symbols and symbols[index] or nil
    if sym and sym.kind == "concept" and sym.id then
        local fid = VerbFrame.VerbAliases["concept:" .. string.upper(tostring(sym.id))]
        if fid and VerbFrame.Frames[fid] then
            return fid, VerbFrame.Frames[fid], (sym.endToken or index)
        end
    end
    local w = tokens[index]
    if w then
        local fid = VerbFrame.VerbAliases["word:" .. string.lower(w)]
        if fid and VerbFrame.Frames[fid] then
            return fid, VerbFrame.Frames[fid], index
        end
    end
    return nil, nil, index
end

local function matchParticipantWord(word, participants)
    if not word then return nil end
    local lw = string.lower(word)
    if RECIPIENT_PRONOUNS[lw] then return lw end
    if type(participants) ~= "table" then return nil end
    for i = 1, #participants do
        local p = participants[i]
        if type(p) == "table" then
            local names = { p.firstName, p.forename, p.name, p.nickname }
            for j = 1, #names do
                if type(names[j]) == "string" and string.lower(names[j]) == lw then
                    return tostring(p.id or p.npcID or lw)
                end
            end
        end
    end
    return nil
end

local function isPrepAt(tokens, i, frame)
    if i + 1 <= #tokens then
        local two = tokens[i] .. " " .. tokens[i + 1]
        if TWO_WORD_PREPS[two] then
            return TWO_WORD_PREPS[two], 2
        end
    end
    local one = ONE_WORD_PREPS[tokens[i]]
    if one then
        if one == "to" then
            return (frame and frame.toRole) or "spatial", 1
        end
        return one, 1
    end
    return nil, 0
end

local function buildCandidate(normalized, frameID, frame, suffix, action, slots, priority)
    local finalAction = action
    local negated = slots.negated == true
    if negated then
        finalAction = VerbFrame.ResolveNegatedAction(action)
    end
    local ir = IR.New({
        rawText = normalized.rawText,
        normalizedText = normalized.normalizedText,
        intent = frame.intent,
        speechAct = frame.speechAct,
        action = finalAction,
        object = slots.object,
        target = slots.target,
        destination = slots.destination,
        source = slots.source,
        recipient = slots.recipient,
        confidence = frame.confidence or 0.84,
        provenance = { provider = "lua", parser = "verb_frame", frameID = frameID },
        diagnostics = {
            parser = "lua_verb_frame",
            frameID = frameID,
            coverage = 1,
            noMatch = false,
            negated = negated,
        },
    })
    if negated then
        ir.polarity = "negative"
        ir.extensions = type(ir.extensions) == "table" and ir.extensions or {}
        ir.extensions.negated = true
        ir.extensions.originalAction = action
    end
    return {
        patternId = "core.verb_frame." .. string.lower(frameID) .. "." .. suffix,
        source = "verb_frame",
        score = frame.confidence or 0.84,
        confidence = frame.confidence or 0.84,
        priority = priority or 65,
        captures = {
            object = slots.object,
            target = slots.target,
            destination = slots.destination,
            source = slots.source,
            recipient = slots.recipient,
        },
        typedCaptures = {
            object = slots.object,
            target = slots.target,
            destination = slots.destination,
            source = slots.source,
            recipient = slots.recipient,
        },
        metadata = { verbFrame = frameID, negated = negated },
        match = { consumed = #(normalized.tokens or {}), skipped = 0, unresolvedCount = 0, ambiguousCount = 0, fuzzyCount = 0, unmatchedCount = 0, fullCoverage = true },
        ir = ir,
    }
end

-- Parse normalized tokens & symbols into a single compositional candidate if a
-- registered verb frame matches. Returns nil if no frame applies.
function VerbFrame.Parse(normalized, symbols, parseOpts)
    if type(normalized) ~= "table" then return nil end
    local tokens = normalized.tokens
    if type(tokens) ~= "table" or #tokens == 0 or #tokens > 16 then return nil end
    parseOpts = type(parseOpts) == "table" and parseOpts or {}
    local negated = parseOpts.negated == true
    local participants = parseOpts.groupParticipants

    local frameID, frame, verbEndIdx = nil, nil, 0
    local maxScan = math.min(#tokens, 3)
    for i = 1, maxScan do
        local fid, spec, endIdx = resolveFrameAt(symbols, tokens, i)
        if fid and spec then
            frameID, frame, verbEndIdx = fid, spec, endIdx
            break
        end
    end
    if not frame then return nil end

    local restStart = verbEndIdx + 1
    -- Special tactical idiom: "hold fire" / "cease fire" -> HOLD_FIRE
    if restStart <= #tokens and tokens[restStart] == "fire"
        and (tokens[verbEndIdx] == "hold" or tokens[verbEndIdx] == "cease")
    then
        return buildCandidate(normalized, "ATTACK", VerbFrame.Frames.ATTACK or frame, "hold_fire", "HOLD_FIRE", {
            negated = true,
        }, 68)
    end
    -- Skip optional verb particle ("down", "up", "still", "out", "off") right after verb
    if restStart <= #tokens and (tokens[restStart] == "down" or tokens[restStart] == "up"
        or tokens[restStart] == "still" or tokens[restStart] == "out"
        or tokens[restStart] == "off")
    then
        restStart = restStart + 1
    end

    local bareTail = restStart <= #tokens and trim(table.concat(tokens, " ", restStart, #tokens)) or ""

    -- 1) Bare / deictic-here / simple-pronoun frame (e.g. "stay here", "follow me", "stop shooting")
    if bareTail == "" or DEICTIC_HERE[bareTail]
        or (frame.bareAction == "FOLLOW" and (bareTail == "me" or bareTail == "with me" or bareTail == "us"))
    then
        if not frame.bareAction then return nil end
        return buildCandidate(normalized, frameID, frame, "bare", frame.bareAction, {
            negated = negated,
        }, 60)
    end

    -- 2) Deictic-there ("stay over there", "wait there")
    if DEICTIC_THERE[bareTail] and frame.spatialAction then
        return buildCandidate(normalized, frameID, frame, "there", frame.spatialAction, {
            target = { reference = "THAT" },
            negated = negated,
        }, 65)
    end

    -- 3) Split post-verb tokens into optional directObject (before first prep)
    --    and preposition-bound roles (spatial, source, recipient).
    local firstPrepIdx = nil
    for i = restStart, #tokens do
        local role = isPrepAt(tokens, i, frame)
        if role then
            firstPrepIdx = i
            break
        end
    end

    local directObj = nil
    local ditransRecipient = nil
    local objEnd = firstPrepIdx and (firstPrepIdx - 1) or #tokens
    if objEnd >= restStart then
        -- Ditransitive indirect object: "give Meghan a bandage" / "bring me some water"
        if frame.ditransitive == true and objEnd > restStart then
            local rec = matchParticipantWord(tokens[restStart], participants)
            if rec then
                ditransRecipient = rec
                directObj = cleanNounPhrase(tokens, restStart + 1, objEnd)
            end
        end
        if not directObj then
            directObj = cleanNounPhrase(tokens, restStart, objEnd)
        end
        if directObj == "" then directObj = nil end
    end

    local roles = {}
    if firstPrepIdx then
        local i = firstPrepIdx
        while i <= #tokens do
            local role, step = isPrepAt(tokens, i, frame)
            if role then
                local npStart = i + step
                local npEnd = npStart
                while npEnd <= #tokens do
                    local nextRole = isPrepAt(tokens, npEnd, frame)
                    if npEnd > npStart and nextRole then break end
                    npEnd = npEnd + 1
                end
                npEnd = npEnd - 1
                if npEnd >= npStart then
                    local phrase = cleanNounPhrase(tokens, npStart, npEnd)
                    if phrase ~= "" and not roles[role] then
                        roles[role] = phrase
                    end
                end
                i = npEnd + 1
            else
                i = i + 1
            end
        end
    end

    local recipient = ditransRecipient or roles.recipient
    local spatial = roles.spatial
    local source = roles.source

    -- 4) Transitive / ditransitive frame match (e.g. FETCH, GIVE, PUT, DROP, HEAL, GUARD, ATTACK)
    if directObj and frame.objectAction then
        local slots = {
            negated = negated,
            source = source,
            recipient = recipient,
        }
        if frame.objectAsTarget == true then
            slots.target = directObj
            if spatial then slots.destination = spatial end
        else
            slots.object = directObj
            if spatial then
                slots.destination = spatial
                slots.target = spatial
            end
        end
        return buildCandidate(normalized, frameID, frame, "transitive", frame.objectAction, slots, 66)
    end

    -- 5) Spatial frame match (e.g. "stay by the garbage", "wait next to the car")
    if spatial and frame.spatialAction then
        local targetValue = DEICTIC_THERE[spatial] and { reference = "THAT" } or spatial
        return buildCandidate(normalized, frameID, frame, "spatial", frame.spatialAction, {
            target = targetValue,
            source = source,
            recipient = recipient,
            negated = negated,
        }, 65)
    end

    return nil
end

return VerbFrame
