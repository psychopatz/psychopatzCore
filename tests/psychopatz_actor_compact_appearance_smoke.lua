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
local Factory = require "PsychopatzCore/Actors/PsychopatzActorFactory"
local Persistence =
    require "PsychopatzCore/Actors/PsychopatzActorPersistence"
local Presentation =
    require "PsychopatzCore/Actors/PsychopatzActorPresentation"
local Json = require "PsychopatzCore/Serialization/PsychopatzJson"

local registry = Actors.NewRegistry()
local generated, reason = registry:Create({
    actorId = "appearance:test:generated",
    identitySeed = "appearance-generated-seed",
    archetypeID = "survivor.appearance",
})
truthy(generated, reason)

local beforePortrait = assert(Presentation.BuildPortrait(generated))
local beforePortraitJSON = assert(Json.Encode(beforePortrait))

local saved = assert(registry:Save())
local wrapper = assert(Json.Decode(saved))
local compact = wrapper.actors[1].appearance
equal(compact.mode, "generated", "generated appearance compact mode")
equal(compact.generatorVersion, Factory.GENERATOR_VERSION,
    "generated appearance version")
equal(compact.value, nil, "generated compact payload has no full appearance")
equal(compact.resolved, nil, "generated compact payload has no resolved cache")
local compactBytes = #assert(Json.Encode(compact))
truthy(compactBytes <= 180,
    "generated compact appearance exceeds 180-byte budget: "
        .. tostring(compactBytes))

local fresh = Actors.NewRegistry()
truthy(fresh:Load(saved), "generated compact reload")
local restored = fresh:Get(generated.actorId)
truthy(restored, "restored generated actor")
local afterPortrait = assert(Presentation.BuildPortrait(restored))
equal(assert(Json.Encode(afterPortrait)), beforePortraitJSON,
    "portrait byte parity after compact reload")
equal(assert(Json.Encode(restored.appearance)),
    assert(Json.Encode(generated.appearance)),
    "rich generated appearance reconstructed exactly")

-- Authored/custom appearance cannot be reduced to the generated token.
local authoredRegistry = Actors.NewRegistry()
local authored = assert(authoredRegistry:Create({
    actorId = "appearance:test:authored",
    identitySeed = "appearance-authored-seed",
    identity = {
        displayName = "Authored Appearance",
        survivor = {
            forename = "Authored",
            surname = "Appearance",
            gender = "female",
        },
    },
    appearance = {
        policy = {
            schemaVersion = 2,
            mode = "authored",
            outfit = "none",
            hairModel = "Long2",
            slots = {
                Torso_Upper = {
                    mode = "item",
                    type = "Base.JacketLong_Random",
                    wornSlot = "Torso_Upper",
                },
            },
        },
        resolved = {
            outfit = "none",
            hairModel = "Long2",
            skinTone = "light",
            slots = {
                Torso_Upper = "Base.JacketLong_Random",
            },
        },
    },
}))
local authoredSaved = assert(authoredRegistry:Save())
local authoredWrapper = assert(Json.Decode(authoredSaved))
equal(authoredWrapper.actors[1].appearance.mode, "full",
    "authored appearance retained full")
truthy(authoredWrapper.actors[1].appearance.value,
    "authored full appearance payload missing")
local authoredFresh = Actors.NewRegistry()
truthy(authoredFresh:Load(authoredSaved), "authored compact reload")
equal(assert(Json.Encode(authoredFresh:Get(authored.actorId).appearance)),
    assert(Json.Encode(authored.appearance)),
    "authored appearance exact parity")

-- A durable visual change to an actor that was originally generated must not
-- be silently thrown away simply because its contract says GENERATED_DEFAULT.
local changed = registry:Get(generated.actorId)
changed.appearance.resolved.hairModel = "durable_changed_hair"
local committed, commitReason = registry:Commit(
    changed.actorId,
    { appearance = changed.appearance },
    changed.revision
)
truthy(committed, commitReason)
local changedSaved = assert(registry:Save())
local changedWrapper = assert(Json.Decode(changedSaved))
equal(changedWrapper.actors[1].appearance.mode, "full",
    "changed generated appearance must fall back to full")
local changedFresh = Actors.NewRegistry()
truthy(changedFresh:Load(changedSaved), "changed appearance reload")
equal(changedFresh:Get(generated.actorId).appearance.resolved.hairModel,
    "durable_changed_hair", "durable visual change survives")

-- Unsupported generator versions fail explicitly rather than silently
-- regenerating a different face.
local unsupported, unsupportedReason = Factory.ExpandAppearance({
    schemaVersion = 1,
    mode = "generated",
    generatorVersion = 999,
}, generated.identity)
equal(unsupported, nil, "unsupported generator rejected")
equal(unsupportedReason, "appearance_generator_unsupported",
    "unsupported generator reason")

-- S1 compact actor schema version 1 stored the rich appearance directly.
local legacyCompact, legacyReason = Persistence.DecodeActor({
    schema = Persistence.ACTOR_SCHEMA,
    schemaVersion = Persistence.LEGACY_ACTOR_SCHEMA_VERSION,
    actorId = "appearance:test:legacy-compact",
    revision = 1,
    identity = generated.identity,
    appearance = generated.appearance,
})
truthy(legacyCompact, legacyReason)
equal(assert(Json.Encode(legacyCompact.appearance)),
    assert(Json.Encode(generated.appearance)),
    "legacy compact appearance survives")

print("psychopatz_actor_compact_appearance_smoke: PASS bytes="
    .. tostring(compactBytes))
