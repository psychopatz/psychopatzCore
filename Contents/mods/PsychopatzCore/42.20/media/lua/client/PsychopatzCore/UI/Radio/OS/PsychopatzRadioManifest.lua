-- PsychopatzCore Radio OS | Walkie Asset Manifest v1
-- Core-owned destination for the migrated DTAbstract walkie artwork.
--
-- AUTHORING CONTRACT, not evidence that any atlas artwork has been sliced yet.
-- Atlas coordinates are top-left-origin PNG pixels: x, y, w, h.
-- Each radio shell has a small safe content viewport and a separately measured
-- alpha-hole backdrop.  The backdrop covers the complete intended LCD aperture
-- while the content viewport keeps text and portraits inside the bezel.
-- At runtime: matte -> LCD background -> app/portrait -> effects -> shell -> controls.
-- Do not persist these tables into world ModData.

local M = {
    schemaVersion = 1,
    family = "walkie",
    coordSystem = "top_left_pixels",
    baseShellWidth = 256,
    baseShellHeight = 432,
    sheets = {
        shells = {
            path = "media/ui/psychopatz/radio/shells/DTA_Walkie_Shells.png",
            width = 1024, height = 1024,
        },
        core = {
            path = "media/ui/psychopatz/radio/ui/DTA_Walkie_UI_Core.png",
            width = 1024, height = 1024,
        },
        buttons = {
            path = "media/ui/psychopatz/radio/ui/DTA_Walkie_Buttons.png",
            width = 1024, height = 512,
        },
        icons = {
            path = "media/ui/psychopatz/radio/ui/DTA_Walkie_Icons.png",
            width = 512, height = 512,
        },
        indicators = {
            path = "media/ui/psychopatz/radio/ui/DTA_Walkie_Indicators.png",
            width = 512, height = 256,
        },
        overlays = {
            path = "media/ui/psychopatz/radio/ui/DTA_Walkie_Overlays.png",
            width = 512, height = 512,
        },
    },
    sprites = {},
    skins = {},
    byFullType = {},
    themes = {
        green = { lcd = "screen_bg_green", signal = "green" },
        amber = { lcd = "screen_bg_amber", signal = "amber" },
        dark = { lcd = "screen_bg_dark", signal = "green" },
    },
}

local function rect(x, y, w, h)
    return { x = x, y = y, w = w, h = h }
end

local function add(id, sheet, x, y, w, h, caps)
    assert(not M.sprites[id], "duplicate sprite ID: " .. id)
    M.sprites[id] = { sheet = sheet, rect = rect(x, y, w, h) }
    if caps then M.sprites[id].capInsets = caps end
end

local function skin(id, fullType, x, y, screen, lcdBackdrop, buttons, theme)
    local model = {
        id = id,
        fullType = fullType,
        family = "walkie",
        sprite = id,
        baseSize = { w = M.baseShellWidth, h = M.baseShellHeight },
        screen = rect(screen[1], screen[2], screen[3], screen[4]),
        lcdBackdrop = rect(lcdBackdrop[1], lcdBackdrop[2],
            lcdBackdrop[3], lcdBackdrop[4]),
        controls = {
            left   = rect(buttons[1][1], buttons[1][2], buttons[1][3], buttons[1][4]),
            center = rect(buttons[2][1], buttons[2][2], buttons[2][3], buttons[2][4]),
            right  = rect(buttons[3][1], buttons[3][2], buttons[3][3], buttons[3][4]),
        },
        theme = theme,
        -- Relative-screen viewports are determined later by active OS apps;
        -- no contact name, portrait, frequency or app state is baked in.
    }
    M.skins[id] = model
    M.byFullType[fullType] = id
    add(id, "shells", x, y, 256, 432)
end

skin("walkie_toys_shell", "Base.WalkieTalkie1", 32, 32,
    { 90, 236, 81, 61 },
    { 88, 232, 90, 81 },
    { {75,326,31,26}, {115,326,31,26}, {154,326,31,26} }, "green")
skin("walkie_valutech_shell", "Base.WalkieTalkie2", 320, 32,
    { 85, 236, 82, 61 },
    { 82, 232, 96, 81 },
    { {74,326,31,26}, {112,326,31,26}, {150,326,31,26} }, "dark")
skin("walkie_premium_shell", "Base.WalkieTalkie3", 608, 32,
    { 81, 236, 83, 61 },
    { 80, 232, 102, 81 },
    { {68,326,31,26}, {108,326,31,26}, {149,326,31,26} }, "amber")
skin("walkie_tactical_shell", "Base.WalkieTalkie4", 32, 496,
    { 99, 246, 81, 55 },
    { 97, 231, 93, 81 },
    { {85,326,31,26}, {123,326,31,26}, {161,326,31,26} }, "dark")
skin("walkie_usarmy_shell", "Base.WalkieTalkie5", 320, 496,
    { 107, 247, 72, 55 },
    { 97, 234, 93, 81 },
    { {85,326,31,26}, {122,326,31,26}, {160,326,31,26} }, "green")
