-- Immersive presentation state for the frameless Radio OS window.
--
-- Canonical radio art and hitboxes remain owned by the runtime manifest.  This
-- module owns only player-local placement, animation and presentation mode.

PsychopatzCore = PsychopatzCore or {}
local OS = PsychopatzCore.RadioOS
local Geometry = require
    "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSGeometry"
local Window = OS.Window

local function numeric(value, fallback)
    return tonumber(value) or fallback or 0
end

local function dimensions(window)
    local width = window.getWidth and window:getWidth() or window.width
    local height = window.getHeight and window:getHeight() or window.height
    return numeric(width, 1), numeric(height, 1)
end

local function position(window)
    local x = window.getX and window:getX() or window.x
    local y = window.getY and window:getY() or window.y
    return numeric(x), numeric(y)
end

local function setPosition(window, x, y)
    if window.setX then window:setX(x) else window.x = x end
    if window.setY then window:setY(y) else window.y = y end
end

local function setDimensions(window, width, height)
    if window.setWidth then window:setWidth(width) else window.width = width end
    if window.setHeight then window:setHeight(height) else window.height = height end
end

local function nowMs()
    if getTimeInMillis then return tonumber(getTimeInMillis()) end
    return nil
end

local function easeOutBack(value)
    local c1 = 1.70158
    local c3 = c1 + 1
    local offset = value - 1
    return 1 + c3 * offset * offset * offset + c1 * offset * offset
end

local function easeInCubic(value)
    return value * value * value
end

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, numeric(value, minimum)))
end

local function diagnostics()
    return OS.Diagnostics
end

function Window:visibleControlBottom()
    local skin = self.skin or {}
    local canvas = skin.canvas or {}
    local scale = self:currentScale()
    local bottom = 0
    local content = skin.lcd and skin.lcd.content
    if type(content) == "table" then
        bottom = math.max(bottom, numeric(content.y) + numeric(content.h))
    end

    local required = {
        back = true, home = true, up = true, down = true,
        left = true, right = true, ok = true, select = true,
    }
    for _, component in ipairs(skin.interactiveComponents
        or skin.components or {}) do
        if type(component) == "table"
            and (component.interactive == true or required[component.id])
        then
            local rect = component.hitbox
            if type(rect) == "table" then
                bottom = math.max(bottom,
                    numeric(rect.y) + numeric(rect.h))
            end
        end
    end

    local canvasHeight = numeric(canvas.height, 1)
    bottom = math.max(1, math.min(canvasHeight, bottom))
    return bottom * scale
end

function Window:visibleBodyBottom()
    local _, height = dimensions(self)
    local fraction = clamp(self.presentationVisibleFraction or 0.75,
        0.35, 1)
    -- The policy may hide the lower body, but never hide the LCD or physical
    -- controls required to operate the radio.
    return math.max(self:visibleControlBottom(), height * fraction)
end

function Window:layoutEditorGrip()
    local _, height = dimensions(self)
    local resizeSize = tonumber(self.resizeHandleSize) or 18
    -- Keep a small recoverable strip visible while editing.  This is an
    -- editor affordance, not a rendering crop or a runtime visibility rule.
    return math.min(height, math.max(24,
        math.floor(resizeSize * 1.5 + 0.5)))
end

-- Layout editing follows the same viewport contract as immersive presentation:
-- the full artwork may extend below the game viewport; the editor does not
-- require physical controls to remain reachable.  A recovery grip keeps the
-- editor usable while the authored surface is moved beyond the viewport.
-- zoom buttons.
function Window:layoutEditorBounds()
    local screenWidth, screenHeight = Geometry.GetScreenSize()
    local width = dimensions(self)
    return math.max(0, screenWidth - width),
        math.max(0, screenHeight - self:layoutEditorGrip())
end

function Window:clampLayoutEditorPosition()
    local maxX, maxY = self:layoutEditorBounds()
    local x, y = position(self)
    setPosition(self, clamp(x, 0, maxX), clamp(y, 0, maxY))
    return position(self)
end

