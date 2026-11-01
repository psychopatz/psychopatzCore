-- Smoke test for P4 Event and Lifecycle Ownership
-- Verifies that features own their event callbacks via activate and detach them on deactivate.

package.path = table.concat({
    "Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua",
    "Contents/mods/PsychopatzCore/42.20/media/lua/shared/?.lua",
    "Contents/mods/PsychopatzCore/common/media/lua/client/?.lua",
    "Contents/mods/PsychopatzCore/42.20/media/lua/client/?.lua",
    package.path,
}, ";")

local eventHooks = {
    OnPlayerUpdate = {},
    OnCreatePlayer = {},
    OnTick = {},
    OnGameBoot = {},
}

Events = setmetatable({}, {
    __index = function(t, eventName)
        local store = eventHooks[eventName] or {}
        eventHooks[eventName] = store
        local handler = {
            Add = function(fn)
                table.insert(store, fn)
            end,
            Remove = function(fn)
                for i = #store, 1, -1 do
                    if store[i] == fn then
                        table.remove(store, i)
                    end
                end
            end,
        }
        rawset(t, eventName, handler)
        return handler
    end,
})

isClient = function() return true end
isServer = function() return false end
getText = function(s) return s end

local Kernel = require "PsychopatzCore/Kernel/PC_Kernel"
Kernel.InitCatalog()

-- 1. Initial State: Unrequested features must contribute ZERO callbacks
assert(#eventHooks.OnPlayerUpdate == 0, "OnPlayerUpdate must have 0 listeners initially")
assert(#eventHooks.OnCreatePlayer == 0, "OnCreatePlayer must have 0 listeners initially")
assert(#eventHooks.OnTick == 0, "OnTick must have 0 listeners initially")

-- 2. Activate core.traits
local ok, facade = Kernel.Require("core.traits", "LifecycleTestConsumer")
assert(ok == true, "Failed to activate core.traits")
assert(#eventHooks.OnPlayerUpdate > 0, "OnPlayerUpdate must have listeners after activation")
assert(#eventHooks.OnCreatePlayer > 0, "OnCreatePlayer must have listeners after activation")

-- 3. Deactivate core.traits
Kernel.Release("core.traits", "LifecycleTestConsumer")
assert(#eventHooks.OnPlayerUpdate == 0, "OnPlayerUpdate listeners must be detached on deactivation")
assert(#eventHooks.OnCreatePlayer == 0, "OnCreatePlayer listeners must be detached on deactivation")

-- 4. Activate core.input_keybinds
local okKb = Kernel.Require("core.input_keybinds", "LifecycleTestConsumer")
assert(okKb == true, "Failed to activate core.input_keybinds")
assert(#eventHooks.OnTick > 0, "OnTick must have listeners after keybinds activation")

-- 5. Deactivate core.input_keybinds
Kernel.Release("core.input_keybinds", "LifecycleTestConsumer")
assert(#eventHooks.OnTick == 0, "OnTick listeners must be detached on keybinds deactivation")

print("psychopatz lifecycle smoke: ok")
