local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

local RuntimeRole = require "PsychopatzCore/Runtime/PC_RuntimeRole"

local function setRole(client, server)
    isClient = function() return client end
    isServer = function() return server end
end

setRole(false, false)
assert(RuntimeRole.IsSinglePlayer(), "single-player role not detected")
assert(RuntimeRole.AllowsServerCode(), "single player lost server code")
assert(RuntimeRole.AllowsClientCode(), "single player lost client code")

setRole(true, false)
assert(RuntimeRole.IsPureClient(), "pure client role not detected")
assert(not RuntimeRole.AllowsServerCode(), "pure client allowed server code")
assert(RuntimeRole.AllowsClientCode(), "pure client lost client code")

setRole(false, true)
assert(RuntimeRole.IsServer(), "dedicated server role not detected")
assert(RuntimeRole.AllowsServerCode(), "dedicated server lost server code")
assert(not RuntimeRole.AllowsClientCode(), "dedicated server allowed client code")

setRole(true, true)
assert(RuntimeRole.IsClient() and RuntimeRole.IsServer(),
    "combined hosted role not detected")
assert(RuntimeRole.AllowsServerCode(), "hosted role lost server code")
assert(RuntimeRole.AllowsClientCode(), "hosted role lost client code")

print("psychopatz_runtime_role_smoke: ok")
