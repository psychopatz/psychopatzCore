-- Provider-neutral discovery and actor inspection controls.
-- Core owns the map toolbar and scoped Debug Hub surfaces; adopters contribute
-- only provider-specific map-debug tools.

local Host = require "PsychopatzCore/UI/Map/PsychopatzMapHost"
local Menu = require "PsychopatzCore/UI/Map/PsychopatzMapToolsMenu"
local DebugMenu = require "PsychopatzCore/UI/Map/PsychopatzMapDebugMenu"
local MarkerDiagnostics = require
    "PsychopatzCore/UI/Map/PsychopatzMapMarkerDiagnostics"
local MarkerDiagnosticsWindow
local ActorMap
local CorridorMap
local Hub = require "PsychopatzCore/UI/PsychopatzDebugHubRegistry"
local Client = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldClient"
local Presence = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldPresence"

local function tr(key, fallback)
    local translation = PsychopatzCore and PsychopatzCore.Translation
    if translation and type(translation.GetKey) == "function" then
        local value = translation.GetKey(key, fallback)
        if type(value) == "string" and value ~= "" then
            return value
        end
    end
    return fallback or key
end

local function player()
    if type(getSpecificPlayer) == "function" then
        return getSpecificPlayer(0)
    end
    if type(getPlayer) == "function" then return getPlayer() end
    return nil
end

local function canUseDebug()
    local authority = PsychopatzCore and PsychopatzCore.Debug
    if not authority or type(authority.CanUse) ~= "function" then
        return false
    end
    local current = player()
    return current ~= nil and authority.CanUse(current) == true
end

local function selectedActorID()
    local selection = Client and Client.Selection
    local value = selection and selection.selectedActorID
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function trackedActorID()
    local selection = Client and Client.Selection
    local value = selection and selection.trackedActorID
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function presenceActorID()
    return selectedActorID() or trackedActorID()
end

local function presenceDebugAvailable()
    return canUseDebug()
        and Presence.IsOverrideEnabled()
        and presenceActorID() ~= nil
end

local function discoveryAction(action, args)
    if not Client or type(Client.DiscoveryAction) ~= "function" then
        return false, "core_discovery_unavailable"
    end
    return Client.DiscoveryAction(action, args or {})
end

MarkerDiagnostics.RegisterSource("PsychopatzCore:SurvivorWorldActors", {
    kind = "actor",
    priority = 100,
    list = function()
        ActorMap = ActorMap or require
            "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldActorMap"
        return ActorMap.ListDiagnostics()
    end,
})

MarkerDiagnostics.RegisterSource("PsychopatzCore:SurvivorWorldCorridors", {
    kind = "corridor",
    priority = 85,
    list = function()
        CorridorMap = CorridorMap or require
            "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldCorridorMap"
        return CorridorMap.ListDiagnostics and CorridorMap.ListDiagnostics() or {}
    end,
})

local function registerDebug(id, titleKey, titleFallback, helpKey,
    helpFallback, order, action, menuTitle, menuTooltip, available)
    local definition = {
        id = "psychopatz.map." .. id,
        title = tr(titleKey, titleFallback),
        description = tr(helpKey, helpFallback),
        source = "Map Tools",
        surface = "map",
        order = order,
        available = available or canUseDebug,
        action = action,
    }
    if menuTitle then definition.menuTitle = menuTitle end
    if menuTooltip then definition.menuTooltip = menuTooltip end
    return Hub.RegisterTool(definition)
end

registerDebug(
    "actor_debug_presentation",
    "UI_PsychopatzMapTools_ActorDebugOn",
    "Toggle survivor overlay diagnostics",
    "UI_PsychopatzMapTools_ActorDebugHelp",
    "Show routes and undiscovered overlays. Portraits require learned identity.",
    10,
    function()
        return Client.SetDebugPresentationEnabled(
            not Client.IsDebugPresentationEnabled())
    end,
    function()
        local state = Client.IsDebugPresentationEnabled()
        return tr("UI_PsychopatzMapTools_DebugLabel", "SURVIVOR OVERLAYS")
            .. (state and ": ON" or ": OFF")
    end,
    function()
        return tr("UI_PsychopatzMapTools_ActorDebugHelp",
            "Toggle survivor routes and undiscovered overlays.")
    end
)

registerDebug(
    "corridor_graph",
    "UI_PsychopatzMapTools_CorridorGraph_Title",
    "Toggle corridor graph & aftermath overlay",
    "UI_PsychopatzMapTools_CorridorGraph_Help",
    "Show or hide MetaGrid road corridor nodes, settlement hubs, and off-camera SOS/aftermath markers.",
    11,
    function()
        CorridorMap = CorridorMap or require
            "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldCorridorMap"
        return CorridorMap.SetEnabled(not CorridorMap.IsEnabled())
    end,
    function()
        CorridorMap = CorridorMap or require
            "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldCorridorMap"
        local state = CorridorMap.IsEnabled()
        return tr("UI_PsychopatzMapTools_CorridorGraph_Label", "CORRIDOR GRAPH")
            .. (state and ": ON" or ": OFF")
    end,
    function()
        return tr("UI_PsychopatzMapTools_CorridorGraph_Help",
            "Toggle MetaGrid street nodes, edges, settlement hubs, and aftermath markers.")
    end
)

