require "TimedActions/ISAttachItemHotbar"

-- Build 42 can lose the active Kahlua call frame when setAttachedItem() is
-- invoked directly from the attach animation event. Walkies reliably expose
-- this on the belt. Defer completion by one tick so vanilla perform() makes
-- the actual attachment from the normal timed-action update context.
if ISAttachItemHotbar._psychopatzWalkieAttachGuardInstalled then
    return ISAttachItemHotbar
end
ISAttachItemHotbar._psychopatzWalkieAttachGuardInstalled = true

local vanillaAnimEvent = ISAttachItemHotbar.animEvent
local pendingCompletions = {}
local tickInstalled = false

local function isWalkieAction(action)
    local item = action and action.item or nil
    if not item or not item.getAttachmentType then
        return false
    end
    return tostring(item:getAttachmentType() or "") == "Walkie"
end

local function completePendingWalkies()
    local pending = pendingCompletions
    pendingCompletions = {}
    Events.OnTick.Remove(completePendingWalkies)
    tickInstalled = false

    for index = 1, #pending do
        local action = pending[index]
        if action and action.forceComplete then
            action._psychopatzWalkieCompletionPending = nil
            action:forceComplete()
        end
    end
end

local function deferCompletion(action)
    if action._psychopatzWalkieCompletionPending then return end
    action._psychopatzWalkieCompletionPending = true
    pendingCompletions[#pendingCompletions + 1] = action
    if tickInstalled then return end
    tickInstalled = true
    Events.OnTick.Add(completePendingWalkies)
end

function ISAttachItemHotbar:animEvent(event, parameter)
    if event ~= "attachConnect" or not isWalkieAction(self) then
        return vanillaAnimEvent(self, event, parameter)
    end

    -- Do not call character:setAttachedItem() here. Vanilla perform() still
    -- owns the attachment bookkeeping, icon refresh, and MP field sync.
    self:setOverrideHandModels(nil, nil)
    if self.character:isEquipped(self.item) then
        self.character:removeFromHands(self.item)
    end

    if self.maxTime == -1 then
        deferCompletion(self)
    end
end

return ISAttachItemHotbar
