PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}

local Conversation = PsychopatzCore.Conversation
local Theme = Conversation.Theme or {}
Conversation.Theme = Theme

Theme.DEFAULT = Theme.DEFAULT or {
    r = 0.28,
    g = 0.76,
    b = 0.62,
}

local function channel(value, fallback)
    return math.max(0, math.min(1, tonumber(value) or fallback))
end

function Theme.Resolve(spec, fallback)
    fallback = type(fallback) == "table" and fallback or Theme.DEFAULT
    local theme = type(spec) == "table" and spec.theme or nil
    local accent = type(theme) == "table"
        and (theme.accent or theme.color) or nil
    accent = type(accent) == "table" and accent or fallback
    return {
        r = channel(accent.r, fallback.r or Theme.DEFAULT.r),
        g = channel(accent.g, fallback.g or Theme.DEFAULT.g),
        b = channel(accent.b, fallback.b or Theme.DEFAULT.b),
    }
end

function Theme.Brighten(color, amount)
    color = Theme.Resolve({ theme = { accent = color } })
    amount = math.max(0, math.min(1, tonumber(amount) or 0.25))
    return {
        r = color.r + (1 - color.r) * amount,
        g = color.g + (1 - color.g) * amount,
        b = color.b + (1 - color.b) * amount,
    }
end

return Theme
