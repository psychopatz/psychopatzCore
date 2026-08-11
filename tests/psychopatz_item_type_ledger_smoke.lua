local SHARED = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
local CLIENT = "Contents/mods/PsychopatzCore/42.19/media/lua/client/"
package.path = SHARED .. "?.lua;" .. CLIENT .. "?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

PsychopatzCore = {
    Inventory = {},
    UI = { Theme = {}, Layout = {} },
    DebugHub = {},
}

local Window = {}
function Window:derive()
    local child = {}
    child.__index = child
    setmetatable(child, { __index = self })
    return child
end
PsychopatzWindow = Window

local registered
function PsychopatzCore.DebugHub.RegisterTool(definition)
    registered = definition
    return true
end

package.preload["ISUI/ISTextEntryBox"] = function()
    ISTextEntryBox = {}
    return ISTextEntryBox
end
package.preload["PsychopatzCore/UI/PsychopatzUI"] = function()
    return PsychopatzCore.UI
end
package.preload["PsychopatzCore/UI/PsychopatzDebugHubWindow"] = function()
    return PsychopatzCore.DebugHub
end

local Types = require "PsychopatzCore/Inventory/PsychopatzItemTypeRegistry"
Types.load(nil)
Types.scan({ "Base.Apple", "Base.Nails" })
dofile(CLIENT
    .. "PsychopatzCore/UI/Inventory/PsychopatzItemTypeLedgerWindow.lua")

equal(registered.id, "psychopatz.inventory.itemTypeLedger",
    "debug hub ledger registration")
equal(type(registered.action), "function", "ledger launch action")
local snapshot = Types.getDebugSnapshot()
equal(snapshot.registeredCount, 2, "ledger registered count")
equal(snapshot.availableCount, 2, "ledger available count")
equal(snapshot.gapCount, 0, "ledger gap count")

print("psychopatz_item_type_ledger_smoke: PASS")
