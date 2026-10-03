local DisplayState = require
    "PsychopatzCore/Inventory/PsychopatzInventoryDisplayState"
local Portable = require "PsychopatzCore/Inventory/PsychopatzPortableItemState"
local Profiles = require "PsychopatzCore/Inventory/PsychopatzItemTypeProfile"

local Model = {}
local Internal = {}
Model.Internal = Internal
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.UI = PsychopatzCore.UI or {}
PsychopatzCore.UI.InventoryTooltipModel = Model
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

Internal.DisplayState = DisplayState
Internal.Portable = Portable
Internal.addLine = addLine
Internal.addSection = addSection
Internal.finite = finite
Internal.text = text
Internal.numberText = numberText
Internal.percentText = percentText
Internal.scaledText = scaledText
Internal.fluidName = fluidName
Internal.metadataFor = metadataFor
Internal.foodProfileFor = foodProfileFor
Internal.typeProfileFor = typeProfileFor
Internal.nativeName = nativeName
Internal.titleFor = titleFor

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
    local context = Internal.prepare(row, player, options)
    if not context then return nil end

    local model = {
        title = Internal.titleFor(
            context.row,
            context.state,
            context.status,
            Internal.nativeName(context.native, context.player),
            context.options,
            context.capabilities
        ),
        category = tostring(
            context.row.category or context.metadata.category or "Item"
        ),
        lines = {},
        stateKnown = context.stateKnown,
        source = context.row.source,
        capabilities = context.capabilities,
    }

    Internal.addCommonLines(model, context)
    Internal.addFoodLines(model, context)
    Internal.addClothingLines(model, context)
    Internal.addFluidLines(model, context)
    Internal.addUnavailableLine(model, context)
    return model
end

require "PsychopatzCore/UI/Inventory/PsychopatzInventoryTooltipModel_Preparation"
require "PsychopatzCore/UI/Inventory/PsychopatzInventoryTooltipModel_Sections"

return Model