registerDebug(
    "actor_presence_override",
    "UI_PsychopatzMapTools_PresenceOverride_Title",
    "Force selected survivor live",
    "UI_PsychopatzMapTools_PresenceOverride_Help",
    "Materialize or release the selected survivor's debug body.",
    12,
    function()
        local id = presenceActorID()
        if not id then return false, "actor_required" end
        local entry = Client.GetActor(id)
        local state = entry and tostring(entry.providerState or "") or ""
        local action = state == "materialized" and "force_abstract"
            or "force_live"
        return Client.RequestPresenceDebug(action, id)
    end,
    function()
        local id = presenceActorID()
        local entry = id and Client.GetActor(id) or nil
        local state = entry and tostring(entry.providerState or "") or ""
        return tr("UI_PsychopatzMapTools_PresenceOverride_Label",
            "SURVIVOR BODY OVERRIDE")
            .. (state == "materialized" and ": RELEASE" or ": FORCE LIVE")
    end,
    function()
        return tr("UI_PsychopatzMapTools_PresenceOverride_Help",
            "Materialize the selected Core actor through its provider, or release its debug body.")
    end,
    presenceDebugAvailable
)

registerDebug(
    "marker_diagnostics",
    "UI_PsychopatzMapTools_MarkerDiagnostics_Title",
    "Map marker diagnostics",
    "UI_PsychopatzMapTools_MarkerDiagnostics_Help",
    "Inspect survivor, group, discovery, and settlement markers.",
    15,
    function()
        MarkerDiagnostics.SetEnabled(
            not MarkerDiagnostics.IsEnabled())
        if MarkerDiagnostics.IsEnabled() then
            MarkerDiagnosticsWindow = MarkerDiagnosticsWindow
                or require
                    "PsychopatzCore/UI/Map/PsychopatzMapMarkerDiagnostics_UI"
            MarkerDiagnosticsWindow.Open()
        elseif MarkerDiagnosticsWindow then
            MarkerDiagnosticsWindow.Close()
        end
        return true
    end,
    function()
        return tr("UI_PsychopatzMapTools_MarkerDiagnostics_Label",
            "MARKER DIAGNOSTICS")
            .. (MarkerDiagnostics.IsEnabled() and ": ON" or ": OFF")
    end,
    function()
        return tr("UI_PsychopatzMapTools_MarkerDiagnostics_Help",
            "Inspect shared marker presence and provider state.")
    end
)

registerDebug(
    "discovery_refresh",
    "UI_PsychopatzMapTools_DiscoveryRefresh_Title",
    "Refresh survivor discovery",
    "UI_PsychopatzMapTools_DiscoveryRefresh_Help",
    "Request the latest Core survivor-world discovery snapshot.",
    20,
    function()
        if not Client or type(Client.RequestDiscovery) ~= "function" then
            return false, "core_discovery_unavailable"
        end
        return Client.RequestDiscovery()
    end
)

registerDebug(
    "discovery_all",
    "UI_PsychopatzMapTools_DiscoveryAll_Title",
    "Reveal all survivor-world entities",
    "UI_PsychopatzMapTools_DiscoveryAll_Help",
    "Reveal every Core survivor-world signal, group, and community.",
    40,
    function()
        return discoveryAction("debug_discover_all", { scope = "all" })
    end
)

registerDebug(
    "discovery_reset",
    "UI_PsychopatzMapTools_DiscoveryReset_Title",
    "Reset survivor discovery",
    "UI_PsychopatzMapTools_DiscoveryReset_Help",
    "Clear this player's Core survivor-world discovery state.",
    70,
    function() return discoveryAction("debug_reset", {}) end
)

if Host and Host.Tools and Host.Tools.Register then
    Host.Tools.Register("PsychopatzCore:track_selected", {
        order = 40,
        field = "psychopatzTrackSelectedButton",
        width = 120,
        visible = function()
            return selectedActorID() ~= nil or trackedActorID() ~= nil
        end,
        title = function()
            return trackedActorID() ~= nil
                and tr("UI_PsychopatzMapTools_TrackingStop_Title",
                    "Stop tracking survivor")
                or tr("UI_PsychopatzMapTools_TrackingStart_Title",
                    "Track selected survivor")
        end,
        tooltip = function()
            return trackedActorID() ~= nil
                and tr("UI_PsychopatzMapTools_TrackingStop_Help",
                    "Clear the current Core survivor tracking target.")
                or tr("UI_PsychopatzMapTools_TrackingStart_Help",
                    "Track the selected Core survivor actor.")
        end,
        onActivate = function()
            local current = trackedActorID()
            local target
            if not current then target = selectedActorID() end
            if not current and not target then return false end
            if not Client or type(Client.SetTracked) ~= "function" then
                return false, "core_tracking_unavailable"
            end
            return Client.SetTracked(target) ~= nil
        end,
    })

end

local function closeMapToolsMenu()
    if Menu.instance and type(Menu.instance.close) == "function" then
        Menu.instance:close()
    end
end

Menu.Register("PsychopatzCore:map_debug", {
    order = 40,
    visible = canUseDebug,
    enabled = canUseDebug,
    title = function()
        return tr("UI_PsychopatzMapTools_DebugHub_Title", "Map Tools")
    end,
    tooltip = function()
        return tr("UI_PsychopatzMapTools_DebugHub_Help",
            "Open map tools.")
    end,
    onActivate = function(map)
        closeMapToolsMenu()
        return DebugMenu.Open(map) ~= nil
    end,
    onMapClose = function()
        DebugMenu.Close()
        if MarkerDiagnosticsWindow then MarkerDiagnosticsWindow.Close() end
        Hub.Close("map")
    end,
})

return Hub
