-- Provider-neutral faction profile registry.
--
-- Core owns the registry and the stable role/profile contract. Adopters may
-- store namespaced policy and materialization data in extensions, but they do
-- not need to maintain a second faction-archetype registry.
local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Json = require "PsychopatzCore/Serialization/PsychopatzJson"

local Profiles = {
    MAX_PROFILES = 128,
    Entries = {},
}

local function validID(value)
    return type(value) == "string"
        and #value > 0
        and #value <= 128
        and string.match(value, "^[%w_%-%.:]+$") ~= nil
end

local function normalizeRoles(value)
    if type(value) ~= "table" then return nil end
    local output = {}
    for role, enabled in pairs(value) do
        if type(role) == "string" and enabled == true then
            output[role] = true
        end
    end
    local hasRole = false
    for _ in pairs(output) do
        hasRole = true
        break
    end
    return hasRole and output or nil
end

local function normalizeProfile(profileID, value)
    if not validID(profileID) then
        return nil, "faction_profile_id_invalid"
    end
    if type(value) ~= "table" then
        return nil, "faction_profile_definition_required"
    end

    local roles = normalizeRoles(value.allowedRoles or value.roles)
    if not roles then return nil, "faction_profile_roles_required" end

    local defaultRole = value.defaultRole
    if type(defaultRole) ~= "string" or not roles[defaultRole] then
        return nil, "faction_profile_default_role_invalid"
    end

    local extensions = type(value.extensions) == "table"
        and Util.clone(value.extensions) or {}
    if not Util.isSerializable(extensions) then
        return nil, "faction_profile_extensions_not_serializable"
    end

    local output = {
        schemaVersion = 1,
        id = profileID,
        label = Util.text(value.label, profileID),
        description = Util.text(value.description, ""),
        sourceMod = Util.text(value.sourceMod, ""),
        allowedRoles = roles,
        defaultRole = defaultRole,
        policyDefaults = Util.clone(value.policyDefaults or {}),
        capabilities = Util.clone(value.capabilities or {}),
        extensions = extensions,
    }
    if not Util.isSerializable(output) then
        return nil, "faction_profile_not_serializable"
    end
    return output
end

local function sameProfile(left, right)
    return Json.Fingerprint(Json.Encode(left))
        == Json.Fingerprint(Json.Encode(right))
end

local function countEntries()
    local count = 0
    for _ in pairs(Profiles.Entries) do count = count + 1 end
    return count
end

function Profiles.Register(profileID, value)
    local normalized, reason = normalizeProfile(profileID, value)
    if not normalized then return false, reason end

    local existing = Profiles.Entries[profileID]
    if existing then
        if sameProfile(existing, normalized) then
            return true, "already_registered"
        end
        return false, "faction_profile_id_conflict"
    end
    if countEntries() >= Profiles.MAX_PROFILES then
        return false, "faction_profile_capacity"
    end
    Profiles.Entries[profileID] = normalized
    return true, "registered"
end

function Profiles.Unregister(profileID)
    if not validID(profileID) or not Profiles.Entries[profileID] then
        return false, "faction_profile_not_registered"
    end
    Profiles.Entries[profileID] = nil
    return true, "unregistered"
end

function Profiles.Get(profileID)
    if not validID(profileID) then return nil end
    local value = Profiles.Entries[profileID]
    return value and Util.clone(value) or nil
end

function Profiles.Exists(profileID)
    return Profiles.Get(profileID) ~= nil
end

function Profiles.List()
    local ids = {}
    for profileID in pairs(Profiles.Entries) do
        ids[#ids + 1] = profileID
    end
    table.sort(ids)

    local output = {}
    for index, profileID in ipairs(ids) do
        output[index] = Util.clone(Profiles.Entries[profileID])
    end
    return output
end

function Profiles.Count()
    return countEntries()
end

function Profiles.ResetForTests()
    Profiles.Entries = {}
end

return Profiles
