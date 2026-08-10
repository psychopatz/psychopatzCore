-- Cross-mod registry for discoverable channels and passive broadcast events.

local Frequencies = PsychopatzCore.RadioFrequencies

Frequencies.Providers = Frequencies.Providers or {}

local function log(message)
    print("[PsychopatzCore][RadioFrequencies] " .. tostring(message))
end

function Frequencies.RegisterProvider(id, definition)
    id = tostring(id or "")
    if id == "" or type(definition) ~= "table"
        or type(definition.listChannels) ~= "function"
    then
        log("ignored invalid provider registration")
        return false
    end
    definition.id = id
    Frequencies.Providers[id] = definition
    return true
end

function Frequencies.UnregisterProvider(id)
    id = tostring(id or "")
    if id == "" or Frequencies.Providers[id] == nil then return false end
    Frequencies.Providers[id] = nil
    return true
end

function Frequencies.ListChannels(context)
    local output = {}
    local seen = {}
    for providerID, provider in pairs(Frequencies.Providers) do
        local ok, channels = pcall(provider.listChannels,
            context or {}, provider)
        if ok then
            for _, source in ipairs(type(channels) == "table"
                and channels or {})
            do
                local id = tostring(source.id
                    or providerID .. ":" .. tostring(source.frequency or ""))
                local frequency = Frequencies.NormalizeMHz(source.frequency)
                if id ~= "" and frequency and not seen[id] then
                    seen[id] = true
                    output[#output + 1] = {
                        id = id,
                        providerID = providerID,
                        frequency = frequency,
                        name = tostring(source.name or id),
                        temporary = source.temporary == true,
                        metadata = source.metadata,
                    }
                end
            end
        elseif not ok then
            log("provider '" .. providerID
                .. "' listChannels failed: " .. tostring(channels))
        end
    end
    table.sort(output, function(left, right)
        if left.frequency ~= right.frequency then
            return left.frequency < right.frequency
        end
        return left.id < right.id
    end)
    return output
end

function Frequencies.PollEvents(context)
    local output = {}
    for providerID, provider in pairs(Frequencies.Providers) do
        if type(provider.pollEvents) == "function" then
            local ok, events = pcall(provider.pollEvents,
                context or {}, provider)
            if ok then
                for _, event in ipairs(type(events) == "table"
                    and events or {})
                do
                    local frequency = Frequencies.NormalizeMHz(
                        event.frequency)
                    if frequency and event.text ~= nil then
                        output[#output + 1] = {
                            id = tostring(event.id or providerID .. ":event"),
                            providerID = providerID,
                            frequency = frequency,
                            channelID = event.channelID,
                            channelName = event.channelName,
                            text = tostring(event.text),
                            durationMs = math.max(1000,
                                tonumber(event.durationMs) or 10000),
                            metadata = event.metadata,
                        }
                    end
                end
            elseif not ok then
                log("provider '" .. providerID
                    .. "' pollEvents failed: " .. tostring(events))
            end
        end
    end
    return output
end

return Frequencies
