local Types = require
    "PsychopatzCore/World/SurvivorWorld/Types/PsychopatzSurvivorWorldTypesCore"
local I = Types.Internal

local VALID_STATUS = {
    active = true,
    archived = true,
    destroyed = true,
}

local function normalizeRelation(targetID, value)
    targetID = I.SafeID(targetID)
    if not targetID then return nil end
    value = type(value) == "table" and value or {}
    return {
        targetFactionID = targetID,
        standing = math.max(-100, math.min(
            100,
            I.Finite(
                value.standing or value.score or value.value,
                0
            )
        )),
        trust = math.max(-100, math.min(
            100,
            I.Finite(value.trust, 0)
        )),
        fear = math.max(0, math.min(
            100,
            I.Finite(value.fear, 0)
        )),
        grievance = math.max(0, math.min(
            100,
            I.Finite(value.grievance, 0)
        )),
        state = I.BoundedText(
            value.state or value.status or value.stance,
            48,
            "unknown"
        ),
        previousState = I.BoundedText(
            value.previousState,
            48,
            "unknown"
        ),
        atWar = value.atWar == true,
        allied = value.allied == true,
        truceUntil = math.max(0, I.Finite(value.truceUntil, 0)),
        warStartedAt = math.max(0, I.Finite(value.warStartedAt, 0)),
        warEndedAt = math.max(0, I.Finite(value.warEndedAt, 0)),
        revision = I.Integer(
            value.revision,
            0,
            2147483647,
            0
        ),
    }
end

local function normalizeRelations(value)
    local output = {}
    local keys = {}
    for key in pairs(type(value) == "table" and value or {}) do
        if I.SafeID(key) then keys[#keys + 1] = key end
    end
    table.sort(keys)
    for index = 1, math.min(#keys, Types.MAX_RELATIONS) do
        local relation =
            normalizeRelation(keys[index], value[keys[index]])
        if relation then output[relation.targetFactionID] = relation end
    end
    return output
end

function Types.NormalizeFaction(value, worldSeed, factionID)
    value = type(value) == "table" and value or {}
    local id = I.SafeID(factionID or value.id or value.factionID)
    local name = I.BoundedText(value.name, Types.MAX_NAME_LENGTH, nil)
    if not id or not name then
        return nil, "faction_identity_required"
    end

    local status = tostring(value.status or "active")
    if not VALID_STATUS[status] then status = "active" end

    return {
        schemaVersion = Types.SCHEMA_VERSION,
        id = id,
        seed = I.StableSeed(worldSeed, "faction", id, value.seed),
        name = name,
        archetypeID = I.BoundedText(
            value.archetypeID or value.archetypeId,
            Types.MAX_ARCHETYPE_LENGTH,
            "survivor.generic"
        ),
        status = status,
        leaderActorID = I.SafeID(
            value.leaderActorID
                or value.leaderActorId
                or value.leaderNPCID
        ),
        memberActorIDs = I.BoundedIDs(
            value.memberActorIDs
                or value.memberActorIds
                or value.memberIDs,
            Types.MAX_FACTION_MEMBERS
        ),
        relations = normalizeRelations(value.relations),
        tags = I.BoundedTags(value.tags),
        createdAt = math.max(0, I.Finite(value.createdAt, 0)),
        archivedAt = math.max(0, I.Finite(value.archivedAt, 0)),
        revision = I.Integer(value.revision, 0, 2147483647, 0),
        generation = I.NormalizeGeneration(value.generation),
    }
end

return Types
