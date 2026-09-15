local DisplayState = require
    "PsychopatzCore/Inventory/PsychopatzInventoryDisplayState"
local Portable = require "PsychopatzCore/Inventory/PsychopatzPortableItemState"
local Profiles = require "PsychopatzCore/Inventory/PsychopatzItemTypeProfile"

local Model = {}
local Translation = PsychopatzCore and PsychopatzCore.Translation

local function call(object, method, ...)
    local value
    local ok
    if not object or type(object[method]) ~= "function" then return nil end
    ok, value = pcall(object[method], object, ...)
    return ok and value or nil
end

local function finite(value)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge
        or value == -math.huge
    then
        return nil
    end
    return value
end

local function text(options, key, fallback)
    local value
    local ok
    if options and type(options.translate) == "function" then
        ok, value = pcall(options.translate, key, fallback)
        if ok and value and value ~= "" then return tostring(value) end
    end
    if Translation and Translation.IsCoreKey
        and Translation.IsCoreKey(key)
    then
        return Translation.GetKey(key, fallback)
    end
    value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function numberText(value, decimals)
    value = finite(value)
    if value == nil then return "?" end
    decimals = math.max(0, math.floor(tonumber(decimals) or 0))
    if decimals == 0 then return string.format("%.0f", value) end
    return string.format("%." .. tostring(decimals) .. "f", value)
end

local function percentText(value)
    value = finite(value)
    if value == nil then return "?" end
    return numberText(value * 100, 0) .. "%"
end

local function scaledText(value)
    value = finite(value)
    if value == nil then return "?" end
    return numberText(value * 100, 0)
end

local function clampProgress(value)
    value = finite(value)
    if value == nil then return nil end
    return math.max(0, math.min(1, value))
end

local function addLine(lines, label, value, progress, tone)
    lines[#lines + 1] = {
        label = tostring(label or ""), value = tostring(value or ""),
        progress = clampProgress(progress), tone = tone,
    }
end

