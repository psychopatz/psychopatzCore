local ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

local Profiles = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldFactionProfiles"
local SurvivorWorld = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorld"
truthy(SurvivorWorld.FactionProfiles == Profiles,
    "SurvivorWorld exposes the Core profile registry")
Profiles.ResetForTests()

local registered, reason = Profiles.Register("test:mobile_profile", {
    label = "Test Mobile Profile",
    sourceMod = "TestFixture",
    allowedRoles = { leader = true, escort = true },
    defaultRole = "escort",
    policyDefaults = { aggression = 0.25 },
    capabilities = { mobile = true },
    extensions = {
        ["test.fixture"] = { materializer = "abstract-or-live" },
    },
})
truthy(registered, reason)

local profile = Profiles.Get("test:mobile_profile")
truthy(profile, "registered profile is queryable")
equal(profile.defaultRole, "escort", "default role preserved")
equal(profile.allowedRoles.leader, true, "role contract preserved")
equal(profile.sourceMod, "TestFixture", "source preserved")
equal(profile.extensions["test.fixture"].materializer,
    "abstract-or-live", "namespaced extension preserved")

profile.allowedRoles.leader = false
equal(Profiles.Get("test:mobile_profile").allowedRoles.leader,
    true, "queries return copies")

local duplicate, duplicateReason = Profiles.Register("test:mobile_profile", {
    label = "Test Mobile Profile",
    sourceMod = "TestFixture",
    allowedRoles = { leader = true, escort = true },
    defaultRole = "escort",
    policyDefaults = { aggression = 0.25 },
    capabilities = { mobile = true },
    extensions = {
        ["test.fixture"] = { materializer = "abstract-or-live" },
    },
})
truthy(duplicate, duplicateReason)
equal(duplicateReason, "already_registered",
    "identical registration is idempotent")

local conflict, conflictReason = Profiles.Register("test:mobile_profile", {
    label = "Conflicting Profile",
    allowedRoles = { leader = true },
    defaultRole = "leader",
})
equal(conflict, false, "conflicting profile rejected")
equal(conflictReason, "faction_profile_id_conflict",
    "conflict reason is explicit")

local invalid, invalidReason = Profiles.Register("test:invalid_profile", {
    allowedRoles = { leader = true },
    defaultRole = "missing",
})
equal(invalid, false, "invalid default role rejected")
equal(invalidReason, "faction_profile_default_role_invalid",
    "invalid role reason is explicit")

equal(Profiles.Count(), 1, "profile count bounded")
truthy(Profiles.Unregister("test:mobile_profile"),
    "profile can be removed by owner")
equal(Profiles.Count(), 0, "profile removed")

print("psychopatz_survivor_world_faction_profiles_smoke: PASS")
