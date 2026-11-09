local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local ActorPresentation = require
    "PsychopatzCore/Actors/PsychopatzActorPresentation"
local ActorProjection = require
    "PsychopatzCore/Actors/PsychopatzActorProjection"

local Presentation = {}

Presentation.SOURCE_ID = "SurvivorWorld"
Presentation.AFFILIATION_EXTENSION =
    "PsychopatzCore.SurvivorWorld"
Presentation.DEFAULT_OVERLAP_RADIUS = 3.0
Presentation.PositionProviders =
    Presentation.PositionProviders or {}

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return tonumber(fallback)
    end
    return value
end

local function point(value)
    if type(value) ~= "table" then return nil end
    local x = finite(value.x)
    local y = finite(value.y)
    if x == nil or y == nil then return nil end
    return {
        x = x,
        y = y,
        z = finite(value.z, 0) or 0,
    }
end

local function affiliation(actor)
    local extensions = actor
        and type(actor.extensions) == "table"
        and actor.extensions or {}
    local value = extensions[Presentation.AFFILIATION_EXTENSION]
    return type(value) == "table" and value or {}
end

local function contextIndex(worldRegistry)
    local groupsByActor = {}
    for _, group in ipairs(
        worldRegistry and worldRegistry:ListGroups() or {}
    ) do
        for _, actorID in ipairs(group.memberActorIDs or {}) do
            groupsByActor[tostring(actorID)] = group
        end
    end
    return groupsByActor
end

