local Palette = {}

function Palette.Create()
    return {
        defaultPreset = "cyan",
        presets = {
            { id = "cyan", title = "Cyan",
                titleKey = "UI_PsychopatzCore_Theme_Cyan",
                color = { r = 0.2, g = 0.72, b = 0.82 } },
            { id = "green", title = "Green",
                titleKey = "UI_PsychopatzCore_Theme_Green",
                color = { r = 0.28, g = 0.82, b = 0.48 } },
            { id = "amber", title = "Amber",
                titleKey = "UI_PsychopatzCore_Theme_Amber",
                color = { r = 0.95, g = 0.68, b = 0.22 } },
            { id = "purple", title = "Purple",
                titleKey = "UI_PsychopatzCore_Theme_Purple",
                color = { r = 0.68, g = 0.48, b = 0.95 } },
            { id = "red", title = "Red",
                titleKey = "UI_PsychopatzCore_Theme_Red",
                color = { r = 0.95, g = 0.38, b = 0.36 } },
        },
        colors = {
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
        },
        metrics = {
            baselineWidth = 1920,
            baselineHeight = 1080,
            minimumScale = 0.78,
            maximumScale = 1.25,
            screenMargin = 18,
            spacing = 8,
            padding = 12,
            controlHeight = 26,
            compactBreakpoint = 760,
        },
    }
end

return Palette
