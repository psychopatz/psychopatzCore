# ConvoEngine Handoff

~~~yaml
status: DIRTY_RESUMABLE
checkpoint_mode: dirty_snapshot
phase_commit: none
phase: S12R2 — Final Closure Integrity Repair
chunk: S12R2A — member-complete retention proof
primary_repo: /home/psychopatz/Zomboid/Workshop/psychopatzCore
branch: main
goal_doc: Docs/semantic_dialogue_language_standard/S12R2_FINAL_CLOSURE_INTEGRITY_REPAIR.md
parent_goal: Docs/semantic_dialogue_language_standard/S12_CONVO_ENGINE_V1_DATASET_MODERNIZATION.md
retained_goal: Docs/semantic_dialogue_language_standard/S12R1_STRUCTURAL_DATASET_MODERNIZATION_CLOSURE_REPAIR.md
authoring_standard: Docs/semantic_dialogue_language_standard/DYNAMIC_COMPOSITION_AND_DATASET_AUTHORING.md
updated_at: 2026-11-19
~~~

## Planning audit participant vector

~~~text
psychopatzCore   43a02e3dad695f65d251ff137765d83e8b00d912
ProjectHoomans   4dce40499d62e9f54836a4b4c2df37f4b8b08656
DynamicTrading   aecc3250068202cdf1701b2bd49e8892abfba87c
~~~

The current Core documentation checkpoint is the commit containing this HANDOFF. Resolve that commit from Git on resume; the vector above is the audited pre-documentation baseline used to identify concurrent work.

Planning-time residual fingerprints:

~~~text
psychopatzCore   rows=8   sha256=acc8d627aa8a52635af59c0aabe217c1314162dd87f3933cd21eb4f1307985d6
ProjectHoomans   rows=6   sha256=775bc6567f904a09a6c699fe0028aeb1e2be7bb0491770ab6b482cf1fdebc36e
DynamicTrading   rows=2   sha256=ab22639e384c1da211005e25b5af7cdc6fd2222ddf108b71ba4ee3628e7d70d5
~~~

Concurrent portrait/editor/radio work is unrelated and must be preserved exactly.

Three current dirty generated files are S12-owned, not unrelated:

~~~text
Contents/mods/PsychopatzCore/common/media/lua/shared/
PsychopatzCore/ConvoEngine/FoundationRegistry.lua

Contents/mods/DTCommon/common/media/lua/shared/DTCommon/ConvoEngine/Manifest.lua
Contents/mods/DTCommon/common/media/lua/shared/DTCommon/ConvoEngine/Registry.lua
~~~

They currently carry the desired whole-model fingerprint
`bfcc2d3b251785f9ef35f347cf93754103b33c119fd45de0090b64a53a280fb7`
and must be reconciled/committed during S12R2C rather than discarded.

## Retained implementation truth

The expensive S12R1 structural work is accepted as the starting point:

~~~text
587 → 470 maintained families
large specialization/context clusters collapsed
behavior/beat hooks added
source schema = psychopatz.convo-engine.v1 only
open actionable family/group = 0 under current verifier
split authority = 0
missing composition hooks = 0
focused audit tests = 26/26 PASS
two current full acceptance runs = 9/9, convoScopeOk=true
~~~

Do not redo broad S12R1 modernization.

## Immediate Next Chunk — S12R2A

Strengthen intentional-retention proof so an N-member group cannot be accepted
from only partial distinctness.

Audit and resolve/re-prove at minimum:

~~~text
domain_cluster:ProjectHoomans:ui.suggestion.identity
context_variant:ProjectHoomans:social.greetings
~~~

`real` and `lie` currently share `INFORM + IDENTITY`; truthful/deceptive meaning
must be represented and verified semantically or the overlap must be
collapsed/parameterized.

The social-greeting verifier must prove actual non-parameterizability rather
than only distinct predicates.

Then continue automatically through S12R2B, S12R2C and S12R2D.

Do not push, publish Workshop content, reset/stash unrelated work, or launch
native Project Zomboid.
