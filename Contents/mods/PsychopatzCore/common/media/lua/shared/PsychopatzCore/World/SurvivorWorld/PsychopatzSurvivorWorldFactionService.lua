-- Canonical faction mutation boundary for SurvivorWorld adopters.
--
-- The registry owns storage and normalization. This service owns the public
-- mutation vocabulary so adopters do not need to modify registry snapshots or
-- invent parallel faction writers.
local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"

local Service = {}

local function validRegistry(registry)
    return type(registry) == "table"
        and type(registry.GetFaction) == "function"
        and type(registry.UpsertFaction) == "function"
end

local function memberIndex(memberIDs, actorID)
    for index, value in ipairs(memberIDs or {}) do
        if tostring(value) == tostring(actorID) then return index end
    end
    return nil
end

local function update(registry, factionID, mutate)
    if not validRegistry(registry) then
        return nil, "survivor_world_faction_registry_required"
    end

    local current = registry:GetFaction(factionID)
    if not current then return nil, "faction_not_found" end

    local candidate = Util.clone(current)
    local changed, reason = mutate(candidate)
    if changed == false then
        return current, reason or "unchanged"
    end
    if changed == nil then return nil, reason end
    return registry:UpsertFaction(candidate)
end

function Service.Get(registry, factionID)
    if not validRegistry(registry) then
        return nil, "survivor_world_faction_registry_required"
    end
    return registry:GetFaction(factionID)
end

function Service.List(registry)
    if not validRegistry(registry)
        or type(registry.ListFactions) ~= "function"
    then
        return nil, "survivor_world_faction_registry_required"
    end
    return registry:ListFactions()
end

function Service.Upsert(registry, faction)
    if not validRegistry(registry) then
        return nil, "survivor_world_faction_registry_required"
    end
    return registry:UpsertFaction(faction)
end

function Service.AddMember(registry, factionID, actorID)
    if type(actorID) ~= "string" or actorID == "" then
        return nil, "actor_id_required"
    end
    return update(registry, factionID, function(candidate)
        candidate.memberActorIDs = candidate.memberActorIDs or {}
        if memberIndex(candidate.memberActorIDs, actorID) then
            return false, "unchanged"
        end
        candidate.memberActorIDs[#candidate.memberActorIDs + 1] = actorID
        return true
    end)
end

function Service.RemoveMember(registry, factionID, actorID)
    if type(actorID) ~= "string" or actorID == "" then
        return nil, "actor_id_required"
    end
    return update(registry, factionID, function(candidate)
        local index = memberIndex(candidate.memberActorIDs, actorID)
        if not index then return false, "actor_not_member" end
        table.remove(candidate.memberActorIDs, index)
        if tostring(candidate.leaderActorID or "") == tostring(actorID) then
            candidate.leaderActorID = nil
        end
        return true
    end)
end

function Service.SetLeader(registry, factionID, actorID)
    if actorID ~= nil
        and (type(actorID) ~= "string" or actorID == "")
    then
        return nil, "actor_id_required"
    end
    return update(registry, factionID, function(candidate)
        if actorID ~= nil
            and not memberIndex(candidate.memberActorIDs, actorID)
        then
            return nil, "leader_not_member"
        end
        if tostring(candidate.leaderActorID or "")
            == tostring(actorID or "")
        then
            return false, "unchanged"
        end
        candidate.leaderActorID = actorID
        return true
    end)
end

function Service.SetStatus(registry, factionID, status)
    if type(status) ~= "string" or status == "" then
        return nil, "status_required"
    end
    return update(registry, factionID, function(candidate)
        if candidate.status == status then return false, "unchanged" end
        candidate.status = status
        return true
    end)
end

return Service
