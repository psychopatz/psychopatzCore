PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Semantics = PsychopatzCore.Semantics
local IR = Semantics.IR
    or require "PsychopatzCore/Semantics/PsychopatzSemanticIR"
local State = Semantics.DialogueState or {}
Semantics.DialogueState = State

State.VERSION = 1
State.DEFAULT_EVENT_LIMIT = 12
State.DEFAULT_PARTICIPANT_LIMIT = 8
State.MAX_EVENT_TEXT = 256
State.MAX_TOPIC_LENGTH = 64

local function copyValue(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 12 then return nil end

    local output = {}
    local key
    local item
    for key, item in pairs(value) do
        output[key] = copyValue(item, depth + 1)
    end
    return output
end

local function textValue(value, maximum)
    value = tostring(value or "")
    maximum = tonumber(maximum) or State.MAX_EVENT_TEXT
    if #value > maximum then return string.sub(value, 1, maximum) end
    return value
end

local function topicValue(value)
    if value == nil then return nil end
    local valueType = type(value)
    if valueType ~= "string" and valueType ~= "number" then return nil end
    value = textValue(value, State.MAX_TOPIC_LENGTH)
    return value ~= "" and value or nil
end

local function compactEntity(value)
    if type(value) ~= "table" then
        local text = tostring(value or "")
        return text ~= "" and { text = text, value = text } or nil
    end

    local output = {}
    local fields = {
        "id", "entityID", "uuid", "concept", "category", "item_id",
        "quantity", "text", "value", "reference", "unresolved",
    }
    local populated = false
    local index
    local field
    for index = 1, #fields do
        field = fields[index]
        if value[field] ~= nil then
            output[field] = copyValue(value[field])
            populated = true
        end
    end
    if not populated then return nil end
    return output
end

State.Internal = State.Internal or {}
State.Internal.CopyValue = copyValue
State.Internal.TextValue = textValue
State.Internal.CompactEntity = compactEntity

function State.New(spec)
    spec = type(spec) == "table" and spec or {}
    local self = {
        version = State.VERSION,
        maxEvents = math.max(
            1,
            math.floor(tonumber(spec.maxEvents) or State.DEFAULT_EVENT_LIMIT)
        ),
        maxParticipants = math.max(
            1,
            math.floor(
                tonumber(spec.maxParticipants)
                    or State.DEFAULT_PARTICIPANT_LIMIT
            )
        ),
        maxReferences = math.max(
            1,
            math.floor(tonumber(spec.maxReferences) or 8)
        ),
        participants = {},
        participantKeys = {},
        currentTopic = topicValue(spec.currentTopic),
        previousTopic = topicValue(spec.previousTopic),
        lastIntent = spec.lastIntent,
        lastAction = spec.lastAction,
        lastConfidence = tonumber(spec.lastConfidence) or 0,
        conversationGoal = copyValue(spec.conversationGoal),
        pendingQuestion = copyValue(spec.pendingQuestion),
        pendingRequest = copyValue(spec.pendingRequest),
        unresolvedReferences = copyValue(spec.unresolvedReferences) or {},
        socialContext = copyValue(spec.socialContext) or {},
        recentSemanticEvents = {},
        sequence = tonumber(spec.sequence) or 0,
        lastEvent = copyValue(spec.lastEvent),
    }
    setmetatable(self, { __index = State })

    local participants = spec.participants or {}
    local index
    local participant
    for index = 1, #participants do
        participant = participants[index]
        self:AddParticipant(participant)
    end
    return self
end

function State:AddParticipant(participant)
    local compact = compactEntity(participant)
    if not compact then return false, "invalid_participant" end
    local key = tostring(
        compact.id or compact.entityID or compact.uuid
            or compact.value or compact.text or ""
    )
    if key == "" then return false, "invalid_participant" end
    if self.participantKeys[key] then return true, "already_present" end
    if #self.participants >= self.maxParticipants then
        return false, "participant_limit"
    end
    compact.id = compact.id or key
    self.participants[#self.participants + 1] = compact
    self.participantKeys[key] = true
    return true, compact
end

function State:Snapshot()
    return {
        version = self.version,
        maxEvents = self.maxEvents,
        maxParticipants = self.maxParticipants,
        maxReferences = self.maxReferences,
        participants = copyValue(self.participants),
        currentTopic = self.currentTopic,
        previousTopic = self.previousTopic,
        lastIntent = self.lastIntent,
        lastAction = self.lastAction,
        lastConfidence = self.lastConfidence,
        conversationGoal = copyValue(self.conversationGoal),
        pendingQuestion = copyValue(self.pendingQuestion),
        pendingRequest = copyValue(self.pendingRequest),
        unresolvedReferences = copyValue(self.unresolvedReferences),
        socialContext = copyValue(self.socialContext),
        recentSemanticEvents = self:Recent(nil, false),
        sequence = self.sequence,
        lastEvent = copyValue(self.lastEvent),
    }
end

function State:ToContext()
    return {
        participants = copyValue(self.participants),
        currentTopic = self.currentTopic,
        previousTopic = self.previousTopic,
        lastIntent = self.lastIntent,
        lastAction = self.lastAction,
        conversationGoal = copyValue(self.conversationGoal),
        pendingQuestion = copyValue(self.pendingQuestion),
        pendingRequest = copyValue(self.pendingRequest),
        unresolvedReferences = copyValue(self.unresolvedReferences),
        socialContext = copyValue(self.socialContext),
        recentSemanticEvents = self:Recent(6, true),
    }
end

function State:ClearPending(kind)
    if kind == "question" or kind == nil then self.pendingQuestion = nil end
    if kind == "request" or kind == nil then self.pendingRequest = nil end
end

-- Mark a turn as having answered the compact conversational obligation it
-- relates to. This is deliberately separate from ClearPending so the router
-- can decide and compose a response while the prior request/question is still
-- available, then retire it before the next turn is previewed.
function State:CompletePending(ir)
    if type(ir) ~= "table" then return false, "invalid_ir" end

    local intent = ir.intent or ir.speechAct
    if intent == "ACCEPT" or intent == "REFUSE" then
        if self.pendingRequest ~= nil then
            self:ClearPending("request")
            return true, "request"
        end
        return false, "no_request"
    end

    if intent == "ANSWER" or intent == "INFORM" or intent == "CLARIFY" then
        if self.pendingQuestion ~= nil then
            self:ClearPending("question")
            return true, "question"
        end
        return false, "no_question"
    end

    return false, "not_pending_resolution"
end

-- Authored conversation blocks can change the active topic without creating a
-- semantic event. Keep that presentation context in the same bounded state
-- object used by the parser so later turns do not inherit a stale topic.
function State:SetTopic(topic, preservePrevious)
    topic = topicValue(topic)
    if not topic then return false, "invalid_topic" end
    if self.currentTopic == topic then return true, "unchanged" end
    if preservePrevious ~= false then
        self.previousTopic = self.currentTopic
    end
    self.currentTopic = topic
    return true, topic
end

function State:Reset(keepParticipants)
    local participants = keepParticipants and copyValue(self.participants) or {}
    self.currentTopic = nil
    self.previousTopic = nil
    self.lastIntent = nil
    self.lastAction = nil
    self.lastConfidence = 0
    self.conversationGoal = nil
    self.pendingQuestion = nil
    self.pendingRequest = nil
    self.unresolvedReferences = {}
    self.socialContext = {}
    self.recentSemanticEvents = {}
    self.sequence = 0
    self.lastEvent = nil
    self.participants = {}
    self.participantKeys = {}
    if keepParticipants then
        for _, participant in ipairs(participants) do
            self:AddParticipant(participant)
        end
    end
    return self
end

require "PsychopatzCore/Semantics/PsychopatzSemanticDialogueState_References"
require "PsychopatzCore/Semantics/PsychopatzSemanticDialogueState_Events"

return State
