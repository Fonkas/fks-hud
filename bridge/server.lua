---------------------------------------------------------------------------
-- Framework bridge (server): items, players, admin commands, saving needs
---------------------------------------------------------------------------
Bridge = {}

local RSGCore, VORPCore, Inv
if Framework == 'rsg' then
    RSGCore = exports['rsg-core']:GetCoreObject()
elseif Framework == 'vorp' then
    VORPCore = exports.vorp_core:GetCore()
    Inv = exports.vorp_inventory
end

local function vorpCharacter(src)
    local user = VORPCore and VORPCore.getUser(src)
    return user and user.getUsedCharacter, user
end

---------------------------------------------------------------------------
-- Players
---------------------------------------------------------------------------
function Bridge.PlayerExists(src)
    if Framework == 'rsg' then return RSGCore.Functions.GetPlayer(src) ~= nil end
    if Framework == 'vorp' then return vorpCharacter(src) ~= nil end
    return false
end

function Bridge.GetLicense(src)
    if Framework == 'rsg' then
        local Player = RSGCore.Functions.GetPlayer(src)
        if Player then return Player.PlayerData.license end
    end
    return GetPlayerIdentifierByType(src, 'license')
end

---------------------------------------------------------------------------
-- Items
---------------------------------------------------------------------------
local function itemData(name)
    if Framework == 'rsg' then return RSGCore.Shared.Items[name] end
    if Framework == 'vorp' then return Inv:getItemDB(name) end
end

function Bridge.ItemExists(name)
    return itemData(name) ~= nil
end

function Bridge.ItemLabel(name)
    local data = itemData(name)
    return data and data.label or name
end

-- cb(source) when a player uses the item
function Bridge.RegisterUsable(name, cb)
    if Framework == 'rsg' then
        RSGCore.Functions.CreateUseableItem(name, function(source) cb(source) end)
    elseif Framework == 'vorp' then
        Inv:registerUsableItem(name, function(data)
            Inv:closeInventory(data.source)
            cb(data.source)
        end, GetCurrentResourceName())
    end
end

function Bridge.HasItem(src, name, amount)
    amount = amount or 1
    if Framework == 'rsg' then
        local Player = RSGCore.Functions.GetPlayer(src)
        local item = Player and Player.Functions.GetItemByName(name)
        return item ~= nil and (item.amount or item.count or 1) >= amount
    end
    if Framework == 'vorp' then
        return (Inv:getItemCount(src, nil, name) or 0) >= amount
    end
    return false
end

function Bridge.RemoveItem(src, name, amount)
    amount = amount or 1
    if Framework == 'rsg' then
        local Player = RSGCore.Functions.GetPlayer(src)
        if not Player or not Player.Functions.RemoveItem(name, amount) then return false end
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[name], 'remove', amount)
        return true
    end
    if Framework == 'vorp' then
        return Inv:subItem(src, name, amount) == true
    end
    return false
end

function Bridge.AddItem(src, name, amount)
    amount = amount or 1
    if Framework == 'rsg' then
        local Player = RSGCore.Functions.GetPlayer(src)
        if not Player then return false end
        Player.Functions.AddItem(name, amount)
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[name], 'add', amount)
        return true
    end
    if Framework == 'vorp' then
        return Inv:addItem(src, name, amount) == true
    end
    return false
end

---------------------------------------------------------------------------
-- Admin commands
---------------------------------------------------------------------------
local function isVorpAdmin(src)
    if src == 0 then return true end -- server console
    local _, user = vorpCharacter(src)
    local group = user and user.getGroup
    for _, allowed in ipairs(Config.Commands.vorpAdminGroups or { 'admin' }) do
        if group == allowed then return true end
    end
    return IsPlayerAceAllowed(src, 'command') -- server owners with full ACE access
end

-- args = { { name, help }, ... }  |  cb(source, args)
function Bridge.RegisterAdminCommand(name, help, args, cb)
    if Framework == 'rsg' then
        RSGCore.Commands.Add(name, help, args, false, cb, Config.Commands.adminPermission or 'admin')
    elseif Framework == 'vorp' then
        RegisterCommand(name, function(source, cmdArgs)
            if isVorpAdmin(source) then cb(source, cmdArgs) end
        end, false)
        TriggerClientEvent('chat:addSuggestion', -1, '/' .. name, help, args)
    end
end

---------------------------------------------------------------------------
-- VORP: hunger / thirst / stress saved in the character "status"
-- (same place and scale as vorp_metabolism: Hunger / Thirst 0-1000)
---------------------------------------------------------------------------
if Framework == 'vorp' then
    local function loadNeeds(src, character)
        character = character or vorpCharacter(src)
        if not character then return end
        local ok, status = pcall(json.decode, character.status or '')
        status = ok and type(status) == 'table' and status or {}

        local state = Player(src).state
        state:set('hunger', math.min(100, (tonumber(status.Hunger) or 1000) / 10), true)
        state:set('thirst', math.min(100, (tonumber(status.Thirst) or 1000) / 10), true)
        state:set('stress', math.min(100, tonumber(status.Stress) or 0), true)
    end

    local function saveNeeds(src)
        local character = vorpCharacter(src)
        local state = Player(src).state
        if not character or state.hunger == nil then return end

        local ok, status = pcall(json.decode, character.status or '')
        status = ok and type(status) == 'table' and status or {}
        status.Hunger = math.floor((tonumber(state.hunger) or 100) * 10)
        status.Thirst = math.floor((tonumber(state.thirst) or 100) * 10)
        status.Stress = math.floor(tonumber(state.stress) or 0)
        status.Metabolism = status.Metabolism or 0
        character.setStatus(json.encode(status))
    end

    AddEventHandler('vorp:SelectedCharacter', function(src, character)
        loadNeeds(src, character)
    end)

    AddEventHandler('playerDropped', function()
        saveNeeds(source)
    end)

    -- resource restarted with players already in game
    CreateThread(function()
        Wait(1000)
        for _, id in ipairs(GetPlayers()) do
            local src = tonumber(id)
            if Player(src).state.IsInSession and Player(src).state.hunger == nil then loadNeeds(src) end
        end
    end)

    -- save regularly (vorp_core writes the character to the database on its own save)
    CreateThread(function()
        while true do
            Wait(60000)
            for _, id in ipairs(GetPlayers()) do saveNeeds(tonumber(id)) end
        end
    end)

    AddEventHandler('onResourceStop', function(res)
        if res ~= GetCurrentResourceName() then return end
        for _, id in ipairs(GetPlayers()) do saveNeeds(tonumber(id)) end
    end)

    -- job / cash for the HUD text info (only sent when something changes)
    local lastInfo = {}
    CreateThread(function()
        while true do
            Wait(2000)
            for _, id in ipairs(GetPlayers()) do
                local src = tonumber(id)
                local character = vorpCharacter(src)
                if character then
                    local info = { job = character.jobLabel or character.job or '', grade = '', money = character.money or 0 }
                    local key = ('%s|%s'):format(info.job, info.money)
                    if lastInfo[src] ~= key then
                        lastInfo[src] = key
                        TriggerClientEvent('fks-hud:client:info', src, info)
                    end
                end
            end
        end
    end)
    AddEventHandler('playerDropped', function() lastInfo[source] = nil end)
end
