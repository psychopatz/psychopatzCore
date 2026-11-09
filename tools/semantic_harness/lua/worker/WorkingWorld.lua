-- Provider-neutral source/working-world bookkeeping and patch projection.
--
-- This module owns only bounded state mechanics. Adopters remain responsible
-- for rehydrating provider records and deciding how a reset affects gameplay.

local WorkingWorld = {}

WorkingWorld.MAX_PATCHES = 512

local function sortedKeys(value)
    local keys = {}
    if type(value) ~= "table" then return keys end
    for key in pairs(value) do
        if type(key) == "string" or type(key) == "number" then
            keys[#keys + 1] = key
        end
    end
    table.sort(keys, function(left, right)
        return tostring(left) < tostring(right)
    end)
    return keys
end

local function collectPatches(imported, effective, path, patches, Values)
    if #patches >= WorkingWorld.MAX_PATCHES then return end
    if type(imported) == "table" and type(effective) == "table" then
        local keys = {}
        local seen = {}
        for _, key in ipairs(sortedKeys(imported)) do
            if not seen[key] then
                seen[key] = true
                keys[#keys + 1] = key
            end
        end
        for _, key in ipairs(sortedKeys(effective)) do
            if not seen[key] then
                seen[key] = true
                keys[#keys + 1] = key
            end
        end
        table.sort(keys, function(left, right)
            return tostring(left) < tostring(right)
        end)
        for _, key in ipairs(keys) do
            if #patches >= WorkingWorld.MAX_PATCHES then break end
            local keyText = tostring(key)
            local childPath = path == "" and keyText
                or path .. "." .. keyText
            collectPatches(
                imported[key], effective[key], childPath, patches, Values
            )
        end
        return
    end
    if imported == effective then return end
    patches[#patches + 1] = {
        path = path,
        imported = Values.copy(imported),
        effective = Values.copy(effective),
        source = "HARNESS_MUTATION",
    }
end

function WorkingWorld.baseline(runtime)
    runtime = type(runtime) == "table" and runtime or {}
    return runtime.sourceWorkingBaseline
        or runtime.sourceSnapshot
        or runtime.scenario
        or {}
end

function WorkingWorld.patches(runtime, Values)
    runtime = type(runtime) == "table" and runtime or {}
    Values = Values or require "worker/Values"
    local patches = {}
    collectPatches(
        WorkingWorld.baseline(runtime),
        runtime.scenario or {},
        "",
        patches,
        Values
    )
    local metadata = type(runtime.sourceMetadata) == "table"
        and runtime.sourceMetadata or {}
    local sourceKind = metadata.sourceKind or "MISSING"
    for _, patch in ipairs(patches) do
        patch.baseSource = sourceKind
    end
    return patches
end

function WorkingWorld.beginSourceImport(runtime)
    runtime.sourceWorkingBaseline = nil
    runtime.captureWorkingBaseline = true
    runtime.workingResetCount = 0
    runtime.workingWorldRevision = (runtime.workingWorldRevision or 0) + 1
end

function WorkingWorld.beginReset(runtime)
    runtime.workingWorldRevision = (runtime.workingWorldRevision or 0) + 1
end

function WorkingWorld.captureBaseline(runtime, Values)
    if runtime.captureWorkingBaseline ~= true then return false end
    Values = Values or require "worker/Values"
    runtime.sourceWorkingBaseline = Values.copy(runtime.scenario or {})
    runtime.captureWorkingBaseline = false
    return true
end

function WorkingWorld.incrementResetCount(runtime)
    runtime.workingResetCount = (runtime.workingResetCount or 0) + 1
    return runtime.workingResetCount
end

return WorkingWorld