skin("walkie_makeshift_shell", "Base.WalkieTalkieMakeShift", 608, 496,
    { 86, 247, 79, 55 },
    { 83, 231, 99, 81 },
    { {72,326,31,26}, {116,326,31,26}, {157,326,31,26} }, "amber")

-- Core UI: resizable panel backgrounds use capInsets; icons/text are separate.
local core = {
    {"screen_bg_green",16,16,224,128},
    {"screen_bg_amber",256,16,224,128},
    {"screen_bg_dark",496,16,224,128},
    {"screen_bg_noise",736,16,224,128},
    {"titlebar_green",16,160,224,32,8},
    {"titlebar_amber",256,160,224,32,8},
    {"titlebar_dark",496,160,224,32,8},
    {"footerbar_green",16,208,224,32,8},
    {"footerbar_amber",256,208,224,32,8},
    {"tabbar_green",16,256,224,32,8},
    {"tabbar_dark",256,256,224,32,8},
    {"listrow_green_idle",16,304,224,40,8},
    {"listrow_green_selected",16,352,224,40,8},
    {"listrow_dark_idle",256,304,224,40,8},
    {"listrow_dark_selected",256,352,224,40,8},
    {"dialog_green",16,416,320,208,12},
    {"dialog_amber",352,416,320,208,12},
    {"popup_small_dark",688,416,192,128,12},
    {"home_tile_idle",16,640,104,104},
    {"home_tile_selected",136,640,104,104},
    {"home_tile_disabled",256,640,104,104},
    {"portrait_frame_green",16,760,128,128,10},
    {"portrait_frame_amber",160,760,128,128,10},
    {"contact_card_green",304,760,224,96,8},
    {"status_strip_green",544,760,224,48,8},
}
for _, entry in ipairs(core) do
    add(entry[1], "core", entry[2], entry[3], entry[4], entry[5], entry[6])
end

-- Button geometry is state-only art: labels/icons are drawn independently.
for _, theme in ipairs({ "green", "dark", "amber", "red" }) do
    local y = ({ green = 16, dark = 64, amber = 112, red = 160 })[theme]
    for i, state in ipairs({"idle", "hover", "pressed", "disabled"}) do
        add("btn_sq_" .. theme .. "_" .. state,
            "buttons", 16 + (i - 1) * 80, y, 64, 32, 6)
    end
end
for _, theme in ipairs({ "green", "dark" }) do
    local y = theme == "green" and 224 or 280
    for i, state in ipairs({"idle", "hover", "pressed", "disabled"}) do
        add("btn_wide_" .. theme .. "_" .. state,
            "buttons", 16 + (i - 1) * 160, y, 144, 40, 8)
    end
end
for _, family in ipairs({"call", "hangup"}) do
    local x = family == "call" and 16 or 416
    for i, state in ipairs({"idle", "hover", "pressed", "disabled"}) do
        add("btn_" .. family .. "_" .. state,
            "buttons", x + (i - 1) * 96, 336, 80, 40, 8)
    end
end
for i, state in ipairs({ "idle", "hover", "active", "disabled" }) do
    add("btn_tab_" .. state, "buttons", 16 + (i - 1) * 128, 400,
        112, 36, 8)
end

-- Icons grid: 64px authoring cells; actual glyph must keep alpha padding.
local icons = {
    {"contacts","radio_call","trade","dossier","scan","home","back","settings"},
    {"chat","logs","faction","trader","caravan","signal","battery","mic"},
    {"speaker","mute","connecting","receiving","transmitting","offline","alert","search"},
    {"plus","minus","next","prev","up","down","left","right"},
}
for row = 1, #icons do
    for col = 1, #icons[row] do
        add("icon_" .. icons[row][col], "icons", (col-1)*64, (row-1)*64, 64, 64)
    end
end

-- Indicators: client supplies factual values (do not derive fake signal/battery).
for _, theme in ipairs({"green", "amber"}) do
    local y = theme == "green" and 16 or 40
    for n = 0, 4 do
        add("ind_signal_" .. theme .. "_" .. n,
            "indicators", 16 + n*56, y, 48, 16)
    end
end
for n = 0, 4 do
    add("ind_battery_green_" .. n, "indicators", 16+n*48, 72, 40, 16)
end
add("ind_rx", "indicators", 16,112,64,20)
add("ind_tx", "indicators", 96,112,64,20)
add("ind_muted", "indicators", 176,112,64,20)
add("ind_offline", "indicators", 256,112,64,20)
local chips = {
    {"standby",16,160}, {"receiving",144,160},
    {"transmitting",272,160}, {"signal_lost",16,200},
    {"offline",144,200}, {"connecting",272,200},
}
for _, v in ipairs(chips) do
    add("chip_" .. v[1], "indicators", v[2], v[3], 112, 28, 8)
end

