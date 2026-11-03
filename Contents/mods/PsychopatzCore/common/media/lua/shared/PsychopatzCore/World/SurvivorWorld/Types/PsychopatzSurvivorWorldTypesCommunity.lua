local Types = require
    "PsychopatzCore/World/SurvivorWorld/Types/PsychopatzSurvivorWorldTypesCore"
local I = Types.Internal

local VALID_STATUS = {
    active = true,
    inactive = true,
    archived = true,
    destroyed = true,
}

function Types.NormalizeCommunity(value, worldSeed, communityID)
    value = type(value) == "table" and value or {}
    local id = I.SafeID(
        communityID or value.id or value.communityID
    )
    local factionID = I.SafeID(
        value.factionID or value.factionId
    )
    local name = I.BoundedText(
        value.name,
        Types.MAX_NAME_LENGTH,
        nil
    )
    local home = I.NormalizePoint(value.home or value.position)
    if not id or not factionID or not name or not home then
        return nil, "community_identity_required"
    end

    local status = tostring(value.status or "active")
    if not VALID_STATUS[status] then status = "inactive" end
    local memberActorIDs = I.BoundedIDs(
        value.memberActorIDs
            or value.memberActorIds
            or value.memberIDs,
        Types.MAX_COMMUNITY_MEMBERS
    )
    local capacity =
        type(value.capacity) == "table" and value.capacity or {}

    return {
        schemaVersion = Types.SCHEMA_VERSION,
        id = id,
        seed = I.StableSeed(
            worldSeed,
            "community",
            id,
            value.seed
        ),
        factionID = factionID,
        name = name,
        mode = I.BoundedText(value.mode, 48, "settled"),
        profile = I.BoundedText(
            value.profile or value.profileID or value.profileId,
            64,
            nil
        ),
        status = status,
        home = {
            x = home.x,
            y = home.y,
            z = home.z,
            radius = math.max(
                0,
                I.Finite(
                    (type(value.home) == "table"
                        and value.home.radius)
                        or value.radius,
                    0
                )
            ),
        },
        siteID = I.SafeID(value.siteID or value.siteId),
        leaderActorID = I.SafeID(
            value.leaderActorID
                or value.leaderActorId
                or value.leaderNPCID
        ),
        memberActorIDs = memberActorIDs,
        population = I.Integer(
            value.population or value.currentPopulation,
            0,
            Types.MAX_COMMUNITY_MEMBERS,
            #memberActorIDs
        ),
        security = math.max(0, I.Finite(value.security, 0)),
        morale = math.max(
            0,
            math.min(1, I.Finite(value.morale, 0))
        ),
        resources = I.NormalizeResources(
            value.resources or value.supplies
        ),
        tags = I.BoundedTags(value.tags),
        createdAt = math.max(0, I.Finite(value.createdAt, 0)),
        archivedAt = math.max(0, I.Finite(value.archivedAt, 0)),
        destroyedAt = math.max(0, I.Finite(value.destroyedAt, 0)),
        revision = I.Integer(value.revision, 0, 2147483647, 0),
        generation = I.NormalizeGeneration(value.generation),
    }
end

return Types
