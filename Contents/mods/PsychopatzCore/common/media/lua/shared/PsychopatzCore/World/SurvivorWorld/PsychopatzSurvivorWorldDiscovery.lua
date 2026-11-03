local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Types = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldTypes"

local Discovery = {}

Discovery.PHASE_UNKNOWN = 0
Discovery.PHASE_RUMORED = 1
Discovery.PHASE_LOCATED = 2
Discovery.PHASE_CONTACTED = 3
Discovery.PHASE_NAMES = {
    [0] = "UNKNOWN",
    [1] = "RUMORED",
    [2] = "LOCATED",
    [3] = "CONTACTED",
}
Discovery.ARRIVAL_UNCHECKED = "unchecked"
Discovery.ARRIVAL_SEARCHED = "searched"
Discovery.ARRIVAL_CONTACTED = "contacted"
Discovery.PRESENCE_UNKNOWN = "unknown"
Discovery.PRESENCE_PRESENT = "present"
Discovery.PRESENCE_ABSENT = "absent"
Discovery.EntityProviders =
    Discovery.EntityProviders or {}

local VALID_KIND = {
    community = true,
    group = true,
    signal = true,
}

local function safeID(value)
    return Types.SafeID(value)
end

function Discovery.Kind(value)
    value = tostring(value or "")
    if value == "settlement" then return "community" end
    if value == "mobile_group" then return "group" end
    return VALID_KIND[value] and value or nil
end

function Discovery.ClampPhase(value)
    return math.max(
        Discovery.PHASE_UNKNOWN,
        math.min(
            Discovery.PHASE_CONTACTED,
            math.floor(tonumber(value) or 0)
        )
    )
end

function Discovery.PhaseName(value)
    return Discovery.PHASE_NAMES[
        Discovery.ClampPhase(value)
    ] or "UNKNOWN"
end

function Discovery.ArrivalState(value)
    value = tostring(value or "")
    if value == Discovery.ARRIVAL_CONTACTED then
        return Discovery.ARRIVAL_CONTACTED
    end
    if value == Discovery.ARRIVAL_SEARCHED then
        return Discovery.ARRIVAL_SEARCHED
    end
    return Discovery.ARRIVAL_UNCHECKED
end

function Discovery.PresenceStatus(value)
    value = tostring(value or "")
    if value == Discovery.PRESENCE_PRESENT then
        return Discovery.PRESENCE_PRESENT
    end
    if value == Discovery.PRESENCE_ABSENT then
        return Discovery.PRESENCE_ABSENT
    end
    return Discovery.PRESENCE_UNKNOWN
end

local function playerKey(value)
    return safeID(value)
end

local function entityPoint(value)
    if type(value) ~= "table" then return nil end
    local x = tonumber(value.x)
    local y = tonumber(value.y)
    if not x or not y then return nil end
    return {
        x = x,
        y = y,
        z = tonumber(value.z) or 0,
    }
end

local function factionInfo(registry, factionID)
    local faction = factionID
        and registry:GetFaction(factionID) or nil
    return faction and faction.name or nil,
        faction and faction.archetypeID or nil
end

local function communityEntity(registry, community)
    if not community or community.status ~= "active" then
        return nil
    end
    local home = community.home or {}
    if tonumber(home.x) == nil or tonumber(home.y) == nil then
        return nil
    end
    local factionName, archetypeID =
        factionInfo(registry, community.factionID)
    return {
        entityID = community.id,
        kind = "community",
        name = community.name,
        factionID = community.factionID,
        factionName = factionName,
        archetypeID = archetypeID,
        x = tonumber(home.x),
        y = tonumber(home.y),
        z = tonumber(home.z) or 0,
        population = tonumber(community.population)
            or #(community.memberActorIDs or {}),
        status = community.status,
    }
end

