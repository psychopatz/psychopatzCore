local CORE_ROOT = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
local DT_ROOT = "../DynamicTrading/Contents/mods/DTCommon/common/media/lua/shared/"
package.path = CORE_ROOT .. "?.lua;" .. DT_ROOT .. "?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. " expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

-- 1. PsychopatzSpatialRelation.RelativeToIsometricScreen
local Relation = require "PsychopatzCore/Spatial/PsychopatzSpatialRelation"
local origin = { x = 100, y = 100, z = 0 }

local rRight = Relation.RelativeToIsometricScreen(origin, { x = 110, y = 90, z = 0 })
equal(rRight.relativeSector8, "RIGHT", "NE is screen RIGHT")
equal(rRight.clockToken, "CLOCK_03", "NE is 3 o'clock on isometric screen")

local rLeft = Relation.RelativeToIsometricScreen(origin, { x = 90, y = 110, z = 0 })
equal(rLeft.relativeSector8, "LEFT", "SW is screen LEFT")
equal(rLeft.clockToken, "CLOCK_09", "SW is 9 o'clock on isometric screen")

local rUp = Relation.RelativeToIsometricScreen(origin, { x = 90, y = 90, z = 0 })
equal(rUp.relativeSector8, "AHEAD", "NW is screen AHEAD")
equal(rUp.clockToken, "CLOCK_12", "NW is 12 o'clock on isometric screen")

local rDown = Relation.RelativeToIsometricScreen(origin, { x = 110, y = 110, z = 0 })
equal(rDown.relativeSector8, "BEHIND", "SE is screen BEHIND")
equal(rDown.clockToken, "CLOCK_06", "SE is 6 o'clock on isometric screen")

-- 2. PsychopatzCore ConvoDSL + DynamicTrading trader story & ActorSocialAuthority relationship commit
local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local Authority = Actors.SocialAuthority
local ConvoDSL = require "PsychopatzCore/ConvoEngine/ConvoDSL/ConvoDSL"
local DTAdapter = require "DTCommon/ConvoEngine/DTCommon_ConvoDSLAdapter"

local storyPath = "../DynamicTrading/Contents/mods/DTCommon/common/media/translation/EN/ConvoBlocks/branches/story_trader_social.convo"
local fh = assert(io.open(storyPath, "r"), "story_trader_social.convo exists")
local rawText = fh:read("*a")
fh:close()

local script, parseErr = ConvoDSL.ParseText(rawText, storyPath, "EN")
equal(parseErr, nil, "story_trader_social.convo parses cleanly with zero ProjectHoomans dependency")
local _, _, _, _, storyCount = ConvoDSL.ApplyScripts({ script }, "EN")
truthy(storyCount and storyCount >= 1, "trader story compiled into PsychopatzCore ConvoDSL")

local registry = Actors.NewRegistry()
local core = { Actors = { DefaultRegistry = registry } }
local traderActor, createErr = registry:Create({
    actorId = "dt:trader:caravan_1",
    identitySeed = "dt-trader-1",
})
truthy(traderActor, createErr)

local warmTrader = {
    actorID = traderActor.actorId,
    social = {
        personality = {
            socialStyle = "warm",
            compassion = 0.85,
            sociability = 0.80,
            materialism = 0.45,
            aggression = 0.15,
            bravery = 0.50,
            forgiveness = 0.80,
            loyalty = 0.70,
        },
    },
}

-- Player picks fair_deal -> warm trader grants approval +3, respect +2, familiarity +2, trade.discount +5
local reaction, okApplied, info = DTAdapter.ResolveAndApplyReaction(
    "convo.trader.social_exchange",
    "cfair_deal",
    warmTrader,
    "player:char:buyer1",
    {},
    { core = core }
)
truthy(reaction ~= nil, "warm trader resolves fair_deal reaction")
truthy(okApplied == true, "trader relationship deltas committed to PsychopatzCore ActorSocialAuthority")
equal(info.deltas.approval, 3, "warm trader approval delta is +3")
equal(info.deltas.respect, 2, "warm trader respect delta is +2")
equal(info.deltas.familiarity, 2, "warm trader familiarity delta is +2")

local socialAfter = Authority.GetSocial(traderActor.actorId, core)
local rel = socialAfter and socialAfter.relationships["player:char:buyer1"]
truthy(rel ~= nil, "persisted Core relationship record created for DynamicTrading trader")
equal(rel.approval, 3, "persisted trader approval == 3")
equal(rel.respect, 2, "persisted trader respect == 2")
equal(rel.familiarity, 2, "persisted trader familiarity == 2")

-- Aggressive trader reacting to accuse_gouging opens conflict follow-up + applies negative approval
local aggTrader = {
    actorID = traderActor.actorId,
    social = {
        personality = {
            socialStyle = "hostile",
            compassion = 0.15,
            aggression = 0.90,
            bravery = 0.80,
            forgiveness = 0.10,
            materialism = 0.85,
        },
    },
}
local aggReaction, okAgg = DTAdapter.ResolveAndApplyReaction(
    "convo.trader.social_exchange",
    "caccuse_gouging",
    aggTrader,
    "player:char:buyer1",
    { speakerStyle = "aggressive" },
    { core = core }
)
truthy(okAgg == true, "aggressive trader conflict deltas committed")
truthy(aggReaction.followUpOffers ~= nil and #aggReaction.followUpOffers == 2,
    "aggressive trader opens apologize vs walk_away_clash follow-up")

