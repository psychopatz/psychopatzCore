-- Single location-resolution contract for PsychopatzCore world events.
-- Reuses PsychopatzCore.Zones, optional adopter providers, and deterministic
-- quantized grid cells/local areas without creating a parallel location store.
-- Kahlua2-safe Lua 5.1: zero pcall, zero next(), zero per-tick polling.

local Util = require "PsychopatzCore/Actors/PsychopatzActorUtil"

PsychopatzCore = PsychopatzCore or {}
local Location = PsychopatzCore.WorldEventLocation or {}
PsychopatzCore.WorldEventLocation = Location

Location.SCHEMA = "PsychopatzCore.WorldEventLocation"
Location.SCHEMA_VERSION = 1
Location.MAX_PROVIDERS = 16
Location.LOCAL_AREA_SIZE = 100
Location.REGION_CELL_SIZE = 300

Location._providers = Location._providers or {}

local function finite(value)
    local num = tonumber(value)
    if num == nil or num ~= num or num == math.huge or num == -math.huge then
        return nil
    end
    return num
end

local function safeID(value, limit)
    if type(value) ~= "string" and type(value) ~= "number" then return nil end
    local text = tostring(value)
    if text == "" or #text > (limit or 128) or string.match(text, "[%c]") then
        return nil
    end
    if not string.match(text, "^[%w_%-%.:]+$") then
        return nil
    end
    return text
end

local function safeText(value, limit)
    if type(value) ~= "string" and type(value) ~= "number" then return nil end
    local text = tostring(value)
    if text == "" or #text > (limit or 160) or string.match(text, "[%c]") then
        return nil
    end
    return text
end

local function sortProviders()
    table.sort(Location._providers, function(left, right)
        if left.priority ~= right.priority then
            return left.priority > right.priority
        end
        return left.id < right.id
    end)
end

function Location.RegisterProvider(providerID, resolverFn, priority)
    local id = safeID(providerID, 96)
    if not id or type(resolverFn) ~= "function" then
        return false, "location_provider_invalid"
    end
    for i = 1, #Location._providers do
        if Location._providers[i].id == id then
            Location._providers[i].resolve = resolverFn
            Location._providers[i].priority = tonumber(priority) or 0
            sortProviders()
            return true, "updated"
        end
    end
    if #Location._providers >= Location.MAX_PROVIDERS then
        return false, "location_provider_capacity_exceeded"
    end
    Location._providers[#Location._providers + 1] = {
        id = id,
        priority = tonumber(priority) or 0,
        resolve = resolverFn,
    }
    sortProviders()
    return true, "registered"
end

function Location.UnregisterProvider(providerID)
    local id = safeID(providerID, 96)
    if not id then return false end
    for i = #Location._providers, 1, -1 do
        if Location._providers[i].id == id then
            table.remove(Location._providers, i)
            return true
        end
    end
    return false
end

function Location.ClearProviders()
    Location._providers = {}
    return true
end

function Location.QuantizeCell(x, y)
    local nx = finite(x)
    local ny = finite(y)
    if nx == nil or ny == nil then return nil, nil end
    return math.floor(nx / Location.REGION_CELL_SIZE), math.floor(ny / Location.REGION_CELL_SIZE)
end

function Location.QuantizeArea(x, y)
    local nx = finite(x)
    local ny = finite(y)
    if nx == nil or ny == nil then return nil, nil end
    return math.floor(nx / Location.LOCAL_AREA_SIZE), math.floor(ny / Location.LOCAL_AREA_SIZE)
end