local function groupEntity(registry, group, now)
    if not group then return nil end
    local position = registry:ProjectGroupPosition(
        group.id,
        now
    )
    position = entityPoint(position)
        or entityPoint(group.location)
    if not position then return nil end
    local factionName, archetypeID =
        factionInfo(registry, group.factionID)
    return {
        entityID = group.id,
        kind = "group",
        name = factionName
            or group.groupType
            or "Mobile group",
        factionID = group.factionID,
        factionName = factionName,
        archetypeID = archetypeID,
        groupType = group.groupType,
        x = position.x,
        y = position.y,
        z = position.z,
        population = #(group.memberActorIDs or {}),
        state = group.state,
        mission = group.mission,
    }
end

function Discovery.RegisterEntityProvider(id, definition)
    id = tostring(id or "")
    if id == ""
        or type(definition) ~= "table"
        or type(definition.list) ~= "function"
    then
        return false, "invalid_discovery_provider"
    end
    Discovery.EntityProviders[id] = {
        priority = tonumber(definition.priority) or 100,
        list = definition.list,
    }
    return true
end

function Discovery.UnregisterEntityProvider(id)
    id = tostring(id or "")
    if id == "" or not Discovery.EntityProviders[id] then
        return false
    end
    Discovery.EntityProviders[id] = nil
    return true
end

local function providerList()
    local output = {}
    for id, definition in pairs(Discovery.EntityProviders) do
        output[#output + 1] = {
            id = id,
            priority = tonumber(definition.priority) or 100,
            list = definition.list,
        }
    end
    table.sort(output, function(left, right)
        if left.priority == right.priority then
            return left.id < right.id
        end
        return left.priority > right.priority
    end)
    return output
end

local function normalizeExternalEntity(value, providerID)
    value = type(value) == "table" and value or {}
    local kind = Discovery.Kind(value.kind)
    local id = safeID(
        value.entityID
            or value.id
            or value.signalID
    )
    local position = entityPoint(
        value.position or value
    )
    if not kind or not id or not position then return nil end
    return {
        entityID = id,
        kind = kind,
        name = tostring(value.name or id),
        factionID = safeID(
            value.factionID or value.factionId
        ),
        factionName = value.factionName
            and tostring(value.factionName) or nil,
        archetypeID = value.archetypeID
            and tostring(value.archetypeID) or nil,
        x = position.x,
        y = position.y,
        z = position.z,
        population = tonumber(value.population),
        provider = providerID,
    }
end

