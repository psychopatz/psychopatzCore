-- Smoke test for P3 Dynamic Trading Vertical Slice
-- Proves demand-driven Core activation across representative configurations.

local function run_config_test(configName, setupFn, assertionsFn)
    -- Run each configuration in an isolated subprocess to ensure pristine package.loaded
    local script = string.format([[
        package.path = table.concat({
            "Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua",
            "Contents/mods/PsychopatzCore/42.20/media/lua/shared/?.lua",
            "Contents/mods/PsychopatzCore/common/media/lua/client/?.lua",
            "Contents/mods/PsychopatzCore/42.20/media/lua/client/?.lua",
            "Contents/mods/PsychopatzCore/42.20/media/lua/server/?.lua",
            "/home/psychopatz/Zomboid/Workshop/DynamicTrading/Contents/mods/DTCommon/common/media/lua/shared/?.lua",
            "/home/psychopatz/Zomboid/Workshop/DynamicTrading/Contents/mods/DTCommon/42.20/media/lua/shared/?.lua",
            "/home/psychopatz/Zomboid/Workshop/DynamicTrading/Contents/mods/DTCommon/common/media/lua/client/?.lua",
            "/home/psychopatz/Zomboid/Workshop/DynamicTrading/Contents/mods/DTCommon/42.20/media/lua/client/?.lua",
            "/home/psychopatz/Zomboid/Workshop/DynamicTrading/Contents/mods/DTAbstract/common/media/lua/shared/?.lua",
            "/home/psychopatz/Zomboid/Workshop/DynamicTrading/Contents/mods/DTAbstract/42.20/media/lua/shared/?.lua",
            "/home/psychopatz/Zomboid/Workshop/DynamicTrading/Contents/mods/DTAbstract/common/media/lua/client/?.lua",
            "/home/psychopatz/Zomboid/Workshop/DynamicTrading/Contents/mods/DTAbstract/42.20/media/lua/client/?.lua",
            "/home/psychopatz/Zomboid/Workshop/DynamicTrading/Contents/mods/DTHoomans/42.20/media/lua/shared/?.lua",
            "/home/psychopatz/Zomboid/Workshop/DynamicTrading/Contents/mods/DTHoomans/42.20/media/lua/client/?.lua",
            "/home/psychopatz/Zomboid/Workshop/DynamicTrading/Contents/mods/DTHoomans/42.20/media/lua/server/?.lua",
            "/home/psychopatz/Zomboid/Workshop/ProjectHoomans/Contents/mods/ProjectHoomans/common/media/lua/shared/?.lua",
            "/home/psychopatz/Zomboid/Workshop/ProjectHoomans/Contents/mods/ProjectHoomans/42.20/media/lua/shared/?.lua",
            "/home/psychopatz/Zomboid/Workshop/ProjectHoomans/Contents/mods/ProjectHoomans/common/media/lua/client/?.lua",
            "/home/psychopatz/Zomboid/Workshop/ProjectHoomans/Contents/mods/ProjectHoomans/42.20/media/lua/client/?.lua",
            "/home/psychopatz/Zomboid/Workshop/ProjectHoomans/Contents/mods/ProjectHoomans/42.20/media/lua/server/?.lua",
            package.path,
        }, ";")

        -- PZ Globals stub
        Events = setmetatable({}, {
            __index = function(t, k)
                local handler = {
                    Add = function(cb) end,
                    Remove = function(cb) end,
                }
                rawset(t, k, handler)
                return handler
            end
        })
        isClient = function() return false end
        isServer = function() return false end
        getText = function(s) return s end
        getPlayer = function() return nil end

        -- Setup
        %s

        -- Assertions
        %s

        print("%s: ok")
    ]], setupFn, assertionsFn, configName)

    local f = io.open("/tmp/p3_test.lua", "w")
    f:write(script)
    f:close()

    local res = os.execute("lua /tmp/p3_test.lua")
    if res ~= 0 and res ~= true then
        error("Config test failed for: " .. configName)
    end
end

-- Config 1: Core Alone
run_config_test("Config 1 (Core Alone)", [[
    local Core = require "PsychopatzCore/00_PsychopatzCore_Init"
]], [[
    assert(PsychopatzCore ~= nil, "PsychopatzCore missing")
    assert(PsychopatzCore.Capabilities ~= nil, "Capabilities missing")

    -- Unrequested features must NOT be in package.loaded
    local unrequested = {
        "PsychopatzCore/Traits/PsychopatzTraitRegistry",
        "PsychopatzCore/Traits/PsychopatzTraitRecovery",
        "PsychopatzCore/ZombieKillDetector/PsychopatzZombieKillDetector",
        "PsychopatzCore/Animation/PsychopatzPlayerAnimationController",
        "PsychopatzCore/WorldLoot/PsychopatzWorldLoot",
        "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOS",
    }
    for _, mod in ipairs(unrequested) do
        assert(package.loaded[mod] == nil, "module '" .. mod .. "' should NOT be loaded in Core Alone!")
    end

    local status = PsychopatzCore.Capabilities.GetStatus("core.traits")
    assert(status ~= nil and status.state == "REGISTERED", "core.traits should be REGISTERED, not active")
]])

