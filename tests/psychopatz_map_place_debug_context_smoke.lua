local SHARED = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
package.path = SHARED .. "?.lua;" .. CLIENT .. "?.lua;" .. package.path

local authorized = true
local baseAllowsMapContext = true
local printed = {}
local contexts = {}
local squareCalls = 0
local oldPrint = print

PsychopatzCore = {
    Debug = {
        CanUse = function() return authorized end,
    },
    Translation = {
        GetKey = function(_, fallback) return fallback end,
    },
}
package.preload["PsychopatzCore/00_PsychopatzCore_Init"] = function()
    return PsychopatzCore
end

print = function(message)
    printed[#printed + 1] = tostring(message)
end

local function newMenu()
    local menu = { options = {} }
    function menu:addOption(name, target, callback)
        local option = {
            name = name,
            target = target,
            callback = callback,
        }
        self.options[#self.options + 1] = option
        return option
    end
    return menu
end

ISContextMenu = {
    get = function(playerNum, x, y)
        local context = newMenu()
        context.playerNum = playerNum
        context.x = x
        context.y = y
        contexts[#contexts + 1] = context
        return context
    end,
}
package.preload["ISUI/ISContextMenu"] = function()
    return ISContextMenu
end

local townZone = {
    getName = function() return "Muldraugh" end,
    getOriginalName = function() return "Muldraugh" end,
    getType = function() return "TownZone" end,
    getZ = function() return 0 end,
    getWidth = function() return 100 end,
    getHeight = function() return 100 end,
}
local moddedZone = {
    getName = function() return "Custom Valley" end,
    getType = function() return "ModdedRegion" end,
}
local zombiesZone = {
    getName = function() return "Office" end,
    getOriginalName = function() return "Office" end,
    getType = function() return "ZombiesType" end,
    getZ = function() return 0 end,
    getWidth = function() return 12 end,
    getHeight = function() return 9 end,
}
local foragingZone = {
    getName = function() return "Forest Forage" end,
    getType = function() return "ForagingNav" end,
    getZ = function() return 0 end,
    getWidth = function() return 50 end,
    getHeight = function() return 50 end,
}
local roomDef = {
    getName = function() return "warehouse" end,
}
local metaGrid = {
    getZonesAt = function()
        return {
            size = function() return 4 end,
            get = function(_, index)
                if index == 0 then return townZone end
                if index == 1 then return moddedZone end
                if index == 2 then return zombiesZone end
                return foragingZone
            end,
        }
    end,
    getRoomAt = function() return roomDef end,
}
getWorld = function()
    return { getMetaGrid = function() return metaGrid end }
end
getZone = function() return townZone end
getSquare = function()
    squareCalls = squareCalls + 1
    return nil
end

local player = {
    getZ = function() return 2 end,
}
getSpecificPlayer = function() return player end

ISWorldMap = {
    onRightMouseUp = function(self, x, y)
        if not baseAllowsMapContext then
            return false
        end
        local context = ISContextMenu.get(
            self.playerNum,
            x + self:getAbsoluteX(),
            y + self:getAbsoluteY()
        )
        context:addOption("Vanilla Map Option", self, function() end)
        return true
    end,
}
package.preload["ISUI/Maps/ISWorldMap"] = function()
    return ISWorldMap
end

local MapContext = require
    "PsychopatzCore/Debug/PsychopatzPlaceDebugMapContext"
assert(MapContext.Installed, "map place context was not installed")

local map = {
    playerNum = 0,
    mapAPI = {
        uiToWorldX = function(_, x) return x + 500.75 end,
        uiToWorldY = function(_, _, y) return y + 600.25 end,
    },
    getAbsoluteX = function() return 100 end,
    getAbsoluteY = function() return 200 end,
}
setmetatable(map, { __index = ISWorldMap })

local firstResult = map:onRightMouseUp(10, 20)
assert(firstResult == true, "map right click did not preserve the vanilla result")
assert(#contexts == 1, "vanilla map context was not captured")
assert(#contexts[1].options == 3,
    "map debug options were not appended to the vanilla context")
assert(contexts[1].options[1].name == "Vanilla Map Option",
    "vanilla map option was not preserved")
assert(contexts[1].options[2].name == "[Debug] Inspect Map Place",
    "map place option label was incorrect")
assert(contexts[1].options[3].name == "[Debug] Inspect Zombie Population",
    "map zombie population option label was incorrect")
contexts[1].options[2].callback()
assert(#printed == 1, "map place option did not print a record")
assert(string.find(printed[1], "source=map", 1, true),
    "map inspection did not identify its source")
assert(string.find(printed[1], "coords=510,620,2", 1, true),
    "map world coordinates were not converted or normalized")
assert(string.find(printed[1], "town=Muldraugh", 1, true),
    "map TownZone name was missing")
assert(string.find(printed[1], "zones=Muldraugh:TownZone,Custom Valley:ModdedRegion,Office:ZombiesType,Forest Forage:ForagingNav",
    1, true), "map metadata zones were missing")
assert(string.find(printed[1], "type=ZombiesType", 1, true),
    "map ZombiesType metadata was missing")
assert(string.find(printed[1], "type=ForagingNav", 1, true),
    "map ForagingNav metadata was missing")
assert(string.find(printed[1], "room=warehouse", 1, true),
    "map metadata room was missing")
contexts[1].options[3].callback()
assert(#printed == 2, "map zombie population option did not print a record")
assert(string.find(printed[2], "Inspect Zombie Population", 1, true),
    "map zombie population output label was missing")
assert(string.find(printed[2], "source=map", 1, true),
    "map zombie population output source was missing")
assert(squareCalls == 0, "map inspection required a loaded square")

authorized = false
contexts[1].options[2].callback()
assert(#printed == 2, "stale map option bypassed debug access")

authorized = true
baseAllowsMapContext = false
local fallbackResult = map:onRightMouseUp(30, 40)
assert(fallbackResult == true,
    "Core debug access did not create a map context when vanilla declined")
assert(#contexts == 2 and #contexts[2].options == 2,
    "fallback map context did not contain the debug option")

print = oldPrint
print("psychopatz_map_place_debug_context_smoke: ok")
