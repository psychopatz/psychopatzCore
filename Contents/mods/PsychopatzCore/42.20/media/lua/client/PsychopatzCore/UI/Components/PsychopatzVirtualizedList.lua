require "ISUI/ISScrollingListBox"

-- Fixed-row virtualization for reusable PsychopatzCore lists.
--
-- The PZ list widget walks every row in prerender(), even when only a small
-- portion of the list is visible. The public component keeps the native
-- interaction model while composing focused metric, collection, navigation,
-- and renderer providers.
local VirtualizedList = {}
local Internal = VirtualizedList.Internal or {}
VirtualizedList.Internal = Internal
PsychopatzCore.UI.VirtualizedList = VirtualizedList

require "PsychopatzCore/UI/Components/PsychopatzVirtualizedList_Metrics"
require "PsychopatzCore/UI/Components/PsychopatzVirtualizedList_Collections"
require "PsychopatzCore/UI/Components/PsychopatzVirtualizedList_Navigation"
require "PsychopatzCore/UI/Components/PsychopatzVirtualizedList_Renderer"

function VirtualizedList.Install(list)
    if not list or list.psychopatzVirtualizedInstalled then return list end

    list.psychopatzVirtualizedInstalled = true
    list.psychopatzVirtualized = true
    list.psychopatzVirtualMetricsDirty = true

    local native = {
        clear = list.clear,
        removeItem = list.removeItem,
        removeItemByIndex = list.removeItemByIndex,
        removeFirst = list.removeFirst,
        rowAt = list.rowAt,
        topOfItem = list.topOfItem,
        ensureVisible = list.ensureVisible,
        prerender = list.prerender,
    }

    -- Install mutation and navigation wrappers before the renderer so all
    -- providers share the same captured native contract.
    Internal.installCollections(list, native)
    Internal.installNavigation(list, native)
    Internal.installRenderer(list, native)

    return list
end

return VirtualizedList