function Window:applyPresentationClip()
    -- Do not use ISUI's maxDrawHeight for the immersive presentation.  The
    -- engine uses that value as an input boundary as well as a draw boundary;
    -- when the pointer is released below it, UIElement.onMouseUp returns
    -- before invoking our Lua callback and can leave a drag captured forever.
    -- The radio art is deliberately never clipped here.  This value is only
    -- a diagnostic measurement of how much of the full surface is currently
    -- inside the game's viewport.
    if type(self.setMaxDrawHeight) == "function"
        and not self._radioOSEngineClipDisabled
    then
        if type(self.clearMaxDrawHeight) == "function" then
            self:clearMaxDrawHeight()
        else
            self:setMaxDrawHeight(-1)
        end
        self._radioOSEngineClipDisabled = true
    end
    if self._closed or self.presentationMode ~= "immersive"
        or self._layoutEditing
    then
        if self.clearMaxDrawHeight then self:clearMaxDrawHeight() end
        self._presentationVisibleHeight = nil
        return false
    end

    local _, height = dimensions(self)
    local visibleHeight
    if self.presentationState == "hidden" then
        visibleHeight = 0
    else
        visibleHeight = self:visibleBodyBottom()
        local _, screenHeight = Geometry.GetScreenSize()
        local _, y = position(self)
        -- This is diagnostic visibility only.  Report the intersection with
        -- the real viewport without feeding it into maxDrawHeight or a
        -- stencil; the authored surface remains uncut.
        visibleHeight = math.min(visibleHeight,
            math.max(0, screenHeight - y))
    end
    visibleHeight = math.floor(clamp(visibleHeight, 0, height) + 0.5)
    if self._presentationVisibleHeight ~= visibleHeight then
        self._presentationVisibleHeight = visibleHeight
        local activeDiagnostics = diagnostics()
        if activeDiagnostics and activeDiagnostics.RecordViewport then
            activeDiagnostics.RecordViewport(self, visibleHeight,
                "height_changed")
        end
    end
    return true
end

function Window:beginPresentationStencil()
    -- Kept as a compatibility no-op for callers from older builds.  The
    -- presentation must not crop the authored radio surface; the game/window
    -- viewport naturally determines which pixels remain visible.
    return false
end

function Window:endPresentationStencil(_)
    -- Intentionally empty.  LCD dynamic content owns the only stencil pass.
end

function Window:dockPosition()
    local screenWidth, screenHeight = Geometry.GetScreenSize()
    local width, height = dimensions(self)
    return Geometry.DockPosition(screenWidth, screenHeight, width, height,
        self:visibleBodyBottom(), self.dockX, self.dockBottomOffset)
end

function Window:applyDockPosition()
    local screenWidth = Geometry.GetScreenSize()
    local width = dimensions(self)
    self.dockX = clamp(self.dockX, 0, 1)
    local x, y = self:dockPosition()
    x = Geometry.ClampX(x, width, screenWidth)
    setPosition(self, x, y)
    return x, y
end

function Window:setDockXFromPosition(x)
    local screenWidth = Geometry.GetScreenSize()
    local width = dimensions(self)
    self.dockX = Geometry.NormalizeDockX(x, width, screenWidth)
    return self.dockX
end

function Window:setVisibleFraction(value)
    self.presentationVisibleFraction = clamp(value, 0.35, 1)
    if self.presentationMode == "immersive"
        and not self._layoutEditing
        and self.applyDockPosition
    then
        self:applyDockPosition()
    end
    self:markGeometryChanged()
    self:saveGeometry(true)
    return self.presentationVisibleFraction
end

function Window:adjustVisibleFraction(delta)
    return self:setVisibleFraction(
        (tonumber(self.presentationVisibleFraction) or 0.75)
            + (tonumber(delta) or 0))
end

function Window:hiddenPositionY()
    local _, screenHeight = Geometry.GetScreenSize()
    return Geometry.HiddenY(screenHeight, self.presentationPeekHeight)
end

function Window:trackPresentationDrag(deltaX, deltaY)
    local screenWidth = Geometry.GetScreenSize()
    local width = dimensions(self)
    local currentX, currentY = position(self)
    local x, y = currentX + numeric(deltaX), currentY + numeric(deltaY)
    if self._dragStartWindowX and self._dragStartWindowY
        and self._dragStartMouseX and self._dragStartMouseY
        and type(getMouseX) == "function" and type(getMouseY) == "function"
    then
        -- ISPanel supplies deltas, but the pointer can cross the panel edge
        -- during a downward swipe.  Reconstructing from the original pointer
        -- position prevents lost/out-of-order deltas from turning the gesture
        -- into a horizontal-only drag.
        x = self._dragStartWindowX
            + (numeric(getMouseX()) - self._dragStartMouseX)
        y = self._dragStartWindowY
            + (numeric(getMouseY()) - self._dragStartMouseY)
    end
    local _, dockY = self:dockPosition()
    local hiddenY = self:hiddenPositionY()
    local nextX = Geometry.ClampX(x, width, screenWidth)
    local nextY = clamp(y, dockY, hiddenY)
    self.dockX = Geometry.NormalizeDockX(nextX, width, screenWidth)
    setPosition(self, nextX, nextY)
    self._dragDistanceY = math.max(0, nextY - dockY)
    self._dragTravelY = math.max(1, hiddenY - dockY)
    self._dragProgress = clamp(self._dragDistanceY / self._dragTravelY,
        0, 1)
    self:applyPresentationClip()
    local activeDiagnostics = diagnostics()
    if activeDiagnostics and activeDiagnostics.TrackDrag then
        activeDiagnostics.TrackDrag(self, deltaX, deltaY)
    end
    self:markGeometryChanged()
    return nextX, nextY
