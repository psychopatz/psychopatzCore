require "ISUI/ISPanel"
require "ISUI/ISButton"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationAnimator"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationLifecycle"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationLayout"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationSession"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationTheme"
require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPortrait"
require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationChat"
require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationChoices"

PsychopatzConversationView = ISPanel:derive("PsychopatzConversationView")

local Conversation = PsychopatzCore.Conversation
local Animator = Conversation.Animator
local Lifecycle = Conversation.Lifecycle
local Layout = Conversation.Layout
local Text = Conversation.Text
local Theme = Conversation.Theme

local function buttonLabel(key, fallback)
    return Text.Resolve({ key = key, fallback = fallback })
end

function PsychopatzConversationView:initialise()
    ISPanel.initialise(self)
    self.background = false
    self.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
end

function PsychopatzConversationView:createChildren()
    ISPanel.createChildren(self)
    local accent = Theme.Resolve(self.spec)
    local portrait = Layout.Resolve("portrait", self.width, self.height)
    local history = Layout.Resolve("history", self.width, self.height)
    local choices = Layout.Resolve("choices", self.width, self.height)
    self.portraitPart = PsychopatzConversationPortrait:new(
        portrait.x, portrait.y, portrait.width, portrait.height,
        {
            owner = self,
            character = self.spec.character,
            portraitSpec = self.spec.portrait,
            backgroundID = self.spec.backgroundID,
            editLabel = { key = "UI_PsychopatzConversation_Portrait", fallback = "Portrait" },
        }
    )
    self.portraitPart:initialise()
    self.portraitPart:instantiate()
    self:addChild(self.portraitPart)

    self.historyPart = PsychopatzConversationChat:new(
        history.x, history.y, history.width, history.height,
        {
            owner = self,
            editLabel = { key = "UI_PsychopatzConversation_History", fallback = "Conversation history" },
        }
    )
    self.historyPart:initialise()
    self.historyPart:instantiate()
    self:addChild(self.historyPart)

    self.choicesPart = PsychopatzConversationChoices:new(
        choices.x, choices.y, choices.width, choices.height,
        {
            owner = self,
            editLabel = { key = "UI_PsychopatzConversation_Choices", fallback = "Choices" },
        }
    )
    self.choicesPart:initialise()
    self.choicesPart:instantiate()
    self:addChild(self.choicesPart)

    self.extensionParts = {}
    for _, definition in ipairs(self.spec.extensionParts or {}) do
        local partID = definition and definition.partID
        local factory = definition and definition.factory
        if type(partID) == "string" and partID ~= ""
            and type(factory) == "function"
        then
            local bounds = Layout.Resolve(
                partID,
                self.width,
                self.height
            )
            local part = factory(bounds, {
                owner = self,
                definition = definition,
                spec = self.spec,
            })
            if part then
                part:initialise()
                part:instantiate()
                part:setVisible(definition.visible ~= false)
                self:addChild(part)
                self.extensionParts[partID] = part
            end
        end
    end

    self.closeButton = ISButton:new(
        self.width - 42, 10, 32, 28,
        buttonLabel("UI_PsychopatzConversation_Close", "X"),
        self,
        PsychopatzConversationView.onCloseButton
    )
    self.closeButton:initialise()
    self.closeButton:instantiate()
    self.closeButton:setAnchorLeft(false)
    self.closeButton:setAnchorRight(true)
    self.closeButton.backgroundColor = { r = 0.14, g = 0.05, b = 0.04, a = 0.88 }
    self.closeButton.backgroundColorMouseOver = { r = 0.42, g = 0.08, b = 0.05, a = 0.95 }
    self.closeButton.borderColor = { r = 0.92, g = 0.38, b = 0.26, a = 0.8 }
    self:addChild(self.closeButton)

    self.layoutButton = ISButton:new(
        self.width - 170, 10, 120, 28,
        buttonLabel("UI_PsychopatzConversation_EditLayout", "Edit layout"),
        self,
        PsychopatzConversationView.toggleEditMode
    )
    self.layoutButton:initialise()
    self.layoutButton:instantiate()
    self.layoutButton:setAnchorLeft(false)
    self.layoutButton:setAnchorRight(true)
    self.layoutButton.backgroundColor = {
        r = accent.r * 0.16,
        g = accent.g * 0.16,
        b = accent.b * 0.16,
        a = 0.88,
    }
    self.layoutButton.backgroundColorMouseOver = {
        r = accent.r * 0.34,
        g = accent.g * 0.34,
        b = accent.b * 0.34,
        a = 0.95,
    }
    self.layoutButton.borderColor = {
        r = accent.r,
        g = accent.g,
        b = accent.b,
        a = 0.78,
    }
    self.layoutButton:setVisible(
        self.editMode or Conversation.Settings.Get("showEditorButton", true) == true
    )
    self:addChild(self.layoutButton)
end

function PsychopatzConversationView:onCloseButton()
    self:close("close_button")
end

function PsychopatzConversationView:start()
    local started, reason = Lifecycle.Begin(self)
    if not started then
        self:close(reason)
        return false
    end
    self.session = Conversation.Session.New(self, self.spec)
    self.session:start()
    return true
end

function PsychopatzConversationView:isConversationInteractive()
    return self.animationInteractive == true
        and self.editMode ~= true
        and self.closing ~= true
        and self.session
        and self.session.busy ~= true
end

function PsychopatzConversationView:onChoiceSelected(choice)
    if self.session then self.session:selectChoice(choice) end
end

