local RSGCore = exports['rsg-core']:GetCoreObject()

-- chosen language (Config.Locale); any missing text falls back to English
local lang     = Locales[Config.Locale] or Locales['en']
local fallback = Locales['en'] or {}

local function L(key, ...)
    local str = lang[key] or fallback[key] or key
    if type(str) == 'string' and select('#', ...) > 0 then return str:format(...) end
    return str
end

local function UI(key)
    return (lang.ui and lang.ui[key]) or (fallback.ui and fallback.ui[key]) or key
end

-- item name: config label > inventory label > item name
local function itemLabel(name)
    local cfg = Consumables[name]
    if cfg and cfg.label then return cfg.label end
    local shared = RSGCore.Shared.Items[name]
    return shared and shared.label or name
end
local pending   = {} -- [src] = { item = name, time = os.time() }
local cooldowns = {} -- [src][item] = os.time() when it ends

local function notify(src, msg, kind)
    TriggerClientEvent('ox_lib:notify', src, {
        description = msg,
        type        = kind or 'inform',
        duration    = 5000,
        position    = Config.Notifications and Config.Notifications.position or nil,
    })
end

---------------------------------------------------------------------------
-- Automatic registration of the items in config_items.lua
---------------------------------------------------------------------------
local function registerItems()
    local count = 0
    for name, data in pairs(Consumables) do
        if not RSGCore.Shared.Items[name] then
            print(('^3[fks-hud] warning: item "%s" does not exist in the RSG shared items (check the name or see install/items_rsg-core.lua)^0'):format(name))
        end
        if data.anim and not Animations[data.anim] then
            print(('^3[fks-hud] warning: animation "%s" of item "%s" does not exist in config_animations.lua^0'):format(data.anim, name))
        end

        RSGCore.Functions.CreateUseableItem(name, function(source)
            local src = source
            local Player = RSGCore.Functions.GetPlayer(src)
            if not Player then return end

            if pending[src] then
                return notify(src, L('busy'), 'error')
            end

            if data.requires and not Player.Functions.GetItemByName(data.requires) then
                return notify(src, L('missing_item', itemLabel(data.requires)), 'error')
            end

            local cd = cooldowns[src] and cooldowns[src][name]
            if cd and cd > os.time() then
                return notify(src, L('cooldown', cd - os.time(), itemLabel(name)), 'error')
            end

            pending[src] = { item = name, time = os.time() }
            TriggerClientEvent('fks-hud:client:useItem', src, name)
        end)
        count = count + 1
    end
    print(('^2[fks-hud] %d consumables registered^0'):format(count))
end

CreateThread(registerItems)

---------------------------------------------------------------------------
-- Animation finished -> remove the item and apply the effects
---------------------------------------------------------------------------
RegisterNetEvent('fks-hud:server:finishItem', function(itemName)
    local src = source
    local p = pending[src]
    pending[src] = nil

    -- only accepted if the server started this consumption (anti-exploit)
    if not p or p.item ~= itemName then return end

    local data = Consumables[itemName]
    local Player = RSGCore.Functions.GetPlayer(src)
    if not data or not Player then return end

    if not data.keep then
        if not Player.Functions.RemoveItem(itemName, 1) then return end
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[itemName], 'remove', 1)
    end

    if data.requires then
        if not Player.Functions.RemoveItem(data.requires, 1) then return end
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[data.requires], 'remove', 1)
    end

    if data.giveBack then
        Player.Functions.AddItem(data.giveBack, 1)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[data.giveBack], 'add', 1)
    end

    if data.cooldown and data.cooldown > 0 then
        cooldowns[src] = cooldowns[src] or {}
        cooldowns[src][itemName] = os.time() + data.cooldown
    end

    TriggerClientEvent('fks-hud:client:applyItem', src, itemName)
end)

RegisterNetEvent('fks-hud:server:cancelItem', function()
    pending[source] = nil
end)

-- clears "stuck" consumptions (e.g. the client crashed halfway)
CreateThread(function()
    while true do
        Wait(30000)
        local now = os.time()
        for src, p in pairs(pending) do
            if now - p.time > 60 then pending[src] = nil end
        end
    end
end)

AddEventHandler('playerDropped', function()
    pending[source] = nil
    cooldowns[source] = nil
end)

---------------------------------------------------------------------------
-- /hudsettings settings saved in the database (per account / license)
-- The table is created automatically. You can also import install/fks_hud.sql.
---------------------------------------------------------------------------
local db = exports.oxmysql

