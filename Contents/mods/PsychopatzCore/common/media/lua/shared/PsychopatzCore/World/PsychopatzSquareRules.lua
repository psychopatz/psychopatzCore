-- Reusable world-square predicates for selectors, facilities, crafting, and
-- any other system that needs the client and authority to agree on a target.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.World = PsychopatzCore.World or {}
PsychopatzCore.World.SquareRules = PsychopatzCore.World.SquareRules or {}

local Rules = PsychopatzCore.World.SquareRules
Rules.Definitions = Rules.Definitions or {}

local function javaListEach(list, visitor)
    if not list then return nil end
    if list.size and list.get then
        local index
        for index = 0, list:size() - 1 do
            local result = visitor(list:get(index), index)
            if result ~= nil then return result end
        end
        return nil
    end
    local index
    for index = 1, #list do
        local result = visitor(list[index], index)
        if result ~= nil then return result end
    end
    return nil
end

local function propertyValue(source, name)
    local properties
    if source and source.getProperties then
        local ok, value = pcall(source.getProperties, source)
        if ok then properties = value end
    end
    if not properties then return nil end
    if properties.get then
        local ok, value = pcall(properties.get, properties, name)
        if ok and value ~= nil and tostring(value) ~= "" then return value end
    end
    if properties.Val then
        local ok, value = pcall(properties.Val, properties, name)
        if ok and value ~= nil and tostring(value) ~= "" then return value end
    end
    if properties.Is then
        local ok, present = pcall(properties.Is, properties, name)
        if ok and present then return true end
    end
    return nil
end

local function spriteName(object)
    local sprite = object and object.getSprite and object:getSprite() or nil
    if not sprite then return "" end
    if sprite.getName then return string.lower(tostring(sprite:getName() or "")) end
    return string.lower(tostring(sprite.name or ""))
end

function Rules.Register(id, definition)
    id = tostring(id or "")
    if id == "" or type(definition) ~= "table"
        or type(definition.matches) ~= "function"
    then
        return false, "INVALID_SQUARE_RULE"
    end
    definition.id = id
    Rules.Definitions[id] = definition
    return true, definition
end

function Rules.Get(id)
    return Rules.Definitions[tostring(id or "")]
end

function Rules.GetSquare(x, y, z)
    local cell = getCell and getCell() or nil
    return cell and cell.getGridSquare
        and cell:getGridSquare(math.floor(tonumber(x) or 0),
            math.floor(tonumber(y) or 0), math.floor(tonumber(z) or 0))
        or nil
end

function Rules.GetObjectProperty(object, name)
    local value = propertyValue(object, name)
    if value ~= nil then return value end
    local sprite = object and object.getSprite and object:getSprite() or nil
    return propertyValue(sprite, name)
end

function Rules.IsActualBed(object)
    if not object then return false end
    local customName = string.lower(tostring(
        Rules.GetObjectProperty(object, "CustomName") or ""))
    if string.find(customName, "bed", 1, true)
        or string.find(customName, "mattress", 1, true)
        or string.find(customName, "futon", 1, true)
        or string.find(customName, "cot", 1, true)
    then
        return true
    end
    local bedType = string.lower(tostring(
        Rules.GetObjectProperty(object, "BedType") or ""))
    if bedType == "goodbed" or bedType == "averagebed"
        or bedType == "badbed"
    then
        return true
    end
    local name = spriteName(object)
    return string.find(name, "bed", 1, true) ~= nil
        and string.find(name, "bedding", 1, true) ~= nil
end

function Rules.FindBed(square)
    if not square then return nil end
    if square.getBed then
        local ok, object = pcall(square.getBed, square)
        if ok and Rules.IsActualBed(object) then return object end
    end
    local objects = square.getObjects and square:getObjects() or nil
    return javaListEach(objects, function(object)
        if Rules.IsActualBed(object) then return object end
        return nil
    end)
end

local function spriteGrid(object)
    local grid
    if object and object.getSpriteGrid then
        local ok, value = pcall(object.getSpriteGrid, object)
        if ok then grid = value end
    end
    local sprite = object and object.getSprite and object:getSprite() or nil
    if not grid and sprite and sprite.getSpriteGrid then
        local ok, value = pcall(sprite.getSpriteGrid, sprite)
        if ok then grid = value end
    end
    return grid, sprite
end

