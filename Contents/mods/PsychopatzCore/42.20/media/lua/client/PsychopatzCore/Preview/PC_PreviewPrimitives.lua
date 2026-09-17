-- Stateless world-space drawing primitives shared by every preview provider.
-- Loading this module does not create a drawer, scan the world, or install an
-- event hook. It is only required by the renderer after a preview is enabled.
require "ISUI/ISUIElement"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Preview = PsychopatzCore.Preview or {}

local Primitives = PsychopatzCore.Preview.Primitives or {}
PsychopatzCore.Preview.Primitives = Primitives

local function number(value)
    value = tonumber(value)
    if value ~= nil and value == value then return value end
    return nil
end

Primitives.Number = number

local function screenBounds(index)
    local left = type(getPlayerScreenLeft) == "function"
        and getPlayerScreenLeft(index) or 0
    local top = type(getPlayerScreenTop) == "function"
        and getPlayerScreenTop(index) or 0
    local width = type(getPlayerScreenWidth) == "function"
        and getPlayerScreenWidth(index) or nil
    local height = type(getPlayerScreenHeight) == "function"
        and getPlayerScreenHeight(index) or nil
    if not width or not height then
        local core = type(getCore) == "function" and getCore() or nil
        width = core and core:getScreenWidth() or 1920
        height = core and core:getScreenHeight() or 1080
    end
    return tonumber(left) or 0, tonumber(top) or 0,
        tonumber(width) or 1920, tonumber(height) or 1080
end

function Primitives.DrawerFor(state, index)
    if not ISUIElement or type(ISUIElement.new) ~= "function" then
        return nil
    end
    local x, y, width, height = screenBounds(index)
    local drawer = state and state.drawer or nil
    if not drawer then
        drawer = ISUIElement:new(x, y, width, height)
        if drawer.initialise then drawer:initialise() end
        if drawer.setCapture then drawer:setCapture(false) end
        state.drawer = drawer
    else
        drawer:setX(x)
        drawer:setY(y)
        drawer:setWidth(width)
        drawer:setHeight(height)
    end
    return drawer
end

function Primitives.Point(drawer, index, x, y, z)
    if type(isoToScreenX) ~= "function"
        or type(isoToScreenY) ~= "function"
    then return nil end
    local screenX = isoToScreenX(index, x, y, z)
    local screenY = isoToScreenY(index, x, y, z)
    if screenX == nil or screenY == nil then return nil end
    return screenX - (number(drawer and drawer.x) or 0),
        screenY - (number(drawer and drawer.y) or 0)
end

function Primitives.WorldPointVisible(drawer, index, x, y, z, margin)
    if not drawer then return true end
    if type(isoToScreenX) ~= "function"
        or type(isoToScreenY) ~= "function"
    then return true end
    local sx, sy = Primitives.Point(drawer, index,
        (number(x) or 0) + 0.5, (number(y) or 0) + 0.5,
        number(z) or 0)
    if not sx or not sy then return true end
    margin = number(margin) or 64
    local width = number(drawer.width) or 1920
    local height = number(drawer.height) or 1080
    return sx >= -margin and sx <= width + margin
        and sy >= -margin and sy <= height + margin
end

function Primitives.WorldLine(drawer, index, x1, y1, z1, x2, y2, z2, color)
    if not drawer or type(drawer.drawLine2) ~= "function" then return false end
    local sx1, sy1 = Primitives.Point(drawer, index, x1, y1, z1)
    local sx2, sy2 = Primitives.Point(drawer, index, x2, y2, z2)
    if not sx1 or not sy1 or not sx2 or not sy2 then return false end
    color = color or { r = 1, g = 1, b = 1, a = 1 }
    drawer:drawLine2(sx1, sy1, sx2, sy2, color.a or 1,
        color.r or 1, color.g or 1, color.b or 1)
    return true
end

function Primitives.WorldMarker(drawer, index, x, y, z, color, size)
    local sx, sy = Primitives.Point(drawer, index, x, y, z)
    if not sx or not sy or type(drawer.drawLine2) ~= "function" then
        return false
    end
    color = color or { r = 1, g = 1, b = 1, a = 1 }
    size = number(size) or 7
    drawer:drawLine2(sx - size, sy, sx + size, sy, color.a or 1,
        color.r or 1, color.g or 1, color.b or 1)
    drawer:drawLine2(sx, sy - size, sx, sy + size, color.a or 1,
        color.r or 1, color.g or 1, color.b or 1)
    return true
