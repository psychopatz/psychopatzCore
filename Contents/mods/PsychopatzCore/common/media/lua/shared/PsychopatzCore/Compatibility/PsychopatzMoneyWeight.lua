PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Compatibility = PsychopatzCore.Compatibility or {}

local Core = PsychopatzCore
local Compatibility = Core.Compatibility
local MoneyWeight = Compatibility.MoneyWeight or {}
Compatibility.MoneyWeight = MoneyWeight

if MoneyWeight._initialized then
    return MoneyWeight
end

local TARGET_WEIGHT = 0.0
local TARGET_TYPES = {
    "Base.Money",
    "Base.MoneyBundle",
}

local State = MoneyWeight._state or {
    attempts = 0,
    applied = false,
    lastReason = nil,
    items = {},
    warnings = {},
    boundEvents = {},
    deferredTickBound = false,
}
MoneyWeight._state = State

local function log(level, message)
    local logger = Core.Logger
    local method = logger and (logger[level] or logger[string.lower(level)])
    if type(method) == "function" then
        local ok = pcall(method, logger, "MoneyWeight", message)
        if ok then return end
    end
    if print then
        print("[PsychopatzCore][MoneyWeight][" .. level .. "] " .. tostring(message))
    end
end

local function warnOnce(key, message)
    if State.warnings[key] then return end
    State.warnings[key] = true
    log("WARN", message)
end

local function resolveScriptManager()
    local ok
    local manager

    if type(getScriptManager) == "function" then
        ok, manager = pcall(getScriptManager)
        if ok and manager then return manager end
    end

    if ScriptManager then
        ok, manager = pcall(function() return ScriptManager.instance end)
        if ok and manager then return manager end
    end

    return nil
end

local function getScriptItem(manager, fullType)
    local method
    local ok
    local item

    if not manager then return nil, "script_manager_unavailable" end

    method = manager.getItem
    if type(method) == "function" then
        ok, item = pcall(method, manager, fullType)
        if ok and item then return item end
    end

    method = manager.FindItem
    if type(method) == "function" then
        ok, item = pcall(method, manager, fullType)
        if ok and item then return item end
    end

    return nil, "item_definition_unavailable"
end

local function applyItem(manager, fullType)
    local itemState = State.items[fullType] or {}
    local item
    local method
    local ok
    local current
    local reader

    State.items[fullType] = itemState
    itemState.found = false
    itemState.verified = nil
    itemState.weight = nil
    itemState.error = nil

    item, itemState.error = getScriptItem(manager, fullType)
    if not item then
        warnOnce(fullType .. ":missing", "Unable to patch " .. fullType
            .. " (" .. tostring(itemState.error) .. ")")
        return false
    end
    itemState.found = true

    -- Remove only the base inventory double-click route. Keep the recipe
    -- registered so other crafting surfaces and mods can still resolve it.
    if fullType == "Base.MoneyBundle"
        and type(item.getDoubleClickRecipe) == "function"
        and type(item.setDoubleClickRecipe) == "function"
    then
        local recipeOK, recipeName = pcall(item.getDoubleClickRecipe, item)
        if recipeOK and (recipeName == "UnbundleMoney"
            or recipeName == "Unbundle Money")
        then
            local cleared = pcall(item.setDoubleClickRecipe, item, nil)
            if not cleared then
                -- Older Lua bridges may reject nil for Java String parameters.
                pcall(item.setDoubleClickRecipe, item, "")
            end
        end
    end

    method = item.setActualWeight
    if type(method) ~= "function" then
        itemState.error = "setActualWeight_unavailable"
        warnOnce(fullType .. ":setter", "Unable to patch " .. fullType
            .. ": setActualWeight is unavailable")
        return false
    end
    ok = pcall(method, item, TARGET_WEIGHT)
    if not ok then
        itemState.error = "setActualWeight_failed"
        warnOnce(fullType .. ":setter_failed", "Unable to patch " .. fullType
            .. ": setActualWeight failed")
        return false
    end

    reader = item.getActualWeight or item.getWeight
    if type(reader) == "function" then
        ok, current = pcall(reader, item)
        if ok then
            itemState.weight = current
            itemState.verified = current == TARGET_WEIGHT
            if not itemState.verified then
                itemState.error = "weight_conflict"
                warnOnce(fullType .. ":conflict", "Another item definition override kept "
                    .. fullType .. " at " .. tostring(current)
                    .. " after the Core patch")
                return false
            end
        else
            itemState.error = "weight_readback_failed"
            warnOnce(fullType .. ":readback", "Unable to verify the patched weight for "
                .. fullType)
        end
    end

    return true
