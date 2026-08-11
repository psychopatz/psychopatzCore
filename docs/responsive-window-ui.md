# Reusable responsive window UI

Use `PsychopatzWindow` for resizable windows and create controls exactly once in
`createChildren()`. Put each independently scrolling region inside its own
panel, then recompute only parent-relative bounds in `onResponsiveLayout()`.

## Required lifecycle

1. Create, initialize, and instantiate the window and each child control.
2. Add each control to the panel that owns its coordinate space.
3. In `onResponsiveLayout()`, resolve the content rectangle and lay out panels.
4. Lay out each panel's children relative to that panel, not to the screen or
   outer window.
5. Resize controls with `UI.Layout.SetBounds`.

```lua
function MyPane:layoutContent()
    local headerHeight = UI.Layout.Pixels(25, self.uiScale)
    UI.Layout.SetBounds(self.list, 0, headerHeight,
        self:getWidth(), self:getHeight() - headerHeight)
end
```

## Native scrollbar rule

Build 42 scrolling controls create `vscroll` or `hscroll` during
`instantiate()`. Their geometry does not reliably follow later direct
`setWidth()` or `setHeight()` calls. `ISScrollingListBox` also uses the vertical
scrollbar's x-position as a stencil boundary, so a stale tiny scrollbar can
clip the entire list even though the row data is present.

`UI.Layout.SetBounds` synchronizes native scrollbar geometry automatically.
For an unusual control that manages its own outer bounds, call
`UI.Layout.SyncNativeScrollbars(control)` after resizing it. Do not manually
position a scrollbar in every feature window.

## Container rules

- Give roster, detail, tree, and form regions their own panel when each can
  scroll or resize independently.
- A child uses coordinates relative to its immediate parent.
- Reserve header/footer space before sizing scroll content.
- Create controls once; refresh their rows or model instead of rebuilding the
  control tree.
- Reset list scroll state when replacing a complete dataset, then let the
  control recompute its scroll height.
- Keep rendering separate from layout and data binding. A refresh should not
  alter geometry.

## Regression checklist

- Resize narrower, wider, shorter, and taller after controls are instantiated.
- Verify the scrollbar remains on the content edge and fills its container.
- Verify the first and last rows render and can be selected after every resize.
- Test empty, one-row, and overflowing datasets.
- Test each tab after a window resize and after a manual data refresh.
- Test at the minimum supported resolution and UI scale.
