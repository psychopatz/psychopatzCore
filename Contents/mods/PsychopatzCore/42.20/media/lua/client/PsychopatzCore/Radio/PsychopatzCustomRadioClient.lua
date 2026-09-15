require "PsychopatzCore/00_PsychopatzCore_Init"
require "RadioCom/RadioWindowModules/RWMChannel"

local Radio = PsychopatzCore.CustomRadio
local RadioDeviceState = PsychopatzCore.RadioDeviceState
local Translation = PsychopatzCore.Translation
local POLL_MS = 5000
local lastPollAt = 0

local function nowMs()
    if getTimeInMillis then return tonumber(getTimeInMillis()) or 0 end
    if getTimestampMs then return tonumber(getTimestampMs()) or 0 end
    local time = getGameTime and getGameTime() or nil
    if time and time.getWorldAgeHours then
        return (tonumber(time:getWorldAgeHours()) or 0) * 3600000
    end
    return 0
end

local function displayName(definition)
    if definition.nameKey and Translation and Translation.GetKey then
        local value = Translation.GetKey(definition.nameKey, definition.name)
        if value and value ~= definition.nameKey then return value end
    elseif definition.nameKey and getText then
        local value = getText(definition.nameKey)
        if value and value ~= definition.nameKey then return value end
    end
    return definition.name
end

function Radio.EnsureDevicePresets(deviceData)
    local holder = deviceData and deviceData.getDevicePresets
        and deviceData:getDevicePresets() or nil
    local presets = holder and holder:getPresets() or nil
    if not presets then return false end
    local changed = false
    for _, definition in ipairs(Radio.ListChannels()) do
        local inRange = definition.autoPreset ~= false
            and definition.frequency >= deviceData:getMinChannelRange()
            and definition.frequency <= deviceData:getMaxChannelRange()
        local exists = false
        for index = 0, presets:size() - 1 do
            if presets:get(index):getFrequency() == definition.frequency then
                exists = true
                break
            end
        end
        if inRange and not exists and presets:size() < holder:getMaxPresets() then
            presets:add(PresetEntry.new(
                displayName(definition), definition.frequency))
            changed = true
        end
    end
    if changed and deviceData.transmitPresets then
        deviceData:transmitPresets()
    end
    return changed
end

if not RWMChannel.psychopatzCustomRadioPatched then
    local originalReadFromObject = RWMChannel.readFromObject
    function RWMChannel:readFromObject(player, device, deviceData, deviceType)
        Radio.EnsureDevicePresets(deviceData)
        return originalReadFromObject(self,
            player, device, deviceData, deviceType)
    end
    RWMChannel.psychopatzCustomRadioPatched = true
end

local function playerDevices(player)
    return RadioDeviceState.GetPlayerDevices(player)
end

local function onTick()
    local at = nowMs()
    if at < lastPollAt then lastPollAt = 0 end
    if at - lastPollAt < POLL_MS then return end
    lastPollAt = at
    for playerNum = 0, 3 do
        local player = getSpecificPlayer and getSpecificPlayer(playerNum) or nil
        if player and not player:isDead() then
            local notified = {}
            for _, item in ipairs(playerDevices(player)) do
                local data = item:getDeviceData()
                if data and RadioDeviceState.IsActive(data) then
                    local definition = Radio.GetChannelByFrequency(
                        data:getChannel())
                    if definition and not notified[definition.id] then
                        notified[definition.id] = true
                        Radio.NotifyTuned(definition.id, {
                            player = player,
                            playerNum = playerNum,
                            device = item,
                            deviceData = data,
                            channel = definition,
                            now = at,
                        })
                    end
                end
            end
        end
    end
end

Events.OnTick.Add(onTick)

return Radio
