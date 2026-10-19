local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"

local Interaction = {}
Interaction.SCHEMA_VERSION = 1

function Interaction.BuildNearbyConversation(entry, viewerKey, distance)
    if type(entry) ~= "table" or not Util.text(entry.actorID, nil) then
        return nil, "map_entry_required"
    end
    if not entry.capabilities or entry.capabilities.talk ~= true then
        return nil, "conversation_unavailable"
    end
    return {
        schemaVersion = Interaction.SCHEMA_VERSION,
        requestID = "talk:" .. entry.actorID .. ":"
            .. tostring(Util.hash(tostring(viewerKey or "anonymous")
                .. ":" .. tostring(entry.revision or 0))),
        actorID = entry.actorID,
        viewerKey = Util.text(viewerKey, nil),
        action = "talk",
        distance = tonumber(distance) or 0,
        provider = entry.provider,
    }
end

function Interaction.AuthorizeConversation(request, entry, context)
    context = type(context) == "table" and context or {}
    if type(request) ~= "table" or type(entry) ~= "table" then
        return false, "interaction_required"
    end
    if request.actorID ~= entry.actorID or request.action ~= "talk" then
        return false, "interaction_target_mismatch"
    end
    if context.authority ~= "server" then
        return false, "server_authority_required"
    end
    if entry.capabilities.talk ~= true then
        return false, "conversation_unavailable"
    end
    local radius = math.max(0, tonumber(context.maxDistance) or 4)
    if tonumber(request.distance) and request.distance > radius then
        return false, "actor_not_nearby"
    end
    return true, {
        requestID = request.requestID,
        actorID = entry.actorID,
        action = "talk",
        authorized = true,
    }
end

return Interaction
