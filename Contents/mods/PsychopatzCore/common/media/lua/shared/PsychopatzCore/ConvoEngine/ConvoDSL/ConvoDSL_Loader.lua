-- ConvoEngine: hand-written
-- Streaming runtime .convo pack discovery, parsing, and registration.
--
-- Canonical path layout (mirrors Project Zomboid custom translation catalogs):
--   media/translation/<LANG>/ConvoBlocks/
--     lexicons/    (Tier 0: loaded synchronously before any line expands)
--     blueprints/  (Tier 0: loaded synchronously before any pool registers)
--     beats/       (Tier 1: streamed incrementally on Events.OnTick)
--     social/      (Tier 1: streamed incrementally)
--     commands/    (Tier 1: streamed incrementally)
--     questions/   (Tier 1: streamed incrementally)
--     themes/      (Tier 1: streamed incrementally; supports `extend` + `theme`)
--     branches/    (Tier 1: streamed incrementally)
--     *.convo      (Tier 1: root single-file community packs)
--
-- Tier 2 (On-Demand): if a pool is requested while Tier 1 files are still
-- queued, EnsurePoolLoaded() drains the queue immediately so gameplay never
-- misses a line or language overlay.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.ConvoEngine = PsychopatzCore.ConvoEngine or {}

local Parser = require "PsychopatzCore/ConvoEngine/ConvoDSL/ConvoDSL_Parser"
local StoryCompiler = require "PsychopatzCore/ConvoEngine/ConvoDSL/ConvoDSL_StoryCompiler"
local Lexicon = nil

local Loader = PsychopatzCore.ConvoEngine.ConvoDSLLoader or {}
PsychopatzCore.ConvoEngine.ConvoDSLLoader = Loader
Loader._targets = Loader._targets or {}
Loader.BASE_ROOT = "media/translation"
Loader.PACK_SUBDIR = "ConvoBlocks"
Loader.PRIMARY_MOD_ID = "PsychopatzCore"
Loader.ENGLISH = "EN"
Loader.MAX_FILE_BYTES = 524288
Loader.MAX_FILES_PER_DIR = 256
Loader.TICK_BUDGET_MS = 1.5
Loader.MAX_FILES_PER_TICK = 3

Loader.TIER0_CATEGORIES = { "lexicons", "blueprints" }
Loader.TIER1_CATEGORIES = { "world", "combat", "beats", "social", "commands", "questions", "needs", "themes", "branches", "" }

Loader._extraModSources = {}
Loader._loadedLanguage = nil
Loader._loaded = false
Loader._blueprintRawByID = {}
Loader._extendedOnlyPools = {}
Loader._streamQueue = {}
Loader._streamCursor = 1
Loader._tickBound = false
Loader._inStep = false
Loader.Diagnostics = {
    language = nil,
    filesLoaded = {},
    packs = {},
    errors = {},
    lexCount = 0,
    blueprintCount = 0,
    poolCount = 0,
    storyCount = 0,
    extendedCount = 0,
    pendingFiles = 0,
}

local function logWarn(msg)
    local line = "[PsychopatzCore][ConvoDSL][WARN] " .. tostring(msg)
    local pnc = rawget(_G, "PNC")
    if type(pnc) == "table" and type(pnc.Core) == "table" and type(pnc.Core.LogWarn) == "function" then
        pnc.Core.LogWarn(line)
    elseif print then
        print(line)
    end
end

local function getExistingPool(Catalog, poolID)
    if type(Catalog) ~= "table" then return nil end
    if type(Catalog.GetRaw) == "function" then
        return Catalog.GetRaw(poolID)
    end
    if type(Catalog.POOLS) == "table" then
        return Catalog.POOLS[tostring(poolID or "")]
    end
    if type(Catalog.Get) == "function" then
        return Catalog.Get(poolID)
    end
    return nil
end

local function nowMs()
    local ts = rawget(_G, "getTimestampMs")
    if type(ts) == "function" then
        local ok, v = pcall(ts)
        if ok and type(v) == "number" then return v end
    end
    return nil
end

local function normalizeLanguage(value)
    local s = string.upper(tostring(value or ""))
    if s == "" or string.find(s, "..", 1, true) or not string.match(s, "^[%w_%-]+$") then
        return Loader.ENGLISH
    end
    return s