end

function Primitives.WorldTile(drawer, index, x, y, z, color)
    if type(addAreaHighlightForPlayer) ~= "function" then return false end
    x, y, z = math.floor(number(x) or 0), math.floor(number(y) or 0),
        number(z) or 0
    if not Primitives.WorldPointVisible(drawer, index, x, y, z) then
        return false
    end
    color = color or { r = 0.75, g = 0.85, b = 1, a = 0.7 }
    addAreaHighlightForPlayer(index, x, y, x + 1, y + 1, z,
        color.r, color.g, color.b, color.a)
    return true
end

function Primitives.WorldCircle(drawer, index, x, y, z, radius, color)
    radius = number(radius)
    if not radius or radius <= 0 then return false end
    local segments = math.max(12, math.floor(math.min(28, radius * 2)))
    local previousX, previousY
    for segment = 0, segments do
        local angle = segment / segments * math.pi * 2
        local worldX = x + math.cos(angle) * radius
        local worldY = y + math.sin(angle) * radius
        if previousX then
            Primitives.WorldLine(drawer, index, previousX, previousY, z,
                worldX, worldY, z, color)
        end
        previousX, previousY = worldX, worldY
    end
    return true
end

function Primitives.ObjectPoint(drawer, index, object)
    return Primitives.Point(drawer, index,
        (number(object and object.x) or 0) + 0.5,
        (number(object and object.y) or 0) + 0.5,
        number(object and object.z) or 0)
end

function Primitives.HoveredWorld(drawer, index, object, mouseX, mouseY)
    local sx, sy = Primitives.ObjectPoint(drawer, index, object)
    if not sx or not sy then return nil end
    local dx, dy = mouseX - sx, mouseY - sy
    local xStep = 16
    if type(isoToScreenX) == "function" then
        local x = number(object.x) or 0
        local y = number(object.y) or 0
        local z = number(object.z) or 0
        local base = isoToScreenX(index, x, y, z)
        local nextX = isoToScreenX(index, x + 1, y, z)
        local nextY = isoToScreenX(index, x, y + 1, z)
        if base and nextX and nextY then
            xStep = math.max(8, math.abs(nextX - base),
                math.abs(nextY - base))
        end
    end
    local size = math.max(14, xStep * 1.5)
    if math.abs(dx) <= size and math.abs(dy) <= size then
        return dx * dx + dy * dy
    end
    return nil
end

function Primitives.DrawText(drawer, value, x, y, color, font)
    if not drawer or type(drawer.drawText) ~= "function" then return false end
    color = color or { r = 1, g = 1, b = 1, a = 1 }
    drawer:drawText(tostring(value or ""), x, y, color.r or 1,
        color.g or 1, color.b or 1, color.a or 1, font or UIFont.Small)
    return true
end

local function readableRoomType(value)
    value = tostring(value or "")
    if value == "" then return nil end
    value = string.lower(string.gsub(value, "_", " "))
    if value == "" or value == "unknown" or value == "unclassified" then
        return nil
    end
    return value
end

function Primitives.ZoneLabel(zone)
    if type(zone) ~= "table" then return nil end
    local label = tostring(zone.label or "")
    if label ~= "" then return label end
    local roomType = readableRoomType(zone.roomType)
    if roomType then return roomType end
    if zone.kind == "campfire" or zone.kind == "radius" then
        return "campfire"
    end
    local roomName = tostring(zone.roomName or "")
    if roomName ~= "" then return roomName end
    if zone.kind == "room" then return "room" end
    return "zone"
end

local function zoneAnchor(zone)
    if type(zone) ~= "table" then return nil end
    local bounds = zone.roomBounds or zone.bounds
    if type(bounds) == "table" then
        local minX, minY = number(bounds.minX), number(bounds.minY)
        local maxX, maxY = number(bounds.maxX), number(bounds.maxY)
        if minX and minY and maxX and maxY then
            return (minX + maxX + 1) / 2,
                (minY + maxY + 1) / 2,
                number(zone.z) or number(bounds.z) or 0
        end
    end
    local x, y = number(zone.x), number(zone.y)
    if x == nil or y == nil then return nil end
    return x + 0.5, y + 0.5, number(zone.z) or 0
end

Primitives.ZoneAnchor = zoneAnchor

