require "PsychopatzCore/00_PsychopatzCore_Init"

PsychopatzCore = PsychopatzCore or {}

local Core = PsychopatzCore
local SquareRules = require "PsychopatzCore/World/PsychopatzSquareRules"
local Context = Core.ObjectNameDebugContext or {}
local LABEL = "[Debug] Grab Object Name"

Core.ObjectNameDebugContext = Context

local function canUseDebug(player)
    local debugAccess = Core.Debug
    return debugAccess
        and type(debugAccess.CanUse) == "function"
        and debugAccess.CanUse(player) == true
end

local function call(object, method)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object)
    return ok and value or nil
end

local function display(value)
    if value == nil then return "<nil>" end
    return tostring(value)
end

local function logObject(object, index)
    local objectName
    local name
    local spriteName
    local customName
    local resolvedName
    local square
    local x
    local y
    local z
    if not object then return false end

    objectName = call(object, "getObjectName")
    name = call(object, "getName")
    spriteName = call(object, "getSpriteName")
    customName = SquareRules.GetObjectProperty(object, "CustomName")
    resolvedName = customName or name or spriteName or objectName
    square = call(object, "getSquare")
    x = call(square, "getX")
    y = call(square, "getY")
    z = call(square, "getZ")

    print(LABEL
        .. " | clickedIndex=" .. display(index)
        .. " | resolvedName=" .. display(resolvedName)
        .. " | customName=" .. display(customName)
        .. " | objectName=" .. display(objectName)
        .. " | name=" .. display(name)
        .. " | spriteName=" .. display(spriteName)
        .. " | square=" .. display(x) .. "," .. display(y)
        .. "," .. display(z))
    return true
end

function Context.Grab(worldObjects, player)
    local logged = 0
    local seen = {}
    local index
    local object
    if not canUseDebug(player) or type(worldObjects) ~= "table" then
        return 0
    end

    for index = 1, #worldObjects do
        object = worldObjects[index]
        if object and not seen[object] then
            seen[object] = true
            if logObject(object, index) then
                logged = logged + 1
            end
        end
    end
    return logged
end

function Context.Add(context, worldObjects, player)
    local option
    if not canUseDebug(player) or not context or type(worldObjects) ~= "table" then
        return nil
    end
    if #worldObjects <= 0 or not worldObjects[1] then
        return nil
    end

    option = context:addOption(LABEL, nil, function()
        return Context.Grab(worldObjects, player)
    end)
    return option
end

Context.Label = LABEL

return Context