end

function Window:beginPresentationDrag(pointerX, pointerY)
    local x, y = position(self)
    self._dragStartWindowX = x
    self._dragStartWindowY = y
    if type(getMouseX) == "function" and type(getMouseY) == "function" then
        self._dragStartMouseX = numeric(getMouseX())
        self._dragStartMouseY = numeric(getMouseY())
    else
        self._dragStartMouseX = nil
        self._dragStartMouseY = nil
    end
    local activeDiagnostics = diagnostics()
    if activeDiagnostics and activeDiagnostics.BeginDrag then
        activeDiagnostics.BeginDrag(self,
            pointerX ~= nil and pointerX or self._dragStartMouseX,
            pointerY ~= nil and pointerY or self._dragStartMouseY,
            "shell")
    end
end

function Window:finishPresentationDrag()
    local progress = tonumber(self._dragProgress) or 0
    local _, dockY = self:dockPosition()
    local activeDiagnostics = diagnostics()
    self._dragDistanceY = nil
    self._dragTravelY = nil
    self._dragProgress = nil
    self._dragStartWindowX = nil
    self._dragStartWindowY = nil
    self._dragStartMouseX = nil
    self._dragStartMouseY = nil
    if progress <= 0.001 then
        if activeDiagnostics and activeDiagnostics.EndDrag then
            activeDiagnostics.EndDrag(self, "snap_back", progress)
        end
        local x = position(self)
        setPosition(self, x, dockY)
        self.presentationState = "docked"
        self:applyPresentationClip()
        self:markGeometryChanged()
        self:saveGeometry(true)
        return true
    end
    if progress >= 0.42 then
        if activeDiagnostics and activeDiagnostics.EndDrag then
            activeDiagnostics.EndDrag(self, "put_away", progress)
        end
        self:putAway("drag", { animate = true })
        return true
    end
    if activeDiagnostics and activeDiagnostics.EndDrag then
        activeDiagnostics.EndDrag(self, "return_to_dock", progress)
    end
    self:beginPresentationAnimation(dockY, "showing",
        math.max(160, (self.animationDuration or 360) * 0.45))
    return true
end

function Window:beginPresentationAnimation(targetY, state, duration)
    local _, currentY = position(self)
    self._animationStartY = currentY
    self._animationTargetY = numeric(targetY, currentY)
    self._animationElapsed = 0
    self._animationLastTime = nowMs()
    self.animationDuration = math.max(1, numeric(duration,
        self.animationDuration or 360))
    self.presentationState = state
    if self.setVisible then self:setVisible(true) end
    self:applyPresentationClip()
end

function Window:stepPresentation()
    local state = self.presentationState
    if state ~= "opening" and state ~= "showing" and state ~= "hiding" then
        return false
    end

    local current = nowMs()
    local delta = 16
    if current and self._animationLastTime then
        delta = current - self._animationLastTime
        if delta < 1 or delta > 250 then delta = 16 end
    end
    self._animationLastTime = current
    self._animationElapsed = self._animationElapsed + delta
    local progress = clamp(self._animationElapsed / self.animationDuration,
        0, 1)
    local eased = state == "hiding" and easeInCubic(progress)
        or easeOutBack(progress)
    local y = self._animationStartY
        + (self._animationTargetY - self._animationStartY) * eased
    local x = position(self)
    setPosition(self, x, y)

    if progress >= 1 then
        setPosition(self, x, self._animationTargetY)
        local completedTargetY = self._animationTargetY
        self._animationStartY = nil
        self._animationTargetY = nil
        if state == "hiding" then
            self.presentationState = "hidden"
            if self.setVisible then self:setVisible(false) end
        else
            self.presentationState = "docked"
        end
        local activeDiagnostics = diagnostics()
        if activeDiagnostics and activeDiagnostics.RecordWindow then
            activeDiagnostics.RecordWindow("presentation.animation_complete",
                self, {
                    animation = state,
                    targetY = completedTargetY,
                })
        end
        self:applyPresentationClip()
        self:markGeometryChanged()
        self:saveGeometry(true)
        return true
    end
    return true
end

