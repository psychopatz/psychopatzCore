local Json = require "PsychopatzCore/Serialization/PsychopatzJson"
local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Types =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldTypes"

local Persistence = {}

Persistence.SCHEMA = "PsychopatzCore.SurvivorWorld.Registry"
Persistence.SCHEMA_VERSION = 1
Persistence.MAX_BYTES = 32 * 1024 * 1024
Persistence.JSON_LIMITS = {
    maxString = Persistence.MAX_BYTES,
    maxDepth = 32,
    maxCollection = 8192,
}

local function isEmptyMap(value)
    if type(value) ~= "table" then return true end
    for _ in pairs(value) do return false end
    return true
end

local function nonZero(value)
    return value ~= nil and value ~= 0
end

local function sameXYZ(a, b)
    return type(a) == "table" and type(b) == "table"
        and a.x == b.x and a.y == b.y and (a.z or 0) == (b.z or 0)
end

local function compactPoint(point)
    if type(point) ~= "table" then return nil end
    local out = { x = point.x, y = point.y }
    if nonZero(point.z) then out.z = point.z end
    return out
end

local function compactLocation(loc)
    if type(loc) ~= "table" then return nil end
    local out = { x = loc.x, y = loc.y }
    if nonZero(loc.z) then out.z = loc.z end
    if loc.id ~= nil then out.id = loc.id end
    if loc.kind ~= nil and loc.kind ~= "world" then
        out.kind = loc.kind
    end
    return out
end

local function compactResources(resources)
    if type(resources) ~= "table" then return nil end
    local out = nil
    for key, amount in pairs(resources) do
        if type(amount) == "number" and amount > 0 then
            if not out then out = {} end
            out[key] = amount
        end
    end
    return out
end

local function compactGeneration(gen)
    if type(gen) ~= "table" or not gen.generationID then return nil end
    local out = { generationID = gen.generationID }
    if gen.source ~= nil and gen.source ~= "world" then
        out.source = gen.source
    end
    if gen.kind ~= nil and gen.kind ~= "group" then
        out.kind = gen.kind
    end
    if gen.groupID ~= nil then out.groupID = gen.groupID end
    if gen.communityID ~= nil then
        out.communityID = gen.communityID
    end
    if gen.requestKey ~= nil then out.requestKey = gen.requestKey end
    if gen.requestSignature ~= nil then
        out.requestSignature = gen.requestSignature
    end
    if gen.sectorID ~= nil then out.sectorID = gen.sectorID end
    if nonZero(gen.createdAt) then out.createdAt = gen.createdAt end
    if gen.seed ~= nil
        and gen.seed ~= Types.StableSeed(0, "generation", gen.generationID)
    then
        out.seed = gen.seed
    end
    return out
end

local function compactRoutePoints(route)
    local points = type(route) == "table" and route.points or nil
    if type(points) ~= "table" or #points == 0 then return nil end
    local out = {}
    for index = 1, #points do
        local p = points[index]
        local entry = { x = p.x, y = p.y }
        if nonZero(p.z) then entry.z = p.z end
        if nonZero(p.waitHours) then entry.waitHours = p.waitHours end
        if p.tag ~= nil then entry.tag = p.tag end
        out[index] = entry
    end
    return out
end

