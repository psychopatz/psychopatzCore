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
local MALE_HAIR_MODELS = {
    "Baldspot", "Messy", "Short", "Recede",
}
local FEMALE_HAIR_MODELS = {
    "Ponytail", "Long2", "Bob", "StraightLong",
}
local HAIR_COLORS = {
    { r = 0.08, g = 0.05, b = 0.03 },
    { r = 0.25, g = 0.12, b = 0.05 },
    { r = 0.72, g = 0.55, b = 0.25 },
    { r = 0.48, g = 0.08, b = 0.03 },
}
local SKIN_TONES = { "light", "tan", "olive", "dark" }
local SKIN_COLORS = {
    { r = 0.86, g = 0.68, b = 0.53 },
    { r = 0.72, g = 0.50, b = 0.36 },
    { r = 0.58, g = 0.38, b = 0.25 },
    { r = 0.38, g = 0.23, b = 0.15 },
}
local BEARDS = { "FullBeard", "Goatee", "Moustache", "ShortBoxedBeard" }
-- Keep the visual contract provider-neutral: Core supplies a base-game named
-- outfit plus concrete item specs.  Providers may materialize those specs,
-- while portrait panels can render the same data without a body.
local OUTFIT_LOADOUTS = {
    {
        profile = "caravan_casual",
        outfit = "Survivor",
        items = {
            "Base.Tshirt_DefaultTEXTURE_TINT",
            "Base.Trousers_Denim",
            "Base.Shoes_Random",
        },
        specs = {
            {
                type = "Base.Tshirt_DefaultTEXTURE_TINT",
                wornSlot = "Torso_Upper",
            },
            { type = "Base.Trousers_Denim", wornSlot = "Legs" },
            { type = "Base.Shoes_Random", wornSlot = "Shoes" },
        },
    },
    {
        profile = "caravan_workwear",
        outfit = "Survivor",
        items = {
            "Base.Shirt_Workman",
            "Base.Trousers_JeanBaggy",
            "Base.Shoes_WorkBoots",
        },
        specs = {
            { type = "Base.Shirt_Workman", wornSlot = "Torso_Upper" },
            { type = "Base.Trousers_JeanBaggy", wornSlot = "Legs" },
            { type = "Base.Shoes_WorkBoots", wornSlot = "Shoes" },
        },
    },
    {
        profile = "caravan_field",
        outfit = "Survivor",
        items = {
            "Base.HoodieDOWN_WhiteTINT",
            "Base.Trousers_Padded",
            "Base.Shoes_HikingBoots",
        },
        specs = {
            { type = "Base.HoodieDOWN_WhiteTINT", wornSlot = "Torso_Upper" },
            { type = "Base.Trousers_Padded", wornSlot = "Legs" },
            { type = "Base.Shoes_HikingBoots", wornSlot = "Shoes" },
        },
    },
    {
        profile = "caravan_formal",
        outfit = "Survivor",
        items = {
            "Base.Shirt_FormalWhite",
            "Base.Trousers_Suit",
            "Base.Shoes_Black",
        },
        specs = {
            { type = "Base.Shirt_FormalWhite", wornSlot = "Torso_Upper" },
            { type = "Base.Trousers_Suit", wornSlot = "Legs" },
            { type = "Base.Shoes_Black", wornSlot = "Shoes" },
        },
    },
}

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

local function generatedAppearanceV1(seed, identity)
    local loadout = Util.pick(OUTFIT_LOADOUTS, seed, 13)
    local isFemale = identity.gender == "female"
    local resolved = {
        skinTone = Util.pick(SKIN_TONES, seed, 3),
        skinTexture = isFemale and "FemaleBody01" or "MaleBody01",
        skinColor = Util.clone(Util.pick(SKIN_COLORS, seed, 9)),
        hairModel = Util.pick(
            isFemale and FEMALE_HAIR_MODELS or MALE_HAIR_MODELS,
            seed,
            5
        ),
        hairColor = Util.clone(Util.pick(HAIR_COLORS, seed, 7)),
        beardModel = isFemale and "" or Util.pick(BEARDS, seed, 11),
        outfit = loadout.outfit,
        outfitMode = "item",
        outfitProfile = loadout.profile,
        outfitItems = Util.clone(loadout.items),
        outfitItemSpecs = Util.clone(loadout.specs),
        gender = identity.gender,
    }
    local policy = {
        schemaVersion = Factory.APPEARANCE_POLICY_SCHEMA,
        mode = "generated",
        seed = seed,
        generatorVersion = 1,
    }
    return policy, resolved
