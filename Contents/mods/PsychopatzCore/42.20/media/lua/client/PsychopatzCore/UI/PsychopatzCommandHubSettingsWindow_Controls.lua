local Window = ISPsychopatzCommandHubSettingsWindow
local Internal = Window.Internal
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Options = UI.CommandHubOptions

local tr = Internal.tr
local label = Internal.label
local branchTitle = Internal.branchTitle
local opacityText = Internal.opacityText
local liftText = Internal.liftText
local controlScaleText = Internal.controlScaleText
local themeTitle = Internal.themeTitle

function Internal.createOpacityRow(window)
    local row = UI.CreateFormRow(window, {
        id = "command-hub-setting-row:opacity",
        label = tr("UI_PsychopatzCore_CommandHub_Settings_Opacity", "Opacity"),
        valueLabel = true,
        valueText = opacityText(Options.GetOpacityPercent()),
        createControl = function(parent)
            return UI.CreateSlider(parent, {
                id = "psychopatz-command-hub-opacity",
                target = window,
                min = 10,
                max = 100,
                step = 1,
                value = Options.GetOpacityPercent(),
                onChange = function(_, value)
                    if window.opacityValue then
                        UI.SetLabelText(window.opacityValue, opacityText(value))
                    end
                end,
            })
        end,
    })
    window.opacityRow = row
    window.opacityLabel = row.label
    window.opacitySlider = row.control
    window.opacityValue = row.valueLabel
end

function Internal.createLiftField(window, id, labelKey, fallback, value)
    local row
    row = UI.CreateFormRow(window, {
        id = id,
        label = tr(labelKey, fallback),
        valueLabel = true,
        valueText = liftText(value),
        createControl = function(parent)
            return UI.CreateSlider(parent, {
                id = id .. ":slider",
                target = window,
                min = 0,
                max = 25,
                step = 1,
                value = value,
                onChange = function(_, nextValue)
                    UI.SetLabelText(row.valueLabel, liftText(nextValue))
                end,
            })
        end,
    })
    return row
end

function Internal.createTitlebarScaleRow(window)
    local row
    row = UI.CreateFormRow(window, {
        id = "command-hub-setting-row:titlebar-scale",
        label = tr("UI_PsychopatzCore_CommandHub_Settings_TitlebarScale",
            "Title-bar control size"),
        valueLabel = true,
        valueText = controlScaleText(
            Options.GetTitlebarControlScale() * 100),
        createControl = function(parent)
            return UI.CreateSlider(parent, {
                id = "psychopatz-command-hub-titlebar-scale",
                target = window,
                min = 50,
                max = 125,
                step = 1,
                value = Options.GetTitlebarControlScale() * 100,
                onChange = function(_, value)
                    UI.SetLabelText(row.valueLabel, controlScaleText(value))
                end,
            })
        end,
    })
    return row
end

function Internal.createActionControls(window)
    window.helpLabel = label(window,
        tr("UI_PsychopatzCore_CommandHub_Settings_Help",
            "Adjust opacity, child surface lifts, title-bar controls, theme, and panel side here."),
        Theme.colors.textMuted)
    window.themeButton = UI.CreateButton(window, {
        id = "theme", title = themeTitle(), target = window,
        onclick = function() return window:onThemeCycle() end,
        variant = "quiet",
    })
    window.branchButton = UI.CreateButton(window, {
        id = "branch", title = branchTitle(), target = window,
        onclick = function() return window:onBranchToggle() end,
        variant = "quiet",
    })
    window.statusLabel = label(window, "", Theme.colors.textMuted)
    window.resetButton = UI.CreateButton(window, {
        id = "reset",
        title = tr("UI_PsychopatzCore_CommandHub_Settings_Reset", "RESET"),
        target = window, onclick = function() return window:onReset() end,
        variant = "quiet",
    })
    window.closeButton = UI.CreateButton(window, {
        id = "close",
        title = tr("UI_PsychopatzCore_CommandHub_Settings_Close", "CLOSE"),
        target = window, onclick = function() return window:close() end,
        variant = "quiet",
    })
    window.applyButton = UI.CreateButton(window, {
        id = "apply",
        title = tr("UI_PsychopatzCore_CommandHub_Settings_Apply", "APPLY"),
        target = window, onclick = function() return window:onApply() end,
        variant = "primary",
    })
end

function Internal.installWidget(window)
    UI.WidgetWindow.Install(window, {
        id = "psychopatzcore-command-hub-settings-widget",
        onDetachedChanged = function()
            local hub = UI.CommandHub
            if hub and hub.Sync then hub.Sync() end
        end,
    })
end

function Internal.createChildren(window)
    PsychopatzWindow.createChildren(window)
    window.fields = {}

    Internal.createOpacityRow(window)
    window.surfaceLiftRow = Internal.createLiftField(
        window,
        "command-hub-setting-row:surface-lift",
        "UI_PsychopatzCore_CommandHub_Settings_SurfaceLift",
        "Surface opacity lift",
        Options.GetSurfaceOpacityLift() * 100)
    window.detailLiftRow = Internal.createLiftField(
        window,
        "command-hub-setting-row:detail-lift",
        "UI_PsychopatzCore_CommandHub_Settings_DetailLift",
        "Detail opacity lift",
        Options.GetDetailOpacityLift() * 100)
    window.titlebarScaleRow = Internal.createTitlebarScaleRow(window)
    Internal.createActionControls(window)

    window:populate()
    window:requestResponsiveLayout(true)
    Internal.installWidget(window)
end

return Internal
