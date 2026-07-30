require "ISUI/ISUIElement"

PsychopatzCore = PsychopatzCore or {}

local Marker = ISUIElement:derive("PsychopatzEventMarker")
PsychopatzCore.EventMarker = Marker

-- Legacy alias retained while Dynamic Trading migrates to the core namespace.
EventMarker = Marker

Marker.iconSize = 96
Marker.clickableSize = 45
Marker.maxRange = 100000

function Marker:initialise()
    ISUIElement.initialise(self)
    self:addToUIManager()
    self.moveWithMouse = true
    self:setVisible(false)
end

function Marker:onMouseDoubleClick()
    self:setDuration(0)
end

function Marker:onMouseDown(x, y)
    if not self.moveWithMouse then return true end
    if not self:getIsVisible() or not self:isMouseOver() then return end
    self.downX = x
    self.downY = y
    self.moving = true
    self:bringToTop()
end

function Marker:finishMoving(x, y)
    if not self.moveWithMouse or not self:getIsVisible() then return end
    self.moving = false
    if ISMouseDrag.tabPanel then ISMouseDrag.tabPanel:onMouseUp(x, y) end
    ISMouseDrag.dragView = nil
end

function Marker:onMouseUp(x, y)
    self:finishMoving(x, y)
end

function Marker:onMouseUpOutside(x, y)
    self:finishMoving(x, y)
end

function Marker:moveBy(dx, dy, mouseOver)
    if not self.moveWithMouse then return end
    self.mouseOver = mouseOver == true
    if not self.moving then return end
    if self.parent then
        self.parent:setX(self.parent.x + dx)
        self.parent:setY(self.parent.y + dy)
    else
        self:setX(self.x + dx)
        self:setY(self.y + dy)
        self:bringToTop()
    end
    local player = self:getPlayer()
    if player then player:getModData().EventMarkerPlacement = { self.x, self.y } end
end

function Marker:onMouseMove(dx, dy)
    self:moveBy(dx, dy, true)
end

function Marker:onMouseMoveOutside(dx, dy)
    self:moveBy(dx, dy, false)
end

function Marker:setDistance(distance)
    self.distanceToPoint = distance
end

function Marker:setAngleFromPoint(x, y)
    if not x or not y or not self.player then return end
    local radians = math.atan2(y - self.player:getY(), x - self.player:getX()) + math.pi
    self.angle = ((radians * 180 / math.pi + 270) + 45) % 360
    self.posX = x
    self.posY = y
end

function Marker:setAngle(value)
    self.angle = value
end

function Marker:setDuration(value)
    self.duration = tonumber(value) or 0
    if self.duration <= 0 then self:setVisible(false) end
end

function Marker:getDuration()
    return self.duration
end

function Marker:formatDistance(tiles)
    local meters = tonumber(tiles) or 0
    if meters < 1000 then return string.format("%.0fm", meters) end
    if meters < 10000 then return string.format("%.1fkm", meters / 1000) end
    return string.format("%.0fkm", meters / 1000)
end

local function colorBlend(color, underLayer, fade)
    local faded = { r = color.r * fade, g = color.g * fade, b = color.b * fade, a = fade }
    local alpha = 1 - (1 - faded.a) * (1 - underLayer.a)
    return {
        r = faded.r * faded.r / alpha + underLayer.r * underLayer.a * (1 - faded.a) / alpha,
        g = faded.g * faded.g / alpha + underLayer.g * underLayer.a * (1 - faded.a) / alpha,
        b = faded.b * faded.b / alpha + underLayer.b * underLayer.a * (1 - faded.a) / alpha,
    }
end

