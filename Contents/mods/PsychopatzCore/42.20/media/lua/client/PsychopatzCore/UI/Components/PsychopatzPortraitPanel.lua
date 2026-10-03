require "ISUI/ISPanel"
require "ISUI/ISUI3DModel"
require "PsychopatzCore/UI/Core/PsychopatzUILayout"

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.UI = PsychopatzCore.UI or {}

local UI = PsychopatzCore.UI
local Descriptor = require
    "PsychopatzCore/UI/Components/PsychopatzPortraitPanel_Descriptor"

local function normalizeScreenVariant(value)
    if value == nil then return nil end
    value = string.lower(tostring(value))
    if value == "crt" or value == "screen" then return "crt" end
    if value == "subtle" or value == "default" or value == "clean" then
        return "subtle"
    end
    if value == "none" or value == "off" then return "none" end
    return nil
end

PsychopatzPortraitPanel = ISPanel:derive("PsychopatzPortraitPanel")
UI.PortraitPanel = PsychopatzPortraitPanel

require "PsychopatzCore/UI/Components/PsychopatzPortraitPanel_Setup"
require "PsychopatzCore/UI/Components/PsychopatzPortraitPanel_View"
require "PsychopatzCore/UI/Components/PsychopatzPortraitPanel_Renderer"

function PsychopatzPortraitPanel:new(x, y, width, height, options)
    local o = ISPanel:new(x, y, width, height)
    options = options or {}
    setmetatable(o, self)
    self.__index = self
    o.zoom = tonumber(options.zoom) or 14
    o.xOffset = tonumber(options.xOffset) or 0
    o.yOffset = tonumber(options.yOffset) or -0.85
    o.direction = options.direction or (IsoDirections and IsoDirections.S)
    o.isometric = options.isometric == true
    o.animate = options.animate ~= false
    o.portraitAnimationEnabled = options.portraitAnimation == true
    o.faceOnly = options.faceOnly == true
    o.showBackground = options.showBackground ~= false
    o.showBorder = options.showBorder ~= false
    o.padding = math.max(0, tonumber(options.padding) or 2)
    o.screenVariant = normalizeScreenVariant(options.screenVariant)
    o.subtleOpacity = math.max(0, math.min(1,
        tonumber(options.subtleOpacity) or 0.18))
    o.crtOpacity = math.max(0, math.min(1,
        tonumber(options.crtOpacity) or 0.52))
    o.contentOpacity = 1
    o.modelVisibilityApplied = nil
    if options.animSetName == nil then
        o.animSetName = "zombie"
    else
        o.animSetName = options.animSetName
    end
    o.stateName = options.stateName or "idle"
    return o
end

function UI.GetPortraitDescriptorCacheSize()
    return Descriptor.CacheSize()
end

return PsychopatzPortraitPanel
