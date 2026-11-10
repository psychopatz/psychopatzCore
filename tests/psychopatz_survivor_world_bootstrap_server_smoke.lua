local VERSIONED_SERVER =
    "Contents/mods/PsychopatzCore/42.20/media/lua/server/"
local VERSIONED_SHARED =
    "Contents/mods/PsychopatzCore/42.20/media/lua/shared/"
local COMMON_SHARED =
    "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = VERSIONED_SERVER .. "?.lua;"
    .. VERSIONED_SHARED .. "?.lua;"
    .. COMMON_SHARED .. "?.lua;"
    .. package.path

isClient = function() return false end
isServer = function() return false end

local roots = {}
ModData = {
    getOrCreate = function(key)
        roots[key] = roots[key] or {}
        return roots[key]
    end,
    get = function(key) return roots[key] end,
}

local callbacks = {}
local function event(name)
    return {
        Add = function(callback) callbacks[name] = callback end,
    }
end
Events = {
    OnInitGlobalModData = event("init"),
    OnSave = event("save"),
    OnServerStarted = event("server_started"),
    OnCreatePlayer = event("create_player"),
}

local player = {
    getX = function() return 100 end,
    getY = function() return 200 end,
    getZ = function() return 0 end,
}
getSpecificPlayer = function() return player end
getGameTime = function()
    return { getWorldAgeHours = function() return 4 end }
end

local Server = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldBootstrapServer"
assert(Server.EnsureRuntime, "Core bootstrap server API missing")
assert(callbacks.server_started, "OnServerStarted hook missing")
assert(callbacks.create_player, "OnCreatePlayer hook missing")

local registry, reason = Server.EnsureRuntime()
assert(registry, reason)
assert(reason == "bootstrapped" or reason == "existing", reason)
local counts = registry:Counts()
assert(counts.communities > 0, "Core bootstrap created no communities")
assert(counts.groups > 0, "Core bootstrap created no groups")
assert(Server.LastStatus and Server.LastStatus.active == true,
    "Core bootstrap status was not recorded")

local sameRegistry = Server.EnsureRuntime()
assert(sameRegistry == registry,
    "repeated Core bootstrap replaced the runtime registry")

print("psychopatz_survivor_world_bootstrap_server_smoke: PASS")
