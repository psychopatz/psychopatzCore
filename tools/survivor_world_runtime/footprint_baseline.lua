local CORE_ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
local HOOMANS_ROOT =
    "/home/psychopatz/Zomboid/Workshop/ProjectHoomans/"
    .. "Contents/mods/ProjectHoomans/42.20/media/lua/shared/"

package.path = table.concat({
    CORE_ROOT .. "?.lua",
    HOOMANS_ROOT .. "?.lua",
    package.path,
}, ";")

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local ActorInventory = require "PsychopatzCore/Actors/PsychopatzActorInventory"
local Json = require "PsychopatzCore/Serialization/PsychopatzJson"

PNC = PNC or {}
require "PNC/Core/Director/PNC_DirectorConfig"
local AbstractWorldTypes =
    require "PNC/Core/Director/PNC_AbstractWorldTypes"

local OUTPUT_JSON = "Docs/survivor_world_runtime/S0_BASELINE.json"
local OUTPUT_MD = "Docs/survivor_world_runtime/S0_BASELINE.md"

local function bytes(value)
    local encoded, reason = Json.Encode(value)
    if not encoded then error(reason or "json_encode_failed") end
    return #encoded, encoded
end

local function write(pathname, value)
    local file = assert(io.open(pathname, "wb"))
    file:write(value)
    file:close()
end

local function round(value, digits)
    local scale = 10 ^ (digits or 2)
    return math.floor(value * scale + 0.5) / scale
end

