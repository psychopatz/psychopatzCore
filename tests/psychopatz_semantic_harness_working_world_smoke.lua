local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = "tools/semantic_harness/lua/?.lua;" .. ROOT .. "?.lua;"
    .. package.path

local Values = require "worker/Values"
local WorkingWorld = require "worker/WorkingWorld"

local runtime = {
    sourceSnapshot = {
        npc = { needs = { hunger = 0.2 } },
        world = { weather = "clear" },
    },
    sourceMetadata = { sourceKind = "SAVE" },
    scenario = {
        npc = { needs = { hunger = 0.8 } },
        world = { weather = "clear" },
    },
}

local patches = WorkingWorld.patches(runtime, Values)
assert(#patches == 1, "working-world patch projection should be bounded")
assert(patches[1].path == "npc.needs.hunger",
    "working-world patch path is not deterministic")
assert(patches[1].source == "HARNESS_MUTATION",
    "working-world patch source is not canonical")
assert(patches[1].baseSource == "SAVE",
    "working-world patch lost source provenance")

runtime.workingWorldRevision = 4
WorkingWorld.beginSourceImport(runtime)
assert(runtime.captureWorkingBaseline == true,
    "source import did not request baseline capture")
assert(runtime.workingResetCount == 0,
    "source import did not reset reset count")
assert(runtime.workingWorldRevision == 5,
    "source import revision transition is incorrect")

WorkingWorld.beginReset(runtime)
assert(runtime.workingWorldRevision == 6,
    "reset revision transition is incorrect")
runtime.scenario = { npc = { npcID = "npc-1" } }
assert(WorkingWorld.captureBaseline(runtime, Values) == true,
    "working-world baseline was not captured")
assert(runtime.sourceWorkingBaseline.npc.npcID == "npc-1",
    "working-world baseline contains the wrong effective state")
assert(WorkingWorld.captureBaseline(runtime, Values) == false,
    "working-world baseline recaptured unexpectedly")
assert(WorkingWorld.incrementResetCount(runtime) == 1,
    "working-world reset count did not increment")

print("psychopatz semantic harness working world: ok")
