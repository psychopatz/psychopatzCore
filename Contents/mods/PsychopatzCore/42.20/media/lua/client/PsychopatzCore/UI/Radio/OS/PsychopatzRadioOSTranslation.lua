-- Core-owned translation facade for the reusable Radio OS.
-- Custom keys stay behind PsychopatzCore's shared catalog manager.

local loaded, Translation = pcall(require,
    "PsychopatzCore/Translation/PsychopatzCoreTranslation")
if not loaded or type(Translation) ~= "table" then Translation = nil end

local M = {}

function M.Get(key, fallback)
    if Translation and type(Translation.GetKey) == "function" then
        return Translation.GetKey(key, fallback)
    end
    return fallback or key or ""
end

function M.Format(key, fallback, ...)
    if Translation and type(Translation.FormatKey) == "function" then
        return Translation.FormatKey(key, fallback, { ... })
    end
    local value = fallback or key or ""
    local ok, formatted = pcall(string.format, value, ...)
    return ok and formatted or value
end

return M
