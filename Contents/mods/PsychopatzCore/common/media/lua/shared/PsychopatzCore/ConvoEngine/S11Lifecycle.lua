-- S11A6: Generic retention, stacking/dedupe, and bounded game-time expiry lifecycle
-- for portable S11 modifiers and semantic memory episodes.
-- Keeps memory and modifiers as distinct semantic objects.
-- Kahlua2-safe (Lua 5.1 compatible).

local S11Lifecycle = {}

S11Lifecycle.MAX_STACKS = 16

local function computeExpiry(retention, nowMinutes)
    if type(retention) ~= "table" then
        return nil
    end
    local kind = tostring(retention.kind or "SESSION")
    if kind == "TIMED" then
        local dur = tonumber(retention.durationMinutes) or 0
        if dur > 0 then
            return (tonumber(nowMinutes) or 0) + dur
        end
    end
    return nil
end

function S11Lifecycle.NewStore()
    return {
        modifiers = {},   -- key -> list of active modifier instances
        memories = {},    -- episodeId -> memory episode record
        nextModifierExpiry = nil,
        nextMemoryExpiry = nil,
    }
end

local function recomputeNextExpiry(bucket, isListBucket)
    local earliest = nil
    if isListBucket then
        for _, list in pairs(bucket) do
            for i = 1, #list do
                local exp = list[i].expiresAtMinutes
                if type(exp) == "number" and (earliest == nil or exp < earliest) then
                    earliest = exp
                end
            end
        end
    else
        for _, entry in pairs(bucket) do
            local exp = entry.expiresAtMinutes
            if type(exp) == "number" and (earliest == nil or exp < earliest) then
                earliest = exp
            end
        end
    end
    return earliest
end

function S11Lifecycle.ApplyModifier(store, modifierSpec, nowMinutes, targetKey)
    if type(store) ~= "table" or type(modifierSpec) ~= "table" then
        return false, "invalid_args"
    end
    local now = tonumber(nowMinutes) or 0
    local id = tostring(modifierSpec.id or "")
    local domain = tostring(modifierSpec.domain or "")
    local field = tostring(modifierSpec.field or "")
    local target = tostring(targetKey or modifierSpec.targetRole or "addressee")
    local key = domain .. ":" .. field .. ":" .. id .. ":" .. target

    local retention = type(modifierSpec.retention) == "table" and modifierSpec.retention or { kind = "SESSION" }
    local kind = tostring(retention.kind or "SESSION")
    local stacking = tostring(modifierSpec.stacking or "replace")
    local expiresAt = computeExpiry(retention, now)
    local delta = tonumber(modifierSpec.delta) or 0

    local list = store.modifiers[key]
    if type(list) ~= "table" then
        list = {}
        store.modifiers[key] = list
    end

    if #list == 0 then
        list[1] = {
            id = id,
            domain = domain,
            field = field,
            delta = delta,
            retentionKind = kind,
            untilFact = retention.untilFact,
            durationMinutes = retention.durationMinutes,
            expiresAtMinutes = expiresAt,
            appliedAtMinutes = now,
            target = target,
        }
    elseif stacking == "ignore" then
        return true, "ignored"
    elseif stacking == "replace" then
        list[1] = {
            id = id,
            domain = domain,
            field = field,
            delta = delta,
            retentionKind = kind,
            untilFact = retention.untilFact,
            durationMinutes = retention.durationMinutes,
            expiresAtMinutes = expiresAt,
            appliedAtMinutes = now,
            target = target,
        }
    elseif stacking == "refresh" then
        list[1].expiresAtMinutes = expiresAt
    elseif stacking == "extend" then
        local dur = tonumber(retention.durationMinutes) or 0
        local base = tonumber(list[1].expiresAtMinutes) or now
        if base < now then
            base = now
        end
        if dur > 0 then
            list[1].expiresAtMinutes = base + dur
        end
    elseif stacking == "accumulate" then
        list[1].delta = (tonumber(list[1].delta) or 0) + delta
        if expiresAt ~= nil then
            list[1].expiresAtMinutes = expiresAt
        end
    elseif stacking == "stack" then
        if #list < S11Lifecycle.MAX_STACKS then
            list[#list + 1] = {
                id = id,
                domain = domain,
                field = field,
                delta = delta,
                retentionKind = kind,
                untilFact = retention.untilFact,
                durationMinutes = retention.durationMinutes,
                expiresAtMinutes = expiresAt,
                appliedAtMinutes = now,
                target = target,
            }
        end
    else
        return false, "unsupported_stacking:" .. stacking
    end

    store.nextModifierExpiry = recomputeNextExpiry(store.modifiers, true)
    return true, stacking
