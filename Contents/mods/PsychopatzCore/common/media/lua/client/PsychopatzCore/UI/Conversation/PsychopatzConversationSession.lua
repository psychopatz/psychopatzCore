require "PsychopatzCore/UI/Conversation/PsychopatzConversationHistory"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationText"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}

local Conversation = PsychopatzCore.Conversation
local History = Conversation.History
local Settings = Conversation.Settings
local Text = Conversation.Text
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
    local self = {
        view = view,
        spec = spec or {},
        namespace = spec.namespace or "default",
        npcID = spec.npcID or spec.id or "unknown",
        context = spec.context or {},
        queue = {},
        busy = false,
    }
    setmetatable(self, { __index = Session })
    return self
end

function Session:start()
    self.view.historyPart:setMessages(History.Get(self.namespace, self.npcID))
    self:enterNode(self.spec.start or "start")
end

function Session:getNode(nodeID)
    local node = self.spec.nodes and self.spec.nodes[nodeID] or nil
    if type(node) == "function" then node = node(self.context, self) end
    return node
end

function Session:append(speaker, payload)
    local message = {
        speaker = speaker,
        payload = Text.Payload(payload),
    }
    History.Append(self.namespace, self.npcID, speaker, message.payload)
    self.view.historyPart:addMessage(message)
    if speaker == "npc" and self.view.portraitPart
        and self.view.portraitPart.portrait
        and self.view.portraitPart.portrait.pulseSpeech
    then
        self.view.portraitPart.portrait:pulseSpeech(Text.Resolve(message.payload))
    end
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

function Session:queueMessage(speaker, payload)
    if payload == nil then return end
    if type(payload) == "table" and payload[1] ~= nil
        and payload.key == nil and payload.text == nil
    then
        local index
        for index = 1, #payload do self:queueMessage(speaker, payload[index]) end
        return
    end
    local previous = self.queue[#self.queue]
    local readyAt = math.max(now(), previous and previous.readyAt or 0)
    if speaker == "npc" then readyAt = readyAt + self:delayFor(payload) end
    self.queue[#self.queue + 1] = {
        speaker = speaker,
        payload = Text.Payload(payload),
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
                action = choice.action or choice.onSelect,
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
        self.view:close()
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
    self:append("player", evaluate(choice.text, self.context, choice.source, self))
    evaluate(choice.action, self.context, choice.source, self)
    local response = evaluate(choice.response, self.context, choice.source, self)
    if response then self:queueMessage("npc", response) end
    self.pendingNext = evaluate(choice.next, self.context, choice.source, self)
    self.pendingClose = evaluate(choice.close, self.context, choice.source, self) == true
    if #self.queue == 0 then self:finishPending() end
    return true
end

function Session:finishPending()
    self.busy = false
    self.view.historyPart:setTyping(nil)
    if self.pendingClose then
        self.pendingClose = nil
        self.view:close()
        return
    end
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
        self:append(queued.speaker, queued.payload)
        queued = self.queue[1]
        self.view.historyPart:setTyping(queued and queued.speaker or nil)
    end
    if #self.queue == 0 and self.busy then self:finishPending() end
end

return Session
