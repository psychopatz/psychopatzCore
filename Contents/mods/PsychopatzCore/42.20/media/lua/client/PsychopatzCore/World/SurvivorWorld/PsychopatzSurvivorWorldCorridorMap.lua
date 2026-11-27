-- Debug world-map overlay for PsychopatzCore's dynamic MetaGrid street &
-- settlement corridor graph. Shared by DynamicTrading (DTAbstract) and
-- Project Hoomans; renders only when Core debug presentation is enabled.

local Client = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldClient"
local CorridorGraph = require
    "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldCorridorGraph"
local WorldEvents = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldEvents"
local Host = require "PsychopatzCore/UI/Map/PsychopatzMapHost"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.SurvivorWorldCorridorMap =
    PsychopatzCore.SurvivorWorldCorridorMap or {}

local CorridorMap = PsychopatzCore.SurvivorWorldCorridorMap
-- Opt-in via Map Tools ("CORRIDOR GRAPH") so the MetaGrid node web never
-- clutters normal debug actor/route inspection unless explicitly toggled ON.
CorridorMap.Enabled = CorridorMap.Enabled == true

function CorridorMap.IsEnabled()
    return CorridorMap.Enabled == true
end

function CorridorMap.SetEnabled(enabled)
    CorridorMap.Enabled = enabled == true
    return CorridorMap.Enabled
end

local function isDebugVisible()
    return CorridorMap.Enabled == true
        and Client
        and type(Client.IsDebugPresentationEnabled) == "function"
        and Client.IsDebugPresentationEnabled() == true
end

function CorridorMap.ListDiagnostics()
    local rows = {}
    local snapshot = CorridorGraph.GetDebugSnapshot()
    if type(snapshot) == "table" then
        local nodes = snapshot.nodes or {}
        for i = 1, #nodes do
            local n = nodes[i]
            if n.kind == "settlement" then
                rows[#rows + 1] = {
                    id = tostring(n.id),
                    label = tostring(n.label or n.id),
                    kind = "corridor_settlement",
                    x = n.x,
                    y = n.y,
                    detail = "sector=" .. tostring(n.sectorKey or "")
                        .. " nodes=" .. tostring(#nodes)
                        .. " edges=" .. tostring(#(snapshot.edges or {})),
                }
            end
        end
    end
    local events = WorldEvents and type(WorldEvents.List) == "function"
        and WorldEvents.List() or {}
    for i = 1, #events do
        local ev = events[i]
        rows[#rows + 1] = {
            id = tostring(ev.id),
            label = tostring(ev.kind) .. " (" .. tostring(ev.ownerMod or "Core") .. ")",
            kind = "world_event_" .. string.lower(tostring(ev.kind or "event")),
            x = ev.x,
            y = ev.y,
            detail = tostring(ev.summary or ""),
        }
    end
    return rows
end

function CorridorMap.Render(map)
    if not isDebugVisible() or not map or not map.mapAPI then
        return
    end
    local snapshot = CorridorGraph.GetDebugSnapshot()
    if type(snapshot) ~= "table" then return end
    local width = tonumber(map.width) or 0
    local height = tonumber(map.height) or 0

    local edges = snapshot.edges or {}
    if map.javaObject and map.javaObject.DrawLine then
        for i = 1, #edges do
            local e = edges[i]
            local x1 = map.mapAPI:worldToUIX(e.fromX, e.fromY)
            local y1 = map.mapAPI:worldToUIY(e.fromX, e.fromY)
            local x2 = map.mapAPI:worldToUIX(e.toX, e.toY)
            local y2 = map.mapAPI:worldToUIY(e.toX, e.toY)
            if (x1 >= -32 and x1 <= width + 32 and y1 >= -32 and y1 <= height + 32)
                or (x2 >= -32 and x2 <= width + 32 and y2 >= -32 and y2 <= height + 32)
            then
                map.javaObject:DrawLine(nil, x1, y1, x2, y2, 1, 0.25, 0.85, 0.95, 0.45)
            end
        end
    end

    local nodes = snapshot.nodes or {}
    for i = 1, #nodes do
        local n = nodes[i]
        local sx = map.mapAPI:worldToUIX(n.x, n.y)
        local sy = map.mapAPI:worldToUIY(n.x, n.y)
        if sx >= -16 and sy >= -16 and sx <= width + 16 and sy <= height + 16 then
            local isSettlement = n.kind == "settlement"
            local size = isSettlement and 7 or 4
            local half = size / 2
            local r = isSettlement and 1.0 or 0.30
            local g = isSettlement and 0.82 or 0.90
            local b = isSettlement and 0.20 or 1.0
            if map.drawRect then
                map:drawRect(sx - half, sy - half, size, size, 0.9, r, g, b)
            end
            if map.drawRectBorder then
                map:drawRectBorder(sx - half - 1, sy - half - 1, size + 2, size + 2, 0.9, 0.05, 0.05, 0.05)
            end
        end
    end

    -- Render canonical Core SurvivorWorld Events (aftermath, SOS, and any future
    -- Events Mod world events) strictly gated behind debug presentation.
    local events = WorldEvents and type(WorldEvents.List) == "function"
        and WorldEvents.List() or {}
    for i = 1, #events do
        local ev = events[i]
        local sx = map.mapAPI:worldToUIX(ev.x, ev.y)
        local sy = map.mapAPI:worldToUIY(ev.x, ev.y)
        if sx >= -16 and sy >= -16 and sx <= width + 16 and sy <= height + 16 then
            local isSOS = ev.kind == "COLONIST_SOS"
            local isDead = ev.kind == "COLONIST_DEAD" or ev.kind == "HAZARD_OVERWHELMED"
            local r = isSOS and 1.0 or (isDead and 0.95 or 0.35)
            local g = isSOS and 0.58 or (isDead and 0.15 or 0.95)
            local b = isSOS and 0.10 or (isDead and 0.15 or 0.45)
            if map.drawRect then
                map:drawRect(sx - 4, sy - 4, 8, 8, 0.95, r, g, b)
            end
            if map.drawRectBorder then
                map:drawRectBorder(sx - 5, sy - 5, 10, 10, 0.95, 0.05, 0.05, 0.05)
            end
        end
    end
end

Host.Overlays.Register("PsychopatzCore:SurvivorWorldCorridors", {
    order = 82,
    render = CorridorMap.Render,
    enabled = isDebugVisible,
    owner = "PsychopatzCore",
})

return CorridorMap
