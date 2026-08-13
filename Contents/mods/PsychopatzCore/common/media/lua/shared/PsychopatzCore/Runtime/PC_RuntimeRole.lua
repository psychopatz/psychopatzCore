PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.RuntimeRole = PsychopatzCore.RuntimeRole or {}

local RuntimeRole = PsychopatzCore.RuntimeRole

function RuntimeRole.IsClient()
    return isClient and isClient() == true or false
end

function RuntimeRole.IsServer()
    return isServer and isServer() == true or false
end

function RuntimeRole.IsPureClient()
    return RuntimeRole.IsClient() and not RuntimeRole.IsServer()
end

function RuntimeRole.IsSinglePlayer()
    return not RuntimeRole.IsClient() and not RuntimeRole.IsServer()
end

function RuntimeRole.AllowsServerCode()
    return not RuntimeRole.IsPureClient()
end

function RuntimeRole.AllowsClientCode()
    return not (RuntimeRole.IsServer() and not RuntimeRole.IsClient())
end

return RuntimeRole
