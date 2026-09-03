PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Composition = PsychopatzCore.Composition or {}

local Composition = PsychopatzCore.Composition.Server or {}
PsychopatzCore.Composition.Server = Composition

if Composition.profilerRoleRegistered then
    return Composition
end

local RuntimeRole = PsychopatzCore.RuntimeRole
local isServer = RuntimeRole
    and RuntimeRole.IsServer
    and RuntimeRole.IsServer()

if not isServer then
    return Composition
end

local Bootstrap = require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"

local function startProfilerServer()
    local Server = require "PsychopatzCore/Profiler/PsychopatzProfilerServer"
    if Server.started then
        return true
    end
    return Server.Start()
end

local registered, reason = Bootstrap.RegisterRoleStarter(
    "server",
    startProfilerServer
)
Composition.profilerRoleRegistered = registered
Composition.profilerRoleReason = reason

return Composition
