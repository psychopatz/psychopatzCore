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
    local skin = self.skin or {}
    local base = skin.baseSize or {}
    local baseWidth = tonumber(base.w) or 256
    local baseHeight = tonumber(base.h) or 432
    local nextScale = Geometry.ClampScale(scale, self.minScale, self.maxScale)
    self.scale = nextScale
    local width = math.max(1, math.floor(baseWidth * nextScale + 0.5))
    local height = math.max(1, math.floor(baseHeight * nextScale + 0.5))
    if self.setWidth then self:setWidth(width) else self.width = width end
    if self.setHeight then self:setHeight(height) else self.height = height end
    self:clampToScreen()
    self.resizeHandleSize = math.max(12, math.floor(18 * nextScale))
    self:markGeometryChanged()
    return nextScale
end

function Window:moveBy(dx, dy)
    local x = value(self, "getX", "x") + (tonumber(dx) or 0)
    local y = value(self, "getY", "y") + (tonumber(dy) or 0)
    if self.setX then self:setX(x) else self.x = x end
    if self.setY then self:setY(y) else self.y = y end
    self:clampToScreen()
    self:markGeometryChanged()
end

function Window:resizeBy(dx, dy)
    local horizontal = tonumber(dx) or 0
    local vertical = tonumber(dy) or 0
    local base = self.skin and self.skin.baseSize or {}
    local baseWidth = tonumber(base.w) or 256
    local baseHeight = tonumber(base.h) or 432
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
    })
    if ok then
        self._savedGeometrySignature = signature
        self._geometryDirty = false
    end
    return ok
end

return Window
