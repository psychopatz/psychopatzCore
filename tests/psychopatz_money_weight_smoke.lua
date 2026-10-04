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
local tick = makeEvent()
Events = { OnGameBoot = boot, OnGameStart = start, OnTick = tick }

local items = {
    ["Base.Money"] = { weight = 0.5 },
    ["Base.MoneyBundle"] = { weight = 5.0 },
    ["Base.Other"] = { weight = 1.25 },
}
for _, item in pairs(items) do
    function item:setActualWeight(weight)
        self.weight = weight
    end
    function item:getActualWeight()
        return self.weight
    end
end

local manager = {}
function manager:getItem(fullType)
    return items[fullType]
end
function getScriptManager()
    return manager
end

PsychopatzCore = {}
local MoneyWeight = require "PsychopatzCore/Compatibility/PsychopatzMoneyWeight"

assertEqual(items["Base.Money"].weight, 0.0, "money weight at shared load")
assertEqual(items["Base.MoneyBundle"].weight, 0.0,
    "bundle weight at shared load")
assertEqual(items["Base.Other"].weight, 1.25, "unrelated item changed")
assertEqual(#boot.listeners, 1, "OnGameBoot binding")
assertEqual(#start.listeners, 1, "OnGameStart binding")

items["Base.Money"].weight = 3.0
boot.listeners[1]()
assertEqual(items["Base.Money"].weight, 0.0, "boot reconciliation")
assertEqual(#boot.listeners, 0, "boot callback removed")

items["Base.MoneyBundle"].weight = 7.0
start.listeners[1]()
assertEqual(items["Base.MoneyBundle"].weight, 0.0,
    "start reconciliation")
assertEqual(#start.listeners, 0, "start callback removed")
assertEqual(#tick.listeners, 1, "deferred tick reconciliation binding")

items["Base.Money"].weight = 9.0
tick.listeners[1]()
assertEqual(items["Base.Money"].weight, 0.0,
    "deferred tick reconciliation")
assertEqual(#tick.listeners, 0, "deferred tick callback removed")

local status = MoneyWeight.GetStatus()
assertEqual(status.applied, true, "patch status")
assertEqual(status.items["Base.Money"].verified, true,
    "money readback")
assertEqual(status.items["Base.MoneyBundle"].verified, true,
    "bundle readback")

print("psychopatz money weight smoke: ok")