end

function S11Lifecycle.RecordMemory(store, closureSpec, nowMinutes)
    if type(store) ~= "table" or type(closureSpec) ~= "table" then
        return false, "invalid_args"
    end
    local epId = tostring(closureSpec.episodeId or closureSpec.obligationRef or "")
    if epId == "" then
        return false, "missing_episode_id"
    end
    local now = tonumber(nowMinutes) or 0
    local retention = type(closureSpec.retention) == "table" and closureSpec.retention or { kind = "TIMED", durationMinutes = 1440 }
    local expiresAt = computeExpiry(retention, now)
    store.memories[epId] = {
        episodeId = epId,
        closureClass = tostring(closureSpec.closureClass or "resolved_episode"),
        retentionKind = tostring(retention.kind or "TIMED"),
        untilFact = retention.untilFact,
        obligationRef = closureSpec.obligationRef,
        expiresAtMinutes = expiresAt,
        recordedAtMinutes = now,
    }
    store.nextMemoryExpiry = recomputeNextExpiry(store.memories, false)
    return true, "recorded"
end

function S11Lifecycle.PruneExpired(store, nowMinutes, factResolver)
    if type(store) ~= "table" then
        return 0
    end
    local now = tonumber(nowMinutes) or 0
    local removed = 0

    if factResolver ~= nil or (store.nextModifierExpiry ~= nil and now >= store.nextModifierExpiry) then
        for key, list in pairs(store.modifiers) do
            local kept = {}
            for i = 1, #list do
                local inst = list[i]
                local expired = false
                if inst.retentionKind == "TIMED" and type(inst.expiresAtMinutes) == "number" and now >= inst.expiresAtMinutes then
                    expired = true
                elseif inst.retentionKind == "UNTIL" and type(factResolver) == "function" and inst.untilFact ~= nil then
                    if factResolver(inst.untilFact) == true then
                        expired = true
                    end
                end
                if expired then
                    removed = removed + 1
                else
                    kept[#kept + 1] = inst
                end
            end
            if #kept == 0 then
                store.modifiers[key] = nil
            else
                store.modifiers[key] = kept
            end
        end
        store.nextModifierExpiry = recomputeNextExpiry(store.modifiers, true)
    end

    if factResolver ~= nil or (store.nextMemoryExpiry ~= nil and now >= store.nextMemoryExpiry) then
        for epId, mem in pairs(store.memories) do
            local expired = false
            if mem.retentionKind == "TIMED" and type(mem.expiresAtMinutes) == "number" and now >= mem.expiresAtMinutes then
                expired = true
            elseif mem.retentionKind == "UNTIL" and type(factResolver) == "function" and mem.untilFact ~= nil then
                if factResolver(mem.untilFact) == true then
                    expired = true
                end
            end
            if expired then
                store.memories[epId] = nil
                removed = removed + 1
            end
        end
        store.nextMemoryExpiry = recomputeNextExpiry(store.memories, false)
    end

    return removed
end

function S11Lifecycle.EndSession(store)
    if type(store) ~= "table" then
        return 0
    end
    local removed = 0
    for key, list in pairs(store.modifiers) do
        local kept = {}
        for i = 1, #list do
            if list[i].retentionKind == "SESSION" then
                removed = removed + 1
            else
                kept[#kept + 1] = list[i]
            end
        end
        store.modifiers[key] = (#kept > 0) and kept or nil
    end
    for epId, mem in pairs(store.memories) do
        if mem.retentionKind == "SESSION" then
            store.memories[epId] = nil
            removed = removed + 1
        end
    end
    store.nextModifierExpiry = recomputeNextExpiry(store.modifiers, true)
    store.nextMemoryExpiry = recomputeNextExpiry(store.memories, false)
    return removed
end

function S11Lifecycle.SumDomainField(store, domain, field, targetKey)
    if type(store) ~= "table" then
        return 0
    end
    local total = 0
    local target = targetKey ~= nil and tostring(targetKey) or nil
    for _, list in pairs(store.modifiers) do
        for i = 1, #list do
            local inst = list[i]
            if inst.domain == domain and inst.field == field and (target == nil or inst.target == target) then
                total = total + (tonumber(inst.delta) or 0)
            end
        end
    end
    return total
end

return S11Lifecycle
