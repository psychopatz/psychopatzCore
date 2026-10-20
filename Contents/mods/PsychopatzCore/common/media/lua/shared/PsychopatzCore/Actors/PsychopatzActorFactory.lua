local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Json = require "PsychopatzCore/Serialization/PsychopatzJson"
local Persona = require "PsychopatzCore/Actors/PsychopatzActorPersona"
local Knowledge = require "PsychopatzCore/Actors/PsychopatzActorKnowledge"

local Factory = {}

Factory.SCHEMA = "PsychopatzCore.NPC"
Factory.SCHEMA_VERSION = 1
Factory.APPEARANCE_POLICY_SCHEMA = 2
Factory.APPEARANCE_CONTRACT_SCHEMA = 1
Factory.GENERATOR_VERSION = 1

local FORENAMES = { "Alex", "Avery", "Casey", "Drew", "Jordan", "Morgan" }
local SURNAMES = { "Bennett", "Carter", "Hayes", "Marlow", "Parker", "Reed" }
local GENDERS = { "female", "male" }
local VOICES = { "calm", "gruff", "warm", "clear" }
local HAIR_MODELS = { "short", "long", "messy", "shaved" }
local HAIR_COLORS = { "black", "brown", "blonde", "red" }
local SKIN_TONES = { "light", "tan", "olive", "dark" }
local BEARDS = { "none", "stubble", "short", "full" }
local OUTFITS = { "casual", "workwear", "survival", "formal" }

local function generatedVoice(seed)
    local voice = Util.pick(VOICES, seed, 1)
    local voiceType = Util.hash(seed .. ":voice") % 4 + 1
    local pitch = 0.9 + (Util.hash(seed .. ":pitch") % 5) * 0.05
    return {
        schemaVersion = 1,
        voice = voice,
        voicePrefix = voice,
        voiceType = voiceType,
        voicePitch = pitch,
        complete = true,
    }
end

local function normalizeVoice(identity, seed)
    local survivor = type(identity.survivor) == "table" and identity.survivor or {}
    local supplied = survivor.voiceProfile
    if type(supplied) ~= "table" then supplied = survivor.voice end

    if type(supplied) == "table" then
        local voice = Util.clone(supplied)
        voice.schemaVersion = Util.integer(voice.schemaVersion, 1)
        voice.complete = voice.complete == true
        return voice
    end

    if survivor.voice ~= nil then
        return {
            schemaVersion = 1,
            voice = survivor.voice,
            voicePrefix = survivor.voicePrefix,
            voiceType = survivor.voiceType,
            voicePitch = survivor.voicePitch,
            complete = survivor.voicePrefix ~= nil
                and survivor.voiceType ~= nil and survivor.voicePitch ~= nil,
        }
    end

    return generatedVoice(seed)
end

local function generatedAppearance(seed, identity)
    local resolved = {
        skinTone = Util.pick(SKIN_TONES, seed, 3),
        hairModel = Util.pick(HAIR_MODELS, seed, 5),
        hairColor = Util.pick(HAIR_COLORS, seed, 7),
        beardModel = Util.pick(BEARDS, seed, 11),
        outfit = Util.pick(OUTFITS, seed, 13),
        gender = identity.gender,
    }
    local policy = {
        schemaVersion = Factory.APPEARANCE_POLICY_SCHEMA,
        mode = "generated",
        seed = seed,
        generatorVersion = Factory.GENERATOR_VERSION,
    }
    return policy, resolved
end

local function appearancePolicy(input)
    if type(input) ~= "table" then return nil, false end
    local policy = input.policy
    if type(policy) ~= "table" and input.schemaVersion ~= nil then policy = input end
    if type(policy) ~= "table" then return nil, false end
    local mode = policy.mode or input.mode
    local authored = mode == "authored" or mode == "AUTHORED_POLICY"
        or policy.authority == "authored"
        or (mode == nil and policy.schemaVersion ~= nil)
    if mode == "generated" or mode == "GENERATED_DEFAULT" then authored = false end
    return Util.clone(policy), authored
