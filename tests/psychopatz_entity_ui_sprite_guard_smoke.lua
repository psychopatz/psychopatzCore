local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end

local vanillaCalls = 0
ISEntityUI = {
    CanOpenWindowFor = function(player, entity)
        vanillaCalls = vanillaCalls + 1
        -- Mirrors vanilla ISEntityUI.lua:342 dereferencing getSprite():getName()
        local name = entity:getSprite():getName()
        return player ~= nil and name == "crafted_workbench_01"
    end,
}

package.preload["Entity/ISEntityUI"] = function() return ISEntityUI end

local Guard = dofile(
    "Contents/mods/PsychopatzCore/42.20/media/lua/client/PsychopatzCore/Compatibility/PsychopatzEntityUISpriteGuard.lua"
)

assertEqual(Guard.installed, true, "guard installs immediately when ISEntityUI is present")

local fireEntity = {
    getSprite = function() return nil end,
}
assertEqual(ISEntityUI.CanOpenWindowFor({}, fireEntity), false,
    "spriteless IsoFire-like entity safely returns false")
assertEqual(vanillaCalls, 0,
    "vanilla CanOpenWindowFor is not called for spriteless entity")

assertEqual(ISEntityUI.CanOpenWindowFor({}, nil), false,
    "nil entity safely returns false")
assertEqual(vanillaCalls, 0,
    "vanilla CanOpenWindowFor is not called for nil entity")

local workbenchEntity = {
    getSprite = function()
        return { getName = function() return "crafted_workbench_01" end }
    end,
}
assertEqual(ISEntityUI.CanOpenWindowFor({}, workbenchEntity), true,
    "valid sprite entity delegates to vanilla CanOpenWindowFor")
assertEqual(vanillaCalls, 1,
    "vanilla CanOpenWindowFor runs once for valid entity")

local wrappedRef = ISEntityUI.CanOpenWindowFor
assertEqual(Guard.Install(), true, "re-installing guard is idempotent")
assertEqual(ISEntityUI.CanOpenWindowFor, wrappedRef,
    "idempotent install does not double-wrap CanOpenWindowFor")

print("psychopatz_entity_ui_sprite_guard_smoke: ok")
