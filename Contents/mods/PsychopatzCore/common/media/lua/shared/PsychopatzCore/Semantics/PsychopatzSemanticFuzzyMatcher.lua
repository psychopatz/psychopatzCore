-- Bounded typo matching for the semantic concept layer.
--
-- Exact aliases remain the hot path.  This module is consulted only after an
-- exact phrase misses, and its registry index is rebuilt only when the
-- vocabulary revision changes.  It is intentionally conservative: short
-- words are never fuzzy-matched because a one-character edit can change a
-- command's meaning completely.
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Semantics = PsychopatzCore.Semantics
local Registry = Semantics.Registry
    or require "PsychopatzCore/Semantics/PsychopatzSemanticRegistry"
local Fuzzy = Semantics.FuzzyMatcher or {}
Semantics.FuzzyMatcher = Fuzzy

Fuzzy.VERSION = 1
Fuzzy.MIN_LENGTH = 4
Fuzzy.MAX_DISTANCE = 2
Fuzzy.MAX_SCAN = 128
Fuzzy.Revision = -1
Fuzzy.Aliases = {}
Fuzzy.ByTokenCount = {}

local function tokenCount(value)
    local count = 0
    for _ in string.gmatch(tostring(value or ""), "%S+") do
        count = count + 1
    end
    return count
end

local function rebuild()
    local aliases = {}
    local byTokenCount = {}
    local conceptIDs = Registry.ListConcepts()
    local conceptIndex
    local concept
    local aliasIndex
    local alias
    for conceptIndex = 1, #conceptIDs do
        concept = Registry.GetConcept(conceptIDs[conceptIndex])
        if type(concept) == "table"
            and type(concept.aliases) == "table"
            and not (concept.metadata and concept.metadata.fuzzy == false)
        then
            for aliasIndex = 1, #concept.aliases do
                alias = tostring(concept.aliases[aliasIndex] or "")
                if #alias >= Fuzzy.MIN_LENGTH then
                    local count = tokenCount(alias)
                    local entry = {
                        phrase = alias,
                        id = concept.id,
                        priority = concept.priority,
                        tokenCount = count,
                        length = #alias,
                    }
                    aliases[#aliases + 1] = entry
                    byTokenCount[count] = byTokenCount[count] or {}
                    local bucket = byTokenCount[count]
                    bucket[#bucket + 1] = entry
                end
            end
        end
    end
    Fuzzy.Aliases = aliases
    Fuzzy.ByTokenCount = byTokenCount
    Fuzzy.Revision = Registry.GetRevision()
end

local function editDistance(left, right, limit)
    if left == right then return 0 end

    local leftLength = #left
    local rightLength = #right
    if math.abs(leftLength - rightLength) > limit then return nil end

    local previousPrevious = {}
    local previous = {}
    local index
    for index = 0, rightLength do previous[index] = index end

    local row
    local leftByte
    local rightByte
    local best
    local substitution
    for row = 1, leftLength do
        local current = {}
        current[0] = row
        leftByte = string.byte(left, row)
        for index = 1, rightLength do
            rightByte = string.byte(right, index)
            substitution = previous[index - 1]
                + (leftByte == rightByte and 0 or 1)
            best = previous[index] + 1
            if current[index - 1] + 1 < best then
                best = current[index - 1] + 1
            end
            if substitution < best then best = substitution end

            -- Adjacent transposition makes common swaps such as "stya" and
            -- "watre" a single edit instead of two substitutions.
            if row > 1 and index > 1
                and leftByte == string.byte(right, index - 1)
                and string.byte(left, row - 1) == rightByte
                and previousPrevious[index - 2] ~= nil
            then
                local transposition = previousPrevious[index - 2] + 1
                if transposition < best then best = transposition end
            end
            current[index] = best
        end
        previousPrevious = previous
        previous = current
    end

    if previous[rightLength] <= limit then return previous[rightLength] end
    return nil
end

local function maximumDistance(phrase, options)
    local length = #phrase
    if length < Fuzzy.MIN_LENGTH then return nil end
    options = type(options) == "table" and options or {}
    local maximum = math.floor(
        tonumber(options.fuzzyMaxDistance) or Fuzzy.MAX_DISTANCE
    )
    if maximum < 1 then return nil end
    -- Keep short aliases strict. Longer phrases get one extra edit so a
    -- missing character plus a transposition can still be recovered.
    if length < 9 and maximum > 1 then maximum = 1 end
    return maximum
end

local function ensureIndex()
    if Fuzzy.Revision ~= Registry.GetRevision() then rebuild() end
end

function Fuzzy.Rebuild()
    rebuild()
    return Fuzzy.Revision
end

function Fuzzy.Find(phrase, options)
    phrase = tostring(phrase or "")
    options = type(options) == "table" and options or {}
    if options.enableFuzzy == false then return nil end

    local maximum = maximumDistance(phrase, options)
    if not maximum then return nil end
    ensureIndex()

    local entries = Fuzzy.ByTokenCount[tokenCount(phrase)]
    if type(entries) ~= "table" then return nil end

    local bestDistance = nil
    local bestEntries = {}
    local scanned = 0
    local truncated = false
    local index
    local entry
    for index = 1, #entries do
        if scanned >= Fuzzy.MAX_SCAN then
            truncated = true
            break
        end
        entry = entries[index]
        if math.abs(entry.length - #phrase) <= maximum then
            scanned = scanned + 1
            local distance = editDistance(phrase, entry.phrase, maximum)
            if distance ~= nil then
                if bestDistance == nil or distance < bestDistance then
                    bestDistance = distance
                    bestEntries = { entry }
                elseif distance == bestDistance then
                    bestEntries[#bestEntries + 1] = entry
                end
            end
        end
    end

    if bestDistance == nil then return nil end

    -- Multiple aliases can belong to the same concept.  Keep one candidate
    -- per concept so ambiguity is about semantic meanings, not vocabulary
    -- spelling variants.
    local unique = {}
    local matches = {}
    for index = 1, #bestEntries do
        entry = bestEntries[index]
        if not unique[entry.id] then
            unique[entry.id] = true
            matches[#matches + 1] = {
                id = entry.id,
                priority = entry.priority,
                distance = bestDistance,
                alias = entry.phrase,
            }
        end
    end
    table.sort(matches, function(left, right)
        if left.priority ~= right.priority then
            return left.priority > right.priority
        end
        return tostring(left.id) < tostring(right.id)
    end)

    return {
        matches = matches,
        distance = bestDistance,
        scanned = scanned,
        truncated = truncated,
    }
end

Fuzzy.Rebuild()

return Fuzzy
