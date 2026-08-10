PsychopatzCore.ProfilerClient = PsychopatzCore.ProfilerClient or {}
local Client = PsychopatzCore.ProfilerClient

local function onServerCommand(module, command, args)
    if module ~= PsychopatzCore.COMMAND_MODULE or command ~= "ProfilerSnapshot" then return end
    Client.serverSnapshot = args and args.snapshot or nil
    Client.serverRunning = args and args.running == true or false
    Client.serverSnapshotAt = getTimeInMillis and getTimeInMillis() or 0
end

function Client.RequestServerSnapshot()
    if not Client.started or not isClient or not isClient() then return false end
    local player = getPlayer and getPlayer() or nil
    if not player or not PsychopatzCore.IsOwner(player) then return false end
    sendClientCommand(player, PsychopatzCore.COMMAND_MODULE, "ProfilerSnapshotRequest", {})
    return true
end

function Client.Start()
    if Client.started then return false end
    if Events and Events.OnServerCommand then Events.OnServerCommand.Add(onServerCommand) end
    local Hub = require "PsychopatzCore/UI/PsychopatzDebugHubWindow"
    Hub.RegisterTool({
        id = "psychopatz.profiler",
        source = "PsychopatzCore",
        order = 100,
        title = getText("UI_PsychopatzProfiler_Title"),
        description = "Inspect generic CPU, rate, growth, and namespace metrics.",
        available = function()
            local player = getPlayer and getPlayer() or nil
            return PsychopatzCore.Profiler and PsychopatzCore.Profiler.IsRunning()
                and PsychopatzCore.IsOwner(player)
        end,
        action = function()
            local Window = require "PsychopatzCore/Profiler/PsychopatzProfilerWindow"
            Window.Open()
        end,
    })
    Client.started = true
    return true
end

function Client.Stop()
    if not Client.started then return false end
    if Events and Events.OnServerCommand and Events.OnServerCommand.Remove then
        Events.OnServerCommand.Remove(onServerCommand)
    end
    if PsychopatzCore.DebugHub then PsychopatzCore.DebugHub.UnregisterTool("psychopatz.profiler") end
    if PsychopatzCore.ProfilerWindow and PsychopatzCore.ProfilerWindow.Close then
        PsychopatzCore.ProfilerWindow.Close()
    end
    Client.serverSnapshot, Client.serverSnapshotAt = nil, nil
    Client.started = false
    return true
end

return Client
