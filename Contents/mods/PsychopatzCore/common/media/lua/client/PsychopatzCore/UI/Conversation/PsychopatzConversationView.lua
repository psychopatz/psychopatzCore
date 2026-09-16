require "ISUI/ISPanel"
require "ISUI/ISButton"
require "PsychopatzCore/Debug/PsychopatzDebug"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationAnimator"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationLifecycle"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationLayout"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationSession"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationTheme"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationText"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationOpacity"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationOpacityControl"
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
local OpacityControl = Conversation.OpacityControl
local Debug = PsychopatzCore.Debug

local function buttonLabel(key, fallback)
    return Text.Resolve({ key = key, fallback = fallback })
end

local function currentPlayer()
    return getPlayer and getPlayer() or nil
end

local function screenVariantFor(spec)
    if type(spec) ~= "table" then return "subtle" end
    local variant = spec.screenVariant
    if variant == nil and type(spec.portrait) == "table" then
        variant = spec.portrait.screenVariant
    end
    return variant or "subtle"
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
            screenVariant = screenVariantFor(self.spec),
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

    self.resetLayoutButton = ISButton:new(
        self.width - 320, 10, 140, 28,
        buttonLabel(
            "UI_PsychopatzConversation_ResetLayout",
            "RESET TO DEFAULT"
        ),
        self,
        PsychopatzConversationView.onResetLayoutButton
    )
    self.resetLayoutButton:initialise()
    self.resetLayoutButton:instantiate()
    self.resetLayoutButton:setAnchorLeft(false)
    self.resetLayoutButton:setAnchorRight(true)
    self.resetLayoutButton.backgroundColor = {
        r = 0.20,
        g = 0.10,
        b = 0.04,
        a = 0.88,
    }
    self.resetLayoutButton.backgroundColorMouseOver = {
        r = 0.42,
        g = 0.20,
        b = 0.06,
        a = 0.95,
    }
    self.resetLayoutButton.borderColor = {
        r = 0.95,
        g = 0.58,
        b = 0.22,
        a = 0.82,
    }
    self.resetLayoutButton:setVisible(self.editMode == true)
    self:addChild(self.resetLayoutButton)

    self.crtDebugButton = ISButton:new(
        self.width - 470, 10, 140, 28,
        buttonLabel(
            "UI_PsychopatzConversation_DebugCRT_Off",
            "CRT DEBUG: OFF"
        ),
        self,
        PsychopatzConversationView.onCRTDebugButton
    )
    self.crtDebugButton:initialise()
    self.crtDebugButton:instantiate()
    self.crtDebugButton:setAnchorLeft(false)
    self.crtDebugButton:setAnchorRight(true)
    self.crtDebugButton.backgroundColor = {
        r = 0.18,
        g = 0.08,
        b = 0.28,
        a = 0.88,
    }
    self.crtDebugButton.backgroundColorMouseOver = {
        r = 0.38,
        g = 0.16,
        b = 0.52,
        a = 0.95,
    }
    self.crtDebugButton.borderColor = {
        r = 0.78,
        g = 0.38,
        b = 0.92,
        a = 0.82,
    }
    self:addChild(self.crtDebugButton)
    self:refreshCRTDebugButton()
    self:attachOpacityControls()
    self:refreshOpacityControls()
end

