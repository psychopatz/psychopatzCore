PsychopatzCore = PsychopatzCore or {}

local RingBuffer = {}
RingBuffer.__index = RingBuffer

function RingBuffer.new(capacity)
    capacity = math.floor(tonumber(capacity) or 0)
    assert(capacity > 0, "ring buffer capacity must be positive")
    return setmetatable({
        capacity = capacity,
        size = 0,
        first = 1,
        values = {},
    }, RingBuffer)
end

function RingBuffer:count()
    return self.size
end

function RingBuffer:append(value)
    local index
    if self.size < self.capacity then
        index = ((self.first + self.size - 1) % self.capacity) + 1
        self.size = self.size + 1
    else
        index = self.first
        self.first = (self.first % self.capacity) + 1
    end
    self.values[index] = value
    return value
end

function RingBuffer:clear()
    self.values = {}
    self.size = 0
    self.first = 1
end

function RingBuffer:getOldest(index)
    index = math.floor(tonumber(index) or 0)
    if index < 1 or index > self.size then return nil end
    return self.values[((self.first + index - 2) % self.capacity) + 1]
end

function RingBuffer:getNewest(index)
    index = math.floor(tonumber(index) or 0)
    if index < 1 or index > self.size then return nil end
    return self:getOldest(self.size - index + 1)
end

function RingBuffer:oldestToNewest()
    local index = 0
    return function()
        index = index + 1
        if index <= self.size then return self:getOldest(index) end
    end
end

function RingBuffer:newestToOldest()
    local index = 0
    return function()
        index = index + 1
        if index <= self.size then return self:getNewest(index) end
    end
end

function RingBuffer:snapshot(newestFirst, limit)
    local output = {}
    local count = math.min(self.size, math.max(0,
        math.floor(tonumber(limit) or self.size)))
    for index = 1, count do
        output[index] = newestFirst == true
            and self:getNewest(index) or self:getOldest(index)
    end
    return output
end

function RingBuffer:restore(entries)
    self:clear()
    if type(entries) ~= "table" then return 0 end
    local start = math.max(1, #entries - self.capacity + 1)
    for index = start, #entries do self:append(entries[index]) end
    return self.size
end

PsychopatzCore.RingBuffer = RingBuffer
PC_RingBuffer = RingBuffer

return RingBuffer
