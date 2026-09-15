-- Shared parent-plus-lift opacity for conversation panels and their content.
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}

local Conversation = PsychopatzCore.Conversation
local Settings = Conversation.Settings or {}
Conversation.Settings = Settings
local Opacity = Conversation.Opacity or {}
Conversation.Opacity = Opacity

Opacity.DefaultBase = 0.82
Opacity.DefaultLift = 0.18

local PART_DEFAULTS = {
    portrait = { surface = 0.10, detail = 0.18 },
    history = { surface = 0.00, detail = 0.18 },
    relationship = { surface = 0.00, detail = 0.18 },
    choices = { surface = 0.00, detail = 0.18 },
    llmInput = { surface = 0.00, detail = 0.18 },
}

local PART_ORDER = { "portrait", "history", "relationship", "choices", "llmInput" }

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function getSetting(key, fallback)
    if type(Settings.Get) == "function" then
        return Settings.Get(key, fallback)
    end
    return fallback
end

local function roleName(role)
    return tostring(role or "surface"):lower() == "detail"
        and "detail" or "surface"
end

local function liftKey(partID, role)
    return tostring(partID or "history")
        .. (roleName(role) == "detail"
            and "DetailOpacityLift" or "SurfaceOpacityLift")
end

local function defaultsFor(partID)
    return PART_DEFAULTS[tostring(partID or "")] or {
        surface = 0,
        detail = Opacity.DefaultLift,
    }
end

function Opacity.GetBase()
    return clamp(
        tonumber(getSetting("conversationOpacityBase", Opacity.DefaultBase))
            or Opacity.DefaultBase,
        0,
        1
    )
end

function Opacity.GetLift(partID, role)
    local normalizedRole = roleName(role)
    local defaults = defaultsFor(partID)
    local fallback = tonumber(defaults[normalizedRole]) or 0
    return clamp(
        tonumber(getSetting(liftKey(partID, normalizedRole), fallback))
            or fallback,
        0,
        0.25
    )
end

function Opacity.Get(partID, role)
    return clamp(
        Opacity.GetBase() + Opacity.GetLift(partID, role),
        0,
        1
    )
end

Opacity.GetOpacity = Opacity.Get

function Opacity.GetSignature()
    local values = { string.format("%.4f", Opacity.GetBase()) }
    for _, partID in ipairs(PART_ORDER) do
        values[#values + 1] = string.format(
            "%.4f:%.4f",
            Opacity.GetLift(partID, "surface"),
            Opacity.GetLift(partID, "detail")
        )
    end
    return table.concat(values, "|")
end

Opacity.GetContentOpacitySignature = Opacity.GetSignature

function Opacity.ApplyColorAlpha(color, alpha)
    if color then color.a = clamp(tonumber(alpha) or 0, 0, 1) end
    return color
end

return Opacity
