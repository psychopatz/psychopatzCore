-- Public facade for PsychopatzCore's shared runtime .convo DSL engine.
-- Serves ProjectHoomans, DynamicTrading, and any activated mod that ships
-- media/translation/<LANG>/ConvoBlocks/ packs.
-- Kahlua2 / Lua 5.1 safe.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.ConvoEngine = PsychopatzCore.ConvoEngine or {}

local Schema = require "PsychopatzCore/ConvoEngine/ConvoDSL/ConvoDSL_Schema"
local Parser = require "PsychopatzCore/ConvoEngine/ConvoDSL/ConvoDSL_Parser"
local StoryCompiler = require "PsychopatzCore/ConvoEngine/ConvoDSL/ConvoDSL_StoryCompiler"
local Loader = require "PsychopatzCore/ConvoEngine/ConvoDSL/ConvoDSL_Loader"
local OfferRealizer = require "PsychopatzCore/ConvoEngine/OfferRealizer"

local ConvoDSL = PsychopatzCore.ConvoEngine.ConvoDSL or {}
PsychopatzCore.ConvoEngine.ConvoDSL = ConvoDSL

ConvoDSL.VERSION = 4
ConvoDSL.Schema = Schema
ConvoDSL.Parser = Parser
ConvoDSL.StoryCompiler = StoryCompiler
ConvoDSL.StoryMetadata = StoryCompiler.Metadata
ConvoDSL.Loader = Loader
ConvoDSL.OfferRealizer = OfferRealizer
ConvoDSL.BASE_ROOT = Loader.BASE_ROOT
ConvoDSL.PACK_SUBDIR = Loader.PACK_SUBDIR

function ConvoDSL.BindTargets(targets)
    Loader.BindTargets(targets)
    OfferRealizer.BindStores(targets)
end

function ConvoDSL.RegisterFields(fields)
    return Schema.RegisterFields(fields)
end

function ConvoDSL.RegisterAliases(aliases)
    return Schema.RegisterAliases(aliases)
end

function ConvoDSL.RegisterCapabilities(caps)
    return StoryCompiler.RegisterCapabilities(caps)
end

function ConvoDSL.NewStream(sourcePath, defaultLang)
    return Parser.NewStream(sourcePath, defaultLang)
end

function ConvoDSL.ParseText(text, sourcePath, defaultLang)
    return Parser.ParseText(text, sourcePath, defaultLang)
end

function ConvoDSL.ApplyScripts(scripts, langOverride)
    return Loader.ApplyScripts(scripts, langOverride)
end

function ConvoDSL.RegisterModSource(modID, packSubdir)
    return Loader.RegisterModSource(modID, packSubdir)
end

function ConvoDSL.ActiveLanguage()
    return Loader.ActiveLanguage()
end

function ConvoDSL.LoadLanguage(language, opts)
    return Loader.LoadLanguage(language, opts)
end

function ConvoDSL.EnsureActiveLanguage()
    return Loader.EnsureActiveLanguage()
end

function ConvoDSL.EnsurePoolLoaded(poolID)
    return Loader.EnsurePoolLoaded(poolID)
end

function ConvoDSL.StepStream(maxFiles, budgetMs)
    return Loader.StepStream(maxFiles, budgetMs)
end

function ConvoDSL.FlushStream()
    return Loader.FlushStream()
end

function ConvoDSL.PendingCount()
    return Loader.PendingCount()
end

function ConvoDSL.Reload(language, opts)
    return Loader.Reload(language, opts)
end

function ConvoDSL.GetDiagnostics()
    return Loader.Diagnostics
end

function ConvoDSL.GetStory(storyID)
    return StoryCompiler.GetStory(storyID)
end

function ConvoDSL.ResolveReaction(storyID, nodeID, context, opts)
    return StoryCompiler.ResolveReaction(storyID, nodeID, context, opts)
end

function ConvoDSL.ApplyReactionEffects(actorID, targetKey, reaction, opts)
    return StoryCompiler.ApplyReactionEffects(actorID, targetKey, reaction, opts)
end

function ConvoDSL.ProjectPersonalityContext(personality, outCtx)
    return Schema.ProjectPersonalityContext(personality, outCtx)
end

return ConvoDSL