local function compactJourney(journey, groupID)
    if type(journey) ~= "table" then return nil end
    local out = {
        state = journey.state,
        startAt = journey.startAt,
    }
    local dest = journey.destination
    local defaultID = type(dest) == "table"
        and ("group_journey:" .. tostring(Util.hash(
            tostring(groupID) .. ":" .. tostring(journey.startAt)
                .. ":" .. tostring(dest.x)
                .. ":" .. tostring(dest.y)
        ))) or nil
    if journey.journeyID ~= nil and journey.journeyID ~= defaultID then
        out.journeyID = journey.journeyID
    end
    if journey.ownerMod ~= nil then out.ownerMod = journey.ownerMod end
    if journey.ownerRef ~= nil then out.ownerRef = journey.ownerRef end
    if journey.mode ~= nil and journey.mode ~= "abstract" then
        out.mode = journey.mode
    end
    local routePoints = type(journey.route) == "table"
        and journey.route.points or nil
    local firstPt = type(routePoints) == "table"
        and routePoints[1] or nil
    local lastPt = type(routePoints) == "table"
        and #routePoints > 0 and routePoints[#routePoints] or nil
    if not sameXYZ(journey.origin, firstPt) then
        out.origin = compactPoint(journey.origin)
    end
    if not sameXYZ(journey.destination, lastPt) then
        out.destination = compactPoint(journey.destination)
    end
    if journey.originAnchorID ~= nil then
        out.originAnchorID = journey.originAnchorID
    end
    if journey.destinationAnchorID ~= nil then
        out.destinationAnchorID = journey.destinationAnchorID
    end
    out.route = compactRoutePoints(journey.route)
    if journey.speed ~= nil and journey.speed ~= 10 then
        out.speed = journey.speed
    end
    if nonZero(journey.distanceTravelled) then
        out.distanceTravelled = journey.distanceTravelled
    end
    if nonZero(journey.waitRemainingHours) then
        out.waitRemainingHours = journey.waitRemainingHours
    end
    if journey.lastAdvancedAt ~= nil
        and journey.lastAdvancedAt ~= journey.startAt
    then
        out.lastAdvancedAt = journey.lastAdvancedAt
    end
    if journey.arrivalRadius ~= nil and journey.arrivalRadius ~= 0.5 then
        out.arrivalRadius = journey.arrivalRadius
    end
    if journey.arrivedAt ~= nil then
        out.arrivedAt = journey.arrivedAt
    end
    if journey.arrivalHandled == true then
        out.arrivalHandled = true
    end
    if journey.arrivalHandledBy ~= nil then
        out.arrivalHandledBy = journey.arrivalHandledBy
    end
    if journey.failureReason ~= nil then
        out.failureReason = journey.failureReason
    end
    if journey.revision ~= nil and journey.revision ~= 1 then
        out.revision = journey.revision
    end
    return out
end

local function compactRelations(relations)
    if isEmptyMap(relations) then return nil end
    local out = {}
    for targetID, rel in pairs(relations) do
        local entry = {}
        if nonZero(rel.standing) then entry.standing = rel.standing end
        if nonZero(rel.trust) then entry.trust = rel.trust end
        if nonZero(rel.fear) then entry.fear = rel.fear end
        if nonZero(rel.grievance) then
            entry.grievance = rel.grievance
        end
        if rel.state ~= nil and rel.state ~= "unknown" then
            entry.state = rel.state
        end
        if rel.previousState ~= nil
            and rel.previousState ~= "unknown"
        then
            entry.previousState = rel.previousState
        end
        if rel.atWar == true then entry.atWar = true end
        if rel.allied == true then entry.allied = true end
        if nonZero(rel.truceUntil) then
            entry.truceUntil = rel.truceUntil
        end
        if nonZero(rel.warStartedAt) then
            entry.warStartedAt = rel.warStartedAt
        end
        if nonZero(rel.warEndedAt) then
            entry.warEndedAt = rel.warEndedAt
        end
        if nonZero(rel.revision) then entry.revision = rel.revision end
        out[targetID] = entry
    end
    return out
end

local function compactFaction(id, f, worldSeed)
    local out = { name = f.name }
    if f.seed ~= Types.StableSeed(worldSeed, "faction", id) then
        out.seed = f.seed
    end
    if f.archetypeID ~= nil and f.archetypeID ~= "survivor.generic" then
        out.archetypeID = f.archetypeID
    end
    if f.status ~= nil and f.status ~= "active" then
        out.status = f.status
    end
    if f.leaderActorID ~= nil then
        out.leaderActorID = f.leaderActorID
    end
    if type(f.memberActorIDs) == "table" and #f.memberActorIDs > 0 then
        out.memberActorIDs = f.memberActorIDs
    end
    out.relations = compactRelations(f.relations)
    if not isEmptyMap(f.tags) then out.tags = f.tags end
    if nonZero(f.createdAt) then out.createdAt = f.createdAt end
    if nonZero(f.archivedAt) then out.archivedAt = f.archivedAt end
    if nonZero(f.revision) then out.revision = f.revision end
    out.generation = compactGeneration(f.generation)
    return out
end

