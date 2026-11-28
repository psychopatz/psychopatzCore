-- Agnostic, modular on-approach physical scene materializer for
-- PsychopatzCore.SurvivorWorld.Events.
--
-- Any mod (ProjectHoomans, DynamicTrading, or a future World Events mod) can:
--   1. Register a simple handler:     Materializer.RegisterHandler(kind, fn)
--   2. Register a rich descriptor:    Materializer.Register(id, { kind/kinds/tag, priority, radius, canMaterialize, materialize, cleanup, ownerMod })
--   3. Register a declarative scene:  Materializer.RegisterBlueprint(kind, { items = {...}, scatterRadius = 2, ... })
--
-- Guarantees one-shot materialization per event, priority-ordered fallback,
-- bounded per-tick pump budget, and automatic cleanup hook dispatch on expiry/cancel.

local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local WorldEvents = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldEvents"

local Materializer = {}

Materializer.Handlers = Materializer.Handlers or {}
Materializer.Registry = Materializer.Registry or {}
Materializer.OrderedIDs = Materializer.OrderedIDs or {}
Materializer.ItemSpawner = Materializer.ItemSpawner or nil
Materializer.DEFAULT_RADIUS = 55
Materializer.DEFAULT_BUDGET = 2
Materializer._lifecycleHooked = Materializer._lifecycleHooked == true
Materializer._stats = Materializer._stats or {
    materialized = 0,
    cleanedUp = 0,
    errors = 0,
}

