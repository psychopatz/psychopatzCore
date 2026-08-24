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
local Client = require "PsychopatzCore/Profiler/PsychopatzProfilerClient"

-- Keep only the small debug-gated tool registration alive while profiling is
-- OFF.  The profiler backend and its sampling callbacks remain unloaded until
-- the runtime is enabled.
Client.Start()

local function startProfilerClient()
    if Client.started then
        Client.SetCaptureActive(true)
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