local function compactCommunity(id, c, worldSeed)
    local home = compactPoint(c.home)
    if type(c.home) == "table" and nonZero(c.home.radius) then
        home.radius = c.home.radius
    end
    local out = {
        factionID = c.factionID,
        name = c.name,
        home = home,
    }
    if c.seed ~= Types.StableSeed(worldSeed, "community", id) then
        out.seed = c.seed
    end
    if c.mode ~= nil and c.mode ~= "settled" then out.mode = c.mode end
    if c.profile ~= nil then out.profile = c.profile end
    if c.status ~= nil and c.status ~= "active" then
        out.status = c.status
    end
    if c.siteID ~= nil then out.siteID = c.siteID end
    if c.leaderActorID ~= nil then
        out.leaderActorID = c.leaderActorID
    end
    local memberCount = type(c.memberActorIDs) == "table"
        and #c.memberActorIDs or 0
    if memberCount > 0 then out.memberActorIDs = c.memberActorIDs end
    if c.population ~= memberCount then
        out.population = c.population
    end
    if nonZero(c.security) then out.security = c.security end
    if nonZero(c.morale) then out.morale = c.morale end
    out.resources = compactResources(c.resources)
    if not isEmptyMap(c.tags) then out.tags = c.tags end
    if nonZero(c.createdAt) then out.createdAt = c.createdAt end
    if nonZero(c.archivedAt) then out.archivedAt = c.archivedAt end
    if nonZero(c.destroyedAt) then out.destroyedAt = c.destroyedAt end
    if nonZero(c.revision) then out.revision = c.revision end
    out.generation = compactGeneration(c.generation)
    return out
end

local function compactAbstractLocation(id, l, worldSeed)
    local out = { x = l.x, y = l.y }
    if nonZero(l.z) then out.z = l.z end
    if l.seed ~= Types.StableSeed(worldSeed, "location", id) then
        out.seed = l.seed
    end
    if l.kind ~= nil and l.kind ~= "temporary" then
        out.kind = l.kind
    end
    if not isEmptyMap(l.tags) then out.tags = l.tags end
    out.resources = compactResources(l.resources)
    if nonZero(l.scavengedLevel) then
        out.scavengedLevel = l.scavengedLevel
    end
    if nonZero(l.danger) then out.danger = l.danger end
    if nonZero(l.revision) then out.revision = l.revision end
    out.generation = compactGeneration(l.generation)
    return out
end

local function compactGroup(id, g, worldSeed)
    local out = {
        factionID = g.factionID,
        location = compactLocation(g.location),
    }
    if g.seed ~= Types.StableSeed(worldSeed, "group", id) then
        out.seed = g.seed
    end
    if g.homeCommunityID ~= nil then
        out.homeCommunityID = g.homeCommunityID
    end
    if g.groupType ~= nil and g.groupType ~= "wanderer" then
        out.groupType = g.groupType
    end
    if type(g.memberActorIDs) == "table" and #g.memberActorIDs > 0 then
        out.memberActorIDs = g.memberActorIDs
    end
    if g.leaderActorID ~= nil then
        out.leaderActorID = g.leaderActorID
    end
    if g.mission ~= nil and g.mission ~= "idle" then
        out.mission = g.mission
    end
    if g.state ~= nil and g.state ~= "idle" then out.state = g.state end
    if g.targetLocation ~= nil then
        out.targetLocation = compactLocation(g.targetLocation)
    end
    if g.journey ~= nil then
        out.journey = compactJourney(g.journey, id)
    end
    if nonZero(g.stateStartedAt) then
        out.stateStartedAt = g.stateStartedAt
    end
    if nonZero(g.stateEndsAt) then out.stateEndsAt = g.stateEndsAt end
    if nonZero(g.missionStartedAt) then
        out.missionStartedAt = g.missionStartedAt
    end
    out.resources = compactResources(g.resources)
    if nonZero(g.morale) then out.morale = g.morale end
    if not isEmptyMap(g.tags) then out.tags = g.tags end
    if nonZero(g.revision) then out.revision = g.revision end
    out.generation = compactGeneration(g.generation)
    return out
end

