local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"

local Presentation = {}
Presentation.SCHEMA_VERSION = 1

function Presentation.BuildPortrait(actor)
    if type(actor) ~= "table" or type(actor.identity) ~= "table"
        or type(actor.appearance) ~= "table"
    then return nil, "actor_presentation_invalid" end
    local survivor = actor.identity.survivor or {}
    local resolved = actor.appearance.resolved or {}
    return {
        schemaVersion = Presentation.SCHEMA_VERSION,
        actorID = actor.actorId,
        displayName = actor.identity.displayName,
        gender = actor.identity.gender,
        voiceProfile = Util.clone(survivor.voiceProfile or {}),
        face = {
            gender = actor.identity.gender,
            skinTone = resolved.skinTone or survivor.skinTone,
            skinColor = resolved.skinColor or survivor.skinColor,
            skinTexture = resolved.skinTexture or survivor.skinTexture,
            hairModel = resolved.hairModel or survivor.hairModel,
            hairColor = resolved.hairColor or survivor.hairColor,
            beardModel = resolved.beardModel or survivor.beardModel,
        },
        appearanceMode = actor.appearance.contract
            and actor.appearance.contract.mode or "UNKNOWN",
        policy = Util.clone(actor.appearance.policy or {}),
    }
end

function Presentation.ValidatePortrait(portrait)
    if type(portrait) ~= "table"
        or Util.integer(portrait.schemaVersion, 0)
            ~= Presentation.SCHEMA_VERSION
        or not Util.text(portrait.actorID, nil)
        or type(portrait.face) ~= "table"
        or type(portrait.policy) ~= "table"
    then return false, "portrait_invalid" end
    return Util.isSerializable(portrait), "portrait_not_serializable"
end

return Presentation
