local SHARED_ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
local MODULE = "PsychopatzCore/Compatibility/PsychopatzMoneyWeight"
package.path = SHARED_ROOT .. "?.lua;" .. package.path

local function runRole(role)
    local items = {
        ["Base.Money"] = { weight = 0.5 },
        ["Base.MoneyBundle"] = { weight = 5.0 },
    }
    local manager = {}

    for _, item in pairs(items) do
        function item:setActualWeight(weight)
            self.weight = weight
        end
        function item:getActualWeight()
            return self.weight
        end
    end

    function manager:getItem(fullType)
        return items[fullType]
    end

    function getScriptManager()
        return manager
    end

    isClient = function() return role == "multiplayer_client" end
    isServer = function() return role == "multiplayer_server" end
    Events = {}
    PsychopatzCore = {}
    package.loaded[MODULE] = nil

    local MoneyWeight = require(MODULE)
    assert(MoneyWeight.GetStatus().applied, role .. " patch status")
    assert(items["Base.Money"].weight == 0.0,
        role .. " Base.Money weight")
    assert(items["Base.MoneyBundle"].weight == 0.0,
        role .. " Base.MoneyBundle weight")
end

runRole("singleplayer")
runRole("multiplayer_server")
runRole("multiplayer_client")

print("psychopatz money weight roles smoke: ok")
