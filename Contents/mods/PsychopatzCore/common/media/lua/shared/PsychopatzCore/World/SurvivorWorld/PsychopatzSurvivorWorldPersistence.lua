local Json = require "PsychopatzCore/Serialization/PsychopatzJson"
local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"
local Types =
    require "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldTypes"

local Persistence = {}

Persistence.SCHEMA = "PsychopatzCore.SurvivorWorld.Registry"
Persistence.SCHEMA_VERSION = 1
Persistence.MAX_BYTES = 32 * 1024 * 1024
Persistence.JSON_LIMITS = {
    maxString = Persistence.MAX_BYTES,
    maxDepth = 32,
    maxCollection = 8192,
}

local function validateEnvelope(payload)
    if type(payload) ~= "table"
        or payload.schema ~= Persistence.SCHEMA
        or tonumber(payload.schemaVersion)
            ~= Persistence.SCHEMA_VERSION
        or type(payload.world) ~= "table"
    then
        return nil, "survivor_world_registry_schema_mismatch"
    end
    local bounded, reason = Types.ValidateInputBounds(payload.world)
    if not bounded then return nil, reason end
    local normalized = Types.NormalizeSnapshot(payload.world)
    local valid, reason = Types.ValidateSnapshot(normalized)
    if not valid then return nil, reason end
    return normalized
end

function Persistence.Encode(snapshot)
    local bounded, reason = Types.ValidateInputBounds(snapshot)
    if not bounded then return nil, reason end
    local normalized = Types.NormalizeSnapshot(snapshot)
    local valid
    valid, reason = Types.ValidateSnapshot(normalized)
    if not valid then return nil, reason end
    return {
        schema = Persistence.SCHEMA,
        schemaVersion = Persistence.SCHEMA_VERSION,
        world = normalized,
    }
end

function Persistence.Serialize(snapshot)
    local payload, reason = Persistence.Encode(snapshot)
    if not payload then return nil, reason end
    local encoded = Json.Encode(payload, Persistence.JSON_LIMITS)
    if not encoded then return nil, "survivor_world_encode_failed" end
    if #encoded > Persistence.MAX_BYTES then
        return nil, "survivor_world_payload_too_large"
    end
    return encoded
end

function Persistence.Decode(serialized)
    local payload = serialized
    if type(serialized) == "string" then
        if #serialized > Persistence.MAX_BYTES then
            return nil, "survivor_world_payload_too_large"
        end
        local reason
        payload, reason = Json.Decode(
            serialized,
            Persistence.JSON_LIMITS
        )
        if payload == nil then
            return nil, reason or "survivor_world_decode_failed"
        end
    else
        payload = Util.clone(serialized)
    end
    return validateEnvelope(payload)
end

return Persistence
