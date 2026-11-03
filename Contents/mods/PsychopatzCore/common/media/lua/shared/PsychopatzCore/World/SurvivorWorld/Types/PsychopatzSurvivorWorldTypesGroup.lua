local Types = require
    "PsychopatzCore/World/SurvivorWorld/Types/PsychopatzSurvivorWorldTypesCore"
local GroupJourney = require
    "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldGroupJourney"
local I = Types.Internal

function Types.NormalizeGroup(value, worldSeed, groupID)
    value = type(value) == "table" and value or {}
    local id = I.SafeID(groupID or value.id or value.groupID)
    local factionID = I.SafeID(
        value.factionID or value.factionId
    )
    local location = I.NormalizeLocation(value.location)
    if not id or not factionID or not location then
        return nil, "group_identity_required"
    end

    local members = I.BoundedIDs(
        value.memberActorIDs
            or value.memberActorIds
            or value.memberIDs
            or value.memberIds,
        Types.MAX_GROUP_MEMBERS
    )
    local journey
    local rawJourney = value.journey or value.groupJourney
    if type(rawJourney) == "table" then
        local reason
        journey, reason = GroupJourney.Normalize(
            rawJourney,
            id,
            rawJourney.lastAdvancedAt
                or rawJourney.lastAdvancedWorldHour
        )
        if not journey then return nil, reason end
    end

    return {
        schemaVersion = Types.SCHEMA_VERSION,
        id = id,
        seed = I.StableSeed(worldSeed, "group", id, value.seed),
        factionID = factionID,
        homeCommunityID = I.SafeID(
            value.homeCommunityID or value.homeCommunityId
        ),
        groupType = I.BoundedText(
            value.groupType or value.type,
            Types.MAX_KIND_LENGTH,
            "wanderer"
        ),
        memberActorIDs = members,
        leaderActorID = I.SafeID(
            value.leaderActorID
                or value.leaderActorId
                or value.leaderID
                or value.leaderId
        ),
        mission = I.BoundedText(value.mission, 64, "idle"),
        state = I.BoundedText(value.state, 64, "idle"),
        location = location,
        targetLocation = I.NormalizeLocation(
            value.targetLocation or value.destination
        ),
        journey = journey,
        stateStartedAt = math.max(
            0,
            I.Finite(value.stateStartedAt, 0)
        ),
        stateEndsAt = math.max(
            0,
            I.Finite(value.stateEndsAt, 0)
        ),
        missionStartedAt = math.max(
            0,
            I.Finite(value.missionStartedAt, 0)
        ),
        resources = I.NormalizeResources(
            value.resources or value.supplies
        ),
        morale = math.max(
            0,
            math.min(1, I.Finite(value.morale, 0))
        ),
        tags = I.BoundedTags(value.tags),
        revision = I.Integer(value.revision, 0, 2147483647, 0),
        generation = I.NormalizeGeneration(value.generation),
    }
end

function Types.NormalizeAbstractLocation(value, worldSeed, locationID)
    value = type(value) == "table" and value or {}
    local id = I.SafeID(
        locationID or value.id or value.locationID
    )
    local point = I.NormalizePoint(value.position or value)
    if not id or not point then
        return nil, "survivor_world_location_identity_required"
    end

    return {
        schemaVersion = Types.SCHEMA_VERSION,
        id = id,
        seed = I.StableSeed(
            worldSeed,
            "location",
            id,
            value.seed
        ),
        kind = I.BoundedText(
            value.kind or value.type,
            Types.MAX_KIND_LENGTH,
            "temporary"
        ),
        x = point.x,
        y = point.y,
        z = point.z,
        tags = I.BoundedTags(value.tags),
        resources = I.NormalizeResources(
            value.resources or value.resourcePotential
        ),
        scavengedLevel = math.max(
            0,
            math.min(
                100,
                I.Finite(value.scavengedLevel, 0)
            )
        ),
        danger = math.max(
            0,
            math.min(100, I.Finite(value.danger, 0))
        ),
        revision = I.Integer(value.revision, 0, 2147483647, 0),
        generation = I.NormalizeGeneration(value.generation),
    }
end

return Types
