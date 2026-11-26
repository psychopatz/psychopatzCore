-- ConvoEngine: hand-written
-- Pure Lua 5.1 / Kahlua2 line-by-line streaming parser for .convo packs.
-- Supports: language/lang, namespace, theme, pack, lexicon/lex, blueprint,
-- pool/beat/flow/extend, multi-line `say` variants, ` >> ` multi-turn plans,
-- smart default priorities, and indentation-nested branching `story` scripts
-- (`say` -> `choice [when] (params):` -> `reply:` -> `do` -> nested `choice`/`goto`/`end`).

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.ConvoEngine = PsychopatzCore.ConvoEngine or {}

local Schema = require "PsychopatzCore/ConvoEngine/ConvoDSL/ConvoDSL_Schema"

local Parser = PsychopatzCore.ConvoEngine.ConvoDSLParser or {}
PsychopatzCore.ConvoEngine.ConvoDSLParser = Parser
Parser.MAX_NEST_DEPTH = 10

local NAMED_PRIORITIES = {
    low = 4,
    normal = 6,
    high = 9,
    urgent = 11,
}

local OFFER_KV_KEYS = {
    label = true,
    say = true,
    intent = true,
    subject = true,
    action = true,
    claim = true,
    style = true,
    tone = true,
    utility = true,
    ai_bias = true,
    aiBias = true,
    when = true,
    stateValue = true,
}

local NODE_TRANSITION_KEYS = {
    on_match = "onMatch",
    on_clarify = "onClarify",
    on_refuse = "onRefuse",
    on_unrelated = "onUnrelated",
    next = "next",
}

local function trim(s)
    return string.match(tostring(s or ""), "^%s*(.-)%s*$") or ""
end

local function indentOf(rawLine)
    local n = 0
    for i = 1, #rawLine do
        local ch = string.sub(rawLine, i, i)
        if ch == " " then
            n = n + 1
        elseif ch == "\t" then
            n = n + 2
        else
            break
        end
    end
    return n
end

local function unescapeQuoted(s)
    s = string.gsub(s, '\\"', '"')
    s = string.gsub(s, "\\n", "\n")
    s = string.gsub(s, "\\r", "\r")
    s = string.gsub(s, "\\\\", "\\")
    return s
end

local function stripQuotes(raw)
    local s = trim(raw)
    local len = #s
    if len >= 2 and string.sub(s, 1, 1) == '"' and string.sub(s, len, len) == '"' then
        return unescapeQuoted(string.sub(s, 2, len - 1))
    end
    return s
end

local function parsePriorityClause(rest)
    local priToken, afterPri = string.match(rest, "^%(priority%s+([%w_]+)%)%s*(.*)$")
    if not priToken then
        priToken, afterPri = string.match(rest, "^%(pri%s+([%w_]+)%)%s*(.*)$")
    end
    if not priToken then return nil, rest end
    local num = tonumber(priToken) or NAMED_PRIORITIES[string.lower(priToken)]
    if not num then return nil, rest end
    return num, afterPri
end

local function parsePredicates(rawPreds, source, lineNo)
    if not rawPreds then return nil, nil end
    local trimmed = trim(rawPreds)
    if trimmed == "" or trimmed == "default" then return nil, nil end

    local out = nil
    local pos = 1
    while true do
        local comma = string.find(trimmed, ",", pos, true)
        local token
        if comma then
            token = trim(string.sub(trimmed, pos, comma - 1))
            pos = comma + 1
        else
            token = trim(string.sub(trimmed, pos))
        end
        if token ~= "" and token ~= "default" then
            local luaKey, val, err = Schema.ResolvePredicate(token, source, lineNo)
            if err then return nil, err end
            out = out or {}
            out[luaKey] = val
        end
        if not comma then break end
    end
    return out, nil
end

local function parseKeyValList(rawExpr, source, lineNo, label)
    local trimmed = trim(rawExpr)
    if trimmed == "" then
        return nil, tostring(source) .. ":" .. tostring(lineNo) .. ": empty " .. tostring(label)
    end
    local out = {}
    local pos = 1
    while true do
        local comma = string.find(trimmed, ",", pos, true)
        local token
        if comma then
            token = trim(string.sub(trimmed, pos, comma - 1))
            pos = comma + 1
        else
            token = trim(string.sub(trimmed, pos))
        end
        if token ~= "" then
            local eq = string.find(token, "=", 1, true)
            if not eq then
                return nil, tostring(source) .. ":" .. tostring(lineNo)
                    .. ": " .. tostring(label) .. " expects key=value, got '" .. token .. "'"
            end
            local k = trim(string.sub(token, 1, eq - 1))
            local v = stripQuotes(string.sub(token, eq + 1))
            if v == "true" then v = true
            elseif v == "false" then v = false
            end
            out[k] = v
        end
        if not comma then break end
    end
    return out, nil
end

