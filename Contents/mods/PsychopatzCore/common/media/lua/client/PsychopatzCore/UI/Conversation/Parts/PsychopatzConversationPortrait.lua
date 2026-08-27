require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationPart"
require "PsychopatzCore/UI/Components/PsychopatzPortraitPanel"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationBackgrounds"

PsychopatzConversationPortrait = PsychopatzConversationPart:derive(
    "PsychopatzConversationPortrait"
)

local Conversation = PsychopatzCore.Conversation
local Text = Conversation.Text

local function partCoordinate(part, panel, value, axis)
    local coordinate = tonumber(value) or 0
    local current = panel
    local getter
    local parent
    local offset
    while current and current ~= part do
        getter = axis == "x" and current.getX or current.getY
        offset = getter and getter(current) or current[axis]
        coordinate = coordinate + (tonumber(offset) or 0)
        parent = current.getParent and current:getParent() or current.parent
        current = parent
    end
    return coordinate
end

-- The 3D portrait consumes pointer input to rotate the face.  During layout
-- editing, forward that input to its containing panel so dragging the face
-- moves/resizes the portrait window like every other conversation panel.
local function routeLayoutPointer(part, original, method, panel, x, y)
    if part and part.editMode then
        local result
        if method == "onMouseDown" then
            result = part[method](
                part,
                partCoordinate(part, panel, x, "x"),
                partCoordinate(part, panel, y, "y")
            )
            if result and panel.setCapture then
                pcall(panel.setCapture, panel, true)
            end
            part.layoutPointerPanel = panel
            return result
        end
        result = part[method](part, x, y)
        if method == "onMouseUp" or method == "onMouseUpOutside" then
            if panel.setCapture then pcall(panel.setCapture, panel, false) end
            if part.layoutPointerPanel == panel then
                part.layoutPointerPanel = nil
            end
        end
        return result
    end
    return original and original(panel, x, y) or false
end

local ResizeGrip = ISPanel:derive("PsychopatzConversationPortraitResizeGrip")

function ResizeGrip:initialise()
    ISPanel.initialise(self)
    self.background = false
    self.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.borderColor = { r = 0, g = 0, b = 0, a = 0 }
end

function ResizeGrip:prerender()
    if not self.owner or not self.owner.editMode then return end
    self:drawRect(0, 0, self.width, self.height,
        0.92, 0.30, 0.82, 1.0)
end

function ResizeGrip:onMouseDown(x, y)
    if not self.owner or not self.owner.editMode then return false end
    local accepted = self.owner:onMouseDown(self.x + x, self.y + y)
    if accepted and self.setCapture then
        pcall(self.setCapture, self, true)
    end
    if accepted then self.owner.layoutPointerPanel = self end
    return accepted
end

function ResizeGrip:onMouseMove(dx, dy)
    if not self.owner or not self.owner.editMode then return false end
    return self.owner:onMouseMove(dx, dy)
end

function ResizeGrip:onMouseMoveOutside(dx, dy)
    if not self.owner or not self.owner.editMode then return false end
    return self.owner:onMouseMoveOutside(dx, dy)
end

function ResizeGrip:onMouseUp(x, y)
    if not self.owner then return false end
    local accepted = self.owner:onMouseUp(self.x + x, self.y + y)
    if self.setCapture then pcall(self.setCapture, self, false) end
    if self.owner.layoutPointerPanel == self then
        self.owner.layoutPointerPanel = nil
    end
    return accepted
end

function ResizeGrip:onMouseUpOutside(x, y)
    if not self.owner then return false end
    local accepted = self.owner:onMouseUpOutside(self.x + x, self.y + y)
    if self.setCapture then pcall(self.setCapture, self, false) end
    if self.owner.layoutPointerPanel == self then
        self.owner.layoutPointerPanel = nil
    end
    return accepted
end

function ResizeGrip:new(x, y, width, height, owner)
    local o = ISPanel.new(self, x, y, width, height)
    o.owner = owner
    return o
end