local socialAfterConflict = Authority.GetSocial(traderActor.actorId, core)
local relAfterConflict = socialAfterConflict.relationships["player:char:buyer1"]
equal(relAfterConflict.approval, -1, "approval updated organically from +3 to -1 after gouging clash")

-- Autonomous NPC/trader choice selection works identically via DTAdapter
local warmPick = DTAdapter.PickAutonomousChoice(
    "convo.trader.social_exchange", "start", warmTrader, { relationshipState = "friend" }, { deterministic = true }
)
equal(warmPick.id, "convo.trader.social_exchange.fair_deal", "warm trader autonomously picks fair_deal")

local greedyPick = DTAdapter.PickAutonomousChoice(
    "convo.trader.social_exchange", "start",
    { social = { personality = { materialism = 0.95, bravery = 0.8, compassion = 0.3, aggression = 0.3 } } },
    {}, { deterministic = true }
)
equal(greedyPick.id, "convo.trader.social_exchange.haggle_firm", "materialistic actor autonomously picks haggle_firm")

-- 3. Non-reentrant ConvoDSL streaming (prevents Kahlua2 stack overflow when Catalog.Get calls EnsurePoolLoaded)
do
    local Loader = ConvoDSL.Loader
    local savedList = _G.listFilesInModDirectory
    local savedReader = _G.getModFileReader
    local savedMods = _G.getActivatedMods
    local savedTargets = {}
    for k, v in pairs(Loader._targets) do savedTargets[k] = v end

    local files = {}
    local fileNames = {}
    files["pool_00_base.convo"] = table.concat({
        "language EN",
        "namespace test",
        "dialogue semantic.test.stream",
        '  say [default] as base_line:',
        '    "Base stream line."',
    }, "\n")
    fileNames[#fileNames + 1] = "pool_00_base.convo"
    for i = 1, 20 do
        local name = string.format("pool_%02d_ext.convo", i)
        fileNames[#fileNames + 1] = name
        files[name] = table.concat({
            "language EN",
            "namespace test",
            "extend semantic.test.stream",
            string.format("  say [topic=t%d] as ext_%d:", i, i),
            string.format('    "Extended line %d."', i),
        }, "\n")
    end

    local pools = {}
    local stepDepth = 0
    local maxDepth = 0
    local origApply = Loader.ApplyScripts
    Loader.ApplyScripts = function(...)
        stepDepth = stepDepth + 1
        if stepDepth > maxDepth then maxDepth = stepDepth end
        local a, b, c, d, e = origApply(...)
        stepDepth = stepDepth - 1
        return a, b, c, d, e
    end

    -- Deliberately omit GetRaw and POOLS to verify the Loader._inStep guard
    -- even against a custom Catalog whose Get() calls EnsurePoolLoaded().
    local reentrantCatalog = {
        Get = function(id)
            if pools[id] == nil and Loader.PendingCount() > 0 then
                Loader.EnsurePoolLoaded(id)
            end
            return pools[id]
        end,
        Register = function(id, def)
            pools[id] = { id = id, variants = {} }
            for i = 1, #(def.variants or {}) do
                pools[id].variants[i] = def.variants[i]
            end
            return true
        end,
        Extend = function(id, def)
            local p = pools[id]
            if not p then return false end
            for i = 1, #(def.variants or {}) do
                p.variants[#p.variants + 1] = def.variants[i]
            end
            return true
        end,
    }

    _G.getActivatedMods = function() return { "TestStreamMod" } end
    _G.listFilesInModDirectory = function(modID, relDir)
        if modID == "TestStreamMod" and relDir == "media/translation/EN/ConvoBlocks/social" then
            return fileNames
        end
        return {}
    end
    _G.getModFileReader = function(modID, relPath)
        if modID ~= "TestStreamMod" then return nil end
        local base = string.match(relPath, "([^/]+)$")
        local content = files[base]
        if not content then return nil end
        local lines = {}
        for line in string.gmatch(content .. "\n", "(.-)\n") do
            lines[#lines + 1] = line
        end
        local idx = 0
        return {
            readLine = function()
                idx = idx + 1
                return lines[idx]
            end,
            close = function() end,
        }
    end

    Loader.BindTargets({ Catalog = reentrantCatalog })
    local diag = Loader.LoadLanguage("EN", { deferStream = true })
    equal(diag.pendingFiles, 21, "deferred streaming queues all 21 Tier 1 files")
    equal(Loader.StepStream(3, 0), 3, "incremental StepStream processes bounded batch of 3")
    equal(Loader.PendingCount(), 18, "18 files remain queued after first tick")
    Loader.FlushStream()

    Loader.ApplyScripts = origApply
    _G.listFilesInModDirectory = savedList
    _G.getModFileReader = savedReader
    _G.getActivatedMods = savedMods
    Loader.BindTargets(savedTargets)

    equal(maxDepth, 1, "ApplyScripts must never re-enter recursively (O(1) stack depth)")
    equal(Loader.PendingCount(), 0, "all queued stream files drained")
    equal(#(diag.errors or {}), 0, "zero loader errors during streaming")
    truthy(pools["semantic.test.stream"] ~= nil, "base + extended stream pool registered")
    equal(#pools["semantic.test.stream"].variants, 21, "all 21 variants merged without drops")
end

print("psychopatz_convo_dsl_and_spatial_smoke: ok")
