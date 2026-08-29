PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.UI = PsychopatzCore.UI or {}

local UI = PsychopatzCore.UI
local Resolver = UI.ImageResolver or {}
UI.ImageResolver = Resolver
local PATH_CACHE = {}
local ITEM_TEXTURE_CACHE = {}

local function textureFromPath(path)
    path = tostring(path or "")
    if path == "" then return nil end
    local cached = PATH_CACHE[path]
    if cached ~= nil then return cached ~= false and cached or nil end
    if tryGetTexture then
        local ok, texture = pcall(tryGetTexture, path)
        if ok and texture then
            PATH_CACHE[path] = texture
            return texture
        end
    end
    if getTexture then
        local ok, texture = pcall(getTexture, path)
        if ok and texture then
            PATH_CACHE[path] = texture
            return texture
        end
    end
    PATH_CACHE[path] = false
    return nil
end

local function itemTextureFromType(fullType)
    fullType = tostring(fullType or "")
    if fullType == "" then return nil end
    local cached = ITEM_TEXTURE_CACHE[fullType]
    if cached ~= nil then return cached ~= false and cached or nil end
    if type(getItemTex) ~= "function" then return nil end

    local ok, texture = pcall(getItemTex, fullType)
    if ok and texture then
        ITEM_TEXTURE_CACHE[fullType] = texture
        return texture
    end
    ITEM_TEXTURE_CACHE[fullType] = false
    return nil
end

local function nativeTexture(source)
    if not source or type(source) == "string" then return nil end
    if type(source.getIconTexture) == "function" then
        local ok, texture = pcall(source.getIconTexture, source)
        if ok and texture then return texture end
    end
    return nil
end

local function resolve(source)
    local sourceType = type(source)
    if not source then return nil end
    if sourceType == "string" then return textureFromPath(source) end
    if sourceType ~= "table" then
        if sourceType == "userdata" then
            return nativeTexture(source) or source
        end
        return nil
    end

    local directNative = nativeTexture(source)
    if directNative then return directNative end

    local direct = source.texture or source.iconTexture
        or source.imageTexture
    if direct then
        local texture = resolve(direct)
        if texture then return texture end
    end

    local nativeInfo = source.nativeObjectInfo or source.objectInfo
    local texture = nativeTexture(nativeInfo)
    if texture then return texture end

    local paths = { source.iconPath, source.imagePath, source.path,
        source.iconName, source.image }
    for _, path in ipairs(paths) do
        texture = resolve(path)
        if texture then return texture end
    end
    return nil
end

function Resolver.Resolve(source)
    return resolve(source)
end

function Resolver.ResolveItemTexture(fullType)
    return itemTextureFromType(fullType)
end

function Resolver.Draw(element, source, x, y, width, height, alpha)
    local texture = resolve(source)
    if not texture or not element
        or type(element.drawTextureScaledAspect) ~= "function"
    then return texture end
    element:drawTextureScaledAspect(texture, x, y, width, height,
        tonumber(alpha) or 1, 1, 1, 1)
    return texture
end

function Resolver.DrawItemIcon(element, fullType, x, y, width, height, alpha)
    local texture = itemTextureFromType(fullType)
    if not texture or not element
        or type(element.drawTextureScaledAspect) ~= "function"
    then return texture end
    element:drawTextureScaledAspect(texture, x, y, width, height,
        tonumber(alpha) or 1, 1, 1, 1)
    return texture
end

function Resolver.ClearCache()
    for key in pairs(PATH_CACHE) do PATH_CACHE[key] = nil end
    for key in pairs(ITEM_TEXTURE_CACHE) do ITEM_TEXTURE_CACHE[key] = nil end
end

return Resolver
