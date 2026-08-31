require "PsychopatzCore/UI/Conversation/PsychopatzConversationHistory"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationText"
require "PsychopatzCore/Conversation/PsychopatzConversationMessage"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}

local Conversation = PsychopatzCore.Conversation
local History = Conversation.History
local Settings = Conversation.Settings
local Text = Conversation.Text
local Message = Conversation.Message
local Session = Conversation.Session or {}
Conversation.Session = Session

local function now()
    return getTimeInMillis and getTimeInMillis()
        or getTimestampMs and getTimestampMs()
        or (getGameTime and getGameTime()
            and getGameTime():getWorldAgeHours() * 3600000)
        or 0
end

local function evaluate(value, context, ...)
    if type(value) == "function" then return value(context, ...) end
    return value
end

function Session.New(view, spec)
    spec = spec or {}
    local context = spec.context or {}
    local persistHistory = spec.persistHistory ~= false
    local self = {
        view = view,
        spec = spec,
        namespace = spec.namespace or "default",
        npcID = spec.npcID or spec.id or "unknown",
        characterUUID = spec.characterUUID or "unbound",
        persistHistory = persistHistory,
        context = context,
        saveUUID = spec.saveUUID
            or (persistHistory and Message.GetSaveID() or "ephemeral"),
        conversationID = spec.conversationID or Message.NewID("conversation"),
        participants = spec.participants or {},
        sequence = 0,
        queue = {},
        busy = false,
    }
    setmetatable(self, { __index = Session })
    return self
end

function Session:loadHistory()
    local messages = self.persistHistory and History.Get(
        self.namespace, self.npcID, self.characterUUID
    ) or {}
    self.view.historyPart:setMessages(messages)
    return messages
end

function Session:start()
    self:loadHistory()
    self:enterNode(self.spec.start or "start")
end

function Session:getNode(nodeID)
    local node = self.spec.nodes and self.spec.nodes[nodeID] or nil
    if type(node) == "function" then node = node(self.context, self) end
    return node
end

local function speakerDetails(session, speaker, metadata)
    metadata = metadata or {}
    local source = type(speaker) == "table" and speaker or {}
    local kind = type(speaker) == "string" and speaker
        or source.kind or source.speakerKind or "npc"
    local context = session.context or {}
    local player = kind == "player"
    local speakerID = metadata.speakerID or source.speakerID or source.id
    local speakerName = metadata.speakerName or source.speakerName or source.name
    if player then
        speakerID = speakerID or metadata.playerID or session.characterUUID
        speakerName = speakerName or context.playerName
            or context.playerFullName or session.spec.playerName
    else
        speakerID = speakerID or metadata.npcID or session.npcID
        speakerName = speakerName or context.npcName
            or context.npcFullName or session.spec.npcName
    end
    return kind, tostring(speakerID or "unknown-speaker"), speakerName
end

function Session:append(speaker, payload, metadata)
    metadata = metadata or {}
    local kind, speakerID, speakerName = speakerDetails(self, speaker, metadata)
    self.sequence = self.sequence + 1
    local textPayload = Text.Payload(
        type(speaker) == "table" and (speaker.payload or payload) or payload
    )
    local message = Message.New({
        conversationID = self.conversationID,
        saveUUID = self.saveUUID,
        sequence = self.sequence,
        messageID = metadata.messageID,
        speaker = kind,
        speakerID = speakerID,
        speakerName = speakerName,
        speakerKind = metadata.speakerKind or kind,
        playerUUID = self.characterUUID,
        npcUUID = self.npcID,
        namespace = self.namespace,
        payload = textPayload,
        text = Text.Resolve(textPayload),
        worldAgeHours = metadata.worldAgeHours,
        participants = metadata.participants or self.participants,
        visibility = metadata.visibility,
        provenance = metadata.provenance,
        source = metadata.source,
        deliveryState = metadata.deliveryState,
        presentationState = metadata.presentationState or {
            conversationUI = true,
            nameplate = false,
        },
    })
    if self.persistHistory then
        History.Append(
            self.namespace, self.npcID, kind, message.payload,
            self.characterUUID, message
        )
    end
    Message.Publish(message)
    self.view.historyPart:addMessage(message)
    if kind == "npc" and self.view.portraitPart
        and self.view.portraitPart.portrait
        and self.view.portraitPart.portrait.pulseSpeech
    then
        self.view.portraitPart.portrait:pulseSpeech(Text.Resolve(message.payload))
    end
    return message
end

