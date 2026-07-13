require "PsychopatzCore/00_PsychopatzCore_Init"

PsychopatzCore.UI = PsychopatzCore.UI or {}

local Theme = PsychopatzCore.UI.Theme or {}
PsychopatzCore.UI.Theme = Theme

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

return Theme
