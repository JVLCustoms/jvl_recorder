fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'jvl_recorder'
author 'JVL MediaCode'
description 'JVL Recorder - Rockstar Editor clips from the server: record, save, discard, open the editor (Qbox, QBCore, ESX, standalone)'
version '2.0.1'

-- Runtime: oxmysql (only with Config.Log.database). Optional: jvl_notify. No fxmanifest dependencies.
shared_scripts {
    'locales/*.lua',
    'config.lua',
    'shared.lua',
}

client_script 'client.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/*.css',
    'web/*.js',
}
