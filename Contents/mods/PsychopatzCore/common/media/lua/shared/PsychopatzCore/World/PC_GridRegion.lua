PsychopatzCore = PsychopatzCore or {}

local GridRegion = PsychopatzCore.GridRegion or {}

local function hasEntries(source)
    for _, _ in pairs(type(source) == "table" and source or {}) do
        return true
    end
    return false
end

local function integer(value)
    local number = tonumber(value)
    if not number or number ~= number or number == math.huge
        or number == -math.huge or number ~= math.floor(number)
    then
        return nil
    end
    return number
end

local function sortedKeys(source)
    local keys = {}
    for key, _ in pairs(type(source) == "table" and source or {}) do
        key = integer(key)
        if key then keys[#keys + 1] = key end
    end
    table.sort(keys)
    return keys
end

local function normalizeSpans(source)
    local ranges = {}
    local index
    if type(source) ~= "table" then return {} end
    for index = 1, #source - 1, 2 do
        local first = integer(source[index])
        local last = integer(source[index + 1])
        if first and last and first <= last then
            ranges[#ranges + 1] = { first, last }
        end
    end
    table.sort(ranges, function(a, b)
        return a[1] < b[1] or (a[1] == b[1] and a[2] < b[2])
    end)
    local output = {}
    for index = 1, #ranges do
        local range = ranges[index]
        local count = #output
        if count > 0 and range[1] <= output[count] + 1 then
            if range[2] > output[count] then output[count] = range[2] end
        else
            output[count + 1] = range[1]
            output[count + 2] = range[2]
        end
    end
    return output
end

local function sourceRows(level)
    if type(level) ~= "table" then return nil end
    return type(level.rows) == "table" and level.rows or level
end

function GridRegion.new()
    return { levels = {} }
end

function GridRegion.normalize(region)
    local output = GridRegion.new()
    local levels = type(region) == "table" and region.levels or nil
    local zKeys = sortedKeys(levels)
    local zi
    for zi = 1, #zKeys do
        local z = zKeys[zi]
        local rows = sourceRows(levels[z])
        local yKeys = sortedKeys(rows)
        local normalizedRows = {}
        local yi
        for yi = 1, #yKeys do
            local y = yKeys[yi]
            local spans = normalizeSpans(rows[y])
            if #spans > 0 then normalizedRows[y] = spans end
        end
        if hasEntries(normalizedRows) then
            output.levels[z] = { rows = normalizedRows }
        end
    end
    return output
end

function GridRegion.validate(region)
    if type(region) ~= "table" or type(region.levels) ~= "table" then
        return false, "INVALID_REGION"
    end
    local normalized = GridRegion.normalize(region)
    if not hasEntries(normalized.levels) then
        return false, "EMPTY_REGION", normalized
    end
    return true, nil, normalized
end

local function rowAt(region, y, z)
    local level = type(region) == "table" and type(region.levels) == "table"
        and region.levels[z] or nil
    local rows = sourceRows(level)
    return rows and rows[y] or nil
end

local function containsInSpans(spans, x)
    local low = 1
    local high = type(spans) == "table" and #spans / 2 or 0
    while low <= high do
        local middle = math.floor((low + high) / 2)
        local index = middle * 2 - 1
        if x < spans[index] then
            high = middle - 1
        elseif x > spans[index + 1] then
            low = middle + 1
        else
            return true
        end
    end
    return false
end

function GridRegion.containsPoint(region, x, y, z)
    x, y, z = integer(x), integer(y), integer(z)
    return x ~= nil and y ~= nil and z ~= nil
        and containsInSpans(rowAt(region, y, z), x)
end

function GridRegion.containsXY(region, x, y)
    x, y = integer(x), integer(y)
    if not x or not y or type(region) ~= "table" then return false end
    for z, _ in pairs(type(region.levels) == "table" and region.levels or {}) do
        if containsInSpans(rowAt(region, y, z), x) then return true end
    end
    return false
end

local function combineRows(a, b, operation)
    local output = {}
    local ai, bi = 1, 1
    a, b = a or {}, b or {}
    if operation == "union" then
        local joined = {}
        for i = 1, #a do joined[#joined + 1] = a[i] end
        for i = 1, #b do joined[#joined + 1] = b[i] end
        return normalizeSpans(joined)
    end
    while ai <= #a do
        local first, last = a[ai], a[ai + 1]
        while bi <= #b and b[bi + 1] < first do bi = bi + 2 end
        local cursor = first
        local scan = bi
        while scan <= #b and b[scan] <= last do
            if operation == "intersect" then
                local left = math.max(first, b[scan])
                local right = math.min(last, b[scan + 1])
                if left <= right then
                    output[#output + 1], output[#output + 2] = left, right
                end
            else
                if b[scan] > cursor then
                    output[#output + 1], output[#output + 2] = cursor,
                        math.min(last, b[scan] - 1)
                end
                cursor = math.max(cursor, b[scan + 1] + 1)
            end
            scan = scan + 2
        end
        if operation == "subtract" and cursor <= last then
            output[#output + 1], output[#output + 2] = cursor, last
        end
        ai = ai + 2
    end
    return output
end

local function combine(a, b, operation)
    a, b = GridRegion.normalize(a), GridRegion.normalize(b)
    local output = GridRegion.new()
    local seen = {}
    for z, level in pairs(a.levels) do
        seen[z] = true
        local rows, other = level.rows, b.levels[z] and b.levels[z].rows or {}
        local resultRows = {}
        local rowSeen = {}
        for y, spans in pairs(rows) do
            rowSeen[y] = true
            local result = combineRows(spans, other[y], operation)
            if #result > 0 then resultRows[y] = result end
        end
        if operation == "union" then
            for y, spans in pairs(other) do
                if not rowSeen[y] then resultRows[y] = combineRows(nil, spans, operation) end
            end
        end
        if hasEntries(resultRows) then
            output.levels[z] = { rows = resultRows }
        end
    end
    if operation == "union" then
        for z, level in pairs(b.levels) do
            if not seen[z] then
                output.levels[z] = { rows = {} }
                for y, spans in pairs(level.rows) do
                    output.levels[z].rows[y] = combineRows(nil, spans, operation)
                end
            end
        end
    end
    return output
end

function GridRegion.union(a, b) return combine(a, b, "union") end
function GridRegion.subtract(a, b) return combine(a, b, "subtract") end
function GridRegion.intersection(a, b) return combine(a, b, "intersect") end

function GridRegion.countTiles(region)
    local count = 0
    region = GridRegion.normalize(region)
    for _, level in pairs(region.levels) do
        for _, spans in pairs(level.rows) do
            for index = 1, #spans, 2 do
                count = count + spans[index + 1] - spans[index] + 1
            end
        end
    end
    return count
end

function GridRegion.bounds(region)
    local result
    region = GridRegion.normalize(region)
    for z, level in pairs(region.levels) do
        for y, spans in pairs(level.rows) do
            if #spans > 0 then
                if not result then
                    result = { minX = spans[1], maxX = spans[#spans], minY = y,
                        maxY = y, minZ = z, maxZ = z }
                else
                    result.minX = math.min(result.minX, spans[1])
                    result.maxX = math.max(result.maxX, spans[#spans])
                    result.minY, result.maxY = math.min(result.minY, y), math.max(result.maxY, y)
                    result.minZ, result.maxZ = math.min(result.minZ, z), math.max(result.maxZ, z)
                end
            end
        end
    end
    return result
end

function GridRegion.intersects(a, b)
    return GridRegion.countTiles(GridRegion.intersection(a, b)) > 0
end

function GridRegion.containsRegion(parent, child)
    return GridRegion.countTiles(GridRegion.subtract(child, parent)) == 0
end

local function overlap(a1, a2, b1, b2)
    return a1 <= b2 and b1 <= a2
end

function GridRegion.componentCount(region, adjacencyMode)
    if adjacencyMode ~= nil and adjacencyMode ~= 4 and adjacencyMode ~= "cardinal" then
        return nil, "UNSUPPORTED_ADJACENCY"
    end
    region = GridRegion.normalize(region)
    local nodes = {}
    local byLevelRow = {}
    for z, level in pairs(region.levels) do
        byLevelRow[z] = {}
        for y, spans in pairs(level.rows) do
            local row = {}
            byLevelRow[z][y] = row
            for index = 1, #spans, 2 do
                local node = { x1 = spans[index], x2 = spans[index + 1], links = {} }
                nodes[#nodes + 1] = node
                row[#row + 1] = node
            end
        end
    end
    for _, rows in pairs(byLevelRow) do
        for y, row in pairs(rows) do
            local adjacent = rows[y + 1]
            if adjacent then
                local ai, bi = 1, 1
                while ai <= #row and bi <= #adjacent do
                    local a, b = row[ai], adjacent[bi]
                    if overlap(a.x1, a.x2, b.x1, b.x2) then
                        a.links[#a.links + 1], b.links[#b.links + 1] = b, a
                    end
                    if a.x2 < b.x2 then ai = ai + 1 else bi = bi + 1 end
                end
            end
        end
    end
    local components, visited = 0, {}
    for index = 1, #nodes do
        local start = nodes[index]
        if not visited[start] then
            components = components + 1
            local stack = { start }
            visited[start] = true
            while #stack > 0 do
                local node = table.remove(stack)
                for li = 1, #node.links do
                    local linked = node.links[li]
                    if not visited[linked] then
                        visited[linked] = true
                        stack[#stack + 1] = linked
                    end
                end
            end
        end
    end
    return components
end

function GridRegion.isConnected(region, adjacencyMode)
    return GridRegion.componentCount(region, adjacencyMode) == 1
end

function GridRegion.spanCount(region)
    local count = 0
    region = GridRegion.normalize(region)
    for _, level in pairs(region.levels) do
        for _, spans in pairs(level.rows) do count = count + (#spans / 2) end
    end
    return count
end

PsychopatzCore.GridRegion = GridRegion
PC_GridRegion = GridRegion
return GridRegion