local function installLayoutPointerBridge(part, panel)
    if not panel or panel.layoutPointerBridgeInstalled then return end
    panel.layoutPointerBridgeInstalled = true
    local originalMouseDown = panel.onMouseDown
    local originalMouseMove = panel.onMouseMove
    local originalMouseMoveOutside = panel.onMouseMoveOutside
    local originalMouseUp = panel.onMouseUp
    local originalMouseUpOutside = panel.onMouseUpOutside
    panel.onMouseDown = function(element, x, y)
        return routeLayoutPointer(
            part, originalMouseDown, "onMouseDown", element, x, y
        )
    end
    panel.onMouseMove = function(element, x, y)
        return routeLayoutPointer(
            part, originalMouseMove, "onMouseMove", element, x, y
        )
    end
    panel.onMouseMoveOutside = function(element, x, y)
        return routeLayoutPointer(
            part,
            originalMouseMoveOutside,
            "onMouseMoveOutside",
            element,
            x,
            y
        )
    end
    panel.onMouseUp = function(element, x, y)
        return routeLayoutPointer(
            part, originalMouseUp, "onMouseUp", element, x, y
        )
    end
    panel.onMouseUpOutside = function(element, x, y)
        return routeLayoutPointer(
            part,
            originalMouseUpOutside,
            "onMouseUpOutside",
            element,
            x,
            y
        )
    end
end

function PsychopatzConversationPortrait:createChildren()
    ISPanel.createChildren(self)
    self.portrait = PsychopatzPortraitPanel:new(2, 2, self.width - 4, self.height - 4, {
        showBackground = false,
        showBorder = false,
        faceOnly = true,
        animate = true,
        animSetName = false,
        stateName = "idle",
        zoom = 14,
        yOffset = -0.85,
        padding = 0,
    })
    self.portrait:initialise()
    self.portrait:instantiate()
    self.portrait:setAnchorLeft(true)
    self.portrait:setAnchorRight(true)
    self.portrait:setAnchorTop(true)
    self.portrait:setAnchorBottom(true)
    installLayoutPointerBridge(self, self.portrait)
    installLayoutPointerBridge(self, self.portrait.modelView)

    -- Keep the resize affordance above the full-size 3D model.  The model is
    -- an eager mouse consumer and otherwise both hides and intercepts the
    -- corner that the common conversation parts use for resizing.
    self:addChild(self.portrait)
    self.resizeGrip = ResizeGrip:new(
        self.width - 14, self.height - 14, 14, 14, self
    )
    self.resizeGrip:initialise()
    self.resizeGrip:instantiate()
    self.resizeGrip:setVisible(self.editMode == true)
    self:addChild(self.resizeGrip)
    self:applyTarget()
end

function PsychopatzConversationPortrait:setTarget(character, spec)
    self.targetCharacter = character
    self.targetSpec = spec or {}
    self:applyTarget()
end

function PsychopatzConversationPortrait:syncResizeGrip()
    if not self.resizeGrip then return end
    self.resizeGrip:setX(math.max(0, self.width - 14))
    self.resizeGrip:setY(math.max(0, self.height - 14))
end

function PsychopatzConversationPortrait:setEditMode(enabled)
    if not enabled and self.layoutPointerPanel
        and self.layoutPointerPanel.setCapture
    then
        pcall(self.layoutPointerPanel.setCapture,
            self.layoutPointerPanel, false)
        self.layoutPointerPanel = nil
    end
    PsychopatzConversationPart.setEditMode(self, enabled)
    if self.resizeGrip then
        self.resizeGrip:setVisible(enabled == true)
    end
end

function PsychopatzConversationPortrait:applyTarget()
    if self.portrait and (self.targetCharacter or self.targetSpec) then
        self.portrait:setTarget(self.targetCharacter, self.targetSpec, true)
    end
end

function PsychopatzConversationPortrait:setBackground(id)
    self.backgroundID = id or "twilight"
    self.backgroundDefinition = Conversation.Backgrounds.Get(self.backgroundID)
    self.backgroundTexture = nil
    if getTexture and self.backgroundDefinition then
        self.backgroundTexture = getTexture(self.backgroundDefinition.texture)
    end
end

