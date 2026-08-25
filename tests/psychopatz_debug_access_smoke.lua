local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

local engineDebug = false
isDebugEnabled = function() return engineDebug end
getCore = function()
    return { getDebug = function() return engineDebug end }
end

PsychopatzCore = {
    OWNER_STEAM_ID = "76561198137190990",
    OWNER_SP_NAME = "Psychopatz",
}
function PsychopatzCore.GetSafeSteamID(player)
    return tostring(player and player.steamID or "0")
end
function PsychopatzCore.IsOwner(player)
    return player and PsychopatzCore.GetSafeSteamID(player)
        == PsychopatzCore.OWNER_STEAM_ID
end

local Debug = require "PsychopatzCore/Debug/PsychopatzDebug"
local owner = {
    steamID = PsychopatzCore.OWNER_STEAM_ID,
    getAccessLevel = function() return "none" end,
    getUsername = function() return "Psychopatz" end,
}
local guest = {
    steamID = "76561198000000000",
    getAccessLevel = function() return "none" end,
    getUsername = function() return "Guest" end,
}
local admin = {
    steamID = guest.steamID,
    getAccessLevel = function() return "admin" end,
    getUsername = function() return "Admin" end,
}

Debug.localOverride = false
Debug.serverOverrides = {}
assert(not Debug.CanUse(owner), "disabled debug unexpectedly authorized owner")
assert(Debug.SetLocalOverride(true, owner), "owner override did not enable")
assert(Debug.CanUse(owner), "local owner override was not accepted")
assert(not Debug.CanUse(guest), "owner override leaked to another player")

Debug.localOverride = false
assert(Debug.CanUse(admin), "real multiplayer admin was rejected")
assert(Debug.SetServerOverride(owner, true), "server owner override did not enable")
assert(Debug.CanUse(owner), "server owner override was not accepted")
assert(not Debug.SetServerOverride(guest, true),
    "non-owner enabled the server override")

Debug.serverOverrides = {}
engineDebug = true
assert(Debug.CanUse(guest), "engine debug flag was rejected")

local opened = 0
PsychopatzCore.DebugHub = {
    Open = function() opened = opened + 1 end,
}
package.preload["PsychopatzCore/00_PsychopatzCore_Init"] = function()
    return PsychopatzCore
end
package.preload["PsychopatzCore/UI/PsychopatzDebugHubWindow"] = function()
    return PsychopatzCore.DebugHub
end
package.path = "Contents/mods/PsychopatzCore/42.19/media/lua/client/?.lua;"
    .. package.path

local contextHandler
Events = {
    OnFillWorldObjectContextMenu = {
        Add = function(handler) contextHandler = handler end,
    },
}
getText = function(key) return key end
local currentPlayer = guest
getSpecificPlayer = function() return currentPlayer end
local printed = {}
local oldPrint = print
print = function(message)
    printed[#printed + 1] = tostring(message)
end
local function newMenu()
    local menu = { options = {} }
    function menu:addOption(label, target, callback)
        local option = { name = label, target = target, callback = callback }
        self.options[#self.options + 1] = option
        return option
    end
    return menu
end
local square = {
    getX = function() return 101 end,
    getY = function() return 202 end,
    getZ = function() return 0 end,
}
local object = {
    getObjectName = function() return "IsoObject" end,
    getName = function() return nil end,
    getSpriteName = function() return "trash_01_22" end,
    getProperties = function()
        return {
            get = function(_, key)
                return key == "CustomName" and "Trash" or nil
            end,
        }
    end,
    getSquare = function() return square end,
}

require "PsychopatzCore/Debug/PsychopatzDebugContextMenu"
local menu = newMenu()
engineDebug = false
currentPlayer = guest
contextHandler(0, menu, {}, false)
assert(#menu.options == 0, "unauthorized context option was visible")

currentPlayer = admin
contextHandler(0, menu, { object }, false)
assert(#menu.options == 2, "admin context options were missing")
assert(menu.options[1].name == "[Debug] Grab Object Name",
    "object-name context option was missing")
assert(menu.options[2].name == "[Debug] Access Psychopatz Mod Controls",
    "context option label was incorrect")
menu.options[1].callback()
assert(#printed == 1, "object-name context option did not print")
assert(string.find(printed[1], "resolvedName=Trash", 1, true),
    "object-name context option did not resolve CustomName")
menu.options[2].callback()
assert(opened == 1, "admin context option did not open the debug hub")

currentPlayer = guest
engineDebug = true
contextHandler(0, menu, { object }, false)
assert(#menu.options == 4, "single-player debug context options were missing")
menu.options[4].callback()
assert(opened == 2, "single-player debug context option did not open the debug hub")

print = oldPrint
print("psychopatz_debug_access_smoke: ok")
