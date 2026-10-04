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

print("psychopatz money bundler smoke: ok")