-- calls oxmysql and waits for the result
local function dbAwait(method, query, params)
    local p = promise.new()
    db[method](db, query, params or {}, function(result) p:resolve(result) end)
    return Citizen.Await(p)
end

CreateThread(function()
    dbAwait('query', [[
        CREATE TABLE IF NOT EXISTS `fks_hud_settings` (
            `license`    VARCHAR(64) NOT NULL,
            `layout`     LONGTEXT    NOT NULL,
            `updated_at` TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`license`)
        )
    ]])
end)

local function licenseOf(src)
    local Player = RSGCore.Functions.GetPlayer(src)
    return Player and Player.PlayerData.license or GetPlayerIdentifierByType(src, 'license')
end

lib.callback.register('fks-hud:server:getLayout', function(source)
    local license = licenseOf(source)
    if not license then return nil end

    local raw = dbAwait('scalar', 'SELECT `layout` FROM `fks_hud_settings` WHERE `license` = ?', { license })
    if not raw then return nil end

    local ok, layout = pcall(json.decode, raw)
    if not ok or type(layout) ~= 'table' then return nil end

    -- saved with an old layout version -> back to the server default
    if layout.version ~= Config.LayoutVersion then
        dbAwait('update', 'DELETE FROM `fks_hud_settings` WHERE `license` = ?', { license })
        return nil
    end
    return layout
end)

local lastSave = {}
RegisterNetEvent('fks-hud:server:saveLayout', function(layout)
    local src = source
    if type(layout) ~= 'table' then return end
    if lastSave[src] and GetGameTimer() - lastSave[src] < 2000 then return end -- anti-spam
    lastSave[src] = GetGameTimer()

    local license = licenseOf(src)
    if not license then return end

    layout.version = Config.LayoutVersion
    local encoded = json.encode(layout)
    if #encoded > 20000 then return end -- a normal layout is ~2 KB

    dbAwait('update', [[
        INSERT INTO `fks_hud_settings` (`license`, `layout`) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE `layout` = VALUES(`layout`)
    ]], { license, encoded })
end)

RegisterNetEvent('fks-hud:server:resetLayout', function()
    local license = licenseOf(source)
    if license then
        dbAwait('update', 'DELETE FROM `fks_hud_settings` WHERE `license` = ?', { license })
    end
end)

AddEventHandler('playerDropped', function() lastSave[source] = nil end)

---------------------------------------------------------------------------
-- Admin test commands: /hunger /thirsty /stress [value] [id]
---------------------------------------------------------------------------
local function registerNeedCommand(command, need, label)
    if not command then return end
    RSGCore.Commands.Add(command, L('cmd_need_help', label), {
        { name = L('cmd_arg_value'), help = L('cmd_arg_value_help') },
        { name = L('cmd_arg_id'),    help = L('cmd_arg_id_help') },
    }, false, function(source, args)
        local value  = math.max(0, math.min(100, tonumber(args[1]) or 0))
        local target = tonumber(args[2]) or source

        if not RSGCore.Functions.GetPlayer(target) then
            return notify(source, L('cmd_no_player'), 'error')
        end

        -- the player's client picks up the statebag change and updates the HUD
        Player(target).state:set(need, value, true)
        notify(source, L('cmd_need_set', label, target, value), 'success')
    end, Config.Commands.adminPermission or 'admin')
end

registerNeedCommand(Config.Commands.hunger, 'hunger', UI('hunger'))
registerNeedCommand(Config.Commands.thirst, 'thirst', UI('thirst'))
registerNeedCommand(Config.Commands.stress, 'stress', UI('stress'))

---------------------------------------------------------------------------
-- Stress (compatible with the rsg-hud events)
---------------------------------------------------------------------------
local function changeStress(src, amount)
    local state = Player(src).state
    local value = math.max(0, math.min(100, (tonumber(state.stress) or 0) + amount))
    state:set('stress', value, true)
end

RegisterNetEvent('hud:server:GainStress', function(amount)
    changeStress(source, math.abs(tonumber(amount) or 0))
end)

RegisterNetEvent('hud:server:RelieveStress', function(amount)
    changeStress(source, -math.abs(tonumber(amount) or 0))
end)

exports('AddStress', function(src, amount) changeStress(src, tonumber(amount) or 0) end)
