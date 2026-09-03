local Integration = {}

function Integration.Register()
    local Bridge = PsychopatzCore and PsychopatzCore.Bridge
    local Bootstrap = PsychopatzCore and PsychopatzCore.ProfilerBootstrap
    if not Bridge or not Bridge.RegisterCommand or not Bootstrap then return false end
    return Bridge.RegisterCommand("psychopatzcore.profiler", "configure", {
        readOnly = false, category = "MUTATION",
        handler = function(_, arguments)
            if type(arguments) ~= "table" then
                return nil, "INVALID_ARGUMENTS", "Profiler configuration must be an object."
            end
            local result, reason = Bootstrap.ApplyCaptureConfig(arguments)
            if not result then return nil, "INVALID_ARGUMENTS", reason end
            return result
        end,
    })
end

return Integration
