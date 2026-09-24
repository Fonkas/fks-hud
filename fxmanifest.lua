fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'
lua54 'yes'

name 'fks-hud'
author 'Fonkas'
description 'HUD + metabolism + consumables for RedM (RSG and VORP)'
version '1.1.0'
license 'GPL-3.0-or-later' -- see LICENSE
-- fks-hud  Copyright (C) 2026 Fonkas

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'config_items.lua',
    'config_animations.lua',
    'locales/*.lua',
    'bridge/shared.lua',
}

client_scripts {
    'bridge/client.lua',
    'client/utils.lua',
    'client/hud.lua',
    'client/metabolism.lua',
    'client/temperature.lua',
    'client/stress.lua',
    'client/consume.lua',
}

server_scripts {
    'bridge/server.lua',
    'server/main.lua',
    'server/version.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/fonts/*',
    'html/img/*',
}

-- plus rsg-core or vorp_core (+ vorp_inventory), detected automatically (Config.Framework)
dependencies {
    'ox_lib',
    'oxmysql',
}
