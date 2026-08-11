local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local Material = require(
    "PsychopatzCore/Inventory/PsychopatzMaterialTransaction"
)

local function store(initial, failRemove)
    local value = initial
    local output = {}
    function output:count() return value end
    function output:remove(_, quantity)
        if failRemove then return false, "forced_remove_failure" end
        if value < quantity then return false, "insufficient_quantity" end
        value = value - quantity
        return true, {{ quantity = quantity }}
    end
    function output:restoreRemoved(removed)
        for _, row in ipairs(removed or {}) do value = value + row.quantity end
        return true
    end
    function output:value() return value end
    return output
end

local player = store(1)
local stockpile = store(2)
local sources = {
    { id = "stockpile", priority = 2, store = stockpile },
    { id = "player", priority = 1, store = player },
}
local recipe = { costs = {
    { fullType = "Base.Money", amount = 2 },
    { fullType = "Base.Money", amount = 1 },
} }
local quote = Material.Quote(recipe, sources)
equal(quote.affordable, true, "combined source affordability")
equal(quote.costs[1].required, 3, "duplicate recipe rows aggregate")
equal(quote.costs[1].allocations[1].sourceId, "player",
    "source priority")
equal(quote.costs[1].allocations[1].quantity, 1, "player allocation")
equal(quote.costs[1].allocations[2].quantity, 2, "stockpile allocation")

local ok = Material.Consume(recipe, sources)
equal(ok, true, "multi-source consume")
equal(player:value(), 0, "player consumed first")
equal(stockpile:value(), 0, "stockpile consumed remainder")

local rollbackPlayer = store(1)
local failingStockpile = store(2, true)
local failed, reason, failedQuote = Material.Consume(recipe, {
    { id = "player", priority = 1, store = rollbackPlayer },
    { id = "stockpile", priority = 2, store = failingStockpile },
})
equal(failed, false, "later source failure")
equal(reason, "forced_remove_failure", "failure reason")
equal(failedQuote.rollbackOK, true, "rollback status")
equal(rollbackPlayer:value(), 1, "earlier source rolled back")
equal(failingStockpile:value(), 2, "failed source unchanged")

local insufficient = Material.Quote(recipe, {
    { id = "player", store = store(1) },
})
equal(insufficient.affordable, false, "insufficient quote")
equal(insufficient.costs[1].missing, 2, "missing quantity")

print("psychopatz_material_transaction_smoke: PASS")