local function providerList()
    local output = {}
    for id, definition in pairs(Presentation.PositionProviders) do
        output[#output + 1] = {
            id = id,
            priority = tonumber(definition.priority) or 100,
            resolve = definition.resolve,
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

function Presentation.RegisterPositionProvider(id, definition)
    id = tostring(id or "")
    if id == ""
        or type(definition) ~= "table"
        or type(definition.resolve) ~= "function"
    then
        return false, "invalid_position_provider"
    end
    Presentation.PositionProviders[id] = {
        priority = tonumber(definition.priority) or 100,
        resolve = definition.resolve,
    }
    return true
end

function Presentation.UnregisterPositionProvider(id)
    id = tostring(id or "")
    if id == "" or not Presentation.PositionProviders[id] then
        return false
    end
    Presentation.PositionProviders[id] = nil
    return true
end

function Presentation.ResolvePosition(
    worldRegistry,
    actor,
    group,
    now
)
    local context = {
        worldRegistry = worldRegistry,
        actor = actor,
        group = group,
        now = now,
    }
    for _, definition in ipairs(providerList()) do
        local ok, resolved = pcall(
            definition.resolve,
            actor,
            context
        )
        local value = ok and point(resolved) or nil
        if value then return value, definition.id end
    end

    local actorID = actor and actor.actorId
    if group and actorID and worldRegistry
        and type(worldRegistry.ProjectGroupMemberPosition) == "function"
    then
        local projected = worldRegistry:ProjectGroupMemberPosition(
            group.id,
            actorID,
            actor.world,
            now
        )
        projected = point(projected)
        if projected then return projected, "group" end
    end

    local world = actor and actor.world
    local location = world and world.location
    return point(location and location.position), "actor"
end

local function roleFor(actor, group)
    local ext = affiliation(actor)
    if ext.role ~= nil then return tostring(ext.role) end
    if group and group.leaderActorID == actor.actorId then
        return "leader"
    end
    return "member"
end

local function metadata(actor, group)
    local ext = affiliation(actor)
    return {
        groupID = group and group.id or ext.groupID,
        communityID = group and group.homeCommunityID
            or ext.communityID,
        factionID = group and group.factionID or ext.factionID,
        factionName = group and group.factionName or ext.factionName,
        factionArchetypeID = group
            and group.factionArchetypeID
            or ext.factionArchetypeID,
        factionPresentation = group
            and group.factionPresentation
            or ext.factionPresentation,
        role = roleFor(actor, group),
    }
end

function Presentation.BuildActorEntry(
    worldRegistry,
    actor,
    group,
    now,
    spec
)
    if type(actor) ~= "table" then
        return nil, "actor_required"
    end
    spec = type(spec) == "table" and spec or {}

    local position, positionSource =
        Presentation.ResolvePosition(
            worldRegistry,
            actor,
            group,
            now
        )
    if not position then
        return nil, "actor_position_required"
    end

    local meta = metadata(actor, group)
    if worldRegistry
        and type(worldRegistry.GetFaction) == "function"
        and meta.factionID
    then
        local faction = worldRegistry:GetFaction(meta.factionID)
        if type(faction) == "table" then
            meta.factionName = meta.factionName or faction.name
            meta.factionArchetypeID = meta.factionArchetypeID
                or faction.archetypeID
            meta.factionPresentation = meta.factionPresentation
                or faction
        end
    end
    local portrait = ActorPresentation.BuildPortrait(actor)
    local entry, reason = ActorProjection.ProjectActor(
        actor,
        now,
        {
            sourceID = spec.sourceID
                or Presentation.SOURCE_ID,
            provider = actor.providerLease
                and actor.providerLease.provider
                or actor.ownerMod,
            providerState = actor.providerLease
                and actor.providerLease.state,
            bodyID = actor.providerLease
                and actor.providerLease.bodyID,
            position = position,
            journey = group and group.journey or nil,
            groupID = meta.groupID,
            communityID = meta.communityID,
            factionID = meta.factionID,
            factionName = meta.factionName,
            factionArchetypeID = meta.factionArchetypeID,
            factionPresentation = meta.factionPresentation,
            role = meta.role,
            markerID = spec.markerID or "npc",
            label = actor.identity
                and actor.identity.displayName
                or actor.actorId,
            capabilities = spec.capabilities or {
                inspect = true,
                select = true,
                track = true,
            },
            portrait = portrait,
        }
    )
    if not entry then return nil, reason end
    entry.positionSource = positionSource
    return entry
end

function Presentation.BuildActorEntries(
    worldRegistry,
    actorRegistry,
    now,
    spec
)
    if type(worldRegistry) ~= "table"
        or type(actorRegistry) ~= "table"
        or type(actorRegistry.List) ~= "function"
    then
        return {}
    end

    local groupsByActor = contextIndex(worldRegistry)
    local output = {}
    for _, actor in ipairs(actorRegistry:List()) do
        local ext = affiliation(actor)
        local group = groupsByActor[tostring(actor.actorId)]
        local isSurvivorWorldActor = group ~= nil
            or ext.groupID ~= nil
            or ext.communityID ~= nil
            or ext.factionID ~= nil
        if isSurvivorWorldActor then
            local entry = Presentation.BuildActorEntry(
                worldRegistry,
                actor,
                group,
                now,
                spec
            )
            if entry then output[#output + 1] = entry end
        end
    end
    table.sort(output, function(left, right)
        return tostring(left.actorID) < tostring(right.actorID)
    end)
    return output
end

-- Reuse authoritative journey math for display only. Provider-owned physical
-- bodies never extrapolate from a group journey. Anchor the delta at the
-- snapshot time to preserve the server's per-member position/offset.
function Presentation.ProjectActorPosition(entry, now)
    local base = point(entry and entry.position)
    local raw = entry and entry.journey
    local at = finite(entry and entry.updatedAt)
    now = finite(now)
    if not base or entry.positionSource ~= "group"
        or entry.providerState == "materialized" or entry.providerState == "live"
        or type(raw) ~= "table" or at == nil or now == nil or now < at
        or type(raw.route) ~= "table" or finite(raw.distanceTotal) == nil
        or finite(raw.speed) == nil or raw.speed <= 0
    then return base end
    local Journey = require
        "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldGroupJourney"
    local journey = Journey.Normalize(raw, raw.groupID or entry.groupID, at)
    if not journey or (finite(raw.distanceTotal) ~= nil
        and math.abs(journey.distanceTotal - raw.distanceTotal) > 0.01)
    then return base end -- A bounded/truncated route cannot be extrapolated safely.
    local previous = Journey.ProjectPosition(journey, at)
    local current = Journey.ProjectPosition(journey, now)
    if not previous or not current then return base end
    return { x = base.x + current.x - previous.x,
        y = base.y + current.y - previous.y,
        z = base.z + current.z - previous.z }
end

local function positionKey(position, precision)
    precision = math.max(1, math.floor(tonumber(precision) or 100))
    return tostring(math.floor(position.x * precision + 0.5))
        .. ":"
        .. tostring(math.floor(position.y * precision + 0.5))
        .. ":"
        .. tostring(math.floor((position.z or 0) * precision + 0.5))
end

function Presentation.SpreadOverlaps(entries, spec)
    spec = type(spec) == "table" and spec or {}
    local radius = math.max(
        0,
        finite(spec.radius, Presentation.DEFAULT_OVERLAP_RADIUS) or 0
    )
    local groups = {}
    local output = {}

    for _, entry in ipairs(type(entries) == "table" and entries or {}) do
        if type(entry) == "table"
            and type(entry.position) == "table"
        then
            local copy = Util.clone(entry)
            copy.canonicalPosition = Util.clone(entry.position)
            local key = positionKey(entry.position, spec.precision)
            groups[key] = groups[key] or {}
            groups[key][#groups[key] + 1] = copy
        end
    end

    for _, bucket in pairs(groups) do
        table.sort(bucket, function(left, right)
            return tostring(left.actorID) < tostring(right.actorID)
        end)
        local count = #bucket
        for index, entry in ipairs(bucket) do
            entry.overlapIndex = index
            entry.overlapCount = count
            if count > 1 and radius > 0 then
                local angle = (index - 1)
                    * (math.pi * 2 / count)
                entry.position.x =
                    entry.canonicalPosition.x
                        + math.cos(angle) * radius
                entry.position.y =
                    entry.canonicalPosition.y
                        + math.sin(angle) * radius
            end
            output[#output + 1] = entry
        end
    end

    table.sort(output, function(left, right)
        return tostring(left.actorID) < tostring(right.actorID)
    end)
    return output
end

function Presentation.JourneyPoints(entry)
    local journey = entry and entry.journey
    if type(journey) ~= "table" then return {} end
    local route = type(journey.route) == "table"
        and journey.route.points or nil
    if type(route) == "table" and #route >= 2 then
        return Util.clone(route)
    end
    local output = {}
    local origin = point(journey.origin)
    local destination = point(journey.destination)
    if origin then output[#output + 1] = origin end
    if destination then output[#output + 1] = destination end
    return output
end

function Presentation.NewSelection()
    return {
        selectedActorID = nil,
        highlightedActorID = nil,
        trackedActorID = nil,
        revision = 0,
    }
end

local function updateSelection(state, field, actorID)
    state = type(state) == "table"
        and state or Presentation.NewSelection()
    actorID = actorID ~= nil and tostring(actorID) or nil
    if state[field] == actorID then return state, "unchanged" end
    state[field] = actorID
    state.revision =
        math.max(0, tonumber(state.revision) or 0) + 1
    return state, "changed"
end

function Presentation.SelectActor(state, actorID)
    return updateSelection(state, "selectedActorID", actorID)
end

function Presentation.HighlightActor(state, actorID)
    return updateSelection(state, "highlightedActorID", actorID)
end

function Presentation.TrackActor(state, actorID)
    return updateSelection(state, "trackedActorID", actorID)
end

function Presentation.ResolveActor(entries, actorID)
    actorID = tostring(actorID or "")
    for _, entry in ipairs(type(entries) == "table" and entries or {}) do
        if tostring(entry.actorID or "") == actorID then
            return entry
        end
    end
    return nil
end

function Presentation.ResolveTracked(entries, state)
    return Presentation.ResolveActor(
        entries,
        state and state.trackedActorID
    )
end

return Presentation