end

local function normalizeAppearance(input, seed, identity)
    local policy, authored = appearancePolicy(input)
    if not authored then
        policy, input = generatedAppearance(seed, identity)
        return {
            policySchemaVersion = Factory.APPEARANCE_POLICY_SCHEMA,
            policy = policy,
            resolved = input,
            contract = {
                schemaVersion = Factory.APPEARANCE_CONTRACT_SCHEMA,
                mode = "GENERATED_DEFAULT",
                generator = {
                    seed = seed,
                    version = Factory.GENERATOR_VERSION,
                    archetypeID = identity.archetypeID,
                },
                policyHash = Json.Fingerprint(Json.Encode(policy)),
            },
        }
    end

    if Util.integer(policy.schemaVersion, 0) ~= Factory.APPEARANCE_POLICY_SCHEMA then
        return nil, "appearance_schema_unsupported"
    end

    local resolved = type(input) == "table" and input.resolved or nil
    if type(resolved) ~= "table" then
        resolved = {
            outfit = policy.outfit,
            slots = Util.clone(policy.slots),
            skinTone = policy.skinTone,
            hairModel = policy.hairModel,
            hairColor = policy.hairColor,
            beardModel = policy.beardModel,
            gender = identity.gender,
        }
    else
        resolved = Util.clone(resolved)
    end

    return {
        policySchemaVersion = Factory.APPEARANCE_POLICY_SCHEMA,
        policy = policy,
        resolved = resolved,
        contract = {
            schemaVersion = Factory.APPEARANCE_CONTRACT_SCHEMA,
            mode = "AUTHORED_POLICY",
            generator = {
                seed = seed,
                version = Factory.GENERATOR_VERSION,
                archetypeID = identity.archetypeID,
            },
            policyHash = Json.Fingerprint(Json.Encode(policy)),
        },
    }
end

local function normalizeIdentity(spec, seed)
    local supplied = type(spec.identity) == "table" and spec.identity or {}
    local survivor = type(supplied.survivor) == "table" and supplied.survivor or {}
    local forename = Util.text(survivor.forename, Util.pick(FORENAMES, seed, 17))
    local surname = Util.text(survivor.surname, Util.pick(SURNAMES, seed, 19))
    local gender = Util.text(survivor.gender, Util.pick(GENDERS, seed, 23))
    local identity = {
        schemaVersion = 1,
        identitySeed = seed,
        archetypeID = Util.text(supplied.archetypeID,
            Util.text(spec.archetypeID, "core.actor")),
        displayName = Util.text(supplied.displayName,
            forename .. " " .. surname),
        generatorVersion = Factory.GENERATOR_VERSION,
        gender = gender,
        survivor = {
            forename = forename,
            surname = surname,
            gender = gender,
            hairModel = survivor.hairModel,
            beardModel = survivor.beardModel,
            skinColor = survivor.skinColor,
            hairColor = survivor.hairColor,
        },
    }
    local voice = normalizeVoice({ survivor = survivor }, seed)
    identity.survivor.voiceProfile = voice
    identity.survivor.voice = voice.voice
    identity.survivor.voicePrefix = voice.voicePrefix
    identity.survivor.voiceType = voice.voiceType
    identity.survivor.voicePitch = voice.voicePitch
    return identity
end

function Factory.ValidateSpec(spec)
    if type(spec) ~= "table" then return false, "spec_required" end
    if spec.actorId ~= nil and Util.text(spec.actorId, nil) == nil then
        return false, "actor_id_required"
    end
    if spec.extensions ~= nil and type(spec.extensions) ~= "table" then
        return false, "extensions_required"
    end
    for key, value in pairs(spec.extensions or {}) do
        if not Util.isNamespacedKey(key) or not Util.isSerializable(value) then
            return false, "extension_namespace_invalid"
        end
    end
    if spec.appearance ~= nil and type(spec.appearance) ~= "table" then
        return false, "appearance_required"
    end
    if spec.persona ~= nil or spec.backstory ~= nil then
        local persona, reason = Persona.NewState(spec.persona or {
            backstory = spec.backstory,
        })
        if not persona then return false, reason end
    end
    if spec.knowledge ~= nil then
        local knowledge, reason = Knowledge.NewState(spec.knowledge)
        if not knowledge then return false, reason end
    end
    return true
