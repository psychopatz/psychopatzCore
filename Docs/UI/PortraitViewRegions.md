# Portrait region views

`PsychopatzCore.UI.PortraitPanel` supports camera-only framing for an existing
NPC/character preview. Consumers keep using `setTarget(character, spec, force)`
and `setPortraitBounds(...)` for content and layout.

```lua
local portrait = PsychopatzCore.UI.PortraitPanel:new(0, 0, 240, 500, {
    zoom = -3, yOffset = 0, animSetName = false, viewRegion = "body",
})
portrait:initialise()
portrait:instantiate()
portrait:setTarget(nil, spec, false)
portrait:setViewRegion("head")
portrait:setViewRegion("left_arm")
portrait:setViewRegion("body")
```

Available regions: `body`, `head`, `neck`, `torso`, `arms`, `left_arm`,
`right_arm`, `hands`, `waist`, `legs`, `feet`, `back`. The back view initially
faces north to expose backpacks. Aliases include `face`, `full`, `upper_body`,
`lower_body`, `held`, `carry` and `other`.

- `setViewRegion(name)` returns `true`, or `false, "unknown_view_region"` without
  changing the camera. Switching regions remembers user zoom, offsets,
  direction and isometric preference independently for each region.
- `setViewRegion(name, true)` resets that region to its default framing.
- `getViewRegion()` returns the canonical active name, or `nil` for an unframed
  consumer.
- `clearViewRegion()` restores the camera that existed before the first region
  selection. Existing consumers that never select a region retain their camera.

Framing never changes the supplied target/spec, filters clothes, reconstructs a
descriptor, registers an actor or writes NPC data. A head-focused loadout preview
can therefore retain hats; an appearance editor may separately request a
`faceOnly` clothing projection. Repeated `setTarget` calls retain the selected
camera. Manual controls can keep updating `zoom`, `xOffset`, `yOffset` and
`direction` followed by `applyCameraState()`. This applies only camera properties
and preserves ongoing portrait animation variables; `applyViewState()` remains
the broader existing state/animation refresh API.

The regression uses the real Core portrait/view composition with native widget
boundaries mocked. Live camera composition remains an adopter-owned native
visual acceptance check.