-- Consumers may learn new presentation-safe information while a conversation
-- is open (for example, an NPC answering "What's your name?"). Refresh the
-- active definition in place without resetting the message history.
function PsychopatzConversationView:refreshConversationSpec(spec)
    if type(spec) ~= "table" then return false end
    self.spec = spec
    if self.portraitPart then
        self.portraitPart:setTarget(spec.character, spec.portrait)
        self.portraitPart:setBackground(spec.backgroundID)
    end
    if self.session then
        self.session.spec = spec
        self.session.context = spec.context or {}
        local nodeID = self.session.currentNodeID
        local node = nodeID and spec.nodes and spec.nodes[nodeID] or nil
        if node then
            self.session.currentNode = node
            if self.session.pendingChoices then
                self.session.pendingChoices = node.choices or {}
            elseif self.session.busy ~= true then
                self.session:setChoices(node.choices or {})
            end
        end
    end
    return true
end

function PsychopatzConversationView:savePartLayout(part)
    Layout.Save(part.partID, {
        x = part:getX(),
        y = part:getY(),
        width = part:getWidth(),
        height = part:getHeight(),
    }, self.width, self.height, true)
end

function PsychopatzConversationView:applySavedLayout()
    local parts = {
        portrait = self.portraitPart,
        history = self.historyPart,
        choices = self.choicesPart,
    }
    for id, part in pairs(self.extensionParts or {}) do
        parts[id] = part
    end
    local id
    local part
    for id, part in pairs(parts) do
        if part then
            local bounds = Layout.Resolve(id, self.width, self.height)
            part:setX(bounds.x)
            part:setY(bounds.y)
            part:setWidth(bounds.width)
            part:setHeight(bounds.height)
            if part.onPartResize then part:onPartResize() end
        end
    end
end

function PsychopatzConversationView:toggleEditMode()
    self.editMode = not self.editMode
    self.portraitPart:setEditMode(self.editMode)
    self.historyPart:setEditMode(self.editMode)
    self.choicesPart:setEditMode(self.editMode)
    for _, part in pairs(self.extensionParts or {}) do
        if part.setEditMode then part:setEditMode(self.editMode) end
    end
    self.layoutButton:setTitle(self.editMode
        and buttonLabel("UI_PsychopatzConversation_SaveLayout", "Done")
        or buttonLabel("UI_PsychopatzConversation_EditLayout", "Edit layout"))
    if self.editMode then
        Animator.SkipOpen(self.animator)
        self.portraitPart:setReveal(1)
        self.historyPart:setReveal(1)
        self.choicesPart:setReveal(1)
        for _, part in pairs(self.extensionParts or {}) do
            if part.setReveal then part:setReveal(1) end
        end
    end
end

function PsychopatzConversationView:update()
    ISPanel.update(self)
    if self.width ~= getCore():getScreenWidth()
        or self.height ~= getCore():getScreenHeight()
    then
        self:setWidth(getCore():getScreenWidth())
        self:setHeight(getCore():getScreenHeight())
        self:applySavedLayout()
    end
    local state = Animator.Get(self.animator)
    self.animationInteractive = state.interactive
    self.portraitPart:setReveal(state.portrait)
    self.historyPart:setReveal(state.history)
    self.choicesPart:setReveal(state.choices)
    for _, part in pairs(self.extensionParts or {}) do
        if part.setReveal then part:setReveal(state.history) end
    end
    local interruption = Lifecycle.Update(self)
    if interruption and not self.closing then
        self:close(interruption)
    end
    if self.session and not self.editMode then self.session:update() end
    if self.closing and state.done then self:destroy() end
end

function PsychopatzConversationView:prerender()
    ISPanel.prerender(self)
    self:drawRect(0, 0, self.width, self.height, 0.075, 0, 0, 0)
    if self.editMode then
        self:drawRect(0, 0, self.width, self.height, 0.32, 0, 0, 0)
        self:drawTextCentre(
            buttonLabel(
                "UI_PsychopatzConversation_EditHint",
                "Drag panels to move them; drag the bright corner to resize."
            ),
            self.width / 2,
            16,
            0.82, 0.94, 0.86, 1,
            UIFont.Small
        )
    end
end

function PsychopatzConversationView:close(reason)
    if self.closing then return end
    if self.editMode then self:toggleEditMode() end
    if type(reason) ~= "string" then reason = nil end
    self.closeReason = reason or self.closeReason or "closed"
    Lifecycle.Finish(self, self.closeReason)
    self.closing = true
    Animator.StartClosing(self.animator)
end

function PsychopatzConversationView:destroy()
    Lifecycle.Finish(self, self.closeReason or "replaced")
    if Conversation.instance == self then Conversation.instance = nil end
    self:setVisible(false)
    self:removeFromUIManager()
end

function PsychopatzConversationView:onKeyRelease(key)
    if Keyboard and key == Keyboard.KEY_ESCAPE then
        self:close("escape")
        return true
    end
    return ISPanel.onKeyRelease(self, key)
end

function PsychopatzConversationView:new(spec)
    local width = getCore and getCore():getScreenWidth() or 1280
    local height = getCore and getCore():getScreenHeight() or 720
    local o = ISPanel:new(0, 0, width, height)
    setmetatable(o, self)
    self.__index = self
    o.spec = spec or {}
    o.animator = Animator.New()
    o.editMode = false
    o.closing = false
    o.animationInteractive = false
    o.lifecycleStarted = false
    o.lifecycleFinished = false
    o.lifecycleState = nil
    o.closeReason = nil
    return o
end

return PsychopatzConversationView
