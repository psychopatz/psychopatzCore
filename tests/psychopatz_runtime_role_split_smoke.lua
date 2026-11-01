-- Smoke test for P7 Runtime-Role Split Enforcement

package.path = table.concat({
    "Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua",
    "Contents/mods/PsychopatzCore/42.20/media/lua/shared/?.lua",
    package.path,
}, ";")

local function run_role_test(testName, roleSetup, testBody)
    local script = string.format([[
        package.path = table.concat({
            "Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua",
            "Contents/mods/PsychopatzCore/42.20/media/lua/shared/?.lua",
            "Contents/mods/PsychopatzCore/common/media/lua/client/?.lua",
            "Contents/mods/PsychopatzCore/42.20/media/lua/client/?.lua",
            "Contents/mods/PsychopatzCore/42.20/media/lua/server/?.lua",
            package.path,
        }, ";")

        -- Role setup
        %s

        -- Mock events
        Events = setmetatable({}, {
            __index = function(t, k)
                local h = { Add = function() end, Remove = function() end }
                rawset(t, k, h)
                return h
            end
        })

        local Kernel = require "PsychopatzCore/Kernel/PC_Kernel"
        Kernel.InitCatalog()

        -- Test Body
        %s

        print("%s: ok")
    ]], roleSetup, testBody, testName)

    local f = io.open("/tmp/role_test.lua", "w")
    f:write(script)
    f:close()

    local res = os.execute("lua /tmp/role_test.lua")
    if res ~= 0 and res ~= true then
        error("Role test failed: " .. testName)
    end
end

-- 1. Dedicated Server Role Test
run_role_test("Dedicated Server Role", [[
    isServer = function() return true end
    isClient = function() return false end
]], [[
    -- Client-only capability must fail
    local okCli, errCli = Kernel.Require("core.radio_os", "ServerConsumer")
    assert(okCli == false, "Client-only capability should fail on dedicated server")
    assert(string.find(errCli, "not eligible", 1, true) ~= nil, "Should report not eligible")

    -- Server capability must succeed
    local okSrv, errSrv = Kernel.Require("core.currency_server", "ServerConsumer")
    assert(okSrv == true, "Server capability should succeed on dedicated server: " .. tostring(errSrv))

    -- Pack requiring abstract trading should filter out client-only radio_os without crashing
    local okPack, errPack = Kernel.RequirePack("pack.trading_abstract", "ServerConsumer")
    assert(okPack == true, "Pack activation should succeed on server via filtering: " .. tostring(errPack))
    local statusRadio = Kernel.GetStatus("core.radio_os")
    assert(statusRadio.state == "REGISTERED", "core.radio_os should remain REGISTERED on server, not loaded or active")
]])

-- 2. Pure Client Role Test
run_role_test("Pure Client Role", [[
    isServer = function() return false end
    isClient = function() return true end
]], [[
    -- Server-only capability must fail
    local okSrv, errSrv = Kernel.Require("core.currency_server", "ClientConsumer")
    assert(okSrv == false, "Server-only capability should fail on pure client")
    assert(string.find(errSrv, "not eligible", 1, true) ~= nil, "Should report not eligible")

    -- Client capability must succeed
    local okCli, errCli = Kernel.Require("core.preview", "ClientConsumer")
    assert(okCli == true, "Client capability should succeed on client: " .. tostring(errCli))
]])

print("psychopatz runtime role split smoke: ok")