function Primitives.DrawZoneLabel(drawer, index, zone, color, labelOverride)
    if not drawer or type(drawer.drawText) ~= "function" then return false end
    local label = labelOverride or Primitives.ZoneLabel(zone)
    local worldX, worldY, worldZ = zoneAnchor(zone)
    if not label or not worldX or not worldY then return false end
    local screenX, screenY = Primitives.Point(drawer, index,
        worldX, worldY, worldZ)
    if not screenX or not screenY then return false end
    local drawerWidth = number(drawer.width) or 1920
    local drawerHeight = number(drawer.height) or 1080
    local width = math.min(240, math.max(64, #label * 7 + 18))
    local height = 20
    if screenX < -width or screenX > drawerWidth + width
        or screenY < -height or screenY > drawerHeight + height
    then return false end
    local x = math.max(4, math.min(drawerWidth - width - 4,
        screenX - width / 2))
    local y = math.max(4, math.min(drawerHeight - height - 4,
        screenY - height / 2))
    if drawer.drawRect then
        drawer:drawRect(x, y, width, height, 0.84, 0.01, 0.02, 0.04)
    end
    if drawer.drawRectBorder then
        color = color or { r = 1, g = 1, b = 1, a = 1 }
        drawer:drawRectBorder(x, y, width, height, 0.90,
            color.r, color.g, color.b)
    end
    Primitives.DrawText(drawer, label, x + 8, y + 3,
        { r = 1, g = 1, b = 1, a = 1 })
    return true
end

function Primitives.TruncateText(value, maximum)
    value = tostring(value or "")
    maximum = math.max(8, math.floor(number(maximum) or 72))
    if #value <= maximum then return value end
    return string.sub(value, 1, maximum - 3) .. "..."
end

function Primitives.DrawRegion(drawer, index, region, color)
    if type(addAreaHighlightForPlayer) ~= "function"
        or type(region) ~= "table"
    then return false end
    color = color or { r = 0.4, g = 0.8, b = 1, a = 0.25 }
    local drawn = false
    for z, level in pairs(region.levels or {}) do
        for y, spans in pairs(level.rows or {}) do
            y = number(y)
            for spanIndex = 1, #spans, 2 do
                local first, last = number(spans[spanIndex]),
                    number(spans[spanIndex + 1])
                if y ~= nil and first and last then
                    addAreaHighlightForPlayer(index, first, y, last + 1,
                        y + 1, number(z) or 0, color.r, color.g,
                        color.b, color.a)
                    drawn = true
                end
            end
        end
    end
    return drawn
end

function Primitives.DrawBounds(drawer, index, bounds, z, color)
    if type(bounds) ~= "table"
        or type(addAreaHighlightForPlayer) ~= "function"
    then return false end
    local minX, minY = number(bounds.minX), number(bounds.minY)
    local maxX, maxY = number(bounds.maxX), number(bounds.maxY)
    if not minX or not minY or not maxX or not maxY then return false end
    color = color or { r = 0.4, g = 0.8, b = 1, a = 0.25 }
    if drawer and not Primitives.WorldPointVisible(drawer, index,
        (minX + maxX) / 2, (minY + maxY) / 2, number(z) or number(bounds.z) or 0,
        math.max(64, math.abs(maxX - minX) * 2))
    then return false end
    addAreaHighlightForPlayer(index, minX, minY, maxX + 1, maxY + 1,
        number(z) or number(bounds.z) or 0,
        color.r, color.g, color.b, color.a)
    return true
end

function Primitives.DrawZone(drawer, index, zone, color)
    if type(zone) ~= "table" then return false end
    local shape = tostring(zone.shape or "")
    local bounds = zone.roomBounds or zone.bounds
    if shape == "region" or type(zone.region) == "table" then
        return Primitives.DrawRegion(drawer, index, zone.region, color)
    end
    if shape == "bounds" or type(bounds) == "table"
        and shape ~= "radius" and shape ~= "circle"
    then
        return Primitives.DrawBounds(drawer, index, bounds, zone.z, color)
    end
    local x, y = number(zone.x), number(zone.y)
    if x == nil or y == nil then return false end
    local z = number(zone.z) or 0
    local drawn = Primitives.WorldTile(drawer, index, x, y, z, color)
    if shape == "radius" or shape == "circle"
        or zone.radius ~= nil
    then
        Primitives.WorldCircle(drawer, index, x, y, z,
            number(zone.radius) or 16, color)
    end
    return drawn
end

return Primitives
