-- Core Radio OS composition root. This is the only module that wires the
-- neutral registry/model to the physical window and Core's existing vanilla
-- radio action host.

local OS = require "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSRegistry"
local Text = require "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSTranslation"

-- Register the opt-in diagnostic switches before lifecycle/window modules are
-- loaded so every later path can emit evidence without inventing a second
-- debug configuration system.
local diagnosticsLoaded, diagnosticsReason = pcall(require,
    "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSDiagnostics")
if not diagnosticsLoaded then
    print("[PsychopatzCore][RadioOS] diagnostics unavailable: "
        .. tostring(diagnosticsReason))
else
    print("[PsychopatzCore][RadioOS] diagnostics registered: "
        .. tostring(OS.Diagnostics ~= nil))
end

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
    RadioActions.Register({
        id = "psychopatzcore:radio_os",
        label = T("UI_PsychopatzCore_Radio_Open", "Radio OS"),
        signalLabel = T("UI_PsychopatzCore_Radio_Open", "Radio OS"),
        placement = RadioActions.PLACEMENT_SIGNAL
            or "psychopatz.radio.signal",
        order = 5,
        requiresOperational = false,
        isAvailable = function(player, window)
            local playerNum = player and player.getPlayerNum
                and tonumber(player:getPlayerNum())
                or tonumber(window and window.playerNum) or 0
            local device = window and (window.device or window.deviceData)
            local context = OS.GetDeviceContext(playerNum, device)
            return context ~= nil and context.canOpen == true
        end,
        onClick = function(player, window)
            local playerNum = player and player.getPlayerNum
                and tonumber(player:getPlayerNum())
                or tonumber(window and window.playerNum) or 0
            local device = window and (window.device or window.deviceData)
            local opened = OS.Open(playerNum, device, {
                owner = "PsychopatzCore",
                hostWindow = window,
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

-- The editor depends on ISUI and the lifecycle depends on client Events.
-- Keep the registry/action path usable in offline harnesses that intentionally
-- omit those engine surfaces; the native client loads both modules.
local editorLoaded, editorReason = pcall(require,
    "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSLayoutEditor")
if not editorLoaded then
    print("[PsychopatzCore][RadioOS] layout editor unavailable: "
        .. tostring(editorReason))
end
local lifecycleLoaded, lifecycleReason = pcall(require,
    "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSLifecycle")
if not lifecycleLoaded then
    print("[PsychopatzCore][RadioOS] equipment lifecycle unavailable: "
        .. tostring(lifecycleReason))
end

-- Install after ISRadioWindow and the lifecycle coordinator are available.
-- The bridge removes only vanilla's automatic equip opener; explicit Device
-- Options remains delegated to the native window.
local bridgeLoaded, bridgeReason = pcall(require,
    "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSVanillaBridge")
if not bridgeLoaded then
    print("[PsychopatzCore][RadioOS] vanilla bridge unavailable: "
        .. tostring(bridgeReason))
end

return OS
