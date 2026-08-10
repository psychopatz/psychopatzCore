local Profiler = PsychopatzCore and PsychopatzCore.Profiler
if not Profiler then return nil end
local Internal = Profiler.Internal

function Internal.NewRing(capacity)
    return { capacity = capacity, count = 0, next = 1, values = {} }
end

function Internal.RingPush(ring, value)
    ring.values[ring.next] = value
    ring.next = ring.next % ring.capacity + 1
    if ring.count < ring.capacity then ring.count = ring.count + 1 end
end

function Internal.RingGetAgo(ring, samplesAgo)
    if not ring or ring.count == 0 then return nil end
    samplesAgo = math.max(0, math.floor(tonumber(samplesAgo) or 0))
    if samplesAgo >= ring.count then return nil end
    local newest = (ring.next - 2) % ring.capacity + 1
    local index = (newest - samplesAgo - 1) % ring.capacity + 1
    return ring.values[index]
end

return Internal
