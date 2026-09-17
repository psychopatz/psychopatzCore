require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Animation = PsychopatzCore.Animation or {}

local Animation = PsychopatzCore.Animation
local Player = Animation.Player or {}
Animation.Player = Player

local staleActiveAtLoad = Player.active
local DEFAULT_OWNER = "PsychopatzCore.Animation"

Player.lastResult = Player.lastResult or nil
Player.loopEnabled = Player.loopEnabled == true

local function nowMillis()
    if getTimeInMillis then return tonumber(getTimeInMillis()) or 0 end
    if getTimestampMs then return tonumber(getTimestampMs()) or 0 end
    return 0
end

local function playerName(player)
    if player and player.getUsername then
        return tostring(player:getUsername() or "local")
    end
    return "local"
end

function Player.ResolveLocalPlayer()
    if type(getSpecificPlayer) == "function" then
        local player = getSpecificPlayer(0)
        if player then return player end
    end
    if type(getPlayer) == "function" then return getPlayer() end
    return nil
end

function Player.Validate(player)
    if not player then return false, "no_local_player" end
    if player.isLocalPlayer and not player:isLocalPlayer() then
        return false, "player_is_not_local"
    end
    if player.isDead and player:isDead() then
        return false, "player_is_dead"
    end
    if player.isSeatedInVehicle and player:isSeatedInVehicle() then
        return false, "player_seated_in_vehicle"
    end
    return true
end

local function actionQueue(player)
    return player and ISTimedActionQueue.getTimedActionQueue(player) or nil
end

local function queueLength(queue)
    return queue and queue.queue and #queue.queue or 0
end

local function queueIsIdle(player)
    local queue = actionQueue(player)
    return not queue or queueLength(queue) == 0
end

local function setResult(ok, reason)
    Player.lastResult = {
        ok = ok == true,
        reason = tostring(reason or "animation_failed"),
        at = nowMillis(),
    }
    return ok, reason
end

local function fail(reason)
    return setResult(false, reason)
end

local function currentEmote(player)
    return player and player.getVariableString
        and player:getVariableString("emote") or nil
end

local function emotePlaying(player)
    return player and player.getVariableBoolean
        and player:getVariableBoolean("EmotePlaying") or false
end

local function cancelActionPressed(player)
    return player and player.pressedCancelAction
        and player:pressedCancelAction() == true
end

local function markActionInactive(action, reason, ok)
    local active = Player.active
    if not active or active.action ~= action then return end
    active.finished = true
    setResult(ok == true, reason)
end

local PlayerAction = Player.Action
    or ISBaseTimedAction:derive("PsychopatzCorePlayerAnimationAction")
Player.Action = PlayerAction

function PlayerAction:new(character, entry, active)
    local action = ISBaseTimedAction.new(self, character)
    action.controller = Player
    action.entry = entry
    action.activeRecord = active
    action.stopOnWalk = true
    action.stopOnRun = true
    action.stopOnAim = true
    action.useProgressBar = false
    action.ignoreHandsWounds = true
    action.loopRequested = active.loopRequested == true
    action.maxTime = tonumber(entry.debugDuration) or 120
    return action
end

function PlayerAction:isValidStart()
    local valid = Player.Validate(self.character)
    return valid == true
end

function PlayerAction:isValid()
    local valid = Player.Validate(self.character)
    return valid == true
end

function PlayerAction:start()
    local entry = self.entry
    self:setActionAnim(tostring(entry.action))
    for _, variable in ipairs(entry.variables or {}) do
        if variable.name and variable.value ~= nil then
            local value = variable.value
            if variable.kind == "BOOL" then value = tostring(value) == "true" end
            self:setAnimVariable(variable.name, value)
        end
    end
    self:setOverrideHandModels(nil, nil)
    local event = entry.event
        or (self.activeRecord.actionEvents
            and self.activeRecord.actionEvents[entry.action])
    if event and self.character.reportEvent then
        self.character:reportEvent(event)
    end
end

function PlayerAction:stop()
    markActionInactive(self, "player_action_stopped", false)
    ISBaseTimedAction.stop(self)
end

function PlayerAction:perform()
    local active = self.activeRecord
    if self.loopRequested == true then
        self:beginAddingActions()
        local nextAction = PlayerAction:new(self.character, self.entry, active)
        nextAction.loopRequested = true
        ISTimedActionQueue.add(nextAction)
        self:endAddingActions()
        ISBaseTimedAction.perform(self)

        if Player.active == active then
            active.action = nextAction
            active.loopCount = (tonumber(active.loopCount) or 0) + 1
            active.startedAt = nowMillis()
            setResult(true, "player_action_replayed")
        end
        return
    end
    markActionInactive(self, "player_action_finished", true)
    ISBaseTimedAction.perform(self)
