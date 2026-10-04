local SHARED_ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = SHARED_ROOT .. "?.lua;" .. package.path

local function assertEqual(actual, expected, message)
    assert(actual == expected, message .. " (expected " .. tostring(expected)
        .. ", got " .. tostring(actual) .. ")")
end

local function javaList(values)
    local list = { values = values }
    function list:size()
        return #self.values
    end
    function list:get(index)
        return self.values[index + 1]
    end
    return list
end

local function item(fullType, count, nested)
    return {
        getFullType = function() return fullType end,
        getCount = function() return count end,
        getItemContainer = function() return nested end,
    }
end

local nested = {
    getItems = function()
        return javaList({ item("Base.Money", 7) })
    end,
}
local root = {
    getItems = function()
        return javaList({
            item("Base.Money", 2),
            item("Base.MoneyBundle", 3),
            item("Base.Bag", 1, nested),
        })
    end,
}

PsychopatzCore = {}
local Currency = require "PsychopatzCore/Economy/PsychopatzCurrency"

local direct = Currency.Snapshot(root, { recursive = false })
assertEqual(direct.units, 302, "direct currency value")
assertEqual(direct.loose, 2, "direct loose currency count")
assertEqual(direct.bundles, 3, "direct bundle count")
assertEqual(direct.itemCount, 2, "direct currency item count")

local recursive = Currency.Snapshot(root, { recursive = true })
assertEqual(recursive.units, 309, "recursive currency value")
assertEqual(recursive.loose, 9, "recursive loose currency count")
assertEqual(recursive.bundles, 3, "recursive bundle count")
assertEqual(recursive.itemCount, 3, "recursive currency item count")

local bundles, loose = Currency.NormalizeUnits(250)
assertEqual(bundles, 2, "currency normalization bundles")
assertEqual(loose, 50, "currency normalization loose remainder")
local specs, specBundles, specLoose = Currency.CanonicalSpecs(10050, "root")
assertEqual(specBundles, 100, "canonical bundle count")
assertEqual(specLoose, 50, "canonical loose count")
assertEqual(#specs, 2, "canonical physical spec count")
assertEqual(specs[1].type, Currency.BUNDLE_TYPE, "canonical bundle type")
assertEqual(specs[1].stack, 100, "canonical bundle stack")
assertEqual(specs[1].container, "root", "canonical bundle container")
assertEqual(specs[2].type, Currency.MONEY_TYPE, "canonical money type")
assertEqual(specs[2].stack, 50, "canonical money stack")
assertEqual(Currency.ValueFor("Base.MoneyBundle", 4), 400,
    "bundle value conversion")

local formatted = Currency.FormatSnapshot(recursive)
assertEqual(formatted.units, 309, "formatted currency value")
assertEqual(formatted.bundles, 3, "formatted bundle count")
assertEqual(formatted.loose, 9, "formatted loose remainder")
assertEqual(formatted.physicalLoose, 9, "formatted physical loose count")
assertEqual(formatted.physicalBundles, 3,
    "formatted physical bundle count")

print("psychopatz currency smoke: ok")
