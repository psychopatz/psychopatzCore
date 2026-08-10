require "PsychopatzCore/00_PsychopatzCore_Init"

local Radio = PsychopatzCore.CustomRadio
Radio.NativeChannels = Radio.NativeChannels or {}

local function category(name)
    local categories = {
        Radio = ChannelCategory.Radio,
        Emergency = ChannelCategory.Emergency,
        Television = ChannelCategory.Television,
        Military = ChannelCategory.Military,
        Amateur = ChannelCategory.Amateur,
        Bandit = ChannelCategory.Bandit,
        Other = ChannelCategory.Other,
    }
    return categories[name] or ChannelCategory.Other
end

local function onLoadRadioScripts(manager)
    for _, definition in ipairs(Radio.ListChannels()) do
        local native = manager:getRadioChannel(definition.guid)
        if not native then
            native = DynamicRadioChannel.new(
                definition.name,
                definition.frequency,
                category(definition.category),
                definition.guid
            )
            if definition.airCounterMultiplier then
                native:setAirCounterMultiplier(
                    tonumber(definition.airCounterMultiplier) or 1)
            end
            manager:AddChannel(native, false)
        end
        Radio.NativeChannels[definition.id] = native
    end
end

function Radio.AirEvent(channelID, eventType, context)
    local channel = Radio.NativeChannels[tostring(channelID or "")]
    if not channel then return false, "channel_unavailable" end
    local message = Radio.SelectMessage(channelID, eventType, context or {})
    if not message or #message.lines == 0 then
        return false, "message_unavailable"
    end
    local id = "PSY-" .. tostring(getTimestampMs and getTimestampMs()
        or ZombRand and ZombRand(100000, 999999) or 1)
    local broadcast = RadioBroadCast.new(id, -1, -1)
    for _, source in ipairs(message.lines) do
        local line = source.effects
            and RadioLine.new(source.text,
                source.r, source.g, source.b, source.effects)
            or RadioLine.new(source.text, source.r, source.g, source.b)
        if source.airTime then line:setAirTime(source.airTime) end
        broadcast:AddRadioLine(line)
    end
    channel:setAiringBroadcast(broadcast)
    return true, message
end

Events.OnLoadRadioScripts.Add(onLoadRadioScripts)

return Radio