function Discovery.ListWorldEntities(registry, now)
    if type(registry) ~= "table" then return {} end
    local output = {}
    local seen = {}

    for _, community in ipairs(
        registry:ListCommunities()
    ) do
        local entity = communityEntity(
            registry,
            community
        )
        if entity then
            local key = entity.kind .. ":" .. entity.entityID
            seen[key] = true
            output[#output + 1] = entity
        end
    end

    for _, group in ipairs(registry:ListGroups()) do
        local entity = groupEntity(
            registry,
            group,
            now
        )
        if entity then
            local key = entity.kind .. ":" .. entity.entityID
            seen[key] = true
            output[#output + 1] = entity
        end
    end

    for _, provider in ipairs(providerList()) do
        local ok, entities = pcall(
            provider.list,
            registry,
            now
        )
        if ok and type(entities) == "table" then
            for _, value in ipairs(entities) do
                local entity = normalizeExternalEntity(
                    value,
                    provider.id
                )
                if entity then
                    local key =
                        entity.kind .. ":" .. entity.entityID
                    if not seen[key] then
                        seen[key] = true
                        output[#output + 1] = entity
                    end
                end
            end
        end
    end

    table.sort(output, function(left, right)
        if left.kind ~= right.kind then
            return left.kind < right.kind
        end
        return left.entityID < right.entityID
    end)
    return output
end

function Discovery.ResolveEntity(registry, kind, id, now)
    kind = Discovery.Kind(kind)
    id = safeID(id)
    if not kind or not id then return nil end
    for _, entity in ipairs(
        Discovery.ListWorldEntities(registry, now)
    ) do
        if entity.kind == kind
            and entity.entityID == id
        then
            return entity
        end
    end
    return nil
end

local function emptyPlayer()
    return {
        revision = 0,
        lastRadioScanAt = 0,
        radioScanCount = 0,
        entities = {
            community = {},
            group = {},
            signal = {},
        },
    }
end

local function mutateDiscovery(registry, key, mutator)
    key = playerKey(key)
    if not key then return nil, "player_key_required" end
    local discovery = registry:GetDiscovery()
    discovery.players = discovery.players or {}
    local player = discovery.players[key] or emptyPlayer()
    local result, reason, changed = mutator(
        player,
        discovery
    )
    if changed == true then
        player.revision =
            math.max(0, tonumber(player.revision) or 0) + 1
        discovery.revision =
            math.max(0, tonumber(discovery.revision) or 0) + 1
        discovery.players[key] = player
        registry:SetDiscovery(discovery)
    end
    return result, reason, changed
end

local function ensureEntry(player, entity, now, source)
    local entries = player.entities[entity.kind]
    local current = entries[entity.entityID]
    if current then return current, false end
    current = {
        entityID = entity.entityID,
        kind = entity.kind,
        phase = Discovery.PHASE_UNKNOWN,
        source = tostring(source or "unknown"),
        discoveredAt = math.max(0, tonumber(now) or 0),
        updatedAt = math.max(0, tonumber(now) or 0),
        x = entity.x,
        y = entity.y,
        z = entity.z or 0,
        arrivalState = Discovery.ARRIVAL_UNCHECKED,
        searchedAt = 0,
        contactedAt = 0,
        presenceStatus = Discovery.PRESENCE_UNKNOWN,
        factionKnown = false,
    }
    entries[entity.entityID] = current
    return current, true
end

function Discovery.SetPhase(
    registry,
    key,
    kind,
    entityID,
    phase,
    source,
    now
)
    local entity = Discovery.ResolveEntity(
        registry,
        kind,
        entityID,
        now
    )
    if not entity then return nil, "entity_not_found" end
    local nextPhase = Discovery.ClampPhase(phase)
    return mutateDiscovery(
        registry,
        key,
        function(player)
            local current, created =
                ensureEntry(
                    player,
                    entity,
                    now,
                    source
                )
            if Discovery.ClampPhase(current.phase)
                >= nextPhase
            then
                return Util.clone(current),
                    "unchanged",
                    created
            end
            current.phase = nextPhase
            current.source = tostring(
                source or current.source or "unknown"
            )
            current.updatedAt =
                math.max(0, tonumber(now) or 0)
            current.x = entity.x
            current.y = entity.y
            current.z = entity.z or 0
            return Util.clone(current),
                "advanced",
                true
        end
    )
end

function Discovery.MarkFactionKnown(
    registry,
    key,
    kind,
    entityID,
    source,
    now
)
    local entity = Discovery.ResolveEntity(
        registry,
        kind,
        entityID,
        now
    )
    if not entity then return nil, "entity_not_found" end
    if not entity.factionID
        and not entity.factionName
    then
        return nil, "faction_unavailable"
    end
    return mutateDiscovery(
        registry,
        key,
        function(player)
            local current, created =
                ensureEntry(
                    player,
                    entity,
                    now,
                    source
                )
            local changed = created
            if current.factionKnown ~= true then
                current.factionKnown = true
                changed = true
            end
            if current.factionID ~= entity.factionID then
                current.factionID = entity.factionID
                changed = true
            end
            if current.factionName ~= entity.factionName then
                current.factionName = entity.factionName
                changed = true
            end
            if current.phase < Discovery.PHASE_RUMORED then
                current.phase = Discovery.PHASE_RUMORED
                changed = true
            end
            if changed then
                current.source = tostring(
                    source or current.source or "unknown"
                )
                current.updatedAt =
                    math.max(0, tonumber(now) or 0)
            end
            return Util.clone(current),
                changed and "advanced" or "unchanged",
                changed
        end
    )
end

local function markArrival(
    registry,
    key,
    kind,
    entityID,
    contacted,
    presence,
    source,
    now
)
    local entity = Discovery.ResolveEntity(
        registry,
        kind,
        entityID,
        now
    )
    if not entity then return nil, "entity_not_found" end
    return mutateDiscovery(
        registry,
        key,
        function(player)
            local current, created =
                ensureEntry(
                    player,
                    entity,
                    now,
                    source
                )
            local changed = created
            local targetPhase = contacted
                and Discovery.PHASE_CONTACTED
                or Discovery.PHASE_LOCATED
            if current.phase < targetPhase then
                current.phase = targetPhase
                changed = true
            end
            local arrival = contacted
                and Discovery.ARRIVAL_CONTACTED
                or Discovery.ARRIVAL_SEARCHED
            if Discovery.ArrivalState(current.arrivalState)
                ~= arrival
                and current.arrivalState
                    ~= Discovery.ARRIVAL_CONTACTED
            then
                current.arrivalState = arrival
                changed = true
            end
            if contacted
                and (tonumber(current.contactedAt) or 0) <= 0
            then
                current.contactedAt =
                    math.max(0, tonumber(now) or 0)
                changed = true
            end
            if (tonumber(current.searchedAt) or 0) <= 0 then
                current.searchedAt =
                    math.max(0, tonumber(now) or 0)
                changed = true
            end
            local nextPresence =
                Discovery.PresenceStatus(presence)
            if contacted then
                nextPresence =
                    Discovery.PRESENCE_PRESENT
            end
            if nextPresence ~= Discovery.PRESENCE_UNKNOWN
                and (
                    current.presenceStatus
                        ~= Discovery.PRESENCE_PRESENT
                    or nextPresence
                        == Discovery.PRESENCE_PRESENT
                )
                and current.presenceStatus ~= nextPresence
            then
                current.presenceStatus = nextPresence
                changed = true
            end
            if contacted then
                current.factionKnown =
                    entity.factionID ~= nil
                        or entity.factionName ~= nil
                current.factionID = entity.factionID
                current.factionName = entity.factionName
            end
            if changed then
                current.source = tostring(
                    source or current.source or "unknown"
                )
                current.updatedAt =
                    math.max(0, tonumber(now) or 0)
                current.x = entity.x
                current.y = entity.y
                current.z = entity.z or 0
            end
            return Util.clone(current),
                changed and "advanced" or "unchanged",
                changed
        end
    )
end

function Discovery.MarkArrived(
    registry,
    key,
    kind,
    entityID,
    presence,
    source,
    now
)
    return markArrival(
        registry,
        key,
        kind,
        entityID,
        false,
        presence,
        source or "traversal",
        now
    )
end

function Discovery.MarkContacted(
    registry,
    key,
    kind,
    entityID,
    source,
    now
)
    return markArrival(
        registry,
        key,
        kind,
        entityID,
        true,
        Discovery.PRESENCE_PRESENT,
        source or "contact",
        now
    )
end

function Discovery.ResetPlayer(registry, key)
    return mutateDiscovery(
        registry,
        key,
        function(player)
            player.lastRadioScanAt = 0
            player.radioScanCount = 0
            player.entities = {
                community = {},
                group = {},
                signal = {},
            }
            return Util.clone(player), "reset", true
        end
    )
end

local function scopeMatches(scope, kind)
    scope = tostring(scope or "all")
    if scope == "all" or scope == "signals" then
        return scope == "all" or kind == "signal"
    end
    if scope == "settlements"
        or scope == "communities"
    then
        return kind == "community"
    end
    if scope == "mobile_groups"
        or scope == "groups"
    then
        return kind == "group"
    end
    return false
end

function Discovery.DiscoverAll(
    registry,
    key,
    scope,
    phase,
    source,
    now
)
    key = playerKey(key)
    if not key then return nil, "player_key_required" end
    local entities =
        Discovery.ListWorldEntities(registry, now)
    local changed = 0
    for _, entity in ipairs(entities) do
        if scopeMatches(scope, entity.kind) then
            local _, _, didChange = Discovery.SetPhase(
                registry,
                key,
                entity.kind,
                entity.entityID,
                phase or Discovery.PHASE_LOCATED,
                source or "debug",
                now
            )
            if didChange then changed = changed + 1 end
        end
    end
    return changed, "discovered"
end

local function approximate(value, id, axis)
    local hash = axis == "x" and 17 or 31
    local token = tostring(id or "") .. axis
    for index = 1, #token do
        hash = (hash * 33 + string.byte(token, index)) % 9973
    end
    return tonumber(value)
        + ((hash % 161) - 80)
end

function Discovery.BuildSnapshot(registry, key, now)
    key = playerKey(key)
    if not key then
        return {
            state = "error",
            reason = "player_key_required",
            entities = {},
        }
    end
    local discovery = registry:GetDiscovery()
    local player = discovery.players[key] or emptyPlayer()
    local current = {}
    for _, entity in ipairs(
        Discovery.ListWorldEntities(registry, now)
    ) do
        current[
            entity.kind .. ":" .. entity.entityID
        ] = entity
    end

    local entities = {}
    for _, kind in ipairs({
        "community",
        "group",
        "signal",
    }) do
        for entityID, entry in pairs(
            player.entities[kind] or {}
        ) do
            local live =
                current[kind .. ":" .. entityID]
            local phase =
                Discovery.ClampPhase(entry.phase)
            local x = live and live.x or entry.x
            local y = live and live.y or entry.y
            if phase == Discovery.PHASE_RUMORED
                and x ~= nil and y ~= nil
            then
                x = approximate(x, entityID, "x")
                y = approximate(y, entityID, "y")
            end
            local factionKnown =
                entry.factionKnown == true
                    or phase >= Discovery.PHASE_CONTACTED
            local factionID = factionKnown
                and (entry.factionID
                    or live and live.factionID)
                or nil
            local factionName = factionKnown
                and (entry.factionName
                    or live and live.factionName)
                or nil
            entities[#entities + 1] = {
                entityID = entityID,
                kind = kind,
                phase = phase,
                phaseName =
                    Discovery.PhaseName(phase),
                source = entry.source,
                discoveredAt = entry.discoveredAt,
                updatedAt = entry.updatedAt,
                arrivalState =
                    Discovery.ArrivalState(
                        entry.arrivalState
                    ),
                searchedAt =
                    tonumber(entry.searchedAt) or 0,
                contactedAt =
                    tonumber(entry.contactedAt) or 0,
                presenceStatus =
                    Discovery.PresenceStatus(
                        entry.presenceStatus
                    ),
                name = phase
                    >= Discovery.PHASE_CONTACTED
                    and live and live.name or nil,
                factionID = factionID,
                factionKnown = factionKnown,
                factionName = factionName,
                groupType = phase
                    >= Discovery.PHASE_LOCATED
                    and live and live.groupType
                    or nil,
                population = phase
                    >= Discovery.PHASE_CONTACTED
                    and live and live.population
                    or nil,
                x = x,
                y = y,
                z = live and live.z
                    or entry.z or 0,
                approximate =
                    phase == Discovery.PHASE_RUMORED,
            }
        end
    end
    table.sort(entities, function(left, right)
        if left.kind ~= right.kind then
            return left.kind < right.kind
        end
        return left.entityID < right.entityID
    end)
    return {
        state = "known",
        playerKey = key,
        revision = tonumber(player.revision) or 0,
        entities = entities,
        lastRadioScanAt =
            tonumber(player.lastRadioScanAt) or 0,
        radioScanCount =
            tonumber(player.radioScanCount) or 0,
        serverWorldHour = tonumber(now) or 0,
    }
end

function Discovery.DiscoverNearby(
    registry,
    key,
    position,
    ranges,
    source,
    now
)
    position = entityPoint(position)
    if not position then
        return nil, "position_required"
    end
    ranges = type(ranges) == "table"
        and ranges or {}
    local changed = 0
    for _, entity in ipairs(
        Discovery.ListWorldEntities(registry, now)
    ) do
        local radius = math.max(
            0,
            tonumber(
                ranges[entity.kind]
                    or ranges.default
                    or 0
            ) or 0
        )
        if radius > 0 then
            local dx = position.x - entity.x
            local dy = position.y - entity.y
            if dx * dx + dy * dy <= radius * radius then
                local _, _, didChange =
                    Discovery.SetPhase(
                        registry,
                        key,
                        entity.kind,
                        entity.entityID,
                        Discovery.PHASE_LOCATED,
                        source or "proximity",
                        now
                    )
                if didChange then changed = changed + 1 end
            end
        end
    end
    return changed, "scanned"
end

return Discovery
