require "PsychopatzCore/EventMarkers/PsychopatzEventMarker"

PsychopatzCore = PsychopatzCore or {}

local Handler = PsychopatzCore.EventMarkers or {}
PsychopatzCore.EventMarkers = Handler
Handler.markers = Handler.markers or {}

-- Legacy alias retained for existing Dynamic Trading callers.
EventMarkerHandler = Handler

function Handler.set(markerID, icon, duration, posX, posY, color, desc)
    markerID = tostring(markerID or "")
    duration = tonumber(duration) or 0
    if markerID == "" then return nil end
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local marker = Handler.markers[markerID]
    if not marker and duration > 0 and player then
        local placement = player:getModData().EventMarkerPlacement
        local screenX = placement and placement[1] or (getCore():getScreenWidth() / 2) - (PsychopatzCore.EventMarker.iconSize / 2)
        local screenY = placement and placement[2] or (PsychopatzCore.EventMarker.iconSize / 2)
        marker = PsychopatzCore.EventMarker:new(markerID, icon, duration, posX, posY, player, screenX, screenY, color, desc)
        Handler.markers[markerID] = marker
    end
    if marker then
        marker.textureIcon = icon and getTexture("media/ui/EventMarkers/" .. icon) or nil
        marker:setDuration(duration)
        if color then marker.markerColor = color end
        if desc ~= nil then marker.desc = desc end
        marker:update(posX, posY)
    end
    return marker
end

function Handler.remove(markerID)
    markerID = tostring(markerID or "")
    local marker = Handler.markers[markerID]
    if not marker then return false end
    marker:setDuration(0)
    marker:setVisible(false)
    marker:removeFromUIManager()
    Handler.markers[markerID] = nil
    return true
end

function Handler.removeAll()
    local ids = {}
    for markerID, _ in pairs(Handler.markers) do ids[#ids + 1] = markerID end
    for index = 1, #ids do Handler.remove(ids[index]) end
end

function Handler.RemoveOldMarkers()
    local now = getGametimeTimestamp()
    local expired = {}
    for markerID, marker in pairs(Handler.markers) do
        if marker.start + marker.duration < now then expired[#expired + 1] = markerID end
    end
    for index = 1, #expired do Handler.remove(expired[index]) end
end

Handler.Set = Handler.set
Handler.Remove = Handler.remove
Handler.RemoveAll = Handler.removeAll

if Events and Events.EveryTenMinutes and not Handler.cleanupHookRegistered then
    Events.EveryTenMinutes.Add(Handler.RemoveOldMarkers)
    Handler.cleanupHookRegistered = true
end

return Handler
