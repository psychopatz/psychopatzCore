local root = "Contents/mods/PsychopatzCore/42.19/media/lua/"
local tickCallback

package.preload["TimedActions/ISAttachItemHotbar"] = function()
    return true
end

Events = {
    OnTick = {
        Add = function(callback)
            tickCallback = callback
        end,
        Remove = function(callback)
            if tickCallback == callback then
                tickCallback = nil
            end
        end,
    },
}

local vanillaCalls = 0
ISAttachItemHotbar = {
    animEvent = function()
        vanillaCalls = vanillaCalls + 1
    end,
}

dofile(root
    .. "client/PsychopatzCore/Compatibility/"
    .. "PsychopatzWalkieHotbarGuard.lua")

local handModelClears = 0
local handRemovals = 0
local completions = 0
local action = {
    item = {
        getAttachmentType = function()
            return "Walkie"
        end,
    },
    character = {
        isEquipped = function()
            return true
        end,
        removeFromHands = function()
            handRemovals = handRemovals + 1
        end,
    },
    maxTime = -1,
    setOverrideHandModels = function()
        handModelClears = handModelClears + 1
    end,
    forceComplete = function()
        completions = completions + 1
    end,
}

ISAttachItemHotbar.animEvent(action, "attachConnect", nil)
ISAttachItemHotbar.animEvent(action, "attachConnect", nil)
assert(vanillaCalls == 0, "walkie must bypass the broken vanilla anim event")
assert(handModelClears == 2, "walkie hand model must be cleared")
assert(handRemovals == 2, "equipped walkie must leave the hands")
assert(completions == 0, "completion must not run inside the animation event")
assert(type(tickCallback) == "function", "completion must be deferred")

tickCallback()
assert(completions == 1, "duplicate events must schedule one completion")
assert(tickCallback == nil, "one-shot tick handler must remove itself")

local ordinaryAction = {
    item = {
        getAttachmentType = function()
            return "Hammer"
        end,
    },
}
ISAttachItemHotbar.animEvent(ordinaryAction, "attachConnect", nil)
assert(vanillaCalls == 1, "non-walkie actions must remain vanilla")

print("psychopatz_walkie_hotbar_guard_smoke: ok")
