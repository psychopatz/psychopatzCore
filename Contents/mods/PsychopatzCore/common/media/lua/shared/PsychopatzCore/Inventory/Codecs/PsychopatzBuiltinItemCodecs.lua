local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local Util = require "PsychopatzCore/Inventory/PsychopatzInventoryUtil"
local Registry = require "PsychopatzCore/Inventory/PsychopatzItemCodecRegistry"
local Support = require "PsychopatzCore/Inventory/Codecs/PsychopatzItemCodecSupport"

require "PsychopatzCore/Inventory/Codecs/PsychopatzSpecializedItemCodecs"

Registry.register({
    id = C.CODEC_DRAINABLE, name = "drainable", priority = 80,
    matches = function(item)
        return Support.isKind(item, "DrainableComboItem") or item.isDrainable == true
            or Util.call(item, "IsDrainable") == true
    end,
    encode = function(item) return Support.commonResult(item) end,
    decode = function(item, flags, state)
        Support.decodeCommon(item, flags, state)
        return true
    end,
})

Registry.register({
    id = C.CODEC_GENERIC, name = "generic", priority = 10,
    matches = function(item)
        if Support.isKind(item, "Key") or Support.isKind(item, "KeyRing")
            or Support.isKind(item, "Literature") or Support.isKind(item, "MapItem")
        then return false end
        return string.sub(Support.fullType(item), 1, 5) == "Base."
    end,
    encode = function(item) return Support.commonResult(item) end,
    decode = function(item, flags, state)
        Support.decodeCommon(item, flags, state)
        return true
    end,
})

Registry.register({
    id = C.CODEC_FALLBACK, name = "fallback", priority = -1000,
    matches = function() return true end,
    encode = function(item)
        local result = Support.commonResult(item, false)
        result.batchable = false
        return result
    end,
    decode = function(item, flags, state)
        Support.decodeCommon(item, flags, state)
        return true
    end,
})

return Registry
