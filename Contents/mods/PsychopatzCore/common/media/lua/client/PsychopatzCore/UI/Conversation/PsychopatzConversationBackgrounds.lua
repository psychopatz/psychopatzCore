PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}

local Conversation = PsychopatzCore.Conversation
local Backgrounds = Conversation.Backgrounds or {}
Conversation.Backgrounds = Backgrounds
Backgrounds.registry = Backgrounds.registry or {}

function Backgrounds.Register(id, definition)
    if not id or type(definition) ~= "table" then return false end
    Backgrounds.registry[tostring(id)] = definition
    return definition
end

function Backgrounds.Get(id)
    return Backgrounds.registry[tostring(id or "twilight")]
        or Backgrounds.registry.twilight
end

local root = "media/ui/Conversation/Backgrounds/"

Backgrounds.Register("dawn", {
    texture = root .. "dawn.png",
    tint = { r = 0.90, g = 0.96, b = 1.0 },
})
Backgrounds.Register("sunrise", {
    texture = root .. "sunrise.png",
    tint = { r = 1.0, g = 0.92, b = 0.76 },
})
Backgrounds.Register("sunset", {
    texture = root .. "sunset.png",
    tint = { r = 1.0, g = 0.72, b = 0.50 },
})
Backgrounds.Register("dusk", {
    texture = root .. "dusk.png",
    tint = { r = 0.72, g = 0.82, b = 0.94 },
})
Backgrounds.Register("twilight", {
    texture = root .. "twilight.png",
    tint = { r = 0.64, g = 0.76, b = 0.88 },
})

return Backgrounds
