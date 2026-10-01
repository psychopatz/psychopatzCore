--[[
    Feeding-trough guard contract.

    The two things that must hold, and that the original vanilla path broke:

      1. The MapObjects callback only *claims* the sprite. It must never touch
         ``transmitRemoveItemFromSquare``, because the Java->Lua callback frame
         reserves no return slot and the call cannot marshal its int result.
      2. The deferred pass performs the square surgery exactly once and leaves
         a valid trough behind.
]]

local function equal(actual, expected, message)
    if actual ~= expected then
        error((message or "mismatch") .. ": expected="
            .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, message)
    if not value then error((message or "expected truthy") .. ": got " .. tostring(value)) end
end

package.path = table.concat({
    "Contents/mods/PsychopatzCore/42.20/media/lua/server/?.lua",
    package.path,
}, ";")

PsychopatzCore = {}

-- --- engine stubs -----------------------------------------------------------

local tickCallback
Events = {
    OnTick = {
        Add = function(callback) tickCallback = callback end,
        Remove = function(callback)
            if tickCallback == callback then tickCallback = nil end
        end,
    },
}
-- Single-player shape: the owning process is both client and authority, which
-- is exactly where the report was observed.  A pure MP client must skip.
isClient = function() return true end
isServer = function() return true end

local registeredNew = {}
local registeredLoad = {}
MapObjects = {
    OnNewWithSprite = function(spriteNames, callback, priority)
        registeredNew[#registeredNew + 1] = {
            sprites = spriteNames, callback = callback, priority = priority,
        }
    end,
    OnLoadWithSprite = function(spriteNames, callback, priority)
        registeredLoad[#registeredLoad + 1] = {
            sprites = spriteNames, callback = callback, priority = priority,
        }
    end,
}

local transmitted = {}
local addedTroughs = {}

local function newSpriteObject(name)
    return {
        getName = function() return name end,
    }
end