function Rules.DescribeBed(square, object)
    object = object or Rules.FindBed(square)
    if not square or not object then return nil end
    local x = square.getX and square:getX() or 0
    local y = square.getY and square:getY() or 0
    local z = square.getZ and square:getZ() or 0
    local centerX, centerY = x + 0.5, y + 0.5
    local grid, sprite = spriteGrid(object)
    local width, height
    if grid then
        local okX, gridX = pcall(grid.getSpriteGridPosX, grid, sprite)
        local okY, gridY = pcall(grid.getSpriteGridPosY, grid, sprite)
        local okW, gridWidth = pcall(grid.getWidth, grid)
        local okH, gridHeight = pcall(grid.getHeight, grid)
        width, height = tonumber(gridWidth), tonumber(gridHeight)
        if okX and okY and okW and okH
            and tonumber(gridX) and tonumber(gridY)
            and width and height and width > 0 and height > 0
        then
            centerX = x - tonumber(gridX) + width / 2
            centerY = y - tonumber(gridY) + height / 2
        end
    end
    local facing = string.upper(tostring(
        Rules.GetObjectProperty(object, "Facing") or ""))
    if facing ~= "N" and facing ~= "S" and facing ~= "E" and facing ~= "W" then
        facing = nil
    end
    local axis
    if width and height and width > height then axis = "x"
    elseif width and height and height > width then axis = "y"
    elseif facing == "N" or facing == "S" then axis = "y"
    elseif facing == "E" or facing == "W" then axis = "x" end
    local surfaceOffset
    if object.getSurfaceOffsetNoTable then
        local ok, value = pcall(object.getSurfaceOffsetNoTable, object)
        if ok then surfaceOffset = tonumber(value) end
    end
    return {
        object = object,
        x = centerX, y = centerY, z = z,
        facing = facing, axis = axis,
        surfaceOffset = surfaceOffset,
    }
end

function Rules.MatchSquare(square, ruleId, context)
    local definition = Rules.Get(ruleId)
    if not definition then return false, nil, "UNKNOWN_SQUARE_RULE" end
    if not square then return false, nil, "WORLD_SQUARE_UNLOADED" end
    local ok, match, reason = pcall(definition.matches, square, context or {})
    if not ok then return false, nil, "SQUARE_RULE_FAILED" end
    if match == true then match = square end
    return match ~= nil and match ~= false, match,
        reason or definition.reason or "INVALID_WORLD_SQUARE"
end

function Rules.MatchAt(x, y, z, ruleId, context)
    return Rules.MatchSquare(Rules.GetSquare(x, y, z), ruleId, context)
end

function Rules.ValidateRegion(region, ruleId, context)
    local checked = 0
    local z
    local level
    local y
    local spans
    local index
    local x
    for z, level in pairs(region and region.levels or {}) do
        for y, spans in pairs(level.rows or {}) do
            for index = 1, #spans, 2 do
                for x = spans[index], spans[index + 1] do
                    local valid, match, reason = Rules.MatchAt(
                        x, y, z, ruleId, context)
                    checked = checked + 1
                    if not valid then
                        return false, reason, {
                            checked = checked, x = x, y = y, z = z,
                        }
                    end
                end
            end
        end
    end
    return checked > 0, checked > 0 and nil or "EMPTY_REGION", {
        checked = checked,
    }
end

Rules.Register("bed", {
    reason = "BED_REQUIRED",
    matches = function(square)
        return Rules.FindBed(square)
    end,
})

Rules.Register("farmland", {
    reason = "FARMLAND_REQUIRED",
    matches = function(square)
        local farming = CFarmingSystem and CFarmingSystem.instance or nil
        if farming and farming.getLuaObjectOnSquare then
            local ok, plot = pcall(farming.getLuaObjectOnSquare, farming, square)
            if ok and plot then return plot end
        end
        local squareData = square.getModData and square:getModData() or nil
        if squareData and (squareData.farming or squareData.typeOfSeed
            or squareData.hasPlant)
        then
            return square
        end
        local objects = square.getObjects and square:getObjects() or nil
        return javaListEach(objects, function(object)
            local data = object and object.getModData and object:getModData() or nil
            local name = spriteName(object)
            if data and (data.farming or data.typeOfSeed or data.hasPlant) then
                return object
            end
            if string.find(name, "vegetation_farming", 1, true)
                or string.find(name, "farming_", 1, true)
            then
                return object
            end
            return nil
        end)
    end,
})

return Rules
