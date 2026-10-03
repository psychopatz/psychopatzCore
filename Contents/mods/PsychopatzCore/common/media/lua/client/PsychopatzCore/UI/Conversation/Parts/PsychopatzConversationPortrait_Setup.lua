local Portrait = PsychopatzConversationPortrait
local Conversation = PsychopatzCore.Conversation
local Input = require
    "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPortrait_Input"

function Portrait:createChildren()
    PsychopatzConversationPart.createChildren(self)
    self.portrait = PsychopatzPortraitPanel:new(
        2,
        2,
        self.width - 4,
        self.height - 4,
        {
            showBackground = false,
            showBorder = false,
            faceOnly = true,
            animate = true,
            portraitAnimation = true,
            -- Portraits intentionally use the zombie anim-set family: it is
            -- the family containing the close-up emote nodes (including
            -- WaveHi). Camera framing remains face-only below.
            animSetName = "zombie",
            stateName = "idle",
            zoom = 14,
            yOffset = -0.85,
            padding = 0,
            screenVariant = self:getScreenVariant(),
        }
    )
    self.portrait:initialise()
    self.portrait:instantiate()
    self.portrait:setAnchorLeft(true)
    self.portrait:setAnchorRight(true)
    self.portrait:setAnchorTop(true)
    self.portrait:setAnchorBottom(true)
    Input.InstallLayoutPointerBridge(self, self.portrait)
    Input.InstallLayoutPointerBridge(self, self.portrait.modelView)

    -- Keep the resize affordance above the full-size 3D model. The model is
    -- an eager mouse consumer and otherwise hides and intercepts the corner
    -- that common conversation parts use for resizing.
    self:addChild(self.portrait)
    self.resizeGrip = Input.ResizeGrip:new(
        self.width - 14, self.height - 14, 14, 14, self
    )
    self.resizeGrip:initialise()
    self.resizeGrip:instantiate()
    self.resizeGrip:setVisible(self.editMode == true)
    self:addChild(self.resizeGrip)
    self:applyTarget()
end

function Portrait:setTarget(character, spec)
    self.targetCharacter = character
    self.targetSpec = spec or {}
    if type(spec) == "table" and spec.screenVariant ~= nil then
        self.screenVariant = Input.NormalizeScreenVariant(spec.screenVariant)
    end
    self:applyTarget()
end

function Portrait:syncResizeGrip()
    if not self.resizeGrip then return end
    self.resizeGrip:setX(math.max(0, self.width - 14))
    self.resizeGrip:setY(math.max(0, self.height - 14))
end

function Portrait:setEditMode(enabled)
    if not enabled and self.layoutPointerPanel
        and self.layoutPointerPanel.setCapture
    then
        self.layoutPointerPanel:setCapture(false)
        self.layoutPointerPanel = nil
    end
    PsychopatzConversationPart.setEditMode(self, enabled)
    if self.resizeGrip then
        self.resizeGrip:setVisible(enabled == true)
    end
end

function Portrait:applyTarget()
    if self.portrait and (self.targetCharacter or self.targetSpec) then
        self.portrait:setTarget(self.targetCharacter, self.targetSpec, true)
    end
end

function Portrait:onPartResize()
    PsychopatzConversationPart.onPartResize(self)
    if self.portrait then
        self.portrait:setPortraitBounds(2, 2, self.width - 4, self.height - 4)
    end
    self:syncResizeGrip()
end

function Portrait:new(x, y, width, height, options)
    local portraitSpec
    local screenVariant
    options = options or {}
    options.partID = "portrait"
    options.minimumWidth = options.minimumWidth or 150
    options.minimumHeight = options.minimumHeight or 150
    options.title = options.title or {
        key = "UI_PsychopatzConversation_Portrait",
        fallback = "PORTRAIT FEED",
    }
    local o = PsychopatzConversationPart.new(self, x, y, width, height, options)
    o.targetCharacter = options.character
    o.targetSpec = options.portraitSpec or {}
    portraitSpec = type(options.portraitSpec) == "table"
        and options.portraitSpec or nil
    screenVariant = options.screenVariant
        or (portraitSpec and portraitSpec.screenVariant)
    o.screenVariant = Input.NormalizeScreenVariant(screenVariant)
    o:setBackground(options.backgroundID or "twilight")
    return o
end

return Portrait
