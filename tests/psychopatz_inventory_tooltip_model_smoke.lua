local CLIENT_ROOT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
local SHARED_ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = CLIENT_ROOT .. "?.lua;" .. SHARED_ROOT .. "?.lua;"
    .. package.path

PsychopatzCore = {}

local Model = require
    "PsychopatzCore/UI/Inventory/PsychopatzInventoryTooltipModel"

local capabilities = {
    food = true,
    clothing = true,
    fluid = true,
    condition = true,
    conditionAlways = true,
    drainable = true,
    ammo = true,
}

local model = Model.Build({
    fullType = "Base.Test",
    name = "Test",
    stateful = true,
    tooltipState = {
        condition = 3,
        conditionMax = 5,
        usedDelta = 0.5,
        ammoCount = 2,
        roundChambered = true,
        jammed = true,
        age = 0.5,
        hungChange = -0.2,
        thirstChange = -0.1,
        cooked = true,
        frozen = true,
        freezingTime = 50,
        dangerousUncooked = true,
        tainted = true,
        poison = true,
        poisonPower = 1,
        wetness = 0.2,
        bloodLevel = 0.3,
        dirtyness = 0.4,
        fluidAmount = 1,
        fluidCapacity = 2,
        fluidPrimaryType = "Water",
        fluids = {
            { type = "Water", amount = 0.5 },
            { type = "Bleach", amount = 0.5 },
        },
    },
}, nil, {
    translate = function(_, fallback) return fallback end,
    itemProfileProvider = function()
        return { capabilities = capabilities }
    end,
    foodProfileProvider = function() return {} end,
})

assert(model and model.title and model.title:find("Test", 1, true))
assert(#model.lines > 10)

local labels = {}
for _, line in ipairs(model.lines) do labels[line.label] = true end
assert(labels.Liquids, "fluid section missing")
assert(labels.Food, "food section missing")
assert(labels.Clothing, "clothing section missing")
assert(labels.Condition, "condition line missing")
assert(labels.Jammed, "ammo line missing")

print("psychopatz_inventory_tooltip_model_smoke: PASS")
