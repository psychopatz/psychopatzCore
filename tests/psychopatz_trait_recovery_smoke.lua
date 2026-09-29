-- Verifies orphaned character-trait recovery.
--
-- Reproduces the save-breaking scenario: a character carries traits whose
-- CharacterTraitDefinition no longer exists (the owning mod was disabled).
-- Such traits must be removed from the character's known-trait list, because the
-- engine stores an unresolvable trait as a nil entry and then dereferences it
-- while saving.

local ROOT =
    "Contents/mods/PsychopatzCore/42.20/media/lua/shared/PsychopatzCore/Traits/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected="
            .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

-- Engine doubles ------------------------------------------------------------

local definitions = {}
local registered = {
    vanilla = { name = "vanilla", registered = true },
    pnc = { name = "pnc", registered = true },
}

CharacterTraitDefinition = {
    getCharacterTraitDefinition = function(trait)
        return definitions[trait]
    end,
}

-- Exercise the real engine path, including the nil entry the engine produces
-- when a saved trait name no longer resolves.
--
-- The engine backs this list with a java.util.ArrayList, so `size` is the
-- authoritative length and a nil element is a real element (indexable, and
-- removable by value). A plain Lua array cannot represent that -- it grows a
-- hole and `#` truncates -- so the double keeps its own count.
local function newCharacterTraits(entries, explicitCount)
    local known = {}
    -- `#entries` cannot see a trailing nil, so callers that need to model one
    -- pass the intended length explicitly.
    local count = explicitCount or #entries
    local index
    for index = 1, count do
        known[index] = entries[index]
    end
    local list = {
        size = function(self) return count end,
        get = function(self, i) return known[i + 1] end,
    }
    return {
        known = known,
        count = function() return count end,
        at = function(i) return known[i] end,
        getKnownTraits = function() return list end,
        remove = function(self, trait)
            local i
            for i = 1, count do
                if known[i] == trait then
                    -- ArrayList.remove(index) shifts the tail down, leaving no
                    -- trailing hole, which is why a trailing nil is really gone.
                    local j
                    for j = i, count - 1 do
                        known[j] = known[j + 1]
                    end
                    known[count] = nil
                    count = count - 1
                    return true
                end
            end
            return false
        end,
    }
end

local function newCharacter(characterTraits)
    return {
        getCharacterTraits = function() return characterTraits end,
    }
end

Events = {
    OnCreatePlayer = { Add = function() end },
    OnPlayerUpdate = { Add = function() end },
}

PsychopatzCore = {}
dofile(ROOT .. "PsychopatzTraitRecovery.lua")
local Recovery = PsychopatzCore.Traits.Recovery

-- 1. Registered traits are never touched ------------------------------------

definitions[registered.vanilla] = { cost = 2 }
definitions[registered.pnc] = { cost = 0 }
local healthy = newCharacterTraits({ registered.vanilla, registered.pnc })
local removed, reason = Recovery.SanitizeCharacter(newCharacter(healthy))
assertEqual(removed, 0, "healthy character: nothing removed")
assertEqual(reason, "clean", "healthy character: clean reason")
assertEqual(healthy.count(), 2, "healthy character: traits preserved")

-- 2. Orphaned traits are removed, registered ones preserved ----------------

local orphan = { name = "pnc_orphan" }
-- `orphan` is deliberately absent from `definitions`.
local mixed = newCharacterTraits({
    registered.vanilla, orphan, registered.pnc,
})
removed, reason = Recovery.SanitizeCharacter(newCharacter(mixed))
assertEqual(removed, 1, "mixed character: one orphan removed")
assertEqual(reason, "sanitized", "mixed character: sanitized reason")
assertEqual(mixed.count(), 2, "mixed character: size shrunk")
assertEqual(mixed.at(1), registered.vanilla, "mixed character: vanilla kept")
assertEqual(mixed.at(2), registered.pnc, "mixed character: registered kept")

