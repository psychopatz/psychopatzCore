require "PsychopatzCore/UI/Conversation/PsychopatzConversationSettings"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationBackgrounds"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationView"

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
