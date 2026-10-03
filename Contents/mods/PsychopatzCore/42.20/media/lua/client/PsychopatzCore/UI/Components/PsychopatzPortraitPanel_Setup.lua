local Descriptor = require
    "PsychopatzCore/UI/Components/PsychopatzPortraitPanel_Descriptor"
local CRT_TEXTURE_PATH = "media/ui/Effects/crt.png"
local Window = PsychopatzPortraitPanel

function Window:initialise()
    ISPanel.initialise(self)
    -- This component draws its optional background and border itself below.
    -- Disable ISPanel's default pass so transparent portraits do not retain
    -- the stock one-pixel edge and opaque portraits are not drawn twice.
    self.background = false
    self.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.borderColor = { r = 0.3, g = 0.3, b = 0.3, a = 1 }
    self.avatarBackground = self.showBackground
        and getTexture
        and getTexture("media/ui/avatarBackgroundWhite.png")
        or nil
    self.crtTexture = getTexture and getTexture(CRT_TEXTURE_PATH) or nil
end

function Window:createChildren()
    ISPanel.createChildren(self)
    self:ensureModelView()
end

function Window:ensureModelView()
    local padding = tonumber(self.padding) or 2
    if self.modelView then return self.modelView end
    self.modelView = Descriptor.Model:new(
        padding,
        padding,
        math.max(1, self.width - padding * 2),
        math.max(1, self.height - padding * 2)
    )
    self.modelView:initialise()
    self.modelView:instantiate()
    self.modelView.animateEnabled = self.animate ~= false
    self.modelView:setAnchorLeft(true)
    self.modelView:setAnchorRight(true)
    self.modelView:setAnchorTop(true)
    self.modelView:setAnchorBottom(true)
    self:addChild(self.modelView)
    -- A false anim-set value deliberately leaves the model on the engine's
    -- normal human avatar set. Descriptor-backed survivor portraits use this
    -- to avoid inheriting the slouched zombie posture.
    if self.animSetName then
        self.modelView:setAnimSetName(self.animSetName)
    end
    self:applyViewState()
    self:applyModelVisibility(self.contentOpacity)
    return self.modelView
end

function Window:applyModelVisibility(value)
    local alpha = math.max(0, math.min(1, tonumber(value) or 1))
    local model = self.modelView
    if not model then return end
    local visible = alpha > 0.001
    if self.modelVisibilityApplied ~= visible then
        -- Java Engine Ground Truth: UI3DModel inherits UIElement.setVisible
        -- but exposes no setAlpha or setColor method in Build 42.20.
        model:setVisible(visible)
        self.modelVisibilityApplied = visible
    end
end

function Window:setContentOpacity(value)
    self.contentOpacity = math.max(0, math.min(1, tonumber(value) or 1))
    self:applyModelVisibility(self.contentOpacity)
end

return Window
