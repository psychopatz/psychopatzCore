local ROOT =
    "Contents/mods/PsychopatzCore/42.20/media/lua/client/PsychopatzCore/Animation/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function assertTruthy(value, label)
    if not value then error(label or "expected truthy value") end
end

local function newClass(parent)
    local class = {}
    setmetatable(class, { __index = parent })
    class.__index = class
    function class:derive()
        return newClass(self)
    end
    return class
end

local state = {
    variables = {},
    actionName = nil,
    event = nil,
    emote = nil,
    emotePlaying = false,
    cancelPressed = false,
}
local queue = { queue = {}, current = nil }

ISBaseTimedAction = newClass({})

function ISBaseTimedAction.new(self, character)
    return setmetatable({ character = character, maxTime = -1 }, self)
end

function ISBaseTimedAction:forceStop()
    self.action.forceStop = true
end

function ISBaseTimedAction:setActionAnim(name)
    self.action:setActionAnim(name)
end

function ISBaseTimedAction:setAnimVariable(name, value)
    self.action:setAnimVariable(name, value)
end

function ISBaseTimedAction:setOverrideHandModels(primary, secondary)
    self.action:setOverrideHandModels(primary, secondary)
end

function ISBaseTimedAction:getDuration()
    return self.maxTime
end

function ISBaseTimedAction:beginAddingActions()
    self._isAddingActions = true
    self._numAddedActions = 0
end

function ISBaseTimedAction:endAddingActions()
    self._isAddingActions = nil
    self._numAddedActions = nil
end

function ISBaseTimedAction:begin()
    local owner = self
    self.action = {
        forceStop = false,
        getCurrentTime = function() return 0 end,
        setActionAnim = function(_, name)
            state.actionName = name
            state.variables.PerformingAction = name
            owner.animVariables = owner.animVariables or {}
            owner.animVariables[#owner.animVariables + 1] = "PerformingAction"
        end,
        setAnimVariable = function(_, name, value)
            state.variables[name] = value
            owner.animVariables = owner.animVariables or {}
            owner.animVariables[#owner.animVariables + 1] = name
        end,
        setOverrideHandModels = function() end,
        stop = function() owner:stop() end,
    }
    self:start()
end

function ISBaseTimedAction:stop()
    for _, name in ipairs(self.animVariables or {}) do
        state.variables[name] = nil
    end
    queue.queue = {}
    queue.current = nil
end

function ISBaseTimedAction:perform()
    table.remove(queue.queue, 1)
    queue.current = queue.queue[1]
    if queue.current then queue.current:begin() end
end

ISTimedActionQueue = {
    getTimedActionQueue = function() return queue end,
    add = function(action)
        local current = queue.queue[1]
        if current and current._isAddingActions then
            table.insert(queue.queue, 2 + (current._numAddedActions or 0), action)
            current._numAddedActions = (current._numAddedActions or 0) + 1
        else
            queue.queue[#queue.queue + 1] = action
            if not queue.current then
                queue.current = action
                action:begin()
            end
        end
        return queue
    end,
}

local player = {
    isLocalPlayer = function() return true end,
    isDead = function() return false end,
    isSeatedInVehicle = function() return false end,
    getUsername = function() return "CoreTestPlayer" end,
    reportEvent = function(_, event) state.event = event end,
    playEmote = function(_, emote)
        state.emote = emote
        state.emotePlaying = true
    end,
    setVariable = function(_, name, value)
        state.variables[name] = value
        if name == "EmotePlaying" then state.emotePlaying = value end
    end,
    getVariableString = function(_, name)
        return name == "emote" and state.emote or ""
    end,
    getVariableBoolean = function(_, name)
        return name == "EmotePlaying" and state.emotePlaying or false
    end,
    pressedCancelAction = function() return state.cancelPressed end,
}

function getSpecificPlayer(index)
    return index == 0 and player or nil
end

PsychopatzCore = {}
Events = nil
function require() return true end
local Player = dofile(ROOT .. "PsychopatzPlayerAnimationController.lua")

local actionEntry = {
    state = "Loot",
    node = "LootHigh",
    anim = "Bob_IdleLooting_High",
    action = "Loot",
    looped = false,
    playable = true,
    variables = {
        { name = "LootPosition", kind = "STRING", value = "High" },
    },
}

Player.SetLoopEnabled(false)
local ok, reason, handle = Player.Play(player, actionEntry, {
    owner = "core-test",
    actionEvents = { Loot = "EventLootItem" },
})
assertTruthy(ok and reason == "player_action_started",
    "core action did not start")
assertTruthy(handle, "core action did not return an ownership handle")
assertEqual(state.actionName, "Loot", "core action selector")
assertEqual(state.variables.LootPosition, "High", "core action variable")
assertEqual(state.event, "EventLootItem", "core action event")
assertEqual(Player.Runtime().owner, "core-test", "core owner tracking")

ok, reason = Player.Play(player, actionEntry, { owner = "other-mod" })
assertEqual(ok, false, "foreign owner replaced active animation")
assertEqual(reason, "player_action_busy",
    "busy action was not refused before ownership replacement")

ok, reason = Player.Stop(nil, "unsafe_stop")
assertEqual(ok, false, "active animation accepted a missing handle")
assertEqual(reason, "animation_handle_required",
    "missing stop handle did not fail closed")

ok, reason = Player.Stop(handle, "test_stop")
assertTruthy(ok and reason == "test_stop", "core action did not stop")
assertEqual(state.variables.PerformingAction, nil,
    "core action selector survived stop")
assertEqual(state.variables.LootPosition, nil,
    "core action variable survived stop")

local emoteEntry = {
    state = "Emote",
    mode = "emote",
    node = "clap",
    anim = "Bob_EmoteClap",
    emote = "core_test_emote",
    looped = true,
    playable = true,
}

Player.SetLoopEnabled(true)
ok, reason, handle = Player.Play(player, emoteEntry, { owner = "core-test" })
assertTruthy(ok and reason == "player_emote_started",
    "core emote did not start")
assertEqual(state.emote, "core_test_emote", "core emote selector")

ok, reason = Player.Play(player, emoteEntry, { owner = "other-mod" })
assertEqual(ok, false, "foreign owner replaced active emote")
assertEqual(reason, "animation_owned_by_other",
    "foreign emote owner was not refused")

state.emotePlaying = false
Player.Maintain()
assertTruthy(state.emotePlaying, "core emote did not loop")
assertEqual(Player.Runtime().loopCount, 1, "core emote loop count")

state.cancelPressed = true
state.emotePlaying = false
Player.Maintain()
assertEqual(Player.GetActiveRecord(), nil,
    "core emote ignored native cancellation")
assertEqual(Player.Runtime().result.reason, "player_emote_cancelled",
    "core emote cancellation result")
state.cancelPressed = false

Player.SetLoopEnabled(false)
assertEqual(Player.HoldCurrentFrame(), false,
    "unsafe frame hold was exposed")
assertEqual(Player.GetActiveRecord(), nil,
    "core emote remained active after cancellation")

print("PASS psychopatz_animation_player_smoke")
