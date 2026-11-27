local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Types =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldTypes"
local Persistence =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldPersistence"
local Traversal =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldTraversal"
local CorridorGraph =
    require "PsychopatzCore/World/SurvivorWorld/Traversal/PsychopatzSurvivorWorldCorridorGraph"

local Registry = {}
Registry.__index = Registry

Registry.MAX_FACTIONS = Types.MAX_FACTIONS
Registry.MAX_COMMUNITIES = Types.MAX_COMMUNITIES
Registry.MAX_LOCATIONS = Types.MAX_LOCATIONS
Registry.MAX_GROUPS = Types.MAX_GROUPS
Registry.MAX_SECTORS = Types.MAX_SECTORS
Registry.MAX_DISCOVERY_PLAYERS = Types.MAX_DISCOVERY_PLAYERS

local function sortedIDs(map)
    local ids = {}
    for id in pairs(type(map) == "table" and map or {}) do
        ids[#ids + 1] = id
    end
    table.sort(ids)
    return ids
end

local function sortedList(self, bucketName, map)
    local ids = self._sortedIDs[bucketName]
    if not ids then
        ids = sortedIDs(map)
        self._sortedIDs[bucketName] = ids
    end
    local output = {}
    for index = 1, #ids do
        output[index] = Util.clone(map[ids[index]])
    end
    return output
end

local function count(map)
    return Types.CountMap(map)
end

local function registerCommunityNode(community)
    if type(community) ~= "table" or not community.id then return end
    local home = community.home
    if type(home) == "table" and tonumber(home.x) and tonumber(home.y) then
        CorridorGraph.RegisterSettlementNode(
            "community:" .. tostring(community.id),
            home.x,
            home.y,
            home.z or 0,
            { label = community.name or community.id, kind = "community" }
        )
    end
end

local function registerLocationNode(location)
    if type(location) ~= "table" or not location.id then return end
    local pos = location.position
    if type(pos) == "table" and tonumber(pos.x) and tonumber(pos.y) then
        CorridorGraph.RegisterSettlementNode(
            "location:" .. tostring(location.id),
            pos.x,
            pos.y,
            pos.z or 0,
            { label = location.name or location.id, kind = tostring(location.kind or "location") }
        )
    end
end

local function rebuildIndexes(self)
    local snapshot = self.snapshot
    if tonumber(snapshot.worldSeed) then
        CorridorGraph.SetWorldSeed(snapshot.worldSeed)
    end
    for _, community in pairs(type(snapshot.communities) == "table" and snapshot.communities or {}) do
        registerCommunityNode(community)
    end
    for _, location in pairs(type(snapshot.locations) == "table" and snapshot.locations or {}) do
        registerLocationNode(location)
    end
    local actorGroupIndex = {}
    local groupIDs = sortedIDs(snapshot.groups)
    for index = 1, #groupIDs do
        local groupID = groupIDs[index]
        local group = snapshot.groups[groupID]
        local members = type(group) == "table"
            and group.memberActorIDs or nil
        if type(members) == "table" then
            for mIndex = 1, #members do
                local actorID = members[mIndex]
                if actorID ~= nil then
                    actorGroupIndex[actorID] = groupID
                end
            end
        end
    end
    self._actorGroupIndex = actorGroupIndex
    self._sortedIDs = {
        factions = nil,
        communities = nil,
        locations = nil,
        groups = groupIDs,
    }
    self._counts = {
        factions = count(snapshot.factions),
        communities = count(snapshot.communities),
        locations = count(snapshot.locations),
        groups = #groupIDs,
        sectors = count(snapshot.population
            and snapshot.population.sectors),
        discoveryPlayers = count(snapshot.discovery
            and snapshot.discovery.players),
    }
end

local function unindexGroupMembers(self, groupID, group)
    local members = type(group) == "table"
        and group.memberActorIDs or nil
    if type(members) ~= "table" then return end
    local index = self._actorGroupIndex
    for mIndex = 1, #members do
        local actorID = members[mIndex]
        if actorID ~= nil and index[actorID] == groupID then
            index[actorID] = nil
        end
    end
end

local function indexGroupMembers(self, groupID, group)
    local members = type(group) == "table"
        and group.memberActorIDs or nil
    if type(members) ~= "table" then return end
    local index = self._actorGroupIndex
    for mIndex = 1, #members do
        local actorID = members[mIndex]
        if actorID ~= nil then
            index[actorID] = groupID
        end
    end
end

local function routePointCount(value)
    value = type(value) == "table" and value or {}
    local journey = value.journey or value.groupJourney
    local route = type(journey) == "table" and journey.route or nil
    local points = type(route) == "table"
        and (route.points or route) or nil
    return type(points) == "table" and #points or 0
end

local function touch(self)
    self.snapshot.revision =
        math.max(0, tonumber(self.snapshot.revision) or 0) + 1
end

function Registry.new(spec)
    spec = type(spec) == "table" and spec or {}
    local snapshot
    if spec.snapshot ~= nil then
        local bounded, boundReason =
            Types.ValidateInputBounds(spec.snapshot)
        if not bounded then return nil, boundReason end
        snapshot = Types.NormalizeSnapshot(spec.snapshot)
        local valid, reason = Types.ValidateSnapshot(snapshot)
        if not valid then return nil, reason end
    else
        snapshot = Types.NewSnapshot(spec.worldSeed)
    end
    local instance = setmetatable({ snapshot = snapshot }, Registry)
    rebuildIndexes(instance)
    return instance
end

function Registry:Revision()
    return tonumber(self.snapshot.revision) or 0
end

function Registry:WorldSeed()
    return tonumber(self.snapshot.worldSeed) or 0
end

function Registry:Snapshot()
    return Util.clone(self.snapshot)
end

function Registry:Counts()
    local counts = self._counts
    return {
        factions = counts.factions,
        communities = counts.communities,
        locations = counts.locations,
        groups = counts.groups,
        sectors = counts.sectors,
        discoveryPlayers = counts.discoveryPlayers,
    }
end

function Registry:GetFaction(id)
    local value = self.snapshot.factions[Types.SafeID(id) or ""]
    return value and Util.clone(value) or nil
end

function Registry:ListFactions()
    return sortedList(self, "factions", self.snapshot.factions)
end

function Registry:UpsertFaction(value)
    value = type(value) == "table" and value or {}
    local id = Types.SafeID(value.id or value.factionID)
    if not id then return nil, "faction_identity_required" end
    if Types.CountMap(Types.MemberInput(value))
        > Types.MAX_FACTION_MEMBERS
    then
        return nil, "survivor_world_faction_member_capacity"
    end
    local exists = self.snapshot.factions[id] ~= nil
    if not exists
        and self._counts.factions >= Types.MAX_FACTIONS
    then
        return nil, "survivor_world_capacity_exceeded"
    end
    local normalized, reason = Types.NormalizeFaction(
        value,
        self:WorldSeed(),
        id
    )
    if not normalized then return nil, reason end
    self.snapshot.factions[id] = normalized
    if not exists then
        self._counts.factions = self._counts.factions + 1
        self._sortedIDs.factions = nil
    end
    touch(self)
    return Util.clone(normalized)
end

function Registry:RemoveFaction(id)
    id = Types.SafeID(id)
    if not id or not self.snapshot.factions[id] then
        return nil, "faction_not_found"
    end
    for _, community in pairs(self.snapshot.communities) do
        if community.factionID == id then
            return nil, "faction_has_communities"
        end
    end
    for _, group in pairs(self.snapshot.groups) do
        if group.factionID == id then
            return nil, "faction_has_groups"
        end
    end
    self.snapshot.factions[id] = nil
    self._counts.factions = math.max(0, self._counts.factions - 1)
    self._sortedIDs.factions = nil
    touch(self)
    return true
end

function Registry:GetCommunity(id)
    local value = self.snapshot.communities[Types.SafeID(id) or ""]
    return value and Util.clone(value) or nil
end

function Registry:ListCommunities()
    return sortedList(self, "communities", self.snapshot.communities)
end

function Registry:UpsertCommunity(value)
    value = type(value) == "table" and value or {}
    local id = Types.SafeID(value.id or value.communityID)
    if not id then return nil, "community_identity_required" end
    if Types.CountMap(Types.MemberInput(value))
        > Types.MAX_COMMUNITY_MEMBERS
    then
        return nil, "survivor_world_community_member_capacity"
    end
    local exists = self.snapshot.communities[id] ~= nil
    if not exists
        and self._counts.communities >= Types.MAX_COMMUNITIES
    then
        return nil, "survivor_world_capacity_exceeded"
    end
    local normalized, reason = Types.NormalizeCommunity(
        value,
        self:WorldSeed(),
        id
    )
    if not normalized then return nil, reason end
    if not self.snapshot.factions[normalized.factionID] then
        return nil, "survivor_world_community_faction_missing"
    end
    self.snapshot.communities[id] = normalized
    registerCommunityNode(normalized)
    if not exists then
        self._counts.communities = self._counts.communities + 1
        self._sortedIDs.communities = nil
    end
    touch(self)
    return Util.clone(normalized)
end

function Registry:RemoveCommunity(id)
    id = Types.SafeID(id)
    if not id or not self.snapshot.communities[id] then
        return nil, "community_not_found"
    end
    for _, group in pairs(self.snapshot.groups) do
        if group.homeCommunityID == id then
            return nil, "community_has_groups"
        end
    end
    self.snapshot.communities[id] = nil
    CorridorGraph.UnregisterSettlementNode("community:" .. tostring(id))
    self._counts.communities = math.max(0, self._counts.communities - 1)
    self._sortedIDs.communities = nil
    if self.snapshot.population.starterCommunityID == id then
        self.snapshot.population.starterCommunityID = nil
    end
    touch(self)
    return true
end

function Registry:GetLocation(id)
    local value = self.snapshot.locations[Types.SafeID(id) or ""]
    return value and Util.clone(value) or nil
end

function Registry:ListLocations()
    return sortedList(self, "locations", self.snapshot.locations)
end

function Registry:UpsertLocation(value)
    value = type(value) == "table" and value or {}
    local id = Types.SafeID(value.id or value.locationID)
    if not id then
        return nil, "survivor_world_location_identity_required"
    end
    local exists = self.snapshot.locations[id] ~= nil
    if not exists
        and self._counts.locations >= Types.MAX_LOCATIONS
    then
        return nil, "survivor_world_capacity_exceeded"
    end
    local normalized, reason = Types.NormalizeAbstractLocation(
        value,
        self:WorldSeed(),
        id
    )
    if not normalized then return nil, reason end
    self.snapshot.locations[id] = normalized
    registerLocationNode(normalized)
    if not exists then
        self._counts.locations = self._counts.locations + 1
        self._sortedIDs.locations = nil
    end
    touch(self)
    return Util.clone(normalized)
end

function Registry:RemoveLocation(id)
    id = Types.SafeID(id)
    if not id or not self.snapshot.locations[id] then
        return nil, "location_not_found"
    end
    for _, group in pairs(self.snapshot.groups) do
        if group.location and group.location.id == id then
            return nil, "location_has_groups"
        end
    end
    self.snapshot.locations[id] = nil
    CorridorGraph.UnregisterSettlementNode("location:" .. tostring(id))
    self._counts.locations = math.max(0, self._counts.locations - 1)
    self._sortedIDs.locations = nil
    touch(self)
    return true
end

function Registry:GetGroup(id)
    local value = self.snapshot.groups[Types.SafeID(id) or ""]
    return value and Util.clone(value) or nil
end

function Registry:GetGroupIDForActor(actorID)
    actorID = Types.SafeID(actorID)
    if not actorID then return nil end
    return self._actorGroupIndex[actorID]
end

function Registry:GetGroupForActor(actorID)
    local groupID = self:GetGroupIDForActor(actorID)
    if not groupID then return nil end
    local value = self.snapshot.groups[groupID]
    return value and Util.clone(value) or nil
end

function Registry:ListGroups()
    return sortedList(self, "groups", self.snapshot.groups)
end

function Registry:UpsertGroup(value)
    value = type(value) == "table" and value or {}
    local id = Types.SafeID(value.id or value.groupID)
    if not id then return nil, "group_identity_required" end
    if Types.CountMap(Types.MemberInput(value))
        > Types.MAX_GROUP_MEMBERS
    then
        return nil, "survivor_world_group_member_capacity"
    end
    if routePointCount(value) > Types.MAX_GROUP_ROUTE_POINTS then
        return nil, "survivor_world_group_route_capacity"
    end
    local previous = self.snapshot.groups[id]
    local exists = previous ~= nil
    if not exists and self._counts.groups >= Types.MAX_GROUPS then
        return nil, "survivor_world_capacity_exceeded"
    end
    local normalized, reason = Types.NormalizeGroup(
        value,
        self:WorldSeed(),
        id
    )
    if not normalized then return nil, reason end
    if not self.snapshot.factions[normalized.factionID] then
        return nil, "survivor_world_group_faction_missing"
    end
    if normalized.homeCommunityID
        and not self.snapshot.communities[normalized.homeCommunityID]
    then
        return nil, "survivor_world_group_home_missing"
    end
    if previous then
        unindexGroupMembers(self, id, previous)
    end
    self.snapshot.groups[id] = normalized
    indexGroupMembers(self, id, normalized)
    if not exists then
        self._counts.groups = self._counts.groups + 1
        self._sortedIDs.groups = nil
    end
    touch(self)
    return Util.clone(normalized)
end

function Registry:StartGroupJourney(groupID, spec, now)
    groupID = Types.SafeID(groupID)
    local group = groupID and self.snapshot.groups[groupID] or nil
    if not group then return nil, "group_not_found" end
    local updated, reason = Traversal.Start(group, spec, now)
    if not updated then return nil, reason end
    self.snapshot.groups[groupID] = updated
    touch(self)
    return Util.clone(updated)
end

function Registry:AdvanceGroupJourney(groupID, now)
    groupID = Types.SafeID(groupID)
    local group = groupID and self.snapshot.groups[groupID] or nil
    if not group then return nil, "group_not_found" end
    local updated, reason = Traversal.Advance(group, now)
    if not updated then return nil, reason end
    self.snapshot.groups[groupID] = updated
    touch(self)
    return Util.clone(updated)
end

function Registry:RebaseGroupJourney(groupID, origin, now)
    groupID = Types.SafeID(groupID)
    local group = groupID and self.snapshot.groups[groupID] or nil
    if not group then return nil, "group_not_found" end
    local updated, reason = Traversal.Rebase(
        group,
        origin,
        now
    )
    if not updated then return nil, reason end
    self.snapshot.groups[groupID] = updated
    touch(self)
    return Util.clone(updated)
end

function Registry:CancelGroupJourney(groupID, reason)
    groupID = Types.SafeID(groupID)
    local group = groupID and self.snapshot.groups[groupID] or nil
    if not group then return nil, "group_not_found" end
    local updated, failure = Traversal.Cancel(group, reason)
    if not updated then return nil, failure end
    self.snapshot.groups[groupID] = updated
    touch(self)
    return Util.clone(updated)
end

function Registry:ProjectGroupPosition(groupID, now)
    groupID = Types.SafeID(groupID)
    local group = groupID and self.snapshot.groups[groupID] or nil
    if not group then return nil, "group_not_found" end
    return Traversal.ProjectGroupPosition(group, now)
end

function Registry:ProjectGroupMemberPosition(
    groupID,
    actorID,
    actorWorld,
    now
)
    groupID = Types.SafeID(groupID)
    local group = groupID and self.snapshot.groups[groupID] or nil
    if not group then return nil, "group_not_found" end
    return Traversal.ProjectMemberPosition(
        group,
        actorID,
        actorWorld,
        now
    )
end

function Registry:RemoveGroup(id)
    id = Types.SafeID(id)
    local previous = id and self.snapshot.groups[id] or nil
    if not previous then
        return nil, "group_not_found"
    end
    unindexGroupMembers(self, id, previous)
    self.snapshot.groups[id] = nil
    self._counts.groups = math.max(0, self._counts.groups - 1)
    self._sortedIDs.groups = nil
    touch(self)
    return true
end

function Registry:GetPopulation()
    return Util.clone(self.snapshot.population)
end

function Registry:SetPopulation(value)
    local population = Types.NormalizePopulation(
        value,
        self:WorldSeed()
    )
    population.worldSeed = self:WorldSeed()
    self.snapshot.population = population
    self._counts.sectors = count(population.sectors)
    touch(self)
    return Util.clone(population)
end

function Registry:GetDiscovery()
    return Util.clone(self.snapshot.discovery)
end

function Registry:SetDiscovery(value)
    self.snapshot.discovery = Types.NormalizeDiscovery(value)
    self._counts.discoveryPlayers = count(
        self.snapshot.discovery and self.snapshot.discovery.players
    )
    touch(self)
    return Util.clone(self.snapshot.discovery)
end

function Registry:Save()
    return Persistence.SerializeNormalized(self.snapshot)
end

function Registry:Load(serialized)
    local snapshot, reason = Persistence.Decode(serialized)
    if not snapshot then return nil, reason end
    self.snapshot = snapshot
    rebuildIndexes(self)
    return true
end

function Registry:Validate()
    return Types.ValidateSnapshot(self.snapshot)
end

Registry.AddFaction = Registry.UpsertFaction
Registry.AddCommunity = Registry.UpsertCommunity
Registry.AddLocation = Registry.UpsertLocation
Registry.AddGroup = Registry.UpsertGroup

return Registry
