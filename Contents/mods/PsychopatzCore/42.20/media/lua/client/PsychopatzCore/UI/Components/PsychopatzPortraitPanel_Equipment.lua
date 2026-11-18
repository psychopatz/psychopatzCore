-- UI3DModel copies a character's attachment models when binding. Use a
-- detached body only for previews that need those models.
local Equipment = {}
local handGroup

local function previewHands()
    if not handGroup then
        handGroup = AttachedLocationGroup.new("PsychopatzPortraitHands")
        handGroup:getOrCreateLocation("primary"):setAttachmentName("Bip01_Prop1")
        handGroup:getOrCreateLocation("secondary"):setAttachmentName("Bip01_Prop2")
    end
    return AttachedItems.new(handGroup)
end

function Equipment.Build(panel, descriptor, spec)
    local held, stowed = spec.previewHandItems, spec.previewStowedItems
    if not held and not stowed then return nil end
    if not IsoZombie or not AttachedLocationGroup or not AttachedItems then return nil end
    local body = panel.equipmentPreviewBody
    if not body then
        -- A null cell and the constructor's zero coordinates keep this body
        -- out of world lists. Write the collections directly to avoid events.
        body = IsoZombie.new(nil)
        panel.equipmentPreviewBody = body
    end
    body:setFemale(spec.isFemale == true)
    body:getHumanVisual():copyFrom(descriptor:getHumanVisual())
    descriptor:getWornItems():getItemVisuals(body:getItemVisuals())
    local attachments = held and previewHands() or AttachedItems.new(AttachedLocations.getGroup("Human"))
    for slot, item in pairs(held or stowed) do
        attachments:setItem(slot, item)
    end
    body:setAttachedItems(attachments)
    return body
end

return Equipment
