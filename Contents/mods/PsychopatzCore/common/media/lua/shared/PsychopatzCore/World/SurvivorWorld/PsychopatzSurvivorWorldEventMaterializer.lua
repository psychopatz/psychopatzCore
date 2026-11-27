-- Provider-neutral on-approach physical scene materializer for
-- PsychopatzCore.SurvivorWorld.Events. Any mod (ProjectHoomans aftermath/SOS,
-- DynamicTrading, or a future Events Mod) registers a handler per event kind
-- and receives guaranteed one-shot materialization when a player approaches.

local WorldEvents = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldEvents"

local Materializer = {}

Materializer.Handlers = Materializer.Handlers or {}
Materializer.DEFAULT_RADIUS = 55
Materializer.DEFAULT_BUDGET = 2

function Materializer.RegisterHandler(kind, handlerFn)
    kind = tostring(kind or "")
    if kind == "" or type(handlerFn) ~= "function" then return false end
    Materializer.Handlers[kind] = handlerFn
    return true
end

function Materializer.UnregisterHandler(kind)
    kind = tostring(kind or "")
    if kind == "" or Materializer.Handlers[kind] == nil then return false end
    Materializer.Handlers[kind] = nil
    return true
end

local function resolveLoadedSquare(x, y, z)
    local cell = getCell and getCell() or nil
    if not cell or type(cell.getGridSquare) ~= "function" then
        return nil
    end
    local ok, sq = pcall(cell.getGridSquare, cell, math.floor(x), math.floor(y), math.floor(z or 0))
    if ok and sq then return sq end
    return nil
end

local function isAnyPlayerNear(players, x, y, radiusSq)
    for i = 1, #players do
        local p = players[i]
        if p and type(p.getX) == "function" and type(p.getY) == "function" then
            local dx = (tonumber(p:getX()) or 0) - x
            local dy = (tonumber(p:getY()) or 0) - y
            if (dx * dx + dy * dy) <= radiusSq then
                return true, p
            end
        end
    end
    return false, nil
end

-- O(activeEvents <= 32) bounded pump: materializes at most `budget` events per call
-- once a player enters range and the target chunk square is loaded.
function Materializer.PumpNearPlayers(players, radius, worldHour, budget)
    if type(players) ~= "table" or #players == 0 then return 0 end
    radius = math.max(8, tonumber(radius) or Materializer.DEFAULT_RADIUS)
    budget = math.max(1, math.floor(tonumber(budget) or Materializer.DEFAULT_BUDGET))
    local radiusSq = radius * radius
    local events = WorldEvents.List()
    local materializedCount = 0

    for i = 1, #events do
        if materializedCount >= budget then break end
        local ev = events[i]
        local payload = type(ev.payload) == "table" and ev.payload or {}
        if ev.active ~= false and payload.materialized ~= true then
            local handler = Materializer.Handlers[ev.kind] or Materializer.Handlers["*"]
            if type(handler) == "function" then
                local near, player = isAnyPlayerNear(players, ev.x, ev.y, radiusSq)
                if near then
                    local sq = resolveLoadedSquare(ev.x, ev.y, ev.z or 0)
                    if sq then
                        local ok, handled, reason = pcall(handler, ev, sq, worldHour, player)
                        if ok and handled == true then
                            payload.materialized = true
                            payload.materializedAt = tonumber(worldHour) or 0
                            ev.payload = payload
                            WorldEvents.Publish(ev, worldHour)
                            materializedCount = materializedCount + 1
                        elseif not ok and PsychopatzCore and PsychopatzCore.LogWarn then
                            PsychopatzCore.LogWarn(
                                "SurvivorWorld EventMaterializer handler failed kind="
                                    .. tostring(ev.kind) .. " err=" .. tostring(handled)
                            )
                        end
                    end
                end
            end
        end
    end
    return materializedCount
end

function Materializer.Reset()
    Materializer.Handlers = {}
end

return Materializer
