-- ConvoEngine: hand-written
-- Bounded multi-clause turn support built on the existing candidate parser.
--
-- This is deliberately not a second grammar. A turn is split only at safe
-- punctuation boundaries and every resulting clause is parsed by the caller's
-- existing ParseCandidates function. If any clause is not independently
-- understood, the original utterance remains the sole parse candidate.
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.ConvoEngine = PsychopatzCore.ConvoEngine or {}

local ConvoEngine = PsychopatzCore.ConvoEngine
local Turn = ConvoEngine.DialogueTurn or {}
ConvoEngine.DialogueTurn = Turn

Turn.VERSION = 1
Turn.DEFAULT_MAX_PARTS = 4
Turn.MAX_PARTS = 8
Turn.MAX_CLAUSE_LENGTH = 512

local function boundedText(value, maximum)
    value = tostring(value or "")
    maximum = tonumber(maximum) or Turn.MAX_CLAUSE_LENGTH
    if #value > maximum then return string.sub(value, 1, maximum) end
    return value
end

local function trim(value)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

local function splitBoundaries(text, maximum)
    local output = {}
    local startAt = 1
    local length = #text
    local index
    local character
    local clause
    local function append(endAt, nextStartAt)
        clause = trim(string.sub(text, startAt, endAt))
        if clause ~= "" then output[#output + 1] = clause end
        startAt = nextStartAt or endAt + 1
    end

    for index = 1, length do
        character = string.sub(text, index, index)
        local isSentencePeriod = character == "."
            and index < length
            and string.sub(text, index + 1, index + 1) == " "
        if character == ","
            or character == ";"
            or character == "?"
            or character == "!"
            or isSentencePeriod
        then
            append(index - 1, index + 1)
            if #output >= maximum then break end
        end
    end
    if #output < maximum and startAt <= length then
        clause = trim(string.sub(text, startAt, length))
        if clause ~= "" then output[#output + 1] = clause end
    end
    return output
end

local function splitConjunctions(text, maximum)
    local lower = string.lower(text)
    local output = {}
    local startAt = 1
    local separators = { " and then ", " then ", " and " }
    while #output < maximum - 1 do
        local bestPos, bestLen = nil, nil
        for i = 1, #separators do
            local sep = separators[i]
            local pos = string.find(lower, sep, startAt, true)
            if pos and (bestPos == nil or pos < bestPos) then
                bestPos = pos
                bestLen = #sep
            end
        end
        if not bestPos then break end
        local head = trim(string.sub(text, startAt, bestPos - 1))
        if head ~= "" then output[#output + 1] = head end
        startAt = bestPos + bestLen
    end
    if startAt <= #text then
        local tail = trim(string.sub(text, startAt))
        if tail ~= "" then output[#output + 1] = tail end
    end
    return output
end

local function candidateSetIsUsable(candidateSet)
    if type(candidateSet) ~= "table" then return false end
    if type(candidateSet.selected) == "table"
        and type(candidateSet.selected.ir) == "table"
    then
        return true
    end
    return type(candidateSet.candidates) == "table"
        and #candidateSet.candidates > 0
end

local function isStrongWholeMatch(candidateSet)
    if not candidateSetIsUsable(candidateSet) then return false end
    local sel = candidateSet.selected
    if type(sel) ~= "table" then return true end
    local pass = tostring(sel.pass or "")
    if pass == "intent_classifier" or pass == "followup" then
        return false
    end
    local conf = tonumber(sel.confidence) or 0
    if conf < 0.80 then return false end
    local match = type(sel.match) == "table" and sel.match or nil
    if match and ((tonumber(match.unmatchedCount) or 0) > 0
        or (tonumber(match.unresolvedCount) or 0) > 0)
    then
        return false
    end
    return true
end

local function parseParts(parts, parseCandidates, options)
    local output = {}
    local index
    local candidateSet
    for index = 1, #parts do
        candidateSet = parseCandidates(parts[index], options)
        if not candidateSetIsUsable(candidateSet) then return nil end
        output[#output + 1] = {
            index = index,
            text = boundedText(parts[index]),
            candidates = candidateSet,
        }
    end
    return output
end

-- Return a bounded description of independently understood clauses, or the
-- ordinary single-parser result when the utterance is not safely compound.
function Turn.Parse(text, parseCandidates, options)
    options = type(options) == "table" and options or {}
    if type(parseCandidates) ~= "function" then
        return nil, "candidate_parser_unavailable"
    end
    text = boundedText(text, 4096)
    -- Preserve an authored whole-utterance pattern (for example, an answer
    -- followed by "thank you") before considering punctuation splitting.
    -- Compound handling is only a fallback for text the existing parser does
    -- not already understand as one complete utterance.
    local whole = parseCandidates(text, options)
    if isStrongWholeMatch(whole) then
        return whole, "single_clause"
    end
    local maxParts = math.min(
        Turn.MAX_PARTS,
        math.max(1, math.floor(tonumber(options.maxParts)
            or Turn.DEFAULT_MAX_PARTS))
    )
    local parts = splitBoundaries(text, maxParts)
    local parsed = (#parts >= 2) and parseParts(parts, parseCandidates, options) or nil
    if not parsed or #parsed < 2 then
        local conjParts = splitConjunctions(text, maxParts)
        if #conjParts >= 2 then
            parsed = parseParts(conjParts, parseCandidates, options)
        end
    end
    if not parsed or #parsed < 2 then
        return whole, "single_clause"
    end
    return {
        schemaVersion = Turn.VERSION,
        kind = "semantic_dialogue_turn",
        compound = true,
        rawText = text,
        parts = parsed,
        diagnostics = {
            parser = "core_bounded_clause_split",
            partCount = #parsed,
            maxParts = Turn.MAX_PARTS,
        },
    }, "compound"
end

return Turn
