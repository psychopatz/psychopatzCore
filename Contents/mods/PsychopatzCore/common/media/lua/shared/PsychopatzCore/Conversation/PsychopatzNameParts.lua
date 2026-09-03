-- Small, engine-agnostic name normalizer shared by conversation systems.
--
-- Full names are retained for UI identity, while addressName/firstName is
-- used when dialogue addresses a person.  This keeps long character names
-- from being repeated in ordinary speech without losing surname data.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}
PsychopatzCore.Conversation.NameParts =
    PsychopatzCore.Conversation.NameParts or {}

local Names = PsychopatzCore.Conversation.NameParts

local function readMethod(object, method)
    if not object or type(object[method]) ~= "function" then
        return nil
    end
    local ok, value = pcall(object[method], object)
    return ok and value or nil
end

local function clean(value)
    if value == nil then return nil end
    value = tostring(value)
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    value = string.gsub(value, "%s+", " ")
    return value ~= "" and value or nil
end

function Names.Split(fullName, firstName, surname)
    fullName = clean(fullName)
    firstName = clean(firstName)
    surname = clean(surname)

    if not firstName and fullName then
        firstName = string.match(fullName, "^(%S+)")
    end
    if not surname and fullName then
        surname = string.match(fullName, "^%S+%s+(.+)$")
    end
    if not fullName then
        fullName = clean(table.concat({ firstName or "", surname or "" }, " "))
    end

    return {
        fullName = fullName,
        firstName = firstName or fullName,
        surname = surname or "",
        -- Existing Hoomans code calls this field lastName. Keep both names
        -- available so the shared contract can be adopted incrementally.
        lastName = surname or "",
        addressName = firstName or fullName,
    }
end

function Names.ForPlayer(player, context)
    context = type(context) == "table" and context or {}
    local descriptor = player and readMethod(player, "getDescriptor") or nil
    local firstName = clean(context.forename)
        or clean(context.firstName)
        or clean(readMethod(descriptor, "getForename"))
    local surname = clean(context.surname)
        or clean(context.lastName)
        or clean(readMethod(descriptor, "getSurname"))
    local fullName = clean(context.displayName)
        or clean(readMethod(player, "getDisplayName"))
        or clean(readMethod(player, "getUsername"))
    return Names.Split(fullName, firstName, surname)
end

return Names
