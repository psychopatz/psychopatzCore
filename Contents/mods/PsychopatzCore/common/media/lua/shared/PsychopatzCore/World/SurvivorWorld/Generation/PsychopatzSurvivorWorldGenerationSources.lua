local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Json = require "PsychopatzCore/Serialization/PsychopatzJson"
local Types = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldTypes"
local Generation = require
    "PsychopatzCore/World/SurvivorWorld/Generation/PsychopatzSurvivorWorldGenerationCore"
local Planner = require
    "PsychopatzCore/World/SurvivorWorld/Generation/PsychopatzSurvivorWorldGenerationPlanner"

local Sources = {
    Entries = {},
    MAX_SOURCES = 32,
}

local function countEntries()
    local total = 0
    for _ in pairs(Sources.Entries) do total = total + 1 end
    return total
end

local function integer(value, minimum, maximum, fallback)
    local normalized = math.floor(tonumber(value) or fallback)
    return math.max(minimum, math.min(maximum, normalized))
end

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return fallback
    end
    return value
end

local function requestKey(value)
    value = Util.text(value, nil)
    if not value or #value > Types.MAX_ID_LENGTH then return nil end
    return value
end

local function normalizeKind(value)
    value = string.lower(tostring(value or "group"))
    if value ~= "group" and value ~= "community" then return nil end
    return value
end

local function normalizeDescriptor(sourceID, value)
    if type(value) ~= "table" then
        return nil, "generation_source_descriptor_required"
    end
    local kind = normalizeKind(
        value.generationKind or value.kind
    )
    if not kind then return nil, "generation_source_kind_invalid" end

    local defaults = value.defaults or value.requestDefaults or {}
    if not Util.isSerializable(defaults) then
        return nil, "generation_source_defaults_not_serializable"
    end

    local profile = value.profile
    if profile ~= nil and not Util.isSerializable(profile) then
        return nil, "generation_source_profile_not_serializable"
    end

    if value.metadata ~= nil
        and not Util.isSerializable(value.metadata)
    then
        return nil, "generation_source_metadata_not_serializable"
    end

    return {
        id = sourceID,
        generationKind = kind,
        enabled = value.enabled ~= false,
        maxCommitted = integer(
            value.maxCommitted or value.maxGenerations,
            0,
            Generation.MAX_PLAN_MEMBERS * 32,
            0
        ),
        cooldownHours = math.max(
            0,
            finite(value.cooldownHours, 0)
        ),
        defaults = Util.clone(defaults),
        profile = Util.clone(profile),
        metadata = Util.clone(value.metadata),
    }
end

local function sourceEntry(sourceID)
    sourceID = Types.SafeID(sourceID)
    if not sourceID then return nil end
    return Sources.Entries[sourceID]
end

local function populationFor(registry)
    if type(registry) ~= "table"
        or type(registry.GetPopulation) ~= "function"
    then
        return nil, "survivor_world_population_api_unavailable"
    end
    return registry:GetPopulation()
end