end

local function stopInternal(active, reason)
    if active.mode == "player_emote_state" then
        local player = Player.ResolveLocalPlayer()
        if player == active.body and currentEmote(player) == active.entry.emote
            and emotePlaying(player)
        then
            player:setVariable("EmotePlaying", false)
        end
        Player.active = nil
        setResult(true, reason or "stopped")
        return true, tostring(reason or "stopped")
    end

    local queue = actionQueue(active.body)
    if queue and queue.current == active.action and queueLength(queue) > 1 then
        return fail("debug_action_has_queued_actions")
    end

    if active.action then
        active.action:forceStop()
        if active.action.action then active.action.action:stop() end
    end
    Player.active = nil
    setResult(true, reason or "stopped")
    return true, tostring(reason or "stopped")
end

local function normalizePlayArguments(player, entry, options)
    if type(player) == "table" and player.playable ~= nil then
        return Player.ResolveLocalPlayer(), player, entry
    end
    return player or Player.ResolveLocalPlayer(), entry, options
end

function Player.Play(player, entry, options)
    player, entry, options = normalizePlayArguments(player, entry, options)
    options = type(options) == "table" and options or {}
    if type(entry) ~= "table" or entry.playable ~= true
        or (entry.mode ~= "emote"
            and (not entry.action or tostring(entry.action) == ""))
        or (entry.mode == "emote"
            and (not entry.emote or tostring(entry.emote) == ""))
    then
        return fail("selected_entry_has_no_player_action")
    end

    local valid, reason = Player.Validate(player)
    if not valid then return fail(reason) end
    if not queueIsIdle(player) then return fail("player_action_busy") end

    local owner = tostring(options.owner or DEFAULT_OWNER)
    if owner == "" then owner = DEFAULT_OWNER end
    if Player.active then
        if Player.active.owner ~= owner then
            return fail("animation_owned_by_other")
        end
        local stopped = stopInternal(Player.active, "replaced")
        if not stopped then return false, "animation_stop_pending" end
    end

    local loopRequested = options.loop
    if loopRequested == nil then loopRequested = Player.loopEnabled end
    local active = {
        body = player,
        playerName = playerName(player),
        entry = entry,
        owner = owner,
        loopRequested = loopRequested == true,
        loopCount = 0,
        startedAt = nowMillis(),
        actionEvents = options.actionEvents or {},
    }
    active.handle = {
        controller = Player,
        owner = owner,
        record = active,
    }

    if entry.mode == "emote" then
        if type(player.playEmote) ~= "function" then
            return fail("player_emote_api_unavailable")
        end
        player:playEmote(tostring(entry.emote))
        active.mode = "player_emote_state"
        Player.active = active
        setResult(true, "player_emote_started")
        return true, "player_emote_started", active.handle
    end

    active.mode = "player_action_context"
    active.action = PlayerAction:new(player, entry, active)
    Player.active = active
    ISTimedActionQueue.add(active.action)
    setResult(true, "player_action_started")
    return true, "player_action_started", active.handle
end

function Player.Stop(handle, reason)
    local active = Player.active
    if not active then return fail("nothing_playing") end
    if not handle then return fail("animation_handle_required") end
    if handle ~= active.handle then
        return fail("animation_handle_not_active")
    end
    return stopInternal(active, reason or "stopped")
end

function Player.Replay(handle)
    local active = Player.active
    if not active then return fail("nothing_playing") end
    if not handle then return fail("animation_handle_required") end
    if handle ~= active.handle then
        return fail("animation_handle_not_active")
    end
    if not active.entry then
        return fail("nothing_playing")
    end
    local entry, owner = active.entry, active.owner
    local stopped, reason = stopInternal(active, "replay")
    if not stopped then return false, reason end
    return Player.Play(active.body, entry, {
        owner = owner,
        loop = Player.loopEnabled,
        actionEvents = active.actionEvents,
    })
end

function Player.IsLoopEnabled()
    return Player.loopEnabled == true
end

function Player.SetLoopEnabled(enabled)
    Player.loopEnabled = enabled == true
    local active = Player.active
    if active then
        active.loopRequested = Player.loopEnabled
        if active.action then active.action.loopRequested = Player.loopEnabled end
    end
    return setResult(true, Player.loopEnabled and "loop_enabled" or "loop_disabled")
end

function Player.ToggleLoop()
    return Player.SetLoopEnabled(not Player.loopEnabled)
end

function Player.GetActiveRecord()
    return Player.active
