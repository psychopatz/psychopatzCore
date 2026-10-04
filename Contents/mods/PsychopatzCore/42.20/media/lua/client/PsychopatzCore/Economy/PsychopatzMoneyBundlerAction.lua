require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"
require "PsychopatzCore/Economy/PsychopatzMoneyBundler"

PsychopatzCore = PsychopatzCore or {}
local Core = PsychopatzCore
local MoneyBundler = Core.MoneyBundler

local Action = MoneyBundler.Action
    or ISBaseTimedAction:derive("PsychopatzCoreMoneyBundlerAction")
MoneyBundler.Action = Action

local function getBaseActionScript()
    if type(getScriptManager) ~= "function" then return nil end
    local ok, manager = pcall(getScriptManager)
    if not ok or not manager or type(manager.getCraftRecipe) ~= "function" then
        return nil
    end
    local recipe = manager:getCraftRecipe(MoneyBundler.UNBUNDLE_RECIPE)
    if not recipe or type(recipe.getTimedActionScript) ~= "function" then
        return nil
    end
    return recipe:getTimedActionScript()
end

local function stopSound(action)
    if action.sound and action.character and action.character:getEmitter():isPlaying(action.sound) then
        action.character:stopOrTriggerSound(action.sound)
    end
end

local function applyBaseAnimation(action)
    local script = action.actionScript
    if not script then
        action:setActionAnim("Craft")
        return
    end

    local animation = script:getActionAnim()
    action:setActionAnim(animation or "Craft")

    local key = script:getAnimVarKey()
    if key then
        action:setAnimVariable(key, script:getAnimVarVal())
    end

    if ActionSoundTime and script:getSound() ~= nil
        and script:getSoundTime() == ActionSoundTime.ACTION_START
    then
        action.sound = action.character:playSound(script:getSound())
    end
end

function Action:new(character, command)
    local action = ISBaseTimedAction.new(self, character)
    action.command = command
    action.maxTime = MoneyBundler.DURATION
    action.stopOnWalk = true
    action.stopOnRun = true
    action.actionScript = getBaseActionScript()
    return action
end

function Action:isValidStart()
    return self:isValid()
end

function Action:isValid()
    if not self.character or type(self.character.getInventory) ~= "function" then
        return false
    end

    local moneyCount, bundleCount = MoneyBundler.GetCounts(self.character:getInventory())
    if self.command == MoneyBundler.BUNDLE_COMMAND then
        return moneyCount >= MoneyBundler.BUNDLE_VALUE
    elseif self.command == MoneyBundler.UNBUNDLE_COMMAND then
        return bundleCount > 0
    end
    return false
end

function Action:getDuration()
    if self.character and self.character.isTimedActionInstant
        and self.character:isTimedActionInstant()
    then
        return 1
    end
    return self.maxTime
end

function Action:start()
    applyBaseAnimation(self)
end

function Action:stop()
    stopSound(self)
    ISBaseTimedAction.stop(self)
end

function Action:perform()
    stopSound(self)
    if self.actionScript and self.actionScript:getCompletionSound() ~= nil then
        self.character:playSound(self.actionScript:getCompletionSound())
    end

    sendClientCommand(
        self.character,
        MoneyBundler.COMMAND_MODULE,
        self.command,
        {}
    )
    if ISInventoryPage and ISInventoryPage.dirtyUI then
        ISInventoryPage.dirtyUI()
    end
    ISBaseTimedAction.perform(self)
end

function Action:animEvent(event, parameter)
    local script = self.actionScript
    if not script or not ActionSoundTime or script:getSound() == nil then return end

    if event == "StartActionAnim"
        and script:getSoundTime() == ActionSoundTime.ANIMATION_START
    then
        stopSound(self)
        self.sound = self.character:playSound(script:getSound())
    elseif event == "PlayActionSound"
        and script:getSoundTime() == ActionSoundTime.ANIMATION_EVENT
    then
        stopSound(self)
        self.sound = self.character:playSound(script:getSound())
    end
end

function MoneyBundler.Queue(player, command)
    if not player or not command or not ISTimedActionQueue then return false end
    ISTimedActionQueue.add(Action:new(player, command))
    return true
end

return Action
