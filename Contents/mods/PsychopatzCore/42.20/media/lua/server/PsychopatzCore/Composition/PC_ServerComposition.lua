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

-- Early-loading vanilla compatibility guards.  These only register handlers, so
-- they must run at mod load time: MapObjects matches sprites before any game
-- event fires, and chunk loading starts long before OnGameStart.
require "PsychopatzCore/Compatibility/PsychopatzFeedingTroughGuard"

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