local function addSection(lines, label)
    lines[#lines + 1] = { section = true, label = tostring(label or "") }
end

local function fluidName(value)
    local name = tostring(value or "")
    local translated
    local fluid
    if name == "" then return "" end
    translated = getText and getText("Fluid_Name_" .. name) or nil
    if translated and translated ~= "" and translated ~= "Fluid_Name_" .. name then
        return translated
    end
    if rawget(_G, "Fluid") and type(Fluid.Get) == "function" then
        local ok
        ok, fluid = pcall(Fluid.Get, name)
        if ok and fluid then
            translated = call(fluid, "getUiName")
            if translated and translated ~= "" then return tostring(translated) end
        end
    end
    return name:gsub("([a-z])([A-Z])", "%1 %2")
end

local function metadataFor(row, fullType, options)
    local metadata
    local ok
    if options and type(options.metadataProvider) == "function" then
        ok, metadata = pcall(options.metadataProvider, fullType, row)
        if ok and type(metadata) == "table" then return metadata end
    end
    return type(row and row.metadata) == "table" and row.metadata or {}
end

local function foodProfileFor(fullType, options)
    local profile
    local ok
    if options and type(options.foodProfileProvider) == "function" then
        ok, profile = pcall(options.foodProfileProvider, fullType)
        if ok and type(profile) == "table" then return profile end
    end
    return {}
end

local function typeProfileFor(row, fullType, options)
    local profile
    local ok
    if row and row.nativeItem then return Profiles.ForRow(row) end
    if row and (row.itemProfile or row.capabilities) then
        return Profiles.ForRow(row)
    end
    if options and type(options.itemProfileProvider) == "function" then
        ok, profile = pcall(options.itemProfileProvider, fullType, row)
        if ok and type(profile) == "table" then
            return Profiles.Normalize(fullType, profile)
        end
    end
    return Profiles.ForRow(row)
end

local function nativeName(item, player)
    local value
    if not item then return nil end
    value = player and call(item, "getName", player) or nil
    value = value or call(item, "getName")
    value = value or (player and call(item, "getDisplayName", player))
    return value or call(item, "getDisplayName")
end

local function titleFor(row, state, status, name, options, capabilities)
    local base = tostring(name or row and row.name or row and row.fullType or "Item")
    local compact = not (row and row.nativeItem)
    local primary = state.fluidPrimaryType or state.fluidType
    local fluids = type(state.fluids) == "table" and state.fluids or {}
    local prefix = {}
    local custom = state.customName
    if custom and tostring(custom) ~= "" then base = tostring(custom) end
    if capabilities.fluid and primary and compact then
        base = fluidName(primary) .. " (" .. base .. ")"
    elseif capabilities.fluid and #fluids > 1 and compact then
        base = text(options, "UI_PsychopatzInventory_Tooltip_MixedLiquids",
            "Mixed Liquids") .. " (" .. base .. ")"
    end
    if compact and status then
        if status.rotten then prefix[#prefix + 1] = text(options,
            "Tooltip_food_Rotten", "Rotten")
        elseif status.stale then prefix[#prefix + 1] = text(options,
            "Tooltip_food_Stale", "Stale")
        elseif status.fresh and state.age ~= nil then prefix[#prefix + 1] = text(
            options, "Tooltip_food_Fresh", "Fresh") end
        if state.burnt == true then prefix[#prefix + 1] = text(options,
            "Tooltip_food_Burnt", "Burnt") end
        if state.cooked == true and not state.burnt then prefix[#prefix + 1] = text(
            options, "Tooltip_food_Cooked", "Cooked") end
        if state.frozen == true then prefix[#prefix + 1] = text(options,
            "Tooltip_food_Frozen", "Frozen") end
    end
    if #prefix > 0 then return table.concat(prefix, " ") .. " " .. base end
    return base
end

function Model.StateSignature(row, player, includeRowMetrics, options)
    local state = DisplayState.StateForRow(row, player, { fullFluid = false })
    local profile = typeProfileFor(row, row and row.fullType or "", options)
    local weight = row and (row.unitWeight ~= nil and row.unitWeight or row.weight) or nil
    local parts = {
        tostring(row and row.fullType or ""),
        "name=" .. tostring(row and row.name or ""),
        "capabilities=" .. Profiles.Signature(profile),
    }
    if includeRowMetrics ~= false then
        parts[#parts + 1] = "stack=" .. tostring(row and (row.stack or row.quantity) or "")
        parts[#parts + 1] = "weight=" .. tostring(weight or "")
        parts[#parts + 1] = "conditionMax=" .. tostring(row and row.conditionMax or "")
    end
    for index = 1, #DisplayState.Fields do
        local field = DisplayState.Fields[index]
        if state[field] ~= nil then
            parts[#parts + 1] = field .. "=" .. tostring(state[field])
        end
    end
    if type(state.fluids) == "table" then
        for index = 1, math.min(DisplayState.MaxFluids, #state.fluids) do
            local entry = state.fluids[index]
            parts[#parts + 1] = "fluid=" .. tostring(entry.type)
                .. ":" .. tostring(entry.amount)
        end
    end
    if row and row.nativeItem and call(row.nativeItem, "getFluidContainer") then
        parts[#parts + 1] = "nativeFluid=" .. tostring(row.id or "")
    end
    return table.concat(parts, "\030")
end

function Model.Build(row, player, options)
    local state
    local stateKnown
    local fullType
    local native
    local metadata
    local profile
    local capabilities
    local foodProfile
    local status
    local isFoodItem
    local condition
    local conditionMax
    local amount
    local capacity
    local fluids
    local primary
    local model
    local stack
    local displayWeight
    options = type(options) == "table" and options or {}
    if type(row) ~= "table" or row.restricted == true
        or row.groupHeader == true and not row.fullType
    then
        return nil
    end

    fullType = tostring(row.fullType or "")
    native = row.nativeItem
    state, stateKnown = DisplayState.StateForRow(row, player, {
        fullFluid = options.fullFluid ~= false,
    })
    metadata = metadataFor(row, fullType, options)
    profile = typeProfileFor(row, fullType, options)
    capabilities = profile and profile.capabilities or {}
    foodProfile = foodProfileFor(fullType, options)
    isFoodItem = capabilities.food == true or state.age ~= nil
        or state.hungChange ~= nil or state.thirstChange ~= nil
    if isFoodItem then status = Portable.GetFoodStatus(state, foodProfile) end
    model = {
        title = titleFor(row, state, status, nativeName(native, player), options,
            capabilities),
        category = tostring(row.category or metadata.category or "Item"),
        lines = {}, stateKnown = stateKnown, source = row.source,
        capabilities = capabilities,
    }

    displayWeight = finite(row.unitWeight)
        or finite(row.weight) or finite(metadata.weight)
    if displayWeight ~= nil then
        addLine(model.lines, text(options, "Tooltip_item_Weight", "Encumbrance"),
            numberText(displayWeight, 1))
    end
    stack = tonumber(row.stack or row.quantity)
    if stack and stack > 1 then
        addLine(model.lines, text(options, "IGUI_ItemInfo_Amount", "Amount"),
            numberText(stack, 0))
    end

    condition = finite(state.condition)
    conditionMax = finite(state.conditionMax)
        or finite(row.conditionMax) or finite(metadata.conditionMax)
    if condition ~= nil and capabilities.condition == true
        and (capabilities.conditionAlways == true
            or capabilities.conditionShowAlways == true
            or capabilities.conditionWhenDamaged == true
            and conditionMax and conditionMax > 0
            and condition < conditionMax)
    then
        if conditionMax and conditionMax > 0 then
            local ratio = condition / conditionMax
            addLine(model.lines, text(options, "Tooltip_weapon_Condition", "Condition"),
                numberText(condition, 0) .. " / " .. numberText(conditionMax, 0),
                ratio, ratio < 0.25 and "danger" or nil)
        else
            addLine(model.lines, text(options, "Tooltip_weapon_Condition", "Condition"),
                numberText(condition, 0))
        end
    end
    if state.usedDelta ~= nil and capabilities.drainable == true
        and capabilities.fluid ~= true
    then
        addLine(model.lines, text(options, "IGUI_invpanel_Remaining", "Remaining"),
            percentText(state.usedDelta), state.usedDelta)
    end
    if state.ammoCount ~= nil and capabilities.ammo == true then
        addLine(model.lines, text(options, "IGUI_ItemInfo_Ammo", "Ammo"),
            numberText(state.ammoCount, 0))
    end
    if state.roundChambered ~= nil and capabilities.ammo == true then
        addLine(model.lines, text(options, "UI_PsychopatzInventory_Tooltip_Chambered",
            "Chambered"), state.roundChambered and "Yes" or "No")
    end
    if state.jammed ~= nil and capabilities.ammo == true then
        addLine(model.lines, text(options, "UI_PsychopatzInventory_Tooltip_Jammed",
            "Jammed"), state.jammed and "Yes" or "No",
            nil, state.jammed and "danger" or nil)
    end

    if isFoodItem then
        addSection(model.lines, text(options, "Tooltip_food_Hunger", "Food"))
        if state.hungChange ~= nil then
            addLine(model.lines, text(options, "Tooltip_food_Hunger", "Hunger"),
                scaledText(state.hungChange))
        end
        if state.thirstChange ~= nil then
            addLine(model.lines, text(options, "Tooltip_food_Thirst", "Thirst"),
                scaledText(state.thirstChange))
        end
        if status then
            local statusText = status.rotten and text(options,
                "Tooltip_food_Rotten", "Rotten")
                or status.stale and text(options, "Tooltip_food_Stale", "Stale")
                or status.fresh and text(options, "Tooltip_food_Fresh", "Fresh")
                or nil
            if statusText then
                addLine(model.lines, text(options,
                    "UI_PsychopatzInventory_Tooltip_Status", "Status"),
                    statusText, nil, status.rotten and "danger" or nil)
            end
        end
        if state.frozen == true then
            addLine(model.lines, text(options, "Tooltip_food_Frozen", "Frozen"),
                text(options, "Tooltip_food_Frozen", "Frozen"), nil, "accent")
        end
        local freezing = finite(state.freezingTime)
        if freezing ~= nil then
            addLine(model.lines, text(options,
                "UI_PsychopatzInventory_Tooltip_Freezing", "Freezing"),
                percentText(freezing), freezing / 100)
        end
        if state.dangerousUncooked == true then
            addLine(model.lines, text(options, "Tooltip_food_Dangerous_uncooked",
                "Dangerous uncooked"), text(options,
                "Tooltip_food_Dangerous_uncooked", "Dangerous uncooked"),
                nil, "danger")
        end
        if state.tainted == true then
            addLine(model.lines, text(options, "Tooltip_tainted", "Tainted"),
                text(options, "Tooltip_tainted", "Tainted"), nil, "danger")
        end
        if state.poison == true or finite(state.poisonPower)
            and state.poisonPower > 0
        then
            addLine(model.lines, text(options, "Tooltip_food_Poisonous", "Poison"),
                text(options, "Tooltip_food_Poisonous", "Poisonous"), nil, "danger")
        end
    end

    if capabilities.clothing == true
        and (state.wetness ~= nil or state.bloodLevel ~= nil
            or state.dirtyness ~= nil)
    then
        addSection(model.lines, text(options, "UI_PsychopatzInventory_Tooltip_Clothing",
            "Clothing"))
        if state.wetness ~= nil then
            addLine(model.lines, text(options, "Tooltip_clothing_Wetness", "Wetness"),
                percentText(state.wetness), state.wetness)
        end
        if state.bloodLevel ~= nil then
            addLine(model.lines, text(options, "Tooltip_clothing_Blood", "Blood"),
                percentText(state.bloodLevel), state.bloodLevel)
        end
        if state.dirtyness ~= nil then
            addLine(model.lines, text(options, "Tooltip_clothing_Dirt", "Dirt"),
                percentText(state.dirtyness), state.dirtyness)
        end
    end

    amount = finite(state.fluidAmount)
    capacity = finite(state.fluidCapacity)
    fluids = type(state.fluids) == "table" and state.fluids or {}
    primary = state.fluidPrimaryType or state.fluidType
    if capabilities.fluid == true
        and (amount ~= nil or capacity ~= nil or primary or #fluids > 0)
    then
        addSection(model.lines, text(options, "Fluid_Fluids", "Liquids"))
        if amount ~= nil or capacity ~= nil then
            local fluidCapacity = capacity and math.max(0, capacity) or 0
            local ratio = fluidCapacity > 0 and amount / fluidCapacity or nil
            addLine(model.lines, text(options, "Fluid_Amount", "Amount"),
                numberText(amount or 0, 2) .. " / " .. numberText(capacity or 0, 2),
                ratio, "fluid")
        end
        if #fluids == 1 then
            addLine(model.lines, fluidName(fluids[1].type),
                numberText(fluids[1].amount, 2), nil, "fluid")
        elseif #fluids > 1 then
            local total = amount or 0
            addLine(model.lines, text(options, "Fluid_Mixture", "Mixture"),
                numberText(total, 2), nil, "fluid")
            for index = 1, #fluids do
                local entry = fluids[index]
                local share = total > 0 and entry.amount / total or nil
                addLine(model.lines, fluidName(entry.type),
                    numberText(entry.amount, 2) .. " (" .. percentText(share) .. ")",
                    share, "fluid")
            end
        elseif primary then
            addLine(model.lines, fluidName(primary), numberText(amount or 0, 2),
                nil, "fluid")
        end
        if state.tainted == true then
            addLine(model.lines, text(options, "Fluid_Tainted", "(Tainted)"),
                text(options, "Tooltip_tainted", "Tainted"), nil, "danger")
        end
        if state.poison == true or finite(state.poisonPower)
            and state.poisonPower > 0
        then
            addLine(model.lines, text(options, "Fluid_Poison", "Poison"),
                text(options, "Tooltip_food_Poisonous", "Poisonous"), nil, "danger")
        end
    elseif row.stateful == true and not stateKnown then
        addLine(model.lines, text(options, "UI_PsychopatzInventory_Tooltip_State", "State"),
            text(options, "UI_PsychopatzInventory_Tooltip_StateUnavailable",
                "State unavailable"), nil, "warning")
    end
    return model
end

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.UI = PsychopatzCore.UI or {}
PsychopatzCore.UI.InventoryTooltipModel = Model

return Model
