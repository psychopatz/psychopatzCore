local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local Util = require "PsychopatzCore/Inventory/PsychopatzInventoryUtil"
local ItemRecord = require "PsychopatzCore/Inventory/PsychopatzItemRecord"
local Metrics = require "PsychopatzCore/Inventory/PsychopatzInventoryMetrics"

local Tester = {}

function Tester.test(item, factory)
    local before, reason = ItemRecord.encode(item, 1)
    if not before then Metrics.increment("roundTripFailures") return false, reason end
    local decoded
    decoded, reason = ItemRecord.decode(before, factory)
    if not decoded then Metrics.increment("roundTripFailures") return false, reason end
    local after
    after, reason = ItemRecord.encode(decoded, 1)
    if not after then Metrics.increment("roundTripFailures") return false, reason end
    local checks = {
        type = before[C.TYPE_ID] == after[C.TYPE_ID],
        codec = before[C.CODEC_ID] == after[C.CODEC_ID],
        flags = before[C.FLAGS] == after[C.FLAGS],
        state = Util.canonical(before[C.STATE]) == Util.canonical(after[C.STATE]),
    }
    local passed = checks.type and checks.codec and checks.flags and checks.state
    if not passed then Metrics.increment("roundTripFailures") end
    return passed, checks, before, after
end

return Tester