local function sortRegistry()
    local ids = {}
    for id in pairs(Materializer.Registry) do
        ids[#ids + 1] = id
    end
    table.sort(ids, function(a, b)
        local ra = Materializer.Registry[a]
        local rb = Materializer.Registry[b]
        local pa = tonumber(ra and ra.priority) or 50
        local pb = tonumber(rb and rb.priority) or 50
        if pa ~= pb then return pa > pb end
        return tostring(a) < tostring(b)
    end)
    Materializer.OrderedIDs = ids
end

local function matchesDescriptor(desc, ev)
    if type(desc) ~= "table" or type(ev) ~= "table" then return false end
    if desc.kind == "*" then return true end
    if desc.kind and ev.kind == desc.kind then return true end
    if type(desc.kinds) == "table" then
        for i = 1, #desc.kinds do
            if desc.kinds[i] == ev.kind then return true end
        end
    end
    if desc.tag and type(ev.tags) == "table" and ev.tags[desc.tag] == true then
        return true
    end
    return false
end

local function ensureLifecycleHook()
    if Materializer._lifecycleHooked then return end
    if WorldEvents and type(WorldEvents.Subscribe) == "function" then
        Materializer._lifecycleHooked = true
        WorldEvents.Subscribe("*", function(ev, lifecycle)
            if lifecycle ~= "expired" and lifecycle ~= "cancelled" then return end
            local payload = type(ev) == "table" and type(ev.payload) == "table" and ev.payload or nil
            if not payload or payload.materialized ~= true then return end
            local handlerID = payload.materializedBy
            local desc = handlerID and Materializer.Registry[handlerID] or nil
            if desc and type(desc.cleanup) == "function" then
                local ok, err = pcall(desc.cleanup, ev, lifecycle)
                if ok then
                    Materializer._stats.cleanedUp = (Materializer._stats.cleanedUp or 0) + 1
                elseif PsychopatzCore and PsychopatzCore.LogWarn then
                    PsychopatzCore.LogWarn(
                        "SurvivorWorld EventMaterializer cleanup failed id="
                            .. tostring(handlerID) .. " err=" .. tostring(err)
                    )
                end
            end
        end)
    end
end

function Materializer.Register(id, spec)
    id = tostring(id or "")
    if id == "" or type(spec) ~= "table" or type(spec.materialize) ~= "function" then
        return false, "invalid_materializer_spec"
    end
    ensureLifecycleHook()
    Materializer.Registry[id] = {
        id = id,
        ownerMod = tostring(spec.ownerMod or "PsychopatzCore"),
        kind = spec.kind and tostring(spec.kind) or nil,
        kinds = type(spec.kinds) == "table" and spec.kinds or nil,
        tag = spec.tag and tostring(spec.tag) or nil,
        priority = tonumber(spec.priority) or 50,
        radius = tonumber(spec.radius) or nil,
        canMaterialize = type(spec.canMaterialize) == "function" and spec.canMaterialize or nil,
        materialize = spec.materialize,
        cleanup = type(spec.cleanup) == "function" and spec.cleanup or nil,
    }
    sortRegistry()
    return true
end

function Materializer.Unregister(id)
    id = tostring(id or "")
    if id == "" or Materializer.Registry[id] == nil then return false end
    Materializer.Registry[id] = nil
    sortRegistry()
    return true
end

function Materializer.UnregisterByOwner(ownerMod)
    ownerMod = tostring(ownerMod or "")
    if ownerMod == "" then return 0 end
    local removed = 0
    for id, desc in pairs(Materializer.Registry) do
        if desc.ownerMod == ownerMod then
            Materializer.Registry[id] = nil
            removed = removed + 1
        end
    end
    if removed > 0 then sortRegistry() end
    return removed
end

-- Backwards-compatible convenience API for single-function per-kind handlers.
function Materializer.RegisterHandler(kind, handlerFn)
    kind = tostring(kind or "")
    if kind == "" or type(handlerFn) ~= "function" then return false end
    Materializer.Handlers[kind] = handlerFn
    Materializer.Register("handler:" .. kind, {
        kind = kind,
        priority = 60,
        materialize = handlerFn,
    })
    return true
end

function Materializer.UnregisterHandler(kind)
    kind = tostring(kind or "")
    if kind == "" then return false end
    local existed = Materializer.Handlers[kind] ~= nil
        or Materializer.Registry["handler:" .. kind] ~= nil
    Materializer.Handlers[kind] = nil
    Materializer.Unregister("handler:" .. kind)
    return existed
end

local function spawnWorldItem(sq, itemType, ox, oy)
    if type(Materializer.ItemSpawner) == "function" then
        return pcall(Materializer.ItemSpawner, sq, itemType, ox, oy)
    end
    if sq and type(sq.AddWorldInventoryItem) == "function" then
        return pcall(sq.AddWorldInventoryItem, sq, tostring(itemType), ox or 0.5, oy or 0.5, 0)
    end
    return true
end

-- Declarative scene blueprint registration so any mod can add new physical
-- world events (camp remains, roadblocks, drops, skirmish aftermath) in data.
function Materializer.RegisterBlueprint(kind, blueprint)
    kind = tostring(kind or "")
    if kind == "" or type(blueprint) ~= "table" then
        return false, "invalid_blueprint"
    end
    local items = type(blueprint.items) == "table" and blueprint.items or {}
    local scatter = math.max(0, tonumber(blueprint.scatterRadius) or 2)
    local id = tostring(blueprint.id or ("blueprint:" .. kind))
    return Materializer.Register(id, {
        ownerMod = tostring(blueprint.ownerMod or "PsychopatzCore"),
        kind = kind,
        tag = blueprint.tag,
        priority = tonumber(blueprint.priority) or 30,
        radius = tonumber(blueprint.radius) or nil,
        canMaterialize = blueprint.canMaterialize,
        cleanup = blueprint.cleanup,
        materialize = function(ev, sq, worldHour, player)
            local spawned = 0
            local seedBase = tostring(ev.id or kind) .. ":" .. tostring(math.floor(ev.x or 0))
                .. ":" .. tostring(math.floor(ev.y or 0))
            for idx = 1, #items do
                local spec = items[idx]
                if type(spec) == "table" and spec.type then
                    local h = Util.hash(seedBase .. ":" .. tostring(idx) .. ":" .. tostring(spec.type))
                    local roll = (h % 1000) / 1000.0
                    local chance = tonumber(spec.chance) or 1.0
                    if roll <= chance then
                        local lo = math.max(0, math.floor(tonumber(spec.min) or 1))
                        local hi = math.max(lo, math.floor(tonumber(spec.max) or lo))
                        local count = lo + (hi > lo and (h % (hi - lo + 1)) or 0)
                        for n = 1, count do
                            local ox = 0.2 + ((Util.hash(seedBase .. ":x:" .. idx .. ":" .. n) % 60) / 100.0)
                            local oy = 0.2 + ((Util.hash(seedBase .. ":y:" .. idx .. ":" .. n) % 60) / 100.0)
                            local targetSq = sq
                            if scatter > 0 and type(getCell) == "function" then
                                local cell = getCell()
                                if cell and type(cell.getGridSquare) == "function" then
                                    local dx = (Util.hash(seedBase .. ":dx:" .. idx .. ":" .. n) % (scatter * 2 + 1)) - scatter
                                    local dy = (Util.hash(seedBase .. ":dy:" .. idx .. ":" .. n) % (scatter * 2 + 1)) - scatter
                                    local okSq, alt = pcall(
                                        cell.getGridSquare,
                                        cell,
                                        math.floor((ev.x or 0) + dx),
                                        math.floor((ev.y or 0) + dy),
                                        math.floor(ev.z or 0)
                                    )
                                    if okSq and alt then targetSq = alt end
                                end
                            end
                            local okAdd = spawnWorldItem(targetSq, spec.type, ox, oy)
                            if okAdd then spawned = spawned + 1 end
                        end
                    end
                end
            end
            if type(blueprint.onMaterialize) == "function" then
                pcall(blueprint.onMaterialize, ev, sq, worldHour, player, spawned)
            end
            return true, { spawnedItems = spawned }
        end,
    })
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
    local defaultRadius = math.max(8, tonumber(radius) or Materializer.DEFAULT_RADIUS)
    budget = math.max(1, math.floor(tonumber(budget) or Materializer.DEFAULT_BUDGET))
    local events = WorldEvents.List()
    local materializedCount = 0

    for i = 1, #events do
        if materializedCount >= budget then break end
        local ev = events[i]
        local payload = type(ev.payload) == "table" and ev.payload or {}
        if ev.active ~= false and payload.materialized ~= true then
            for hIdx = 1, #Materializer.OrderedIDs do
                local desc = Materializer.Registry[Materializer.OrderedIDs[hIdx]]
                if desc and matchesDescriptor(desc, ev) then
                    local effRadius = math.max(8, tonumber(desc.radius) or defaultRadius)
                    local near, player = isAnyPlayerNear(players, ev.x, ev.y, effRadius * effRadius)
                    if near then
                        local sq = resolveLoadedSquare(ev.x, ev.y, ev.z or 0)
                        if sq then
                            local allowed = true
                            if desc.canMaterialize then
                                local okCan, resCan = pcall(desc.canMaterialize, ev, sq, worldHour, player)
                                allowed = okCan and resCan == true
                            end
                            if allowed then
                                local ok, handled, meta = pcall(desc.materialize, ev, sq, worldHour, player)
                                if ok and handled == true then
                                    payload.materialized = true
                                    payload.materializedAt = tonumber(worldHour) or 0
                                    payload.materializedBy = desc.id
                                    if type(meta) == "table" then
                                        payload.materializedMeta = meta
                                    end
                                    ev.payload = payload
                                    WorldEvents.Publish(ev, worldHour)
                                    Materializer._stats.materialized = (Materializer._stats.materialized or 0) + 1
                                    materializedCount = materializedCount + 1
                                    break
                                elseif not ok then
                                    Materializer._stats.errors = (Materializer._stats.errors or 0) + 1
                                    if PsychopatzCore and PsychopatzCore.LogWarn then
                                        PsychopatzCore.LogWarn(
                                            "SurvivorWorld EventMaterializer handler failed id="
                                                .. tostring(desc.id) .. " kind="
                                                .. tostring(ev.kind) .. " err=" .. tostring(handled)
                                        )
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return materializedCount
end

function Materializer.ListHandlers()
    local out = {}
    for i = 1, #Materializer.OrderedIDs do
        local desc = Materializer.Registry[Materializer.OrderedIDs[i]]
        if desc then
            out[#out + 1] = {
                id = desc.id,
                ownerMod = desc.ownerMod,
                kind = desc.kind,
                tag = desc.tag,
                priority = desc.priority,
                radius = desc.radius,
            }
        end
    end
    return out
end

function Materializer.GetStats()
    return {
        handlerCount = #Materializer.OrderedIDs,
        materialized = Materializer._stats.materialized or 0,
        cleanedUp = Materializer._stats.cleanedUp or 0,
        errors = Materializer._stats.errors or 0,
    }
end

function Materializer.RegisterDefaultBlueprints()
    Materializer.RegisterBlueprint("CAMP_REMAINS", {
        id = "core:blueprint:CAMP_REMAINS",
        ownerMod = "PsychopatzCore",
        priority = 20,
        radius = 45,
        scatterRadius = 2,
        items = {
            { type = "Base.TinCanEmpty", min = 1, max = 2, chance = 0.85 },
            { type = "Base.Twigs", min = 1, max = 2, chance = 0.90 },
            { type = "Base.RippedSheetsDirty", min = 0, max = 1, chance = 0.45 },
        },
    })
    Materializer.RegisterBlueprint("RAID_AFTERMATH", {
        id = "core:blueprint:RAID_AFTERMATH",
        ownerMod = "PsychopatzCore",
        priority = 20,
        radius = 55,
        scatterRadius = 3,
        items = {
            { type = "Base.RippedSheetsDirty", min = 1, max = 2, chance = 0.80 },
            { type = "Base.BandageDirty", min = 0, max = 1, chance = 0.50 },
            { type = "Base.TinCanEmpty", min = 1, max = 2, chance = 0.65 },
        },
    })
end

function Materializer.Reset()
    Materializer.Handlers = {}
    Materializer.Registry = {}
    Materializer.OrderedIDs = {}
    Materializer._lifecycleHooked = false
    Materializer._stats = { materialized = 0, cleanedUp = 0, errors = 0 }
end

Materializer.RegisterDefaultBlueprints()

return Materializer
