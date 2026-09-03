PsychopatzCore.ProfilerServer = PsychopatzCore.ProfilerServer or {}
local Server = PsychopatzCore.ProfilerServer

local function onClientCommand(module, command, player)
    if module ~= PsychopatzCore.COMMAND_MODULE or command ~= "ProfilerSnapshotRequest" then return end
    local debugAccess = PsychopatzCore.Debug
    if not debugAccess or not debugAccess.CanUse or not debugAccess.CanUse(player) then return end
    local profiler = PsychopatzCore.Profiler
    local snapshot = profiler and profiler.IsRunning and profiler.IsRunning()
        and profiler.BuildSnapshot() or nil
    sendServerCommand(player, PsychopatzCore.COMMAND_MODULE, "ProfilerSnapshot", {
        running = snapshot ~= nil,
        snapshot = snapshot,
    })
end

function Server.Start()
    if Server.started then return false end
    if Events and Events.OnClientCommand then
        Events.OnClientCommand.Add(onClientCommand)
        Server.started = true
    end
    return Server.started == true
end

function Server.Stop()
    if not Server.started then return false end
    if Events and Events.OnClientCommand and Events.OnClientCommand.Remove then
        Events.OnClientCommand.Remove(onClientCommand)
    end
    Server.started = false
    return true
end

return Server