local function sourceRecords(registry, sourceID, kind)
    local population, reason = populationFor(registry)
    if not population then return nil, reason end

    local records = {}
    for generationID, record in pairs(
        population.provenance or {}
    ) do
        if type(record) == "table"
            and tostring(record.source or "") == sourceID
            and (kind == nil or tostring(record.kind or "") == kind)
        then
            local normalized = Util.clone(record)
            normalized.generationID = normalized.generationID
                or generationID
            records[#records + 1] = normalized
        end
    end
    return records
end

local function existingRequest(registry, sourceID, kind, key)
    if not key then return nil end
    local records, reason = sourceRecords(registry, sourceID, kind)
    if not records then return nil, reason end
    for _, record in ipairs(records) do
        if tostring(record.requestKey or "") == key then
            return record
        end
    end
    return nil
end

local function availability(registry, descriptor, now)
    if descriptor.enabled ~= true then
        return false, "generation_source_disabled"
    end

    local records, reason = sourceRecords(
        registry,
        descriptor.id,
        descriptor.generationKind
    )
    if not records then return false, reason end

    if descriptor.maxCommitted > 0
        and #records >= descriptor.maxCommitted
    then
        return false, "generation_source_cap_reached"
    end

    if descriptor.cooldownHours > 0 then
        local latest = 0
        for _, record in ipairs(records) do
            latest = math.max(
                latest,
                finite(record.createdAt, 0)
            )
        end
        now = finite(now, 0)
        if latest > 0 and now < latest + descriptor.cooldownHours then
            return false, "generation_source_cooldown"
        end
    end

    return true
end

local function mergedRequest(descriptor, request, population)
    local input = Util.clone(descriptor.defaults or {})
    request = type(request) == "table" and request or {}
    for key, value in pairs(request) do
        input[key] = Util.clone(value)
    end

    input.source = descriptor.id
    input.sourceID = descriptor.id
    input.serial = math.max(
        1,
        math.floor(
            tonumber(population.nextGenerationSerial) or 1
        )
    )
    if input.profile == nil and descriptor.profile ~= nil then
        input.profile = Util.clone(descriptor.profile)
    end
    input.requestKey = requestKey(
        request.idempotencyKey or request.requestKey
    )
    input.createdAt = math.max(
        0,
        finite(
            request.createdAt or request.now,
            0
        )
    )
    return input
end

local function requestSignature(input)
    local comparable = Util.clone(input)
    comparable.source = nil
    comparable.sourceID = nil
    comparable.serial = nil
    comparable.requestKey = nil
    return Generation.SeedText(Json.Encode(comparable))
end

local function existingCanonical(registry, kind, record)
    if kind == "group"
        and type(registry.GetGroup) == "function"
    then
        return registry:GetGroup(record.groupID)
    end
    if kind == "community"
        and type(registry.GetCommunity) == "function"
    then
        return registry:GetCommunity(record.communityID)
    end
    return nil
end

local function generate(registry, actorRegistry, sourceID, request, kind)
    local descriptor = sourceEntry(sourceID)
    if not descriptor then return nil, "generation_source_not_registered" end
    if descriptor.generationKind ~= kind then
        return nil, "generation_source_kind_mismatch"
    end
    if type(actorRegistry) ~= "table" then
        return nil, "actor_registry_required"
    end
    if request ~= nil and not Util.isSerializable(request) then
        return nil, "generation_request_not_serializable"
    end

    local population, reason = populationFor(registry)
    if not population then return nil, reason end

    local input = mergedRequest(descriptor, request, population)
    if not input.requestKey then
        return nil, "generation_request_key_required"
    end
    local signature = requestSignature(input)

    local already, alreadyReason = existingRequest(
        registry,
        descriptor.id,
        kind,
        input.requestKey
    )
    if alreadyReason then return nil, alreadyReason end
    if already then
        if already.requestSignature ~= nil
            and tonumber(already.requestSignature) ~= signature
        then
            return nil, "generation_request_key_conflict"
        end
        local canonical = existingCanonical(registry, kind, already)
        if not canonical then
            return nil, "generation_record_orphaned"
        end
        return canonical, "already_committed", already
    end

    local available, availabilityReason = availability(
        registry,
        descriptor,
        input.createdAt
    )
    if not available then return nil, availabilityReason end

    local plan
    if kind == "group" then
        plan, reason = Planner.BuildGroupPlan(input)
    else
        plan, reason = Planner.BuildCommunityPlan(input)
    end
    if not plan then return nil, reason end

    plan.requestKey = input.requestKey
    plan.requestSignature = signature
    plan.sourceID = descriptor.id
    plan.memberSpecs = Util.clone(input.memberSpecs)

    -- Bootstrap is loaded lazily because it depends on the public Generation
    -- facade. This keeps the source registry reusable without a module cycle.
    local Bootstrap = require
        "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldBootstrap"
    local canonical
    if kind == "group" then
        canonical, reason = Bootstrap.CommitGroupPlan(
            registry,
            plan,
            actorRegistry
        )
    else
        canonical, reason = Bootstrap.CommitCommunityPlan(
            registry,
            plan,
            actorRegistry
        )
    end
    if not canonical then return nil, reason end

    return canonical, "committed", plan
end

function Sources.Register(sourceID, descriptor)
    sourceID = Types.SafeID(sourceID)
    if not sourceID then return false, "generation_source_id_invalid" end
    if not Sources.Entries[sourceID]
        and countEntries() >= Sources.MAX_SOURCES
    then
        return false, "generation_source_capacity"
    end

    local normalized, reason = normalizeDescriptor(
        sourceID,
        descriptor
    )
    if not normalized then return false, reason end
    Sources.Entries[sourceID] = normalized
    return true
end

function Sources.Unregister(sourceID)
    sourceID = Types.SafeID(sourceID)
    if not sourceID or not Sources.Entries[sourceID] then
        return false, "generation_source_not_registered"
    end
    Sources.Entries[sourceID] = nil
    return true
end

function Sources.Get(sourceID)
    local entry = sourceEntry(sourceID)
    return entry and Util.clone(entry) or nil
end

function Sources.List()
    local ids = {}
    for sourceID in pairs(Sources.Entries) do
        ids[#ids + 1] = sourceID
    end
    table.sort(ids)
    local output = {}
    for index, sourceID in ipairs(ids) do
        output[index] = Util.clone(Sources.Entries[sourceID])
    end
    return output
end

function Sources.SetEnabled(sourceID, enabled)
    local entry = sourceEntry(sourceID)
    if not entry then return false, "generation_source_not_registered" end
    entry.enabled = enabled == true
    return true
end

function Sources.GenerateGroup(registry, actorRegistry, sourceID, request)
    return generate(
        registry,
        actorRegistry,
        sourceID,
        request,
        "group"
    )
end

function Sources.GenerateCommunity(
    registry,
    actorRegistry,
    sourceID,
    request
)
    return generate(
        registry,
        actorRegistry,
        sourceID,
        request,
        "community"
    )
end

function Sources.ResetForTests()
    Sources.Entries = {}
end

return Sources
