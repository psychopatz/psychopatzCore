-- Provider-neutral World Hazard & Corridor Cost Modifier registry for
-- PsychopatzCore SurvivorWorld. Shared by DynamicTrading (DTAbstract),
-- ProjectHoomans, and any future World Events / Roaming Horde / Roadblock mods.

local Hazards = {}

Hazards.ThreatProviders = Hazards.ThreatProviders or {}
Hazards.CorridorModifiers = Hazards.CorridorModifiers or {}
Hazards.TemporaryPenalties = Hazards.TemporaryPenalties or {}
Hazards.MAX_TEMP_PENALTIES = 48
Hazards._revision = Hazards._revision or 1

function Hazards.GetRevision()
    return tonumber(Hazards._revision) or 1
end

local function bumpRevision()
    Hazards._revision = (tonumber(Hazards._revision) or 1) + 1
end

local function sortedKeys(map)
    local keys = {}
    for k in pairs(map) do
        keys[#keys + 1] = k
    end
    table.sort(keys)
    return keys
end

function Hazards.RegisterThreatProvider(id, fn)
    id = tostring(id or "")
    if id == "" or type(fn) ~= "function" then return false end
    Hazards.ThreatProviders[id] = fn
    return true
end

function Hazards.UnregisterThreatProvider(id)
    id = tostring(id or "")
    if id == "" or Hazards.ThreatProviders[id] == nil then return false end
    Hazards.ThreatProviders[id] = nil
    return true
end

function Hazards.RegisterCorridorModifier(id, fn)
    id = tostring(id or "")
    if id == "" or type(fn) ~= "function" then return false end
    Hazards.CorridorModifiers[id] = fn
    bumpRevision()
    return true
end

function Hazards.UnregisterCorridorModifier(id)
    id = tostring(id or "")
    if id == "" or Hazards.CorridorModifiers[id] == nil then return false end
    Hazards.CorridorModifiers[id] = nil
    bumpRevision()
    return true
end

-- Ephemeral TTL-bounded corridor penalty (e.g., live horde blocking a street).
function Hazards.AddTemporaryCorridorPenalty(id, x, y, radius, multiplier, expiresAt)
    id = tostring(id or "")
    x = tonumber(x)
    y = tonumber(y)
    if id == "" or x == nil or y == nil then return false end
    Hazards.TemporaryPenalties[id] = {
        id = id,
        x = x,
        y = y,
        radius = math.max(8, tonumber(radius) or 32),
        multiplier = math.max(1.0, tonumber(multiplier) or 4.0),
        expiresAt = tonumber(expiresAt) or 0,
    }
    bumpRevision()
    local keys = sortedKeys(Hazards.TemporaryPenalties)
    while #keys > Hazards.MAX_TEMP_PENALTIES do
        local oldestId, oldestExp = nil, nil
        for i = 1, #keys do
            local p = Hazards.TemporaryPenalties[keys[i]]
            if not oldestExp or (p.expiresAt or 0) < oldestExp then
                oldestId = keys[i]
                oldestExp = p.expiresAt or 0
            end
        end
        if not oldestId then break end
        Hazards.TemporaryPenalties[oldestId] = nil
        keys = sortedKeys(Hazards.TemporaryPenalties)
    end
    return true
end

function Hazards.PruneTemporaryPenalties(nowHours)
    nowHours = tonumber(nowHours)
    if not nowHours then return 0 end
    local removed = 0
    for id, p in pairs(Hazards.TemporaryPenalties) do
        if (tonumber(p.expiresAt) or 0) > 0 and p.expiresAt <= nowHours then
            Hazards.TemporaryPenalties[id] = nil
            removed = removed + 1
        end
    end
    if removed > 0 then bumpRevision() end
    return removed
end

-- O(1) in-memory IsoMetaChunk zombie intensity lookup (0..255). Never loads chunks.
function Hazards.SampleMetaZombieIntensity(x, y)
    x = tonumber(x)
    y = tonumber(y)
    if x == nil or y == nil then return 0 end
    local world = getWorld and getWorld() or nil
    local metaGrid = world and world.getMetaGrid and world:getMetaGrid() or nil
    if not metaGrid or type(metaGrid.getChunkData) ~= "function" then
        return 0
    end
    local ok, chunkData = pcall(
        metaGrid.getChunkData,
        metaGrid,
        math.floor(x / 10),
        math.floor(y / 10)
    )
    if not ok or not chunkData or type(chunkData.getZombieIntensity) ~= "function" then
        return 0
    end
    local okVal, val = pcall(chunkData.getZombieIntensity, chunkData)
    if okVal and tonumber(val) then
        return math.max(0, tonumber(val))
    end
    return 0
end

function Hazards.EvaluateThreatAt(x, y, at)
    local metaIntensity = Hazards.SampleMetaZombieIntensity(x, y)
    local providerTotal = 0
    local sources = {}
    if metaIntensity > 0 then
        sources[#sources + 1] = { id = "metagrid_zombies", intensity = metaIntensity, kind = "zombies" }
    end
    local ids = sortedKeys(Hazards.ThreatProviders)
    for i = 1, #ids do
        local id = ids[i]
        local ok, res = pcall(Hazards.ThreatProviders[id], x, y, at)
        if ok then
            local intensity = 0
            local kind = "custom"
            if type(res) == "number" then
                intensity = math.max(0, res)
            elseif type(res) == "table" then
                intensity = math.max(0, tonumber(res.intensity) or 0)
                kind = tostring(res.kind or "custom")
            end
            if intensity > 0 then
                providerTotal = providerTotal + intensity
                sources[#sources + 1] = { id = id, intensity = intensity, kind = kind }
            end
        end
    end
    return {
        totalThreat = metaIntensity + providerTotal,
        metaIntensity = metaIntensity,
        providerThreat = providerTotal,
        sources = sources,
    }
end

-- Returns costMultiplier (>= 1.0) and blocked (boolean) for an A* corridor edge midpoint.
function Hazards.EvaluateCorridorCost(x, y, at)
    x = tonumber(x)
    y = tonumber(y)
    if x == nil or y == nil then return 1.0, false end
    local mult = 1.0
    local blocked = false
    local now = tonumber(at)

    for id, p in pairs(Hazards.TemporaryPenalties) do
        if now and (tonumber(p.expiresAt) or 0) > 0 and p.expiresAt <= now then
            Hazards.TemporaryPenalties[id] = nil
        else
            local dx = x - p.x
            local dy = y - p.y
            if (dx * dx + dy * dy) <= (p.radius * p.radius) then
                mult = mult * p.multiplier
            end
        end
    end

    local ids = sortedKeys(Hazards.CorridorModifiers)
    for i = 1, #ids do
        local ok, res = pcall(Hazards.CorridorModifiers[ids[i]], x, y, at)
        if ok then
            if res == "blocked" or res == math.huge then
                blocked = true
                return math.huge, true
            elseif type(res) == "number" and res > 0 then
                mult = mult * res
            elseif type(res) == "table" then
                if res.blocked == true then
                    blocked = true
                    return math.huge, true
                end
                local m = tonumber(res.multiplier)
                if m and m > 0 then
                    mult = mult * m
                end
            end
        end
    end

    return math.max(0.25, mult), blocked
end

function Hazards.GetDebugSummary()
    local tp, cm, temp = 0, 0, 0
    for _ in pairs(Hazards.ThreatProviders) do tp = tp + 1 end
    for _ in pairs(Hazards.CorridorModifiers) do cm = cm + 1 end
    for _ in pairs(Hazards.TemporaryPenalties) do temp = temp + 1 end
    return {
        threatProviderCount = tp,
        corridorModifierCount = cm,
        temporaryPenaltyCount = temp,
    }
end

function Hazards.Reset()
    Hazards.ThreatProviders = {}
    Hazards.CorridorModifiers = {}
    Hazards.TemporaryPenalties = {}
    bumpRevision()
end

return Hazards
