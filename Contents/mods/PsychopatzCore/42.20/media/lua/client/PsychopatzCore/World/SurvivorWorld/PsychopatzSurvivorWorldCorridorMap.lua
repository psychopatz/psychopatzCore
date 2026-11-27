-- Debug world-map overlay for PsychopatzCore's dynamic MetaGrid street &
-- settlement corridor graph. Shared by DynamicTrading (DTAbstract) and
-- Project Hoomans; renders only when Core debug presentation is enabled.

local Client = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldClient"
local CorridorGraph = require
    "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldCorridorGraph"
local Host = require "PsychopatzCore/UI/Map/PsychopatzMapHost"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.SurvivorWorldCorridorMap =
    PsychopatzCore.SurvivorWorldCorridorMap or {}

local CorridorMap = PsychopatzCore.SurvivorWorldCorridorMap
CorridorMap.Enabled = CorridorMap.Enabled ~= false

local function isDebugVisible()
    return CorridorMap.Enabled == true
        and Client
        and type(Client.IsDebugPresentationEnabled) == "function"
        and Client.IsDebugPresentationEnabled() == true
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

    -- Render off-camera aftermath / SOS / hazard debug markers when available
    -- (strictly gated behind Core debug presentation; normal map stays clean).
    local aftermath = _G.PNC and _G.PNC.AbstractAftermathService or nil
    if aftermath and type(aftermath.GetDebugSnapshot) == "function" then
        local aSnap = aftermath.GetDebugSnapshot()
        local sites = type(aSnap) == "table" and aSnap.sites or {}
        for i = 1, #sites do
            local s = sites[i]
            local sx = map.mapAPI:worldToUIX(s.x, s.y)
            local sy = map.mapAPI:worldToUIY(s.x, s.y)
            if sx >= -16 and sy >= -16 and sx <= width + 16 and sy <= height + 16 then
                local isSOS = s.kind == "COLONIST_SOS"
                local isDead = s.kind == "COLONIST_DEAD"
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
end

Host.Overlays.Register("PsychopatzCore:SurvivorWorldCorridors", {
    order = 82,
    render = CorridorMap.Render,
    enabled = isDebugVisible,
    owner = "PsychopatzCore",
})

return CorridorMap
