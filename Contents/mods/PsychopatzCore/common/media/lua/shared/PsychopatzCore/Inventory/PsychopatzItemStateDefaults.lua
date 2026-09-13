-- Definition-relative item state.
--
-- Item definitions are the immutable baseline.  This module keeps the
-- mutable part sparse: a missing field means "use the definition", while a
-- present zero or false remains an intentional override.

local Util = require "PsychopatzCore/Inventory/PsychopatzInventoryUtil"

local Defaults = {}
local EPSILON = 0.000001
local MAX_FLUIDS = 8

local provider
local providerRevision = 0
local cache = {}

local FLUID_FIELDS = {
    fluidAmount = true,
    fluidCapacity = true,
    fluidPrimaryType = true,
    fluidType = true,
    fluidInputLocked = true,
    fluidCanPlayerEmpty = true,
    fluidRainCatcher = true,
    fluids = true,
}

local function finite(value)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge
        or value == -math.huge
    then
        return nil
    end
    return value
end

local function copy(value)
    return Util.copy(value)
end

local function equal(left, right)
    local leftNumber
    local rightNumber
    local key
    if left == right then return true end
    leftNumber, rightNumber = finite(left), finite(right)
    if leftNumber ~= nil and rightNumber ~= nil then
        return math.abs(leftNumber - rightNumber) <= EPSILON
    end
    if type(left) ~= "table" or type(right) ~= "table" then return false end
    for key, _ in pairs(left) do
        if not equal(left[key], right[key]) then return false end
    end
    for key, _ in pairs(right) do
        if not equal(left[key], right[key]) then return false end
    end
    return true
end

local function boundedFluidType(value)
    value = tostring(value or "")
    if value == "" then return nil end
    if #value > 64 then value = string.sub(value, 1, 64) end
    return value
end

