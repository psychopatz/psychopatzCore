-- Owns the boundary between vanilla radio UI entry points and Radio OS.
--
-- Equip/double-click is routed to Radio OS for supported portable devices.
-- Explicit Device Options continues through the original ISRadioWindow path.
-- Keeping those two routes distinct prevents the two windows from competing.

require "RadioCom/ISRadioWindow"
require "PsychopatzCore/Radio/PC_RadioDeviceState"

PsychopatzCore = PsychopatzCore or {}
local OS = PsychopatzCore.RadioOS
local RadioDeviceState = PsychopatzCore.RadioDeviceState

local Bridge = OS.VanillaBridge or {}
OS.VanillaBridge = Bridge

local function log(message)
    print("[PsychopatzCore][RadioOS] " .. tostring(message))
end

local function playerNumber(player)
    if player and type(player.getPlayerNum) == "function" then
        local ok, value = pcall(player.getPlayerNum, player)
        if ok then return tonumber(value) or 0 end
    end
    return 0
end

local function isPortableRadio(item)
    if not item or type(item.getDeviceData) ~= "function" then
        return false
    end
    local ok, data = pcall(item.getDeviceData, item)
    if not ok or not data or type(data.getIsPortable) ~= "function" then
        return false
    end
    local portable, value = pcall(data.getIsPortable, data)
    return portable and value == true
end

local function supportedDevice(player, item)
    if not isPortableRadio(item) or not OS
        or type(OS.GetDeviceContext) ~= "function"
    then
        return nil
    end
    local context = OS.GetDeviceContext(playerNumber(player), item)
    if not context or context.canOpen ~= true then return nil end
    return context
end

local function isLocalPlayer(player)
    -- Match ISRadioWindow.onEquip: its automatic surface belongs only to the
    -- local player.  Without this guard a multiplayer/split-screen equip
    -- event could create an extra Radio OS window for another player.
    if type(getPlayer) ~= "function" then return true end
    local ok, localPlayer = pcall(getPlayer)
    if not ok or not localPlayer then return false end
    return player == localPlayer
end

local function closeRadioOS(player, reason)
    if not OS or type(OS.GetOpenWindow) ~= "function" then return false end
    local window = OS.GetOpenWindow(playerNumber(player))
    if not window or window._closed or type(window.close) ~= "function" then
        return false
    end
    window:close(reason or "vanilla_device_options")
    return true
end

function Bridge.BeforeVanillaActivate(player, device)
    -- The native window remains authoritative for explicit Device Options.
    -- Closing the custom surface first guarantees that only one radio UI can
    -- own input and that a hosted vanilla window can be restored correctly.
    return closeRadioOS(player, "vanilla_device_options")
end

function Bridge.OpenFromEquip(player, item, source)
    local context = supportedDevice(player, item)
    if not context then return nil, "not_a_supported_portable_radio" end

    if ISRadioWindow and ISRadioWindow.closeIfActive then
        pcall(ISRadioWindow.closeIfActive, player, item)
    end

    local Lifecycle = OS and OS.Lifecycle
    if Lifecycle and type(Lifecycle.HandleEquip) == "function" then
        local window, reason = Lifecycle.HandleEquip(player, item,
            source or "equip")
        if window then return window end
        return nil, reason
    end

    if not OS or type(OS.Open) ~= "function" then
        return nil, "radio_os_unavailable"
    end
    return OS.Open(playerNumber(player), item, {
        owner = "auto",
        source = source or "equip",
        immersive = true,
        animate = true,
    })
end

