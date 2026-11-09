-- Provider-neutral discovery, actor-tracking, and Debug Hub actions exposed
-- through the shared map-tools surface.

local Menu = require "PsychopatzCore/UI/Map/PsychopatzMapToolsMenu"
local Client = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldClient"

local function tr(key, fallback)
    local translation = PsychopatzCore and PsychopatzCore.Translation
    if translation and type(translation.GetKey) == "function" then
        local ok, value = pcall(translation.GetKey, key, fallback)
        if ok and type(value) == "string" and value ~= "" then
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

local function closeMenu()
    if Menu and type(Menu.Close) == "function" then Menu.Close() end
end

local function discoveryAction(action, args)
    if not Client or type(Client.DiscoveryAction) ~= "function" then
        return false, "core_discovery_unavailable"
    end
    return Client.DiscoveryAction(action, args or {})
end

local function register(id, definition)
    Menu.Register("PsychopatzCore:" .. id, definition)
end

register("actor_debug_presentation", {
    order = 39,
    visible = canUseDebug,
    title = function()
        return Client.IsDebugPresentationEnabled()
            and tr("UI_PsychopatzMapTools_ActorDebugOff", "Hide survivor debug inspection")
            or tr("UI_PsychopatzMapTools_ActorDebugOn", "Show survivor debug inspection")
    end,
    tooltip = function()
        return tr("UI_PsychopatzMapTools_ActorDebugHelp",
            "Show routes and undiscovered overlays. Portraits require learned identity.")
    end,
    onActivate = function()
        return Client.SetDebugPresentationEnabled(not Client.IsDebugPresentationEnabled())
    end,
})

register("discovery_refresh", {
    order = 10,
    title = function()
        return tr("UI_PsychopatzMapTools_DiscoveryRefresh_Title",
            "Refresh survivor discovery")
    end,
    tooltip = function()
        return tr("UI_PsychopatzMapTools_DiscoveryRefresh_Help",
            "Request the latest Core survivor-world discovery snapshot.")
    end,
    onActivate = function()
        if not Client or type(Client.RequestDiscovery) ~= "function" then
            return false, "core_discovery_unavailable"
        end
        return Client.RequestDiscovery()
    end,
})

register("discovery_all_signals", {
    order = 21,
    visible = canUseDebug,
    title = function()
        return tr("UI_PsychopatzMapTools_DiscoverySignals_Title",
            "Discover all signals")
    end,
    tooltip = function()
        return tr("UI_PsychopatzMapTools_DiscoverySignals_Help",
            "Reveal every Core survivor-world signal to this player.")
    end,
    onActivate = function()
        return discoveryAction("debug_discover_all", { scope = "signals" })
    end,
})

register("discovery_all", {
    order = 20,
    visible = canUseDebug,
    title = function()
        return tr("UI_PsychopatzMapTools_DiscoveryAll_Title",
            "Discover all survivor-world entities")
    end,
    tooltip = function()
        return tr("UI_PsychopatzMapTools_DiscoveryAll_Help",
            "Reveal every Core survivor-world signal, group, and community.")
    end,
    onActivate = function()
        return discoveryAction("debug_discover_all", { scope = "all" })
    end,
})

register("discovery_all_groups", {
    order = 22,
    visible = canUseDebug,
    title = function()
        return tr("UI_PsychopatzMapTools_DiscoveryGroups_Title",
            "Discover all mobile groups")
    end,
    tooltip = function()
        return tr("UI_PsychopatzMapTools_DiscoveryGroups_Help",
            "Reveal every Core survivor-world mobile group.")
    end,
    onActivate = function()
        return discoveryAction(
            "debug_discover_all", { scope = "mobile_groups" }
        )
    end,
})

register("discovery_all_communities", {
    order = 23,
    visible = canUseDebug,
    title = function()
        return tr("UI_PsychopatzMapTools_DiscoveryCommunities_Title",
            "Discover all communities")
    end,
    tooltip = function()
        return tr("UI_PsychopatzMapTools_DiscoveryCommunities_Help",
            "Reveal every Core survivor-world community.")
    end,
    onActivate = function()
        return discoveryAction(
            "debug_discover_all", { scope = "settlements" }
        )
    end,
})

register("discovery_reset", {
    order = 24,
    visible = canUseDebug,
    title = function()
        return tr("UI_PsychopatzMapTools_DiscoveryReset_Title",
            "Reset discovery")
    end,
    tooltip = function()
        return tr("UI_PsychopatzMapTools_DiscoveryReset_Help",
            "Clear this player's Core survivor-world discovery state.")
    end,
    onActivate = function()
        return discoveryAction("debug_reset", {})
    end,
})

register("track_selected", {
    order = 40,
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

register("debug_hub", {
    order = 90,
    visible = canUseDebug,
    title = function()
        return tr("UI_PsychopatzMapTools_DebugHub_Title", "Debug Hub")
    end,
    tooltip = function()
        return tr("UI_PsychopatzMapTools_DebugHub_Help",
            "Open the shared Psychopatz Debug Hub.")
    end,
    onActivate = function()
        closeMenu()
        local hub = PsychopatzCore and PsychopatzCore.DebugHub
        if not hub or type(hub.Open) ~= "function" then
            local ok, loaded = pcall(require,
                "PsychopatzCore/UI/PsychopatzDebugHubWindow")
            if not ok then return false, tostring(loaded) end
            hub = PsychopatzCore and PsychopatzCore.DebugHub
        end
        return hub and type(hub.Open) == "function"
            and hub.Open() ~= nil
    end,
})

return Menu
