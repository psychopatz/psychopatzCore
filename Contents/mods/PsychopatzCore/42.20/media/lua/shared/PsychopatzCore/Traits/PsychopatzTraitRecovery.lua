-- Orphaned character-trait recovery.
--
-- Why this exists
-- ---------------
-- Build 42 stores a character's traits as a list of ResourceLocation strings in
-- CharacterTraits.knownTraits. Traits contributed by a mod are registered into
-- the engine catalog at boot; if that mod is later disabled, the saved trait
-- names no longer resolve to a registered CharacterTrait.
--
-- The engine does not defend against this. In CharacterTraits.load/read the
-- lookup result is passed straight to add(...), which pushes it onto
-- knownTraits. A failed lookup therefore becomes a literal nil element:
--
--     characterTrait = CharacterTrait.get(ResourceLocation.of(name))  -- nil
--     this.add(characterTrait)                                        -- nil stored
--
-- Saving then iterates knownTraits and dereferences the location:
--
--     Registries.CHARACTER_TRAIT.getLocation(characterTrait).toString()
--
-- which throws for the nil entry. The character loads fine and the damage only
-- surfaces on the *next* save, so a save can look healthy while already being
-- unrecoverable without manual file surgery.
--
-- What this module does
-- ---------------------
-- On character create/load, before anything can re-save the character, it
-- removes every known trait that has no registered CharacterTraitDefinition.
-- Removal is by trait object identity (and name, for Lua-side doubles), which
-- is exactly what CharacterTraits.remove handles: it deletes the entry from
-- knownTraits, clearing the nil that would otherwise crash serialization.
--
-- Scope and safety
-- ----------------
-- This is a mechanism, not a policy: it knows nothing about which mods own
-- which traits. It never removes a trait that is still registered, so it is a
-- no-op while the owning mod is enabled, and it does not depend on
-- PsychopatzCore having registered any trait itself. Vanilla traits always
-- resolve and are therefore never touched.
--
-- What it cannot undo
-- -------------------
-- Perk levels granted at character creation are baked into the save and are not
-- recomputed here. A removed trait's XP boost stays applied.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Traits = PsychopatzCore.Traits or {}

local Recovery = PsychopatzCore.Traits.Recovery or {}
PsychopatzCore.Traits.Recovery = Recovery

Recovery.VERSION = 1

-- Bounded: one pass over a character's known traits, plus one retry window for
-- the engine not having synchronized the trait container yet.
Recovery.MAX_RETRIES = 10

local function call(target, methodName, ...)
    if not target then return nil end
    local method = target[methodName]
    if type(method) ~= "function" then return nil end
    local ok, result = pcall(method, target, ...)
    return ok and result or nil
end

-- A trait is "orphaned" when the engine holds an object for it but no
-- CharacterTraitDefinition is registered. A true nil entry (what load() stores
-- for an unresolvable name) is orphaned as well.
local function isOrphaned(trait)
    if not CharacterTraitDefinition
        or type(CharacterTraitDefinition.getCharacterTraitDefinition) ~= "function"
    then
        -- Without the lookup API we cannot prove a trait is unknown, so we
        -- deliberately do nothing rather than risk stripping valid traits.
        return false
    end
    if trait == nil then return true end
    local ok, definition = pcall(
        CharacterTraitDefinition.getCharacterTraitDefinition, trait
    )
    if not ok then return false end
    return definition == nil
end

local function knownList(characterTraits)
    local known = call(characterTraits, "getKnownTraits")
    if type(known) ~= "table" then return nil end
    return known
end

-- The engine returns a java.util.List, so `size()` is authoritative. A Lua table
-- double cannot be measured with `#` here: an orphaned trait is stored as a nil
-- entry, and `#` stops at the first hole (a trailing nil even reads as length 0),
-- which would hide the very entry we must remove. Fall back to the highest
-- present index instead.
local function entryCount(known)
    local size = call(known, "size")
    if size ~= nil then
        return math.max(0, tonumber(size) or 0), true
    end
    -- A Lua table: scan for the highest present index so a hole does not truncate
    -- the range. `#known` is only a starting hint.
    local highest = #known
    local key
    for key in pairs(known) do
        if type(key) == "number" and key > highest then
            highest = key
        end
    end
    return highest, false
end

-- Collects orphaned entries first, then removes them, so the known-trait list is
-- never mutated while it is being indexed.
--
-- A nil entry cannot be stored in `orphans` (assigning nil is a no-op), yet a nil
-- entry is exactly what the engine produces for an unresolvable trait name. So
-- orphans are recorded as {trait = value} wrappers, and an explicit count is kept
-- instead of relying on `#`.
local function collectOrphans(characterTraits)
    local known = knownList(characterTraits)
    if not known then return nil, "traits_not_ready" end

    local total, indexed = entryCount(known)
    local index
    local trait
    local orphans = {}
    local count = 0
    local function consider(value)
        if isOrphaned(value) then
            count = count + 1
            orphans[count] = { trait = value }
        end
    end
    if indexed then
        for index = 0, total - 1 do
            consider(call(known, "get", index))
        end
    else
        for index = 1, total do
            consider(known[index])
        end
    end
    return { entries = orphans, count = count }, "ready", total
