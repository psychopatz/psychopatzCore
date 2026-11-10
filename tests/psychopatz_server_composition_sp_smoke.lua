local SERVER = "Contents/mods/PsychopatzCore/42.20/media/lua/server/"

local loaded = {
    feeding = 0,
    projection = 0,
    discovery = 0,
    bootstrap = 0,
}

package.preload[
    "PsychopatzCore/Compatibility/PsychopatzFeedingTroughGuard"
] = function()
    loaded.feeding = loaded.feeding + 1
    return {}
end
package.preload[
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldProjectionServer"
] = function()
    loaded.projection = loaded.projection + 1
    return {}
end
package.preload[
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldDiscoveryServer"
] = function()
    loaded.discovery = loaded.discovery + 1
    return {}
end
package.preload[
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldBootstrapServer"
] = function()
    loaded.bootstrap = loaded.bootstrap + 1
    return {}
end

PsychopatzCore = {
    RuntimeRole = {
        IsServer = function() return false end,
        IsClient = function() return false end,
        IsSinglePlayer = function() return true end,
        AllowsServerCode = function() return true end,
    },
    Composition = {},
}

local composition = assert(dofile(
    SERVER .. "PsychopatzCore/Composition/PC_ServerComposition.lua"
))
assert(composition.serverLoaded == true,
    "single-player authority did not load server composition")
assert(loaded.feeding == 1,
    "single-player authority skipped server compatibility guard")
assert(loaded.projection == 1,
    "single-player authority skipped SurvivorWorld projection server")
assert(loaded.discovery == 1,
    "single-player authority skipped SurvivorWorld discovery server")
assert(loaded.bootstrap == 1,
    "single-player authority skipped SurvivorWorld bootstrap server")

-- A pure client must still refuse server composition.
PsychopatzCore.Composition = {}
PsychopatzCore.RuntimeRole.AllowsServerCode =
    function() return false end
local beforeProjection = loaded.projection
local pureClient = assert(dofile(
    SERVER .. "PsychopatzCore/Composition/PC_ServerComposition.lua"
))
assert(pureClient.serverLoaded ~= true,
    "pure client loaded server composition")
assert(loaded.projection == beforeProjection,
    "pure client loaded SurvivorWorld projection server")

print("psychopatz_server_composition_sp_smoke: PASS")
