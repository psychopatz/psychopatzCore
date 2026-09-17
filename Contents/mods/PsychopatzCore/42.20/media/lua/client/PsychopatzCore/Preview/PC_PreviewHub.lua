-- Lazy public entry point for the generic Core preview dashboard.
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.PreviewHub = PsychopatzCore.PreviewHub or {}

local Hub = PsychopatzCore.PreviewHub

function Hub.Open(providerID)
    local Window = require "PsychopatzCore/Preview/PC_PreviewHubWindow"
    return Window.Open(providerID)
end

function Hub.Toggle(providerID)
    local Window = require "PsychopatzCore/Preview/PC_PreviewHubWindow"
    local instance = Window.instance
    if instance and instance:getIsVisible() then
        instance:close()
        return nil
    end
    return Window.Open(providerID)
end

return Hub