end

function Factory.Generate(spec)
    local valid, reason = Factory.ValidateSpec(spec)
    if not valid then return nil, reason end

    local ownerMod = Util.text(spec.ownerMod, "PsychopatzCore")
    local suppliedId = Util.text(spec.actorId, nil)
    local identitySpec = type(spec.identity) == "table" and spec.identity or {}
    local seed = spec.identitySeed or identitySpec.identitySeed
    if type(seed) ~= "string" and type(seed) ~= "number" then seed = nil end
    if not seed then seed = suppliedId or (ownerMod .. ":" .. tostring(Util.hash(spec.archetypeID))) end
    local actorId = suppliedId or "pnc:core:" .. tostring(Util.hash(ownerMod .. ":" .. seed))
    local identity = normalizeIdentity(spec, seed)
    local appearance, appearanceReason = normalizeAppearance(spec.appearance, seed, identity)
    if not appearance then return nil, appearanceReason end
    local persona, personaReason = Persona.NewState(spec.persona or {
        backstory = spec.backstory,
    })
    if not persona then return nil, personaReason end
    local knowledge, knowledgeReason = Knowledge.NewState(spec.knowledge)
    if not knowledge then return nil, knowledgeReason end

    return {
        schema = Factory.SCHEMA,
        schemaVersion = Factory.SCHEMA_VERSION,
        actorId = actorId,
        ownerMod = ownerMod,
        revision = 1,
        identity = identity,
        appearance = appearance,
        persona = persona,
        knowledge = knowledge,
        extensions = Util.clone(spec.extensions or {}),
        source = Util.clone(spec.source),
        social = Util.clone(spec.social),
        world = Util.clone(spec.world),
    }
end

function Factory.ValidateActor(actor)
    if type(actor) ~= "table" then return false, "actor_required" end
    if actor.schema ~= Factory.SCHEMA
        or Util.integer(actor.schemaVersion, 0) ~= Factory.SCHEMA_VERSION
    then
        return false, "actor_schema_mismatch"
    end
    if Util.text(actor.actorId, nil) == nil then return false, "actor_id_required" end
    if Util.text(actor.ownerMod, nil) == nil then return false, "owner_mod_required" end
    if Util.integer(actor.revision, 0) < 1 then return false, "revision_required" end
    if type(actor.identity) ~= "table" or type(actor.appearance) ~= "table" then
        return false, "identity_appearance_required"
    end
    if (type(actor.identity.identitySeed) ~= "string"
        and type(actor.identity.identitySeed) ~= "number")
        or type(actor.identity.survivor) ~= "table"
    then
        return false, "identity_contract_invalid"
    end
    if Util.integer(actor.appearance.policySchemaVersion, 0)
        ~= Factory.APPEARANCE_POLICY_SCHEMA
        or type(actor.appearance.policy) ~= "table"
        or type(actor.appearance.resolved) ~= "table"
        or type(actor.appearance.contract) ~= "table"
    then
        return false, "appearance_contract_invalid"
    end
    if actor.persona ~= nil then
        local personaValid, personaReason = Persona.Validate(actor.persona)
        if not personaValid then return false, personaReason end
    end
    if actor.knowledge ~= nil then
        local knowledgeValid, knowledgeReason = Knowledge.Validate(actor.knowledge)
        if not knowledgeValid then return false, knowledgeReason end
    end
    if not Util.isSerializable(actor) then return false, "actor_not_serializable" end
    return true
end

return Factory
