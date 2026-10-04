PsychopatzCore = PsychopatzCore or {}

local Core = PsychopatzCore
local Currency = Core.Currency or {}
Core.Currency = Currency

Currency.MONEY_TYPE = Currency.MONEY_TYPE or "Base.Money"
Currency.BUNDLE_TYPE = Currency.BUNDLE_TYPE or "Base.MoneyBundle"
Currency.BUNDLE_VALUE = Currency.BUNDLE_VALUE or 100

local function call(object, methodName, fallback, ...)
    local method = object and object[methodName]
    if type(method) ~= "function" then return fallback end
    local ok, value = pcall(method, object, ...)
    if not ok or value == nil then return fallback end
    return value
end

local function javaListItems(list)
    if not list or type(list.size) ~= "function"
        or type(list.get) ~= "function"
    then
        return {}
    end
    local output = {}
    local size = tonumber(call(list, "size", 0)) or 0
    for index = 0, size - 1 do
        local item = call(list, "get", nil, index)
        if item then output[#output + 1] = item end
    end
    return output
end

local function itemType(item)
    return tostring(call(item, "getFullType", "") or "")
end

local function itemQuantity(item)
    local quantity = call(item, "getCount", 1)
    quantity = tonumber(quantity)
    if not quantity or quantity < 1 then return 1 end
    return math.max(1, math.floor(quantity))
end

local function isContainer(value)
    return value and type(value.getItems) == "function"
end

function Currency.IsType(fullType)
    fullType = tostring(fullType or "")
    return fullType == Currency.MONEY_TYPE
        or fullType == Currency.BUNDLE_TYPE
end

function Currency.UnitValue(fullType)
    fullType = tostring(fullType or "")
    if fullType == Currency.MONEY_TYPE then return 1 end
    if fullType == Currency.BUNDLE_TYPE then return Currency.BUNDLE_VALUE end
    return 0
end

function Currency.ItemQuantity(item)
    return itemQuantity(item)
end

function Currency.NormalizeUnits(units)
    units = math.max(0, math.floor(tonumber(units) or 0))
    local bundleValue = math.max(1, math.floor(
        tonumber(Currency.BUNDLE_VALUE) or 100))
    return math.floor(units / bundleValue), units % bundleValue
end

-- Canonical physical representation shared by native and compact inventories.
-- Currency is never persisted as an abstract balance: one container may have
-- at most one bundle spec and one loose-money spec for a requested total.
function Currency.CanonicalSpecs(units, containerID)
    local bundles, loose = Currency.NormalizeUnits(units)
    local specs = {}

    if bundles > 0 then
        specs[#specs + 1] = {
            type = Currency.BUNDLE_TYPE,
            stack = bundles,
        }
    end

    if loose > 0 then
        specs[#specs + 1] = {
            type = Currency.MONEY_TYPE,
            stack = loose,
        }
    end

    if containerID ~= nil then
        for index = 1, #specs do
            specs[index].container = containerID
        end
    end

    return specs, bundles, loose
end

function Currency.ValueFor(fullType, quantity)
    return Currency.UnitValue(fullType)
        * math.max(0, math.floor(tonumber(quantity) or 0))
end

local function addSnapshotItem(snapshot, item, fullType, quantity)
    local value = Currency.ValueFor(fullType, quantity)
    if value <= 0 then return end
    snapshot.units = snapshot.units + value
    if fullType == Currency.MONEY_TYPE then
        snapshot.loose = snapshot.loose + quantity
    else
        snapshot.bundles = snapshot.bundles + quantity
    end
    snapshot.itemCount = snapshot.itemCount + 1
    if snapshot.items then
        snapshot.items[#snapshot.items + 1] = {
            item = item,
            fullType = fullType,
            quantity = quantity,
            container = call(item, "getContainer", nil),
        }
    end
end

function Currency.Snapshot(containerOrInventory, options)
    options = type(options) == "table" and options or {}
    local snapshot = {
        units = 0,
        loose = 0,
        bundles = 0,
        itemCount = 0,
    }
    if options.includeItems == true then snapshot.items = {} end
    if not isContainer(containerOrInventory) then return snapshot end

    local recursive = options.recursive == true
    local maxDepth = math.max(0, math.floor(
        tonumber(options.maxDepth) or 8))
    local visited = {}
    local function visit(container, depth)
        if not container or depth > maxDepth or visited[container] then return end
        visited[container] = true
        local items = javaListItems(call(container, "getItems", nil))
        for index = 1, #items do
            local item = items[index]
            local fullType = itemType(item)
            if Currency.IsType(fullType) then
                addSnapshotItem(snapshot, item, fullType, itemQuantity(item))
            end
            if recursive then
                local nested = call(item, "getItemContainer", nil)
                    or call(item, "getInventory", nil)
                if isContainer(nested) then visit(nested, depth + 1) end
            end
        end
    end
    visit(containerOrInventory, 0)
    return snapshot
end

function Currency.GetCount(inventory, fullType, options)
    local snapshot = Currency.Snapshot(inventory, options)
    fullType = tostring(fullType or "")
    if fullType == Currency.MONEY_TYPE then return snapshot.loose end
    if fullType == Currency.BUNDLE_TYPE then return snapshot.bundles end
    return 0
end

function Currency.GetCounts(inventory, options)
    return Currency.GetCount(inventory, Currency.MONEY_TYPE, options),
        Currency.GetCount(inventory, Currency.BUNDLE_TYPE, options)
end

function Currency.FormatSnapshot(snapshot)
    snapshot = type(snapshot) == "table" and snapshot or {}
    local bundles, loose = Currency.NormalizeUnits(snapshot.units)
    return {
        units = math.max(0, math.floor(tonumber(snapshot.units) or 0)),
        loose = loose,
        bundles = bundles,
        physicalLoose = math.max(0, math.floor(tonumber(snapshot.loose) or 0)),
        physicalBundles = math.max(0, math.floor(tonumber(snapshot.bundles) or 0)),
        itemCount = math.max(0, math.floor(tonumber(snapshot.itemCount) or 0)),
    }
end

pcall(require, "PsychopatzCore/Economy/PsychopatzCurrencyDiagnostics")

return Currency
