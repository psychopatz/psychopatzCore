local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"

local Presentation = {}
Presentation.SCHEMA_VERSION = 1

local function equipmentFor(actor)
    local output = { worn = {} }
    local payload = actor and actor.personalInventory
    if type(payload) ~= "table" then return output end

    local ok, ActorInventory = pcall(
        require,
        "PsychopatzCore/Actors/PsychopatzActorInventory"
    )
    if not ok or not ActorInventory
        or type(ActorInventory.Decode) ~= "function"
    then
        return output
    end

    local ledger = ActorInventory.Decode(payload)
    if not ledger then return output end
    local equipment = type(ledger.equipment) == "table"
        and ledger.equipment or {}
    local worn = type(equipment.worn) == "table"
        and equipment.worn or {}
    for slot, itemID in pairs(worn) do
        local item = ledger:Get(itemID)
        if type(item) == "table"
            and type(item.fullType) == "string"
            and item.fullType ~= ""
        then
            output.worn[tostring(slot)] = item.fullType
        end
    end
    return output
end

function Presentation.BuildPortrait(actor)
    if type(actor) ~= "table" or type(actor.identity) ~= "table"
        or type(actor.appearance) ~= "table"
    then return nil, "actor_presentation_invalid" end
    local survivor = actor.identity.survivor or {}
    local resolved = actor.appearance.resolved or {}
    local appearance = Util.clone(resolved)
    if appearance.outfit and appearance.outfitMode == nil then
        appearance.outfitMode = "item"
    end
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
        appearance = appearance,
        equipment = equipmentFor(actor),
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