function PsychopatzConversationPortrait:prerender()
    local reveal = self.reveal or 0
    if reveal <= 0.18 then
        self.reveal = 0
        PsychopatzConversationPart.prerender(self)
        self.reveal = reveal
    else
        PsychopatzConversationPart.prerender(self)
    end
    local alpha = self:getContentOpacity()
    local backgroundAlpha = self:getBackgroundOpacity()
    local accent = self:getAccentColor()
    if reveal <= 0 then
        if self.portrait then self.portrait:setVisible(false) end
        return
    end
    local linePhase = math.min(1, reveal / 0.18)
    local expansion = reveal <= 0.18 and 0 or ((reveal - 0.18) / 0.82)
    expansion = math.max(0, math.min(1, expansion))
    if expansion <= 0 then
        if self.portrait then self.portrait:setVisible(false) end
        self:drawRect(
            self.width * 0.5 * (1 - linePhase),
            math.floor(self.height / 2),
            self.width * linePhase,
            2,
            alpha,
            accent.r,
            accent.g,
            accent.b
        )
        return
    end
    local visibleH = math.max(2, self.height * expansion)
    local visibleY = (self.height - visibleH) / 2
    self:setStencilRect(1, visibleY, self.width - 2, visibleH)
    if self.backgroundTexture then
        local tint = self.backgroundDefinition.tint or { r = 1, g = 1, b = 1 }
        self:drawTextureScaled(
            self.backgroundTexture,
            2,
            2,
            self.width - 4,
            self.height - 4,
            backgroundAlpha,
            tint.r or 1,
            tint.g or 1,
            tint.b or 1
        )
    end
    if self.portrait then self.portrait:setVisible(true) end
end

function PsychopatzConversationPortrait:render()
    if (self.reveal or 0) > 0.18 then
        self:clearStencilRect()
        local alpha = self:getContentOpacity()
        local accent = self:getAccentColor()
        local bright = Conversation.Theme.Brighten(accent, 0.34)
        local context = self.owner
            and self.owner.spec
            and self.owner.spec.context
            or {}
        if alpha < 1 then
            -- ISUI3DModel has no portable alpha setter across supported PZ
            -- builds. Composite it down against the panel layer instead.
            self:drawRect(2, 2, self.width - 4, self.height - 4,
                1 - alpha, 0, 0, 0)
        end
        local scanY
        for scanY = 3, self.height - 4, 5 do
            self:drawRect(
                3,
                scanY,
                self.width - 7,
                1,
                alpha * 0.055,
                0.03,
                0.08,
                0.065
            )
        end
        local plateHeight = math.max(48, math.min(62, self.height * 0.18))
        local plateY = self.height - plateHeight - 3
        self:drawRect(
            3,
            plateY - 18,
            self.width - 7,
            18,
            alpha * 0.35,
            0,
            0,
            0
        )
        self:drawRect(
            3,
            plateY,
            self.width - 7,
            plateHeight,
            alpha * 0.91,
            0.012,
            0.030,
            0.025
        )
        self:drawRect(
            3,
            plateY,
            self.width - 7,
            2,
            alpha * 0.92,
            accent.r,
            accent.g,
            accent.b
        )
        self:drawRect(13, plateY + 13, 7, 7,
            alpha, accent.r, accent.g, accent.b)
        self:drawText(
            string.upper(tostring(context.npcName or "NPC")),
            27,
            plateY + 8,
            bright.r,
            bright.g,
            bright.b,
            alpha,
            UIFont.Small
        )
        local factionName = tostring(context.factionName or "")
        local factionRole = tostring(context.factionRole or "")
        if factionName ~= "" then
            local affiliation = string.upper(factionName)
            if factionRole ~= "" then affiliation = affiliation .. " / " .. string.upper(factionRole) end
            self:drawText(
                affiliation,
                13,
                plateY + 28,
                bright.r,
                bright.g,
                bright.b,
                alpha * 0.92,
                UIFont.Small
            )
        end
        self:drawRectBorder(2, 2, self.width - 5, self.height - 5,
            alpha * 0.75, accent.r, accent.g, accent.b)
        if self.editMode then
            self:drawRectBorder(
                0,
                0,
                self.width,
                self.height,
                0.98,
                0.30,
                0.82,
                1.0
            )
            self:drawRect(
                self.width - 14,
                self.height - 14,
                14,
                14,
                0.92,
                0.30,
                0.82,
                1.0
            )
        end
    end
end

function PsychopatzConversationPortrait:onPartResize()
    if self.portrait then
        self.portrait:setPortraitBounds(2, 2, self.width - 4, self.height - 4)
    end
    self:syncResizeGrip()
end

function PsychopatzConversationPortrait:new(x, y, width, height, options)
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
    o:setBackground(options.backgroundID or "twilight")
    return o
end

return PsychopatzConversationPortrait
