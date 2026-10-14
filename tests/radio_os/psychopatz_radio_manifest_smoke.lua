local M = assert(loadfile(arg[1] or 'DTA_Walkie_Manifest.lua'))()
local ok, errs = M.Validate()
assert(ok, table.concat(errs, '\n'))
local count=0
for _ in pairs(M.sprites) do count=count+1 end
assert(count >= 125, 'sprite manifest unexpectedly incomplete: ' .. count)
local skins=0
local expectedShellCells = {
  walkie_toys_shell = { x = 32, y = 32 },
  walkie_valutech_shell = { x = 320, y = 32 },
  walkie_premium_shell = { x = 608, y = 32 },
  walkie_tactical_shell = { x = 32, y = 496 },
  walkie_usarmy_shell = { x = 320, y = 496 },
  walkie_makeshift_shell = { x = 608, y = 496 },
}
for id, s in pairs(M.skins) do
  skins=skins+1
  assert(M.GetSkin(s.fullType) == s, 'fullType lookup failed')
  local _, shellRect = M.GetSprite(id)
  assert(shellRect ~= nil, 'missing shell atlas rect')
  assert(shellRect.x == expectedShellCells[id].x
    and shellRect.y == expectedShellCells[id].y
    and shellRect.w == 256 and shellRect.h == 432,
    'shell atlas coordinates drifted: ' .. id)
  assert(s.screen.x + s.screen.w <= 256, 'screen x out of bounds')
  assert(s.screen.y + s.screen.h <= 432, 'screen y out of bounds')
  assert(s.lcdBackdrop, 'missing LCD backdrop metadata')
  assert(s.lcdBackdrop.x <= s.screen.x, 'backdrop does not contain screen x')
  assert(s.lcdBackdrop.y <= s.screen.y, 'backdrop does not contain screen y')
  assert(s.lcdBackdrop.x + s.lcdBackdrop.w >= s.screen.x + s.screen.w,
    'backdrop does not contain screen width')
  assert(s.lcdBackdrop.y + s.lcdBackdrop.h >= s.screen.y + s.screen.h,
    'backdrop does not contain screen height')
  assert(M.ScreenBounds(id, 0.5, 100, 200).w == s.screen.w * 0.5)
  assert(M.LCDBounds(id, 0.5, 100, 200).w == s.lcdBackdrop.w * 0.5)
end
assert(skins == 6, 'need six walkie skins')
assert(M.GetSkin('Base.WalkieTalkie5').id == 'walkie_usarmy_shell')
assert(M.GetSkin('Base.HamRadio1') == nil, 'HAM deferred to separate atlas')
assert(M.GetSprite('btn_sq_green_hover') ~= nil)
assert(M.GetSprite('icon_contacts') ~= nil)
assert(M.GetSprite('chip_offline') ~= nil)
assert(M.GetSprite('overlay_noise_light') ~= nil)
print('PASS walkie asset manifest: ' .. skins .. ' device skins, ' .. count .. ' sprite entries')