local function compactPopulation(pop)
    if type(pop) ~= "table" then return nil end
    local out = {}
    if pop.worldSeedString ~= nil then
        out.worldSeedString = pop.worldSeedString
    end
    if pop.nextGenerationSerial ~= nil
        and pop.nextGenerationSerial ~= 1
    then
        out.nextGenerationSerial = pop.nextGenerationSerial
    end
    if pop.bootstrapCompleted == true then
        out.bootstrapCompleted = true
    end
    if nonZero(pop.bootstrapCompletedAt) then
        out.bootstrapCompletedAt = pop.bootstrapCompletedAt
    end
    if pop.starterCommunityID ~= nil then
        out.starterCommunityID = pop.starterCommunityID
    end
    if nonZero(pop.starterAttempts) then
        out.starterAttempts = pop.starterAttempts
    end
    if not isEmptyMap(pop.sectors) then
        local sectors = {}
        for id, s in pairs(pop.sectors) do
            local entry = {}
            if s.discovered == true then entry.discovered = true end
            if s.hadGroups == true then entry.hadGroups = true end
            if s.hadCommunities == true then
                entry.hadCommunities = true
            end
            if nonZero(s.groupGenerationCooldownUntil) then
                entry.groupGenerationCooldownUntil =
                    s.groupGenerationCooldownUntil
            end
            if nonZero(s.communityGenerationCooldownUntil) then
                entry.communityGenerationCooldownUntil =
                    s.communityGenerationCooldownUntil
            end
            if nonZero(s.lastReconciledAt) then
                entry.lastReconciledAt = s.lastReconciledAt
            end
            sectors[id] = entry
        end
        out.sectors = sectors
    end
    if not isEmptyMap(pop.siteHistory) then
        local history = {}
        for id, h in pairs(pop.siteHistory) do
            local entry = {}
            if h.formerCommunity == true then
                entry.formerCommunity = true
            end
            if nonZero(h.destroyedAt) then
                entry.destroyedAt = h.destroyedAt
            end
            if nonZero(h.regenerationBlockedUntil) then
                entry.regenerationBlockedUntil =
                    h.regenerationBlockedUntil
            end
            history[id] = entry
        end
        out.siteHistory = history
    end
    if not isEmptyMap(pop.provenance) then
        local provenance = {}
        for id, gen in pairs(pop.provenance) do
            local compactGen = compactGeneration(gen)
            if compactGen then provenance[id] = compactGen end
        end
        if not isEmptyMap(provenance) then out.provenance = provenance end
    end
    if type(pop.committedOrder) == "table"
        and #pop.committedOrder > 0
    then
        out.committedOrder = pop.committedOrder
    end
    return isEmptyMap(out) and nil or out
end

local function compactDiscoveryEntry(e)
    local out = {}
    if nonZero(e.phase) then out.phase = e.phase end
    if e.source ~= nil and e.source ~= "unknown" then
        out.source = e.source
    end
    if nonZero(e.discoveredAt) then
        out.discoveredAt = e.discoveredAt
    end
    if nonZero(e.updatedAt) then out.updatedAt = e.updatedAt end
    if e.x ~= nil and e.y ~= nil then
        out.x = e.x
        out.y = e.y
        if nonZero(e.z) then out.z = e.z end
    end
    if e.arrivalState ~= nil and e.arrivalState ~= "unchecked" then
        out.arrivalState = e.arrivalState
    end
    if nonZero(e.searchedAt) then out.searchedAt = e.searchedAt end
    if nonZero(e.contactedAt) then out.contactedAt = e.contactedAt end
    if e.presenceStatus ~= nil and e.presenceStatus ~= "unknown" then
        out.presenceStatus = e.presenceStatus
    end
    if e.factionKnown == true then out.factionKnown = true end
    if e.factionID ~= nil then out.factionID = e.factionID end
    if e.factionName ~= nil then out.factionName = e.factionName end
    return out
end

