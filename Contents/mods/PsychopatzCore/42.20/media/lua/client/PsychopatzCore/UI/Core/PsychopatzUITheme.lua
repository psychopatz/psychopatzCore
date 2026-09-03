require "PsychopatzCore/00_PsychopatzCore_Init"
require "PsychopatzCore/Settings/PsychopatzSettings"

PsychopatzCore.UI = PsychopatzCore.UI or {}

local Theme = PsychopatzCore.UI.Theme or {}
PsychopatzCore.UI.Theme = Theme

local ThemeStore = PsychopatzCore.Settings.Open("UI", {
    fileName = "PsychopatzCore_UI.txt",
    defaults = { themePreset = "cyan" },
})

Theme.DefaultPreset = "cyan"
Theme.presets = {
    { id = "cyan", title = "Cyan", titleKey = "UI_PsychopatzCore_Theme_Cyan",
        color = { r = 0.2, g = 0.72, b = 0.82 } },
    { id = "green", title = "Green", titleKey = "UI_PsychopatzCore_Theme_Green",
        color = { r = 0.28, g = 0.82, b = 0.48 } },
    { id = "amber", title = "Amber", titleKey = "UI_PsychopatzCore_Theme_Amber",
        color = { r = 0.95, g = 0.68, b = 0.22 } },
    { id = "purple", title = "Purple", titleKey = "UI_PsychopatzCore_Theme_Purple",
        color = { r = 0.68, g = 0.48, b = 0.95 } },
    { id = "red", title = "Red", titleKey = "UI_PsychopatzCore_Theme_Red",
        color = { r = 0.95, g = 0.38, b = 0.36 } },
}
Theme.revision = Theme.revision or 0

Theme.colors = {
    window = { r = 0.035, g = 0.043, b = 0.052, a = 0.97 },
    surface = { r = 0.065, g = 0.078, b = 0.092, a = 0.98 },
    surfaceRaised = { r = 0.09, g = 0.108, b = 0.125, a = 0.98 },
    surfaceHover = { r = 0.12, g = 0.145, b = 0.17, a = 1 },
    border = { r = 0.23, g = 0.28, b = 0.32, a = 0.9 },
    borderStrong = { r = 0.38, g = 0.47, b = 0.54, a = 1 },
    text = { r = 0.91, g = 0.94, b = 0.96, a = 1 },
    textMuted = { r = 0.58, g = 0.65, b = 0.7, a = 1 },
    accent = { r = 0.2, g = 0.72, b = 0.82, a = 1 },
    accentDark = { r = 0.08, g = 0.31, b = 0.38, a = 1 },
    success = { r = 0.39, g = 0.78, b = 0.48, a = 1 },
    warning = { r = 0.94, g = 0.7, b = 0.27, a = 1 },
    danger = { r = 0.94, g = 0.36, b = 0.31, a = 1 },
    transparent = { r = 0, g = 0, b = 0, a = 0 },
}

Theme.metrics = {
    baselineWidth = 1920,
    baselineHeight = 1080,
    minimumScale = 0.78,
    maximumScale = 1.25,
    screenMargin = 18,
    spacing = 8,
    padding = 12,
    controlHeight = 26,
    compactBreakpoint = 760,
}

local function copyColor(color, alpha)
    color = color or Theme.colors.text
    return {
        r = color.r or 1,
        g = color.g or 1,
        b = color.b or 1,
        a = alpha == nil and (color.a or 1) or alpha,
    }
end

local function ensureLoaded()
    if ThemeStore.loaded then return end
    ThemeStore:Load()
end

local function presetFor(id)
    id = tostring(id or ""):lower()
    for _, preset in ipairs(Theme.presets) do
        if preset.id == id then return preset end
    end
    return nil
end

local function setColor(target, source)
    target.r = source.r
    target.g = source.g
    target.b = source.b
    target.a = source.a or target.a or 1
end

local function applyPreset(id, notify)
    local preset = presetFor(id) or presetFor(Theme.DefaultPreset)
    if not preset then return false end
    local accent = preset.color
    setColor(Theme.colors.accent, {
        r = accent.r, g = accent.g, b = accent.b, a = 1,
    })
    setColor(Theme.colors.accentDark, {
        r = accent.r * 0.42,
        g = accent.g * 0.43,
        b = accent.b * 0.46,
        a = 1,
    })
    Theme.activePreset = preset.id
    if notify then Theme.revision = Theme.revision + 1 end
    return preset.id
end

function Theme.GetPresetID()
    ensureLoaded()
    local stored = tostring(ThemeStore:Get("themePreset", Theme.DefaultPreset)
        or Theme.DefaultPreset):lower()
    return presetFor(stored) and stored or Theme.DefaultPreset
end

function Theme.GetPresetLabel(id)
    local preset = presetFor(id or Theme.GetPresetID())
    if not preset then preset = presetFor(Theme.DefaultPreset) end
    local translated = preset.titleKey and getText and getText(preset.titleKey)
        or nil
    if translated and translated ~= "" and translated ~= preset.titleKey then
        return translated
    end
    return preset.title
end

function Theme.GetPresetIDs()
    local ids = {}
    for _, preset in ipairs(Theme.presets) do ids[#ids + 1] = preset.id end
    return ids
end

function Theme.SetPreset(id, persist)
    ensureLoaded()
    local preset = presetFor(id) or presetFor(Theme.DefaultPreset)
    if not preset then return nil end
    if persist ~= false then ThemeStore:Set("themePreset", preset.id, true)
    else ThemeStore:Set("themePreset", preset.id, false) end
    if Theme.activePreset ~= preset.id then applyPreset(preset.id, true) end
    return preset.id
end

function Theme.GetRevision()
    return Theme.revision or 0
end

function Theme.Reset()
    return Theme.SetPreset(Theme.DefaultPreset)
end

function Theme.CopyColor(color, alpha)
    return copyColor(color, alpha)
end

function Theme.Color(name, alpha)
    return copyColor(Theme.colors[name] or Theme.colors.text, alpha)
end

function Theme.Font(scale, emphasis)
    scale = tonumber(scale) or 1
    if emphasis == "title" then
        return scale >= 1.12 and UIFont.Large or UIFont.Medium
    end
    if emphasis == "body" and scale >= 1.15 then
        return UIFont.Medium
    end
    return UIFont.Small
end

function Theme.FontHeight(font)
    if getTextManager and getTextManager() and getTextManager().getFontHeight then
        return getTextManager():getFontHeight(font or UIFont.Small)
    end
    return 14
end

function Theme.TextWidth(font, value)
    if getTextManager and getTextManager() and getTextManager().MeasureStringX then
        return getTextManager():MeasureStringX(font or UIFont.Small, tostring(value or ""))
    end
    return #tostring(value or "") * 7
end

ensureLoaded()
applyPreset(Theme.GetPresetID(), false)

return Theme