end

-- Removes orphaned traits from one character. Returns removed count, reason.
function Recovery.SanitizeCharacter(character)
    if not character then return 0, "no_character" end
    local characterTraits = call(character, "getCharacterTraits")
    if not characterTraits then return 0, "no_trait_container" end

    local batch, reason, total = collectOrphans(characterTraits)
    if not batch then return 0, reason end
    if batch.count == 0 then return 0, "clean" end

    local removed = 0
    local index
    local entry
    for index = 1, batch.count do
        entry = batch.entries[index]
        -- The engine reports the boolean result of the removal; a nil entry
        -- (`trait == nil`) is removed by passing nil to remove(...).
        local result = call(characterTraits, "remove", entry.trait)
        if result == true or result == nil then
            removed = removed + 1
        end
    end
    return removed, "sanitized", total
end

local function describe(removed, reason, total)
    if removed > 0 then
        return "[PsychopatzCore] Recovered character traits: removed="
            .. tostring(removed) .. " of=" .. tostring(total) .. " reason="
            .. tostring(reason)
            .. " (traits from a disabled mod were cleared to keep the save writable)"
    end
    return nil
end

function Recovery.Log(removed, reason, total)
    local message = describe(removed, reason, total)
    if not message then return end
    if PsychopatzCore.LogWarning then
        PsychopatzCore.LogWarning(message)
    elseif print then
        print(message)
    end
end

-- Runs the sanitizer, retrying while the engine has not yet synchronized a
-- character's trait container. OnCreatePlayer fires before the first save of
-- the session, so this always precedes the write that would otherwise crash.
--
-- Event argument order is not guaranteed across builds, so both arguments are
-- accepted and the player object is identified by capability rather than by
-- position. Only a string/number index is used as a retry key.
local function isCharacter(value)
    return type(value) == "table" or type(value) == "userdata"
end

local function keyFor(playerIndex, player)
    if type(playerIndex) == "string" or type(playerIndex) == "number" then
        return playerIndex
    end
    return player
end

local function sanitizePlayer(first, second)
    local player
    if isCharacter(second) then
        player = second
    end
    if not isCharacter(player) and isCharacter(first) then
        player = first
    end
    if not isCharacter(player) and getSpecificPlayer then
        player = getSpecificPlayer(0)
    end
    if not isCharacter(player) then return end

    local removed, reason, total = Recovery.SanitizeCharacter(player)
    if reason == "traits_not_ready" then
        Recovery.Pending = Recovery.Pending or {}
        local key = keyFor(first, player)
        local state = Recovery.Pending[key]
        if not state then
            state = { attempts = 0 }
            Recovery.Pending[key] = state
        end
        if state.attempts >= Recovery.MAX_RETRIES then
            Recovery.Pending[key] = nil
            return
        end
        state.attempts = state.attempts + 1
        state.player = player
        return
    end

    if Recovery.Pending then Recovery.Pending[keyFor(first, player)] = nil end
    Recovery.Log(removed, reason, total)
end

-- Retry hook for the "traits not ready" window. Dropping the table entirely once
-- nothing is pending keeps this at one nil check per tick in the normal case.
-- Exposed so diagnostics and tests can drive the retry pass directly.
function Recovery.RetryPending()
    local pending = Recovery.Pending
    if not pending then return end
    -- Clearing entries while iterating a table with pairs is not reliable, so
    -- finished keys are collected and removed afterwards.
    local done = {}
    local doneCount = 0
    local stillPending = 0
    local index
    local state
    for index, state in pairs(pending) do
        local removed, reason, total = Recovery.SanitizeCharacter(state.player)
        if reason ~= "traits_not_ready" then
            doneCount = doneCount + 1
            done[doneCount] = index
            Recovery.Log(removed, reason, total)
        elseif state.attempts >= Recovery.MAX_RETRIES then
            doneCount = doneCount + 1
            done[doneCount] = index
        else
            state.attempts = state.attempts + 1
            stillPending = stillPending + 1
        end
    end
    for index = 1, doneCount do
        pending[done[index]] = nil
    end
    if stillPending == 0 then
        Recovery.Pending = nil
    end
end

function Recovery.Install()
    if Recovery.Installed then return false, "already_installed" end
    if not Events then return false, "no_events" end

    if Events.OnCreatePlayer and Events.OnCreatePlayer.Add then
        Events.OnCreatePlayer.Add(sanitizePlayer)
    end
    if Events.OnPlayerUpdate and Events.OnPlayerUpdate.Add then
        Events.OnPlayerUpdate.Add(Recovery.RetryPending)
    end

    Recovery.Installed = true
    return true, "installed"
end

Recovery.Install()

return Recovery