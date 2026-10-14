-- Core Radio OS composition root. This is the only module that wires the
-- neutral registry/model to the physical window and Core's existing vanilla
-- radio action host.

local OS = require "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSRegistry"
local Text = require "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSTranslation"

local function T(key, fallback)
    return Text.Get(key, fallback)
end

-- Keep the existing vanilla radio integration as the single host. Failure to
-- load it in an offline harness must not make the reusable registry unusable.
local actionsLoaded, RadioActions = pcall(require,
    "PsychopatzCore/UI/Radio/PsychopatzRadioActions")
pcall(require, "PsychopatzCore/UI/Radio/PsychopatzRadioSignalHost")

if actionsLoaded and RadioActions and RadioActions.Register
    and not OS._coreRadioActionLoaded
then
    local RadioDeviceState = PsychopatzCore.RadioDeviceState
    RadioActions.Register({
        id = "psychopatzcore:radio_os",
        label = T("UI_PsychopatzCore_Radio_Open", "Radio OS"),
        signalLabel = T("UI_PsychopatzCore_Radio_Open", "Radio OS"),
        placement = RadioActions.PLACEMENT_SIGNAL
            or "psychopatz.radio.signal",
        order = 5,
        isAvailable = function(_, window)
            local data = window and window.deviceData
            if not data or not RadioDeviceState then return false end
            return RadioDeviceState.IsActive(data) == true
        end,
        onClick = function(player, window)
            local playerNum = player and player.getPlayerNum
                and tonumber(player:getPlayerNum())
                or tonumber(window and window.playerNum) or 0
            local device = window and (window.device or window.deviceData)
            local opened = OS.Open(playerNum, device, {
                owner = "PsychopatzCore",
            })
            return opened ~= nil
        end,
    })
    OS._coreRadioActionLoaded = true
end

if not OS._coreAppsLoaded then
    OS.RegisterApp({
        id = "psychopatzcore:contacts",
        ownerModID = "PsychopatzCore",
        label = T("UI_PsychopatzCore_Radio_Contacts", "Contacts"),
        icon = "icon_contacts",
        order = 20,
        page = "contacts",
    })
    OS.RegisterApp({
        id = "psychopatzcore:settings",
        ownerModID = "PsychopatzCore",
        label = T("UI_PsychopatzCore_Radio_Settings", "Settings"),
        icon = "icon_settings",
        order = 90,
        page = "settings",
    })
    OS._coreAppsLoaded = true
end

return OS
