fx_version 'cerulean'
game 'gta5'

name 'Sun Framework'
author 'Sun'
description 'Custom Framework'
version '1.0.0'

lua54 'yes'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/cl_main.lua',
    'client/cl_function.lua',
    'client/cl_player.lua',
    'client/cl_commands.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',

    'server/sv_main.lua',
    'server/sv_function.lua',
    'server/sv_player.lua',
    'server/sv_commands.lua',
    'exports/function.lua'
}
