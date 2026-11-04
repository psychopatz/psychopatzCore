-- Provider-neutral SurvivorWorld per-actor world-map renderer.
-- Core owns canonical actor dots, hover, selection, tracking and route drawing.
-- Adopters may register bounded presentation decorators; they do not own a
-- second actor-dot system.

local Client = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldClient"
local Hover = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldMapHover"
local Host = require "PsychopatzCore/UI/Map/PsychopatzMapHost"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.SurvivorWorldActorMap =
    PsychopatzCore.SurvivorWorldActorMap or {}

local ActorMap = PsychopatzCore.SurvivorWorldActorMap

ActorMap.Enabled = ActorMap.Enabled ~= false
ActorMap.MarkerSize = tonumber(ActorMap.MarkerSize) or 9
ActorMap.RefreshMs = tonumber(ActorMap.RefreshMs) or 500
ActorMap.Decorators = ActorMap.Decorators or {}
ActorMap.LastMarkers = ActorMap.LastMarkers or {}
ActorMap.DotTexture = ActorMap.DotTexture
    or (getTexture and getTexture("media/ui/circle.png") or nil)

local DEFAULT_COLOR = {
    r = 0.45, g = 0.82, b = 0.95, a = 1.0,
}
local SELECTED_COLOR = {
    r = 1.0, g = 0.92, b = 0.35, a = 1.0,
}
local TRACKED_COLOR = {
    r = 0.45, g = 1.0, b = 0.55, a = 1.0,
}

local function copyColor(value, fallback)
    value = type(value) == "table" and value or fallback
    return {
        r = tonumber(value.r) or fallback.r,
        g = tonumber(value.g) or fallback.g,
        b = tonumber(value.b) or fallback.b,
        a = tonumber(value.a) or fallback.a,
    }
end

local function decoratorList()
    local output = {}
    for id, definition in pairs(ActorMap.Decorators) do
        output[#output + 1] = {
            id = id,
            priority = tonumber(definition.priority) or 0,
            decorate = definition.decorate,
        }
    end
    table.sort(output, function(left, right)
        if left.priority == right.priority then
            return tostring(left.id) < tostring(right.id)
        end
        return left.priority > right.priority
    end)
    return output
end

function ActorMap.RegisterDecorator(id, definition)
    id = tostring(id or "")
    if id == "" or type(definition) ~= "table"
        or type(definition.decorate) ~= "function"
    then
        return false, "invalid_actor_map_decorator"
    end
    ActorMap.Decorators[id] = {
        priority = tonumber(definition.priority) or 0,
        decorate = definition.decorate,
    }
    return true
end

function ActorMap.UnregisterDecorator(id)
    id = tostring(id or "")
    if id == "" or ActorMap.Decorators[id] == nil then
        return false
    end
    ActorMap.Decorators[id] = nil
    return true
end

local function decorate(entry, decorators)
    local style = {
        label = tostring(entry.label or entry.actorID or "Survivor"),
        color = copyColor(DEFAULT_COLOR, DEFAULT_COLOR),
        size = ActorMap.MarkerSize,
        visible = true,
    }
    for _, definition in ipairs(decorators or {}) do
        local ok, result = pcall(
            definition.decorate,
            entry,
            style
        )
        if ok and type(result) == "table" then
            style = result
        end
    end
    style.color = copyColor(style.color, DEFAULT_COLOR)
    style.size = math.max(5, tonumber(style.size) or ActorMap.MarkerSize)
    style.label = tostring(style.label or entry.label or entry.actorID)
    return style
end

local function selectionID()
    local selection = Client.Selection or {}
    return selection.selectedActorID
        and tostring(selection.selectedActorID) or nil
end

local function trackedID()
    local tracked = Client.GetTracked and Client.GetTracked() or nil
    return tracked and tostring(tracked.actorID or "") or nil
end

function ActorMap.BuildMarkers()
    if Client.RequestActorsIfDue then
        Client.RequestActorsIfDue(ActorMap.RefreshMs)
    end
    local markers = {}
    local selected = selectionID()
    local tracked = trackedID()
    local decorators = decoratorList()
    for _, entry in ipairs(Client.ListActors(false) or {}) do
        local position = entry and entry.position or nil
        if position and tonumber(position.x) and tonumber(position.y) then
            local style = decorate(entry, decorators)
            if style.visible ~= false then
                local actorID = tostring(entry.actorID or "")
                local isSelected = selected == actorID
                local isTracked = tracked == actorID
                local color = isTracked and TRACKED_COLOR
                    or isSelected and SELECTED_COLOR
                    or style.color
                markers[#markers + 1] = {
                    actorID = actorID,
                    entry = entry,
                    position = position,
                    label = style.label,
                    color = color,
                    size = isTracked and math.max(style.size, 13)
                        or isSelected and math.max(style.size, 12)
                        or style.size,
                    selected = isSelected,
                    tracked = isTracked,
                }
            end
        end
    end
    table.sort(markers, function(left, right)
        return left.actorID < right.actorID
    end)
    return markers
end

local function drawRoute(map, marker)
    if not marker or not (marker.selected or marker.tracked) then return end
    local points = marker.entry
        and marker.entry.journey
        and marker.entry.journey.route
        and marker.entry.journey.route.points or nil
    if type(points) ~= "table" or #points < 2
        or not map.javaObject
        or not map.javaObject.DrawLine
    then
        return
    end
    for index = 1, #points - 1 do
        local from = points[index]
        local to = points[index + 1]
        if from and to then
            map.javaObject:DrawLine(
                nil,
                map.mapAPI:worldToUIX(from.x, from.y),
                map.mapAPI:worldToUIY(from.x, from.y),
                map.mapAPI:worldToUIX(to.x, to.y),
                map.mapAPI:worldToUIY(to.x, to.y),
                2,
                marker.color.r,
                marker.color.g,
                marker.color.b,
                0.8
            )
        end
    end
