--[[
    fks-hud - items for ox_inventory
    --------------------------------
    ONLY needed if your ox_inventory does NOT load the items from rsg-core.
    (RSG ports of ox_inventory usually import rsg-core/shared/items.lua automatically -
     in that case use install/items_rsg-core.lua instead and ignore this file.)

    Paste these entries inside the table returned by:
        ox_inventory/data/items.lua
    and put cigarette.png, cigar.png and pipe.png in ox_inventory/web/images/.

    Do NOT add "client.status" / "client.anim" to these items: fks-hud handles
    the animations and the effects (config_items.lua / config_animations.lua).
]]

    -- REQUIRED: smoking (fks-hud)
    ['cigarette'] = {
        label = 'Cigarette',
        weight = 20,
        stack = true,
        close = true,
        description = 'Relieves stress',
    },

    ['cigar'] = {
        label = 'Cigar',
        weight = 30,
        stack = true,
        close = true,
        description = 'A fine cigar to relax',
    },

    ['pipe'] = {
        label = 'Pipe',
        weight = 150,
        stack = true,
        close = true,
        description = 'Needs pipe tobacco',
    },

    ['pipe_tobacco'] = {
        label = 'Pipe Tobacco',
        weight = 20,
        stack = true,
        close = false,
        description = 'Tobacco for the pipe',
        client = { image = 'herb_indian_tobacco.png' },
    },