function Location.Resolve(x, y, z, opts)
    opts = type(opts) == "table" and opts or {}
    local nx = finite(x)
    local ny = finite(y)
    local nz = finite(z) or 0

    if nx == nil or ny == nil then
        local explicitRegion = safeID(opts.regionID)
        local explicitSettlement = safeID(opts.settlementID)
        local explicitFaction = safeID(opts.factionID)
        local explicitArea = safeID(opts.localAreaID)
        if not (explicitRegion or explicitSettlement or explicitFaction or explicitArea) then
            return nil, "location_coordinates_or_scope_required"
        end
        return {
            settlementID = explicitSettlement,
            factionID = explicitFaction,
            regionID = explicitRegion,
            localAreaID = explicitArea,
            zoneID = safeID(opts.zoneID),
            label = safeText(opts.label, 128) or explicitSettlement or explicitArea or explicitRegion or explicitFaction,
            kind = safeID(opts.kind, 64) or (explicitSettlement and "settlement" or "region"),
            coarse = true,
        }
    end

    local cellX, cellY = Location.QuantizeCell(nx, ny)
    local bucketX, bucketY = Location.QuantizeArea(nx, ny)
    local resolved = {
        x = math.floor(nx),
        y = math.floor(ny),
        z = math.floor(nz),
        cellX = cellX,
        cellY = cellY,
        bucketX = bucketX,
        bucketY = bucketY,
        settlementID = safeID(opts.settlementID),
        factionID = safeID(opts.factionID),
        regionID = safeID(opts.regionID),
        localAreaID = safeID(opts.localAreaID),
        zoneID = safeID(opts.zoneID),
        label = safeText(opts.label, 128),
        kind = safeID(opts.kind, 64),
        coarse = false,
    }

    -- 1. Consult registered adopter providers (e.g., Hoomans settlement/community or DT market registry).
    local singleResolver = type(opts.resolveLocation) == "function" and opts.resolveLocation or nil
    if singleResolver then
        local hit = singleResolver(nx, ny, nz, opts)
        if type(hit) == "table" then
            resolved.settlementID = resolved.settlementID or safeID(hit.settlementID)
            resolved.factionID = resolved.factionID or safeID(hit.factionID)
            resolved.regionID = resolved.regionID or safeID(hit.regionID)
            resolved.localAreaID = resolved.localAreaID or safeID(hit.localAreaID)
            resolved.zoneID = resolved.zoneID or safeID(hit.zoneID)
            resolved.label = resolved.label or safeText(hit.label or hit.name, 128)
            resolved.kind = resolved.kind or safeID(hit.kind, 64)
        end
    end

    for i = 1, #Location._providers do
        local provider = Location._providers[i]
        local hit = provider.resolve(nx, ny, nz, opts)
        if type(hit) == "table" then
            resolved.settlementID = resolved.settlementID or safeID(hit.settlementID)
            resolved.factionID = resolved.factionID or safeID(hit.factionID)
            resolved.regionID = resolved.regionID or safeID(hit.regionID)
            resolved.localAreaID = resolved.localAreaID or safeID(hit.localAreaID)
            resolved.zoneID = resolved.zoneID or safeID(hit.zoneID)
            resolved.label = resolved.label or safeText(hit.label or hit.name, 128)
            resolved.kind = resolved.kind or safeID(hit.kind, 64)
        end
    end

    -- 2. Reuse PsychopatzCore.Zones if available and zone/settlement still unresolved.
    local zonesApi = type(opts.zonesApi) == "table" and opts.zonesApi or PsychopatzCore.Zones
    local ix, iy, iz = math.floor(nx), math.floor(ny), math.floor(nz)
    if zonesApi and type(zonesApi.queryPoint) == "function" then
        local hits = zonesApi.queryPoint(ix, iy, iz)
        if type(hits) == "table" and #hits > 0 then
            table.sort(hits, function(a, b)
                return tostring(a.id or "") < tostring(b.id or "")
            end)
            local firstZone = hits[1]
            if type(firstZone) == "table" then
                resolved.zoneID = resolved.zoneID or safeID(firstZone.id)
                resolved.kind = resolved.kind or safeID(firstZone.type, 64)
                if not resolved.settlementID and firstZone.ownerType == "settlement" then
                    resolved.settlementID = safeID(firstZone.ownerId)
                elseif not resolved.factionID and firstZone.ownerType == "faction" then
                    resolved.factionID = safeID(firstZone.ownerId)
                end
            end
        end
    end

    -- 3. Deterministic quantized region/area fallback.
    resolved.regionID = resolved.regionID or ("region:cell_" .. tostring(cellX) .. "_" .. tostring(cellY))
    resolved.localAreaID = resolved.localAreaID or ("area:" .. tostring(bucketX) .. "_" .. tostring(bucketY))
    resolved.kind = resolved.kind or (resolved.settlementID and "settlement" or "local_area")
    if not resolved.label then
        resolved.label = resolved.settlementID or ("cell " .. tostring(cellX) .. "," .. tostring(cellY))
    end

    return resolved
end

function Location.ToFactReference(locRef)
    if type(locRef) ~= "table" then return nil end
    local id = safeID(locRef.settlementID or locRef.localAreaID or locRef.regionID or locRef.zoneID)
    if not id then return nil end
    local out = {
        id = id,
        kind = safeID(locRef.kind, 64) or (locRef.settlementID and "settlement" or "local_area"),
    }
    local label = safeText(locRef.label, 128)
    if label then out.name = label end
    local region = safeID(locRef.regionID)
    if region then out.region = region end
    local faction = safeID(locRef.factionID)
    if faction then out.factionID = faction end
    return out
end

function Location.ResolveScope(locRef, preferredScope)
    if type(locRef) ~= "table" then return nil, nil end
    local scope = tostring(preferredScope or "")
    if scope == "settlement" and locRef.settlementID then
        return "settlement", locRef.settlementID
    elseif scope == "faction" and locRef.factionID then
        return "faction", locRef.factionID
    elseif scope == "region" and locRef.regionID then
        return "region", locRef.regionID
    elseif scope == "local_area" and locRef.localAreaID then
        return "local_area", locRef.localAreaID
    end
    if locRef.settlementID and (preferredScope == nil or preferredScope == "settlement") then
        return "settlement", locRef.settlementID
    end
    if locRef.regionID and preferredScope == "region" then
        return "region", locRef.regionID
    end
    if locRef.localAreaID then
        return "local_area", locRef.localAreaID
    end
    if locRef.regionID then
        return "region", locRef.regionID
    end
    return nil, nil
end

return Location