end

local function drawDot(map, marker, sx, sy)
    local size = marker.size
    local half = size / 2
    local color = marker.color
    if ActorMap.DotTexture and map.drawTextureScaledAspect then
        map:drawTextureScaledAspect(
            ActorMap.DotTexture,
            sx - half,
            sy - half,
            size,
            size,
            color.a or 1,
            color.r,
            color.g,
            color.b
        )
    elseif map.drawRect then
        map:drawRect(
            sx - half,
            sy - half,
            size,
            size,
            color.a or 1,
            color.r,
            color.g,
            color.b
        )
    end
    if map.drawRectBorder then
        map:drawRectBorder(
            sx - half - 1,
            sy - half - 1,
            size + 2,
            size + 2,
            0.95,
            0.05,
            0.05,
            0.05
        )
    end
end

function ActorMap.FindMarkerAt(x, y, padding)
    local best
    local bestDistance
    for _, marker in pairs(ActorMap.LastMarkers or {}) do
        local dx = (tonumber(x) or 0) - marker.x
        local dy = (tonumber(y) or 0) - marker.y
        local distance = math.sqrt(dx * dx + dy * dy)
        local radius = (marker.radius or 6) + (tonumber(padding) or 0)
        if distance <= radius
            and (bestDistance == nil or distance < bestDistance)
        then
            best = marker
            bestDistance = distance
        end
    end
    return best
end

function ActorMap.Render(map)
    if not ActorMap.Enabled or not map or not map.mapAPI then
        if Hover and Hover.Hide then Hover.Hide(map) end
        return
    end

    local markers = ActorMap.BuildMarkers()
    ActorMap.LastMarkers = {}
    local mouseX = map.getMouseX and map:getMouseX() or -10000
    local mouseY = map.getMouseY and map:getMouseY() or -10000
    local hovered

    for _, marker in ipairs(markers) do
        local x = tonumber(marker.position.x)
        local y = tonumber(marker.position.y)
        if x and y then
            local sx = map.mapAPI:worldToUIX(x, y)
            local sy = map.mapAPI:worldToUIY(x, y)
            local half = marker.size / 2
            if sx >= -marker.size
                and sy >= -marker.size
                and sx <= (tonumber(map.width) or 0) + marker.size
                and sy <= (tonumber(map.height) or 0) + marker.size
            then
                drawRoute(map, marker)
                drawDot(map, marker, sx, sy)
                ActorMap.LastMarkers[marker.actorID] = {
                    actorID = marker.actorID,
                    marker = marker,
                    x = sx,
                    y = sy,
                    radius = half + 4,
                }
                if math.abs(mouseX - sx) <= half + 4
                    and math.abs(mouseY - sy) <= half + 4
                then
                    hovered = ActorMap.LastMarkers[marker.actorID]
                elseif (marker.selected or marker.tracked)
                    and map.drawTextCentre
                then
                    map:drawTextCentre(
                        marker.label,
                        sx,
                        sy + half + 2,
                        1, 1, 1, 1,
                        UIFont.Small
                    )
                end
            end
        end
    end

    if hovered then
        if Client.SetHighlighted then
            Client.SetHighlighted(hovered.actorID)
        end
        if Hover and Hover.Update then
            Hover.Update(
                map,
                hovered.marker.entry,
                hovered.x,
                hovered.y
            )
        end
    else
        if Client.SetHighlighted then Client.SetHighlighted(nil) end
        if Hover and Hover.Hide then Hover.Hide(map) end
    end
end

Host.Overlays.Register("PsychopatzCore:SurvivorWorldActors", {
    order = 85,
    render = ActorMap.Render,
    enabled = function()
        return ActorMap.Enabled
    end,
})

Host.Events.Register("PsychopatzCore:SurvivorWorldActors", {
    order = 60,
    onMouseDown = function(_, x, y)
        local hit = ActorMap.FindMarkerAt(x, y, 2)
        if not hit then return false end
        if Client.SetSelected then
            Client.SetSelected(hit.actorID)
        end
        return true
    end,
    onClose = function(map)
        if Client.SetSelected then Client.SetSelected(nil) end
        if Client.SetHighlighted then Client.SetHighlighted(nil) end
        if Hover and Hover.Hide then Hover.Hide(map) end
        ActorMap.LastMarkers = {}
        return false
    end,
})

Host.Contexts.Register("PsychopatzCore:SurvivorWorldActors", {
    order = 60,
    available = function(_, x, y)
        return ActorMap.FindMarkerAt(x, y, 3) ~= nil
    end,
    augment = function(_, context, x, y)
        local hit = ActorMap.FindMarkerAt(x, y, 3)
        if not hit or not context or not context.addOption then
            return false
        end
        local tracked = Client.GetTracked and Client.GetTracked() or nil
        local trackedID = tracked
            and tostring(tracked.actorID or "") or ""
        local alreadyTracked = trackedID == hit.actorID
        context:addOption(
            alreadyTracked and "Stop tracking survivor"
                or ("Track " .. tostring(hit.marker.label)),
            nil,
            function()
                if Client.SetTracked then
                    Client.SetTracked(
                        alreadyTracked and nil or hit.actorID
                    )
                end
            end
        )
        return true
    end,
})

return ActorMap
