local ROOT = "Contents/mods/PsychopatzCore/42.19/media/lua/client/PsychopatzCore/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

PsychopatzCore = { UI = {} }
local itemTexture = {}
local pathTexture = {}
local itemCalls = 0
local pathCalls = 0

getItemTex = function(fullType)
    itemCalls = itemCalls + 1
    return fullType == "Base.Axe" and itemTexture or nil
end
tryGetTexture = function(path)
    pathCalls = pathCalls + 1
    return path == "media/ui/test.png" and pathTexture or nil
end
getTexture = function() return nil end

local Resolver = dofile(ROOT .. "UI/Components/PsychopatzImageResolver.lua")
assertEqual(Resolver.ResolveItemTexture("Base.Axe"), itemTexture,
    "item texture resolves")
assertEqual(Resolver.ResolveItemTexture("Base.Axe"), itemTexture,
    "item texture cache resolves")
assertEqual(itemCalls, 1, "item texture is looked up once")
assertEqual(Resolver.ResolveItemTexture("Base.Missing"), nil,
    "missing item texture is safe")
assertEqual(Resolver.ResolveItemTexture("Base.Missing"), nil,
    "missing item texture cache is safe")
assertEqual(itemCalls, 2, "missing item texture is looked up once")

local element = {}
function element:drawTextureScaledAspect(texture, x, y, width, height, alpha)
    self.drawn = { texture = texture, x = x, y = y, width = width,
        height = height, alpha = alpha }
end
assertEqual(Resolver.DrawItemIcon(element, "Base.Axe", 8, 9, 34, 35, 0.8),
    itemTexture, "item icon draw returns texture")
assertEqual(element.drawn.texture, itemTexture, "item icon draws resolved texture")
assertEqual(element.drawn.alpha, 0.8, "item icon preserves alpha")
assertEqual(Resolver.Resolve("media/ui/test.png"), pathTexture,
    "path texture resolves")
assertEqual(Resolver.Resolve("media/ui/test.png"), pathTexture,
    "path texture cache resolves")
assertEqual(pathCalls, 1, "path texture is looked up once")
assertEqual(Resolver.DrawItemIcon({}, "Base.Missing", 0, 0, 1, 1), nil,
    "item icon drawing is safe without texture or draw method")

Resolver.ClearCache()
assertEqual(Resolver.ResolveItemTexture("Base.Axe"), itemTexture,
    "cache clear permits a fresh item lookup")
assertEqual(itemCalls, 3, "cache clear resets item texture cache")

print("psychopatz_image_resolver_smoke: ok")
