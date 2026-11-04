local COMMON =
    "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = COMMON .. "?.lua;" .. package.path

isClient = function() return false end
isServer = function() return false end

local roots = {}
ModData = {
    getOrCreate = function(key)
        roots[key] = roots[key] or {}
        return roots[key]
    end,
    get = function(key)
        return roots[key]
    end,
}

Events = {
    OnInitGlobalModData = { Add = function() end },
    OnSave = { Add = function() end },
}

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local Store = Actors.RuntimeStore

local serialized = string.rep("x", Store.MAX_STRING_BYTES + 17)
local restored
local fakeRegistry = {
    revision = 7,
    Save = function()
        return serialized
    end,
    Load = function(_, value)
        restored = value
        return value == serialized
    end,
}

Store.Registry = fakeRegistry
local saved, saveReason = Store.Save()
assert(saved == true, saveReason)

local root = assert(roots[Store.STORAGE_KEY])
assert(root.registry == nil,
    "oversized actor registry must not be written as one PZ string")
assert(type(root.registryChunks) == "table",
    "oversized actor registry did not use chunked persistence")
assert(#root.registryChunks >= 2,
    "oversized actor registry was not split into multiple chunks")
for index = 1, #root.registryChunks do
    assert(#root.registryChunks[index] <= Store.MAX_STRING_BYTES,
        "actor registry chunk exceeds the PZ StringUTF boundary")
end
assert(table.concat(root.registryChunks) == serialized,
    "actor registry chunks changed serialized bytes")

local loaded, loadReason = Store.Load()
assert(loaded == true, loadReason)
assert(restored == serialized,
    "chunked actor registry did not reassemble before decode")

print("psychopatz_actor_runtime_store_chunk_smoke: PASS")
