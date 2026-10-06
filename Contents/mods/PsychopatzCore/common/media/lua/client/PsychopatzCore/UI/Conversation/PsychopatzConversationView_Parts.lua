local View = PsychopatzConversationView
local Internal = View.Internal
local Layout = Internal.Layout

local function initialisePart(view, part)
    if not part then return nil end
    part:initialise()
    part:instantiate()
    view:addChild(part)
    return part
end

function Internal.buildParts(view)
    local spec = view.spec
    local portrait = Layout.Resolve("portrait", view.width, view.height)
    local history = Layout.Resolve("history", view.width, view.height)
    local choices = Layout.Resolve("choices", view.width, view.height)

    view.portraitPart = initialisePart(view, PsychopatzConversationPortrait:new(
        portrait.x, portrait.y, portrait.width, portrait.height,
        {
            owner = view,
            character = spec.character,
            portraitSpec = spec.portrait,
            backgroundID = spec.backgroundID,
            screenVariant = Internal.screenVariantFor(spec),
            editLabel = {
                key = "UI_PsychopatzConversation_Portrait",
                fallback = "Portrait",
            },
        }
    ))
    view.historyPart = initialisePart(view, PsychopatzConversationChat:new(
        history.x, history.y, history.width, history.height,
        {
            owner = view,
            editLabel = {
                key = "UI_PsychopatzConversation_History",
                fallback = "Conversation history",
            },
        }
    ))
    view.choicesPart = initialisePart(view, PsychopatzConversationChoices:new(
        choices.x, choices.y, choices.width, choices.height,
        {
            owner = view,
            editLabel = {
                key = "UI_PsychopatzConversation_Choices",
                fallback = "Choices",
            },
        }
    ))

    view.extensionParts = {}
    for _, definition in ipairs(spec.extensionParts or {}) do
        local partID = definition and definition.partID
        local factory = definition and definition.factory
        if type(partID) == "string" and partID ~= ""
            and type(factory) == "function"
        then
            local bounds = Layout.Resolve(partID, view.width, view.height)
            local part = factory(bounds, {
                owner = view,
                partID = partID,
                definition = definition,
                spec = spec,
            })
            if part then
                part:initialise()
                part:instantiate()
                part:setVisible(definition.visible ~= false)
                view:addChild(part)
                view.extensionParts[partID] = part
            end
        end
    end
end

return Internal
