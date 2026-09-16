-- Event history and bounded semantic recording for dialogue state.
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Semantics = PsychopatzCore.Semantics
local IR = Semantics.IR
local State = Semantics.DialogueState
local Internal = State.Internal or {}
State.Internal = Internal
local copyValue = Internal.CopyValue
local textValue = Internal.TextValue
local compactEntity = Internal.CompactEntity
local referenceFrom = Internal.ReferenceFrom
local addUnresolvedReference = Internal.AddUnresolvedReference

local function topicFor(ir)
    local extensions = type(ir.extensions) == "table" and ir.extensions or nil
    local topic = extensions and extensions.topic or nil
    if type(topic) == "table" then
        topic = topic.id or topic.key or topic.name
    end
    if topic ~= nil and tostring(topic) ~= "" then
        return tostring(topic)
    end
    if ir.action and tostring(ir.action) ~= "" then
        return tostring(ir.action)
    end
    if ir.subject and tostring(ir.subject) ~= "" then
        return tostring(ir.subject)
    end
    if ir.object and ir.object.category then
        return tostring(ir.object.category)
    end
    if ir.intent and tostring(ir.intent) ~= "" then
        return tostring(ir.intent)
    end
    return nil
end

local function nowValue(options)
    if type(options) == "table" and options.timestamp ~= nil then
        return options.timestamp
    end
    if getTimeInMillis then return getTimeInMillis() end
    if getTimestampMs then return getTimestampMs() end
    return 0
end

local function eventFromIR(ir, sequence, options)
    return {
        sequence = sequence,
        timestamp = nowValue(options),
        intent = ir.intent,
        speechAct = ir.speechAct,
        action = ir.action,
        subject = ir.subject,
        actor = compactEntity(ir.actor),
        recipient = compactEntity(ir.recipient),
        target = compactEntity(ir.target),
        object = compactEntity(ir.object),
        source = compactEntity(ir.source),
        destination = compactEntity(ir.destination),
        topic = topicFor(ir),
        confidence = tonumber(ir.confidence) or 0,
        rawText = textValue(ir.rawText),
        provider = ir.provenance and ir.provenance.provider or nil,
        pattern = ir.provenance and ir.provenance.pattern or nil,
        modifiers = copyValue(ir.modifiers) or {},
        socialContext = copyValue(ir.socialContext) or {},
    }
end

local function mergeSocialContext(state, values)
    if type(values) ~= "table" then return end
    local key
    local value
    for key, value in pairs(values) do
        state.socialContext[key] = copyValue(value)
    end
end

function State:Record(ir, options)
    local valid, validationReason = IR.Validate(ir)
    if valid ~= true then
        return false, validationReason or "invalid_ir"
    end

    self.sequence = self.sequence + 1
    local event = eventFromIR(ir, self.sequence, options)
    self.previousTopic = self.currentTopic
    self.currentTopic = topicFor(ir) or self.currentTopic
    self.lastIntent = ir.intent
    self.lastAction = ir.action
    self.lastConfidence = tonumber(ir.confidence) or 0
    self.lastEvent = event

    if ir.intent == "QUESTION" then self.pendingQuestion = copyValue(event) end
    if ir.intent == "REQUEST" then self.pendingRequest = copyValue(event) end
    mergeSocialContext(self, ir.socialContext)

    local references = {
        { field = "actor", value = event.actor },
        { field = "recipient", value = event.recipient },
        { field = "target", value = event.target },
        { field = "object", value = event.object },
        { field = "source", value = event.source },
        { field = "destination", value = event.destination },
    }
    local index
    local reference
    for index = 1, #references do
        reference = referenceFrom(
            references[index].field,
            references[index].value
        )
        addUnresolvedReference(self, reference)
    end

    self.recentSemanticEvents[#self.recentSemanticEvents + 1] = event
    while #self.recentSemanticEvents > self.maxEvents do
        table.remove(self.recentSemanticEvents, 1)
    end
    return true, copyValue(event)
end

function State:Recent(limit, newestFirst)
    local count = math.min(
        #self.recentSemanticEvents,
        math.max(0, math.floor(tonumber(limit) or #self.recentSemanticEvents))
    )
    local output = {}
    local index
    if newestFirst == false then
        for index = 1, count do
            output[index] = copyValue(self.recentSemanticEvents[index])
        end
        return output
    end
    for index = 1, count do
        output[index] = copyValue(
            self.recentSemanticEvents[
                #self.recentSemanticEvents - index + 1
            ]
        )
    end
    return output
end

return State
