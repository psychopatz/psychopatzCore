local function truthy(value, label)
    assert(value, label or "expected truthy")
    return value
end

local function falsy(value, label)
    assert(not value, label or "expected falsy")
end

local function equal(actual, expected, label)
    assert(actual == expected,
        (label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
end

local function contains(value, fragment, label)
    assert(string.find(tostring(value or ""), fragment, 1, true),
        (label or "contains") .. ": missing=" .. tostring(fragment))
end

PsychopatzCore = nil
getFileReader = nil
local savedText
getFileWriter = function()
    return {
        write = function(_, value) savedText = value end,
        close = function() end,
    }
end

local Settings = dofile(
    "Contents/mods/PsychopatzCore/common/media/lua/shared/"
        .. "PsychopatzCore/Debug/PsychopatzDebugSettings.lua"
)

local liveState = false
Settings.Register({
    id = "Test.Live",
    title = "Live setting",
    runtimeMutable = true,
    apply = function(enabled) liveState = enabled == true end,
})
Settings.Register({
    id = "Test.Restart",
    title = "Restart setting",
    runtimeMutable = false,
})

falsy(liveState, "live setting starts disabled")
truthy(Settings.Set("Test.Live", true, false), "stage live setting")
falsy(Settings.IsEnabled("Test.Live"), "staged value is not active")
truthy(Settings.IsPendingApply("Test.Live"), "live apply pending")

local applied, report = Settings.ApplyConfigured()
truthy(applied, "apply live setting")
truthy(liveState, "live callback applied")
equal(#report.applied, 1, "one live setting applied")

truthy(Settings.Set("Test.Restart", true, false), "stage restart setting")
local appliedAgain, reportAgain = Settings.ApplyConfigured()
truthy(appliedAgain, "apply with restart setting pending")
equal(#reportAgain.pendingRestart, 1, "restart setting remains pending")
falsy(Settings.IsEnabled("Test.Restart"), "restart value waits")
truthy(Settings.Save(), "save settings")
contains(savedText, "setting.Test.Live=true", "saved live value")
contains(savedText, "setting.Test.Restart=true", "saved restart value")

savedText = table.concat({
    "config_version=1",
    "setting.Test.Live=false",
    "setting.Test.Restart=true",
}, "\n")
local lines, lineIndex = {}, 0
for line in string.gmatch(savedText, "[^\n]+") do lines[#lines + 1] = line end
getFileReader = function()
    return {
        readLine = function()
            lineIndex = lineIndex + 1
            return lines[lineIndex]
        end,
        close = function() end,
    }
end

truthy(Settings.Reload(), "reload file")
truthy(Settings.IsEnabled("Test.Live"), "reload does not live apply")
truthy(Settings.IsPendingApply("Test.Live"), "reloaded live value pending")
local reloadedApplied = Settings.ApplyConfigured()
truthy(reloadedApplied, "apply reloaded value")
falsy(liveState, "reloaded live callback applied")
print("psychopatz debug settings smoke: ok")
