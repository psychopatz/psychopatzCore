-- Core-owned open band shared by world-discovery and future mod providers.

PsychopatzCore = PsychopatzCore or {}
local Radio = PsychopatzCore.CustomRadio
if not Radio or type(Radio.RegisterChannel) ~= "function" then
    return nil
end

local Channel = PsychopatzCore.RadioBroadcastChannel or {
    ID = "psychopatzcore.world_broadcast",
    GUID = "PSY-WORLD-69000",
    FREQUENCY = 69000,
}
PsychopatzCore.RadioBroadcastChannel = Channel

Radio.RegisterChannel({
    id = Channel.ID,
    guid = Channel.GUID,
    frequency = Channel.FREQUENCY,
    name = "Open World Band",
    nameKey = "UI_PsychopatzCore_Radio_WorldBroadcastChannel",
    category = "Amateur",
    autoPreset = true,
    airCounterMultiplier = 0.75,
})

return Channel
