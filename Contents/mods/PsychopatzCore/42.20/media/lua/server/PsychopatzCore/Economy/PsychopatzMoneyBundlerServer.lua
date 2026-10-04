require "PsychopatzCore/00_PsychopatzCore_Init"
require "PsychopatzCore/Economy/PsychopatzCurrencyServer"
require "PsychopatzCore/Economy/PsychopatzMoneyBundler"

PsychopatzCore = PsychopatzCore or {}
local Core = PsychopatzCore
local MoneyBundler = Core.MoneyBundler

local function fail(player, command, reason)
    local detail = tostring(reason or "physical_add_failed")
    local message = reason == "rollback_failed"
        and "Money conversion aborted; rollback could not be verified."
        or MoneyBundler.Translate(
            "UI_PsychopatzInventory_Money_Failed",
            "Money conversion failed; inventory restored."
        )
    print("[PsychopatzCore][MoneyBundler][ERROR] command="
        .. tostring(command or "unknown") .. " reason=" .. detail)
    MoneyBundler.Notify(
        player,
        message .. " [" .. detail .. "]",
        true
    )
end

local function bundleMoney(player)
    local inventory = player and player:getInventory() or nil
    local Currency = Core.Currency
    if not inventory or not Currency then return end

    local snapshot = Currency.Snapshot(inventory, { recursive = true })
    local bundles = math.floor(snapshot.loose / Currency.BUNDLE_VALUE)
    if bundles < 1 then
        MoneyBundler.Notify(
            player,
            MoneyBundler.Translate(
                "UI_PsychopatzInventory_Money_Need100",
                "Need at least 100 loose money."
            ),
            true
        )
        return
    end
    local ok, reason, details = Currency.BundleLoose(inventory)
    if not ok then
        fail(player, MoneyBundler.BUNDLE_COMMAND, reason)
        return
    end

    MoneyBundler.Notify(
        player,
        MoneyBundler.Translate(
            "UI_PsychopatzInventory_Money_Bundled",
            "Bundled $%d into %d bundles",
            { bundles * Currency.BUNDLE_VALUE, bundles }
        )
    )
    print("[PsychopatzCore][MoneyBundler][INFO] command="
        .. MoneyBundler.BUNDLE_COMMAND .. " complete bundles=" .. tostring(bundles)
        .. " physicalReplacementRecords="
        .. tostring(details and details.added and #details.added or 0))
end

local function unbundleMoney(player)
    local inventory = player and player:getInventory() or nil
    local Currency = Core.Currency
    if not inventory or not Currency then return end

    local snapshot = Currency.Snapshot(inventory, { recursive = true })
    local bundleCount = snapshot.bundles
    if bundleCount < 1 then return end

    local ok, reason, details = Currency.Unbundle(inventory)
    if not ok then
        fail(player, MoneyBundler.UNBUNDLE_COMMAND, reason)
        return
    end

    MoneyBundler.Notify(
        player,
        MoneyBundler.Translate(
            "UI_PsychopatzInventory_Money_Unbundled",
            "Unbundled %d bundles into $%d",
            { bundleCount, bundleCount * Currency.BUNDLE_VALUE }
        )
    )
    print("[PsychopatzCore][MoneyBundler][INFO] command="
        .. MoneyBundler.UNBUNDLE_COMMAND .. " complete bundles="
        .. tostring(bundleCount) .. " money="
        .. tostring(bundleCount * Currency.BUNDLE_VALUE)
        .. " physicalReplacementRecords="
        .. tostring(details and details.added and #details.added or 0))
end

local function onClientCommand(module, command, player)
    if module ~= MoneyBundler.COMMAND_MODULE or not player then return end
    print("[PsychopatzCore][MoneyBundler][INFO] command="
        .. tostring(command or "unknown") .. " received")
    if command == MoneyBundler.BUNDLE_COMMAND then
        bundleMoney(player)
    elseif command == MoneyBundler.UNBUNDLE_COMMAND then
        unbundleMoney(player)
    end
end

if Events and Events.OnClientCommand and not Core.moneyBundlerServerRegistered then
    Events.OnClientCommand.Add(onClientCommand)
    Core.moneyBundlerServerRegistered = true
end

return MoneyBundler
