-- Provider-neutral broadcast delivery for Core-owned radio channels.
--
-- Content providers stay in their owning mod. Core owns the common lifecycle:
-- validate the provider/channel, air the selected message through CustomRadio,
-- and notify the provider after the engine accepts the broadcast.

PsychopatzCore = PsychopatzCore or {}
local Broadcasts = PsychopatzCore.RadioBroadcasts or {}
PsychopatzCore.RadioBroadcasts = Broadcasts

local Radio = PsychopatzCore.CustomRadio
local MAX_TRACE = 64

Broadcasts.VERSION = 1
Broadcasts.Providers = Broadcasts.Providers or {}
Broadcasts.Trace = Broadcasts.Trace or {}

local function id(value)
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function trace(entry)
    Broadcasts.Trace[#Broadcasts.Trace + 1] = entry
    while #Broadcasts.Trace > MAX_TRACE do
        table.remove(Broadcasts.Trace, 1)
    end
end

function Broadcasts.RegisterProvider(providerID, definition)
    providerID = id(providerID)
    if not providerID or type(definition) ~= "table" then
        return false, "broadcast_provider_invalid"
    end
    definition.id = providerID
    Broadcasts.Providers[providerID] = definition
    return true
end

function Broadcasts.UnregisterProvider(providerID)
    providerID = id(providerID)
    if not providerID or Broadcasts.Providers[providerID] == nil then
        return false
    end
    Broadcasts.Providers[providerID] = nil
    return true
end

function Broadcasts.GetProvider(providerID)
    return Broadcasts.Providers[id(providerID) or ""]
end

function Broadcasts.ListProviders()
    local output = {}
    for providerID, definition in pairs(Broadcasts.Providers) do
        output[#output + 1] = {
            id = providerID,
            channelID = definition.channelID,
        }
    end
    table.sort(output, function(left, right)
        return left.id < right.id
    end)
    return output
end

-- Air one provider-owned event through the singular Core radio path.
-- provider.onAired is an addon-owned callback invoked only after the radio
-- engine accepts the event, so its failure cannot turn a played broadcast
-- into a false delivery failure.
function Broadcasts.Air(providerID, specification)
    local provider = Broadcasts.GetProvider(providerID)
    local channelID
    local eventType
    local context
    local aired
    local message
    local result
    specification = type(specification) == "table" and specification or {}
    if not provider then return false, "broadcast_provider_unavailable" end
    channelID = id(specification.channelID or provider.channelID)
    if not channelID then return false, "broadcast_channel_required" end
    if provider.channelID
        and tostring(provider.channelID) ~= channelID
    then
        return false, "broadcast_channel_mismatch"
    end
    eventType = id(specification.eventType) or "*"
    context = type(specification.context) == "table"
        and specification.context or {}
    if not Radio or type(Radio.AirEvent) ~= "function" then
        return false, "radio_engine_unavailable"
    end
    aired, message = Radio.AirEvent(channelID, eventType, context)
    if not aired then return false, message or "broadcast_not_aired", context end
    result = {
        providerID = provider.id,
        channelID = channelID,
        eventType = eventType,
        context = context,
        message = message,
    }
    trace({
        providerID = provider.id,
        channelID = channelID,
        eventType = eventType,
    })
    if type(provider.onAired) == "function" then
        -- This is an unavoidable failure boundary for an addon-owned hook;
        -- the authoritative radio delivery has already completed.
        local ok, callbackReason = pcall(provider.onAired, result,
            specification)
        if not ok then
            trace({
                providerID = provider.id,
                eventType = eventType,
                callbackError = tostring(callbackReason),
            })
        end
    end
    return true, message, context, result
end

return Broadcasts
