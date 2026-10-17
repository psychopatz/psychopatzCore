-- Shared pointer state for conversation-style layout editors.
--
-- Geometry remains owned by the editor/part using this helper.  This module
-- owns only pointer capture bookkeeping and cumulative movement so every
-- editor has the same drag/resize semantics.

local Pointer = {}

local function mousePosition(fallbackX, fallbackY)
    local x, y = fallbackX, fallbackY
    if type(getMouseX) == "function" then
        local ok, value = pcall(getMouseX)
        if ok and value ~= nil then x = tonumber(value) or x end
    end
    if type(getMouseY) == "function" then
        local ok, value = pcall(getMouseY)
        if ok and value ~= nil then y = tonumber(value) or y end
    end
    return x, y
end

function Pointer.Start(x, y, resizing)
    local startX, startY = mousePosition(x, y)
    return {
        active = true,
        resizing = resizing == true,
        startX = startX,
        startY = startY,
        accumulatedX = 0,
        accumulatedY = 0,
    }
end

function Pointer.IsActive(pointer)
    return type(pointer) == "table" and pointer.active == true
end

function Pointer.Move(pointer, deltaX, deltaY)
    if not Pointer.IsActive(pointer) then return false, 0, 0 end
    local fallbackX = pointer.startX + pointer.accumulatedX
        + (tonumber(deltaX) or 0)
    local fallbackY = pointer.startY + pointer.accumulatedY
        + (tonumber(deltaY) or 0)
    local currentX, currentY = mousePosition(fallbackX, fallbackY)
    local movedX = currentX - pointer.startX
    local movedY = currentY - pointer.startY

    -- When the engine does not expose global mouse coordinates, retain the
    -- event deltas.  When it does, the absolute pointer position wins so a
    -- drag remains continuous across panel boundaries.
    if type(getMouseX) ~= "function" or type(getMouseY) ~= "function" then
        pointer.accumulatedX = pointer.accumulatedX + (tonumber(deltaX) or 0)
        pointer.accumulatedY = pointer.accumulatedY + (tonumber(deltaY) or 0)
        movedX = pointer.accumulatedX
        movedY = pointer.accumulatedY
    end
    return true, movedX, movedY
end

function Pointer.Stop(pointer)
    if not Pointer.IsActive(pointer) then return false end
    pointer.active = false
    return true
end

return Pointer