-- 3. A literal nil entry (what the engine stores for an unresolvable name) --
--    is removed too, since a nil is what crashes serialization.

local withNil = newCharacterTraits({ registered.vanilla, nil }, 2)
assertEqual(withNil.count(), 2, "nil entry present before sanitize")
assertEqual(withNil.at(2), nil, "nil entry is the second element")
removed, reason = Recovery.SanitizeCharacter(newCharacter(withNil))
assertEqual(removed, 1, "nil entry removed")
assertEqual(withNil.count(), 1, "nil entry: list shrunk")
-- Prove no hole remains, i.e. the nil is gone rather than skipped over.
local index
local holes = 0
for index = 1, withNil.count() do
    if withNil.at(index) == nil then holes = holes + 1 end
end
assertEqual(holes, 0, "no nil holes remain after sanitize")

-- 4. Idempotent: a second pass is a no-op --------------------------------

removed, reason = Recovery.SanitizeCharacter(newCharacter(withNil))
assertEqual(removed, 0, "second pass removes nothing")
assertEqual(reason, "clean", "second pass is clean")

-- 5. Missing/undeclared inputs degrade instead of throwing ----------------

removed, reason = Recovery.SanitizeCharacter(nil)
assertEqual(removed, 0, "nil character")
assertEqual(reason, "no_character", "nil character reason")

removed, reason = Recovery.SanitizeCharacter({})
assertEqual(removed, 0, "character without trait container")
assertEqual(reason, "no_trait_container", "missing container reason")

-- 6. Without the definition lookup API we must not strip anything ----------

local savedLookup = CharacterTraitDefinition.getCharacterTraitDefinition
CharacterTraitDefinition.getCharacterTraitDefinition = nil
local guarded = newCharacterTraits({ registered.vanilla, orphan })
removed, reason = Recovery.SanitizeCharacter(newCharacter(guarded))
assertEqual(removed, 0, "no lookup API: nothing removed")
assertEqual(guarded.count(), 2, "no lookup API: traits preserved")
CharacterTraitDefinition.getCharacterTraitDefinition = savedLookup

-- 7. Install is guarded against double registration -----------------------

local ok = Recovery.Install()
assertEqual(ok, false, "second install rejected")

-- 8. Event wiring tolerates either argument order -------------------------
-- OnCreatePlayer has been observed with the player in either position, so both
-- shapes must reach the sanitizer.

local caught = {}
Events = {
    OnCreatePlayer = { Add = function(fn) caught.handler = fn end },
    OnPlayerUpdate = { Add = function() end },
}
Recovery.Installed = false
Recovery.Pending = nil
Recovery.Install()
assertEqual(type(caught.handler), "function", "OnCreatePlayer handler captured")

local orderTrait = { name = "order_orphan" }
-- Trait container first, index second.
local orderFirst = newCharacterTraits({ registered.vanilla, orderTrait })
caught.handler(newCharacter(orderFirst), 0)
assertEqual(orderFirst.count(), 1, "player passed as first argument sanitized")

-- Index first, player second, with a container that is not ready yet so we also
-- cover the retry bookkeeping.
local notReady = {
    getCharacterTraits = function()
        return { getKnownTraits = function() return nil end }
    end,
}
caught.handler(0, notReady)
assertEqual(Recovery.Pending ~= nil, true, "unready character queued for retry")

-- Once the container becomes ready, the retry pass clears the queue entirely so
-- the per-tick hook stops costing anything.
local lateOrphan = { name = "late_orphan" }
local lateTraits = newCharacterTraits({ registered.vanilla, lateOrphan })
local lateReady = { getCharacterTraits = function() return lateTraits end }
assertEqual(Recovery.Pending[0].player, notReady, "queued player recorded")
Recovery.Pending[0].player = lateReady
Recovery.RetryPending()
assertEqual(lateTraits.count(), 1, "queued character sanitized on retry")
assertEqual(Recovery.Pending, nil, "pending table dropped when empty")

print("psychopatz_trait_recovery_smoke: ok")