local function parseWordList(raw, source, lineNo)
    local words = {}
    local parts = {}
    local buf = {}
    local inQuotes = false
    local escaped = false
    local len = #raw

    for i = 1, len do
        local ch = string.sub(raw, i, i)
        if escaped then
            buf[#buf + 1] = ch
            escaped = false
        elseif ch == "\\" and inQuotes then
            buf[#buf + 1] = ch
            escaped = true
        elseif ch == '"' then
            inQuotes = not inQuotes
            buf[#buf + 1] = ch
        elseif ch == "|" and not inQuotes then
            parts[#parts + 1] = table.concat(buf)
            buf = {}
        else
            buf[#buf + 1] = ch
        end
    end
    parts[#parts + 1] = table.concat(buf)

    for i = 1, #parts do
        local p = trim(parts[i])
        local plen = #p
        if not (plen >= 2 and string.sub(p, 1, 1) == '"' and string.sub(p, plen, plen) == '"') then
            return nil, tostring(source) .. ":" .. tostring(lineNo)
                .. ": expected quoted string in lexicon list, got '" .. p .. "'"
        end
        words[#words + 1] = unescapeQuoted(string.sub(p, 2, plen - 1))
    end
    if #words == 0 then
        return nil, tostring(source) .. ":" .. tostring(lineNo) .. ": empty lexicon word list"
    end
    return words, nil
end

local function countPredicates(when)
    if type(when) ~= "table" then return 0 end
    local n = 0
    for _ in pairs(when) do n = n + 1 end
    return n
end

local function autoPriority(when, explicitPri, ruleOrder)
    if explicitPri ~= nil then return explicitPri end
    local k = countPredicates(when)
    if k == 0 then return 1 end
    -- More specific conditions always win; top-to-bottom rule order breaks
    -- equal-specificity ties naturally (while multi-line quotes under one `say`
    -- share the exact same ruleOrder so random/anti-repeat rotation is preserved).
    local orderBonus = math.max(0, 1000 - (tonumber(ruleOrder) or 0)) * 0.0001
    return (5 + k) + orderBonus
end

local function parseLexEntry(stripped, source, lineNo, ruleOrder)
    local rest = stripped
    local rawPreds = nil

    if string.sub(rest, 1, 1) == "[" then
        local closeBracket = string.find(rest, "]", 2, true)
        if not closeBracket then return nil, nil, nil, false end
        rawPreds = string.sub(rest, 2, closeBracket - 1)
        rest = trim(string.sub(rest, closeBracket + 1))
    end

    local explicitPri, afterPri = parsePriorityClause(rest)
    rest = afterPri

    local rawWords = string.match(rest, "^:%s*(.+)$")
    if not rawWords then return nil, nil, nil, false end

    local when, err = parsePredicates(rawPreds, source, lineNo)
    if err then return nil, nil, nil, err end
    local words, wErr = parseWordList(rawWords, source, lineNo)
    if wErr then return nil, nil, nil, wErr end
    local pri = autoPriority(when, explicitPri, ruleOrder)
    return words, when, pri, nil
end

local function parseSpeechLine(stripped, keyword, source, lineNo, ruleOrder)
    local rest = string.match(stripped, "^" .. keyword .. "(.*)$")
    if not rest then return nil, false end
    local firstChar = string.sub(rest, 1, 1)
    if firstChar ~= "" and firstChar ~= " " and firstChar ~= "\t" and firstChar ~= ":" then
        return nil, false
    end
    rest = trim(rest)

    local rawPreds = nil
    local explicitID = nil

    if string.sub(rest, 1, 1) == "[" then
        local closeBracket = string.find(rest, "]", 2, true)
        if not closeBracket then return nil, false end
        rawPreds = string.sub(rest, 2, closeBracket - 1)
        rest = trim(string.sub(rest, closeBracket + 1))
    end

    local explicitPri, afterPri = parsePriorityClause(rest)
    rest = afterPri

    local idStr, afterID = string.match(rest, "^as%s+([%w_%.%-]+)%s*(.*)$")
    if idStr then
        explicitID = idStr
        rest = afterID
    end

    if string.sub(rest, 1, 1) ~= ":" then
        return nil, false
    end
    local tail = trim(string.sub(rest, 2))
    local inlineText = nil
    if tail ~= "" then
        local tlen = #tail
        if not (tlen >= 2 and string.sub(tail, 1, 1) == '"' and string.sub(tail, tlen, tlen) == '"') then
            return nil, false
        end
        inlineText = unescapeQuoted(string.sub(tail, 2, tlen - 1))
    end

    local when, err = parsePredicates(rawPreds, source, lineNo)
    if err then return nil, err end
    local pri = autoPriority(when, explicitPri, ruleOrder)

    return {
        when = when,
        priority = pri,
        explicitID = explicitID,
        inlineText = inlineText,
        lineNo = lineNo,
    }, nil
end

local function parseChoiceHeader(stripped, source, lineNo)
    local rest = string.match(stripped, "^choice%s+(.+)$")
    if not rest then return nil, false end
    local chID, afterID = string.match(rest, "^([%w_%.%-]+)%s*(.*)$")
    if not chID then return nil, false end
    rest = trim(afterID)

    local when = nil
    local params = nil
    local target = nil

    -- Optional [when] and (params) in either order before optional `-> target:`
    for _ = 1, 2 do
        if string.sub(rest, 1, 1) == "[" then
            local closeB = string.find(rest, "]", 2, true)
            if not closeB then return nil, false end
            local w, wErr = parsePredicates(string.sub(rest, 2, closeB - 1), source, lineNo)
            if wErr then return nil, wErr end
            when = w
            rest = trim(string.sub(rest, closeB + 1))
        elseif string.sub(rest, 1, 1) == "(" then
            local closeP = string.find(rest, ")", 2, true)
            if not closeP then return nil, false end
            local p, pErr = parseKeyValList(string.sub(rest, 2, closeP - 1), source, lineNo, "choice parameters")
            if pErr then return nil, pErr end
            params = p
            rest = trim(string.sub(rest, closeP + 1))
        end
    end

    local arrowTarget, afterArrow = string.match(rest, "^%->%s*([%w_%.%-]+)%s*(.*)$")
    if arrowTarget then
        target = arrowTarget
        rest = trim(afterArrow)
    end
    if rest ~= ":" then return nil, false end

    local offer = {
        offerID = chID,
        target = target,
        label = "",
        say = "",
        intent = (params and params.intent) or "INFORM",
        subject = (params and params.subject) or "",
        action = params and params.action or nil,
        claim = params and params.claim or nil,
        style = params and (params.style or params.tone) or nil,
        utility = params and params.utility or nil,
        aiBias = params and (params.ai_bias or params.aiBias) or nil,
        stateValue = params and params.stateValue or nil,
        when = when,
        lineNo = lineNo,
    }
    return offer, nil
end

local function parseGateLine(stripped, source, lineNo)
    local rawPred, rawTargets = string.match(stripped, "^gate%s+%[([^%]]+)%]%s*%->%s*(.+)$")
    if not rawPred or not rawTargets then return nil, false end
    local luaKey, expected, err = Schema.ResolvePredicate(rawPred, source, lineNo)
    if err then return nil, err end

    local targets = {}
    local pos = 1
    while true do
        local bar = string.find(rawTargets, "|", pos, true)
        if not bar then
            targets[#targets + 1] = trim(string.sub(rawTargets, pos))
            break
        end
        targets[#targets + 1] = trim(string.sub(rawTargets, pos, bar - 1))
        pos = bar + 1
    end
    if #targets < 2 or targets[1] == "" or targets[2] == "" then
        return nil, tostring(source) .. ":" .. tostring(lineNo)
            .. ": gate requires '-> pass_node | fail_node [| unknown_node]'"
    end
    return {
        rawPred = trim(rawPred),
        luaKey = luaKey,
        expected = expected,
        onPass = targets[1],
        onFail = targets[2],
        onUnknown = targets[3] and targets[3] ~= "" and targets[3] or targets[2],
        lineNo = lineNo,
    }, nil
end

local function autoVariantID(targetContainer, explicitID, repeatIndex)
    if explicitID and explicitID ~= "" then
        if repeatIndex and repeatIndex > 1 then
            return explicitID .. "_" .. tostring(repeatIndex)
        end
        return explicitID
    end
    local idx = #targetContainer.variants + 1
    if targetContainer.mode == "extend" then
        local scope = (targetContainer.theme and targetContainer.theme ~= "" and targetContainer.theme)
            or (targetContainer.pack and targetContainer.pack ~= "" and targetContainer.pack)
            or nil
        if scope then
            return scope .. ".v" .. tostring(idx)
        end
    end
    return "v" .. tostring(idx)
end

local function matchPoolHeader(stripped)
    local kind, poolID = string.match(stripped, "^(dialogue)%s+([%w_%.%-]+)$")
    if kind then return kind, poolID, "replace" end
    kind, poolID = string.match(stripped, "^(pool)%s+([%w_%.%-]+)$")
    if kind then return kind, poolID, "replace" end
    kind, poolID = string.match(stripped, "^(beat)%s+([%w_%.%-]+)$")
    if kind then return kind, poolID, "replace" end
    kind, poolID = string.match(stripped, "^(flow)%s+([%w_%.%-]+)$")
    if kind then return kind, poolID, "replace" end
    poolID = string.match(stripped, "^extend%s+dialogue%s+([%w_%.%-]+)$")
    if poolID then return "extend", poolID, "extend" end
    poolID = string.match(stripped, "^extend%s+pool%s+([%w_%.%-]+)$")
    if poolID then return "extend", poolID, "extend" end
    kind, poolID = string.match(stripped, "^(extend)%s+([%w_%.%-]+)$")
    if kind then return kind, poolID, "extend" end
    return nil, nil, nil
end

local function newStoryNode(story, nodeID, isTerminal, lineNo, theme, pack)
    local node = {
        nodeID = nodeID,
        terminal = isTerminal == true,
        responsePool = nil,
        variants = {},
        reactions = {},
        choices = {},
        uses = {},
        gate = nil,
        actions = {},
        recommends = {},
        transitions = {},
        theme = theme,
        pack = pack,
        mode = story.mode,
        lineNo = lineNo,
    }
    story.nodes[#story.nodes + 1] = node
    return node
end

function Parser.NewStream(sourcePath, defaultLang)
    local stream = {
        sourcePath = tostring(sourcePath or "<memory>"),
        namespace = "hoomans",
        language = string.upper(tostring(defaultLang or "EN")),
        theme = nil,
        pack = nil,
        lexicons = {},
        blueprints = {},
        pools = {},
        stories = {},
        lineNo = 0,
        err = nil,
        _currentLex = nil,
        _currentBlueprint = nil,
        _currentPool = nil,
        _currentStory = nil,
        _storyStack = {},
        _currentOffer = nil,
        _activeSay = nil,
        _activeSayTarget = nil,
        _activeSayCount = 0,
        _activeReaction = nil,
    }

    local function closeActiveSay()
        if stream._activeSay ~= nil and stream._activeSayCount == 0 then
            stream.err = stream.sourcePath .. ":" .. tostring(stream._activeSay.lineNo)
                .. ": dangling 'say:'/'reply:' without text line"
            return false
        end
        stream._activeSay = nil
        stream._activeSayTarget = nil
        stream._activeSayCount = 0
        stream._activeReaction = nil
        return true
    end

    local function resetContext()
        stream._currentLex = nil
        stream._currentBlueprint = nil
        stream._currentPool = nil
        stream._currentStory = nil
        stream._storyStack = {}
        stream._currentOffer = nil
    end

    local function popStoryScopesTo(indent)
        while #stream._storyStack > 0 do
            local top = stream._storyStack[#stream._storyStack]
            if indent <= top.indent then
                stream._storyStack[#stream._storyStack] = nil
            else
                break
            end
        end
    end

    local function currentStoryScope()
        return stream._storyStack[#stream._storyStack]
    end

    function stream:feedLine(rawLine)
        if self.err then return false, self.err end
        self.lineNo = self.lineNo + 1
        local idx = self.lineNo
        local src = self.sourcePath
        local stripped = trim(rawLine)
        if stripped == "" or string.sub(stripped, 1, 1) == "#" then
            return true, nil
        end
        local lineIndent = indentOf(rawLine)

        -- Consecutive quoted lines continue an active multi-line `say:` / `reply:` block.
        if self._activeSay ~= nil then
            local slen = #stripped
            if slen >= 2 and string.sub(stripped, 1, 1) == '"'
                and string.sub(stripped, slen, slen) == '"'
            then
                self._activeSayCount = self._activeSayCount + 1
                local target = self._activeSayTarget
                local ps = self._activeSay
                local text = unescapeQuoted(string.sub(stripped, 2, slen - 1))
                target.variants[#target.variants + 1] = {
                    variantID = autoVariantID(target, ps.explicitID, self._activeSayCount),
                    fallback = text,
                    when = ps.when,
                    priority = ps.priority,
                    theme = target.theme or self.theme,
                    lineNo = idx,
                }
                if self._activeReaction ~= nil then
                    self._activeReaction.variants[#self._activeReaction.variants + 1] = text
                end
                return true, nil
            end
            if not closeActiveSay() then
                return false, self.err
            end
        end

        local nsVal = string.match(stripped, "^namespace%s+(.+)$")
        if nsVal then
            nsVal = trim(nsVal)
            if not string.match(nsVal, "^[%w_%.%-]+$") then
                self.err = src .. ":" .. tostring(idx) .. ": invalid namespace '" .. nsVal .. "'"
                return false, self.err
            end
            self.namespace = nsVal
            return true, nil
        end

        local langVal = string.match(stripped, "^language%s+(.+)$")
            or string.match(stripped, "^lang%s+(.+)$")
        if langVal then
            langVal = string.upper(trim(langVal))
            if not string.match(langVal, "^%u%u%u?%u?%u?%u?%u?%u?$") then
                self.err = src .. ":" .. tostring(idx) .. ": invalid language '" .. langVal .. "'"
                return false, self.err
            end
            self.language = langVal
            return true, nil
        end

        local themeVal = string.match(stripped, "^theme%s+(.+)$")
        if themeVal then
            themeVal = trim(themeVal)
            if not string.match(themeVal, "^[%w_%.%-]+$") then
                self.err = src .. ":" .. tostring(idx) .. ": invalid theme '" .. themeVal .. "'"
                return false, self.err
            end
            self.theme = themeVal
            return true, nil
        end

        local packVal = string.match(stripped, "^pack%s+(.+)$")
        if packVal then
            packVal = trim(packVal)
            if not string.match(packVal, "^[%w_%.%-]+$") then
                self.err = src .. ":" .. tostring(idx) .. ": invalid pack '" .. packVal .. "'"
                return false, self.err
            end
            self.pack = packVal
            return true, nil
        end

        if lineIndent == 0 then
            local extendStoryID = string.match(stripped, "^extend%s+story%s+([%w_%.%-]+)$")
            if extendStoryID then
                resetContext()
                self._currentStory = {
                    storyID = extendStoryID,
                    mode = "extend",
                    triggers = {},
                    guards = {},
                    initial = nil,
                    nodes = {},
                    theme = self.theme,
                    pack = self.pack,
                    lineNo = idx,
                }
                self.stories[#self.stories + 1] = self._currentStory
                return true, nil
            end

            local storyID = string.match(stripped, "^story%s+([%w_%.%-]+)$")
            if storyID then
                resetContext()
                self._currentStory = {
                    storyID = storyID,
                    mode = "replace",
                    triggers = {},
                    guards = {},
                    initial = nil,
                    nodes = {},
                    theme = self.theme,
                    pack = self.pack,
                    lineNo = idx,
                }
                self.stories[#self.stories + 1] = self._currentStory
                return true, nil
            end

            local extendLexID = string.match(stripped, "^extend%s+lexicon%s+([%w_%.%-]+)$")
                or string.match(stripped, "^extend%s+lex%s+([%w_%.%-]+)$")
            if extendLexID then
                resetContext()
                self._currentLex = { lexID = extendLexID, mode = "extend", entries = {}, lineNo = idx }
                self.lexicons[#self.lexicons + 1] = self._currentLex
                return true, nil
            end

            local lexID = string.match(stripped, "^lexicon%s+([%w_%.%-]+)$")
                or string.match(stripped, "^lex%s+([%w_%.%-]+)$")
            if lexID then
                resetContext()
                self._currentLex = { lexID = lexID, mode = "replace", entries = {}, lineNo = idx }
                self.lexicons[#self.lexicons + 1] = self._currentLex
                return true, nil
            end

            local extendBpID = string.match(stripped, "^extend%s+blueprint%s+([%w_%.%-]+)$")
            if extendBpID then
                resetContext()
                self._currentBlueprint = { blueprintID = extendBpID, mode = "extend", offers = {}, lineNo = idx }
                self.blueprints[#self.blueprints + 1] = self._currentBlueprint
                return true, nil
            end

            local bpID = string.match(stripped, "^blueprint%s+([%w_%.%-]+)$")
            if bpID then
                resetContext()
                self._currentBlueprint = { blueprintID = bpID, mode = "replace", offers = {}, lineNo = idx }
                self.blueprints[#self.blueprints + 1] = self._currentBlueprint
                return true, nil
            end

            local poolKind, poolID, poolMode = matchPoolHeader(stripped)
            if poolKind and poolID then
                resetContext()
                self._currentPool = {
                    kind = poolKind,
                    mode = poolMode,
                    poolID = poolID,
                    theme = self.theme,
                    pack = self.pack,
                    variants = {},
                    offers = {},
                    uses = {},
                    lineNo = idx,
                }
                self.pools[#self.pools + 1] = self._currentPool
                return true, nil
            end
        end

        -- Inside a `story` block: handle story-level, node-level, and nested `choice` scopes.
        if self._currentStory ~= nil then
            popStoryScopesTo(lineIndent)
            local scope = currentStoryScope()

            local nodeID, nodeFlags = string.match(stripped, "^node%s+([%w_%.%-]+)%s*(.*)$")
            if nodeID then
                self._storyStack = {}
                local isTerminal = string.find(nodeFlags or "", "terminal", 1, true) ~= nil
                local node = newStoryNode(self._currentStory, nodeID, isTerminal, idx, self.theme, self.pack)
                self._storyStack[1] = { kind = "node", node = node, indent = lineIndent }
                return true, nil
            end

            local triggerExpr = string.match(stripped, "^trigger%s+(.+)$")
            if triggerExpr then
                local frame, fErr = parseKeyValList(triggerExpr, src, idx, "trigger")
                if fErr then self.err = fErr; return false, self.err end
                self._currentStory.triggers[#self._currentStory.triggers + 1] = frame
                return true, nil
            end

            local guardName = string.match(stripped, "^guard%s+([%w_%.%-]+)$")
            if guardName then
                self._currentStory.guards[#self._currentStory.guards + 1] = guardName
                return true, nil
            end

            local initNode = string.match(stripped, "^initial%s+([%w_%.%-]+)$")
            if initNode then
                self._currentStory.initial = initNode
                return true, nil
            end

            -- Choice header inside a node or nested inside another choice
            local choiceObj, choiceErr = parseChoiceHeader(stripped, src, idx)
            if choiceErr and choiceErr ~= false then
                self.err = choiceErr; return false, self.err
            elseif choiceObj then
                if #self._storyStack >= Parser.MAX_NEST_DEPTH then
                    self.err = src .. ":" .. tostring(idx) .. ": max choice nesting depth ("
                        .. tostring(Parser.MAX_NEST_DEPTH) .. ") exceeded"
                    return false, self.err
                end
                if not scope then
                    local rootNode = newStoryNode(self._currentStory, "start", false, idx, self.theme, self.pack)
                    self._currentStory.initial = self._currentStory.initial or "start"
                    scope = { kind = "node", node = rootNode, indent = lineIndent - 1 }
                    self._storyStack[1] = scope
                end
                local parentNode = scope.node
                if scope.kind == "reply" and scope.reaction then
                    if not scope.followUpNode then
                        local fID = scope.node.nodeID .. "_" .. scope.reaction.reactionID
                        scope.followUpNode = newStoryNode(self._currentStory, fID, false, idx, self.theme, self.pack)
                        scope.reaction.followUpNodeID = fID
                        scope.node.terminal = false
                    end
                    parentNode = scope.followUpNode
                end
                parentNode.terminal = false
                parentNode.choices[#parentNode.choices + 1] = choiceObj

                local childNode = nil
                if not choiceObj.target then
                    local prefix = parentNode.nodeID == "start" and "c" or (parentNode.nodeID .. "_c")
                    local autoNodeID = prefix .. choiceObj.offerID
                    childNode = newStoryNode(self._currentStory, autoNodeID, true, idx, self.theme, self.pack)
                    choiceObj.target = autoNodeID
                end
                self._storyStack[#self._storyStack + 1] = {
                    kind = "choice",
                    choice = choiceObj,
                    node = childNode or parentNode,
                    hasAutoNode = childNode ~= nil,
                    indent = lineIndent,
                }
                return true, nil
            end

            -- `reply` inside a choice/node targets that node and opens a personality-reaction scope
            local replyInfo, replyErr = parseSpeechLine(stripped, "reply", src, idx, idx)
            if replyErr and replyErr ~= false then
                self.err = replyErr; return false, self.err
            elseif replyInfo and scope and scope.node then
                local reaction = {
                    reactionID = "r" .. tostring(#scope.node.reactions + 1),
                    when = replyInfo.when,
                    priority = replyInfo.priority,
                    variants = {},
                    actions = {},
                    recommends = {},
                    transitions = {},
                    followUpNodeID = nil,
                    terminal = false,
                    lineNo = idx,
                }
                scope.node.reactions[#scope.node.reactions + 1] = reaction
                self._storyStack[#self._storyStack + 1] = {
                    kind = "reply",
                    node = scope.node,
                    reaction = reaction,
                    followUpNode = nil,
                    indent = lineIndent,
                }
                if replyInfo.inlineText ~= nil then
                    scope.node.variants[#scope.node.variants + 1] = {
                        variantID = autoVariantID(scope.node, replyInfo.explicitID, 1),
                        fallback = replyInfo.inlineText,
                        when = replyInfo.when,
                        priority = replyInfo.priority,
                        theme = self.theme,
                        lineNo = idx,
                    }
                    reaction.variants[#reaction.variants + 1] = replyInfo.inlineText
                else
                    self._activeSay = replyInfo
                    self._activeSayTarget = scope.node
                    self._activeSayCount = 0
                    self._activeReaction = reaction
                end
                return true, nil
            end

            -- `do <capability> [arg]` attaches whitelisted action/effect to current reply reaction or node
            local doExpr = string.match(stripped, "^do%s+(.+)$")
            if doExpr and scope and scope.node then
                local cap, arg = string.match(trim(doExpr), "^([%w_%.%-]+)%s*(.*)$")
                local actEntry = {
                    capability = cap,
                    arg = arg ~= "" and arg or nil,
                    lineNo = idx,
                }
                if scope.kind == "reply" and scope.reaction then
                    scope.reaction.actions[#scope.reaction.actions + 1] = actEntry
                else
                    scope.node.actions[#scope.node.actions + 1] = actEntry
                end
                return true, nil
            end

            -- `goto <node_id>` jumps to a named node
            local gotoTarget = string.match(stripped, "^goto%s+([%w_%.%-]+)$")
            if gotoTarget and scope then
                if scope.kind == "reply" and scope.reaction then
                    scope.reaction.transitions.next = gotoTarget
                    scope.node.terminal = false
                elseif scope.kind == "choice" and scope.hasAutoNode and #scope.node.variants == 0
                    and #scope.node.actions == 0 and #scope.node.choices == 0
                then
                    scope.choice.target = gotoTarget
                    scope.node._unused = true
                elseif scope.node then
                    scope.node.terminal = false
                    scope.node.transitions.next = gotoTarget
                end
                return true, nil
            end

            if stripped == "end" and scope and scope.node then
                if scope.kind == "reply" and scope.reaction then
                    scope.reaction.terminal = true
                else
                    scope.node.terminal = true
                end
                return true, nil
            end

            -- KV properties inside a choice (`label:`, `say:`, `intent:`, `subject:`, `when:`, `ai_bias:`, etc.)
            if scope and scope.kind == "choice" then
                local kvKey, kvVal = string.match(stripped, "^([%w_]+)%s*:%s*(.+)$")
                if kvKey and OFFER_KV_KEYS[kvKey] then
                    if kvKey == "when" then
                        local inner = trim(kvVal)
                        if string.sub(inner, 1, 1) == "[" and string.sub(inner, -1) == "]" then
                            inner = string.sub(inner, 2, #inner - 1)
                        end
                        local w, wErr = parsePredicates(inner, src, idx)
                        if wErr then self.err = wErr; return false, self.err end
                        scope.choice.when = w
                    elseif kvKey == "tone" then
                        scope.choice.style = stripQuotes(kvVal)
                    elseif kvKey == "ai_bias" then
                        scope.choice.aiBias = stripQuotes(kvVal)
                    else
                        scope.choice[kvKey] = stripQuotes(kvVal)
                    end
                    return true, nil
                end
            end

            -- Node-level `dialogue`/`pool`, `recommend`, `use`, `gate`, transitions, and `say`
            local nodePoolRef = string.match(stripped, "^dialogue%s+([%w_%.%-]+)$")
                or string.match(stripped, "^pool%s+([%w_%.%-]+)$")
            if nodePoolRef and scope and scope.node then
                scope.node.responsePool = nodePoolRef
                return true, nil
            end

            local recID = string.match(stripped, "^recommend%s+([%w_%.%-]+)$")
            if recID and scope and scope.node then
                if scope.kind == "reply" and scope.reaction then
                    scope.reaction.recommends[#scope.reaction.recommends + 1] = recID
                else
                    scope.node.recommends[#scope.node.recommends + 1] = recID
                end
                return true, nil
            end

            local useID = string.match(stripped, "^use%s+([%w_%.%-]+)$")
            if useID and scope and scope.node then
                scope.node.uses[#scope.node.uses + 1] = useID
                return true, nil
            end

            local gateInfo, gateErr = parseGateLine(stripped, src, idx)
            if gateErr and gateErr ~= false then
                self.err = gateErr; return false, self.err
            elseif gateInfo and scope and scope.node then
                scope.node.gate = gateInfo
                return true, nil
            end

            local trKey, trVal = string.match(stripped, "^([%w_]+)%s*:%s*([%w_%.%-]+)$")
            if trKey and NODE_TRANSITION_KEYS[trKey] and scope and scope.node then
                scope.node.transitions[NODE_TRANSITION_KEYS[trKey]] = trVal
                return true, nil
            end

            local sayInfo, sayErr = parseSpeechLine(stripped, "say", src, idx, idx)
            if sayErr and sayErr ~= false then
                self.err = sayErr; return false, self.err
            elseif sayInfo then
                if not scope then
                    local rootNode = newStoryNode(self._currentStory, "start", false, idx, self.theme, self.pack)
                    self._currentStory.initial = self._currentStory.initial or "start"
                    scope = { kind = "node", node = rootNode, indent = lineIndent }
                    self._storyStack[1] = scope
                end
                if sayInfo.inlineText ~= nil then
                    scope.node.variants[#scope.node.variants + 1] = {
                        variantID = autoVariantID(scope.node, sayInfo.explicitID, 1),
                        fallback = sayInfo.inlineText,
                        when = sayInfo.when,
                        priority = sayInfo.priority,
                        theme = self.theme,
                        lineNo = idx,
                    }
                else
                    self._activeSay = sayInfo
                    self._activeSayTarget = scope.node
                    self._activeSayCount = 0
                end
                return true, nil
            end

            self.err = src .. ":" .. tostring(idx) .. ": unrecognized story statement '" .. stripped .. "'"
            return false, self.err
        end

        if self._currentLex ~= nil then
            local words, when, pri, lexErr = parseLexEntry(stripped, src, idx, idx)
            if lexErr == false then
                self.err = src .. ":" .. tostring(idx) .. ": invalid lexicon entry '" .. stripped .. "'"
                return false, self.err
            elseif lexErr then
                self.err = lexErr
                return false, self.err
            end
            self._currentLex.entries[#self._currentLex.entries + 1] = {
                words = words,
                when = when,
                priority = pri,
                lineNo = idx,
            }
            return true, nil
        end

        if self._currentPool == nil and self._currentBlueprint == nil then
            self.err = src .. ":" .. tostring(idx)
                .. ": expected lexicon/blueprint/pool/beat/flow/extend/story header before '" .. stripped .. "'"
            return false, self.err
        end

        local useID = self._currentPool ~= nil and string.match(stripped, "^use%s+([%w_%.%-]+)$") or nil
        if useID then
            self._currentOffer = nil
            self._currentPool.uses[#self._currentPool.uses + 1] = useID
            return true, nil
        end

        local choiceObj, choiceErr = parseChoiceHeader(stripped, src, idx)
        if choiceErr and choiceErr ~= false then
            self.err = choiceErr
            return false, self.err
        elseif choiceObj then
            self._currentOffer = choiceObj
            if self._currentBlueprint ~= nil then
                self._currentBlueprint.offers[#self._currentBlueprint.offers + 1] = self._currentOffer
            else
                self._currentPool.offers[#self._currentPool.offers + 1] = self._currentOffer
            end
            return true, nil
        end

        local offerID = string.match(stripped, "^offer%s+([%w_%.%-]+)%s*:$")
        if offerID then
            self._currentOffer = {
                offerID = offerID,
                label = "",
                say = "",
                intent = "INFORM",
                subject = "",
                action = nil,
                claim = nil,
                style = nil,
                utility = nil,
                stateValue = nil,
                when = nil,
                lineNo = idx,
            }
            if self._currentBlueprint ~= nil then
                self._currentBlueprint.offers[#self._currentBlueprint.offers + 1] = self._currentOffer
            else
                self._currentPool.offers[#self._currentPool.offers + 1] = self._currentOffer
            end
            return true, nil
        end

        if self._currentOffer ~= nil then
            local kvKey, kvVal = string.match(stripped, "^([%w_]+)%s*:%s*(.+)$")
            if kvKey and OFFER_KV_KEYS[kvKey] then
                if kvKey == "when" then
                    local inner = trim(kvVal)
                    if string.sub(inner, 1, 1) == "[" and string.sub(inner, -1) == "]" then
                        inner = string.sub(inner, 2, #inner - 1)
                    end
                    local w, wErr = parsePredicates(inner, src, idx)
                    if wErr then
                        self.err = wErr
                        return false, self.err
                    end
                    self._currentOffer.when = w
                elseif kvKey == "tone" then
                    self._currentOffer.style = stripQuotes(kvVal)
                elseif kvKey == "ai_bias" then
                    self._currentOffer.aiBias = stripQuotes(kvVal)
                else
                    self._currentOffer[kvKey] = stripQuotes(kvVal)
                end
                return true, nil
            end
        end

        if self._currentPool == nil then
            self.err = src .. ":" .. tostring(idx) .. ": unrecognized statement '" .. stripped .. "'"
            return false, self.err
        end

        local sayInfo, sayErr = parseSpeechLine(stripped, "say", src, idx, idx)
        if sayErr == false then
            self.err = src .. ":" .. tostring(idx) .. ": unrecognized statement '" .. stripped .. "'"
            return false, self.err
        elseif sayErr then
            self.err = sayErr
            return false, self.err
        end

        self._currentOffer = nil
        if sayInfo.inlineText ~= nil then
            local pool = self._currentPool
            pool.variants[#pool.variants + 1] = {
                variantID = autoVariantID(pool, sayInfo.explicitID, 1),
                fallback = sayInfo.inlineText,
                when = sayInfo.when,
                priority = sayInfo.priority,
                theme = pool.theme,
                lineNo = idx,
            }
        else
            self._activeSay = sayInfo
            self._activeSayTarget = self._currentPool
            self._activeSayCount = 0
        end
        return true, nil
    end

    function stream:finish()
        if self.err then return nil, self.err end
        if not closeActiveSay() then return nil, self.err end
        local src = self.sourcePath

        local seenLex = {}
        for i = 1, #self.lexicons do
            local lx = self.lexicons[i]
            if lx.mode ~= "extend" then
                if seenLex[lx.lexID] then
                    return nil, src .. ":" .. tostring(lx.lineNo) .. ": duplicate lexicon '" .. lx.lexID .. "'"
                end
                seenLex[lx.lexID] = true
            end
            if #lx.entries == 0 then
                return nil, src .. ":" .. tostring(lx.lineNo) .. ": lexicon '" .. lx.lexID .. "' has no entries"
            end
        end

        local seenPools = {}
        for i = 1, #self.pools do
            local pool = self.pools[i]
            if pool.mode ~= "extend" then
                if seenPools[pool.poolID] then
                    return nil, src .. ":" .. tostring(pool.lineNo) .. ": duplicate pool '" .. pool.poolID .. "'"
                end
                seenPools[pool.poolID] = true
            end
            if #pool.variants == 0 and #pool.offers == 0 and #pool.uses == 0 then
                return nil, src .. ":" .. tostring(pool.lineNo)
                    .. ": pool '" .. pool.poolID .. "' has no 'say' variants"
            end
            local seenVars = {}
            for j = 1, #pool.variants do
                local v = pool.variants[j]
                if seenVars[v.variantID] then
                    return nil, src .. ":" .. tostring(v.lineNo)
                        .. ": duplicate variant '" .. v.variantID .. "' in pool '" .. pool.poolID .. "'"
                end
                seenVars[v.variantID] = true
            end
        end

        for i = 1, #self.stories do
            local st = self.stories[i]
            local activeNodes = {}
            for j = 1, #st.nodes do
                if not st.nodes[j]._unused then
                    activeNodes[#activeNodes + 1] = st.nodes[j]
                end
            end
            st.nodes = activeNodes
            if st.mode ~= "extend" and #st.nodes == 0 then
                return nil, src .. ":" .. tostring(st.lineNo)
                    .. ": story '" .. st.storyID .. "' has no nodes"
            end
        end

        return {
            sourcePath = self.sourcePath,
            namespace = self.namespace,
            language = self.language,
            theme = self.theme,
            pack = self.pack,
            lexicons = self.lexicons,
            blueprints = self.blueprints,
            pools = self.pools,
            stories = self.stories,
        }, nil
    end

    return stream
end

function Parser.ParseText(text, sourcePath, defaultLang)
    local stream = Parser.NewStream(sourcePath, defaultLang)
    local normalized = string.gsub(tostring(text or ""), "\r\n", "\n")
    normalized = string.gsub(normalized, "\r", "\n")
    local pos = 1
    local len = #normalized
    while pos <= len do
        local nl = string.find(normalized, "\n", pos, true)
        local line
        if not nl then
            line = string.sub(normalized, pos)
            pos = len + 1
        else
            line = string.sub(normalized, pos, nl - 1)
            pos = nl + 1
        end
        local ok, err = stream:feedLine(line)
        if not ok then return nil, err end
    end
    return stream:finish()
end

return Parser
