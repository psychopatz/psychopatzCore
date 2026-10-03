local Model = PsychopatzCore.UI.InventoryTooltipModel
local Internal = Model.Internal

local DisplayState = Internal.DisplayState
local Portable = Internal.Portable
local metadataFor = Internal.metadataFor
local foodProfileFor = Internal.foodProfileFor
local typeProfileFor = Internal.typeProfileFor

function Internal.prepare(row, player, options)
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

    return {
        row = row,
        player = player,
        options = options,
        state = state,
        stateKnown = stateKnown,
        fullType = fullType,
        native = native,
        metadata = metadata,
        profile = profile,
        capabilities = capabilities,
        foodProfile = foodProfile,
        status = status,
        isFoodItem = isFoodItem,
    }
end

return Internal

