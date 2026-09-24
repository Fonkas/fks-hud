--[[
    fks-hud - items for rsg-core
    ---------------------------
    Paste these lines inside the RSGShared.Items table in:
        rsg-core/shared/items.lua
    then RESTART THE SERVER (rsg-core only loads its items on start).

    Images: put cigarette.png, cigar.png and pipe.png in your inventory images folder
    (rsg-inventory/html/images/ or ox_inventory/web/images/).

    The food, drinks and medical items used by config_items.lua (water, bread, coffee, beer,
    stew, canned_apricots, animal_heart, bandage, fieldbandage, firstaid) are default RSG items.
    You only need what is below.
]]

    -- REQUIRED: smoking (fks-hud)
    cigarette    = { name = 'cigarette',    label = 'Cigarette',    weight = 20,  type = 'item', image = 'cigarette.png',           unique = false, useable = true,  shouldClose = true, description = 'Relieves stress',             category = 'consumable' },
    cigar        = { name = 'cigar',        label = 'Cigar',        weight = 30,  type = 'item', image = 'cigar.png',               unique = false, useable = true,  shouldClose = true, description = 'A fine cigar to relax',       category = 'consumable' },
    pipe         = { name = 'pipe',         label = 'Pipe',         weight = 150, type = 'item', image = 'pipe.png',                unique = false, useable = true,  shouldClose = true, description = 'Needs pipe tobacco',          category = 'consumable' },
    pipe_tobacco = { name = 'pipe_tobacco', label = 'Pipe Tobacco', weight = 20,  type = 'item', image = 'herb_indian_tobacco.png', unique = false, useable = false, shouldClose = true, description = 'Tobacco for the pipe',        category = 'consumable' },

    -- OPTIONAL: tonics (only add them if your server doesn't have them yet - otherwise remove them from config_items.lua)
    tonic_healing  = { name = 'tonic_healing',  label = 'Healing Tonic',      weight = 100, type = 'item', image = 'tonic_healing.png',  unique = false, useable = true, shouldClose = true, description = 'A restorative herbal tonic.',      category = 'consumable' },
    tonic_stamina  = { name = 'tonic_stamina',  label = 'Stamina Tonic',      weight = 100, type = 'item', image = 'tonic_stamina.png',  unique = false, useable = true, shouldClose = true, description = 'Restores stamina when consumed.',  category = 'consumable' },
    tonic_energy   = { name = 'tonic_energy',   label = 'Energy Tonic',       weight = 100, type = 'item', image = 'tonic_energy.png',   unique = false, useable = true, shouldClose = true, description = 'A sharp herbal pick-me-up.',       category = 'consumable' },
    tonic_antidote = { name = 'tonic_antidote', label = 'Snake Oil Antidote', weight = 100, type = 'item', image = 'tonic_antidote.png', unique = false, useable = true, shouldClose = true, description = 'Counters poison and venom.',       category = 'consumable' },