end

function Player.GetActiveHandle()
    return Player.active and Player.active.handle or nil
end

function Player.HoldCurrentFrame()
    return fail("action_context_has_no_safe_frame_freeze")
end

function Player.IsHoldPoseEnabled()
    return false
end

function Player.SetHoldPose()
    return fail("action_context_has_no_safe_pose_hold")
end

function Player.Maintain()
    local active = Player.active
    if not active then return false end

    local player = Player.ResolveLocalPlayer()
    if player ~= active.body then
        stopInternal(active, "local_player_changed")
        return false
    end
    local valid, reason = Player.Validate(player)
    if not valid then
        stopInternal(active, reason)
        return false
    end

    if active.mode == "player_emote_state" then
        local emote = currentEmote(player)
        if emote ~= active.entry.emote and emote ~= nil and emote ~= "" then
            Player.active = nil
            setResult(true, "player_emote_finished")
            return false
        end
        if not emotePlaying(player) then
            if cancelActionPressed(player) then
                Player.active = nil
                setResult(true, "player_emote_cancelled")
                return false
            end
            if active.loopRequested then
                player:playEmote(tostring(active.entry.emote))
                active.loopCount = (tonumber(active.loopCount) or 0) + 1
                active.startedAt = nowMillis()
                setResult(true, "player_emote_replayed")
                return true
            end
            Player.active = nil
            setResult(true, "player_emote_finished")
            return false
        end
        return true
    end

    local queue = actionQueue(player)
    if active.finished or not queue or queue.current ~= active.action then
        Player.active = nil
        return false
    end
    return true
end

function Player.Runtime()
    local active = Player.active
    local currentPlayer = Player.ResolveLocalPlayer()
    local playerValid, playerReason = Player.Validate(currentPlayer)
    local busy = currentPlayer and not queueIsIdle(currentPlayer) or false
    if playerValid and busy and not active then playerReason = "player_action_busy" end

    local action = active and active.action or nil
    local javaAction = action and action.action or nil
    local actionTime = javaAction and javaAction.getCurrentTime
        and tonumber(javaAction:getCurrentTime()) or nil
    local actionDuration = action and action.getDuration
        and tonumber(action:getDuration()) or nil
    local entry = active and active.entry or nil
    return {
        active = active ~= nil,
        mode = active and active.mode or nil,
        owner = active and active.owner or nil,
        playerAvailable = currentPlayer ~= nil,
        playerReady = playerValid == true and not busy,
        playerBusy = busy,
        playerReason = playerReason,
        playerName = active and active.playerName
            or (currentPlayer and playerName(currentPlayer) or nil),
        requestedState = entry and entry.state or nil,
        requestedAction = entry and entry.action or nil,
        requestedEmote = entry and entry.emote or nil,
        requestedClip = entry and entry.anim or nil,
        node = entry and entry.node or nil,
        looped = entry and entry.looped == true or false,
        loopRequested = active and active.loopRequested == true or false,
        loopCount = active and tonumber(active.loopCount) or 0,
        actionTime = actionTime,
        actionDuration = actionDuration,
        actionSource = entry and (entry.bridgePath or entry.path) or nil,
        result = Player.lastResult,
    }
end

function Player.Dump()
    local runtime = Player.Runtime()
    print("[PsychopatzCore][ANIMATION] active=" .. tostring(runtime.active)
        .. " player=" .. tostring(runtime.playerName or "-")
        .. " mode=" .. tostring(runtime.mode or "-")
        .. " action=" .. tostring(runtime.requestedAction or "-")
        .. " emote=" .. tostring(runtime.requestedEmote or "-")
        .. " node=" .. tostring(runtime.node or "-")
        .. " clip=" .. tostring(runtime.requestedClip or "-")
        .. " loop=" .. tostring(runtime.loopRequested)
        .. " repeats=" .. tostring(runtime.loopCount or 0)
        .. " time=" .. tostring(runtime.actionTime or "-"))
    return runtime
end

local function onTick()
    Player.Maintain()
end

if Events and Events.OnTick and Events.OnTick.Add and not Player._tickHook then
    Events.OnTick.Add(onTick)
    Player._tickHook = true
end

local function onResetLua()
    if Player.active then stopInternal(Player.active, "lua_reset") end
end

if Events and Events.OnResetLua and Events.OnResetLua.Add
    and not Player._resetHook
then
    Events.OnResetLua.Add(onResetLua)
    Player._resetHook = true
end

if staleActiveAtLoad and Player.active == staleActiveAtLoad then
    stopInternal(staleActiveAtLoad, "module_reload")
end

return Player
