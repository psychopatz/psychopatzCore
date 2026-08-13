PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Composition = PsychopatzCore.Composition or {}

local Composition = PsychopatzCore.Composition.Client or {}
PsychopatzCore.Composition.Client = Composition

if Composition.profilerRoleRegistered then
    return Composition
end

local RuntimeRole = PsychopatzCore.RuntimeRole
local allowsClient = RuntimeRole
    and RuntimeRole.AllowsClientCode
    and RuntimeRole.AllowsClientCode()

if not allowsClient then
    return Composition
end

local Bootstrap = require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"

local function startProfilerClient()
    local Client = require "PsychopatzCore/Profiler/PsychopatzProfilerClient"
    if Client.started then
        return true
    end
    return Client.Start()
end

local registered, reason = Bootstrap.RegisterRoleStarter(
    "client",
    startProfilerClient
)
Composition.profilerRoleRegistered = registered
Composition.profilerRoleReason = reason

return Composition