function Session:delayFor(payload)
    payload = Text.Payload(payload)
    if tonumber(payload.delayMs) then return math.max(0, tonumber(payload.delayMs)) end
    local length = #Text.Resolve(payload)
    local rate = math.max(1, tonumber(Settings.Get("typingCharactersPerSecond", 38)) or 38)
    local minimum = math.max(0, tonumber(Settings.Get("typingMinimumMs", 320)) or 320)
    local maximum = math.max(minimum, tonumber(Settings.Get("typingMaximumMs", 1800)) or 1800)
    return math.max(minimum, math.min(maximum, length / rate * 1000))
end

function Session:queueMessage(speaker, payload, metadata)
    metadata = metadata or {}
    if payload == nil then return end
    if type(payload) == "table" and payload[1] ~= nil
        and payload.key == nil and payload.text == nil
    then
        local index
        for index = 1, #payload do
            self:queueMessage(speaker, payload[index], metadata)
        end
        return
    end
    local previous = self.queue[#self.queue]
    local readyAt = math.max(now(), previous and previous.readyAt or 0)
    if speaker == "npc" then readyAt = readyAt + self:delayFor(payload) end
    self.queue[#self.queue + 1] = {
        speaker = speaker,
        payload = Text.Payload(payload),
        metadata = metadata,
        readyAt = readyAt,
    }
    self.busy = true
    self.view.historyPart:setTyping(self.queue[1] and self.queue[1].speaker or nil)
end

function Session:setChoices(choices)
    local output = {}
    local index
    for index = 1, #(choices or {}) do
        local choice = choices[index]
        local visible = evaluate(choice.visible, self.context, choice, self) ~= false
        if visible then
            local choiceText = choice.text
            if choiceText == nil and choice.textKey then
                choiceText = {
                    key = choice.textKey,
                    domain = choice.textDomain,
                    args = choice.textArgs,
                }
            end
            output[#output + 1] = {
                id = choice.id or tostring(index),
                text = evaluate(choiceText, self.context, choice, self),
                response = choice.response,
                next = choice.next,
                close = choice.close,
                closeReason = choice.closeReason,
                action = choice.action or choice.onSelect,
                log = choice.log ~= false,
                enabled = evaluate(choice.enabled, self.context, choice, self) ~= false,
                source = choice,
            }
        end
    end
    self.view.choicesPart:setChoices(output)
end

function Session:enterNode(nodeID)
    local node = self:getNode(nodeID)
    self.currentNodeID = nodeID
    self.currentNode = node
    self.view.choicesPart:setChoices({})
    if not node then
        self.view:close("missing_node:" .. tostring(nodeID))
        return
    end
    local npc = evaluate(node.npc or node.message, self.context, self)
    if npc then self:queueMessage("npc", npc) end
    self.pendingChoices = node.choices or {}
    if #self.queue == 0 then
        self:setChoices(self.pendingChoices)
        self.pendingChoices = nil
    end
end

function Session:selectChoice(choice)
    if self.busy or not choice or choice.enabled == false then return false end
    self.view.choicesPart:setChoices({})
    if choice.log ~= false then
        self:append(
            "player",
            evaluate(choice.text, self.context, choice.source, self)
        )
    end
    evaluate(choice.action, self.context, choice.source, self)
    local response = evaluate(choice.response, self.context, choice.source, self)
    if response then self:queueMessage("npc", response) end
    self.pendingNext = evaluate(choice.next, self.context, choice.source, self)
    self.pendingClose = evaluate(choice.close, self.context, choice.source, self) == true
    self.pendingCloseReason = evaluate(
        choice.closeReason,
        self.context,
        choice.source,
        self
    )
    if #self.queue == 0 then self:finishPending() end
    return true
end

function Session:finishPending()
    self.busy = false
    self.view.historyPart:setTyping(nil)
    if self.pendingClose then
        self.pendingClose = nil
        local reason = self.pendingCloseReason or "choice_close"
        self.pendingCloseReason = nil
        self.view:close(reason)
        return
    end
    self.pendingCloseReason = nil
    if self.pendingNext then
        local nextID = self.pendingNext
        self.pendingNext = nil
        self:enterNode(nextID)
        return
    end
    if self.pendingChoices then
        local choices = self.pendingChoices
        self.pendingChoices = nil
        self:setChoices(choices)
    end
end

function Session:update()
    local queued = self.queue[1]
    if queued and now() >= queued.readyAt then
        table.remove(self.queue, 1)
        self:append(queued.speaker, queued.payload, queued.metadata)
        queued = self.queue[1]
        self.view.historyPart:setTyping(queued and queued.speaker or nil)
    end
    if #self.queue == 0 and self.busy then self:finishPending() end
end

return Session
