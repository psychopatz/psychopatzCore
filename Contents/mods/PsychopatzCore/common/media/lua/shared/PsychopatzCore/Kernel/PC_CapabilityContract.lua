-- PsychopatzCore Capability Contract and Validation Specification
-- Defines descriptor schema, role constraints, and validation helpers.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Kernel = PsychopatzCore.Kernel or {}

local CapabilityContract = {}
PsychopatzCore.Kernel.CapabilityContract = CapabilityContract

CapabilityContract.VALID_ROLES = {
    shared = true,
    client = true,
    server = true,
}

CapabilityContract.STATES = {
    UNREGISTERED = "UNREGISTERED",
    REGISTERED = "REGISTERED",
    RESOLVED = "RESOLVED",
    LOADED = "LOADED",
    ACTIVE = "ACTIVE",
    DORMANT = "DORMANT",
    FAILED = "FAILED",
}

function CapabilityContract.ValidateDescriptor(desc)
    if type(desc) ~= "table" then
        return false, "descriptor must be a table"
    end

    if type(desc.id) ~= "string" or desc.id:match("^%s*$") then
        return false, "descriptor id must be a non-empty string"
    end

    if desc.roles ~= nil then
        if type(desc.roles) ~= "table" then
            return false, "roles must be a table of role flags"
        end
        local has_valid_role = false
        for role, enabled in pairs(desc.roles) do
            if not CapabilityContract.VALID_ROLES[role] then
                return false, "invalid role: " .. tostring(role)
            end
            if enabled then
                has_valid_role = true
            end
        end
        if not has_valid_role then
            return false, "descriptor must declare at least one enabled role"
        end
    end

    if desc.depends ~= nil then
        if type(desc.depends) ~= "table" then
            return false, "depends must be a list of capability ID strings"
        end
        for i, dep in ipairs(desc.depends) do
            if type(dep) ~= "string" or dep:match("^%s*$") then
                return false, "dependency at index " .. tostring(i) .. " must be a non-empty string"
            end
        end
    end

    if desc.load ~= nil and type(desc.load) ~= "function" then
        return false, "load must be a function if provided"
    end

    if desc.activate ~= nil and type(desc.activate) ~= "function" then
        return false, "activate must be a function if provided"
    end

    if desc.deactivate ~= nil and type(desc.deactivate) ~= "function" then
        return false, "deactivate must be a function if provided"
    end

    return true, nil
end

function CapabilityContract.ValidatePack(pack)
    if type(pack) ~= "table" then
        return false, "pack must be a table"
    end

    if type(pack.id) ~= "string" or pack.id:match("^%s*$") then
        return false, "pack id must be a non-empty string"
    end

    if type(pack.capabilities) ~= "table" or #pack.capabilities == 0 then
        return false, "pack capabilities must be a non-empty list of capability IDs"
    end

    for i, capId in ipairs(pack.capabilities) do
        if type(capId) ~= "string" or capId:match("^%s*$") then
            return false, "pack capability at index " .. tostring(i) .. " must be a non-empty string"
        end
    end

    return true, nil
end

return CapabilityContract
