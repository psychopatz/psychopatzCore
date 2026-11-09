local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = "tools/semantic_harness/lua/?.lua;" .. ROOT .. "?.lua;"
    .. package.path

local Values = require "worker/Values"
local SessionEnvelope = require "worker/SessionEnvelope"

local runtime = {
    sourceSnapshot = { npc = { npcID = "npc-1" } },
    sourceMetadata = {
        sourceKind = "FIXTURE",
        sourceID = "fixture:session-envelope",
    },
    sourceProvenance = { schema = "semantic.provenance.v1" },
    sourceWorkingBaseline = { npc = { npcID = "npc-1" } },
    scenario = { npc = { npcID = "npc-1", activeBehavior = "idle" } },
    sourceProviderPayloads = {
        ProjectHoomans = { rawRegistries = { count = 1 } },
        DTAbstract = { mode = "abstract" },
    },
    extensions = { ProjectHoomans = { materialization = "physical" } },
    workingWorldRevision = 3,
    workingResetCount = 1,
}

local envelope = SessionEnvelope.project(runtime, Values)
assert(envelope.schema == SessionEnvelope.SCHEMA,
    "session envelope schema missing")
assert(envelope.source.metadata.sourceID == "fixture:session-envelope",
    "session envelope lost source metadata")
assert(envelope.working.revision == 3 and envelope.working.resetCount == 1,
    "session envelope lost working revision state")
assert(envelope.providerPayloads.ProjectHoomans.rawRegistries.count == 1,
    "session envelope lost namespaced provider payload")
assert(envelope.extensions.ProjectHoomans.materialization == "physical",
    "session envelope lost opaque provider extension")

local compact = SessionEnvelope.compact(envelope)
assert(compact.source.data == nil and compact.providerPayloads == nil,
    "session envelope compact projection retained raw provider data")
assert(compact.working.baseline == nil,
    "session envelope compact projection retained baseline")

print("psychopatz semantic harness session envelope: ok")