local function copyFluidEntries(entries)
    local output = {}
    local index
    local entry
    local fluidType
    local amount
    if type(entries) ~= "table" then return output end
    for index = 1, math.min(#entries, MAX_FLUIDS) do
        entry = entries[index]
        fluidType = type(entry) == "table"
            and boundedFluidType(entry.type) or nil
        amount = type(entry) == "table" and finite(entry.amount) or nil
        if fluidType and amount and amount >= 0 then
            output[#output + 1] = { type = fluidType, amount = amount }
        end
    end
    return output
end

local function fluidEntries(state)
    local entries = copyFluidEntries(state and state.fluids)
    local primary = boundedFluidType(state and (
        state.fluidPrimaryType or state.fluidType))
    local amount = finite(state and state.fluidAmount)
    if #entries == 0 and primary and amount and amount > EPSILON then
        entries[1] = { type = primary, amount = amount }
    end
    return entries
end

local function sortFluidEntries(entries, primary)
    table.sort(entries, function(left, right)
        if left.type == primary then return right.type ~= primary end
        if right.type == primary then return false end
        return left.type < right.type
    end)
end

local function compactFluidState(state)
    local output = {}
    local primary
    local entries
    local amount
    local key
    if type(state) ~= "table" then return output end
    amount = finite(state.fluidAmount)
    primary = boundedFluidType(state.fluidPrimaryType or state.fluidType)
    entries = fluidEntries(state)
    if amount ~= nil then output.fluidAmount = amount end
    if finite(state.fluidCapacity) ~= nil then
        output.fluidCapacity = finite(state.fluidCapacity)
    end
    if primary then output.fluidPrimaryType = primary end
    for _, key in ipairs({
        "fluidInputLocked", "fluidCanPlayerEmpty", "fluidRainCatcher",
    }) do
        if state[key] ~= nil then output[key] = copy(state[key]) end
    end
    if #entries > 0 then
        sortFluidEntries(entries, primary)
        if not (#entries == 1
            and entries[1].type == tostring(primary or "")
            and amount ~= nil
            and math.abs(entries[1].amount - amount) <= EPSILON
        ) then
            output.fluids = entries
        end
    end
    return output
end

local function hasFluidState(state)
    if type(state) ~= "table" then return false end
    return state.fluidAmount ~= nil
        or state.fluidCapacity ~= nil
        or state.fluidPrimaryType ~= nil
        or state.fluidType ~= nil
        or state.fluidInputLocked ~= nil
        or state.fluidCanPlayerEmpty ~= nil
        or state.fluidRainCatcher ~= nil
        or type(state.fluids) == "table"
end

local function isEmpty(state)
    if type(state) ~= "table" then return true end
    for _, _ in pairs(state) do return false end
    return true
end

local function resolvedValue(value)
    if type(value) == "table" and type(value.state) == "table" then
        return value.state, finite(value.revision) or providerRevision
    end
    return value, providerRevision
end

function Defaults.RegisterProvider(callback, revision)
    provider = type(callback) == "function" and callback or nil
    providerRevision = math.max(0, math.floor(tonumber(revision) or 0))
    cache = {}
end

function Defaults.ClearProvider()
    Defaults.RegisterProvider(nil, 0)
end

function Defaults.GetProviderRevision()
    return providerRevision
end

function Defaults.Resolve(fullType, context)
    local key = tostring(fullType or "")
    local value
    local ok
    local state
    local revision
    if key == "" then return nil, false, providerRevision end
    if type(context) == "table" and type(context.defaults) == "table" then
        return context.defaults, true,
            finite(context.definitionRevision) or providerRevision
    end
    if cache[key] ~= nil then
        value = cache[key]
        return value.state, value.resolved, value.revision
    end
    if not provider then
        cache[key] = { state = nil, resolved = false, revision = providerRevision }
        return nil, false, providerRevision
    end
    ok, value = pcall(provider, key, context)
    if ok then
        state, revision = resolvedValue(value)
    else
        state, revision = nil, providerRevision
    end
    revision = finite(revision) or providerRevision
    if type(state) ~= "table" then
        cache[key] = { state = nil, resolved = false, revision = revision }
        return nil, false, revision
    end
    cache[key] = {
        state = Defaults.Compact(state), resolved = true, revision = revision,
    }
    return cache[key].state, true, revision
end

function Defaults.Get(fullType, context)
    return Defaults.Resolve(fullType, context)
end

local function copyNonFluidState(source, output)
    local key
    if type(source) ~= "table" then return end
    for key, value in pairs(source) do
        if not FLUID_FIELDS[key] then output[key] = copy(value) end
    end
end

function Defaults.Compact(state)
    local output = {}
    local key
    if type(state) ~= "table" then return output end
    copyNonFluidState(state, output)
    if hasFluidState(state) then
        local fluid = compactFluidState(state)
        for key, value in pairs(fluid) do output[key] = value end
    end
    return output
end

function Defaults.Diff(fullType, actual, context)
    local baseline
    local resolved
    local delta = {}
    local compacted = Defaults.Compact(actual)
    local explicitFluidEntries = type(actual) == "table"
        and copyFluidEntries(actual.fluids) or {}
    local baselineFluidEntries
    local explicitFluidList = type(actual) == "table"
        and type(actual.fluids) == "table"
    local key
    local value
    local baseValue
    local actualFluid
    local baselineFluid
    local fluidKey
    baseline, resolved = Defaults.Resolve(fullType, context)
    baseline = Defaults.Compact(baseline or {})
    baselineFluidEntries = fluidEntries(baseline)
    sortFluidEntries(explicitFluidEntries,
        compacted.fluidPrimaryType or compacted.fluidType)
    sortFluidEntries(baselineFluidEntries, baseline.fluidPrimaryType)

    for key, value in pairs(compacted) do
        if not FLUID_FIELDS[key] then
            baseValue = baseline[key]
            if not equal(value, baseValue) then delta[key] = copy(value) end
        end
    end

    -- An absent instance fluid state is the important default case: do not
    -- interpret it as an empty container merely because the baseline has a
    -- fluid component.
    if hasFluidState(compacted) then
        actualFluid = compactFluidState(compacted)
        baselineFluid = compactFluidState(baseline)
        if (finite(actualFluid.fluidAmount) or 0) <= EPSILON then
            -- Empty is an explicit override unless empty is already the
            -- definition default.  Clearing the inherited primary/mix is
            -- implied by fluidAmount == 0 and costs no extra marker.
            if not resolved
                or (finite(baselineFluid.fluidAmount) or 0) > EPSILON
            then
                delta.fluidAmount = 0
            end
            for _, fluidKey in ipairs({
                "fluidCapacity", "fluidInputLocked",
                "fluidCanPlayerEmpty", "fluidRainCatcher",
            }) do
                value = actualFluid[fluidKey]
                baseValue = baselineFluid[fluidKey]
                if value ~= nil and not equal(value, baseValue) then
                    delta[fluidKey] = copy(value)
                end
            end
        else
            for _, fluidKey in ipairs({
                "fluidAmount", "fluidCapacity", "fluidPrimaryType",
                "fluidInputLocked", "fluidCanPlayerEmpty", "fluidRainCatcher",
                "fluids",
            }) do
                value = actualFluid[fluidKey]
                baseValue = baselineFluid[fluidKey]
                if value ~= nil and not equal(value, baseValue) then
                    delta[fluidKey] = copy(value)
                end
            end
            -- A single explicit entry is normally redundant, but it is the
            -- only compact way to say "replace a mixed definition with this
            -- one fluid" when primary type and total amount are unchanged.
            if explicitFluidList and #explicitFluidEntries == 1
                and #baselineFluidEntries > 1
                and not equal(explicitFluidEntries, baselineFluidEntries)
            then
                delta.fluids = explicitFluidEntries
            end
        end
    end
    if isEmpty(delta) then return nil, resolved end
    return delta, resolved
end

local function copyBaseline(baseline)
    return type(baseline) == "table" and copy(baseline) or {}
end

function Defaults.Apply(fullType, delta, context)
    local baseline = Defaults.Resolve(fullType, context)
    local output = copyBaseline(baseline)
    local baselineAmount = finite(output.fluidAmount)
    local requestedAmount
    local ratio
    local key
    local value
    if type(delta) ~= "table" then return output end
    for key, value in pairs(delta) do
        if not FLUID_FIELDS[key] then output[key] = copy(value) end
    end
    if hasFluidState(delta) then
        if delta.fluidAmount ~= nil then
            output.fluidAmount = finite(delta.fluidAmount) or 0
            if output.fluidAmount <= EPSILON then
                output.fluidPrimaryType = nil
                output.fluidType = nil
                output.fluids = nil
            elseif delta.fluids == nil and baselineAmount
                and baselineAmount > EPSILON
                and type(output.fluids) == "table"
            then
                -- An amount-only override keeps the definition's mixture
                -- ratios while reducing the total volume.
                requestedAmount = output.fluidAmount
                ratio = requestedAmount / baselineAmount
                for index = 1, #output.fluids do
                    output.fluids[index].amount = output.fluids[index].amount
                        * ratio
                end
            end
        end
        for _, keyName in ipairs({
            "fluidCapacity", "fluidPrimaryType", "fluidInputLocked",
            "fluidCanPlayerEmpty", "fluidRainCatcher", "fluids",
        }) do
            if delta[keyName] ~= nil then
                output[keyName] = copy(delta[keyName])
            end
        end
        if delta.fluidPrimaryType ~= nil and delta.fluids == nil
            and (finite(output.fluidAmount) or 0) > EPSILON
        then
            output.fluids = {
                { type = tostring(delta.fluidPrimaryType),
                    amount = output.fluidAmount },
            }
        end
        if output.fluidAmount ~= nil
            and (finite(output.fluidAmount) or 0) <= EPSILON
        then
            output.fluidPrimaryType = nil
            output.fluidType = nil
            output.fluids = nil
        end
    end
    return output
end

function Defaults.Effective(item, context)
    if type(item) ~= "table" then return {} end
    return Defaults.Apply(item.type or item.fullType, item.itemState, context)
end

function Defaults.IsDefault(fullType, state, context)
    local delta = Defaults.Diff(fullType, state, context)
    return delta == nil
end

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Inventory = PsychopatzCore.Inventory or {}
PsychopatzCore.Inventory.ItemStateDefaults = Defaults
return Defaults