local function createActor(registry, index)
    local id = string.format("bench:actor:%04d", index)
    local actor, reason = registry:Create({
        actorId = id,
        identitySeed = "survivor-world-benchmark:" .. tostring(index),
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
    return actor
end

local function convertInventory(registry, actor, mode, mutate)
    -- The benchmark deliberately rebuilds deterministic baseline inventory
    -- from the actor seed. Decoding a legacy FULL payload is not equivalent:
    -- FULL does not preserve enough baseline provenance to safely emit
    -- SEED_ONLY again. S1 must therefore provide an explicit migration lane.
    local source = actor.personalInventory or {}
    local ledger, reason = ActorInventory.CreateForActor(
        actor.actorId,
        actor.identity.identitySeed,
        {
            starterVersion = source.starterVersion,
        }
    )
    if not ledger then error(reason or "inventory_rebuild_failed") end
    if mutate then
        local added
        added, reason = ledger:Add({
            itemId = actor.actorId .. ":durable:bandage",
            fullType = "Base.Bandage",
            metadata = { benchmark = true },
        })
        if not added then error(reason or "inventory_mutation_failed") end
    end
    local payload
    payload, reason = ledger:ToPayload(mode)
    if not payload then error(reason or "inventory_payload_failed") end
    local updated
    updated, reason = registry:Commit(actor.actorId, {
        personalInventory = payload,
    }, actor.revision)
    if not updated then error(reason or "inventory_commit_failed") end
    return updated
end

local function registryScenario(count, inventoryMode)
    local registry = Actors.NewRegistry()
    local inventoryBytes = 0
    local appearanceBytes = 0
    for index = 1, count do
        local actor = createActor(registry, index)
        if inventoryMode == "SEED_ONLY" then
            actor = convertInventory(registry, actor, "SEED_ONLY", false)
        elseif inventoryMode == "BASELINE_DELTA" then
            actor = convertInventory(registry, actor, "BASELINE_DELTA", true)
        end
        inventoryBytes = inventoryBytes + bytes(actor.personalInventory)
        appearanceBytes = appearanceBytes + bytes(actor.appearance)
    end
    local serialized, reason = registry:Save()
    if not serialized then error(reason or "registry_save_failed") end
    return {
        count = count,
        inventoryMode = inventoryMode,
        totalBytes = #serialized,
        bytesPerActor = round(#serialized / math.max(1, count), 2),
        inventoryBytes = inventoryBytes,
        inventoryBytesPerActor =
            round(inventoryBytes / math.max(1, count), 2),
        appearanceBytes = appearanceBytes,
        appearanceBytesPerActor =
            round(appearanceBytes / math.max(1, count), 2),
    }
end

local function sectionBreakdown(actor)
    local output = {}
    local keys = {}
    for key in pairs(actor or {}) do keys[#keys + 1] = key end
    table.sort(keys)
    for _, key in ipairs(keys) do
        local value = actor[key]
        if value ~= nil then
            output[#output + 1] = {
                section = tostring(key),
                bytes = bytes(value),
            }
        end
    end
    table.sort(output, function(left, right)
        if left.bytes ~= right.bytes then return left.bytes > right.bytes end
        return left.section < right.section
    end)
    return output
end

local function actorSectionScenario()
    local fullRegistry = Actors.NewRegistry()
    local full = createActor(fullRegistry, 7777)
    local seedRegistry = Actors.NewRegistry()
    local seed = createActor(seedRegistry, 7777)
    seed = convertInventory(seedRegistry, seed, "SEED_ONLY", false)
    return {
        full = sectionBreakdown(full),
        seedOnlyInventory = sectionBreakdown(seed),
    }
end

local function authoredAppearanceScenario()
    local registry = Actors.NewRegistry()
    local actor, reason = registry:Create({
        actorId = "bench:actor:authored",
        identitySeed = "survivor-world-authored",
        archetypeID = "survivor.authored",
        identity = {
            displayName = "Authored Benchmark",
            survivor = {
                forename = "Authored",
                surname = "Benchmark",
                gender = "female",
            },
        },
        appearance = {
            policy = {
                schemaVersion = 2,
                mode = "authored",
                outfit = "none",
                slots = {
                    Torso_Upper = {
                        mode = "item",
                        type = "Base.JacketLong_Random",
                        wornSlot = "Torso_Upper",
                    },
                    Legs = {
                        mode = "item",
                        type = "Base.Trousers_DefaultTEXTURE_TINT",
                        wornSlot = "Legs1",
                    },
                },
                hairModel = "Long2",
                beardModel = "",
                skinTone = "light",
            },
            resolved = {
                outfit = "none",
                skinTone = "light",
                hairModel = "Long2",
                beardModel = "",
                slots = {
                    Torso_Upper = "Base.JacketLong_Random",
                    Legs = "Base.Trousers_DefaultTEXTURE_TINT",
                },
            },
        },
    })
    if not actor then error(reason or "authored_actor_failed") end
    return {
        generatedAppearanceBytes =
            bytes(createActor(Actors.NewRegistry(), 9001).appearance),
        authoredAppearanceBytes = bytes(actor.appearance),
    }
end

local function memberIDs(count)
    local output = {}
    for index = 1, count do
        output[index] = string.format("npc_bench_%03d", index)
    end
    return output
end

local function groupScenario(count)
    local origin = {
        id = "aloc_benchmark_origin",
        type = "SETTLEMENT",
        x = 1000,
        y = 2000,
        z = 0,
    }
    local target = {
        id = "aloc_benchmark_target",
        type = "SETTLEMENT",
        x = 3500,
        y = 4400,
        z = 0,
    }
    local group = AbstractWorldTypes.NormalizeGroup({
        id = "agroup_benchmark",
        factionId = "faction_benchmark",
        homeCommunityId = "community_benchmark",
        groupType = "CARAVAN",
        memberIds = memberIDs(count),
        leaderId = "npc_bench_001",
        mission = "TRAVEL",
        state = "TRAVELING",
        location = origin,
        targetLocation = target,
        stateStartedAt = 120,
        stateEndsAt = 132,
        missionStartedAt = 118,
        resources = {
            food = 10, water = 10, ammo = 15,
            medical = 2, materials = 1, weapons = 3,
        },
        morale = 0.72,
        simulation = { nextUpdate = 121 },
    }, "agroup_benchmark")
    if not group then error("group_normalize_failed") end
    return {
        members = count,
        groupBytes = bytes(group),
        bytesPerMember = round(bytes(group) / count, 2),
    }
end

local function duplicatedTravelScenario(count)
    local journey = {
        schemaVersion = 2,
        journeyId = "journey:benchmark:001",
        revision = 3,
        state = "en_route",
        origin = { x = 1000, y = 2000, z = 0 },
        destination = { x = 3500, y = 4400, z = 0 },
        destinationAnchorID = "community_benchmark",
        startedAt = 120,
        eta = 132,
        progress = 0.42,
        route = {
            { x = 1000, y = 2000, z = 0 },
            { x = 1400, y = 2300, z = 0 },
            { x = 1800, y = 2800, z = 0 },
            { x = 2400, y = 3300, z = 0 },
            { x = 3000, y = 3800, z = 0 },
            { x = 3500, y = 4400, z = 0 },
        },
    }
    local group = {
        groupID = "agroup_benchmark",
        memberIDs = memberIDs(count),
        journey = journey,
    }
    local duplicated = { actors = {} }
    for index = 1, count do
        duplicated.actors[index] = {
            actorID = string.format("npc_bench_%03d", index),
            journey = journey,
        }
    end
    local sharedBytes = bytes(group)
    local duplicatedBytes = bytes(duplicated)
    return {
        members = count,
        sharedBytes = sharedBytes,
        duplicatedBytes = duplicatedBytes,
        avoidableBytes = duplicatedBytes - sharedBytes,
        duplicationRatio = round(duplicatedBytes / sharedBytes, 2),
    }
end

local function emptyAbstractWorld()
    local registry = AbstractWorldTypes.NewRegistry()
    return { bytes = bytes(registry) }
end

local counts = { 10, 100, 500, 1000 }
local report = {
    schema = "PsychopatzCore.SurvivorWorld.S0Baseline",
    schemaVersion = 1,
    generatedAt = "2026-11-03",
    coreActorRegistry = {
        currentFull = {},
        seedOnlyCounterfactual = {},
        sparseDeltaCounterfactual = {},
    },
    appearance = authoredAppearanceScenario(),
    actorSections = actorSectionScenario(),
    abstractWorld = {
        empty = emptyAbstractWorld(),
        groups = {},
        routeDuplication = {},
    },
}

for _, count in ipairs(counts) do
    report.coreActorRegistry.currentFull[#report.coreActorRegistry.currentFull + 1] =
        registryScenario(count, "FULL")
    report.coreActorRegistry.seedOnlyCounterfactual[
        #report.coreActorRegistry.seedOnlyCounterfactual + 1] =
        registryScenario(count, "SEED_ONLY")
    report.coreActorRegistry.sparseDeltaCounterfactual[
        #report.coreActorRegistry.sparseDeltaCounterfactual + 1] =
        registryScenario(count, "BASELINE_DELTA")
end

for _, count in ipairs({ 1, 5, 10, 25 }) do
    report.abstractWorld.groups[#report.abstractWorld.groups + 1] =
        groupScenario(count)
    report.abstractWorld.routeDuplication[
        #report.abstractWorld.routeDuplication + 1] =
        duplicatedTravelScenario(count)
end

local encoded = assert(Json.Encode(report))
write(OUTPUT_JSON, encoded .. "\n")

local function rows(values, fields)
    local output = {}
    for _, item in ipairs(values) do
        local row = {}
        for _, field in ipairs(fields) do
            row[#row + 1] = tostring(item[field])
        end
        output[#output + 1] = "| " .. table.concat(row, " | ") .. " |"
    end
    return table.concat(output, "\n")
end

local md = {}
md[#md + 1] = "# S0 Serialized Footprint Baseline"
md[#md + 1] = ""
md[#md + 1] = "Generated by tools/survivor_world_runtime/footprint_baseline.lua."
md[#md + 1] = ""
md[#md + 1] = "## Core actor registry — current FULL inventory"
md[#md + 1] = ""
md[#md + 1] = "| Actors | Total bytes | Bytes/actor | Inventory bytes/actor | Appearance bytes/actor |"
md[#md + 1] = "| ---: | ---: | ---: | ---: | ---: |"
md[#md + 1] = rows(report.coreActorRegistry.currentFull, {
    "count", "totalBytes", "bytesPerActor",
    "inventoryBytesPerActor", "appearanceBytesPerActor",
})
md[#md + 1] = ""
md[#md + 1] = "## Same actor schema with SEED_ONLY inventory"
md[#md + 1] = ""
md[#md + 1] = "| Actors | Total bytes | Bytes/actor | Inventory bytes/actor | Appearance bytes/actor |"
md[#md + 1] = "| ---: | ---: | ---: | ---: | ---: |"
md[#md + 1] = rows(report.coreActorRegistry.seedOnlyCounterfactual, {
    "count", "totalBytes", "bytesPerActor",
    "inventoryBytesPerActor", "appearanceBytesPerActor",
})
md[#md + 1] = ""
md[#md + 1] = "## Same actor schema with one durable inventory delta"
md[#md + 1] = ""
md[#md + 1] = "| Actors | Total bytes | Bytes/actor | Inventory bytes/actor |"
md[#md + 1] = "| ---: | ---: | ---: | ---: |"
md[#md + 1] = rows(report.coreActorRegistry.sparseDeltaCounterfactual, {
    "count", "totalBytes", "bytesPerActor", "inventoryBytesPerActor",
})
md[#md + 1] = ""
md[#md + 1] = "## Top-level actor section bytes"
md[#md + 1] = ""
md[#md + 1] = "### Current FULL actor"
md[#md + 1] = ""
md[#md + 1] = "| Section | Bytes |"
md[#md + 1] = "| --- | ---: |"
md[#md + 1] = rows(report.actorSections.full, { "section", "bytes" })
md[#md + 1] = ""
md[#md + 1] = "### Same actor with SEED_ONLY inventory"
md[#md + 1] = ""
md[#md + 1] = "| Section | Bytes |"
md[#md + 1] = "| --- | ---: |"
md[#md + 1] = rows(report.actorSections.seedOnlyInventory, { "section", "bytes" })
md[#md + 1] = ""
md[#md + 1] = "## Appearance payload"
md[#md + 1] = ""
md[#md + 1] = "- Generated appearance bytes: "
    .. tostring(report.appearance.generatedAppearanceBytes)
md[#md + 1] = "- Representative authored appearance bytes: "
    .. tostring(report.appearance.authoredAppearanceBytes)
md[#md + 1] = ""
md[#md + 1] = "## PNC abstract group record scaling"
md[#md + 1] = ""
md[#md + 1] = "| Members | Group bytes | Group bytes/member |"
md[#md + 1] = "| ---: | ---: | ---: |"
md[#md + 1] = rows(report.abstractWorld.groups, {
    "members", "groupBytes", "bytesPerMember",
})
md[#md + 1] = ""
md[#md + 1] = "## Shared journey vs duplicated per-actor journey"
md[#md + 1] = ""
md[#md + 1] = "| Members | Shared bytes | Duplicated bytes | Avoidable bytes | Duplication ratio |"
md[#md + 1] = "| ---: | ---: | ---: | ---: | ---: |"
md[#md + 1] = rows(report.abstractWorld.routeDuplication, {
    "members", "sharedBytes", "duplicatedBytes",
    "avoidableBytes", "duplicationRatio",
})
md[#md + 1] = ""
md[#md + 1] = "Empty normalized PNC abstract-world registry bytes: "
    .. tostring(report.abstractWorld.empty.bytes)
md[#md + 1] = ""

write(OUTPUT_MD, table.concat(md, "\n") .. "\n")
print("survivor_world_footprint_baseline: PASS")
print("json=" .. OUTPUT_JSON)
print("markdown=" .. OUTPUT_MD)
