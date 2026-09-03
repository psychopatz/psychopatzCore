local Radio = PsychopatzCore.CustomRadio

Radio.Channels = Radio.Channels or {}
Radio.ChannelsByFrequency = Radio.ChannelsByFrequency or {}
Radio.Listeners = Radio.Listeners or {}

local function channelID(value)
    value = tostring(value or "")
    return value ~= "" and value or nil
end

function Radio.RegisterChannel(definition)
    if type(definition) ~= "table" then return false end
    local id = channelID(definition.id)
    local frequency = math.floor(tonumber(definition.frequency) or 0)
    if not id or frequency <= 0 then return false end
    local occupied = Radio.ChannelsByFrequency[frequency]
    if occupied and occupied.id ~= id then return false end
    local previous = Radio.Channels[id]
    if previous then Radio.ChannelsByFrequency[previous.frequency] = nil end
    definition.id = id
    definition.frequency = frequency
    definition.name = tostring(definition.name or id)
    definition.guid = tostring(definition.guid or id)
    definition.category = tostring(definition.category or "Other")
    Radio.Channels[id] = definition
    Radio.ChannelsByFrequency[frequency] = definition
    return true
end

function Radio.GetChannel(id)
    return Radio.Channels[channelID(id)]
end

function Radio.GetChannelByFrequency(frequency)
    return Radio.ChannelsByFrequency[
        math.floor(tonumber(frequency) or 0)]
end

function Radio.ListChannels()
    local output = {}
    for _, definition in pairs(Radio.Channels) do
        output[#output + 1] = definition
    end
    table.sort(output, function(left, right)
        if left.frequency ~= right.frequency then
            return left.frequency < right.frequency
        end
        return left.id < right.id
    end)
    return output
end

function Radio.RegisterListener(channel, id, callback)
    channel = channelID(channel)
    id = channelID(id)
    if not channel or not id or type(callback) ~= "function" then
        return false
    end
    Radio.Listeners[channel] = Radio.Listeners[channel] or {}
    Radio.Listeners[channel][id] = callback
    return true
end

function Radio.UnregisterListener(channel, id)
    local listeners = Radio.Listeners[channelID(channel)]
    id = channelID(id)
    if not listeners or not id or listeners[id] == nil then return false end
    listeners[id] = nil
    return true
end

function Radio.NotifyTuned(channel, context)
    local count = 0
    for id, callback in pairs(Radio.Listeners[channel] or {}) do
        local ok, handled = pcall(callback, context or {}, id)
        if ok and handled ~= false then count = count + 1 end
    end
    return count
end

return Radio