function PsychopatzConversationView:attachOpacityControls()
    if not OpacityControl then return end
    local parts = {
        self.portraitPart,
        self.historyPart,
        self.choicesPart,
    }
    for _, part in pairs(self.extensionParts or {}) do
        parts[#parts + 1] = part
    end
    for _, part in ipairs(parts) do
        if part and part.attachOpacityControl then
            part:attachOpacityControl(self)
        end
    end
end

function PsychopatzConversationView:refreshOpacityControls()
    local parts = {
        self.portraitPart,
        self.historyPart,
        self.choicesPart,
    }
    for _, part in pairs(self.extensionParts or {}) do
        parts[#parts + 1] = part
    end
    for _, part in ipairs(parts) do
        if part then
            if part.positionOpacityControl then
                part:positionOpacityControl()
            end
            if part.refreshOpacityControlVisibility then
                part:refreshOpacityControlVisibility()
            end
            if part.opacityControl and part.opacityControl.parent == self
                and part.opacityControl.bringToTop
            then
                part.opacityControl:bringToTop()
            end
        end
    end
end

function PsychopatzConversationView:onCloseButton()
    self:close("close_button")
end

function PsychopatzConversationView:onResetLayoutButton()
    if self.editMode ~= true then return end
    if Layout and Layout.ResetAll then Layout.ResetAll(true) end
end

function PsychopatzConversationView:canUseDebug()
    return Debug and type(Debug.CanUse) == "function"
        and Debug.CanUse(currentPlayer()) == true
end

function PsychopatzConversationView:isCRTDebugOn()
    return self.crtDebugOverrideActive == true
        and self.crtDebugEnabled == true
end

function PsychopatzConversationView:setCRTDebugEnabled(enabled)
    enabled = enabled == true
    if enabled and not self:canUseDebug() then return false end
    self.crtDebugEnabled = enabled
    self.crtDebugOverrideActive = true
    if self.portraitPart
        and self.portraitPart.setTemporaryScreenVariant
    then
        self.portraitPart:setTemporaryScreenVariant(
            enabled and "crt" or "clean"
        )
    end
    if self.crtDebugButton then
        self.crtDebugButton:setTitle(buttonLabel(
            enabled and "UI_PsychopatzConversation_DebugCRT_On"
                or "UI_PsychopatzConversation_DebugCRT_Off",
            enabled and "CRT DEBUG: ON" or "CRT DEBUG: OFF"
        ))
    end
    return true
end

function PsychopatzConversationView:clearCRTDebug()
    self.crtDebugEnabled = false
    self.crtDebugOverrideActive = false
    if self.portraitPart
        and self.portraitPart.setTemporaryScreenVariant
    then
        self.portraitPart:setTemporaryScreenVariant(nil)
    end
    if self.crtDebugButton then
        self.crtDebugButton:setTitle(buttonLabel(
            "UI_PsychopatzConversation_DebugCRT_Off",
            "CRT DEBUG: OFF"
        ))
    end
end

function PsychopatzConversationView:refreshCRTDebugButton()
    local visible = self.editMode == true and self:canUseDebug()
    if not visible and self.crtDebugOverrideActive then
        self:clearCRTDebug()
    end
    if self.crtDebugButton then
        self.crtDebugButton:setVisible(visible)
        self.crtDebugButton:setTitle(buttonLabel(
            self:isCRTDebugOn()
                and "UI_PsychopatzConversation_DebugCRT_On"
                or "UI_PsychopatzConversation_DebugCRT_Off",
            self:isCRTDebugOn() and "CRT DEBUG: ON" or "CRT DEBUG: OFF"
        ))
    end
end

function PsychopatzConversationView:onCRTDebugButton()
    if not self:canUseDebug() then
        self:clearCRTDebug()
        self:refreshCRTDebugButton()
        return
    end
    self:setCRTDebugEnabled(not self:isCRTDebugOn())
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
        self.portraitPart:setScreenVariant(screenVariantFor(spec))
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
    if self.editMode then self:clearCRTDebug() end
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
    self.resetLayoutButton:setVisible(self.editMode == true)
    self:refreshCRTDebugButton()
    self:refreshOpacityControls()
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
    self:refreshCRTDebugButton()
    self:refreshOpacityControls()
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
    o.crtDebugEnabled = false
    o.crtDebugOverrideActive = false
    o.closing = false
    o.animationInteractive = false
    o.lifecycleStarted = false
    o.lifecycleFinished = false
    o.lifecycleState = nil
    o.closeReason = nil
    return o
end

return PsychopatzConversationView
