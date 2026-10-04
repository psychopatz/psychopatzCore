--[[
    PsychopatzCore: Feeding Trough map-object guard

    Vanilla ``media/lua/server/Map/MapObjects/MOFeedingTrough.lua`` replaces the
    map's feeding-trough sprites with real ``IsoFeedingTrough`` objects from
    inside a ``MapObjects`` callback.  Those callbacks are invoked by Java:

        MapObjects.newGridSquare / loadGridSquare
            -> LuaManager.caller.protectedCallVoid(thread, fn, params)

    ``protectedCallVoid`` reserves no Lua return slot.  When such a callback
    then calls a Lua-visible Java method *that returns a value* - here
    ``IsoGridSquare:transmitRemoveItemFromSquare(obj, safelyRemove)``, which is
    declared ``public int`` - Kahlua cannot marshal the result and dies while
    filling the return frame:

        java.lang.NullPointerException:
            Cannot assign field "callFrame" because "a" is null
            at ReturnValues.put(ReturnValues.java:61)

    The failure surfaces as ``Lua(Vanilla).ReplaceExistingObject> Exception
    thrown`` at MOFeedingTrough.lua:21 and aborts the whole replacement, so the
    trough never materialises and the chunk load keeps erroring.

    Deferring the surgery alone is not sufficient: ``Events.OnTick`` is also
    dispatched through a void callback frame.  The deferred pass must invoke
    the value-returning Java method as the function passed to ``pcall`` so
    Kahlua has a return frame for the integer result.  Wrapping only the outer
    Lua replacement function is insufficient.

    Contract:
      * Only the value-returning square mutation is deferred; sprite matching
        still happens synchronously in the callback, so we stay the sole
        producer for these sprites.
      * The original object is left untouched until the deferred pass runs, so
        a failed pass can never lose the map object.
      * The vanilla global-object system is re-entered through its public
        ``loadIsoObject`` hook, so containers, definitions, and client sync all
        keep working.
]]

PsychopatzCore = PsychopatzCore or {}

local Guard = PsychopatzCore.FeedingTroughGuard or {}
PsychopatzCore.FeedingTroughGuard = Guard

-- Authority-only.  Vanilla MOFeedingTrough.lua opens with the same predicate,
-- and the trough work belongs to whoever owns the map objects: that is the
-- single-player process and the multiplayer host, and never a remote client.
if isClient and isClient() == true and isServer and isServer() ~= true then
    return Guard
end

if Guard.installed then
    return Guard
end

-- Above vanilla's PRIORITY = 5 so this handler runs before MOFeedingTrough and
-- can claim the sprite before vanilla queries it.
local PRIORITY = 6
-- Bound per-frame work so a table of troughs cannot hitch the tick.
local MAX_PER_TICK = 8
-- Bound the queue so an unload/load storm cannot grow it without limit.
local MAX_QUEUED = 256
local DEBUG = false

-- Every sprite vanilla MOFeedingTrough registers, partitioned the same way it
-- partitions them, so the orientation matches the original handler exactly.
local SINGLE_WEST = {
    "location_farm_accesories_01_14",
}
local SINGLE_NORTH = {
    "location_farm_accesories_01_15",
}
local DOUBLE_WEST = {
    "location_farm_accesories_01_4",
    "location_farm_accesories_01_5",
    "location_farm_accesories_01_34",
    "location_farm_accesories_01_35",
    "location_farm_accesories_01_27",
    "location_farm_accesories_01_28",
    "location_farm_accesories_01_29",
    "location_farm_accesories_01_20",
    "location_farm_accesories_01_21",
    "location_farm_accesories_01_22",
    "location_farm_accesories_01_23",
}
local DOUBLE_NORTH = {
    "location_farm_accesories_01_6",
    "location_farm_accesories_01_7",
    "location_farm_accesories_01_32",
    "location_farm_accesories_01_33",
    "location_farm_accesories_01_24",
    "location_farm_accesories_01_25",
    "location_farm_accesories_01_26",
    "location_farm_accesories_01_16",
    "location_farm_accesories_01_17",
    "location_farm_accesories_01_18",
    "location_farm_accesories_01_19",
}

local function log(message)
    print("[PC] FeedingTroughGuard " .. tostring(message))
end

local function logOnce(key, message)
    Guard.reported = Guard.reported or {}
    if Guard.reported[key] then return end
    Guard.reported[key] = true
    log(message)
end

local function spriteName(isoObject)
    if not isoObject or not isoObject.getSprite then return nil end
    local ok, sprite = pcall(isoObject.getSprite, isoObject)
    if not ok or not sprite then return nil end
    if sprite.getName then
        local okName, name = pcall(sprite.getName, sprite)
        if okName and name and name ~= "" then return tostring(name) end
    end
    return nil
end

local function troughSystem()
    local system = rawget(_G, "SFeedingTroughSystem")
    return system and system.instance or nil
end

local function objectIndex(isoObject)
    if not isoObject.getObjectIndex then return nil end
    local ok, index = pcall(isoObject.getObjectIndex, isoObject)
    if ok then return index end
    return nil
end

