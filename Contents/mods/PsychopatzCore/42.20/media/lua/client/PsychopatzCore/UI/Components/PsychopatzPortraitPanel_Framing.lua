-- Reusable camera-only region views. Target/spec/clothing state stays untouched.
local UI, Window = PsychopatzCore.UI, PsychopatzPortraitPanel
local presets = {
    body = { zoom = -3, xOffset = 0, yOffset = 0 },
    head = { zoom = 14, xOffset = 0, yOffset = -.85 },
    neck = { zoom = 10, xOffset = 0, yOffset = -.65 },
    torso = { zoom = 5, xOffset = 0, yOffset = -.3 },
    arms = { zoom = 7, xOffset = 0, yOffset = -.25 },
    left_arm = { zoom = 8, xOffset = -.3, yOffset = -.25 },
    right_arm = { zoom = 8, xOffset = .3, yOffset = -.25 },
    hands = { zoom = 8, xOffset = 0, yOffset = .05 },
    waist = { zoom = 6, xOffset = 0, yOffset = .1 },
    legs = { zoom = 3, xOffset = 0, yOffset = .45 },
    feet = { zoom = 9, xOffset = 0, yOffset = .85 },
    back = { zoom = 3, xOffset = 0, yOffset = -.25, direction = 'N' },
}
local aliases = { face = 'head', full = 'body', upper_body = 'torso', lower_body = 'legs',
    held = 'hands', carry = 'body', other = 'body' }
local function copyCamera(panel)
    return { zoom = panel.zoom, xOffset = panel.xOffset, yOffset = panel.yOffset,
        direction = panel.direction, isometric = panel.isometric }
end
local function applyCamera(panel, camera)
    for _, key in ipairs({ 'zoom', 'xOffset', 'yOffset', 'direction', 'isometric' }) do panel[key] = camera[key] end
    panel:applyCameraState()
end
function Window:setViewRegion(region, reset)
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
    applyCamera(self, camera)
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
