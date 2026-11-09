-- Provider-neutral SurvivorWorld per-actor world-map renderer.
-- Core owns canonical actor dots, hover, selection, tracking and route drawing.
-- Adopters may register bounded presentation decorators; they do not own a
-- second actor-dot system.

local Client = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldClient"
local Hover = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldMapHover"
local Host = require "PsychopatzCore/UI/Map/PsychopatzMapHost"
local HOVER_OWNER = "PsychopatzCore:SurvivorWorldActors"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.SurvivorWorldActorMap =
    PsychopatzCore.SurvivorWorldActorMap or {}

local ActorMap = PsychopatzCore.SurvivorWorldActorMap

ActorMap.Enabled = ActorMap.Enabled ~= false
ActorMap.MarkerSize = tonumber(ActorMap.MarkerSize) or 9
ActorMap.RefreshMs = tonumber(ActorMap.RefreshMs) or 500
-- Screen projection may refresh twice per second, but the map must not turn
-- every render pass into a network roster request.  Keep transport cadence
-- explicit so Hoomans and DynamicTrading share one bounded request policy.
ActorMap.NetworkRefreshMs = tonumber(ActorMap.NetworkRefreshMs) or 1000
ActorMap.Decorators = ActorMap.Decorators or {}
ActorMap.Sources = ActorMap.Sources or {}
ActorMap.LastMarkers = ActorMap.LastMarkers or {}
ActorMap.EntryCache = ActorMap.EntryCache or nil
ActorMap.EntryCacheAt = ActorMap.EntryCacheAt or nil
ActorMap.MarkerCache = ActorMap.MarkerCache or nil
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

local function nowMs()
    if type(getTimestampMs) == "function" then
        local value = getTimestampMs()
        if tonumber(value) then return tonumber(value) end
    end
    if type(getTimeInMillis) == "function" then
        local value = getTimeInMillis()
        if tonumber(value) then return tonumber(value) end
    end
    return nil
end

local sourceList

