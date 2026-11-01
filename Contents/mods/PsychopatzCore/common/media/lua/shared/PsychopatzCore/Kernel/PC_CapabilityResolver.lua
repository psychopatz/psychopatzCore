-- PsychopatzCore Capability Resolver
-- Resolves transitive dependency closures, detects cycles, and enforces runtime-role eligibility.

local Contract = require "PsychopatzCore/Kernel/PC_CapabilityContract"

local Resolver = {}

local function getCurrentRoles()
    local RuntimeRole = PsychopatzCore and PsychopatzCore.RuntimeRole
    local roles = { shared = true }

    if RuntimeRole and type(RuntimeRole.AllowsClientCode) == "function" then
        if RuntimeRole.AllowsClientCode() then
            roles.client = true
        end
        if RuntimeRole.IsServer and RuntimeRole.IsServer() then
            roles.server = true
        end
    else
        -- Fallback using PZ engine globals if RuntimeRole not yet loaded
        local client = (type(isClient) == "function" and isClient())
        local server = (type(isServer) == "function" and isServer())
        if client then
            roles.client = true
        end
        if server then
            roles.server = true
        end
        if not client and not server then
            -- Single-player / local test role: can act as client and local server
            roles.client = true
            roles.server = true
        end
    end
    return roles
end

function Resolver.IsRoleEligible(desc, currentRoles)
    currentRoles = currentRoles or getCurrentRoles()
    if not desc.roles then
        -- Default: shared is eligible everywhere
        return true
    end

    for role, required in pairs(desc.roles) do
        if required and currentRoles[role] then
            return true
        end
    end
    return false
end

function Resolver.ResolveClosure(registry, requestedIds, currentRoles)
    currentRoles = currentRoles or getCurrentRoles()

    if type(requestedIds) == "string" then
        requestedIds = { requestedIds }
    end

    local ordered = {}
    local visited = {}   -- permanent mark (1 = resolving/in stack, 2 = resolved)
    local path = {}

    local function visit(id)
        if visited[id] == 1 then
            -- Cycle detected! Build readable cycle path
            local cycleIndex = 1
            for idx, p in ipairs(path) do
                if p == id then
                    cycleIndex = idx
                    break
                end
            end
            local cycleStr = table.concat(path, " -> ", cycleIndex) .. " -> " .. id
            return false, "Dependency cycle detected: " .. cycleStr
        end

        if visited[id] == 2 then
            return true, nil
        end

        local desc = registry.Get(id)
        if not desc then
            return false, "Unknown capability: '" .. tostring(id) .. "'"
        end

        -- Check role eligibility
        if not Resolver.IsRoleEligible(desc, currentRoles) then
            return false, "Capability '" .. id .. "' is not eligible for current runtime role"
        end

        visited[id] = 1
        table.insert(path, id)

        if desc.depends then
            for _, depId in ipairs(desc.depends) do
                local ok, err = visit(depId)
                if not ok then
                    return false, err
                end
            end
        end

        table.remove(path)
        visited[id] = 2
        table.insert(ordered, id)
        return true, nil
    end

    for _, reqId in ipairs(requestedIds) do
        local ok, err = visit(reqId)
        if not ok then
            return nil, err
        end
    end

    return ordered, nil
end

function Resolver.ResolvePackClosure(registry, packId, currentRoles)
    currentRoles = currentRoles or getCurrentRoles()
    local pack = registry.GetPack(packId)
    if not pack then
        return nil, "unknown capability pack: " .. tostring(packId)
    end

    local eligibleIds = {}
    for _, capId in ipairs(pack.capabilities) do
        local desc = registry.Get(capId)
        if desc and Resolver.IsRoleEligible(desc, currentRoles) then
            table.insert(eligibleIds, capId)
        end
    end

    return Resolver.ResolveClosure(registry, eligibleIds, currentRoles)
end

return Resolver
