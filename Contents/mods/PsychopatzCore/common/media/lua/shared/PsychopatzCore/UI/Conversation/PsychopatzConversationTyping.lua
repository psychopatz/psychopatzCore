PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}
PsychopatzCore.Conversation.Typing =
    PsychopatzCore.Conversation.Typing or {}

local Typing = PsychopatzCore.Conversation.Typing

Typing.FRAME_MS = Typing.FRAME_MS or 240

local function now()
    return getTimeInMillis and tonumber(getTimeInMillis()) or 0
end

function Typing.GetText(timestamp)
    local phase = math.floor(
        (tonumber(timestamp) or now()) / Typing.FRAME_MS
    ) % 4
    return phase == 0 and "."
        or phase == 1 and ".  ."
        or phase == 2 and ".  .  ."
        or ".  ."
end

return Typing
