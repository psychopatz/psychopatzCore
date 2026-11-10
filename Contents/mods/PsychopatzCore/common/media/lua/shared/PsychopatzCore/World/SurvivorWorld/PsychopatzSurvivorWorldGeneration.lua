local Generation = require
    "PsychopatzCore/World/SurvivorWorld/Generation/PsychopatzSurvivorWorldGenerationCore"
local Profiles = require
    "PsychopatzCore/World/SurvivorWorld/Generation/PsychopatzSurvivorWorldGenerationProfiles"
local Policies = require
    "PsychopatzCore/World/SurvivorWorld/Generation/PsychopatzSurvivorWorldGenerationPolicies"
local Planner = require
    "PsychopatzCore/World/SurvivorWorld/Generation/PsychopatzSurvivorWorldGenerationPlanner"
local Sources = require
    "PsychopatzCore/World/SurvivorWorld/Generation/PsychopatzSurvivorWorldGenerationSources"

Generation.Profiles = Profiles
Generation.Policies = Policies
Generation.Planner = Planner
Generation.Sources = Sources

function Generation.BuildCommunityPlan(request)
    return Planner.BuildCommunityPlan(request)
end

function Generation.BuildGroupPlan(request)
    return Planner.BuildGroupPlan(request)
end

function Generation.BuildPolicyExtensions(plan, context)
    return Policies.BuildExtensions(plan, context)
end

function Generation.GenerateGroup(registry, actorRegistry, sourceID, request)
    return Sources.GenerateGroup(
        registry,
        actorRegistry,
        sourceID,
        request
    )
end

function Generation.GenerateCommunity(
    registry,
    actorRegistry,
    sourceID,
    request
)
    return Sources.GenerateCommunity(
        registry,
        actorRegistry,
        sourceID,
        request
    )
end

return Generation
