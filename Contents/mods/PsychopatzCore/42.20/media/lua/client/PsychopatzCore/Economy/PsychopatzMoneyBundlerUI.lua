require "PsychopatzCore/Economy/PsychopatzMoneyBundler"
require "PsychopatzCore/Economy/PsychopatzMoneyBundlerAction"

PsychopatzCore = PsychopatzCore or {}
local MoneyBundler = PsychopatzCore.MoneyBundler

local function selectedItem(itemOrGroup)
    if instanceof(itemOrGroup, "InventoryItem") then
        return itemOrGroup
    end
    if itemOrGroup and itemOrGroup.items and itemOrGroup.items[1] then
        return itemOrGroup.items[1]
    end
    return nil
end

local function hasSelectedMoney(items)
    for _, itemOrGroup in ipairs(items) do
        local item = selectedItem(itemOrGroup)
        if item then
            local fullType = item:getFullType()
            if fullType == MoneyBundler.MONEY_TYPE
                or fullType == MoneyBundler.BUNDLE_TYPE
            then
                return true
            end
        end
    end
    return false
end

local function getBaseIcon(fullType)
    local manager
    local script
    if type(getScriptManager) == "function" then
        local ok
        ok, manager = pcall(getScriptManager)
        if not ok then manager = nil end
    end
    if not manager and ScriptManager then
        local ok
        ok, manager = pcall(function() return ScriptManager.instance end)
        if not ok then manager = nil end
    end
    if manager and type(manager.getItem) == "function" then
        script = manager:getItem(fullType)
    end
    if script and script:getIcon() then
        return getTexture("Item_" .. script:getIcon())
    end
    return nil
end

local function isBaseUnbundleOption(option)
    if not option then return false end

    local recipe = option.param1
    if recipe and type(recipe.getTranslationName) == "function"
        and recipe:getTranslationName() == MoneyBundler.UNBUNDLE_RECIPE
    then
        return true
    end
    if recipe and type(recipe.getName) == "function"
        and recipe:getName() == "Unbundle Money"
    then
        return true
    end

    local baseLabel = "Unbundle Money"
    if type(getText) == "function" then
        local translated = getText(MoneyBundler.UNBUNDLE_RECIPE)
        if translated and translated ~= MoneyBundler.UNBUNDLE_RECIPE then
            baseLabel = translated
        end
    end
    return option.name == baseLabel or option.name == "Unbundle Money"
end

local function removeBaseUnbundleOption(context)
    if not context or not context.options
        or type(context.removeOptionByName) ~= "function"
    then
        return
    end
    local function removeFromMenu(menu)
        if not menu or type(menu.options) ~= "table" then return end
        for index = #menu.options, 1, -1 do
            local option = menu.options[index]
            if option and option.subOption
                and type(menu.getSubMenu) == "function"
            then
                removeFromMenu(menu:getSubMenu(option.subOption))
            end
            if isBaseUnbundleOption(option)
                and type(menu.removeOptionByName) == "function"
            then
                menu:removeOptionByName(option.name)
            end
        end
    end
    removeFromMenu(context)
end

local function addMoneyBundlerContext(playerNum, context, items)
    if not hasSelectedMoney(items) then return end

    removeBaseUnbundleOption(context)

    local player = getSpecificPlayer(playerNum)
    if not player or type(player.getInventory) ~= "function" then return end

    local moneyCount, bundleCount = MoneyBundler.GetCounts(player:getInventory())
    if moneyCount < MoneyBundler.BUNDLE_VALUE and bundleCount == 0 then return end

    local root = context:addOption(
        MoneyBundler.Translate(
            "UI_PsychopatzInventory_Money_Bundler",
            "Money Bundler"
        ),
        player,
        nil
    )
    root.iconTexture = getBaseIcon(MoneyBundler.BUNDLE_TYPE)
        or getBaseIcon(MoneyBundler.MONEY_TYPE)

    local submenu = context:getNew(context)
    context:addSubMenu(root, submenu)

    if moneyCount >= MoneyBundler.BUNDLE_VALUE then
        local bundles = math.floor(moneyCount / MoneyBundler.BUNDLE_VALUE)
        local option = submenu:addOption(
            MoneyBundler.Translate(
                "UI_PsychopatzInventory_Money_BundleAll",
                "Bundle All ($%d -> %d bundles)",
                { moneyCount, bundles }
            ),
            player,
            MoneyBundler.Queue,
            MoneyBundler.BUNDLE_COMMAND
        )
        option.iconTexture = getBaseIcon(MoneyBundler.BUNDLE_TYPE)
    end

    if bundleCount > 0 then
        local money = bundleCount * MoneyBundler.BUNDLE_VALUE
        local option = submenu:addOption(
            MoneyBundler.Translate(
                "UI_PsychopatzInventory_Money_UnbundleAll",
                "Unbundle All (%d bundles -> $%d)",
                { bundleCount, money }
            ),
            player,
            MoneyBundler.Queue,
            MoneyBundler.UNBUNDLE_COMMAND
        )
        option.iconTexture = getBaseIcon(MoneyBundler.MONEY_TYPE)
    end
end

Events.OnFillInventoryObjectContextMenu.Add(addMoneyBundlerContext)

return MoneyBundler
