PsychopatzCore = PsychopatzCore or {}

local Core = PsychopatzCore
local MoneyBundler = Core.MoneyBundler or {}
Core.MoneyBundler = MoneyBundler
local Currency = Core.Currency

MoneyBundler.MONEY_TYPE = Currency and Currency.MONEY_TYPE or "Base.Money"
MoneyBundler.BUNDLE_TYPE = Currency and Currency.BUNDLE_TYPE or "Base.MoneyBundle"
MoneyBundler.BUNDLE_VALUE = Currency and Currency.BUNDLE_VALUE or 100
MoneyBundler.UNBUNDLE_RECIPE = "UnbundleMoney"
MoneyBundler.COMMAND_MODULE = Core.COMMAND_MODULE or "PsychopatzCore"
MoneyBundler.BUNDLE_COMMAND = "BundleMoney"
MoneyBundler.UNBUNDLE_COMMAND = "UnbundleMoney"
-- ISBaseTimedAction maxTime is measured in simulation ticks. Thirty ticks is
-- the one-second target while still allowing the vanilla craft animation and
-- its sound hooks to run.
MoneyBundler.DURATION = 30

function MoneyBundler.GetCount(inventory, fullType)
    if Currency and type(Currency.GetCount) == "function" then
        return Currency.GetCount(inventory, fullType, { recursive = true })
    end
    if not inventory or type(inventory.getItemsFromType) ~= "function" then
        return 0
    end
    local items = inventory:getItemsFromType(fullType, true)
    return items and items:size() or 0
end

function MoneyBundler.GetCounts(inventory)
    return MoneyBundler.GetCount(inventory, MoneyBundler.MONEY_TYPE),
        MoneyBundler.GetCount(inventory, MoneyBundler.BUNDLE_TYPE)
end

function MoneyBundler.Translate(key, fallback, args)
    local translation = Core.Translation
    if translation and type(translation.Format) == "function" then
        return translation.Format("Inventory", key, fallback, args)
    end
    if type(args) == "table" then
        local ok, value = pcall(
            string.format,
            fallback,
            args[1], args[2], args[3], args[4]
        )
        if ok then return value end
    end
    return fallback or key
end

local function disableVanillaUnbundle()
    if type(getScriptManager) ~= "function" then return false end
    local ok, manager = pcall(getScriptManager)
    if not ok or not manager or type(manager.getItem) ~= "function" then
        return false
    end
    local itemOK, item = pcall(manager.getItem, manager, MoneyBundler.BUNDLE_TYPE)
    if not itemOK or not item then return false end

    local getRecipe = item.getDoubleClickRecipe
    local setRecipe = item.setDoubleClickRecipe
    if type(getRecipe) ~= "function" or type(setRecipe) ~= "function" then
        return false
    end
    local readOK, recipe = pcall(getRecipe, item)
    if not readOK then return false end
    recipe = tostring(recipe or "")
    if recipe ~= "" and recipe ~= MoneyBundler.UNBUNDLE_RECIPE then
        print("[PsychopatzCore][MoneyBundler][WARN] preserving custom "
            .. "MoneyBundle double-click recipe=" .. recipe)
        return true
    end
    local writeOK = pcall(setRecipe, item, "")
    if not writeOK then return false end
    local verifyOK, current = pcall(getRecipe, item)
    if verifyOK and tostring(current or "") == "" then
        print("[PsychopatzCore][MoneyBundler][INFO] vanilla MoneyBundle "
            .. "double-click unbundle disabled")
        return true
    end
    return false
end

MoneyBundler.DisableVanillaUnbundle = disableVanillaUnbundle
local vanillaDisabled = disableVanillaUnbundle()
if not vanillaDisabled and Events then
    local function retryVanillaDisable(eventName)
        local event = Events[eventName]
        if not event or type(event.Add) ~= "function" then return end
        local callback
        callback = function()
            if disableVanillaUnbundle()
                and type(event.Remove) == "function"
            then
                pcall(event.Remove, callback)
            end
        end
        pcall(event.Add, callback)
    end
    retryVanillaDisable("OnGameBoot")
    retryVanillaDisable("OnGameStart")
end

function MoneyBundler.Notify(player, message, isError)
    if not player or type(player.setHaloNote) ~= "function" then return end
    if isError then
        player:setHaloNote(message, 255, 0, 0, 300)
    else
        player:setHaloNote(message, 0, 255, 0, 300)
    end
end

return MoneyBundler