local function projectedEntries()
    local now = nowMs()
    local cached = ActorMap.EntryCache
    local cachedAt = tonumber(ActorMap.EntryCacheAt)
    local refreshMs = math.max(0, tonumber(ActorMap.RefreshMs) or 500)
    if cached and type(cached.entries) == "table"
        and now ~= nil and cachedAt ~= nil
        and now >= cachedAt and now - cachedAt < refreshMs
    then
        return cached.entries
    end

    local entries = {}
    local seen = {}
    local function append(entry)
        if type(entry) ~= "table" then return end
        local actorID = tostring(
            entry.actorID or entry.id or entry.npcId or ""
        )
        if actorID == "" or seen[actorID] then return end
        seen[actorID] = true
        entries[#entries + 1] = entry
    end

    -- Core's canonical source always wins a duplicate supplied by an
    -- optional adopter. Registered sources are integration boundaries: a
    -- failed optional provider must not break the shared actor map.
    for _, entry in ipairs(Client.ListActors(false) or {}) do
        append(entry)
    end
    for _, source in ipairs(sourceList()) do
        local ok, rows = pcall(source.list)
        if ok and type(rows) == "table" then
            for _, entry in ipairs(rows) do append(entry) end
        elseif not ok and PsychopatzCore and PsychopatzCore.LogWarn then
            PsychopatzCore.LogWarn(
                "Actor map source failed id=" .. tostring(source.id)
                    .. " error=" .. tostring(rows)
            )
        end
    end

    ActorMap.EntryCache = {
        entries = entries,
        at = now,
    }
    ActorMap.EntryCacheAt = now
    return entries
end

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

sourceList = function()
    local output = {}
    for id, definition in pairs(ActorMap.Sources) do
        output[#output + 1] = {
            id = id,
            priority = tonumber(definition.priority) or 0,
            list = definition.list,
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

function ActorMap.InvalidateCache()
    ActorMap.EntryCache = nil
    ActorMap.EntryCacheAt = nil
    ActorMap.MarkerCache = nil
    return true
end

function ActorMap.RegisterSource(id, definition)
    id = tostring(id or "")
    if id == "" or type(definition) ~= "table"
        or type(definition.list) ~= "function"
    then
        return false, "invalid_actor_map_source"
    end
    ActorMap.Sources[id] = {
        priority = tonumber(definition.priority) or 0,
        list = definition.list,
    }
    ActorMap.InvalidateCache()
    return true, id
end

function ActorMap.UnregisterSource(id)
    id = tostring(id or "")
    if id == "" or ActorMap.Sources[id] == nil then
        return false
    end
    ActorMap.Sources[id] = nil
    ActorMap.InvalidateCache()
    return true
end

function ActorMap.RegisterDecorator(id, definition)
    id = tostring(id or "")
    if id == "" or type(definition) ~= "table"
        or type(definition.decorate) ~= "function"
    then
        return false, "invalid_actor_map_decorator"
    end
    ActorMap.MarkerCache = nil
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
    ActorMap.MarkerCache = nil
    return true
end

local function decorate(entry, decorators)
    local actorID = entry and (
        entry.actorID or entry.id or entry.npcId
    ) or nil
    local style = {
        label = tostring(
            entry.label or entry.displayName or entry.name
                or actorID or "Survivor"
        ),
        color = copyColor(DEFAULT_COLOR, DEFAULT_COLOR),
        size = ActorMap.MarkerSize,
        visible = true,
        showLabel = entry.showLabel == true,
        icon = entry.icon,
        emblem = entry.emblem,
        badge = entry.badge,
        subtitle = entry.subtitle,
        hoverMetadata = entry.hoverMetadata,
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
    style.label = tostring(
        style.label or entry.label or entry.displayName
            or entry.name or actorID
    )
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
        Client.RequestActorsIfDue(ActorMap.NetworkRefreshMs)
    end
    local selected = selectionID()
    local tracked = trackedID()
    local entries = projectedEntries()
    local now = nowMs()
    local cache = ActorMap.MarkerCache
    -- World coordinates/styles only change at projection cadence. Screen
    -- coordinates and hover hit tests still run every render for smooth pan.
    if cache and cache.entries == entries and cache.selected == selected
        and cache.tracked == tracked and now ~= nil and cache.at ~= nil
        and now >= cache.at
        and now - cache.at < math.max(0, tonumber(ActorMap.RefreshMs) or 500)
    then
        return cache.markers
    end
    local markers = {}
    local decorators = decoratorList()
    for _, entry in ipairs(entries) do
        local position = entry and entry.position or nil
        if not position and entry
            and tonumber(entry.x) and tonumber(entry.y)
        then
            position = {
                x = tonumber(entry.x),
                y = tonumber(entry.y),
                z = tonumber(entry.z) or 0,
            }
        end
        if position and tonumber(position.x) and tonumber(position.y) then
            local style = decorate(entry, decorators)
            if style.visible ~= false then
                local actorID = tostring(
                    entry.actorID or entry.id or entry.npcId or ""
                )
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
                    icon = style.icon,
                    emblem = style.emblem,
                    badge = style.badge,
                    subtitle = style.subtitle,
                    hoverMetadata = style.hoverMetadata,
                    showLabel = style.showLabel == true,
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
    ActorMap.MarkerCache = {
        entries = entries, selected = selected, tracked = tracked,
        at = now, markers = markers,
    }
    return markers
end

local function markerPresence(entry, metadata)
    local state = string.lower(tostring(
        entry and entry.providerState
            or metadata and metadata.providerState or ""
    ))
    if state == "materialized" or state == "physical"
        or state == "live"
    then
        return "materialized"
    end
    if state == "abstract" or state == "remote"
        or state == "virtual"
    then
        return "abstract"
    end
    if entry and entry.bodyID then return "materialized" end
    return "unknown"
end

function ActorMap.DescribeMarker(marker)
    if type(marker) ~= "table" then return nil end
    local entry = marker.entry or marker
    local metadata = type(marker.hoverMetadata) == "table"
        and marker.hoverMetadata or {}
    local actorID = tostring(marker.actorID or entry.actorID
        or entry.id or entry.npcId or "")
    if actorID == "" then return nil end
    local presence = markerPresence(entry, metadata)
    local journey = entry.journey or {}
    local route = journey.route or entry.route
    local routePoints = route and route.points or route
    return {
        kind = "actor",
        source = "PsychopatzCore:SurvivorWorldActors",
        actorID = actorID,
        id = actorID,
        label = marker.label or entry.label or entry.displayName
            or entry.name or actorID,
        position = entry.position or marker.position,
        provider = entry.provider or metadata.provider,
        providerState = entry.providerState or metadata.providerState,
        presence = presence,
        materialized = presence == "materialized",
        bodyID = entry.bodyID or metadata.bodyID,
        traderID = metadata.traderID,
        groupID = entry.groupID or metadata.groupID,
        communityID = entry.communityID or metadata.communityID,
        actorSource = entry.sourceID or metadata.sourceID,
        journeyID = journey.id or journey.journeyID or entry.journeyID,
        journeyState = journey.state or entry.journeyState,
        routeAvailable = type(routePoints) == "table"
            and #routePoints > 0,
        rendered = marker.visible ~= false,
    }
end

function ActorMap.ListDiagnostics()
    local output = {}
    for _, marker in ipairs(ActorMap.BuildMarkers() or {}) do
        local row = ActorMap.DescribeMarker(marker)
        if row then output[#output + 1] = row end
    end
    return output
end

local function drawRoute(map, marker)
    if not marker or not (marker.selected or marker.tracked
        or Client.IsDebugPresentationEnabled and Client.IsDebugPresentationEnabled())
    then return end
    local journey = marker.entry and marker.entry.journey or nil
    local route = journey and journey.route or marker.entry
        and marker.entry.route or nil
    local points = route and route.points or nil
    if type(points) ~= "table" and type(route) == "table" then
        points = route
    end
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

    local icon = marker.icon or marker.emblem
    if type(icon) == "table" then
        local texture = icon.texture
        if texture and map.drawTextureScaledAspect then
            local iconSize = math.max(8, math.min(size, tonumber(icon.size) or size))
            map:drawTextureScaledAspect(
                texture,
                sx - iconSize / 2,
                sy - iconSize / 2,
                iconSize,
                iconSize,
                tonumber(icon.alpha) or 1,
                tonumber(icon.r) or 1,
                tonumber(icon.g) or 1,
                tonumber(icon.b) or 1
            )
        elseif icon.glyph and map.drawTextCentre then
            map:drawTextCentre(
                tostring(icon.glyph),
                sx,
                sy - math.max(6, size / 2),
                tonumber(icon.r) or 1,
                tonumber(icon.g) or 1,
                tonumber(icon.b) or 1,
                tonumber(icon.a) or 1,
                UIFont.Small
            )
        end
    end

    local badge = marker.badge
    if type(badge) == "table" and badge.glyph and map.drawTextCentre then
        map:drawTextCentre(
            tostring(badge.glyph),
            sx + size / 2,
            sy - size / 2,
            tonumber(badge.r) or 1,
            tonumber(badge.g) or 1,
            tonumber(badge.b) or 1,
            tonumber(badge.a) or 1,
            UIFont.Small
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
        if Hover and Hover.Hide then
            Hover.Hide(map, true, HOVER_OWNER)
        end
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
                elseif (marker.selected or marker.tracked or marker.showLabel)
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
                hovered.y,
                hovered.marker,
                HOVER_OWNER
            )
        end
    else
        if Client.SetHighlighted then Client.SetHighlighted(nil) end
        if Hover and Hover.Hide then
            Hover.Hide(map, true, HOVER_OWNER)
        end
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
