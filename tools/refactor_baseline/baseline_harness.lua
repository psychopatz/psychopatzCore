-- Baseline dynamic execution harness for PsychopatzCore
-- Records module load edges and require-time callback registrations.

local role = arg and arg[1] or "shared" -- "shared", "client", or "server"

local SHARED_COMMON = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
local SHARED_42 = "Contents/mods/PsychopatzCore/42.20/media/lua/shared/"
local CLIENT_COMMON = "Contents/mods/PsychopatzCore/common/media/lua/client/"
local CLIENT_42 = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
local SERVER_42 = "Contents/mods/PsychopatzCore/42.20/media/lua/server/"

package.path = table.concat({
    SHARED_COMMON .. "?.lua",
    SHARED_42 .. "?.lua",
    CLIENT_COMMON .. "?.lua",
    CLIENT_42 .. "?.lua",
    SERVER_42 .. "?.lua",
    package.path,
}, ";")

-- Mock class creator for ISUI elements
local function makeClassStub(className)
    local c = {}
    c.__index = c
    c._className = className
    function c:derive(name)
        local sub = setmetatable({}, { __index = c })
        sub.__index = sub
        sub._className = name or (c._className .. "_derived")
        return sub
    end
    function c:new(...)
        local inst = setmetatable({}, self)
        return inst
    end
    return c
end

local isui_classes = {
    "ISUIElement", "ISPanel", "ISButton", "ISLabel", "ISRichTextPanel",
    "ISScrollingListBox", "ISTextEntryBox", "ISComboBox", "ISRadioWindow",
    "ISModalRichText", "ISCollapsableWindow", "ISWidgetWindow", "ISImage",
    "ISInventoryPane", "ISInventoryPage", "ISToolTip"
}

for _, cls in ipairs(isui_classes) do
    local stub = makeClassStub(cls)
    _G[cls] = stub
    package.preload["ISUI/" .. cls] = function() return stub end
end
package.preload["RadioCom/ISRadioWindow"] = function() return makeClassStub("ISRadioWindow") end

-- Environment mocks
isClient = function() return role == "client" end
isServer = function() return role == "server" end
getText = function(key) return key end
getPlayer = function() return nil end
getSpecificPlayer = function() return nil end
getTimeInMillis = function() return 1000 end
SandboxVars = SandboxVars or {}
ZomboidFileSystem = {
    instance = {
        getString = function() return "" end
    }
}
getActivatedMods = function()
    local mods = { "PsychopatzCore" }
    local t = {}
    t.size = function() return #mods end
    t.get = function(_, idx) return mods[idx + 1] end
    return t
end
getModFileReader = function() return nil end
getModFileWriter = function() return nil end
getFileReader = function() return nil end
getFileWriter = function() return nil end

-- Instrumentation storage
local load_edges = {}
local modules_loaded = {}
local registered_events = {}
local require_stack = {}
local orig_require = require

_G.require = function(mod)
    local caller = require_stack[#require_stack] or "<root>"
    local edge = { caller = caller, callee = mod }
    table.insert(load_edges, edge)

    local already_loaded = package.loaded[mod] ~= nil
    if not already_loaded then
        table.insert(modules_loaded, {
            module = mod,
            caller = caller,
            depth = #require_stack,
        })
    end

    table.insert(require_stack, mod)
    local ok, res = pcall(orig_require, mod)
    table.remove(require_stack)

    if not ok then
        error(res)
    end
    return res
end

Events = setmetatable({}, {
    __index = function(t, eventName)
        local handler = {
            Add = function(fn)
                local currentMod = require_stack[#require_stack]
                local info = debug.getinfo(2, "Sl")
                local loc = (info and info.short_src and info.currentline)
                    and (info.short_src .. ":" .. info.currentline)
                    or "unknown"
                table.insert(registered_events, {
                    action = "Add",
                    event = eventName,
                    module = currentMod or "<unattributed>",
                    attributed = currentMod ~= nil,
                    loc = loc,
                    role = role,
                })
            end,
            Remove = function(fn)
                local currentMod = require_stack[#require_stack]
                local info = debug.getinfo(2, "Sl")
                local loc = (info and info.short_src and info.currentline)
                    and (info.short_src .. ":" .. info.currentline)
                    or "unknown"
                table.insert(registered_events, {
                    action = "Remove",
                    event = eventName,
                    module = currentMod or "<unattributed>",
                    attributed = currentMod ~= nil,
                    loc = loc,
                    role = role,
                })
            end,
        }
        rawset(t, eventName, handler)
        return handler
    end
})

-- Now run the target bootstrap
local target_entry = "PsychopatzCore/00_PsychopatzCore_Init"
if role == "client" then
    -- PZ loads shared first, then client
    local ok_shared, err_shared = pcall(require, "PsychopatzCore/00_PsychopatzCore_Init")
    if not ok_shared then
        io.stderr:write("Error loading shared in client role: " .. tostring(err_shared) .. "\n")
    end
    target_entry = "PsychopatzCore/00_PsychopatzCore_Client_Init"
elseif role == "server" then
    -- PZ loads shared first, then server
    local ok_shared, err_shared = pcall(require, "PsychopatzCore/00_PsychopatzCore_Init")
    if not ok_shared then
        io.stderr:write("Error loading shared in server role: " .. tostring(err_shared) .. "\n")
    end
    target_entry = "PsychopatzCore/00_PsychopatzCore_Server_Init"
end

local ok, err = pcall(require, target_entry)

-- Simple JSON encoder for output
local function escape_str(s)
    s = s:gsub("\\", "\\\\")
    s = s:gsub("\"", "\\\"")
    s = s:gsub("\n", "\\n")
    s = s:gsub("\r", "\\r")
    s = s:gsub("\t", "\\t")
    return s
end

local function to_json(val)
    local t = type(val)
    if t == "string" then
        return "\"" .. escape_str(val) .. "\""
    elseif t == "number" or t == "boolean" then
        return tostring(val)
    elseif t == "nil" then
        return "null"
    elseif t == "table" then
        local is_array = false
        local n = #val
        if n > 0 or next(val) == nil then
            is_array = true
            for k, _ in pairs(val) do
                if type(k) ~= "number" or k < 1 or k > n or math.floor(k) ~= k then
                    is_array = false
                    break
                end
            end
        end

        local parts = {}
        if is_array then
            for i = 1, n do
                parts[#parts + 1] = to_json(val[i])
            end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            for k, v in pairs(val) do
                parts[#parts + 1] = "\"" .. escape_str(tostring(k)) .. "\":" .. to_json(v)
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    end
    return "\"<" .. t .. ">\""
end

local report = {
    role = role,
    success = ok,
    error = not ok and tostring(err) or nil,
    target = target_entry,
    module_count = #modules_loaded,
    edge_count = #load_edges,
    event_count = #registered_events,
    modules = modules_loaded,
    edges = load_edges,
    events = registered_events,
}

print("===BASELINE_JSON_START===")
print(to_json(report))
print("===BASELINE_JSON_END===")
