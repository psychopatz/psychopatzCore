local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local Json = require "PsychopatzCore/Serialization/PsychopatzJson"

local function round(value)
    return math.floor(value * 100 + 0.5) / 100
end

local function scenario(count)
    local registry = Actors.NewRegistry()
    for index = 1, count do
        local actor, reason = registry:Create({
            actorId = string.format("current:actor:%04d", index),
            identitySeed = "current-footprint:" .. tostring(index),
            archetypeID = index % 5 == 0 and "merchant.benchmark"
                or "survivor.benchmark",
            world = {
                location = {
                    kind = "world",
                    x = 1000 + index * 3,
                    y = 2000 + index * 2,
                    z = 0,
                },
            },
        })
        if not actor then error(reason or "actor_create_failed") end
    end
    local serialized, reason = registry:Save()
    if not serialized then error(reason or "registry_save_failed") end
    local inventoryModes = {}
    for _, actor in ipairs(registry:List()) do
        local mode = actor.personalInventory
            and actor.personalInventory.mode or "NONE"
        inventoryModes[mode] = (inventoryModes[mode] or 0) + 1
    end
    return {
        actors = count,
        totalBytes = #serialized,
        bytesPerActor = round(#serialized / count),
        inventoryModes = inventoryModes,
    }
end

local report = {
    schema = "PsychopatzCore.SurvivorWorld.CurrentFootprint",
    schemaVersion = 1,
    registrySchemaVersion = 2,
    scenarios = {},
}
for _, count in ipairs({ 10, 100, 500, 1000 }) do
    report.scenarios[#report.scenarios + 1] = scenario(count)
end

local encoded = assert(Json.Encode(report))
local json = assert(io.open(
    "Docs/survivor_world_runtime/S1_FOOTPRINT.json", "wb"))
json:write(encoded, "\n")
json:close()

local md = assert(io.open(
    "Docs/survivor_world_runtime/S1_FOOTPRINT.md", "wb"))
md:write("# S1 Compact Persistence Footprint\n\n")
md:write("| Actors | Total bytes | Bytes/actor | SEED_ONLY | FULL |\n")
md:write("| ---: | ---: | ---: | ---: | ---: |\n")
for _, item in ipairs(report.scenarios) do
    md:write(string.format("| %d | %d | %.2f | %d | %d |\n",
        item.actors,
        item.totalBytes,
        item.bytesPerActor,
        item.inventoryModes.SEED_ONLY or 0,
        item.inventoryModes.FULL or 0))
end
md:close()

print("survivor_world_current_footprint: PASS")
