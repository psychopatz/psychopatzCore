local Model = PsychopatzCore.UI.InventoryTooltipModel
local Internal = Model.Internal

local addLine = Internal.addLine
local addSection = Internal.addSection
local finite = Internal.finite
local text = Internal.text
local numberText = Internal.numberText
local percentText = Internal.percentText
local scaledText = Internal.scaledText
local fluidName = Internal.fluidName

function Internal.addCommonLines(model, context)
    local row = context.row
    local state = context.state
    local metadata = context.metadata
    local capabilities = context.capabilities
    local options = context.options
    local displayWeight
    local stack
    local condition
    local conditionMax

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
end

function Internal.addFoodLines(model, context)
    local state = context.state
    local status = context.status
    local isFoodItem = context.isFoodItem
    local options = context.options

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
end

function Internal.addClothingLines(model, context)
    local state = context.state
    local capabilities = context.capabilities
    local options = context.options

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
end

function Internal.addFluidLines(model, context)
    local state = context.state
    local capabilities = context.capabilities
    local options = context.options
    local amount
    local capacity
    local fluids
    local primary

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
end
end

function Internal.addUnavailableLine(model, context)
    local row = context.row
    local stateKnown = context.stateKnown
    local options = context.options

    if row.stateful == true and not stateKnown then
        addLine(model.lines, text(options, "UI_PsychopatzInventory_Tooltip_State", "State"),
            text(options, "UI_PsychopatzInventory_Tooltip_StateUnavailable",
                "State unavailable"), nil, "warning")
    end
end

return Internal
