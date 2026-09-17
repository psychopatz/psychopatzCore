-- Public façade for the client preview framework.
--
-- Registry and snapshot validation load cheaply. The world renderer and its
-- ISUI drawer are lazy-loaded only when a caller first needs a session.
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Preview = PsychopatzCore.Preview or {}

local Preview = PsychopatzCore.Preview
local Registry = Preview.Registry
    or require "PsychopatzCore/Preview/PC_PreviewRegistry"
local Snapshot = Preview.Snapshot
    or require "PsychopatzCore/Preview/PC_PreviewSnapshot"
local Overlay

Preview.VERSION = 1

local function engine()
    if not Overlay then
        Overlay = require "PsychopatzCore/Preview/PC_PreviewOverlay"
    end
    return Overlay
end

function Preview.RegisterProvider(definition)
    return Registry.Register(definition)
end

function Preview.UnregisterProvider(id)
    if Overlay then Overlay.RemoveSession(id) end
    return Registry.Unregister(id)
end

function Preview.GetProvider(id)
    return Registry.Get(id)
end

function Preview.ListProviders()
    return Registry.List()
end

function Preview.RegisterLayer(providerID, layer)
    local provider = Registry.Get(providerID)
    if not provider or type(layer) ~= "table" then
        return false, "provider_or_layer_required"
    end
    for index = 1, #provider.layers do
        if provider.layers[index].id == layer.id then
            return false, "duplicate_layer_id"
        end
    end
    local definition = {}
    for key, value in pairs(provider) do
        if key ~= "layers" then definition[key] = value end
    end
    definition.layers = {}
    for index = 1, #provider.layers do
        definition.layers[#definition.layers + 1] = provider.layers[index]
    end
    definition.layers[#definition.layers + 1] = layer
    local ok, replacement = Registry.Register(definition)
    if ok and Overlay then Overlay.RegisterSession(providerID) end
    return ok, replacement
end

function Preview.SetSnapshot(providerID, snapshot)
    return engine().SetSnapshot(providerID, snapshot)
end

function Preview.Refresh(providerID, options)
    local provider = Registry.Get(providerID)
    local callback = provider and provider.refreshSnapshot or nil
    if type(callback) ~= "function" then
        return nil, "provider_refresh_unavailable"
    end
    local ok, snapshot = pcall(callback, options or {})
    if not ok then return nil, snapshot end
    if snapshot == nil then return nil, "provider_refresh_empty" end
    return Preview.SetSnapshot(providerID, snapshot)
end

function Preview.GetSnapshot(providerID)
    if not Overlay then return nil end
    return Overlay.GetSnapshot(providerID)
end

function Preview.SetSettings(providerID, settings, revision)
    return engine().SetSettings(providerID, settings, revision)
end

function Preview.SetEnabled(providerID, enabled)
    return engine().SetEnabled(providerID, enabled)
end

function Preview.Toggle(providerID)
    local current = false
    if Overlay then current = Overlay.IsEnabled(providerID) end
    return Preview.SetEnabled(providerID, not current)
end

function Preview.IsEnabled(providerID)
    return Overlay and Overlay.IsEnabled(providerID) or false
end

function Preview.IsHookInstalled()
    return Overlay and Overlay.IsHookInstalled
        and Overlay.IsHookInstalled() or false
end

function Preview.Clear(providerID)
    if not Overlay then return false end
    return Overlay.Clear(providerID)
end

function Preview.HasRenderableLayers(providerID, settings)
    if not Overlay then
        local provider = Registry.Get(providerID)
        return Registry.HasRenderableLayers(provider, settings)
    end
    return Overlay.HasRenderableLayers(providerID, settings)
end

function Preview.SyncRenderHook()
    if not Overlay then return true end
    return Overlay.SyncRenderHook()
end

function Preview.Render()
    return engine().Render()
end

function Preview.GetSession(providerID)
    if not Overlay then return nil end
    return Overlay.GetSession(providerID)
end

function Preview.GetVisibleObjects(providerID)
    if not Overlay then return {} end
    return Overlay.GetVisibleObjects(providerID)
end

function Preview.NormalizeSnapshot(snapshot, providerID)
    return Snapshot.Normalize(snapshot, providerID)
end

return Preview
