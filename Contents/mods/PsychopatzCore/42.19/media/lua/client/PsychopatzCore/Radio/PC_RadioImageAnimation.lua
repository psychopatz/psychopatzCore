-- Small, dependency-free image animator for radio UIs.
--
-- Dynamic Trading's radio scanner uses these shared media paths:
--   media/ui/Radio/Signal_found/2.png       idle/off
--   media/ui/Radio/Signal_search/1..5.png  active/search loop
-- Keep the paths configurable so other mods can reuse the controller without
-- depending on Dynamic Trading's Lua modules. Missing textures fall back to
-- the supplied item icon instead of making the consuming UI disappear.

PsychopatzCore = PsychopatzCore or {}

local Animation = PsychopatzCore.RadioImageAnimation or {}
PsychopatzCore.RadioImageAnimation = Animation

Animation.MEDIA_ROOT = Animation.MEDIA_ROOT or "media/ui/Radio/"
Animation.FOUND_PREFIX = Animation.FOUND_PREFIX
    or Animation.MEDIA_ROOT .. "Signal_found/"
Animation.NONE_PREFIX = Animation.NONE_PREFIX
    or Animation.MEDIA_ROOT .. "Signal_none/"
Animation.SEARCH_PREFIX = Animation.SEARCH_PREFIX
    or Animation.MEDIA_ROOT .. "Signal_search/"
Animation.OFF_PATH = Animation.OFF_PATH
    or Animation.FOUND_PREFIX .. "2.png"
Animation.SEARCH_FRAME_COUNT = tonumber(Animation.SEARCH_FRAME_COUNT) or 5
Animation.FRAME_DURATION = tonumber(Animation.FRAME_DURATION) or 200
Animation.textureCache = Animation.textureCache or {}

function Animation.SignalPath(state, frame)
    state = tostring(state or "")
    frame = math.max(1, math.floor(tonumber(frame) or 1))
    if state == "found" then
        return Animation.FOUND_PREFIX .. tostring(frame) .. ".png"
    elseif state == "none" then
        return Animation.NONE_PREFIX .. tostring(frame) .. ".png"
    elseif state == "search" then
        return Animation.SEARCH_PREFIX .. tostring(frame) .. ".png"
    end
    return nil
end

local Controller = {}
Controller.__index = Controller

local function now()
    if getTimestampMs then return getTimestampMs() end
    if getTimeInMillis then return getTimeInMillis() end
    return 0
end

local function texture(path)
    if type(path) ~= "string" or path == "" or not getTexture then
        return nil
    end
    local cached = Animation.textureCache[path]
    if cached ~= nil then return cached end
    cached = getTexture(path)
    -- Texture atlases can become available after the first UI pass. Keep a
    -- miss retryable instead of poisoning the shared cache with false.
    if cached then Animation.textureCache[path] = cached end
    return cached
end

local function resolve(value, self, active)
    if type(value) == "function" then
        value = value(self, active)
    end
    if type(value) == "string" then return texture(value) end
    return value
end

function Animation.New(options)
    options = type(options) == "table" and options or {}
    local object = setmetatable({
        searchPrefix = tostring(options.searchPrefix
            or Animation.SEARCH_PREFIX),
        offPath = tostring(options.offPath or Animation.OFF_PATH),
        frameCount = math.max(1, math.floor(tonumber(options.frameCount)
            or Animation.SEARCH_FRAME_COUNT)),
        frameDuration = math.max(1, math.floor(tonumber(options.frameDuration)
            or Animation.FRAME_DURATION)),
        onFallback = options.onFallback,
        offFallback = options.offFallback,
        active = nil,
        activeSince = nil,
        lastPath = nil,
        lastTexture = nil,
    }, Controller)
    return object
end

Animation.new = Animation.New

function Controller:Reset(active, at)
    self.active = active == true
    self.activeSince = tonumber(at) or now()
    self.lastPath = nil
    self.lastTexture = nil
end

function Controller:SetActive(active, at)
    active = active == true
    if self.active == nil or self.active ~= active then
        self:Reset(active, at)
    elseif self.activeSince == nil then
        self.activeSince = tonumber(at) or now()
    end
    return self.active
end

function Controller:GetFrame(active, at)
    at = tonumber(at) or now()
    self:SetActive(active, at)
    if not self.active then return 2 end
    local elapsed = math.max(0, at - (self.activeSince or at))
    return math.floor(elapsed / self.frameDuration) % self.frameCount + 1
end

function Controller:GetPath(active, at)
    local frame = self:GetFrame(active, at)
    if not self.active then return self.offPath end
    return self.searchPrefix .. tostring(frame) .. ".png"
end

function Controller:GetTexture(active, at)
    local path = self:GetPath(active, at)
    if path == self.lastPath then
        return self.lastTexture or resolve(
            self.active and self.onFallback or self.offFallback,
            self, self.active
        )
    end

    self.lastPath = path
    self.lastTexture = texture(path)
    if self.lastTexture then return self.lastTexture end
    return resolve(self.active and self.onFallback or self.offFallback,
        self, self.active)
end

return Animation
