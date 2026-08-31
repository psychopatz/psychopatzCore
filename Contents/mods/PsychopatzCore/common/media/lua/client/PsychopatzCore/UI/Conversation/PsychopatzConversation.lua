require "PsychopatzCore/UI/Conversation/PsychopatzConversationSettings"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationBackgrounds"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationView"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationSession"

local Conversation = PsychopatzCore.Conversation

function Conversation.Open(spec)
    spec = spec or {}
    if Conversation.instance then Conversation.instance:destroy() end
    local view = PsychopatzConversationView:new(spec)
    view:initialise()
    view:instantiate()
    view:addToUIManager()
    Conversation.instance = view
    view:start()
    if spec.editMode then view:toggleEditMode() end
    return view
end

function Conversation.Close()
    if Conversation.instance then Conversation.instance:close() end
end

function Conversation.CreateHeadless(spec)
    spec = spec or {}
    local Lifecycle = Conversation.Lifecycle
    local host = {
        spec = spec,
        headless = true,
        session = nil,
        closed = false,
        historyPart = {
            messages = {},
            typingSpeaker = nil,
        },
        choicesPart = {},
        extensionParts = {},
    }
    function host.historyPart:setMessages(messages)
        self.messages = messages or {}
    end
    function host.historyPart:addMessage(message)
        self.messages[#self.messages + 1] = message
    end
    function host.historyPart:setTyping(speaker)
        self.typingSpeaker = speaker
    end
    function host.choicesPart:setChoices(choices)
        self.choices = choices or {}
    end
    function host:isConversationInteractive()
        return self.closed ~= true
            and self.session ~= nil
            and self.session.busy ~= true
    end
    function host:close(reason)
        self.closed = true
        if Lifecycle and Lifecycle.Finish then
            Lifecycle.Finish(self, reason or "headless_closed")
        end
    end
    local started, reason = Lifecycle and Lifecycle.Begin
        and Lifecycle.Begin(host) or true
    if not started then
        host.closed = true
        host.lifecycleError = reason or "lifecycle_rejected"
        return host
    end
    host.session = Conversation.Session.New(host, spec)
    host.session:loadHistory()
    host.session.currentNodeID = spec.start or "start"
    host.session.currentNode = host.session:getNode(host.session.currentNodeID)
    return host
end

function Conversation.OpenPreview(editMode)
    return Conversation.Open({
        namespace = "psychopatz-preview",
        npcID = "preview",
        backgroundID = "twilight",
        editMode = editMode == true,
        portrait = {
            id = "preview",
            identitySeed = 9127,
            isFemale = false,
            faceOnly = true,
            preferDescriptor = true,
            appearance = {
                hairModel = "Short",
                beardModel = "Goatee",
            },
        },
        start = "start",
        nodes = {
            start = {
                npc = {
                    key = "UI_PsychopatzConversation_PreviewGreeting",
                    fallback = "Evening. This is a preview of the conversation interface.",
                    delayMs = 150,
                },
                choices = {
                    {
                        text = {
                            key = "UI_PsychopatzConversation_PreviewChoice",
                            fallback = "Show me another message.",
                        },
                        response = {
                            key = "UI_PsychopatzConversation_PreviewReply",
                            fallback = "Messages stay here for the current in-game day.",
                        },
                        next = "finish",
                    },
                    {
                        text = {
                            key = "UI_PsychopatzConversation_Goodbye",
                            fallback = "Goodbye.",
                        },
                        close = true,
                    },
                },
            },
            finish = {
                choices = {
                    {
                        text = {
                            key = "UI_PsychopatzConversation_Goodbye",
                            fallback = "Goodbye.",
                        },
                        response = {
                            key = "UI_PsychopatzConversation_PreviewGoodbye",
                            fallback = "Stay safe out there.",
                        },
                        close = true,
                    },
                },
            },
        },
    })
end

function Conversation.OpenLayoutEditor()
    return Conversation.OpenPreview(true)
end

return Conversation
