local Test = {}

local repository = os.getenv("PZ_TEST_CORE_REPOSITORY") or "."
local coreRuntime = os.getenv("PZ_TEST_CORE_RUNTIME") or "42.20"
local modRoot = repository .. "/Contents/mods/PsychopatzCore/"

local LAYER_ROOTS = {
    shared = modRoot .. "common/media/lua/shared/",
    client = modRoot .. coreRuntime .. "/media/lua/client/",
    server = modRoot .. coreRuntime .. "/media/lua/server/",
    common_shared = modRoot .. "common/media/lua/shared/",
    common_client = modRoot .. "common/media/lua/client/",
    common_server = modRoot .. "common/media/lua/server/",
    runtime_shared = modRoot .. coreRuntime .. "/media/lua/shared/",
    runtime_client = modRoot .. coreRuntime .. "/media/lua/client/",
    runtime_server = modRoot .. coreRuntime .. "/media/lua/server/",
}

function Test.runtime()
    return coreRuntime
end

function Test.repository()
    return repository
end

function Test.modRoot()
    return modRoot
end

function Test.layerRoot(layer)
    local root = LAYER_ROOTS[layer]
    if not root then
        error("unknown PsychopatzCore test layer: " .. tostring(layer), 2)
    end
    return root
end

function Test.path(layer, relative)
    return Test.layerRoot(layer) .. relative
end

function Test.addPackagePaths(...)
    local layers = { ... }
    if #layers == 0 then
        layers = {
            "common_shared",
            "common_client",
            "common_server",
            "runtime_shared",
            "runtime_client",
            "runtime_server",
        }
    end
    local prefixes = {}
    for i = 1, #layers do
        local root = Test.layerRoot(layers[i])
        prefixes[#prefixes + 1] = root .. "?.lua"
    end
    package.path = table.concat(prefixes, ";") .. ";" .. package.path
    return Test
end

function Test.load(layer, relative)
    return dofile(Test.path(layer, relative))
end

function Test.read(layerOrPath, relative)
    local target = relative and Test.path(layerOrPath, relative) or layerOrPath
    local handle, err = io.open(target, "r")
    if not handle then
        error("unable to read " .. tostring(target) .. ": " .. tostring(err), 2)
    end
    local content = handle:read("*a")
    handle:close()
    return content
end

function Test.equal(actual, expected, label)
    if actual ~= expected then
        error(string.format(
            "%s: expected %s, got %s",
            tostring(label or "equal"),
            tostring(expected),
            tostring(actual)
        ), 2)
    end
end

function Test.truthy(value, label)
    if not value then
        error(tostring(label or "expected truthy"), 2)
    end
end

function Test.falsy(value, label)
    if value then
        error(tostring(label or "expected falsy") .. ", got " .. tostring(value), 2)
    end
end

function Test.near(actual, expected, tolerance, label)
    local delta = math.abs((tonumber(actual) or 0) - (tonumber(expected) or 0))
    if delta > (tolerance or 1e-6) then
        error(string.format(
            "%s: expected %s (+/- %s), got %s",
            tostring(label or "near"),
            tostring(expected),
            tostring(tolerance or 1e-6),
            tostring(actual)
        ), 2)
    end
end

function Test.contains(haystack, needle, label)
    if type(haystack) ~= "string" or not string.find(haystack, needle, 1, true) then
        error(string.format(
            "%s: expected %q to contain %q",
            tostring(label or "contains"),
            tostring(haystack),
            tostring(needle)
        ), 2)
    end
end

function Test.ok(message)
    if os.getenv("PZ_TEST_VERBOSE") == "1" then
        print(message or "OK")
    end
end

return Test