end

function MoneyWeight.Apply(reason)
    local manager = resolveScriptManager()
    local appliedCount = 0
    local index

    State.attempts = State.attempts + 1
    State.lastReason = reason or "manual"

    if not manager then
        State.applied = false
        warnOnce("manager", "Script manager is not available for the money-weight patch")
        return false
    end

    for index = 1, #TARGET_TYPES do
        if applyItem(manager, TARGET_TYPES[index]) then
            appliedCount = appliedCount + 1
        end
    end

    State.applied = appliedCount == #TARGET_TYPES
    if State.applied and not State.loggedApplied then
        State.loggedApplied = true
        log("INFO", "Base.Money and Base.MoneyBundle weights set to 0.0")
    end
    return State.applied
end

function MoneyWeight.GetStatus()
    local status = {
        attempts = State.attempts,
        applied = State.applied,
        lastReason = State.lastReason,
        items = {},
    }
    local index
    local fullType
    local source
    local target

    for index = 1, #TARGET_TYPES do
        fullType = TARGET_TYPES[index]
        source = State.items[fullType] or {}
        target = {}
        for key, value in pairs(source) do
            target[key] = value
        end
        status.items[fullType] = target
    end

    return status
end

local function bindOnce(eventName)
    local event = Events and Events[eventName]
    local callback
    local ok
    local called = false

    if State.boundEvents[eventName] or not event
        or type(event.Add) ~= "function"
    then
        return false
    end

    callback = function()
        if called then return end
        called = true
        MoneyWeight.Apply(eventName)
        State.boundEvents[eventName] = false
        if type(event.Remove) == "function" then
            pcall(event.Remove, callback)
        end
    end

    ok = pcall(event.Add, callback)
    if ok then
        State.boundEvents[eventName] = true
        return true
    end

    warnOnce(eventName .. ":bind", "Unable to bind the money-weight patch to "
        .. eventName)
    return false
end

local function bindDeferredReconcile()
    local event = Events and Events.OnTick
    local callback
    local ok
    local called = false

    if State.deferredTickBound or not event
        or type(event.Add) ~= "function"
    then
        return false
    end

    callback = function()
        if called then return end
        called = true
        MoneyWeight.Apply("OnTick_reconcile")
        State.deferredTickBound = false
        if type(event.Remove) == "function" then
            pcall(event.Remove, callback)
        end
    end

    ok = pcall(event.Add, callback)
    if ok then
        State.deferredTickBound = true
        return true
    end

    warnOnce("OnTick:bind", "Unable to bind the deferred money-weight reconciliation")
    return false
end

local function bindStartReconcile()
    local event = Events and Events.OnGameStart
    local callback
    local ok
    local called = false

    if State.boundEvents.OnGameStart or not event
        or type(event.Add) ~= "function"
    then
        return false
    end

    callback = function()
        if called then return end
        called = true
        MoneyWeight.Apply("OnGameStart")
        State.boundEvents.OnGameStart = false
        bindDeferredReconcile()
        if type(event.Remove) == "function" then
            pcall(event.Remove, callback)
        end
    end

    ok = pcall(event.Add, callback)
    if ok then
        State.boundEvents.OnGameStart = true
        return true
    end

    warnOnce("OnGameStart:bind", "Unable to bind the money-weight patch to OnGameStart")
    return false
end

MoneyWeight._initialized = true
MoneyWeight.Apply("shared_load")
bindOnce("OnGameBoot")
bindStartReconcile()

return MoneyWeight
