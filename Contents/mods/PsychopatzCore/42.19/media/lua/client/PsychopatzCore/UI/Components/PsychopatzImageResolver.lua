PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.UI = PsychopatzCore.UI or {}

local UI = PsychopatzCore.UI
local Resolver = UI.ImageResolver or {}
UI.ImageResolver = Resolver
local PATH_CACHE = {}
local ITEM_TEXTURE_CACHE = {}

local function safeCall(target, methodName, ...)
    if not target then return nil end

    local okMethod, method = pcall(function()
        return target[methodName]
    end)
    if not okMethod or not method then return nil end

    local ok, value = pcall(method, target, ...)
    return ok and value or nil
end

local function isUsableTexture(texture)
    if not texture or type(texture) == "string" then return false end

    -- getItemTex() can return PZ's question-mark texture for an item whose
    -- normal texture is not registered.  Treat that as a miss so the script
    -- icon and InventoryItemFactory fallbacks still get a chance to resolve
    -- the actual item art.
    local name = safeCall(texture, "getName")
    if name then
        name = string.lower(tostring(name))
        if name == "question_highlight" or name == "questionmark"
            or name == "question_mark"
        then
            return false
        end
    end
    return true
end

local function textureFromPath(path)
    path = tostring(path or "")
    if path == "" then return nil end
    local cached = PATH_CACHE[path]
    if cached ~= nil then return cached ~= false and cached or nil end
    if tryGetTexture then
        local ok, texture = pcall(tryGetTexture, path)
        texture = ok and isUsableTexture(texture) and texture or nil
        if texture then
            PATH_CACHE[path] = texture
            return texture
        end
    end
    if getTexture then
        local ok, texture = pcall(getTexture, path)
        texture = ok and isUsableTexture(texture) and texture or nil
        if texture then
            PATH_CACHE[path] = texture
            return texture
        end
    end
    PATH_CACHE[path] = false
    return nil
end

local function coerceTexture(value)
    if type(value) == "string" then
        return textureFromPath(value)
    end
    return isUsableTexture(value) and value or nil
end

local function appendUnique(list, value)
    value = tostring(value or "")
    if value == "" then return end

    for _, existing in ipairs(list) do
        if existing == value then return end
    end
    list[#list + 1] = value
end

local function appendIconVariants(list, rawIcon)
    rawIcon = tostring(rawIcon or "")
    if rawIcon == "" then return end

    rawIcon = string.gsub(rawIcon, "^%s+", "")
    rawIcon = string.gsub(rawIcon, "%s+$", "")
    if rawIcon == "" then return end

    appendUnique(list, rawIcon)

    local iconName = string.gsub(rawIcon, "^media/textures/", "")
    iconName = string.gsub(iconName, "%.png$", "")
    appendUnique(list, iconName)

    local itemIcon = iconName
    if string.sub(itemIcon, 1, 5) ~= "Item_" then
        itemIcon = "Item_" .. itemIcon
    end
    appendUnique(list, itemIcon)
    appendUnique(list, "media/textures/" .. itemIcon .. ".png")
end

local function appendIconCollection(list, rawIcons)
    if not rawIcons then return end

    if type(rawIcons) == "string" then
        for rawIcon in string.gmatch(rawIcons, "([^;]+)") do
            appendIconVariants(list, rawIcon)
        end
        return
    end

    if type(rawIcons) == "table" then
        for _, rawIcon in ipairs(rawIcons) do
            appendIconVariants(list, rawIcon)
        end
        return
    end

    local size = tonumber(safeCall(rawIcons, "size")) or 0
    for index = 0, size - 1 do
        appendIconVariants(list, safeCall(rawIcons, "get", index))
    end
end

local function getScriptItem(fullType)
    local manager
    if type(getScriptManager) == "function" then
        local ok, result = pcall(getScriptManager)
        if ok then manager = result end
    end
    if not manager and ScriptManager and ScriptManager.instance then
        manager = ScriptManager.instance
    end
    return safeCall(manager, "getItem", fullType)
end

local function resolveScriptItemTexture(fullType)
    local scriptItem = getScriptItem(fullType)
    if not scriptItem then return nil end

    local texture = coerceTexture(safeCall(scriptItem, "getNormalTexture"))
        or coerceTexture(safeCall(scriptItem, "getIconTexture"))
    if texture then return texture end

    local icons = {}
    appendIconCollection(icons, safeCall(scriptItem, "getIcon"))
    appendIconCollection(icons, safeCall(scriptItem, "getIconsForTexture"))
    appendIconCollection(icons, safeCall(scriptItem, "getIconsForTextures"))
    appendIconCollection(icons, safeCall(scriptItem, "getClothingItem"))

    for _, icon in ipairs(icons) do
        texture = textureFromPath(icon)
        if texture then return texture end
    end
    return nil
end

local function resolveInventoryItemTexture(fullType)
    if not InventoryItemFactory then
        return nil
    end

    local item
    local ok
    for _, creator in ipairs({ "CreateItem", "instanceItem" }) do
        local method = InventoryItemFactory[creator]
        if type(method) == "function" then
            ok, item = pcall(method, fullType)
            if ok and item then break end
        end
    end
    if not item and InventoryItemFactory.instance then
        item = safeCall(InventoryItemFactory.instance, "CreateItem", fullType)
            or safeCall(InventoryItemFactory.instance, "instanceItem", fullType)
    end
    if not item and type(instanceItem) == "function" then
        ok, item = pcall(instanceItem, fullType)
    end
    if not item then return nil end

    local texture = coerceTexture(safeCall(item, "getTex"))
        or coerceTexture(safeCall(item, "getTexture"))
    if texture then return texture end

    local icon = safeCall(item, "getIcon")
    if type(icon) == "string" then
        local icons = {}
        appendIconVariants(icons, icon)
        for _, iconPath in ipairs(icons) do
            texture = textureFromPath(iconPath)
            if texture then return texture end
        end
    elseif icon then
        return coerceTexture(icon)
    end
    return nil
end

local function itemTextureFromType(fullType)
    fullType = tostring(fullType or "")
    if fullType == "" then return nil end
    local cached = ITEM_TEXTURE_CACHE[fullType]
    if cached ~= nil then return cached ~= false and cached or nil end

    local texture
    if type(getItemTex) == "function" then
        local ok, result = pcall(getItemTex, fullType)
        if ok then texture = coerceTexture(result) end
    end
    if texture then
        ITEM_TEXTURE_CACHE[fullType] = texture
        return texture
    end

    texture = resolveScriptItemTexture(fullType)
    if not texture then
        texture = resolveInventoryItemTexture(fullType)
    end
    if texture then
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
