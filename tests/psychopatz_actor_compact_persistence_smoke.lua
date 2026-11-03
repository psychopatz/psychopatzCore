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

local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local ActorInventory =
    require "PsychopatzCore/Actors/PsychopatzActorInventory"
local Persistence =
    require "PsychopatzCore/Actors/PsychopatzActorPersistence"
local Json = require "PsychopatzCore/Serialization/PsychopatzJson"

local registry = Actors.NewRegistry()
local actor, reason = registry:Create({
    actorId = "compact:test:actor",
    identitySeed = "compact-test-seed",
    world = {
        location = { kind = "world", x = 10, y = 20, z = 0 },
    },
})
truthy(actor, reason)
equal(actor.personalInventory.mode, "SEED_ONLY",
    "new actor defaults to seed-only inventory")
equal(actor.personalInventory.baseline.kind, "default",
    "default starter baseline is symbolic")
equal(actor.personalInventory.baseline.definitions, nil,
    "default seed payload does not persist starter definitions")

local saved = assert(registry:Save())
local wrapper = assert(Json.Decode(saved))
equal(wrapper.schemaVersion, 2, "registry compact schema version")
equal(wrapper.actors[1].schema, Persistence.ACTOR_SCHEMA,
    "compact actor schema")
equal(wrapper.actors[1].social, nil, "default social omitted")
equal(wrapper.actors[1].persona, nil, "default persona omitted")
equal(wrapper.actors[1].knowledge, nil, "default knowledge omitted")
equal(wrapper.actors[1].providerLease, nil,
    "default released provider lease omitted")
equal(wrapper.actors[1].extensions, nil, "empty extensions omitted")
equal(wrapper.actors[1].ownerMod, nil, "default owner omitted")

local fresh = Actors.NewRegistry()
truthy(fresh:Load(saved), "compact registry reload")
local restored = fresh:Get(actor.actorId)
truthy(restored, "restored compact actor")
equal(restored.identity.displayName, actor.identity.displayName,
    "identity parity")
equal(restored.appearance.resolved.outfit,
    actor.appearance.resolved.outfit, "appearance parity")
equal(restored.world.location.position.x, 10, "world parity")
equal(restored.personalInventory.mode, "SEED_ONLY",
    "seed-only survives compact reload")

-- Simulate a supported v1 registry containing the old FULL actor payload.
local legacyActor = registry:Get(actor.actorId)
local legacyLedger = assert(ActorInventory.Decode(
    legacyActor.personalInventory))
legacyActor.personalInventory = assert(legacyLedger:ToPayload("FULL"))
equal(legacyActor.personalInventory.mode, "FULL",
    "legacy fixture is full")
local legacySerialized = assert(Json.Encode({
    schema = Persistence.SCHEMA,
    schemaVersion = 1,
    revision = 17,
    actors = { legacyActor },
}))

local migrated = Actors.NewRegistry()
truthy(migrated:Load(legacySerialized), "v1 registry loads")
equal(migrated:Get(actor.actorId).personalInventory.mode, "FULL",
    "v1 load preserves full payload in memory")
local migratedSaved = assert(migrated:Save())
local migratedWrapper = assert(Json.Decode(migratedSaved))
equal(migratedWrapper.schemaVersion, 2, "v1 rewrites as v2")
equal(migratedWrapper.actors[1].personalInventory.mode, "SEED_ONLY",
    "unchanged legacy full inventory safely compacts")
equal(migratedWrapper.actors[1].personalInventory.baseline.kind,
    "default", "legacy full compacts to default baseline")

-- A genuine durable item delta must never be guessed away.
local changed = registry:Get(actor.actorId)
local changedLedger = assert(ActorInventory.Decode(
    changed.personalInventory))
truthy(changedLedger:Add({
    itemId = changed.actorId .. ":found:bandage",
    fullType = "Base.Bandage",
    metadata = { source = "compact-regression" },
}), "add durable item")
changed.personalInventory = assert(changedLedger:ToPayload("FULL"))
local changedLegacy = assert(Json.Encode({
    schema = Persistence.SCHEMA,
    schemaVersion = 1,
    revision = 18,
    actors = { changed },
}))
local changedRegistry = Actors.NewRegistry()
truthy(changedRegistry:Load(changedLegacy), "changed legacy loads")
local changedSaved = assert(changedRegistry:Save())
local changedWrapper = assert(Json.Decode(changedSaved))
equal(changedWrapper.actors[1].personalInventory.mode, "FULL",
    "changed legacy full retained rather than losing state")
local changedRoundTrip = Actors.NewRegistry()
truthy(changedRoundTrip:Load(changedSaved), "changed v2 reload")
local changedLedgerReloaded = assert(ActorInventory.Decode(
    changedRoundTrip:Get(actor.actorId).personalInventory))
truthy(changedLedgerReloaded:Get(
    changed.actorId .. ":found:bandage"), "durable item survives migration")

print("psychopatz_actor_compact_persistence_smoke: PASS")
