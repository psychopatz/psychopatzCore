local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
local COMMON = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = CLIENT .. "?.lua;" .. COMMON .. "?.lua;" .. package.path

package.preload["RadioCom/ISRadioWindow"] = function() return true end

local function event()
    local value = { callbacks = {} }
    function value.Add(callback)
        value.callbacks[#value.callbacks + 1] = callback
    end
    function value.Remove(callback)
        for index = #value.callbacks, 1, -1 do
            if value.callbacks[index] == callback then
                table.remove(value.callbacks, index)
            end
        end
    end
    return value
end

local primary = event()
local secondary = event()
Events = { OnEquipPrimary = primary, OnEquipSecondary = secondary }

local vanillaEquipCalls = 0
local nativeActivateCalls = 0
local nativeCloseCalls = 0
local opened
local nativeWindow = { visible = true }
local player = { getPlayerNum = function() return 0 end }
local data = {
    getIsPortable = function() return true end,
}
local device = {
    getDeviceData = function() return data end,
}
local unsupported = {
    getDeviceData = function()
        return { getIsPortable = function() return false end }
    end,
}

ISRadioWindow = {
    onEquip = function()
        vanillaEquipCalls = vanillaEquipCalls + 1
    end,
    activate = function()
        nativeActivateCalls = nativeActivateCalls + 1
    end,
    closeIfActive = function() nativeCloseCalls = nativeCloseCalls + 1 end,
}

local lifecycle = {
    HandleEquip = function(selectedPlayer, selectedDevice, source)
        opened = {
            player = selectedPlayer,
            device = selectedDevice,
            source = source,
        }
        return nativeWindow
    end,
}

PsychopatzCore = {
    RadioOS = {
        Lifecycle = lifecycle,
        GetDeviceContext = function(_, selectedDevice)
            return selectedDevice == device and { canOpen = true } or nil
        end,
        GetOpenWindow = function() return nativeWindow end,
    },
    RadioDeviceState = {},
}
function nativeWindow:close(reason)
    self.closeReason = reason
    self.visible = false
end

local bridge = dofile(CLIENT
    .. "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSVanillaBridge.lua")
assert(bridge._installed, "vanilla bridge installs")
assert(#primary.callbacks == 1 and #secondary.callbacks == 1,
    "vanilla equip callbacks are replaced exactly once")

primary.callbacks[1](player, device)
assert(opened and opened.device == device and opened.source == "equip",
    "supported equip routes to Radio OS")
assert(vanillaEquipCalls == 0, "supported equip bypasses vanilla auto-open")
assert(nativeCloseCalls == 1, "native window is closed before Radio OS opens")

ISRadioWindow.activate(player, device)
assert(nativeActivateCalls == 1, "native activation still delegates")
assert(nativeWindow.closeReason == "vanilla_device_options",
    "native Device Options arbitrates the custom surface")

primary.callbacks[1](player, unsupported)
assert(vanillaEquipCalls == 1, "unsupported radios retain vanilla behavior")

print("psychopatz_radio_os_vanilla_bridge_smoke: ok")
