-- S11A7: Runtime dependency-driven fact projection and authoritative invalidation.
-- Projects only required facts for a selected family (no N x N precompute) and
-- invalidates only affected families on authoritative fact changes, with safe
-- full-rebuild fallback. Kahlua2-safe (Lua 5.1 compatible).

local S11DependencyIndex = {}

local function readPath(tbl, path)
    local cur = tbl
    for seg in string.gmatch(path, "[^%.]+") do
        if type(cur) ~= "table" then
            return nil, false
        end
        cur = cur[seg]
        if cur == nil then
            return nil, false
        end
    end
    return cur, true
end

local function writePath(dst, path, value)
    local parts = {}
    for seg in string.gmatch(path, "[^%.]+") do
        parts[#parts + 1] = seg
    end
    if #parts == 0 then
        return
    end
    local cur = dst
    for i = 1, #parts - 1 do
        local seg = parts[i]
        if type(cur[seg]) ~= "table" then
            cur[seg] = {}
        end
        cur = cur[seg]
    end
    cur[parts[#parts]] = value
end

function S11DependencyIndex.ProjectRequiredFacts(familyId, index, context)
    local projected = {}
    if type(index) ~= "table" or type(index.familyRequiredFacts) ~= "table" then
        return projected
    end
    local req = index.familyRequiredFacts[familyId]
    if type(req) ~= "table" then
        return projected
    end
    local ctx = type(context) == "table" and context or {}
    for i = 1, #req do
        local path = req[i]
        local val, ok = readPath(ctx, path)
        if ok then
            writePath(projected, path, val)
        end
    end
    return projected
end

function S11DependencyIndex.InvalidatedFamilies(changedFacts, index)
    local out = {}
    local seen = {}
    if type(changedFacts) ~= "table" or type(index) ~= "table" or type(index.factToFamilies) ~= "table" then
        return out
    end
    for i = 1, #changedFacts do
        local fams = index.factToFamilies[changedFacts[i]]
        if type(fams) == "table" then
            for j = 1, #fams do
                local fid = fams[j]
                if not seen[fid] then
                    seen[fid] = true
                    out[#out + 1] = fid
                end
            end
        end
    end
    return out
end

function S11DependencyIndex.CreateProjectionCache()
    return {
        entries = {},
        rebuilds = 0,
    }
end

function S11DependencyIndex.Invalidate(cache, changedFacts, index)
    if type(cache) ~= "table" or type(cache.entries) ~= "table" then
        return 0
    end
    if type(index) ~= "table" or type(index.factToFamilies) ~= "table" then
        cache.entries = {}
        cache.rebuilds = (cache.rebuilds or 0) + 1
        return -1
    end
    local fams = S11DependencyIndex.InvalidatedFamilies(changedFacts, index)
    local count = 0
    for i = 1, #fams do
        if cache.entries[fams[i]] ~= nil then
            cache.entries[fams[i]] = nil
            count = count + 1
        end
    end
    return count
end

return S11DependencyIndex
