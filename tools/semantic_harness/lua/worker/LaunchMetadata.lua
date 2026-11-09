-- Provider-neutral worker launch metadata.
--
-- Adopter workers may use this module to advertise the same validated launch
-- selection that Core's Python client sent through SEMANTIC_HARNESS_*.

local LaunchMetadata = {}

local function environment(name)
    if os and type(os.getenv) == "function" then
        return os.getenv(name)
    end
    return nil
end

local function providerIDs(defaults)
    local value = environment("SEMANTIC_HARNESS_PROVIDER_IDS")
    if not value or value == "" then return defaults end
    local result = {}
    for providerID in string.gmatch(value, "[^,]+") do
        providerID = string.gsub(providerID, "^%s+", "")
        providerID = string.gsub(providerID, "%s+$", "")
        if providerID ~= "" then result[#result + 1] = providerID end
    end
    if #result == 0 then return defaults end
    return result
end

function LaunchMetadata.read(defaults)
    defaults = type(defaults) == "table" and defaults or {}
    return {
        profile = tostring(
            environment("SEMANTIC_HARNESS_PROFILE")
                or defaults.profile
                or "core"
        ),
        providers = providerIDs(defaults.providers or { "PsychopatzCore" }),
        materializationMode = tostring(
            environment("SEMANTIC_HARNESS_MATERIALIZATION_MODE")
                or defaults.materializationMode
                or "none"
        ):lower(),
    }
end

return LaunchMetadata
