fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'corex-loot'
description 'COREX World Loot System'
author 'ABUGIZA'
version '1.0.0'

shared_scripts {
    '@corex-inventory/shared/items.lua',
    '@corex-inventory/shared/weapons.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'corex-core',
    'corex-inventory'
}
