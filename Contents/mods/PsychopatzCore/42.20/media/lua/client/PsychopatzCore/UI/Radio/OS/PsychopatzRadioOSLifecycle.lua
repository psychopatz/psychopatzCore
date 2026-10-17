-- Owns the bounded equipment-to-window lifecycle for immersive Radio OS.
-- Equip events open the window; the tick hook only reconciles removal and
-- stale state. It must never compete with the vanilla equip callback.

require "PsychopatzCore/Radio/PC_RadioDeviceState"

PsychopatzCore = PsychopatzCore or {}
local OS = PsychopatzCore.RadioOS
local RadioDeviceState = PsychopatzCore.RadioDeviceState

local Lifecycle = OS.Lifecycle or {}
OS.Lifecycle = Lifecycle

local CHECK_INTERVAL_MS = 200

local function diagnostics()
    return OS.Diagnostics
end

local function fullTypeOf(device)
    if not device then return nil end
    if type(device.getFullType) == "function" then
        local ok, value = pcall(device.getFullType, device)
        if ok and value ~= nil and tostring(value) ~= "" then
            return tostring(value)
        end
    end
    if device.fullType ~= nil and tostring(device.fullType) ~= "" then
        return tostring(device.fullType)
    end
    return nil
end

local function playerNumber(player)
    if player and type(player.getPlayerNum) == "function" then
        local ok, value = pcall(player.getPlayerNum, player)
        if ok then return tonumber(value) or 0 end
    end
    return 0
end

local function nowMs()
    if getTimeInMillis then return tonumber(getTimeInMillis()) or 0 end
    return nil
end

local function currentPlayer()
    if getSpecificPlayer then return getSpecificPlayer(0) end
    return nil
end

local function stateFor(playerNum)
    Lifecycle._states = Lifecycle._states or {}
    local key = tonumber(playerNum) or 0
    local state = Lifecycle._states[key]
    if not state then
        state = { playerNum = key }
        Lifecycle._states[key] = state
    end
    if key == 0 then Lifecycle._state = state end
    return state
end

function Lifecycle.GetState(playerNum)
    if playerNum ~= nil then
        return Lifecycle._states
            and Lifecycle._states[tonumber(playerNum) or 0]
    end
    return Lifecycle._states and Lifecycle._states[0] or Lifecycle._state
end

function Lifecycle.GetPlayerState(playerNum)
    return Lifecycle.GetState(playerNum)
end

function Lifecycle.HandleEquip(player, device, source)
    if not player or not device then return nil, "device_not_found" end
    local playerNum = playerNumber(player)
    local context = OS.GetDeviceContext(playerNum, device)
    if not context or context.canOpen ~= true then
        local activeDiagnostics = diagnostics()
        if activeDiagnostics and activeDiagnostics.RecordPresentation then
            activeDiagnostics.RecordPresentation("lifecycle.equip_rejected", {
                playerNum = playerNum,
                source = source or "equip",
                reason = context and context.reason or "device_unavailable",
            })
        end
        return nil, "device_unavailable"
    end

    local key = fullTypeOf(device)
    local state = stateFor(playerNum)
    local now = nowMs()
    if state.device == device and state.lastOpenAt and now
        and now - state.lastOpenAt < 120
    then
        local existing = OS.GetOpenWindow(playerNum)
        if existing and not existing._closed then return existing end
    end

    state.device = device
    state.key = key
    state.source = source or "equip"
    state.lastOpenAt = now

    local window = OS.Open(playerNum, device, {
        owner = "auto",
        source = source or "equip",
        immersive = true,
        animate = true,
    })
    if window then
        window.autoDevice = device
        window.autoDeviceKey = key
        window.openSource = source or "equip"
        state.window = window
        local activeDiagnostics = diagnostics()
        if activeDiagnostics and activeDiagnostics.RecordPresentation then
            activeDiagnostics.RecordPresentation("lifecycle.equip_opened", {
                playerNum = playerNum,
                fullType = key,
                source = source or "equip",
            })
        end
        return window
    end
    state.window = nil
    return nil, "radio_os_open_failed"
end

function Lifecycle.ReconcilePlayer(player)
    if not player then return false end
    local playerNum = playerNumber(player)
    local device = RadioDeviceState
        and RadioDeviceState.FindHandheldDevice(player) or nil
    local key = fullTypeOf(device)
    local state = stateFor(playerNum)
    if state.device == device and state.key == key then return false end

    local previousDevice = state.device
    state.device = device
    state.key = key
    state.playerNum = playerNum

    if previousDevice and not device then
        local previousWindow = OS.GetOpenWindow(playerNum)
        if previousWindow
            and (previousWindow.owner == "auto"
                or previousWindow.autoManaged == true)
            and previousWindow.putAway
        then
            previousWindow:putAway("unequipped", { animate = true })
        end
        state.window = nil
        local activeDiagnostics = diagnostics()
        if activeDiagnostics and activeDiagnostics.RecordPresentation then
            activeDiagnostics.RecordPresentation("lifecycle.unequipped", {
                playerNum = playerNum,
                previousFullType = fullTypeOf(previousDevice),
            })
        end
        return true
    end

    -- A missed equip event must not turn this reconciliation loop back into a
    -- second auto-opener. The vanilla event bridge owns opening.
    return true
end

function Lifecycle.OnTick()
    local now = nowMs()
    if now and Lifecycle._nextCheckAt and now < Lifecycle._nextCheckAt then
        return
    end
    if now then Lifecycle._nextCheckAt = now + CHECK_INTERVAL_MS end
    Lifecycle.ReconcilePlayer(currentPlayer())
end

if Events and Events.OnTick and not Lifecycle._tickHookRegistered then
    Events.OnTick.Add(Lifecycle.OnTick)
    Lifecycle._tickHookRegistered = true
end

return Lifecycle