local function compactDiscovery(disc)
    if type(disc) ~= "table" then return nil end
    local out = {}
    if nonZero(disc.revision) then out.revision = disc.revision end
    if not isEmptyMap(disc.players) then
        local players = {}
        for playerID, p in pairs(disc.players) do
            local pOut = {}
            if nonZero(p.revision) then pOut.revision = p.revision end
            if nonZero(p.lastRadioScanAt) then
                pOut.lastRadioScanAt = p.lastRadioScanAt
            end
            if nonZero(p.radioScanCount) then
                pOut.radioScanCount = p.radioScanCount
            end
            if type(p.entities) == "table" then
                local entities = nil
                for kind, bucket in pairs(p.entities) do
                    if not isEmptyMap(bucket) then
                        if not entities then entities = {} end
                        local cBucket = {}
                        for entityID, entry in pairs(bucket) do
                            cBucket[entityID] =
                                compactDiscoveryEntry(entry)
                        end
                        entities[kind] = cBucket
                    end
                end
                if entities then pOut.entities = entities end
            end
            players[playerID] = pOut
        end
        out.players = players
    end
    return isEmptyMap(out) and nil or out
end

local function compactMap(source, compactor, worldSeed)
    if isEmptyMap(source) then return nil end
    local out = {}
    for id, record in pairs(source) do
        out[id] = compactor(id, record, worldSeed)
    end
    return out
end

local function compactSnapshot(snapshot)
    local worldSeed = snapshot.worldSeed
    local out = {
        worldSeed = worldSeed,
    }
    if nonZero(snapshot.revision) then
        out.revision = snapshot.revision
    end
    out.factions = compactMap(snapshot.factions, compactFaction, worldSeed)
    out.communities = compactMap(
        snapshot.communities,
        compactCommunity,
        worldSeed
    )
    out.locations = compactMap(
        snapshot.locations,
        compactAbstractLocation,
        worldSeed
    )
    out.groups = compactMap(snapshot.groups, compactGroup, worldSeed)
    out.population = compactPopulation(snapshot.population)
    out.discovery = compactDiscovery(snapshot.discovery)
    return out
end

local function validateEnvelope(payload)
    if type(payload) ~= "table"
        or payload.schema ~= Persistence.SCHEMA
        or tonumber(payload.schemaVersion)
            ~= Persistence.SCHEMA_VERSION
        or type(payload.world) ~= "table"
    then
        return nil, "survivor_world_registry_schema_mismatch"
    end
    local bounded, reason = Types.ValidateInputBounds(payload.world)
    if not bounded then return nil, reason end
    local normalized = Types.NormalizeSnapshot(payload.world)
    local valid
    valid, reason = Types.ValidateSnapshot(normalized)
    if not valid then return nil, reason end
    return normalized
end

local function encodeValidated(normalized)
    return {
        schema = Persistence.SCHEMA,
        schemaVersion = Persistence.SCHEMA_VERSION,
        world = compactSnapshot(normalized),
    }
end

function Persistence.Encode(snapshot)
    local bounded, reason = Types.ValidateInputBounds(snapshot)
    if not bounded then return nil, reason end
    local normalized = Types.NormalizeSnapshot(snapshot)
    local valid
    valid, reason = Types.ValidateSnapshot(normalized)
    if not valid then return nil, reason end
    return encodeValidated(normalized)
end

function Persistence.SerializeNormalized(normalized)
    local valid, reason = Types.ValidateSnapshot(normalized)
    if not valid then return nil, reason end
    local payload = encodeValidated(normalized)
    local encoded = Json.Encode(payload, Persistence.JSON_LIMITS)
    if not encoded then return nil, "survivor_world_encode_failed" end
    if #encoded > Persistence.MAX_BYTES then
        return nil, "survivor_world_payload_too_large"
    end
    return encoded
end

function Persistence.Serialize(snapshot)
    local payload, reason = Persistence.Encode(snapshot)
    if not payload then return nil, reason end
    local encoded = Json.Encode(payload, Persistence.JSON_LIMITS)
    if not encoded then return nil, "survivor_world_encode_failed" end
    if #encoded > Persistence.MAX_BYTES then
        return nil, "survivor_world_payload_too_large"
    end
    return encoded
end

function Persistence.Decode(serialized)
    local payload = serialized
    if type(serialized) == "string" then
        if #serialized > Persistence.MAX_BYTES then
            return nil, "survivor_world_payload_too_large"
        end
        local reason
        payload, reason = Json.Decode(
            serialized,
            Persistence.JSON_LIMITS
        )
        if payload == nil then
            return nil, reason or "survivor_world_decode_failed"
        end
    else
        payload = Util.clone(serialized)
    end
    return validateEnvelope(payload)
end

return Persistence
