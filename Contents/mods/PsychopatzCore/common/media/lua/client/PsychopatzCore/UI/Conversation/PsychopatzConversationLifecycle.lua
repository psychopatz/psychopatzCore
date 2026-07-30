PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}

local Conversation = PsychopatzCore.Conversation
local Lifecycle = Conversation.Lifecycle or {}
Conversation.Lifecycle = Lifecycle

local function invoke(callback, ...)
    if type(callback) ~= "function" then
        return true
    end
    local ok, first, second = pcall(callback, ...)
    if not ok then
        return false, "lifecycle_error"
    end
    return true, first, second
end

function Lifecycle.Begin(view)
    if not view or view.lifecycleStarted then return true end
    local hooks = view.spec and view.spec.lifecycle or nil
    view.lifecycleStarted = true
    if type(hooks) ~= "table" then return true end
    local ok, state, reason = invoke(hooks.begin, view, view.spec)
    if not ok or state == false then
        return false, reason or state or "lifecycle_rejected"
    end
    view.lifecycleState = state == true and {} or state
    return true
end

function Lifecycle.Update(view)
    if not view or not view.lifecycleStarted or view.lifecycleFinished then
        return nil
    end
    local hooks = view.spec and view.spec.lifecycle or nil
    if type(hooks) ~= "table" then return nil end
    local ok, result, reason = invoke(
        hooks.update,
        view,
        view.spec,
        view.lifecycleState
    )
    if not ok then return "lifecycle_error" end
    if result == false then return reason or "interrupted" end
    if type(result) == "string" and result ~= "" then return result end
    return nil
end

function Lifecycle.Finish(view, reason)
    if not view or view.lifecycleFinished then return false end
    view.lifecycleFinished = true
    local hooks = view.spec and view.spec.lifecycle or nil
    if type(hooks) == "table" then
        invoke(
            hooks.finish,
            view,
            view.spec,
            view.lifecycleState,
            reason or view.closeReason or "closed"
        )
    end
    return true
end

return Lifecycle
