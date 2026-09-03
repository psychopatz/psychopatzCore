PsychopatzCore.ProfilerClient = PsychopatzCore.ProfilerClient or {}
local Client = PsychopatzCore.ProfilerClient

Client.started = Client.started or false
Client.captureActive = Client.captureActive or false
Client.commandListenerActive = Client.commandListenerActive or false

local function onServerCommand(module, command, args)
    if module ~= PsychopatzCore.COMMAND_MODULE or command ~= "ProfilerSnapshot" then return end
    Client.serverSnapshot = args and args.snapshot or nil
    Client.serverRunning = args and args.running == true or false
    Client.serverSnapshotAt = getTimeInMillis and getTimeInMillis() or 0
end

function Client.RequestServerSnapshot()
    if not Client.started or not isClient or not isClient() then return false end
    local player = getPlayer and getPlayer() or nil
    local debugAccess = PsychopatzCore.Debug
    if not player or not debugAccess or not debugAccess.CanUse
        or not debugAccess.CanUse(player) then return false end
    sendClientCommand(player, PsychopatzCore.COMMAND_MODULE, "ProfilerSnapshotRequest", {})
    return true
end

function Client.SetCaptureActive(enabled)
    enabled = enabled == true
    if enabled == Client.commandListenerActive then
        Client.captureActive = enabled
        return true
    end
    if enabled then
        if Events and Events.OnServerCommand then Events.OnServerCommand.Add(onServerCommand) end
        Client.commandListenerActive = true
    elseif Events and Events.OnServerCommand and Events.OnServerCommand.Remove then
        Events.OnServerCommand.Remove(onServerCommand)
        Client.commandListenerActive = false
    else
        Client.commandListenerActive = false
    end
    Client.captureActive = enabled
    if not enabled then Client.ClearServerSnapshot() end
    return true
end

function Client.ClearServerSnapshot()
    Client.serverSnapshot, Client.serverSnapshotAt = nil, nil
    Client.serverRunning = false
end

function Client.Start()
    if Client.started then return true end
    local Hub = require "PsychopatzCore/UI/PsychopatzDebugHubWindow"
    Hub.RegisterTool({
        id = "psychopatz.profiler",
        source = "PsychopatzCore",
        order = 100,
        title = getText("UI_PsychopatzProfiler_Title"),
        description = "Inspect metrics and configure the shared profiler capture runtime.",
        available = function()
            local player = getPlayer and getPlayer() or nil
            local debugAccess = PsychopatzCore.Debug
            return Client.started and debugAccess and debugAccess.CanUse
                and debugAccess.CanUse(player)
        end,
        action = function()
            local Window = require "PsychopatzCore/Profiler/PsychopatzProfilerWindow"
            Window.Open()
        end,
    })
    Client.started = true
    local Bootstrap = PsychopatzCore.ProfilerBootstrap
    if Bootstrap and Bootstrap.IsEnabled() then Client.SetCaptureActive(true) end
    return true
end

function Client.Stop()
    if not Client.started then return false end
    Client.SetCaptureActive(false)
    if PsychopatzCore.DebugHub then PsychopatzCore.DebugHub.UnregisterTool("psychopatz.profiler") end
    if PsychopatzCore.ProfilerWindow and PsychopatzCore.ProfilerWindow.Close then
        PsychopatzCore.ProfilerWindow.Close()
    end
    Client.started = false
    return true
end

return Client
