local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Types =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldTypes"
local Persistence =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldPersistence"

local Registry = {}
Registry.__index = Registry

Registry.MAX_FACTIONS = Types.MAX_FACTIONS
Registry.MAX_COMMUNITIES = Types.MAX_COMMUNITIES
Registry.MAX_LOCATIONS = Types.MAX_LOCATIONS
Registry.MAX_GROUPS = Types.MAX_GROUPS
Registry.MAX_SECTORS = Types.MAX_SECTORS
Registry.MAX_DISCOVERY_PLAYERS = Types.MAX_DISCOVERY_PLAYERS

local function sortedList(map)
    local ids = {}
    for id in pairs(type(map) == "table" and map or {}) do
        ids[#ids + 1] = id
    end
    table.sort(ids)
    local output = {}
    for index = 1, #ids do
        output[index] = Util.clone(map[ids[index]])
    end
    return output
end

local function count(map)
    return Types.CountMap(map)
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
    return setmetatable({ snapshot = snapshot }, Registry)
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
    return {
        factions = count(self.snapshot.factions),
        communities = count(self.snapshot.communities),
        locations = count(self.snapshot.locations),
        groups = count(self.snapshot.groups),
        sectors = count(self.snapshot.population
            and self.snapshot.population.sectors),
        discoveryPlayers = count(self.snapshot.discovery
            and self.snapshot.discovery.players),
    }
end

function Registry:GetFaction(id)
    local value = self.snapshot.factions[Types.SafeID(id) or ""]
    return value and Util.clone(value) or nil
end

function Registry:ListFactions()
    return sortedList(self.snapshot.factions)
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
        and count(self.snapshot.factions) >= Types.MAX_FACTIONS
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
    touch(self)
    return true
end

function Registry:GetCommunity(id)
    local value = self.snapshot.communities[Types.SafeID(id) or ""]
    return value and Util.clone(value) or nil
end

function Registry:ListCommunities()
    return sortedList(self.snapshot.communities)
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
        and count(self.snapshot.communities)
            >= Types.MAX_COMMUNITIES
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
    return sortedList(self.snapshot.locations)
end

function Registry:UpsertLocation(value)
    value = type(value) == "table" and value or {}
    local id = Types.SafeID(value.id or value.locationID)
    if not id then
        return nil, "survivor_world_location_identity_required"
    end
    local exists = self.snapshot.locations[id] ~= nil
    if not exists
        and count(self.snapshot.locations) >= Types.MAX_LOCATIONS
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
    touch(self)
    return true
end

function Registry:GetGroup(id)
    local value = self.snapshot.groups[Types.SafeID(id) or ""]
    return value and Util.clone(value) or nil
end

function Registry:ListGroups()
    return sortedList(self.snapshot.groups)
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
    local exists = self.snapshot.groups[id] ~= nil
    if not exists and count(self.snapshot.groups) >= Types.MAX_GROUPS then
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
    self.snapshot.groups[id] = normalized
    touch(self)
    return Util.clone(normalized)
end

function Registry:RemoveGroup(id)
    id = Types.SafeID(id)
    if not id or not self.snapshot.groups[id] then
        return nil, "group_not_found"
    end
    self.snapshot.groups[id] = nil
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
    touch(self)
    return Util.clone(population)
end

function Registry:GetDiscovery()
    return Util.clone(self.snapshot.discovery)
end

function Registry:SetDiscovery(value)
    self.snapshot.discovery = Types.NormalizeDiscovery(value)
    touch(self)
    return Util.clone(self.snapshot.discovery)
end

function Registry:Save()
    return Persistence.Serialize(self.snapshot)
end

function Registry:Load(serialized)
    local snapshot, reason = Persistence.Decode(serialized)
    if not snapshot then return nil, reason end
    self.snapshot = snapshot
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
