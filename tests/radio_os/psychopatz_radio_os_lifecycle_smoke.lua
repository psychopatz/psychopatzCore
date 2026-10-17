local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
local COMMON = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = CLIENT .. "?.lua;" .. COMMON .. "?.lua;" .. package.path

PsychopatzCore = {}
dofile(COMMON .. "PsychopatzCore/Radio/PC_RadioDeviceState.lua")

local radio = {
    fullType = "Base.WalkieTalkie5",
    getFullType = function(self) return self.fullType end,
    getIsPortable = function() return true end,
    getIsTwoWay = function() return true end,
}
local attached = {
    getItem = function() return radio end,
    size = function() return 1 end,
    get = function() return attached end,
}
local player = {
    getPlayerNum = function() return 0 end,
    getPrimaryHandItem = function(self) return self.primary end,
    getSecondaryHandItem = function(self) return self.secondary end,
    getAttachedItems = function() return attached end,
    primary = radio,
}
getSpecificPlayer = function() return player end
local ticks = 0
getTimeInMillis = function() ticks = ticks + 250; return ticks end

local window = {
    owner = "auto",
    putAway = function(self, reason) self.putAwayReason = reason end,
}
local opened
local OS = {
    GetOpenWindow = function() return window end,
    GetDeviceContext = function(_, device)
        return { canOpen = device == radio }
    end,
    Open = function(_, device, options)
        opened = { device = device, options = options }
        return window
    end,
}
PsychopatzCore.RadioOS = OS

local Lifecycle = dofile(CLIENT
    .. "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSLifecycle.lua")
local openedWindow = assert(Lifecycle.HandleEquip(player, radio, "equip"))
assert(opened and opened.device == radio,
    "handheld radio opens the immersive OS")
assert(opened.options.owner == "auto" and opened.options.animate == true,
    "auto lifecycle owns and animates the opening")

player.primary = nil
Lifecycle.OnTick()
assert(window.putAwayReason == "unequipped",
    "removing a handheld radio puts the automatic window away")

player.getAttachedItems = function() return attached end
assert(PsychopatzCore.RadioDeviceState.FindHandheldDevice(player) == nil,
    "attached radios do not trigger immersive auto-popup")

print("psychopatz_radio_os_lifecycle_smoke: ok")
