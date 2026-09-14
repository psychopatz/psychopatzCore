require "TimedActions/ISAttachItemHotbar"

-- Build 42 can lose the active Kahlua call frame when setAttachedItem() is
-- invoked directly from the attach animation event. Walkies reliably expose
-- this on the belt. Defer completion by one tick so vanilla perform() makes
-- the actual attachment from the normal timed-action update context.
local pendingCompletions = {}
local tickInstalled = false

local function isWalkieAction(action)
    local item = action and action.item or nil
    local ok
    local attachmentType
    if not item or type(item.getAttachmentType) ~= "function" then
        return false
    end
    ok, attachmentType = pcall(item.getAttachmentType, item)
    return ok and tostring(attachmentType or "") == "Walkie"
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

local function discardStaleHotbarWalkie(hotbar, item)
    -- A stale client hotbar entry is not recoverable by calling
    -- setAttachedItem() from this path.  Build 42 can lose the Kahlua return
    -- frame for that void Java call, and wrapping it in pcall still logs the
    -- engine exception.  Remove only the Lua-side attachment metadata; the
    -- item remains in the inventory and can be attached again through the
    -- normal timed-action path.
    if not item then return end
    if item.setAttachedSlot then item:setAttachedSlot(-1) end
    if item.setAttachedSlotType then item:setAttachedSlotType(nil) end
    if item.setAttachedToModel then item:setAttachedToModel(nil) end
    if hotbar and hotbar.reloadIcons then hotbar:reloadIcons() end
end

local function isWalkieItem(item)
    local ok
    local attachmentType
    if not item or type(item.getAttachmentType) ~= "function" then
        return false
    end
    ok, attachmentType = pcall(item.getAttachmentType, item)
    return ok and tostring(attachmentType or "") == "Walkie"
end

if not ISAttachItemHotbar._psychopatzWalkieAttachGuardInstalled then
    ISAttachItemHotbar._psychopatzWalkieAttachGuardInstalled = true
    local vanillaAnimEvent = ISAttachItemHotbar.animEvent

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
end

local function installHotbarGuard()
    if not ISHotbar or type(ISHotbar.attachItem) ~= "function" then
        return false
    end
    if ISHotbar._psychopatzWalkieHotbarGuardInstalled then return true end
    ISHotbar._psychopatzWalkieHotbarGuardInstalled = true
    local vanillaHotbarAttachItem = ISHotbar.attachItem
    function ISHotbar:attachItem(item, slot, slotIndex, slotDef, doAnim)
        if doAnim == false and isWalkieItem(item) then
            -- ISHotbar:update() reaches this path while repairing the native
            -- attachment map. Do not call the Java setter from this repair
            -- path; discard the stale metadata and let the user reattach the
            -- inventory item through the normal timed action.
            discardStaleHotbarWalkie(self, item)
            return
        end
        return vanillaHotbarAttachItem(
            self, item, slot, slotIndex, slotDef, doAnim)
    end
    return true
end

local function retryHotbarGuard()
    if not installHotbarGuard() then return end
    if Events.OnGameStart and type(Events.OnGameStart.Remove) == "function" then
        Events.OnGameStart.Remove(retryHotbarGuard)
    end
    if Events.OnTick and type(Events.OnTick.Remove) == "function" then
        Events.OnTick.Remove(retryHotbarGuard)
    end
end

if not installHotbarGuard() then
    if Events.OnGameStart and type(Events.OnGameStart.Add) == "function" then
        Events.OnGameStart.Add(retryHotbarGuard)
    end
    if Events.OnTick and type(Events.OnTick.Add) == "function" then
        Events.OnTick.Add(retryHotbarGuard)
    end
end

return ISAttachItemHotbar
