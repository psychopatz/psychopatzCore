local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
local COMMON = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = CLIENT .. "?.lua;" .. COMMON .. "?.lua;" .. package.path

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

print("psychopatz_radio_os_action_smoke: ok")
