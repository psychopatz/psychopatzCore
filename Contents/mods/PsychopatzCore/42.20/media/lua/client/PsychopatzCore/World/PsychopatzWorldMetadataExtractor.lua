require "PsychopatzCore/00_PsychopatzCore_Init"

PsychopatzCore = PsychopatzCore or {}

local Core = PsychopatzCore
local Extractor = Core.WorldMetadataExtractor or {}
Core.WorldMetadataExtractor = Extractor

-- Coordinates and bounds are used internally to associate records, but never
-- leave this module. They are runtime facts, not stable NLP features.
Extractor.OUTPUT_ROOT = Extractor.OUTPUT_ROOT
    or "Debugs/WorldPlaceMetadata"
Extractor.INDEX_FILE = Extractor.INDEX_FILE
    or (Extractor.OUTPUT_ROOT .. "/Index.json")
Extractor.SCHEMA_VERSION = Extractor.SCHEMA_VERSION or 2
Extractor.STEP_BUDGET_MS = Extractor.STEP_BUDGET_MS or 3
Extractor.STEP_ITEM_LIMIT = Extractor.STEP_ITEM_LIMIT or 64
Extractor.MAX_LOG_LINES = 5
Extractor.DEFAULT_ZONE_SELECTIONS = {
    Places = true,
    ZombiesType = true,
    Nav = false,
    ForagingNav = false,
    SpawnPoint = false,
    Other = true,
}

Extractor.Internal = Extractor.Internal or {}

-- Ordered providers: records first, session lifecycle second, output writer
-- last. The public entry point remains at its original require path.
require "PsychopatzCore/World/PsychopatzWorldMetadataExtractor_Records"
require "PsychopatzCore/World/PsychopatzWorldMetadataExtractor_Session"
require "PsychopatzCore/World/PsychopatzWorldMetadataExtractor_Scan"
require "PsychopatzCore/World/PsychopatzWorldMetadataExtractor_Output"
require "PsychopatzCore/World/PsychopatzWorldMetadataExtractor_Writer"

local Session = Extractor.Internal.Session

function Extractor.CreateSession(options)
    return Session.new(options)
end

-- Useful for focused tests and small integrations. The Debug Hub uses
-- CreateSession and Step instead, so a real map never enters this synchronous
-- path from the UI.
function Extractor.Extract(options)
    options = type(options) == "table" and options or {}
    local sessionOptions = {}
    for key, value in pairs(options) do sessionOptions[key] = value end
    sessionOptions.writeOutput = false
    sessionOptions.itemLimit = 1000000
    sessionOptions.timeBudgetMs = 0
    local session = Session.new(sessionOptions)
    local started, reason = session:Start()
    if not started then return nil, reason end
    local ok, runReason, document = session:RunToCompletion()
    if not ok then return nil, runReason end
    return document
end

function Extractor.Export(options)
    options = type(options) == "table" and options or {}
    local sessionOptions = {}
    for key, value in pairs(options) do sessionOptions[key] = value end
    sessionOptions.writeOutput = true
    local session = Session.new(sessionOptions)
    local started, reason = session:Start()
    if not started then return nil, reason end
    local ok, runReason, document = session:RunToCompletion()
    if not ok then return nil, runReason, document end
    return document
end

return Extractor