end

function Loader.RegisterModSource(modID, packSubdir)
    modID = tostring(modID or "")
    if modID == "" then return false end
    Loader._extraModSources[#Loader._extraModSources + 1] = {
        modID = modID,
        packSubdir = tostring(packSubdir or Loader.PACK_SUBDIR),
    }
    return true
end

function Loader.ActiveLanguage()
    local manager = rawget(_G, "CustomTranslationManager")
        or (PsychopatzCore and PsychopatzCore.CustomTranslationManager)
    if type(manager) == "table" and type(manager.getLanguage) == "function" then
        local ok, value = pcall(manager.getLanguage)
        if ok and value and tostring(value) ~= "" then
            return normalizeLanguage(value)
        end
    end
    local tr = rawget(_G, "Translator")
    if tr and type(tr.getLanguage) == "function" then
        local ok, langObj = pcall(tr.getLanguage)
        if ok and langObj and type(langObj.toString) == "function" then
            local okStr, str = pcall(langObj.toString, langObj)
            if okStr and str and tostring(str) ~= "" then
                return normalizeLanguage(str)
            end
        end
    end
    return Loader.ENGLISH
end

local function listToLuaArray(collection)
    local out = {}
    if collection ~= nil and type(collection.size) == "function" and type(collection.get) == "function" then
        local okSize, count = pcall(collection.size, collection)
        if okSize and type(count) == "number" and count > 0 then
            for i = 0, count - 1 do
                local okItem, item = pcall(collection.get, collection, i)
                if okItem and item ~= nil then
                    out[#out + 1] = tostring(item)
                end
            end
        end
        return out
    end
    if type(collection) == "table" then
        for i = 1, #collection do
            out[#out + 1] = tostring(collection[i])
        end
        return out
    end
    return out
end

local function collectModSources()
    local ordered = { { modID = Loader.PRIMARY_MOD_ID, packSubdir = Loader.PACK_SUBDIR } }
    local seen = { [Loader.PRIMARY_MOD_ID .. ":" .. Loader.PACK_SUBDIR] = true }

    for i = 1, #Loader._extraModSources do
        local src = Loader._extraModSources[i]
        local k = src.modID .. ":" .. src.packSubdir
        if not seen[k] then
            seen[k] = true
            ordered[#ordered + 1] = src
        end
    end

    local getMods = rawget(_G, "getActivatedMods")
    if type(getMods) == "function" then
        local ok, mods = pcall(getMods)
        if ok and mods ~= nil then
            local list = listToLuaArray(mods)
            for i = 1, #list do
                local id = list[i]
                local k = id .. ":" .. Loader.PACK_SUBDIR
                if id ~= "" and not seen[k] then
                    seen[k] = true
                    ordered[#ordered + 1] = { modID = id, packSubdir = Loader.PACK_SUBDIR }
                end
            end
        end
    end
    return ordered
end

local function listConvoFiles(modID, relDir)
    local listFn = rawget(_G, "listFilesInModDirectory")
    if type(listFn) ~= "function" then return {} end
    local ok, rawList = pcall(listFn, modID, relDir)
    if not ok or rawList == nil then return {} end
    local names = listToLuaArray(rawList)
    local convoFiles = {}
    local seen = {}
    for i = 1, #names do
        local name = names[i]
        if #convoFiles >= Loader.MAX_FILES_PER_DIR then break end
        if type(name) == "string"
            and string.sub(name, -6) == ".convo"
            and not string.find(name, "..", 1, true)
            and not string.find(name, "/", 1, true)
            and not string.find(name, "\\", 1, true)
            and not seen[name]
        then
            seen[name] = true
            convoFiles[#convoFiles + 1] = name
        end
    end
    table.sort(convoFiles)
    return convoFiles
end

local function parseModFileStreaming(modID, relPath, defaultLang)
    local readerFn = rawget(_G, "getModFileReader")
    if type(readerFn) ~= "function" then
        return nil, "getModFileReader_unavailable"
    end
    local ok, reader = pcall(readerFn, modID, relPath, false)
    if not ok then return nil, "getModFileReader_failed" end
    if not reader then return nil, "file_missing:" .. relPath end

    local sourceLabel = modID .. ":" .. relPath
    local stream = Parser.NewStream(sourceLabel, defaultLang)
    local totalBytes = 0
    local readOK, streamErr = pcall(function()
        local line = reader:readLine()
        while line ~= nil do
            line = tostring(line)
            totalBytes = totalBytes + #line + 1
            if totalBytes > Loader.MAX_FILE_BYTES then
                error("file_too_large")
            end
            local feedOK, err = stream:feedLine(line)
            if not feedOK then
                return err
            end
            line = reader:readLine()
        end
        return nil
    end)
    pcall(function() reader:close() end)

    if not readOK then
        return nil, sourceLabel .. ": " .. tostring(streamErr)
    end
    if streamErr then
        return nil, tostring(streamErr)
    end
    return stream:finish()
end

local function splitTurns(text)
    local parts = {}
    local pos = 1
    while true do
        local sep = string.find(text, " >> ", pos, true)
        local chunk
        if sep then
            chunk = string.sub(text, pos, sep - 1)
            pos = sep + 4
        else
            chunk = string.sub(text, pos)
        end
        chunk = string.match(chunk, "^%s*(.-)%s*$") or ""
        if chunk ~= "" then
            parts[#parts + 1] = chunk
        end
        if not sep then break end
    end
    return parts
end

local function buildOfferTable(offer)
    local out = {
        id = offer.offerID,
        label = offer.label,
        say = offer.say,
        intent = offer.intent,
        subject = offer.subject,
    }
    if offer.claim ~= nil then out.claim = offer.claim end
    if offer.style ~= nil then out.style = offer.style end
    if offer.utility ~= nil then out.utility = offer.utility end
    if offer.aiBias ~= nil then out.aiBias = offer.aiBias end
    if offer.when ~= nil then out.when = offer.when end
    return out
end

local function buildPlanOfferRow(offer)
    local frame = {
        intent = offer.intent,
        speechAct = offer.intent,
    }
    if offer.action and offer.action ~= "" then
        frame.action = offer.action
        frame.target = "SELF"
    elseif offer.subject and offer.subject ~= "" then
        frame.subject = offer.subject
    end
    if offer.reference and offer.reference ~= "" then
        frame.reference = offer.reference
    end
    return {
        id = offer.offerID,
        labelKey = offer.offerID .. ".label",
        labelFallback = offer.label,
        utteranceKey = offer.offerID .. ".say",
        utteranceFallback = offer.say,
        frame = frame,
    }
end

local function templateIDFor(namespace, poolID, variantID)
    local cleanPool = poolID
    if string.sub(cleanPool, 1, 9) == "semantic." then
        cleanPool = string.sub(cleanPool, 10)
    end
    return namespace .. "." .. cleanPool .. "." .. variantID
end

local function appendUnique(dest, items, keyFn)
    local seen = {}
    for i = 1, #dest do
        local k = keyFn(dest[i])
        if k ~= nil then seen[k] = true end
    end
    for i = 1, #items do
        local k = keyFn(items[i])
        if k == nil or not seen[k] then
            if k ~= nil then seen[k] = true end
            dest[#dest + 1] = items[i]
        end
    end
end

function Loader.ApplyScripts(scripts, langOverride)
    local Catalog = Loader._targets.Catalog or PsychopatzCore.ConvoEngine.ResponseCatalog
    local canRegisterCatalog = type(Catalog) == "table" and type(Catalog.Register) == "function"

    local offerBlueprints = Loader._targets.OfferBlueprints or PsychopatzCore.ConvoEngine.OfferBlueprints or {}
    PsychopatzCore.ConvoEngine.OfferBlueprints = offerBlueprints
    local generatedOffers = Loader._targets.GeneratedOffers or PsychopatzCore.ConvoEngine.GeneratedOffers or {}
    PsychopatzCore.ConvoEngine.GeneratedOffers = generatedOffers
    local generatedOfferUses = Loader._targets.GeneratedOfferUses or PsychopatzCore.ConvoEngine.GeneratedOfferUses or {}
    PsychopatzCore.ConvoEngine.GeneratedOfferUses = generatedOfferUses

    local lexCount = 0
    local bpCount = 0
    local poolCount = 0
    local extendedCount = 0

    -- Pass 1: Register or extend all lexicons first.
    for sIdx = 1, #scripts do
        local script = scripts[sIdx]
        local lang = normalizeLanguage(langOverride or script.language)
        for i = 1, #(script.lexicons or {}) do
            local lx = script.lexicons[i]
            local entries = {}
            for j = 1, #lx.entries do
                local e = lx.entries[j]
                entries[j] = {
                    when = e.when,
                    priority = e.priority or 6,
                    words = e.words,
                }
            end
            local lex = Loader._targets.Lexicon or Lexicon
            if lex then
                if lx.mode == "extend" and type(lex.Extend) == "function" then
                    lex.Extend(lang, lx.lexID, entries)
                    extendedCount = extendedCount + 1
                elseif type(lex.Register) == "function" then
                    lex.Register(lang, lx.lexID, entries)
                    lexCount = lexCount + 1
                end
            end
        end
    end

    -- Pass 2: Register or extend all blueprints (persisted across streamed files).
    for sIdx = 1, #scripts do
        local script = scripts[sIdx]
        for i = 1, #(script.blueprints or {}) do
            local bp = script.blueprints[i]
            local built = {}
            for j = 1, #bp.offers do
                built[j] = buildOfferTable(bp.offers[j])
            end
            if bp.mode == "extend" and type(Loader._blueprintRawByID[bp.blueprintID]) == "table" then
                appendUnique(Loader._blueprintRawByID[bp.blueprintID], bp.offers, function(o) return o.offerID end)
                offerBlueprints[bp.blueprintID] = offerBlueprints[bp.blueprintID] or {}
                appendUnique(offerBlueprints[bp.blueprintID], built, function(o) return o.id end)
                extendedCount = extendedCount + 1
            else
                local rawCopy = {}
                for j = 1, #bp.offers do rawCopy[j] = bp.offers[j] end
                Loader._blueprintRawByID[bp.blueprintID] = rawCopy
                offerBlueprints[bp.blueprintID] = built
                bpCount = bpCount + 1
            end
        end
    end

    -- Pass 3: Register or extend pools, offers, and blueprint uses.
    if canRegisterCatalog then
        for sIdx = 1, #scripts do
            local script = scripts[sIdx]
            for pIdx = 1, #(script.pools or {}) do
                local pool = script.pools[pIdx]
                local effectiveOffers = {}
                for oIdx = 1, #pool.offers do
                    effectiveOffers[#effectiveOffers + 1] = pool.offers[oIdx]
                end
                for uIdx = 1, #pool.uses do
                    local bpOffers = Loader._blueprintRawByID[pool.uses[uIdx]]
                    if type(bpOffers) == "table" then
                        for oIdx = 1, #bpOffers do
                            effectiveOffers[#effectiveOffers + 1] = bpOffers[oIdx]
                        end
                    end
                end

                local planOffers = nil
                if #effectiveOffers > 0 then
                    planOffers = {}
                    for oIdx = 1, #effectiveOffers do
                        planOffers[oIdx] = buildPlanOfferRow(effectiveOffers[oIdx])
                    end
                end

                local defaultPresentationClass = nil
                if string.sub(pool.poolID, 1, 16) == "semantic.combat." then
                    local hasTacticalAction = false
                    if planOffers then
                        for oIdx = 1, #planOffers do
                            local act = planOffers[oIdx].frame and planOffers[oIdx].frame.action
                            if type(act) == "string" and string.sub(act, 1, 7) == "COMBAT_" then
                                hasTacticalAction = true
                                break
                            end
                        end
                    end
                    defaultPresentationClass = hasTacticalAction and "TACTICAL_PROMPT" or "BARK"
                end

                local variants = {}
                for vIdx = 1, #pool.variants do
                    local var = pool.variants[vIdx]
                    local vid = pool.poolID .. "." .. var.variantID
                    local tid = templateIDFor(script.namespace, pool.poolID, var.variantID)
                    local hasMulti = string.find(var.fallback, " >> ", 1, true) ~= nil
                    if hasMulti then
                        local parts = splitTurns(var.fallback)
                        local firstFb = parts[1] or var.fallback
                        local hasTokens = false
                        local turns = {}
                        for tIdx = 1, #parts do
                            local part = parts[tIdx]
                            if string.find(part, "{", 1, true) ~= nil then
                                hasTokens = true
                            end
                            local cont = tIdx < #parts and "continue" or "await_player"
                            local segTID = tIdx == 1 and tid or (tid .. ".t" .. tostring(tIdx))
                            local row = {
                                id = "t" .. tostring(tIdx),
                                continuation = cont,
                                segments = {
                                    { kind = "translation", templateID = segTID, fallback = part },
                                },
                            }
                            if planOffers and tIdx == #parts then
                                row.offers = planOffers
                            end
                            turns[tIdx] = row
                        end
                        variants[vIdx] = {
                            id = vid,
                            templateID = tid,
                            fallback = firstFb,
                            when = var.when,
                            priority = var.priority or 6,
                            hasTokens = hasTokens,
                            theme = var.theme,
                            plan = {
                                sourcePoolID = pool.poolID,
                                presentationClass = defaultPresentationClass,
                                turns = turns,
                            },
                        }
                    else
                        local hasTokens = string.find(var.fallback, "{", 1, true) ~= nil
                        local plan = nil
                        if planOffers or defaultPresentationClass ~= nil then
                            plan = {
                                sourcePoolID = pool.poolID,
                                presentationClass = defaultPresentationClass,
                                turns = {
                                    {
                                        segments = {
                                            { kind = "translation", templateID = tid, fallback = var.fallback },
                                        },
                                        offers = planOffers,
                                    },
                                },
                            }
                        end
                        variants[vIdx] = {
                            id = vid,
                            templateID = tid,
                            fallback = var.fallback,
                            when = var.when,
                            priority = var.priority or 6,
                            hasTokens = hasTokens,
                            theme = var.theme,
                            plan = plan,
                        }
                    end
                end

                local isExtend = pool.mode == "extend"
                local langTag = normalizeLanguage(langOverride or script.language)
                local extKey = langTag .. ":" .. pool.poolID
                Loader._baseRegisteredPools = Loader._baseRegisteredPools or {}
                if #variants > 0 then
                    local existingPool = getExistingPool(Catalog, pool.poolID)
                    if isExtend then
                        if existingPool ~= nil and type(Catalog.Extend) == "function" then
                            Catalog.Extend(pool.poolID, { variants = variants })
                            if not Loader._baseRegisteredPools[extKey] then
                                Loader._extendedOnlyPools[extKey] = true
                            end
                            extendedCount = extendedCount + 1
                        else
                            Catalog.Register(pool.poolID, { variants = variants })
                            Loader._extendedOnlyPools[extKey] = true
                            poolCount = poolCount + 1
                        end
                    elseif existingPool ~= nil and Loader._extendedOnlyPools[extKey] == true
                        and type(Catalog.Extend) == "function"
                    then
                        -- Base pool arrived after same-language `extend` files; merge without clobbering.
                        Catalog.Extend(pool.poolID, { variants = variants })
                        Loader._extendedOnlyPools[extKey] = nil
                        Loader._baseRegisteredPools[extKey] = true
                        poolCount = poolCount + 1
                    else
                        Catalog.Register(pool.poolID, { variants = variants })
                        Loader._extendedOnlyPools[extKey] = nil
                        Loader._baseRegisteredPools[extKey] = true
                        poolCount = poolCount + 1
                    end
                end

                if #pool.offers > 0 then
                    local genList = {}
                    for oIdx = 1, #pool.offers do
                        genList[oIdx] = buildOfferTable(pool.offers[oIdx])
                    end
                    if isExtend and type(generatedOffers[pool.poolID]) == "table" then
                        appendUnique(generatedOffers[pool.poolID], genList, function(o) return o.id end)
                    else
                        generatedOffers[pool.poolID] = genList
                    end
                end
                if #pool.uses > 0 then
                    local usesCopy = {}
                    for uIdx = 1, #pool.uses do
                        usesCopy[uIdx] = pool.uses[uIdx]
                    end
                    if isExtend and type(generatedOfferUses[pool.poolID]) == "table" then
                        appendUnique(generatedOfferUses[pool.poolID], usesCopy, function(u) return u end)
                    else
                        generatedOfferUses[pool.poolID] = usesCopy
                    end
                end
            end
        end
    end

    -- Pass 4: Compile declarative branching `story` / `extend story` blocks into FlowRegistry.
    local storyCount, storyExt, storyErrs = StoryCompiler.ApplyStories(scripts, Loader._blueprintRawByID, Loader._targets)
    extendedCount = extendedCount + storyExt
    for eIdx = 1, #(storyErrs or {}) do
        Loader.Diagnostics.errors = Loader.Diagnostics.errors or {}
        Loader.Diagnostics.errors[#Loader.Diagnostics.errors + 1] = storyErrs[eIdx]
        logWarn(storyErrs[eIdx])
    end

    return lexCount, bpCount, poolCount, extendedCount, storyCount
end

local function discoverTierJobs(lang, modSources, categories, outJobs)
    local langVariants = { lang }
    local lowerLang = string.lower(lang)
    if lowerLang ~= lang then langVariants[2] = lowerLang end

    for mIdx = 1, #modSources do
        local src = modSources[mIdx]
        local modID = src.modID
        local packSubdir = src.packSubdir
        for cIdx = 1, #categories do
            local cat = categories[cIdx]
            local seenFile = {}
            for lIdx = 1, #langVariants do
                local relDir = Loader.BASE_ROOT .. "/" .. langVariants[lIdx] .. "/" .. packSubdir
                if cat ~= "" then
                    relDir = relDir .. "/" .. cat
                end
                local files = listConvoFiles(modID, relDir)
                for i = 1, #files do
                    local filename = files[i]
                    if not seenFile[filename] then
                        seenFile[filename] = true
                        outJobs[#outJobs + 1] = {
                            modID = modID,
                            relPath = relDir .. "/" .. filename,
                            lang = lang,
                            category = cat,
                        }
                    end
                end
            end
        end
    end
end

local function executeJob(job, diag)
    local script, err = parseModFileStreaming(job.modID, job.relPath, job.lang)
    if not script then
        diag.errors[#diag.errors + 1] = tostring(err)
        logWarn(err)
        return false
    end
    diag.filesLoaded[#diag.filesLoaded + 1] = job.modID .. ":" .. job.relPath
    if script.pack and script.pack ~= "" then
        diag.packs = diag.packs or {}
        diag.packs[script.pack] = true
    end
    local lx, bp, pl, ex, st = Loader.ApplyScripts({ script }, job.lang)
    diag.lexCount = diag.lexCount + lx
    diag.blueprintCount = diag.blueprintCount + bp
    diag.poolCount = diag.poolCount + pl
    diag.extendedCount = diag.extendedCount + ex
    diag.storyCount = (diag.storyCount or 0) + (st or 0)
    return true
end

function Loader.PendingCount()
    local rem = #Loader._streamQueue - Loader._streamCursor + 1
    return rem > 0 and rem or 0
end

function Loader.StepStream(maxFiles, budgetMs)
    if Loader._inStep then
        return 0
    end
    local pending = Loader.PendingCount()
    if pending <= 0 then
        Loader.Diagnostics.pendingFiles = 0
        return 0
    end
    local limit = tonumber(maxFiles) or Loader.MAX_FILES_PER_TICK
    local maxMs = tonumber(budgetMs) or Loader.TICK_BUDGET_MS
    local startMs = nowMs()
    local processed = 0

    Loader._inStep = true
    while Loader._streamCursor <= #Loader._streamQueue and processed < limit do
        local job = Loader._streamQueue[Loader._streamCursor]
        Loader._streamCursor = Loader._streamCursor + 1
        local ok, err = pcall(executeJob, job, Loader.Diagnostics)
        if not ok then
            local label = tostring(job and job.modID or "") .. ":" .. tostring(job and job.relPath or "")
            local msg = label .. ": " .. tostring(err)
            Loader.Diagnostics.errors[#Loader.Diagnostics.errors + 1] = msg
            logWarn(msg)
        end
        processed = processed + 1
        if startMs ~= nil and maxMs > 0 then
            local elapsed = (nowMs() or startMs) - startMs
            if elapsed >= maxMs then break end
        end
    end
    Loader._inStep = false

    if Loader._streamCursor > #Loader._streamQueue then
        Loader._streamQueue = {}
        Loader._streamCursor = 1
    end
    Loader.Diagnostics.pendingFiles = Loader.PendingCount()
    return processed
end

function Loader.FlushStream()
    if Loader._inStep then
        return 0
    end
    local total = 0
    while Loader.PendingCount() > 0 do
        local stepped = Loader.StepStream(#Loader._streamQueue, 0)
        if stepped <= 0 then break end
        total = total + stepped
    end
    return total
end

function Loader.EnsurePoolLoaded(_poolID)
    if Loader._inStep then
        return false
    end
    if Loader.PendingCount() > 0 then
        Loader.FlushStream()
    end
    return true
end

local function bindTickStreamer()
    if Loader._tickBound then return end
    local events = rawget(_G, "Events")
    if type(events) == "table" and type(events.OnTick) == "table"
        and type(events.OnTick.Add) == "function"
    then
        events.OnTick.Add(function()
            if Loader.PendingCount() > 0 then
                Loader.StepStream()
            end
        end)
        Loader._tickBound = true
    end
end

function Loader.LoadLanguage(language, opts)
    opts = type(opts) == "table" and opts or {}
    local targetLang = normalizeLanguage(language or Loader.ActiveLanguage())
    local prevLang = Loader._loadedLanguage

    -- Drop previous non-EN lexicon pack to keep memory bounded to EN + 1 language.
    local lex = Loader._targets.Lexicon or Lexicon
    if prevLang and prevLang ~= Loader.ENGLISH and prevLang ~= targetLang
        and lex and type(lex.Packs) == "table"
    then
        lex.Packs[prevLang] = nil
    end

    Loader._blueprintRawByID = {}
    Loader._extendedOnlyPools = {}
    Loader._baseRegisteredPools = {}
    Loader._streamQueue = {}
    Loader._streamCursor = 1
    Loader._inStep = false
    StoryCompiler.Reset()

    local modSources = collectModSources()
    local diag = {
        language = targetLang,
        filesLoaded = {},
        packs = {},
        errors = {},
        lexCount = 0,
        blueprintCount = 0,
        poolCount = 0,
        storyCount = 0,
        extendedCount = 0,
        pendingFiles = 0,
    }
    Loader.Diagnostics = diag

    -- Tier 0: Synchronously load lexicons & blueprints (EN base, then active lang).
    local tier0Jobs = {}
    discoverTierJobs(Loader.ENGLISH, modSources, Loader.TIER0_CATEGORIES, tier0Jobs)
    if targetLang ~= Loader.ENGLISH then
        discoverTierJobs(targetLang, modSources, Loader.TIER0_CATEGORIES, tier0Jobs)
    end
    for i = 1, #tier0Jobs do
        executeJob(tier0Jobs[i], diag)
    end

    -- Tier 1: Queue pools, beats, themes, and branches (EN base, then active lang).
    local tier1Jobs = {}
    discoverTierJobs(Loader.ENGLISH, modSources, Loader.TIER1_CATEGORIES, tier1Jobs)
    if targetLang ~= Loader.ENGLISH then
        discoverTierJobs(targetLang, modSources, Loader.TIER1_CATEGORIES, tier1Jobs)
    end

    Loader._streamQueue = tier1Jobs
    Loader._streamCursor = 1
    diag.pendingFiles = #tier1Jobs
    Loader._loadedLanguage = targetLang
    Loader._loaded = true

    bindTickStreamer()

    -- In headless/test runtimes without Events.OnTick (unless deferStream=true),
    -- drain synchronously so tests stay deterministic.
    local deferStream
    if opts.deferStream ~= nil then
        deferStream = opts.deferStream == true
    else
        deferStream = Loader._tickBound
    end
    if not deferStream then
        Loader.FlushStream()
    end

    return diag
end

function Loader.EnsureActiveLanguage()
    local lang = Loader.ActiveLanguage()
    if not Loader._loaded or Loader._loadedLanguage ~= lang then
        return Loader.LoadLanguage(lang)
    end
    return Loader.Diagnostics
end

function Loader.Reload(language, opts)
    Loader._loaded = false
    return Loader.LoadLanguage(language, opts)
end

function Loader.BindTargets(targets)
    if type(targets) ~= "table" then return end
    for k, v in pairs(targets) do
        Loader._targets[k] = v
    end
    StoryCompiler.BindTargets(Loader._targets)
end

return Loader
