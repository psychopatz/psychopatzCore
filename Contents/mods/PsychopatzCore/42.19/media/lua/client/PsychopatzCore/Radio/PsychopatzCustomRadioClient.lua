require "PsychopatzCore/00_PsychopatzCore_Init"
require "RadioCom/RadioWindowModules/RWMChannel"

local Radio = PsychopatzCore.CustomRadio
local POLL_MS = 5000
local lastPollAt = 0

local function displayName(definition)
    if definition.nameKey and getText then
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

local function addDevice(output, seen, item)
    if not item or not instanceof(item, "Radio") or seen[item] then return end
    seen[item] = true
    output[#output + 1] = item
end

local function playerDevices(player)
    local output, seen = {}, {}
    addDevice(output, seen, player:getPrimaryHandItem())
    addDevice(output, seen, player:getSecondaryHandItem())
    local attached = player.getAttachedItems and player:getAttachedItems() or nil
    if attached then
        for index = 0, attached:size() - 1 do
            addDevice(output, seen, attached:get(index):getItem())
        end
    end
    return output
end

local function onTick()
    local at = getTimestampMs and tonumber(getTimestampMs()) or 0
    if at - lastPollAt < POLL_MS then return end
    lastPollAt = at
    for playerNum = 0, 3 do
        local player = getSpecificPlayer and getSpecificPlayer(playerNum) or nil
        if player and not player:isDead() then
            local notified = {}
            for _, item in ipairs(playerDevices(player)) do
                local data = item:getDeviceData()
                if data and data:getIsTurnedOn() and data:getPower() > 0 then
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
