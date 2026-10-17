local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
local COMMON_CLIENT = "Contents/mods/PsychopatzCore/common/media/lua/client/"
local COMMON = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = CLIENT .. "?.lua;" .. COMMON_CLIENT .. "?.lua;"
    .. COMMON .. "?.lua;" .. package.path

getModFileReader = function(_, filename, _)
    local handle = assert(io.open("Contents/mods/PsychopatzCore/common/"
        .. filename, "r"))
    return {
        readLine = function() return handle:read("*l") end,
        close = function() handle:close() end,
    }
end

package.preload["ISUI/ISButton"] = function() return true end
package.preload["ISUI/ISContextMenu"] = function() return true end
package.preload["RadioCom/ISRadioWindow"] = function() return true end

PsychopatzCore = {}
dofile(COMMON .. "PsychopatzCore/Radio/PC_RadioDeviceState.lua")
local player = { getPlayerNum = function() return 0 end }
getSpecificPlayer = function() return player end

local device = {
    fullType = "Base.WalkieTalkie5",
    getFullType = function(self) return self.fullType end,
    getIsPortable = function() return true end,
    getIsTwoWay = function() return true end,
    getIsTelevision = function() return false end,
    getIsTurnedOn = function() return true end,
    getPower = function() return 1 end,
    getDeviceVolume = function() return 1 end,
    getMicIsMuted = function() return false end,
}

local OS = dofile(CLIENT
    .. "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOS.lua")
local Actions = PsychopatzCore.RadioActions
local radio = { playerNum = 0, deviceData = device }
local available = Actions.GetAvailableForPlacement(
    radio, Actions.PLACEMENT_SIGNAL)
local action
for _, candidate in ipairs(available) do
    if candidate.id == "psychopatzcore:radio_os" then
        action = candidate
        break
    end
end
assert(action, "Core Radio OS action is registered")

local opened = false
local originalOpen = OS.Open
OS.Open = function(playerNum, selectedDevice, options)
    assert(playerNum == 0 and selectedDevice == device)
    assert(options.owner == "PsychopatzCore")
    opened = true
    return {}
end
assert(action.onClick(player, radio, action) == true)
assert(opened)
OS.Open = originalOpen

-- Stationary Ham radios are valid two-way Radio OS devices even though the
-- vanilla item definition deliberately reports IsPortable=false.
local hamDevice = {
    fullType = "Base.HamRadio1",
    getFullType = function(self) return self.fullType end,
    getIsPortable = function() return false end,
    getIsTwoWay = function() return true end,
    getIsTelevision = function() return false end,
    getIsTurnedOn = function() return true end,
    getPower = function() return 1 end,
    getDeviceVolume = function() return 1 end,
    getMicIsMuted = function() return false end,
}
local hamRadio = { playerNum = 0, deviceData = hamDevice }
local hamAvailable = Actions.GetAvailableForPlacement(
    hamRadio, Actions.PLACEMENT_SIGNAL)
local hamAction
for _, candidate in ipairs(hamAvailable) do
    if candidate.id == "psychopatzcore:radio_os" then
        hamAction = candidate
        break
    end
end
assert(hamAction, "stationary Ham radio exposes the Core Radio OS action")

-- A placed IsoWaveSignal has no InventoryItem:getFullType(); its sprite's
-- CustomItem is the engine-owned source identity used by the Java constructor.
local properties = {
    get = function(_, key)
        return key == "CustomItem" and "Base.HamRadio1" or nil
    end,
}
local sprite = { getProperties = function() return properties end }
local placedRadio = {
    getDeviceData = function() return hamDevice end,
    getSprite = function() return sprite end,
}
local placedContext = OS.GetDeviceContext(0, placedRadio)
assert(placedContext and placedContext.fullType == "Base.HamRadio1",
    "placed Ham radio resolves its CustomItem identity")

print("psychopatz_radio_os_action_smoke: ok")
