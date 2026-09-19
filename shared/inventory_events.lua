-- The neutral CoreX item events.
--
-- An event name that starts with a resource name is a dependency written in
-- string form: every resource that listens for `corex-inventory:client:useItem`
-- is tied to that one inventory even though it never calls it. These names
-- belong to CoreX instead, so whichever inventory is installed can raise them
-- and everything else can listen without knowing who did.
--
-- This file is the canonical copy. Every resource that raises or listens for
-- one of these events ships a byte-identical copy at
-- `shared/inventory_events.lua`, and
-- `corex-capabilities/tests/test_replaceable_modules.py` fails if a copy drifts.
-- It is copied rather than included so that no CoreX module gains a dependency
-- on the compatibility layer just to know an event name.
--
-- The inventory that ships with CoreX raises its own legacy names as well, so
-- nothing that already listened for them stops working.

CoreXInventoryEvents = CoreXInventoryEvents or {
    -- Raised by the inventory when a player uses an item.
    -- (itemName, itemData)
    UseItem = 'corex:inventory:client:useItem',

    -- Raised by the inventory when a player's carried items change.
    -- (items)
    SyncInventory = 'corex:inventory:client:syncInventory',

    -- Asks the inventory to show a container's contents.
    -- (containerId, items, label, revealDelay)
    OpenContainer = 'corex:inventory:client:openContainer',

    -- Tells the inventory that one item in the open container was taken.
    -- (itemIndex)
    ContainerItemTaken = 'corex:inventory:client:containerItemTaken',

    -- Asks the inventory to put a looted item on the ground near a player.
    -- (source, itemName, count, coords)
    AddLootItem = 'corex:inventory:server:addLootItem',
}
