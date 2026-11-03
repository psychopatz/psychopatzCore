local Generation = require
    "PsychopatzCore/World/SurvivorWorld/Generation/PsychopatzSurvivorWorldGenerationCore"
local Profiles = require
    "PsychopatzCore/World/SurvivorWorld/Generation/PsychopatzSurvivorWorldGenerationProfiles"
local Policies = require
    "PsychopatzCore/World/SurvivorWorld/Generation/PsychopatzSurvivorWorldGenerationPolicies"
local Planner = require
    "PsychopatzCore/World/SurvivorWorld/Generation/PsychopatzSurvivorWorldGenerationPlanner"

Generation.Profiles = Profiles
Generation.Policies = Policies
Generation.Planner = Planner

function Generation.BuildCommunityPlan(request)
    return Planner.BuildCommunityPlan(request)
end

function Generation.BuildGroupPlan(request)
    return Planner.BuildGroupPlan(request)
end

function Generation.BuildPolicyExtensions(plan, context)
    return Policies.BuildExtensions(plan, context)
end

return Generation
