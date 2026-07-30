require "PsychopatzCore/UI/Core/PsychopatzUILayout"
require "PsychopatzCore/UI/Conversation/PsychopatzConversationSettings"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}

local Conversation = PsychopatzCore.Conversation
local Settings = Conversation.Settings
local Layout = Conversation.Layout or {}
Conversation.Layout = Layout

Layout.defaults = Layout.defaults or {
    portrait = { x = 0.08, y = 0.12, w = 0.24, h = 0.37 },
    history = { x = 0.40, y = 0.13, w = 0.50, h = 0.41 },
    choices = { x = 0.26, y = 0.64, w = 0.43, h = 0.27 },
}

local function key(part, field)
    return "layout_" .. tostring(part) .. "_" .. tostring(field)
end

local function clamp(value, minimum, maximum)
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

local function rounded(value)
    return math.floor((tonumber(value) or 0) * 10000 + 0.5) / 10000
end

function Layout.GetNormalized(part)
    local defaults = Layout.defaults[part] or Layout.defaults.history
    return {
        x = tonumber(Settings.Get(key(part, "x"), defaults.x)) or defaults.x,
        y = tonumber(Settings.Get(key(part, "y"), defaults.y)) or defaults.y,
        w = tonumber(Settings.Get(key(part, "w"), defaults.w)) or defaults.w,
        h = tonumber(Settings.Get(key(part, "h"), defaults.h)) or defaults.h,
    }
end

function Layout.Resolve(part, screenWidth, screenHeight)
    local state = Layout.GetNormalized(part)
    screenWidth = math.max(1, tonumber(screenWidth) or 1)
    screenHeight = math.max(1, tonumber(screenHeight) or 1)
    return {
        x = math.floor(state.x * screenWidth),
        y = math.floor(state.y * screenHeight),
        width = math.floor(state.w * screenWidth),
        height = math.floor(state.h * screenHeight),
    }
end

function Layout.Save(part, bounds, screenWidth, screenHeight, save)
    screenWidth = math.max(1, tonumber(screenWidth) or 1)
    screenHeight = math.max(1, tonumber(screenHeight) or 1)
    local minimumW = 120 / screenWidth
    local minimumH = 90 / screenHeight
    local state = {
        x = clamp((tonumber(bounds.x) or 0) / screenWidth, 0, 0.95),
        y = clamp((tonumber(bounds.y) or 0) / screenHeight, 0, 0.95),
        w = clamp((tonumber(bounds.width or bounds.w) or 1) / screenWidth, minimumW, 1),
        h = clamp((tonumber(bounds.height or bounds.h) or 1) / screenHeight, minimumH, 1),
    }
    if state.x + state.w > 1 then state.x = math.max(0, 1 - state.w) end
    if state.y + state.h > 1 then state.y = math.max(0, 1 - state.h) end
    Settings.Set(key(part, "x"), rounded(state.x), false)
    Settings.Set(key(part, "y"), rounded(state.y), false)
    Settings.Set(key(part, "w"), rounded(state.w), false)
    Settings.Set(key(part, "h"), rounded(state.h), save ~= false)
    return state
end

function Layout.Reset(part, save)
    local defaults = Layout.defaults[part]
    if not defaults then return false end
    Settings.Set(key(part, "x"), defaults.x, false)
    Settings.Set(key(part, "y"), defaults.y, false)
    Settings.Set(key(part, "w"), defaults.w, false)
    Settings.Set(key(part, "h"), defaults.h, save ~= false)
    return true
end

function Layout.ResetAll(save)
    Layout.Reset("portrait", false)
    Layout.Reset("history", false)
    Layout.Reset("choices", save ~= false)
    local view = Conversation.instance
    if view and view.applySavedLayout then view:applySavedLayout() end
end

return Layout
