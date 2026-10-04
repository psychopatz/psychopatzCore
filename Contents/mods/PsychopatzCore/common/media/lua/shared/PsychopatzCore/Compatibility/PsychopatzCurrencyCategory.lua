PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Compatibility = PsychopatzCore.Compatibility or {}

local Core = PsychopatzCore
local Compatibility = Core.Compatibility
local Category = Compatibility.CurrencyCategory or {}
Compatibility.CurrencyCategory = Category

if Category._initialized then
    return Category
end

local TARGET_CATEGORY = "Currency"
local DEFAULT_CATEGORY = "Junk"
local TARGET_TYPES = {
    "Base.Money",
    "Base.MoneyBundle",
}

local State = Category._state or {
    attempts = 0,
    applied = false,
    lastReason = nil,
    scriptItems = {},
    conflicts = {},
    warnings = {},
    boundEvents = {},
}
Category._state = State

local function log(level, message)
    local logger = Core.Logger
    local method = logger and (logger[level] or logger[string.lower(level)])
    if type(method) == "function" then
        local ok = pcall(method, logger, "CurrencyCategory", message)
        if ok then return end
    end
    if print then
        print("[PsychopatzCore][CurrencyCategory][" .. level .. "] "
            .. tostring(message))
    end
end

local function warnOnce(key, message)
    if State.warnings[key] then return end
    State.warnings[key] = true
    log("WARN", message)
end

local function resolveScriptManager()
    local ok, manager
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
    local ok, item
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

local function readField(item, field)
    local ok, value = pcall(function() return item[field] end)
    if ok then return value end
    return nil
end

local function readScriptCategory(item)
    local getter = item.getDisplayCategory
    if type(getter) == "function" then
        local ok, value = pcall(getter, item)
        if ok then return value end
    end
    return readField(item, "displayCategory")
end

local function writeScriptCategory(item)
    local doParam = item.DoParam
    if type(doParam) == "function" then
        return pcall(doParam, item, "DisplayCategory=" .. TARGET_CATEGORY)
    end
    if type(item) == "table" then
        item.displayCategory = TARGET_CATEGORY
        return true
    end
    return false
end

local function patchScriptItem(manager, fullType)
    local status = State.scriptItems[fullType] or {}
    local item, reason
    local current
    State.scriptItems[fullType] = status
    status.found = false
    status.applied = false
    status.category = nil
    status.error = nil

    item, reason = getScriptItem(manager, fullType)
    if not item then
        status.error = reason
        warnOnce(fullType .. ":missing", "Unable to patch " .. fullType
            .. " (" .. tostring(reason) .. ")")
        return false
    end
    status.found = true

    current = tostring(readScriptCategory(item) or "")
    if current ~= "" and current ~= DEFAULT_CATEGORY
        and current ~= TARGET_CATEGORY
    then
        status.category = current
        State.conflicts[fullType] = current
        warnOnce(fullType .. ":conflict", "Preserving another mod's display category "
            .. current .. " for " .. fullType)
        return false
    end

    local ok = writeScriptCategory(item)
    if not ok then
        status.error = "display_category_write_failed"
        warnOnce(fullType .. ":setter", "Unable to set display category for "
            .. fullType)
        return false
    end

    current = tostring(readScriptCategory(item) or "")
    status.category = current
    status.applied = current == TARGET_CATEGORY
    if not status.applied then
        status.error = "display_category_readback_failed"
        warnOnce(fullType .. ":readback", "Unable to verify Currency category for "
            .. fullType)
    end
    return status.applied
end

local function itemType(item)
    local ok, fullType = pcall(function() return item:getFullType() end)
    if ok then return tostring(fullType or "") end
    return ""
end

