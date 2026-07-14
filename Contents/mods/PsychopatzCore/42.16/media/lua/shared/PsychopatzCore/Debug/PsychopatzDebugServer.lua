require "PsychopatzCore/00_PsychopatzCore_Init"
require "PsychopatzCore/Inventory/PsychopatzItemTransfer"

if PsychopatzCore._specialCommandHandlerInstalled then
    return PsychopatzCore
end
PsychopatzCore._specialCommandHandlerInstalled = true

local function addItems(player, itemType, quantity)
    local count = math.max(1, math.floor(tonumber(quantity) or 1))
    if not player or not getScriptManager():getItem(itemType) then
        return false
    end
    return PsychopatzCore.ItemTransfer.GiveToPlayer(player, itemType, count) ~= nil
end

local function heal(player)
    local bodyDamage = player:getBodyDamage()
    if bodyDamage and bodyDamage.RestoreToFullHealth then
        bodyDamage:RestoreToFullHealth()
    end
end

local function resetStats(player)
    if player.setStatsHunger then
        player:setStatsHunger(0.0)
    else
        local stats = player:getStats()
        if stats and stats.setHunger then
            stats:setHunger(0.0)
        end
    end
    if player.setStatsThirst then player:setStatsThirst(0.0) end
    if player.setStatsFatigue then player:setStatsFatigue(0.0) end

    local bodyDamage = player:getBodyDamage()
    if bodyDamage and bodyDamage.setHealthFromFoodTimer then
        bodyDamage:setHealthFromFoodTimer(0.0)
    end
end

local function onPsychopatzCommand(module, command, player, args)
    if module ~= PsychopatzCore.COMMAND_MODULE or command ~= "GrantPowers" then
        return
    end
    if not PsychopatzCore.IsOwner(player) then
        return
    end

    args = args or {}
    if args.doHeal then heal(player) end
    if args.doStats then resetStats(player) end
    if args.doSpawn then addItems(player, tostring(args.itemID or "Base.Katana"), args.quantity) end
    if args.doMoney then addItems(player, "Base.MoneyBundle", args.qtyMoney or 100) end
    if args.doWalkie then addItems(player, "Base.WalkieTalkie5", args.qtyWalkie or 1) end
end

Events.OnClientCommand.Add(onPsychopatzCommand)

return PsychopatzCore
