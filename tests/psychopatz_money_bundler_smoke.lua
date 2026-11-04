local SHARED_ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = SHARED_ROOT .. "?.lua;" .. package.path

local item = { recipe = "UnbundleMoney" }
function item:getDoubleClickRecipe() return self.recipe end
function item:setDoubleClickRecipe(value) self.recipe = value end

local manager = {}
function manager:getItem(fullType)
    if fullType == "Base.MoneyBundle" then return item end
end
function getScriptManager() return manager end

PsychopatzCore = {
    Currency = {
        MONEY_TYPE = "Base.Money",
        BUNDLE_TYPE = "Base.MoneyBundle",
        BUNDLE_VALUE = 100,
    },
}

local MoneyBundler = require "PsychopatzCore/Economy/PsychopatzMoneyBundler"
assert(item.recipe == "", "vanilla unbundle recipe disabled")

item.recipe = "OtherModRecipe"
assert(MoneyBundler.DisableVanillaUnbundle() == true,
    "custom recipe compatibility check")
assert(item.recipe == "OtherModRecipe", "custom recipe preserved")

local SERVER_ROOT =
    "Contents/mods/PsychopatzCore/42.20/media/lua/server/"
package.path = SERVER_ROOT .. "?.lua;" .. package.path

package.preload["PsychopatzCore/00_PsychopatzCore_Init"] =
    function() return PsychopatzCore end
package.preload["PsychopatzCore/Economy/PsychopatzCurrencyServer"] =
    function() return PsychopatzCore.Currency end

local onClientCommand
Events = {
    OnClientCommand = {
        Add = function(fn) onClientCommand = fn end,
    },
}
local originalPrint = print
local messages = {}
print = function(message)
    messages[#messages + 1] = tostring(message)
end

package.loaded[
    "PsychopatzCore/Economy/PsychopatzMoneyBundlerServer"
] = nil
require "PsychopatzCore/Economy/PsychopatzMoneyBundlerServer"
assert(type(onClientCommand) == "function",
    "money bundler server command hook registered")

local player = {
    getInventory = function() return nil end,
}
onClientCommand(
    "PsychopatzCore",
    "ActorProjectionRequest",
    player,
    {}
)
assert(#messages == 0,
    "money bundler logged unrelated PsychopatzCore command")

onClientCommand(
    "PsychopatzCore",
    MoneyBundler.BUNDLE_COMMAND,
    player,
    {}
)
assert(#messages == 1
    and string.find(messages[1], "BundleMoney", 1, true),
    "money bundler did not log its own command")

print = originalPrint
print("psychopatz money bundler smoke: ok")
