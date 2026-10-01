require "PsychopatzCore/00_PsychopatzCore_Init"

PsychopatzCore = PsychopatzCore or {}

--- Destination geometry for teleports: turning an arbitrary (x, y, z) request
-- into a square the player will not be sealed inside. Pure and side-effect
-- free, so other core systems can reuse it without a teleport in mind.
local Destination = PsychopatzCore.TeleportDestination or {}
PsychopatzCore.TeleportDestination = Destination

-- IsoGameCharacter.teleportTo clamps z to this window; mirror it so an
-- out-of-range destination is corrected before it reaches the engine.
Destination.MIN_Z = -32
Destination.MAX_Z = 31

-- Horizontal nudge search used when the requested square is solid. Two squares
-- is enough to escape a wall without visibly missing the requested spot.
local RING_RADIUS = 2

local function isFiniteNumber(value)
    if type(value) ~= "number" then return false end
    if value ~= value then return false end                       -- NaN
    if value == math.huge or value == -math.huge then return false end
    return true
end

--- Coerces and bounds a destination. Returns nil when the input is not a
-- usable world position. Exposed so callers can sanitize untrusted args.
function Destination.Normalize(x, y, z)
    x = tonumber(x)
    y = tonumber(y)
    z = tonumber(z)
    if not isFiniteNumber(x) or not isFiniteNumber(y) then return nil end
    if not isFiniteNumber(z) then z = 0 end
    z = math.floor(z)
    if z < Destination.MIN_Z then z = Destination.MIN_Z end
    if z > Destination.MAX_Z then z = Destination.MAX_Z end
    return x, y, z
end

--- Mirrors the base-game map gate (ISWorldMap.lua:941). Fails open so a
-- missing or not-yet-loaded world API never blocks a teleport.
function Destination.IsInsideWorld(x, y)
    if type(getWorld) ~= "function" then return true end
    local world = getWorld()
    if not world or type(world.getMetaGrid) ~= "function" then return true end
    local metaGrid = world:getMetaGrid()
    if not metaGrid or type(metaGrid.isValidChunk) ~= "function" then
        return true
    end
    local ok, valid = pcall(metaGrid.isValidChunk, metaGrid, x / 10, y / 10)
    if not ok then return true end
    return valid == true
end

local function squareAt(x, y, z)
    if type(getSquare) ~= "function" then return nil end
    local ok, square = pcall(getSquare, x, y, z)
    if not ok then return nil end
    return square
end

local function callSquare(square, method)
    local fn = square and square[method]
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, square)
    if not ok then return nil end
    return value
end

local function isSolid(square)
    return callSquare(square, "isSolid") == true
end

-- A square the player can share without being sealed inside geometry.
local function isUsable(square)
    return square ~= nil and not isSolid(square)
end

-- Preferred landing: usable and on a real level.
local function isStandable(square)
    return isUsable(square) and callSquare(square, "hasFloor") == true
end

Destination.IsStandableAt = function(x, y, z)
    return isStandable(squareAt(x, y, z))
end

local ringCache = {}

-- Square rings around the origin, cached because resolving a destination may
-- walk several levels and otherwise allocates per attempt.
local function ringCells(radius)
    local cached = ringCache[radius]
    if cached then return cached end
    local cells = {}
    local dx = -radius
    while dx <= radius do
        local dy = -radius
        while dy <= radius do
            if math.abs(dx) == radius or math.abs(dy) == radius then
                cells[#cells + 1] = { dx, dy }
            end
            dy = dy + 1
        end
        dx = dx + 1
    end
    ringCache[radius] = cells
    return cells
end

local function findStandableNeighbour(x, y, z)
    local radius = 1
    while radius <= RING_RADIUS do
        local cells = ringCells(radius)
        local index = 1
        while index <= #cells do
            local offset = cells[index]
            local nearX = x + offset[1]
            local nearY = y + offset[2]
            if isStandable(squareAt(nearX, nearY, z)) then
                return nearX, nearY
            end
            index = index + 1
        end
        radius = radius + 1
    end
    return nil
end

-- Ground level first, because the world map is a top-down view of it. A caller
-- that names an exact level (coordinate entry, scripted teleports) wins
-- instead, and otherwise its level is only the second candidate.
local function levelOrder(preferredZ, exact)
    local order = {}
    if exact then
        order[#order + 1] = preferredZ
        if preferredZ ~= 0 then order[#order + 1] = 0 end
    else
        order[#order + 1] = 0
        if preferredZ ~= 0 then order[#order + 1] = preferredZ end
    end
    local dz = 1
    while dz <= Destination.MAX_Z do
        order[#order + 1] = dz
        order[#order + 1] = -dz
        dz = dz + 1
    end
    return order
end

--- Picks a destination that will not leave the player sealed on a null or
-- solid square. Returns x, y, z, exact -- `exact` is true only when the
-- requested square itself was the landing point.
--
-- Resolution is deliberately best-effort. A multiplayer client normally has
-- the destination chunk unloaded, so no square is found; the requested level
-- is then kept and the engine streams the chunks in after the teleport, which
-- is exactly what the base game does.
function Destination.Resolve(x, y, z, exact)
    x, y, z = Destination.Normalize(x, y, z)
    if not x then return nil end
    if not Destination.IsInsideWorld(x, y) then
        return nil, "outside_world"
    end

    local order = levelOrder(z, exact == true)
    local fallbackX
    local fallbackY
    local fallbackZ
    local index = 1
    while index <= #order do
        local candidateZ = order[index]
        local square = squareAt(x, y, candidateZ)
        if square then
            if isStandable(square) then
                return x, y, candidateZ, true
            end
            if fallbackZ == nil and isUsable(square) then
                fallbackX, fallbackY, fallbackZ = x, y, candidateZ
            end
            local nearX, nearY = findStandableNeighbour(x, y, candidateZ)
            if nearX then
                return nearX, nearY, candidateZ, false
            end
        end
        index = index + 1
    end

    if fallbackZ ~= nil then
        return fallbackX, fallbackY, fallbackZ, false
    end
    return x, y, z, false
end

return Destination
