-- Frameless Radio OS geometry.  Rendering uses one uniform scale so the
-- shell, LCD, hitboxes and physical buttons cannot drift apart.

PsychopatzCore = PsychopatzCore or {}
local OS = PsychopatzCore.RadioOS
local Geometry = OS.Geometry or require
    "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSGeometry"
local Window = OS.Window

local function value(window, getter, field)
    if window and type(window[getter]) == "function" then
        local ok, result = pcall(window[getter], window)
        if ok and result ~= nil then return tonumber(result) or 0 end
    end
    return tonumber(window and window[field]) or 0
end

local function dimensions(window)
    return value(window, "getWidth", "width"),
        value(window, "getHeight", "height")
end

function Window:currentScale()
    return tonumber(self.scale) or 1
end

function Window:baseDimensions()
    local canvas = self.skin and self.skin.canvas or {}
    return math.max(1, tonumber(canvas.width) or 256),
        math.max(1, tonumber(canvas.height) or 432)
end

function Window:reconcileScreenGeometry()
    local screenWidth, screenHeight = Geometry.GetScreenSize()
    if self._lastScreenWidth == screenWidth
        and self._lastScreenHeight == screenHeight
    then
        return false
    end
    local hadViewport = self._lastScreenWidth ~= nil
    self._lastScreenWidth = screenWidth
    self._lastScreenHeight = screenHeight
    local baseWidth, baseHeight = self:baseDimensions()
    local minimum, maximum = Geometry.GetScaleLimits(screenWidth,
        screenHeight, baseWidth, baseHeight)
    self.minScale = minimum
    self.maxScale = maximum
    if not hadViewport then return false end

    local beforeScale = self:currentScale()
    local nextScale = Geometry.ClampScale(beforeScale, minimum, maximum)
    if math.abs(nextScale - beforeScale) > 0.0001 then
        self:applyScale(nextScale)
    elseif self.presentationMode == "immersive"
        and not self._layoutEditing and self.applyDockPosition
    then
        self:applyDockPosition()
    else
        self:clampToScreen()
    end
    self:markGeometryChanged()
    return true
end

function Window:clampToScreen()
    local width, height = dimensions(self)
    local x, y = Geometry.ClampPosition(
        value(self, "getX", "x"), value(self, "getY", "y"), width, height)
    if self.setX then self:setX(x) else self.x = x end
    if self.setY then self:setY(y) else self.y = y end
    return x, y
end

function Window:geometrySignature()
    local width, height = dimensions(self)
    return table.concat({
        math.floor(value(self, "getX", "x")),
        math.floor(value(self, "getY", "y")),
        math.floor(width), math.floor(height),
        string.format("%.4f", self:currentScale()),
    }, ":")
end

function Window:markGeometryChanged()
    self._geometryDirty = true
end

function Window:applyScale(scale)
    local baseWidth, baseHeight = self:baseDimensions()
    local nextScale = Geometry.ClampScale(scale, self.minScale, self.maxScale)
    self.scale = nextScale
    local width = math.max(1, math.floor(baseWidth * nextScale + 0.5))
    local height = math.max(1, math.floor(baseHeight * nextScale + 0.5))
    if self.setWidth then self:setWidth(width) else self.width = width end
    if self.setHeight then self:setHeight(height) else self.height = height end
    if self.presentationMode == "immersive"
        and not self._layoutEditing and self.applyDockPosition
    then
        self:applyDockPosition()
    elseif self._layoutEditing and self.clampLayoutEditorPosition
    then
        self:clampLayoutEditorPosition()
    else
        self:clampToScreen()
    end
    self.resizeHandleSize = math.max(12, math.floor(18 * nextScale))
    self:markGeometryChanged()
    return nextScale
end

function Window:scaleStep()
    -- A fixed tenth keeps adjacent Zoom In/Out actions reversible and easy to
    -- understand at every monitor size; Fit remains the fast large-jump path.
    return 0.1
end

function Window:zoomBy(direction)
    local delta = (tonumber(direction) or 0) * self:scaleStep()
    return self:applyScale(self:currentScale() + delta)
end

function Window:resetScale()
    local baseWidth, baseHeight = self:baseDimensions()
    return self:applyScale(Geometry.GetPreferredScale(nil, nil,
        baseWidth, baseHeight))
end

function Window:fitToScreen()
    return self:applyScale(self.maxScale or select(2,
        Geometry.GetScaleLimits()))
end

function Window:moveBy(dx, dy)
    local x = value(self, "getX", "x") + (tonumber(dx) or 0)
    local y = value(self, "getY", "y") + (tonumber(dy) or 0)
    if self.presentationMode == "immersive"
        and not self._layoutEditing and self.applyDockPosition
    then
        local width = dimensions(self)
        self.dockX = Geometry.NormalizeDockX(x, width)
        self:applyDockPosition()
        self:markGeometryChanged()
        return
    end
    if self.setX then self:setX(x) else self.x = x end
    if self.setY then self:setY(y) else self.y = y end
    self:clampToScreen()
    self:markGeometryChanged()
end

function Window:resizeBy(dx, dy)
    local horizontal = tonumber(dx) or 0
    local vertical = tonumber(dy) or 0
    local baseWidth, baseHeight = self:baseDimensions()
    local delta = math.abs(horizontal) >= math.abs(vertical)
        and horizontal / baseWidth or vertical / baseHeight
    return self:applyScale(self:currentScale() + delta)
end

function Window:saveGeometry(force)
    if self.persistGeometry == false then return false end
    local signature = self:geometrySignature()
    if force ~= true and not self._geometryDirty then return false end
    if force ~= true and signature == self._savedGeometrySignature then
        self._geometryDirty = false
        return false
    end
    local width, height = dimensions(self)
    local ok = Geometry.Save(self.playerNum, {
        x = value(self, "getX", "x"),
        y = value(self, "getY", "y"),
        w = width,
        h = height,
        scale = self:currentScale(),
        dockX = self.dockX,
        dockBottomOffset = self.dockBottomOffset,
        presentationVisibleFraction = self.presentationVisibleFraction,
        presentationMode = self.presentationMode,
        hidden = self.presentationState == "hidden",
        presentationVersion = 1,
    }, self.geometryIdentity)
    if ok then
        self._savedGeometrySignature = signature
        self._geometryDirty = false
    end
    return ok
end

return Window