function Bridge.OnEquip(player, item)
    if Bridge._delegating then return false end
    if not isLocalPlayer(player) then return false end
    local opened, reason = Bridge.OpenFromEquip(player, item, "equip")
    if opened then return true end

    -- Unsupported radios retain the base game's behavior.  This also keeps
    -- the bridge safe when another mod supplies a non-portable Radio item.
    if type(Bridge._originalOnEquip) == "function" then
        Bridge._delegating = true
        local ok, result = pcall(Bridge._originalOnEquip, player, item)
        Bridge._delegating = false
        if not ok then
            log("vanilla equip fallback failed: " .. tostring(result))
        else
            return result
        end
    end
    if reason and reason ~= "not_a_supported_portable_radio" then
        log("equip route unavailable: " .. tostring(reason))
    end
    local diagnostics = OS and OS.Diagnostics
    if diagnostics and diagnostics.RecordPresentation then
        diagnostics.RecordPresentation("bridge.equip_fallback", {
            playerNum = playerNumber(player),
            reason = reason or "unsupported",
        })
    end
    return false
end

local function removeEventCallback(event, callback)
    if not event or type(event.Remove) ~= "function" then return false end
    local ok = pcall(event.Remove, callback)
    return ok
end

local function addEventCallback(event, callback)
    if not event or type(event.Add) ~= "function" then return false end
    local ok = pcall(event.Add, callback)
    return ok
end

function Bridge.Install()
    if Bridge._installed then return true end
    if not ISRadioWindow then
        Bridge._installReason = "vanilla_radio_window_unavailable"
        return false
    end

    local originalOnEquip = ISRadioWindow.onEquip
    local originalActivate = ISRadioWindow.activate
    local primary = Events and Events.OnEquipPrimary or nil
    local secondary = Events and Events.OnEquipSecondary or nil
    if type(originalOnEquip) ~= "function"
        or type(originalActivate) ~= "function"
        or not primary or not secondary
    then
        Bridge._installReason = "vanilla_radio_events_unavailable"
        return false
    end

    -- Remove the exact callback that vanilla registered.  The native event
    -- API supports Remove; if either event cannot be changed, restore the
    -- first removal and fail closed instead of creating a duplicate opener.
    local removedPrimary = removeEventCallback(primary, originalOnEquip)
    local removedSecondary = removeEventCallback(secondary, originalOnEquip)
    if not removedPrimary or not removedSecondary then
        if removedPrimary then addEventCallback(primary, originalOnEquip) end
        if removedSecondary then addEventCallback(secondary, originalOnEquip) end
        Bridge._installReason = "vanilla_equip_callback_not_removable"
        return false
    end

    Bridge._originalOnEquip = originalOnEquip
    Bridge._originalActivate = originalActivate
    ISRadioWindow.onEquip = Bridge.OnEquip

    if not addEventCallback(primary, Bridge.OnEquip)
        or not addEventCallback(secondary, Bridge.OnEquip)
    then
        removeEventCallback(primary, Bridge.OnEquip)
        removeEventCallback(secondary, Bridge.OnEquip)
        addEventCallback(primary, originalOnEquip)
        addEventCallback(secondary, originalOnEquip)
        ISRadioWindow.onEquip = originalOnEquip
        Bridge._originalOnEquip = nil
        Bridge._originalActivate = nil
        Bridge._installReason = "custom_equip_callback_unavailable"
        return false
    end

    -- Device Options still calls the real vanilla implementation.  This
    -- wrapper only arbitrates ownership so the custom panel is not left
    -- stacked behind the native panel.
    if not ISRadioWindow.psychopatzCoreActivateBridge then
        ISRadioWindow.activate = function(player, device, ...)
            Bridge.BeforeVanillaActivate(player, device)
            return originalActivate(player, device, ...)
        end
        ISRadioWindow.psychopatzCoreActivateBridge = true
    end

    Bridge._installed = true
    Bridge._installReason = nil
    log("vanilla radio bridge installed")
    local diagnostics = OS and OS.Diagnostics
    if diagnostics and diagnostics.RecordPresentation then
        diagnostics.RecordPresentation("bridge.installed", {
            primary = true,
            secondary = true,
            nativeActivateWrapped = true,
        })
    end
    return true
end

if Events and ISRadioWindow then
    Bridge.Install()
end

return Bridge
