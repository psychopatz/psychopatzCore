local M = assert(loadfile(arg[1] or 'DTA_Walkie_Manifest.lua'))()
local ok, errs = M.Validate()
assert(ok, table.concat(errs, '\n'))
local count=0
for _ in pairs(M.sprites) do count=count+1 end
assert(count >= 125, 'sprite manifest unexpectedly incomplete: ' .. count)
local skins=0
for id, s in pairs(M.skins) do
  skins=skins+1
  assert(M.GetSkin(s.fullType) == s, 'fullType lookup failed')
  assert(M.GetSprite(id) ~= nil, 'missing shell atlas rect')
  assert(s.screen.x + s.screen.w <= 256, 'screen x out of bounds')
  assert(s.screen.y + s.screen.h <= 432, 'screen y out of bounds')
  assert(M.ScreenBounds(id, 0.5, 100, 200).w == s.screen.w * 0.5)
end
assert(skins == 6, 'need six walkie skins')
assert(M.GetSkin('Base.WalkieTalkie5').id == 'walkie_usarmy_shell')
assert(M.GetSkin('Base.HamRadio1') == nil, 'HAM deferred to separate atlas')
assert(M.GetSprite('btn_sq_green_hover') ~= nil)
assert(M.GetSprite('icon_contacts') ~= nil)
assert(M.GetSprite('chip_offline') ~= nil)
assert(M.GetSprite('overlay_noise_light') ~= nil)
print('PASS walkie asset manifest: ' .. skins .. ' device skins, ' .. count .. ' sprite entries')
