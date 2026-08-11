local function equal(actual, expected, message)
    if actual ~= expected then
        error((message or "assertion failed") .. ": expected "
            .. tostring(expected) .. ", got " .. tostring(actual))
    end
end

package.path = table.concat({
    "Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua",
    "Contents/mods/PsychopatzCore/42.19/media/lua/shared/?.lua",
    package.path,
}, ";")

-- Build 42's Kahlua sandbox does not expose the global next() helper.
next = nil

local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Editor = require "PsychopatzCore/World/PC_GridRegionEditor"
local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"

local rectangle = Editor.rectangle(5, 6, 7, 8, 0)
equal(GridRegion.countTiles(rectangle), 9, "editor rectangle")
local edited = Editor.apply(rectangle, Editor.point(8, 8, 0), "add")
edited = Editor.apply(edited, Editor.point(6, 7, 0), "erase")
equal(GridRegion.countTiles(edited), 9, "editor add and erase")
local moved = Editor.translate(edited, 10, -2)
equal(GridRegion.containsPoint(moved, 15, 4, 0), true, "editor translate")

local normalized = GridRegion.normalize({ levels = { [0] = { rows = {
    [10] = { 10, 15, 14, 20, 21, 25, 40, 39, 9 },
} } } })
equal(#normalized.levels[0].rows[10], 2, "normalization span count")
equal(normalized.levels[0].rows[10][1], 10, "normalization minimum")
equal(normalized.levels[0].rows[10][2], 25, "normalization maximum")

local lShape = { levels = { [0] = { rows = {
    [0] = { 0, 3 }, [1] = { 0, 0 }, [2] = { 0, 0 },
} } } }
equal(GridRegion.countTiles(lShape), 6, "L shape tile count")
equal(GridRegion.containsPoint(lShape, 3, 0, 0), true, "point membership")
equal(GridRegion.containsPoint(lShape, 3, 1, 0), false, "point rejection")
equal(GridRegion.isConnected(lShape, 4), true, "L shape connected")

local hole = { levels = { [0] = { rows = {
    [0] = { 0, 2 }, [1] = { 0, 0, 2, 2 }, [2] = { 0, 2 },
} } } }
equal(GridRegion.countTiles(hole), 8, "hole tile count")
equal(GridRegion.isConnected(hole), true, "ring around hole connected")

local island = { levels = { [0] = { rows = {
    [0] = { 0, 1 }, [1] = { 2, 3 },
} } } }
equal(GridRegion.componentCount(island), 2, "diagonal does not connect")

local added = GridRegion.union(lShape, { levels = { [0] = { rows = {
    [1] = { 1, 2 },
} } } })
equal(GridRegion.countTiles(added), 8, "union")
equal(GridRegion.countTiles(GridRegion.intersection(added, lShape)), 6,
    "intersection")
equal(GridRegion.countTiles(GridRegion.subtract(added, lShape)), 2,
    "subtraction")
equal(GridRegion.containsRegion(added, lShape), true, "region containment")

Zones.import({ byID = {} })
local ok, zone = Zones.register({
    id = "test", ownerType = "test", ownerId = "owner",
    type = "shape", geometry = hole,
})
equal(ok, true, "zone registration")
equal(zone.cachedTileCount, 8, "zone cached count")
equal(#Zones.queryPoint(0, 0, 0, "shape"), 1, "indexed query")
equal(#Zones.queryPoint(1, 1, 0, "shape"), 0, "indexed hole query")
local previousRevision = zone.revision
ok, zone = Zones.updateGeometry("test", lShape, previousRevision)
equal(ok, true, "zone geometry update")
equal(zone.revision, previousRevision + 1, "zone revision")

print("psychopatz_grid_region_smoke: ok")
