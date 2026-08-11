PsychopatzCore = PsychopatzCore or {}

local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Editor = PsychopatzCore.GridRegionEditor or {}

function Editor.rectangle(x1, y1, x2, y2, z)
    x1, x2 = math.min(math.floor(x1), math.floor(x2)),
        math.max(math.floor(x1), math.floor(x2))
    y1, y2 = math.min(math.floor(y1), math.floor(y2)),
        math.max(math.floor(y1), math.floor(y2))
    z = math.floor(tonumber(z) or 0)
    local rows = {}
    for y = y1, y2 do rows[y] = { x1, x2 } end
    return { levels = { [z] = { rows = rows } } }
end

function Editor.point(x, y, z)
    return Editor.rectangle(x, y, x, y, z)
end

function Editor.apply(region, patch, tool)
    tool = tostring(tool or "replace")
    if tool == "add" then return GridRegion.union(region, patch) end
    if tool == "erase" then return GridRegion.subtract(region, patch) end
    return GridRegion.normalize(patch)
end

function Editor.translate(region, dx, dy, targetZ)
    dx, dy = math.floor(tonumber(dx) or 0), math.floor(tonumber(dy) or 0)
    local output = GridRegion.new()
    region = GridRegion.normalize(region)
    for z, level in pairs(region.levels) do
        local destinationZ = targetZ == nil and z or math.floor(targetZ)
        local destination = output.levels[destinationZ]
        if not destination then
            destination = { rows = {} }
            output.levels[destinationZ] = destination
        end
        for y, spans in pairs(level.rows) do
            local row = destination.rows[y + dy] or {}
            destination.rows[y + dy] = row
            for index = 1, #spans, 2 do
                row[#row + 1] = spans[index] + dx
                row[#row + 1] = spans[index + 1] + dx
            end
        end
    end
    return GridRegion.normalize(output)
end

function Editor.stats(region)
    local normalized = GridRegion.normalize(region)
    local bounds = GridRegion.bounds(normalized)
    return {
        region = normalized,
        tileCount = GridRegion.countTiles(normalized),
        spanCount = GridRegion.spanCount(normalized),
        bounds = bounds,
        width = bounds and bounds.maxX - bounds.minX + 1 or 0,
        height = bounds and bounds.maxY - bounds.minY + 1 or 0,
        connected = bounds ~= nil and GridRegion.isConnected(normalized, 4),
    }
end

PsychopatzCore.GridRegionEditor = Editor
PC_GridRegionEditor = Editor
return Editor