local function newSquareObject(name)
    local square = {
        objects = {},
        x = 10, y = 10, z = 0,
        transmitted = transmitted,
        addSpecialCount = 0,
    }
    local object = {
        square = square,
        index = 3,
        getSquare = function() return square end,
        getObjectIndex = function() return 3 end,
        getSprite = function() return newSpriteObject(name) end,
    }
    square.objects[1] = object
    square.contains = function(_, candidate)
        for i = 1, #square.objects do
            if square.objects[i] == candidate then return true end
        end
        return false
    end
    square.transmitRemoveItemFromSquare = function(_, target, safely)
        transmitted[#transmitted + 1] = {
            target = target, safely = safely, index = #transmitted + 1,
        }
        for i = #square.objects, 1, -1 do
            if square.objects[i] == target then table.remove(square.objects, i) end
        end
        return 1
    end
    square.AddSpecialObject = function(_, trough, index)
        square.addSpecialCount = square.addSpecialCount + 1
        trough.addedAtIndex = index
        square.objects[#square.objects + 1] = trough
    end
    return square, object
end

local troughInstances = {}
IsoFeedingTrough = {
    new = function(square, name, linked)
        local trough = {
            square = square, spriteName = name, linked = linked,
            north = false,
            def = nil,
            initCount = 0,
            overlayChecked = 0,
            transmittedToClients = 0,
        }
        function trough.setNorth(_, value) trough.north = value end
        function trough.initWithDef() trough.initCount = trough.initCount + 1 end
        function trough.getDef() return trough.def end
        function trough.getMasterTrough() return trough end
        function trough.getContainer() return trough.container end
        function trough.checkOverlayFull() trough.overlayChecked = trough.overlayChecked + 1 end
        function trough.transmitCompleteItemToClients()
            trough.transmittedToClients = trough.transmittedToClients + 1
        end
        troughInstances[#troughInstances + 1] = trough
        return trough
    end,
}

ZombRand = function() return 1 end
FluidType = { TaintedWater = "TaintedWater" }

local loadedThroughSystem = 0
SFeedingTroughSystem = {
    instance = {
        removed = 0,
        getLuaObjectOnSquare = function() return nil end,
        removeLuaObject = function(self) self.removed = self.removed + 1 end,
        loadIsoObject = function() loadedThroughSystem = loadedThroughSystem + 1 end,
    },
}

-- --- install ----------------------------------------------------------------

require "PsychopatzCore/Compatibility/PsychopatzFeedingTroughGuard"

local Guard = PsychopatzCore.FeedingTroughGuard
truthy(Guard, "guard module did not load")
equal(Guard.installed, true, "guard did not install")
truthy(tickCallback, "guard did not register its deferred pump")

-- Vanilla registers at priority 5; we must sit strictly above it so the sprite
-- is claimed before the vanilla callback reaches the unmarshalable call.
equal(#registeredNew, 4, "expected four OnNew registrations")
equal(#registeredLoad, 4, "expected four OnLoad registrations")
local spriteCount = 0
for i = 1, #registeredNew do
    local entry = registeredNew[i]
    truthy(entry.priority > 5, "OnNew priority must beat vanilla (5)")
    spriteCount = spriteCount + #entry.sprites
end
for i = 1, #registeredLoad do
    local entry = registeredLoad[i]
    truthy(entry.priority > 5, "OnLoad priority must beat vanilla (5)")
    spriteCount = spriteCount + #entry.sprites
end
-- Vanilla registers 24 trough sprites on each of the two paths.
equal(spriteCount, 48, "expected 24 sprites on each path")

-- --- the callback must not touch the square ---------------------------------

local square, object = newSquareObject("location_farm_accesories_01_35")
-- Match the west-facing double handler, which vanilla wires with isNorth=false.
local newWestCallback = registeredNew[1].callback
newWestCallback(object)

equal(#transmitted, 0,
    "callback must not call transmitRemoveItemFromSquare")
equal(#square.objects, 1, "callback must leave the original object in place")
equal(#troughInstances, 0, "callback must not create the trough")

-- --- the deferred pump performs the surgery ---------------------------------

tickCallback()

equal(#transmitted, 1, "pump must transmit the removal exactly once")
equal(transmitted[1].target, object, "pump must remove the claimed object")
equal(transmitted[1].safely, false, "pump must keep vanilla's safelyRemove flag")
equal(#troughInstances, 1, "pump must create one trough")

local trough = troughInstances[1]
equal(trough.spriteName, "location_farm_accesories_01_35", "sprite name preserved")
equal(trough.north, false, "west handler keeps isNorth=false")
equal(trough.initCount, 1, "definition initialised exactly once")
equal(trough.addedAtIndex, 3, "original object index preserved on the square")
equal(trough.overlayChecked, 1, "overlay refresh performed")
equal(trough.transmittedToClients, 1, "client sync performed")
equal(loadedThroughSystem, 1, "vanilla trough system re-entered")
equal(SFeedingTroughSystem.instance.removed, 0,
    "no stale lua object to remove on a fresh square")

-- The queue drains, so a second pump pass must be a no-op.
tickCallback()
equal(#transmitted, 1, "empty queue must not re-transmit")
equal(#troughInstances, 1, "empty queue must not re-create the trough")

-- --- north-facing registration routes isNorth=true ---------------------------

local northSquare, northObject =
    newSquareObject("location_farm_accesories_01_6")
registeredNew[3].callback(northObject)
equal(#transmitted, 1, "north callback must stay deferred")
tickCallback()
equal(#transmitted, 2, "north pump must transmit")
equal(troughInstances[2].north, true, "north handler sets isNorth=true")

-- --- a missing definition is initialised -------------------------------------

local freshSquare, freshObject =
    newSquareObject("location_farm_accesories_01_14")
registeredNew[2].callback(freshObject)
freshObject.getDef = nil
tickCallback()
equal(#transmitted, 3, "single-west pump must transmit")
equal(troughInstances[3].initCount, 1,
    "a trough without a definition must run initWithDef once")

-- --- an unloadable square is skipped without losing the object ---------------

local goneSquare, goneObject =
    newSquareObject("location_farm_accesories_01_34")
registeredNew[1].callback(goneObject)
goneObject.getSquare = function() return nil end
tickCallback()
equal(#transmitted, 3, "unloaded square must not transmit")
equal(goneSquare.addSpecialCount, 0, "unloaded square must not receive a trough")

print("psychopatz_feeding_trough_guard_smoke: ok")
