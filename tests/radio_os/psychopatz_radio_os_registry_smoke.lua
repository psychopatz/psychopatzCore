local CLIENT = "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
local COMMON = "Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = CLIENT .. "?.lua;" .. COMMON .. "?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy", 2) end
end

PsychopatzCore = {}
dofile(COMMON .. "PsychopatzCore/Radio/PC_RadioDeviceState.lua")
local Manifest = dofile(CLIENT
    .. "PsychopatzCore/UI/Radio/OS/PsychopatzRadioManifest.lua")
local OS = dofile(CLIENT
    .. "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSRegistry.lua")

local validManifest, manifestErrors = Manifest.Validate()
truthy(validManifest, table.concat(manifestErrors or {}, ","))
equal(Manifest.GetSkin("Base.WalkieTalkie5").id,
    "walkie_usarmy_shell", "manifest skin")
equal(Manifest.GetSkin("Base.HamRadio1"), nil, "deferred HAM skin")

local device = {
    fullType = "Base.WalkieTalkie5",
    getFullType = function(self) return self.fullType end,
    getIsPortable = function() return true end,
    getIsTwoWay = function() return true end,
    getIsTelevision = function() return false end,
    getIsTurnedOn = function() return true end,
    getPower = function() return 1 end,
    getDeviceVolume = function() return 1 end,
    getMicIsMuted = function() return false end,
}
local player = { getPlayerNum = function() return 0 end }
getSpecificPlayer = function() return player end

local context = assert(OS.GetDeviceContext(0, device))
equal(context.active, true, "active device")
equal(context.fullType, "Base.WalkieTalkie5", "device full type")
equal(context.skin.id, "walkie_usarmy_shell", "device skin")

local appID = "dummy:app"
local callbackAppID = "dummy:callback"
local providerID = "dummy:contacts"
OS.UnregisterApp(appID)
OS.UnregisterApp(callbackAppID)
OS.UnregisterContactProvider(providerID)
truthy(OS.RegisterApp({
    id = appID,
    ownerModID = "DummyPlugin",
    label = "Dummy",
    page = "custom",
    order = 1,
}), "app registration")
truthy(OS.RegisterApp({
    id = callbackAppID,
    ownerModID = "DummyPlugin",
    label = "Callback",
    open = function() return "custom" end,
}), "callback app registration")
truthy(OS.RegisterContactProvider({
    id = providerID,
    ownerModID = "DummyPlugin",
    list = function(_, page)
        equal(page.limit, 12, "bounded provider page")
        return {
            contacts = {
                { id = "b", title = "Bravo", status = "known",
                    actions = { "dummy:ping" } },
                { id = "a", title = "Alpha", status = "ready",
                    actions = { { id = "dummy:ping", label = "Ping" } } },
                { id = "a", title = "Duplicate" },
            },
            total = 3,
            revision = 4,
        }
    end,
    invoke = function(_, contactID, actionID)
        equal(contactID, "a", "contact dispatch ID")
        equal(actionID, "dummy:ping", "contact dispatch action")
        return { ok = true, requestID = "bounded" }
    end,
}), "provider registration")

local listed, page = OS.ListContacts(providerID, context, { limit = 999 })
truthy(listed, "provider listing")
equal(#page.contacts, 2, "deduplicated contacts")
equal(page.contacts[1].title, "Alpha", "deterministic contact sort")
local invoked = OS.InvokeContact(providerID, context, "a", "dummy:ping",
    page.contacts[1])
truthy(invoked, "provider action")
local before = OS.GetRegistryRevision()
truthy(OS.EmitContactRefresh(providerID), "refresh event")
truthy(OS.GetRegistryRevision() > before, "refresh revision")
truthy(OS.UnregisterContactProvider(providerID), "provider unload")
truthy(OS.UnregisterApp(appID), "app unload")
truthy(OS.UnregisterApp(callbackAppID), "callback app unload")

print("psychopatz_radio_os_registry_smoke: ok")
