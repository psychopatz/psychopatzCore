-- Smoke test for baseline instrumentation and contract reproducibility
local harness = dofile("tools/refactor_baseline/baseline_harness.lua")

-- Since baseline_harness.lua runs the bootstrap for arg[1], let's also test via subprocess or direct require
local res = os.execute("lua tools/refactor_baseline/baseline_harness.lua shared > /tmp/baseline_shared.log 2>&1")
assert(res == 0 or res == true, "baseline_harness shared failed to execute")

local res_server = os.execute("lua tools/refactor_baseline/baseline_harness.lua server > /tmp/baseline_server.log 2>&1")
assert(res_server == 0 or res_server == true, "baseline_harness server failed to execute")

print("psychopatz baseline smoke: ok")
