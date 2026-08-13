local ROOT = "Contents/mods/PsychopatzCore/42.19/media/lua/client/"
package.path = ROOT .. "?.lua;" .. package.path

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local Element = {}
Element.__index = Element
function Element:derive(name)
    local class = { Type = name }
    class.__index = class
    setmetatable(class, { __index = self })
    return class
end
function Element:new(x, y, width, height)
    return setmetatable({ x = x, y = y, width = width, height = height }, self)
end
function Element:initialise() end
function Element:addToUIManager() self.added = true end
function Element:removeFromUIManager() self.removed = true end
function Element:setVisible(value) self.visible = value end
function Element:getIsVisible() return self.visible end
function Element:setX(value) self.x = value end
function Element:setY(value) self.y = value end
function Element:bringToTop() end
ISUIElement = Element
package.preload["ISUI/ISUIElement"] = function() return Element end

local playerData = {}
local player = {
    getX = function() return 10 end,
    getY = function() return 20 end,
    getModData = function() return playerData end,
}
getSpecificPlayer = function() return player end
getCore = function()
    return { getScreenWidth = function() return 1000 end }
end
getTexture = function(path) return path end
getGametimeTimestamp = function() return 100 end
getTimeInMillis = function() return 100 end
IsoUtils = { DistanceTo = function(x1, y1, x2, y2) return math.sqrt((x1 - x2)^2 + (y1 - y2)^2) end }
ISMouseDrag = {}
Events = { EveryTenMinutes = { Add = function(callback) Events.cleanup = callback end } }

PsychopatzCore = {}
local Handler = require "PsychopatzCore/EventMarkers/PsychopatzEventMarkerHandler"
assertEqual(Handler, PsychopatzCore.EventMarkers, "core handler namespace")
assertEqual(EventMarkerHandler, Handler, "legacy handler alias")
assertEqual(EventMarker, PsychopatzCore.EventMarker, "legacy marker alias")
local marker = Handler.set("test", "friend.png", 60, 30, 40, { r = 0, g = 1, b = 0 }, "Target")
assert(marker ~= nil)
assertEqual(marker.textureIcon, "media/ui/EventMarkers/friend.png", "shared icon path")
assertEqual(marker.desc, "Target", "marker description")
assertEqual(Handler.markers.test, marker, "marker registry")
Handler.set("test", "raid.png", 30, 35, 45, nil, "Updated")
assertEqual(marker.textureIcon, "media/ui/EventMarkers/raid.png", "marker update")
assertEqual(Handler.remove("test"), true, "marker remove")
assertEqual(marker.removed, true, "marker removed from UI")
assertEqual(Handler.markers.test, nil, "marker registry cleared")

print("psychopatz_event_marker_smoke: ok")
