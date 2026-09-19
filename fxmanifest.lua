fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'corex-loot'
description 'COREX World Loot System'
author 'ABUGIZA'
version '1.0.0'

shared_scripts {
    -- The neutral CoreX item event names, so this resource never names an
    -- inventory - not even in an event it waits for.
    'shared/inventory_events.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/inventory_bridge.lua',
    'server/main.lua'
}

-- No inventory is named here at all, in a dependency or in an include. This
-- resource asks CoreX for whichever inventory is installed, so stopping that
-- one must not stop this one - and deleting it from disk must not stop this one
-- from starting.
dependencies {
    'corex-core'
}