-- Config 2: Core + DTCommon
run_config_test("Config 2 (Core + DTCommon)", [[
    local Core = require "PsychopatzCore/00_PsychopatzCore_Init"
    local DTCommon = require "DTCommon/00_DTCommon_Init"
]], [[
    assert(DTCommon ~= nil, "DTCommon missing")

    -- Inventory and Currency should be loaded and active
    local invStatus = PsychopatzCore.Capabilities.GetStatus("core.inventory")
    assert(invStatus.state == "ACTIVE" or invStatus.state == "LOADED", "core.inventory should be ACTIVE or LOADED")

    -- Unrelated Core features must remain strictly UNLOADED
    local unrelated = {
        "PsychopatzCore/Traits/PsychopatzTraitRegistry",
        "PsychopatzCore/Traits/PsychopatzTraitRecovery",
        "PsychopatzCore/ZombieKillDetector/PsychopatzZombieKillDetector",
        "PsychopatzCore/Animation/PsychopatzPlayerAnimationController",
        "PsychopatzCore/WorldLoot/PsychopatzWorldLoot",
        "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOS",
    }
    for _, mod in ipairs(unrelated) do
        assert(package.loaded[mod] == nil, "unrelated module '" .. mod .. "' should NOT be loaded in Core + DTCommon!")
    end

    local traitsStatus = PsychopatzCore.Capabilities.GetStatus("core.traits")
    assert(traitsStatus.state == "REGISTERED", "core.traits should remain REGISTERED")
]])

-- Config 3: Core + DTCommon + DTAbstract
run_config_test("Config 3 (Core + DTCommon + DTAbstract)", [[
    local Core = require "PsychopatzCore/00_PsychopatzCore_Init"
    local DTCommon = require "DTCommon/00_DTCommon_Init"
    local DTAbstract = require "DTAbstract/00_DTAbstract_Init"
]], [[
    assert(DTAbstract ~= nil, "DTAbstract missing")

    -- Unrelated Core features still remain strictly UNLOADED
    local unrelated = {
        "PsychopatzCore/Traits/PsychopatzTraitRegistry",
        "PsychopatzCore/Traits/PsychopatzTraitRecovery",
        "PsychopatzCore/ZombieKillDetector/PsychopatzZombieKillDetector",
        "PsychopatzCore/Animation/PsychopatzPlayerAnimationController",
        "PsychopatzCore/WorldLoot/PsychopatzWorldLoot",
    }
    for _, mod in ipairs(unrelated) do
        assert(package.loaded[mod] == nil, "unrelated module '" .. mod .. "' should NOT be loaded in Core + DTAbstract!")
    end
]])

-- Config 4: Core + Hoomans without Dynamic Trading
run_config_test("Config 4 (Core + Hoomans without Dynamic Trading)", [[
    local Core = require "PsychopatzCore/00_PsychopatzCore_Init"
    local Hoomans = require "PNC/00_PNC_Init"
]], [[
    assert(Hoomans ~= nil or PNC ~= nil, "Hoomans missing")
    -- Dynamic Trading modules must NOT be loaded
    assert(package.loaded["DTCommon/00_DTCommon_Init"] == nil, "DTCommon should NOT be loaded in Hoomans without DT")
    assert(package.loaded["DTAbstract/00_DTAbstract_Init"] == nil, "DTAbstract should NOT be loaded in Hoomans without DT")
]])

-- Config 5: Core + DTCommon + Hoomans + DTHoomans
run_config_test("Config 5 (Core + DTCommon + Hoomans + DTHoomans)", [[
    local Core = require "PsychopatzCore/00_PsychopatzCore_Init"
    local DTCommon = require "DTCommon/00_DTCommon_Init"
    local PNC_Conv = require "PNC/00_PNC_Conversation_Init"
    local Hoomans = require "PNC/00_PNC_Init"
    local DTHoomans = require "DTHoomans/00_DTHoomans_Init"
]], [[
    assert(DTHoomans ~= nil, "DTHoomans missing")
    assert(DTCommon ~= nil, "DTCommon missing")
]])

print("psychopatz dt slice smoke: all configurations ok")