function Window:showImmersive(options)
    if self._closed then return false end
    options = type(options) == "table" and options or {}
    self.presentationMode = "immersive"
    self._layoutEditing = false
    self.presentationState = "docked"
    self.hidden = false
    local activeDiagnostics = diagnostics()
    if activeDiagnostics and activeDiagnostics.RecordWindow then
        activeDiagnostics.RecordWindow("presentation.show", self, {
            animate = options.animate ~= false,
        }, { print = false })
    end
    local _, screenHeight = Geometry.GetScreenSize()
    local width, height = dimensions(self)
    local _, dockY = self:dockPosition()
    local dockX = Geometry.DockX(self.dockX, width)
    if self.setX then self:setX(dockX) else self.x = dockX end

    if options.animate == false then
        setPosition(self, dockX, dockY)
        if self.setVisible then self:setVisible(true) end
        self:applyPresentationClip()
        self:markGeometryChanged()
        return true
    end

    local startY = numeric(options.startY,
        screenHeight + math.max(20, height * 0.22))
    setPosition(self, dockX, startY)
    self:beginPresentationAnimation(dockY, "opening",
        options.duration or self.animationDuration)
    return true
end

function Window:putAway(reason, options)
    if self._closed then return false end
    if self._layoutEditing then return false end
    options = type(options) == "table" and options or {}
    local _, screenHeight = Geometry.GetScreenSize()
    local targetY = Geometry.HiddenY(screenHeight,
        self.presentationPeekHeight)
    self.presentationMode = "immersive"
    self.putAwayReason = reason
    local activeDiagnostics = diagnostics()
    if activeDiagnostics and activeDiagnostics.RecordWindow then
        activeDiagnostics.RecordWindow("presentation.put_away", self, {
            reason = reason or "unspecified",
            animate = options.animate ~= false,
            targetY = targetY,
        }, { print = false })
    end
    if options.animate == false then
        local x = position(self)
        setPosition(self, x, targetY)
        self.presentationState = "hidden"
        if self.setVisible then self:setVisible(false) end
        self:applyPresentationClip()
        self:markGeometryChanged()
        self:saveGeometry(true)
        return true
    end
    self:beginPresentationAnimation(targetY, "hiding",
        options.duration or self.animationDuration * 0.75)
    return true
end

function Window:beginLayoutEdit()
    if self._closed or self._layoutEditing then return false end
    local x, y = position(self)
    self._layoutSnapshot = {
        x = x, y = y, scale = self:currentScale(),
        dockX = self.dockX,
        dockBottomOffset = self.dockBottomOffset,
        presentationVisibleFraction = self.presentationVisibleFraction,
        presentationMode = self.presentationMode,
        presentationState = self.presentationState,
        visible = not self.getIsVisible or self:getIsVisible(),
    }
    self._layoutEditing = true
    self.presentationMode = "editor"
    self.presentationState = "editing"
    self._animationStartY = nil
    self._animationTargetY = nil
    if self.setVisible then self:setVisible(true) end
    self:applyPresentationClip()
    -- Do not clamp against the full artwork.  The editor must preserve the
    -- immersive viewport edge so dragging vertically can choose how much of
    -- the long chassis is visible at runtime.
    self:clampLayoutEditorPosition()
    return true
end

function Window:commitLayoutEdit()
    if not self._layoutEditing then return false end
    local _, screenHeight = Geometry.GetScreenSize()
    local x, y = position(self)
    local _, height = dimensions(self)
    self:setDockXFromPosition(x)
    self.dockBottomOffset = math.floor(clamp(screenHeight
        - (y + self:visibleBodyBottom()), -height, screenHeight) + 0.5)
    self._layoutEditing = false
    self._layoutSnapshot = nil
    self.presentationMode = "immersive"
    self.presentationState = "docked"
    self:applyDockPosition()
    self:applyPresentationClip()
    self:saveGeometry(true)
    return true
end

function Window:cancelLayoutEdit()
    local snapshot = self._layoutSnapshot
    if not snapshot then return false end
    self._layoutEditing = false
    self._layoutSnapshot = nil
    self.scale = snapshot.scale
    local baseWidth, baseHeight = self:baseDimensions()
    setDimensions(self, math.max(1, math.floor(baseWidth * self.scale + 0.5)),
        math.max(1, math.floor(baseHeight * self.scale + 0.5)))
    self.dockX = snapshot.dockX
    self.dockBottomOffset = snapshot.dockBottomOffset
    self.presentationVisibleFraction = snapshot.presentationVisibleFraction
    self.presentationMode = snapshot.presentationMode
    self.presentationState = snapshot.presentationState
    setPosition(self, snapshot.x, snapshot.y)
    if self.setVisible then self:setVisible(snapshot.visible == true) end
    self:applyPresentationClip()
    return true
end

function Window:openLayoutEditor()
    if OS.OpenLayoutEditor then return OS.OpenLayoutEditor(self) end
    return false
end

return Window
