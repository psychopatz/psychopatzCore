-- Transport evidence classification owned by the Core harness.
--
-- The default is deliberately conservative: unknown commands remain dispatch
-- evidence. Adopters may configure one fact command or a classifier callback
-- without making Core import an adopter namespace.

local Evidence = {}

local factCommand = "SemanticInteractionLifecycle"
local factClassifier = nil

function Evidence.configure(options)
    if type(options) ~= "table" then return false end
    if options.factCommand ~= nil then
        if type(options.factCommand) ~= "string"
            or options.factCommand == ""
        then
            return false
        end
        factCommand = options.factCommand
    end
    if options.isFactCommand ~= nil
        and type(options.isFactCommand) ~= "function"
    then
        return false
    end
    factClassifier = options.isFactCommand
    return true
end

local function isFact(event)
    if type(event) ~= "table" then return false end
    if type(factClassifier) == "function" then
        return factClassifier(event.command, event)
    end
    return event.command == factCommand
end

function Evidence.partition(transport)
    local dispatches = {}
    local facts = {}
    for _, event in ipairs(transport or {}) do
        -- Unknown commands remain dispatch evidence (fail closed). Only the
        -- explicitly configured interaction fact protocol is separated.
        if isFact(event) then
            facts[#facts + 1] = event
        else
            dispatches[#dispatches + 1] = event
        end
    end
    return dispatches, facts
end

function Evidence.annotate(record)
    record.dispatchTransport, record.factTransport =
        Evidence.partition(record.transport)
    return record
end

return Evidence
