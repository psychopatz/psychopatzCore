-- Modular Multi-Clause Script Splitter for PsychopatzCore Semantics.
-- Splits chained natural-language commands ("loot all food from the pantry,
-- put it in the fridge, then follow me") into an ordered sequence of bounded
-- clauses (max 5), preserving actor lists ("Meghan and Rory") and carrying
-- forward audienceScope + anaphoric object references ("it" / "them").

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Semantics = PsychopatzCore.Semantics
local ClausePreParser = Semantics.ClausePreParser
    or require "PsychopatzCore/Semantics/PsychopatzSemanticClausePreParser"

local Splitter = Semantics.ClauseSplitter or {}
Semantics.ClauseSplitter = Splitter

Splitter.VERSION = 1
Splitter.MAX_CLAUSES = 5

local ANAPHORA_OBJECTS = {
    it = true,
    them = true,
    those = true,
    that = true,
    everything = true,
}

local ROOM_WORDS = {
    room = true, kitchen = true, bedroom = true, bathroom = true,
    garage = true, pantry = true, basement = true, attic = true,
    hallway = true, office = true, living = true, storage = true,
    warehouse = true, shop = true, store = true, clinic = true,
    house = true, building = true, area = true, place = true,
}

local QUANTITY_WORDS = {
    all = "all",
    every = "all",
    everything = "all",
    some = "some",
    one = "one",
    a = "one",
    an = "one",
}

local function trim(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local AREA_PREPS = { ["in"] = true, on = true, inside = true, around = true }
local TARGET_PREPS = { from = true, at = true, to = true, into = true, onto = true, by = true, near = true, out = true }
local AREA_DETS = { this = true, the = true, that = true }
local AREA_TAILS = { "on the ground", "in the area", "in this area", "around here", "right here", "nearby", "around", "here" }

local function extractAreaScope(text)
    local lower = string.lower(text)
    -- Match trailing "in/on/inside/around this/the/that <room>"
    local prep, det, place = string.match(lower, "%s+(%a+)%s+(%a+)%s+(%a+)%s*$")
    if prep and AREA_PREPS[prep] and det and AREA_DETS[det] and place and ROOM_WORDS[place] then
        local scopeKind = (place == "area" or place == "place") and "area"
            or (place == "house" or place == "building") and "building"
            or "room"
        local suffix = prep .. " " .. det .. " " .. place
        local stripped = trim(string.sub(text, 1, #text - #suffix))
        return stripped, { kind = scopeKind, room = place, currentOnly = (det == "this") }
    end
    -- Match direct object room scope without preposition: "scavenge this room", "clear this kitchen"
    -- Do NOT steal container/destination targets introduced by from/at/to/into ("from the pantry").
    if not (prep and TARGET_PREPS[prep]) then
        local dDet, dPlace = string.match(lower, "%s+(%a+)%s+(%a+)%s*$")
        if dDet and AREA_DETS[dDet] and dPlace and ROOM_WORDS[dPlace] then
            local scopeKind = (dPlace == "area" or dPlace == "place") and "area"
                or (dPlace == "house" or dPlace == "building") and "building"
                or "room"
            local suffix = dDet .. " " .. dPlace
            local stripped = trim(string.sub(text, 1, #text - #suffix))
            return stripped, { kind = scopeKind, room = dPlace, currentOnly = (dDet == "this") }
        end
    end
    for i = 1, #AREA_TAILS do
        local tail = AREA_TAILS[i]
        if #lower > #tail and string.sub(lower, -#tail) == tail
            and string.sub(lower, -(#tail + 1), -(#tail + 1)) == " "
        then
            local stripped = trim(string.sub(text, 1, #text - #tail))
            return stripped, { kind = "area", label = tail }
        end
    end
    return text, nil
end

local function detectQuantity(text)
    local lower = string.lower(text)
    if string.find(lower, "%f[%a]all%f[%A]") or string.find(lower, "%f[%a]everything%f[%A]")
        or string.find(lower, "%f[%a]every%f[%A]")
    then
        return "all"
    end
    if string.find(lower, "%f[%a]some%f[%A]") then
        return "some"
    end
    return "all" -- default for pickup/loot commands ("pick up that food")
end

-- Split on explicit sequence delimiters: ";", "and then", "then", ", and", ","
-- without splitting leading vocative lists ("Meghan and Rory, ...").
local function rawSplitClauses(coreBody)
    local s = trim(coreBody)
    if s == "" then return {} end
    -- Normalize sequence delimiters into a safe sentinel "\1"
    local work = s
    work = string.gsub(work, "%s*;%s*", "\1")
    work = string.gsub(work, "%s*,%s*[Aa][Nn][Dd]%s+[Tt][Hh][Ee][Nn]%s+", "\1")
    work = string.gsub(work, "%s+[Aa][Nn][Dd]%s+[Tt][Hh][Ee][Nn]%s+", "\1")
    work = string.gsub(work, "%s*,%s*[Tt][Hh][Ee][Nn]%s+", "\1")
    work = string.gsub(work, "%s+[Tt][Hh][Ee][Nn]%s+", "\1")
    work = string.gsub(work, "%s*,%s*[Aa][Nn][Dd]%s+", "\1")
    work = string.gsub(work, "%s*,%s*", "\1")

    local parts = {}
    for seg in string.gmatch(work, "[^\1]+") do
        local c = trim(seg)
        if c ~= "" and #parts < Splitter.MAX_CLAUSES then
            parts[#parts + 1] = c
        end
    end
    return parts
end

-- Split a raw utterance into an ordered script of clauses with shared
-- audienceScope, per-clause quantity, and per-clause areaScope.
function Splitter.Split(rawText, participants)
    local raw = trim(rawText)
    if raw == "" then
        return {
            rawText = raw,
            audienceScope = { scope = "DEFAULT" },
            clauses = {},
            isChained = false,
        }
    end

    -- Extract leading audienceScope once from the full utterance ("Meghan and Rory, ...")
    local leadFrame = ClausePreParser.Analyze(raw, participants)
    local sharedScope = leadFrame.audienceScope or { scope = "DEFAULT" }
    local body = raw
    if sharedScope.scope ~= "DEFAULT" then
        -- Use the remainder after audience extraction (re-preserve trailing text)
        local afterScope = raw
        if sharedScope.matchedPhrase then
            local p = string.lower(sharedScope.matchedPhrase)
            local pos = string.find(string.lower(raw), p, 1, true)
            if pos and pos <= 6 then
                afterScope = trim(string.sub(raw, pos + #p))
                afterScope = trim(string.gsub(afterScope, "^[,:%-]+%s*", ""))
            end
        elseif sharedScope.scope == "INDIVIDUAL" then
            -- Strip leading vocative up to first comma if present
            local afterComma = string.match(raw, "^[^,]+,%s*(.+)$")
            if afterComma and trim(afterComma) ~= "" then
                afterScope = trim(afterComma)
            end
        end
        if afterScope ~= "" then body = afterScope end
    end

    local segments = rawSplitClauses(body)
    if #segments == 0 then segments = { body } end

    local clauses = {}
    for i = 1, #segments do
        local seg = segments[i]
        local cleanSeg, areaScope = extractAreaScope(seg)
        local qty = detectQuantity(cleanSeg)
        clauses[#clauses + 1] = {
            index = i,
            rawText = seg,
            text = cleanSeg,
            quantity = qty,
            areaScope = areaScope,
        }
    end

    return {
        rawText = raw,
        audienceScope = sharedScope,
        clauses = clauses,
        isChained = #clauses > 1,
    }
end

-- Parse all clauses in a script using PsychopatzSemanticParser and resolve
-- cross-clause anaphora ("it" / "them" -> previous clause's object filter).
function Splitter.ParseScript(rawText, parser, options)
    options = type(options) == "table" and options or {}
    local split = Splitter.Split(rawText, options.groupParticipants)
    local parsedSteps = {}
    local lastObject = nil
    local lastTarget = nil

    for i = 1, #split.clauses do
        local clause = split.clauses[i]
        local ir = parser.Parse(clause.text, options)
        if type(ir) == "table" and (tonumber(ir.confidence) or 0) > 0 then
            -- Resolve cross-clause anaphora ("put it in the fridge", "drop them here")
            if type(ir.object) == "string" and ANAPHORA_OBJECTS[string.lower(ir.object)] and lastObject then
                ir.object = lastObject
            elseif ir.object == nil and (ir.action == "STORE" or ir.action == "DROP") and lastObject then
                ir.object = lastObject
            end
            if type(ir.object) == "string" and ir.object ~= "" and not ANAPHORA_OBJECTS[string.lower(ir.object)] then
                lastObject = ir.object
            end
            if type(ir.target) == "string" and ir.target ~= "" then
                lastTarget = ir.target
            end
            ir.extensions = type(ir.extensions) == "table" and ir.extensions or {}
            ir.extensions.quantity = clause.quantity
            if clause.areaScope then
                ir.extensions.areaScope = clause.areaScope
            end
            if split.audienceScope and split.audienceScope.scope ~= "DEFAULT"
                and not ir.extensions.audienceScope
            then
                ir.extensions.audienceScope = split.audienceScope
            end
            parsedSteps[#parsedSteps + 1] = ir
        end
    end

    return {
        rawText = split.rawText,
        audienceScope = split.audienceScope,
        isChained = #parsedSteps > 1,
        steps = parsedSteps,
        lastObject = lastObject,
        lastTarget = lastTarget,
    }
end

return Splitter