local overlays = {
    {"overlay_scanlines_green",16,16,160,160},
    {"overlay_scanlines_amber",192,16,160,160},
    {"overlay_noise_light",16,192,160,160},
    {"overlay_noise_heavy",192,192,160,160},
    {"overlay_glare_soft",16,368,160,96},
    {"overlay_glow_green",192,368,160,96},
    {"overlay_mask_square",368,16,128,128},
    {"overlay_mask_wide",368,160,128,64},
}
for _, entry in ipairs(overlays) do
    add(entry[1], "overlays", entry[2], entry[3], entry[4], entry[5])
end

function M.GetSkin(fullTypeOrSkinId)
    local id = M.byFullType[fullTypeOrSkinId] or fullTypeOrSkinId
    return M.skins[id]
end

function M.GetSprite(id)
    local sprite = M.sprites[id]
    if not sprite then return nil end
    return M.sheets[sprite.sheet].path, sprite.rect, sprite.capInsets
end

-- Returns a copy of the screen bounds in *window* coordinates for any scale.
-- Render surface must be clipped to these bounds to prevent portrait bleed.
function M.ScreenBounds(skinID, scale, windowX, windowY)
    local s = M.GetSkin(skinID)
    if not s then return nil end
    scale = math.max(0.1, tonumber(scale) or 1)
    windowX = tonumber(windowX) or 0
    windowY = tonumber(windowY) or 0
    return rect(windowX + s.screen.x * scale,
        windowY + s.screen.y * scale,
        s.screen.w * scale, s.screen.h * scale)
end

-- Returns the scaled, window-local LCD matte bounds.  This is deliberately
-- distinct from ScreenBounds: app content uses the inset safe viewport, while
-- the matte and themed backing cover the measured transparent aperture.
function M.LCDBounds(skinID, scale, windowX, windowY)
    local s = M.GetSkin(skinID)
    if not s then return nil end
    scale = math.max(0.1, tonumber(scale) or 1)
    windowX = tonumber(windowX) or 0
    windowY = tonumber(windowY) or 0
    local aperture = s.lcdBackdrop or s.screen
    return rect(windowX + aperture.x * scale,
        windowY + aperture.y * scale,
        aperture.w * scale, aperture.h * scale)
end

-- This validates CONTRACT rectangles; it does not verify actual PNG artwork.
-- A separate authoring-time tool should check atlas dimensions and alpha holes.
function M.Validate()
    local errors = {}
    local function err(message) errors[#errors + 1] = message end
    for id, sprite in pairs(M.sprites) do
        local sheet = M.sheets[sprite.sheet]
        local r = sprite.rect
        if not sheet then
            err(id .. ": unknown sheet")
        elseif r.x < 0 or r.y < 0 or r.w <= 0 or r.h <= 0
            or r.x + r.w > sheet.width or r.y + r.h > sheet.height then
            err(id .. ": sprite outside sheet")
        end
        if sprite.capInsets and sprite.capInsets * 2 >= math.min(r.w, r.h) then
            err(id .. ": invalid cap inset")
        end
    end
    -- Atlas cells must not overlap, even if each rectangle is in bounds.
    -- This catches accidental manifest drift when an atlas is repacked.
    local ids = {}
    for id in pairs(M.sprites) do ids[#ids + 1] = id end
    table.sort(ids)
    for a = 1, #ids do
        local left = M.sprites[ids[a]]
        local l = left.rect
        for b = a + 1, #ids do
            local right = M.sprites[ids[b]]
            if left.sheet == right.sheet then
                local r = right.rect
                if l.x < r.x + r.w and r.x < l.x + l.w
                    and l.y < r.y + r.h and r.y < l.y + l.h then
                    err(ids[a] .. " overlaps " .. ids[b])
                end
            end
        end
    end
    for id, s in pairs(M.skins) do
        local b = s.baseSize
        local r = s.screen
        local aperture = s.lcdBackdrop or s.screen
        if r.x < 0 or r.y < 0 or r.w <= 0 or r.h <= 0
            or r.x + r.w > b.w or r.y + r.h > b.h then
            err(id .. ": screen outside shell")
        end
        if aperture.x < 0 or aperture.y < 0 or aperture.w <= 0
            or aperture.h <= 0 or aperture.x + aperture.w > b.w
            or aperture.y + aperture.h > b.h then
            err(id .. ": LCD backdrop outside shell")
        end
        if r.x < aperture.x or r.y < aperture.y
            or r.x + r.w > aperture.x + aperture.w
            or r.y + r.h > aperture.y + aperture.h then
            err(id .. ": screen is outside LCD backdrop")
        end
        for controlId, c in pairs(s.controls) do
            if c.x < 0 or c.y < 0 or c.w <= 0 or c.h <= 0
                or c.x + c.w > b.w or c.y + c.h > b.h then
                err(id .. ": control outside shell: " .. controlId)
            end
        end
    end
    table.sort(errors)
    return #errors == 0, errors
end

return M
