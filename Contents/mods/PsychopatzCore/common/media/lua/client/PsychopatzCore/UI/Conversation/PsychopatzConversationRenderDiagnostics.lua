-- Small, opt-in diagnostics for modular conversation render stages.
-- UIElement swallows Lua callback errors; keeping the guarded result on the
-- component lets the runtime audit identify the failing stage without making
-- the conversation window itself disappear.
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}

local Diagnostics = PsychopatzCore.Conversation.RenderDiagnostics or {}
PsychopatzCore.Conversation.RenderDiagnostics = Diagnostics

local function stateFor(part)
    local state = part.psychopatzRenderDiagnostics
    if state then return state end
    state = {
        prerenderCalls = 0,
        prerenderCompleted = 0,
        renderCalls = 0,
        renderCompleted = 0,
        lastStage = nil,
        lastError = nil,
        errorCount = 0,
    }
    part.psychopatzRenderDiagnostics = state
    return state
end

local function logFailure(part, stage, message)
    local DebugTrace = PsychopatzCore.DebugTrace
    if DebugTrace and type(DebugTrace.Record) == "function" then
        DebugTrace.Record({
            source = "PsychopatzCore",
            event = "conversation.render_error",
            data = {
                partID = part.partID,
                stage = stage,
                error = message,
            },
        })
        return
    end
    if type(print) == "function" then
        print("[PsychopatzCore][WARN] conversation render error part="
            .. tostring(part.partID)
            .. " stage=" .. tostring(stage)
            .. " error=" .. tostring(message))
    end
end

function Diagnostics.Run(part, stage, callback)
    if not part or type(callback) ~= "function" then return false end
    local state = stateFor(part)
    local isRender = stage == "render"
    local callKey = isRender and "renderCalls" or "prerenderCalls"
    local completeKey = isRender and "renderCompleted" or "prerenderCompleted"
    state[callKey] = state[callKey] + 1
    local ok, message = pcall(callback)
    if ok then
        state[completeKey] = state[completeKey] + 1
        state.lastStage = stage
        state.lastError = nil
        return true
    end
    state.lastStage = stage
    state.lastError = tostring(message)
    state.errorCount = state.errorCount + 1
    if state.lastLoggedError ~= state.lastError then
        state.lastLoggedError = state.lastError
        logFailure(part, stage, state.lastError)
    end
    return false
end

function Diagnostics.Describe(part)
    local state = part and part.psychopatzRenderDiagnostics
    if not state then return "render=-" end
    if state.lastError then
        return string.format(
            "render=ERR/%s errors=%d",
            tostring(state.lastStage or "?"),
            tonumber(state.errorCount) or 0
        )
    end
    return string.format(
        "render=P%d/%d R%d/%d",
        tonumber(state.prerenderCompleted) or 0,
        tonumber(state.prerenderCalls) or 0,
        tonumber(state.renderCompleted) or 0,
        tonumber(state.renderCalls) or 0
    )
end

return Diagnostics
