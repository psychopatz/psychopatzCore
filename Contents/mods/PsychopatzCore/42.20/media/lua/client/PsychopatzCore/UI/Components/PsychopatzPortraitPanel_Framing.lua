-- Reusable camera-only region views. Target/spec/clothing state stays untouched.
local UI, Window = PsychopatzCore.UI, PsychopatzPortraitPanel
-- UI3DModel offsets translate the model. Zero uses the native full-body offset.
local presets = {
    body = { zoom = -3, xOffset = 0, yOffset = 0 },
    head = { zoom = 14, xOffset = 0, yOffset = -.85 },
    neck = { zoom = 10, xOffset = 0, yOffset = -.73 },
    torso = { zoom = 3, xOffset = 0, yOffset = -.58 },
    arms = { zoom = 0, xOffset = 0, yOffset = -.52 },
    left_arm = { zoom = 5, xOffset = .15, yOffset = -.52 },
    right_arm = { zoom = 5, xOffset = -.15, yOffset = -.52 },
    hands = { zoom = -7, xOffset = 0, yOffset = -.33 },
    waist = { zoom = 6, xOffset = 0, yOffset = -.48 },
    legs = { zoom = 3, xOffset = 0, yOffset = -.24 },
    feet = { zoom = 9, xOffset = 0, yOffset = -.06 },
    back = { zoom = 3, xOffset = 0, yOffset = -.58, direction = 'N' },
}
local aliases = { face = 'head', full = 'body', upper_body = 'torso', lower_body = 'legs',
    held = 'hands', carry = 'body', other = 'body' }
local function copyCamera(panel)
    return { zoom = panel.zoom, xOffset = panel.xOffset, yOffset = panel.yOffset,
        direction = panel.direction, isometric = panel.isometric }
end
local function verticalOffset(camera)
    local offset = tonumber(camera.yOffset) or -.85
    if offset == 0 then return camera.isometric and -.45 or -.5 end
    return offset
end

function Window:getRenderedCamera(now)
    local motion = self.cameraTransition
    if not motion then return self end
    local progress = math.max(0, (now - motion.startedAt) / 250)
    if progress >= 1 then
        self.cameraTransition = nil
        return self
    end
    local eased = progress * progress * (3 - 2 * progress)
    local from = motion.from
    local y = verticalOffset(from) + (verticalOffset(self) - verticalOffset(from)) * eased
    return {
        zoom = from.zoom + ((tonumber(self.zoom) or 14) - from.zoom) * eased,
        xOffset = from.xOffset + ((tonumber(self.xOffset) or 0) - from.xOffset) * eased,
        yOffset = y == 0 and -.0001 or y,
    }
end

local function applyCamera(panel, camera, animate)
    local now = getTimeInMillis and getTimeInMillis()
    local from = now and animate and panel:getRenderedCamera(now)
    panel.cameraTransition = from and { startedAt = now, from = {
        zoom = tonumber(from.zoom) or 14,
        xOffset = tonumber(from.xOffset) or 0,
        yOffset = verticalOffset(from),
    } } or nil
    for _, key in ipairs({ 'zoom', 'xOffset', 'yOffset', 'direction', 'isometric' }) do panel[key] = camera[key] end
    panel:applyCameraState(now)
end

function Window:setViewRegion(region, reset, animate)
    region = string.lower(tostring(region or 'body'))
    region = aliases[region] or region
    local preset = presets[region]
    if not preset then return false, 'unknown_view_region' end
    if self.viewRegion == region and reset ~= true then return true end
    self.regionCameras = self.regionCameras or {}
    self.unframedCamera = self.unframedCamera or copyCamera(self)
    if self.viewRegion then self.regionCameras[self.viewRegion] = copyCamera(self) end
    local camera = reset ~= true and self.regionCameras[region] or nil
    if not camera then
        camera = { zoom = preset.zoom, xOffset = preset.xOffset, yOffset = preset.yOffset,
            direction = preset.direction and IsoDirections and IsoDirections[preset.direction]
                or self.unframedCamera.direction, isometric = self.unframedCamera.isometric }
    end
    self.viewRegion = region
    applyCamera(self, camera, animate)
    return true
end
function Window:getViewRegion() return self.viewRegion end
function Window:clearViewRegion()
    if not self.unframedCamera then return false end
    self.regionCameras[self.viewRegion] = copyCamera(self)
    local camera = self.unframedCamera
    self.viewRegion, self.unframedCamera = nil, nil
    applyCamera(self, camera)
    return true
end
UI.PortraitViewRegions = presets
return Window