end

local function generatedAppearanceForVersion(version, seed, identity)
    version = Util.integer(version, 0)
    if version ~= 1 then
        return nil, nil, "appearance_generator_unsupported"
    end
    local policy, resolved = generatedAppearanceV1(seed, identity)
    return policy, resolved
end

local function buildGeneratedAppearance(seed, identity, version)
    local policy, resolved, reason = generatedAppearanceForVersion(
        version, seed, identity)
    if not policy then return nil, reason end
    return {
        policySchemaVersion = Factory.APPEARANCE_POLICY_SCHEMA,
        policy = policy,
        resolved = resolved,
        contract = {
            schemaVersion = Factory.APPEARANCE_CONTRACT_SCHEMA,
            mode = "GENERATED_DEFAULT",
            generator = {
                seed = seed,
                version = version,
                archetypeID = identity.archetypeID,
            },
            policyHash = Json.Fingerprint(Json.Encode(policy)),
        },
    }
end

local LEGACY_GENERATED_OUTFITS = {
    casual = true,
    workwear = true,
    survival = true,
    formal = true,
}

local function upgradeLegacyGeneratedAppearance(appearance, identity)
    if type(appearance) ~= "table"
        or type(appearance.contract) ~= "table"
        or appearance.contract.mode ~= "GENERATED_DEFAULT"
        or type(appearance.resolved) ~= "table"
    then
        return Util.clone(appearance)
    end
    local resolved = appearance.resolved
    if type(resolved.outfitItemSpecs) == "table"
        and #resolved.outfitItemSpecs > 0
    then
        return Util.clone(appearance)
    end
    if not LEGACY_GENERATED_OUTFITS[resolved.outfit] then
        return Util.clone(appearance)
    end

    local upgraded, reason = buildGeneratedAppearance(
        identity.identitySeed,
        identity,
        Factory.GENERATOR_VERSION
    )
    if not upgraded then return nil, reason end
    for _, key in ipairs({
        "skinTone", "hairModel", "hairColor", "beardModel", "gender",
    }) do
        if resolved[key] ~= nil then
            upgraded.resolved[key] = Util.clone(resolved[key])
        end
    end
    return upgraded
end

function Factory.UpgradeAppearance(appearance, identity)
    if type(identity) ~= "table" then
        return nil, "appearance_identity_required"
    end
    return upgradeLegacyGeneratedAppearance(appearance, identity)
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
        return buildGeneratedAppearance(
            seed, identity, Factory.GENERATOR_VERSION)
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

function Factory.CompactAppearance(appearance, identity)
    if type(appearance) ~= "table" or type(identity) ~= "table" then
        return nil, "appearance_identity_required"
    end
    local contract = type(appearance.contract) == "table"
        and appearance.contract or {}
    local generator = type(contract.generator) == "table"
        and contract.generator or {}
    if contract.mode == "GENERATED_DEFAULT" then
        local version = Util.integer(
            generator.version,
            Factory.GENERATOR_VERSION
        )
        local rebuilt, reason = buildGeneratedAppearance(
            identity.identitySeed,
            identity,
            version
        )
        if not rebuilt then return nil, reason end
        if Json.Encode(rebuilt) == Json.Encode(appearance) then
            return {
                schemaVersion = 1,
                mode = "generated",
                generatorVersion = version,
            }
        end
    end
    return {
        schemaVersion = 1,
        mode = "full",
        value = Util.clone(appearance),
    }
end

function Factory.ExpandAppearance(compact, identity)
    if type(identity) ~= "table" then
        return nil, "appearance_identity_required"
    end
    if type(compact) == "table"
        and type(compact.policy) == "table"
        and type(compact.resolved) == "table"
        and type(compact.contract) == "table"
    then
        return Util.clone(compact)
    end
    if type(compact) ~= "table"
        or tonumber(compact.schemaVersion) ~= 1
    then
        return nil, "appearance_compact_schema_mismatch"
    end
    if compact.mode == "generated" then
        return buildGeneratedAppearance(
            identity.identitySeed,
            identity,
            compact.generatorVersion
        )
    end
    if compact.mode == "full" and type(compact.value) == "table" then
        return Factory.UpgradeAppearance(compact.value, identity)
    end
    return nil, "appearance_compact_mode_invalid"
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