function Marker:render()
    if not self.visible or self.duration <= 0 then return end
    self:setAngleFromPoint(self.posX, self.posY)
    local centerX = self.width / 2
    local centerY = self.height / 2
    local radius = math.max(1, tonumber(self.radius) or Marker.maxRange)
    local fade = 0.2 + (0.8 * (1 - (self.distanceToPoint / radius)))
    local color = colorBlend(self.markerColor, { r = 0.22, g = 0.22, b = 0.22, a = 1 }, fade)
    self:drawTexture(self.textureBG, centerX - Marker.iconSize / 2, centerY - Marker.iconSize / 2, 1, color.r, color.g, color.b)
    if self.desc then self:drawTextCentre(self.desc, centerX, centerY + 25, 1, 1, 1, 1, UIFont.Small) end
    local distanceY = self.desc and centerY + 38 or centerY + 25
    self:drawTextCentre(self:formatDistance(self.distanceToPoint), centerX, distanceY, 0.8, 0.8, 0.8, 1, UIFont.Small)

    local pointTexture = self.texturePoint
    local ratio = self.distanceToPoint / radius
    if ratio <= (8 / Marker.maxRange) then
        pointTexture = self.texturePointClose
    elseif ratio <= (125 / Marker.maxRange) then
        pointTexture = self.texturePoint
    elseif ratio <= (375 / Marker.maxRange) then
        pointTexture = self.texturePointMedium
    else
        pointTexture = self.texturePointFar
    end
    self:DrawTextureAngle(pointTexture, centerX, centerY, self.angle)
    if self.textureIcon then
        self:drawTexture(self.textureIcon, centerX - Marker.iconSize / 2, centerY - Marker.iconSize / 2, 1, 1, 1, 1)
    end
    ISUIElement.render(self)
end

function Marker:setEnabled(value) self.enabled = value end
function Marker:getEnabled() return self.enabled end
function Marker:prerender() end
function Marker:refresh()
    self.opacity = 0
    self.opacityGain = 2
end
function Marker:getPlayer() return self.player end

function Marker:new(markerID, icon, duration, posX, posY, player, screenX, screenY, color, desc)
    local o = ISUIElement:new(screenX, screenY, 1, 1)
    setmetatable(o, self)
    self.__index = self
    o.markerID = markerID
    o.player = player
    o.x = screenX
    o.y = screenY
    o.markerColor = color or { r = 1, g = 0.5, b = 0.5 }
    o.posX = posX or 0
    o.posY = posY or 0
    o.width = Marker.clickableSize
    o.height = Marker.clickableSize
    o.angle = 0
    o.opacity = 255
    o.opacityGain = 2
    o.start = getGametimeTimestamp()
    o.duration = tonumber(duration) or 0
    o.lastUpdateTime = -1
    o.enabled = true
    o.visible = true
    o.distanceToPoint = Marker.maxRange
    o.radius = Marker.maxRange
    o.mouseOver = false
    o.bConsumeMouseEvents = false
    o.texturePoint = getTexture("media/ui/EventMarkers/eventMarker.png")
    o.texturePointClose = getTexture("media/ui/EventMarkers/eventMarker_close.png")
    o.texturePointMedium = getTexture("media/ui/EventMarkers/eventMarker_medium.png")
    o.texturePointFar = getTexture("media/ui/EventMarkers/eventMarker_far.png")
    o.textureBG = getTexture("media/ui/EventMarkers/eventMarkerBase.png")
    o.textureIcon = icon and getTexture("media/ui/EventMarkers/" .. icon) or nil
    o.desc = desc
    o:initialise()
    return o
end

function Marker:update(posX, posY)
    if not self.enabled then return end
    local timestamp = getTimeInMillis()
    if self.lastUpdateTime + 5 >= timestamp then return end
    self.lastUpdateTime = timestamp
    posX = posX or self.posX
    posY = posY or self.posY
    local distance
    if posX and posY and self.player then
        distance = IsoUtils.DistanceTo(posX, posY, self.player:getX(), self.player:getY())
    end
    if self.duration > 0 then
        self.posX = posX
        self.posY = posY
        if distance then
            self:setDistance(distance)
            self:setAngleFromPoint(posX, posY)
        end
        self:setVisible(true)
    else
        self:setVisible(false)
    end
end

return Marker
