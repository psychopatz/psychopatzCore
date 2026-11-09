# Semantic Harness Migration Architecture

## Boundary

PsychopatzCore owns the semantic harness mechanism: worker lifecycle, bounded
protocol, scenario execution, inspection, generic tests, and CodeBuilder
compilation. Project Hoomans and Dynamic Trading provide adapters and content.

The Core harness must remain usable with no adopter repository present. An
adopter is selected by an explicit provider profile, not by a Core import or a
hard-coded Hoomans-first bootstrap.

## Profiles

The planned profiles are:

| Profile | Required providers | Representation |
| --- | --- | --- |
| `core` | `PsychopatzCore` | none |
| `hoomans` | Core + `ProjectHoomans` | physical |
| `dtabstract` | Core + `DTCommon` + `DTAbstract` | abstract |
| `dthoomans` | Core + `DTCommon` + `ProjectHoomans` + `DTHoomans` | physical |
| `combined` | Core + Hoomans + DTCommon + DTHoomans | physical |

`DTAbstract` and `DTHoomans` share Core actor identity, semantic IR,
conversation landing, and trading contracts. Their only intentional runtime
difference is whether a nearby actor is represented abstractly or materialized
as a physical NPC.

## Provider rule

The Core worker consumes provider descriptors and capabilities. It does not
know PNC, DTHoomans, DTAbstract, MarketSense, or PBrainZ module paths. Provider
load failures are isolated at the provider boundary and must report a bounded
diagnostic rather than corrupting Core state.

## Migration rule

Move mechanism before content. Hoomans conversation datasets, PNC policy,
save/profiler adapters, and first-party fixtures stay in Project Hoomans.
DTCommon trading content stays in DynamicTrading. The old Hoomans launcher may
temporarily delegate to the Core harness, but the final state has one engine,
one protocol, and one CodeBuilder.
