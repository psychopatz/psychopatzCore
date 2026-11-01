-- Smoke test for capability contract and built-in catalog validation

package.path = table.concat({
    "Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua",
    "Contents/mods/PsychopatzCore/42.20/media/lua/shared/?.lua",
    package.path,
}, ";")

local Contract = require "PsychopatzCore/Kernel/PC_CapabilityContract"
local Catalog = require "PsychopatzCore/Kernel/PC_CapabilityCatalog"

local function assertEqual(actual, expected, msg)
    if actual ~= expected then
        error((msg or "mismatch") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

-- 1. Validation tests
assertEqual(Contract.ValidateDescriptor(nil), false, "nil descriptor should fail")
assertEqual(Contract.ValidateDescriptor({}), false, "empty descriptor should fail")
assertEqual(Contract.ValidateDescriptor({ id = "   " }), false, "whitespace id should fail")
assertEqual(Contract.ValidateDescriptor({ id = "test", roles = { invalid_role = true } }), false, "invalid role should fail")
assertEqual(Contract.ValidateDescriptor({ id = "test", roles = { shared = true }, depends = { 123 } }), false, "non-string dependency should fail")

local ok, err = Contract.ValidateDescriptor({
    id = "test.valid",
    domain = "Test",
    roles = { shared = true, client = true },
    depends = { "other.dep" },
    load = function() return true end,
})
assertEqual(ok, true, "valid descriptor failed: " .. tostring(err))

-- 2. Pack validation
assertEqual(Contract.ValidatePack({}), false, "empty pack should fail")
assertEqual(Contract.ValidatePack({ id = "test.pack", capabilities = {} }), false, "pack without capabilities should fail")

-- 3. Catalog integrity
local descCount = 0
for id, desc in pairs(Catalog.descriptors) do
    descCount = descCount + 1
    assertEqual(desc.id, id, "descriptor key matches id")
    local v_ok, v_err = Contract.ValidateDescriptor(desc)
    assertEqual(v_ok, true, "catalog descriptor '" .. id .. "' failed validation: " .. tostring(v_err))

    -- Check that all declared dependencies exist in the catalog
    if desc.depends then
        for _, depId in ipairs(desc.depends) do
            assert(Catalog.descriptors[depId] ~= nil, "catalog descriptor '" .. id .. "' depends on unknown capability '" .. depId .. "'")
        end
    end
end
assert(descCount >= 25, "expected at least 25 descriptors in catalog, got " .. tostring(descCount))

local packCount = 0
for packId, pack in pairs(Catalog.packs) do
    packCount = packCount + 1
    assertEqual(pack.id, packId, "pack key matches id")
    local p_ok, p_err = Contract.ValidatePack(pack)
    assertEqual(p_ok, true, "catalog pack '" .. packId .. "' failed validation: " .. tostring(p_err))

    for _, capId in ipairs(pack.capabilities) do
        assert(Catalog.descriptors[capId] ~= nil, "pack '" .. packId .. "' references unknown capability '" .. capId .. "'")
    end
end
assert(packCount >= 3, "expected at least 3 packs in catalog, got " .. tostring(packCount))

print("psychopatz capability contract smoke: ok")