-- Kept in lockstep with vanilla MOFeedingTrough.generateContainer.  Reading the
-- vanilla global would couple this guard to another file's load order, and the
-- roll is what makes a freshly placed trough useful.
local function generateContainerContents(trough)
    if trough:getFluidContainer() ~= nil and ZombRand(6) == 0 then
        trough:addWater(FluidType.TaintedWater,
            ZombRand(30, trough:getMaxWater()))
        return
    end
    local rolls = {
        { chance = 4, item = "Base.HayTuft", min = 10, max = 30 },
        { chance = 4, item = "Base.GrassTuft", min = 10, max = 30 },
        { chance = 6, item = "Base.AnimalFeedBag", min = 3, max = 8 },
    }
    for i = 1, #rolls do
        local roll = rolls[i]
        if ZombRand(roll.chance) == 0 then
            local container = trough:getContainer()
            local count = ZombRand(roll.min, roll.max)
            for _ = 0, count - 1 do
                container:AddItem(roll.item)
            end
        end
    end
end

-- Square surgery.  Runs one tick later than the map-object callback on purpose:
-- this is the call whose return value Kahlua cannot marshal from inside
-- protectedCallVoid.
local function replaceTrough(isoObject, isNorth)
    local square = isoObject:getSquare()
    if not square then return false, "no_square" end
    local name = spriteName(isoObject)
    if not name then return false, "no_sprite" end
    local index = objectIndex(isoObject)

    local system = troughSystem()
    if system and system.removeLuaObject then
        local existing = system.getLuaObjectOnSquare
            and system:getLuaObjectOnSquare(square)
            or nil
        if existing then
            system:removeLuaObject(existing)
        end
    end

    -- This Java method returns an int.  Pass the bound method directly to
    -- pcall so Kahlua owns a return frame even though flush() runs from the
    -- void Events.OnTick callback.
    local removed = pcall(
        square.transmitRemoveItemFromSquare,
        square,
        isoObject,
        false
    )
    if not removed then
        return false, "remove_failed"
    end

    local trough = IsoFeedingTrough.new(square, name, nil)
    if not trough then return false, "create_failed" end
    trough:setNorth(isNorth == true)
    -- Vanilla always runs this on a freshly created trough; it fetches (or
    -- registers) the definition that carries capacity and fluid data.
    trough:initWithDef()
    if index ~= nil and square.AddSpecialObject then
        square:AddSpecialObject(trough, index)
    else
        square:AddSpecialObject(trough)
    end
    if trough.getMasterTrough
        and trough:getMasterTrough() == trough
        and trough:getContainer()
    then
        generateContainerContents(trough)
    end
    if trough.checkOverlayFull then
        trough:checkOverlayFull(false)
    end
    if trough.transmitCompleteItemToClients then
        trough:transmitCompleteItemToClients()
    end
    if system and system.loadIsoObject then
        system:loadIsoObject(trough)
    end
    return true
end

local function applyEntry(entry)
    local isoObject = entry.isoObject
    if not isoObject or not isoObject.getSquare then return end
    -- The chunk may have unloaded between the callback and this tick.
    if not isoObject:getSquare() then
        logOnce("no_square", "deferred trough skipped: square unloaded")
        return
    end
    local called, replaced, reason =
        pcall(replaceTrough, isoObject, entry.isNorth)
    if not called then
        -- The original object is only removed after this point, so a throw
        -- here leaves the map intact for a clean retry.
        logOnce("replace_threw",
            "deferred trough replacement threw: " .. tostring(replaced))
    elseif replaced ~= true then
        logOnce("replace_" .. tostring(reason),
            "deferred trough skipped: " .. tostring(reason))
    end
end

local function flush(now)
    local queue = Guard.queue
    if not queue or #queue == 0 then return end
    local processed = 0
    while #queue > 0 and processed < MAX_PER_TICK do
        local entry = table.remove(queue, 1)
        processed = processed + 1
        applyEntry(entry)
    end
end

local function enqueue(isoObject, isNorth)
    if not isoObject then return end
    Guard.queue = Guard.queue or {}
    local queue = Guard.queue
    if #queue >= MAX_QUEUED then
        logOnce("queue_full", "deferred trough queue full; skipping")
        return
    end
    queue[#queue + 1] = { isoObject = isoObject, isNorth = isNorth == true }
    if DEBUG then
        log("queued trough sprite=" .. tostring(spriteName(isoObject))
            .. " north=" .. tostring(isNorth == true))
    end
end

Guard.Install = function()
    if Guard.installed then return end
    if not MapObjects or not MapObjects.OnNewWithSprite
        or not MapObjects.OnLoadWithSprite
    then
        return
    end
    -- VANILLA_PRIORITY(5) < PRIORITY(6) => this handler is inserted first.
    MapObjects.OnNewWithSprite(DOUBLE_WEST, enqueue, PRIORITY)
    MapObjects.OnNewWithSprite(SINGLE_WEST, enqueue, PRIORITY)
    MapObjects.OnNewWithSprite(DOUBLE_NORTH, function(isoObject)
        enqueue(isoObject, true)
    end, PRIORITY)
    MapObjects.OnNewWithSprite(SINGLE_NORTH, function(isoObject)
        enqueue(isoObject, true)
    end, PRIORITY)
    -- Existing saves still hold the raw sprite, so the load path needs the same
    -- claim before vanilla's loader reaches for the same return-value call.
    MapObjects.OnLoadWithSprite(DOUBLE_WEST, enqueue, PRIORITY)
    MapObjects.OnLoadWithSprite(SINGLE_WEST, enqueue, PRIORITY)
    MapObjects.OnLoadWithSprite(DOUBLE_NORTH, function(isoObject)
        enqueue(isoObject, true)
    end, PRIORITY)
    MapObjects.OnLoadWithSprite(SINGLE_NORTH, function(isoObject)
        enqueue(isoObject, true)
    end, PRIORITY)

    Events.OnTick.Add(flush)
    Guard.installed = true
    log("installed vanilla feeding-trough defusal (deferred removal)")
end

Guard.Install()

return Guard
