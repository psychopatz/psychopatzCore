local SHARED_ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = SHARED_ROOT .. "?.lua;" .. package.path

local function assertEqual(actual, expected, message)
    assert(actual == expected, message .. " (expected " .. tostring(expected)
        .. ", got " .. tostring(actual) .. ")")
end

local function makeEvent()
    local event = { listeners = {} }
    function event.Add(callback)
        event.listeners[#event.listeners + 1] = callback
    end
    function event.Remove(callback)
        for index = #event.listeners, 1, -1 do
            if event.listeners[index] == callback then
                table.remove(event.listeners, index)
            end
        end
    end
    return event
end

local boot = makeEvent()
local start = makeEvent()
local createPlayer = makeEvent()
Events = {
    OnGameBoot = boot,
    OnGameStart = start,
    OnCreatePlayer = createPlayer,
}

local scriptItems = {
    ["Base.Money"] = { displayCategory = "Junk" },
    ["Base.MoneyBundle"] = { displayCategory = "Junk" },
    ["Base.OtherModMoney"] = { displayCategory = "OtherModCategory" },
}
for _, item in pairs(scriptItems) do
    function item:getDisplayCategory() return self.displayCategory end
    function item:DoParam(value)
        local category = string.match(value, "^DisplayCategory=(.+)$")
        if category then self.displayCategory = category end
    end
end

local manager = {}
function manager:getItem(fullType)
    return scriptItems[fullType]
end
function getScriptManager()
    return manager
end

local function physical(fullType, category)
    local item = { fullType = fullType, displayCategory = category }
    function item:getFullType() return self.fullType end
    function item:getDisplayCategory() return self.displayCategory end
    function item:setDisplayCategory(value) self.displayCategory = value end
    return item
end

PsychopatzCore = {}
local Category = require "PsychopatzCore/Compatibility/PsychopatzCurrencyCategory"

assertEqual(scriptItems["Base.Money"].displayCategory, "Currency",
    "money script category")
assertEqual(scriptItems["Base.MoneyBundle"].displayCategory, "Currency",
    "bundle script category")
assertEqual(#boot.listeners, 1, "category boot binding")
assertEqual(#start.listeners, 1, "category start binding")
assertEqual(#createPlayer.listeners, 1, "category player binding")

local money = physical("Base.Money", "Junk")
local bundle = physical("Base.MoneyBundle", "Junk")
local custom = physical("Base.Money", "OtherModCategory")
assertEqual(Category.PatchItem(money), true, "money instance category")
assertEqual(Category.PatchItem(bundle), true, "bundle instance category")
assertEqual(Category.PatchItem(custom), false, "custom category preserved")
assertEqual(money.displayCategory, "Currency", "money instance readback")
assertEqual(bundle.displayCategory, "Currency", "bundle instance readback")
assertEqual(custom.displayCategory, "OtherModCategory",
    "other mod category preserved")

local inventory = { items = { money } }
function inventory:getItems() return self.items end
local player = {}
function player:getInventory() return inventory end
function getPlayer() return player end
assertEqual(Category.Apply("instance_scan"), true,
    "instance scan without nested-container methods")

scriptItems["Base.MoneyBundle"].displayCategory = "OtherModCategory"
Category.Apply("compatibility_test")
assertEqual(scriptItems["Base.MoneyBundle"].displayCategory,
    "OtherModCategory", "script conflict preserved")
assertEqual(Category.GetStatus().conflicts["Base.MoneyBundle"],
    "OtherModCategory", "script conflict reported")

print("psychopatz currency category smoke: ok")
