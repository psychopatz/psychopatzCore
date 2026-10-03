local State = {}

function State.EnsureLoaded(store)
    if store.loaded then return end
    store:Load()
end

local function presetFor(theme, id)
    id = tostring(id or ""):lower()
    for _, preset in ipairs(theme.presets) do
        if preset.id == id then return preset end
    end
    return nil
end

function State.ApplyPreset(theme, id, notify)
    local preset = presetFor(theme, id) or presetFor(theme, theme.DefaultPreset)
    if not preset then return false end
    local accent = preset.color
    theme.colors.accent.r = accent.r
    theme.colors.accent.g = accent.g
    theme.colors.accent.b = accent.b
    theme.colors.accent.a = 1
    theme.colors.accentDark.r = accent.r * 0.42
    theme.colors.accentDark.g = accent.g * 0.43
    theme.colors.accentDark.b = accent.b * 0.46
    theme.colors.accentDark.a = 1
    theme.activePreset = preset.id
    if notify then theme.revision = theme.revision + 1 end
    return preset.id
end

function State.Install(theme, store, translation)
    function theme.GetPresetID()
        State.EnsureLoaded(store)
        local stored = tostring(store:Get(
            "themePreset", theme.DefaultPreset
        ) or theme.DefaultPreset):lower()
        return presetFor(theme, stored) and stored or theme.DefaultPreset
    end

    function theme.GetPresetLabel(id)
        local preset = presetFor(theme, id or theme.GetPresetID())
        if not preset then preset = presetFor(theme, theme.DefaultPreset) end
        local translated = preset.titleKey and translation
            and translation.GetKey(preset.titleKey, nil) or nil
        if not translated and preset.titleKey and getText then
            translated = getText(preset.titleKey)
        end
        if translated and translated ~= "" and translated ~= preset.titleKey then
            return translated
        end
        return preset.title
    end

    function theme.GetPresetIDs()
        local ids = {}
        for _, preset in ipairs(theme.presets) do ids[#ids + 1] = preset.id end
        return ids
    end

    function theme.SetPreset(id, persist)
        State.EnsureLoaded(store)
        local preset = presetFor(theme, id)
            or presetFor(theme, theme.DefaultPreset)
        if not preset then return nil end
        store:Set("themePreset", preset.id, persist ~= false)
        if theme.activePreset ~= preset.id then
            State.ApplyPreset(theme, preset.id, true)
        end
        return preset.id
    end

    function theme.GetRevision()
        return theme.revision or 0
    end

    function theme.Reset()
        return theme.SetPreset(theme.DefaultPreset)
    end
end

return State