local function patchInstance(item)
    local fullType = itemType(item)
    if fullType ~= "Base.Money" and fullType ~= "Base.MoneyBundle" then
        return false
    end

    local getter = item.getDisplayCategory
    local setter = item.setDisplayCategory
    if type(setter) ~= "function" then return false end

    local current = ""
    if type(getter) == "function" then
        local ok, value = pcall(getter, item)
        if ok then current = tostring(value or "") end
    end
    if current ~= "" and current ~= DEFAULT_CATEGORY
        and current ~= TARGET_CATEGORY
    then
        return false
    end

    local ok = pcall(setter, item, TARGET_CATEGORY)
    if not ok then return false end
    if type(getter) == "function" then
        local readOK, value = pcall(getter, item)
        return readOK and tostring(value or "") == TARGET_CATEGORY
    end
    return true
end

local function listItems(container)
    local output = {}
    if not container or type(container.getItems) ~= "function" then
        return output
    end
    local ok, list = pcall(container.getItems, container)
    if not ok or not list then return output end
    if type(list.size) == "function" and type(list.get) == "function" then
        local size = tonumber(list:size()) or 0
        for index = 0, size - 1 do
            local item = list:get(index)
            if item then output[#output + 1] = item end
        end
    elseif type(list) == "table" then
        for index = 1, #list do
            if list[index] then output[#output + 1] = list[index] end
        end
    end
    return output
end

local function scanContainer(container, depth)
    if not container or depth > 12 then return 0 end
    local patched = 0
    for _, item in ipairs(listItems(container)) do
        if patchInstance(item) then patched = patched + 1 end
        local nested
        local getItemContainer = item.getItemContainer
        if type(getItemContainer) == "function" then
            local ok, candidate = pcall(getItemContainer, item)
            if ok and candidate then nested = candidate end
        end
        if not nested then
            local getInventory = item.getInventory
            if type(getInventory) == "function" then
                local ok, candidate = pcall(getInventory, item)
                if ok and candidate then nested = candidate end
            end
        end
        if nested then
            patched = patched + scanContainer(nested, depth + 1)
        end
    end
    return patched
end

local function scanPlayer(player)
    if not player or type(player.getInventory) ~= "function" then return 0 end
    local ok, inventory = pcall(player.getInventory, player)
    if not ok then return 0 end
    return scanContainer(inventory, 0)
end

function Category.Apply(reason)
    local manager = resolveScriptManager()
    local appliedCount = 0
    State.attempts = State.attempts + 1
    State.lastReason = reason or "manual"
    if not manager then
        State.applied = false
        warnOnce("manager", "Script manager is unavailable for currency categories")
        return false
    end

    for index = 1, #TARGET_TYPES do
        if patchScriptItem(manager, TARGET_TYPES[index]) then
            appliedCount = appliedCount + 1
        end
    end

    if type(getPlayer) == "function" then
        local ok, player = pcall(getPlayer)
        if ok and player then scanPlayer(player) end
    end

    State.applied = appliedCount == #TARGET_TYPES
    if State.applied and not State.loggedApplied then
        State.loggedApplied = true
        log("INFO", "Base.Money and Base.MoneyBundle category set to Currency")
    end
    return State.applied
end

function Category.PatchItem(item)
    return patchInstance(item)
end

function Category.GetStatus()
    local status = {
        attempts = State.attempts,
        applied = State.applied,
        lastReason = State.lastReason,
        scriptItems = {},
        conflicts = {},
    }
    for key, value in pairs(State.scriptItems) do
        status.scriptItems[key] = {}
        for field, fieldValue in pairs(value) do
            status.scriptItems[key][field] = fieldValue
        end
    end
    for key, value in pairs(State.conflicts) do
        status.conflicts[key] = value
    end
    return status
end

local function bindOnce(eventName)
    local event = Events and Events[eventName]
    if State.boundEvents[eventName] or not event
        or type(event.Add) ~= "function"
    then
        return false
    end
    local callback = function()
        Category.Apply(eventName)
        State.boundEvents[eventName] = false
        if type(event.Remove) == "function" then
            pcall(event.Remove, callback)
        end
    end
    local ok = pcall(event.Add, callback)
    if ok then
        State.boundEvents[eventName] = true
        return true
    end
    return false
end

Category._initialized = true
Category.Apply("shared_load")
bindOnce("OnGameBoot")
bindOnce("OnGameStart")
bindOnce("OnCreatePlayer")

return Category
