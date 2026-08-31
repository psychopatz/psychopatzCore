local ROOT = "Contents/mods/PsychopatzCore/42.19/media/lua/client/PsychopatzCore/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

PsychopatzCore = { UI = {} }
local itemTexture = {}
local scriptTexture = {}
local factoryTexture = {}
local instanceTexture = {}
local pathTexture = {}
local placeholderTexture = {}
function placeholderTexture:getName() return "Question_Highlight" end
local itemCalls = 0
local pathCalls = 0

getItemTex = function(fullType)
    itemCalls = itemCalls + 1
    if fullType == "Base.Axe" then return itemTexture end
    if fullType == "Base.PlaceholderBox" then return placeholderTexture end
    return nil
end

local scriptItems = {
    ["Base.Toolbox"] = {
        getIcon = function() return "Toolbox.png" end,
    },
    ["Base.BoxVariant"] = {
        getIconsForTexture = function() return { "BoxVariant" } end,
    },
    ["Base.PlaceholderBox"] = {
        getIcon = function() return "PlaceholderBox.png" end,
    },
}
function getScriptManager()
    return {
        getItem = function(_, fullType) return scriptItems[fullType] end,
    }
end

InventoryItemFactory = {
    CreateItem = function(fullType)
        if fullType ~= "Base.FactoryBox" then return nil end
        return {
            getTex = function() return factoryTexture end,
        }
    end,
    instanceItem = function(fullType)
        if fullType ~= "Base.InstanceBox" then return nil end
        return {
            getTex = function() return instanceTexture end,
        }
    end,
}

tryGetTexture = function(path)
    pathCalls = pathCalls + 1
    return path == "media/ui/test.png" and pathTexture or nil
end
getTexture = function(path)
    if path == "Item_Toolbox" then return scriptTexture end
    if path == "Item_BoxVariant" then return scriptTexture end
    if path == "Item_PlaceholderBox" then return scriptTexture end
    return nil
end

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
assertEqual(Resolver.ResolveItemTexture("Base.PlaceholderBox"), scriptTexture,
    "placeholder item texture falls through to script icon")
assertEqual(Resolver.ResolveItemTexture("Base.Toolbox"), scriptTexture,
    "script-defined container icon resolves through icon name variants")
assertEqual(Resolver.ResolveItemTexture("Base.BoxVariant"), scriptTexture,
    "script-defined icon variants resolve")
assertEqual(Resolver.ResolveItemTexture("Base.FactoryBox"), factoryTexture,
    "inventory factory icon fallback resolves")
assertEqual(Resolver.ResolveItemTexture("Base.InstanceBox"), instanceTexture,
    "instance-item icon fallback resolves")

local element = {}
function element:drawTextureScaledAspect(texture, x, y, width, height, alpha)
    self.drawn = { texture = texture, x = x, y = y, width = width,
        height = height, alpha = alpha }
end
assertEqual(Resolver.DrawItemIcon(element, "Base.Axe", 8, 9, 34, 35, 0.8),
    itemTexture, "item icon draw returns texture")
assertEqual(element.drawn.texture, itemTexture, "item icon draws resolved texture")
assertEqual(element.drawn.alpha, 0.8, "item icon preserves alpha")
pathCalls = 0
assertEqual(Resolver.Resolve("media/ui/test.png"), pathTexture,
    "path texture resolves")
assertEqual(Resolver.Resolve("media/ui/test.png"), pathTexture,
    "path texture cache resolves")
assertEqual(pathCalls, 1, "path texture is looked up once")
assertEqual(Resolver.DrawItemIcon({}, "Base.Missing", 0, 0, 1, 1), nil,
    "item icon drawing is safe without texture or draw method")

Resolver.ClearCache()
local callsBeforeClear = itemCalls
assertEqual(Resolver.ResolveItemTexture("Base.Axe"), itemTexture,
    "cache clear permits a fresh item lookup")
assertEqual(itemCalls, callsBeforeClear + 1,
    "cache clear resets item texture cache")

print("psychopatz_image_resolver_smoke: ok")
