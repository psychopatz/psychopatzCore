PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Semantics = PsychopatzCore.Semantics
local IR = Semantics.IR or {}
Semantics.IR = IR

IR.VERSION = 1
IR.CANONICAL_SCHEMA = "psychopatz.semantic.dialogue-ir.v1"
IR.MAX_RAW_TEXT = 4096
IR.MAX_PARTICIPANTS = 8
IR.MAX_SLOTS = 16
IR.MAX_REFERENCES = 16

IR.PUBLIC_CONTEXT_ROOTS = {
    speaker = true,
    addressee = true,
    initiator = true,
    observer = true,
    participants = true,
    target = true,
    relationship = true,
    scene = true,
    world = true,
    slot = true,
    reference = true,
    conversation = true,
}

local function copyValue(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 12 then return nil end

    local output = {}
    local key
    local item
    for key, item in pairs(value) do
        if type(key) ~= "function" and type(item) ~= "function" then
            output[key] = copyValue(item, depth + 1)
        end
    end
    return output
end

local function clamp(value)
    value = tonumber(value) or 0
    if value < 0 then return 0 end
    if value > 1 then return 1 end
    return value
end

local function textValue(value, maximum)
    value = tostring(value or "")
    maximum = tonumber(maximum) or IR.MAX_RAW_TEXT
    if #value > maximum then return string.sub(value, 1, maximum) end
    return value
end

local function confidenceBand(value)
    if value >= 0.85 then return "high" end
    if value >= 0.60 then return "medium" end
    return "low"
end

local function countKeys(value, maximum)
    if type(value) ~= "table" then return 0 end
    local count = 0
    local key
    for key in pairs(value) do
        count = count + 1
        if count > maximum then return count end
    end
    return count
end

function IR.IsPublicContextPath(path)
    if type(path) ~= "string" or path == "" or #path > 128 then return false end
    local first
    for segment in string.gmatch(path, "[^%.]+") do
        first = first or string.lower(segment)
        local normalized = string.lower(segment)
        if normalized == "private"
            or normalized == "secret"
            or normalized == "undiscovered"
            or string.find(normalized, "private", 1, true) ~= nil
            or string.find(normalized, "secret", 1, true) ~= nil
            or string.find(normalized, "undiscovered", 1, true) ~= nil
            or normalized == "java"
            or normalized == "lua"
            or normalized == "callback"
        then
            return false
        end
    end
    return first ~= nil and IR.PUBLIC_CONTEXT_ROOTS[first] == true
end

function IR.New(spec)
    spec = type(spec) == "table" and spec or {}

    local confidence = clamp(spec.confidence)
    local intent = spec.intent or spec.speechAct
    local speechAct = spec.speechAct or intent
    local speaker = copyValue(spec.speaker or spec.actor)
    local addressee = copyValue(spec.addressee or spec.recipient)
    local participants = copyValue(spec.participants) or {}

    local output = {
        schemaVersion = IR.VERSION,
        schema = IR.CANONICAL_SCHEMA,
        kind = spec.kind or "utterance",
        rawText = textValue(spec.rawText or spec.text),
        normalizedText = textValue(spec.normalizedText),

        -- Keep both names in the first contract. speechAct is the clearer
        -- semantic name; intent keeps the IR convenient for existing tools.
        intent = intent,
        speechAct = speechAct,
        action = spec.action,
        subject = spec.subject,

        -- Actor-neutral names are canonical. actor/recipient remain aliases
        -- for accepted runtime callers during migration.
        speaker = speaker,
        addressee = addressee,
        actor = speaker,
        recipient = addressee,
        initiator = copyValue(spec.initiator),
        observer = copyValue(spec.observer),
        participants = participants,
        target = copyValue(spec.target),
        object = copyValue(spec.object),
        -- Inventory questions are semantic read requests, not gameplay
        -- actions.  Keeping the query beside the other IR slots lets the
        -- client/server boundary use the same contract without pretending a
        -- question is a task.
        inventoryQuery = copyValue(spec.inventoryQuery or spec.itemQuery),
        source = copyValue(spec.source),
        destination = copyValue(spec.destination),

        slots = copyValue(spec.slots) or {},
        slotDefinitions = copyValue(spec.slotDefinitions or spec.slotSpecs) or {},
        modifiers = copyValue(spec.modifiers) or {},
        emotionalState = copyValue(spec.emotionalState) or {},
        certainty = copyValue(spec.certainty) or {},
        socialContext = copyValue(spec.socialContext) or {},
        references = copyValue(spec.references) or {},
        referenceDefinitions = copyValue(spec.referenceDefinitions) or {},
        constraints = copyValue(spec.constraints or spec.predicate),
        context = copyValue(spec.context) or {},

        confidence = confidence,
        confidenceBand = spec.confidenceBand or confidenceBand(confidence),
        diagnostics = copyValue(spec.diagnostics) or {},
        provenance = copyValue(spec.provenance) or {},
    }

    if type(spec.analysis) == "table" then
        output.analysis = copyValue(spec.analysis)
    end
    if type(spec.extensions) == "table" then
        output.extensions = copyValue(spec.extensions)
    end

    return output
end

function IR.Clone(value)
    return copyValue(value)
end

function IR.Is(value)
    return type(value) == "table"
        and tonumber(value.schemaVersion) == IR.VERSION
        and value.kind ~= nil
end

function IR.Validate(value)
    if not IR.Is(value) then return false, "invalid_schema" end
    if value.schema ~= IR.CANONICAL_SCHEMA then
        return false, "invalid_canonical_schema"
    end
    if type(value.rawText) ~= "string" then return false, "invalid_raw_text" end
    if type(value.normalizedText) ~= "string" then
        return false, "invalid_normalized_text"
    end
    if type(value.confidence) ~= "number"
        or value.confidence < 0 or value.confidence > 1
    then
        return false, "invalid_confidence"
    end
    if value.intent ~= nil and type(value.intent) ~= "string" then
        return false, "invalid_intent"
    end
    if value.speechAct ~= nil and type(value.speechAct) ~= "string" then
        return false, "invalid_speech_act"
    end
    if value.intent ~= nil and value.speechAct ~= nil
        and value.intent ~= value.speechAct
    then
        return false, "intent_speech_act_mismatch"
    end
    if value.speaker ~= nil and type(value.speaker) ~= "table" then
        return false, "invalid_speaker"
    end
    if value.addressee ~= nil and type(value.addressee) ~= "table" then
        return false, "invalid_addressee"
    end
    if value.participants ~= nil and type(value.participants) ~= "table" then
        return false, "invalid_participants"
    end
    if type(value.participants) == "table"
        and #value.participants > IR.MAX_PARTICIPANTS
    then
        return false, "participant_limit"
    end
    if countKeys(value.slotDefinitions, IR.MAX_SLOTS) > IR.MAX_SLOTS
    then
        return false, "slot_limit"
    end
    if countKeys(value.referenceDefinitions, IR.MAX_REFERENCES) > IR.MAX_REFERENCES
    then
        return false, "reference_limit"
    end
    return true
end

return IR
