-- Provider-neutral SurvivorWorld actor portrait hover host.
-- Adopters supply only a canonical actor projection and marker screen point.

local Client = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldClient"
local PortraitCard

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.SurvivorWorldMapHover =
    PsychopatzCore.SurvivorWorldMapHover or {}

local Hover = PsychopatzCore.SurvivorWorldMapHover

Hover.SIZE = 128
Hover.NAME_HEIGHT = 24
Hover.GAP = 8
Hover.DELAY_MS = 90

local function nowMs()
    if type(getTimestampMs) == "function" then
        local ok, value = pcall(getTimestampMs)
        if ok and tonumber(value) then return tonumber(value) end
    end
    if type(getTimeInMillis) == "function" then
        local ok, value = pcall(getTimeInMillis)
        if ok and tonumber(value) then return tonumber(value) end
    end
    return 0
end

local function visible(panel, value)
    if not panel then return end
    if type(panel.setVisible) == "function" then
        panel:setVisible(value == true)
    else
        panel.visible = value == true
    end
end

local function portraitCard()
    if PortraitCard then return PortraitCard end
    local ok, value = pcall(
        require,
        "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldMapHoverCard"
    )
    if ok and type(value) == "table" then
        PortraitCard = value
    end
    return PortraitCard
end

function Hover.Ensure(map)
    if not map then return nil end
    if map.psychopatzSurvivorWorldHover then
        return map.psychopatzSurvivorWorldHover
    end
    local panelType = portraitCard()
    if not panelType or not panelType.new
        or type(map.addChild) ~= "function"
    then
        return nil
    end
    local panel = panelType:new(
        0,
        0,
        Hover.SIZE,
        {
            nameHeight = Hover.NAME_HEIGHT,
            badgeSize = 24,
            badgeInset = 5,
        }
    )
    if panel.initialise then panel:initialise() end
    if panel.instantiate then panel:instantiate() end
    visible(panel, false)
    map:addChild(panel)
    map.psychopatzSurvivorWorldHover = panel
    return panel
end

function Hover.Hide(map, resetCandidate)
    if not map then return false end
    visible(map.psychopatzSurvivorWorldHover, false)
    map._psychopatzSurvivorWorldHoverActorID = nil
    if resetCandidate ~= false then
        map._psychopatzSurvivorWorldHoverCandidateID = nil
        map._psychopatzSurvivorWorldHoverCandidateAt = nil
    end
    return true
end

function Hover.Update(map, entry, markerX, markerY, marker)
    local actorID = entry and entry.actorID
    if not map or not actorID then
        Hover.Hide(map)
        return false
    end
    local spec = Client.GetPortraitSpec(entry)
    if not spec then
        Hover.Hide(map)
        return false
    end

    actorID = tostring(actorID)
    local now = nowMs()
    if map._psychopatzSurvivorWorldHoverCandidateID
        ~= actorID
    then
        map._psychopatzSurvivorWorldHoverCandidateID =
            actorID
        map._psychopatzSurvivorWorldHoverCandidateAt = now
        Hover.Hide(map, false)
        if now > 0 and Hover.DELAY_MS > 0 then
            return false
        end
    end
    if now > 0
        and now
            - (tonumber(
                map._psychopatzSurvivorWorldHoverCandidateAt
            ) or now)
            < Hover.DELAY_MS
    then
        return false
    end

    local panel = Hover.Ensure(map)
    if not panel then return false end
    if panel.setContext then panel:setContext(entry, marker) end
    if map._psychopatzSurvivorWorldHoverActorID
        ~= actorID
    then
        if panel:setTarget(nil, spec, true) ~= true then
            Hover.Hide(map, false)
            return false
        end
        map._psychopatzSurvivorWorldHoverActorID =
            actorID
    end

    local size = Hover.SIZE
    local totalHeight = tonumber(panel.height)
        or size + Hover.NAME_HEIGHT
    local width = tonumber(map.width)
        or (map.getWidth and map:getWidth())
        or size
    local x = math.max(
        4,
        math.min(
            width - size - 4,
            (tonumber(markerX) or 0) - size / 2
        )
    )
    local y = math.max(
        4,
        (tonumber(markerY) or 0) - totalHeight - Hover.GAP
    )
    if panel.setCardPosition then
        panel:setCardPosition(x, y)
    else
        panel.x = x
        panel.y = y
    end
    visible(panel, true)
    return true
end

return Hover
