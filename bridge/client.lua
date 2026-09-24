---------------------------------------------------------------------------
-- Framework bridge (client): everything the HUD needs from RSG / VORP
---------------------------------------------------------------------------
Bridge = {}

if Framework == 'rsg' then
    RSGCore = exports['rsg-core']:GetCoreObject()
end

local loadedCbs, unloadedCbs = {}, {}
function Bridge.OnLoaded(cb) loadedCbs[#loadedCbs + 1] = cb end
function Bridge.OnUnloaded(cb) unloadedCbs[#unloadedCbs + 1] = cb end

local function fire(list)
    for _, cb in ipairs(list) do CreateThread(cb) end
end

-- is the character loaded / in session?
function Bridge.IsLoggedIn()
    if Framework == 'rsg' then return LocalPlayer.state.isLoggedIn == true end
    if Framework == 'vorp' then return LocalPlayer.state.IsInSession == true end
    return false
end

if Framework == 'rsg' then
    RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function() Wait(1000) fire(loadedCbs) end)
    RegisterNetEvent('RSGCore:Client:OnPlayerUnload', function() fire(unloadedCbs) end)
elseif Framework == 'vorp' then
    -- the server loads hunger / thirst / stress when the character is selected (bridge/server.lua)
    RegisterNetEvent('vorp:SelectedCharacter', function() Wait(2000) fire(loadedCbs) end)
end

-- resource restarted while the player is already in game
AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    Wait(500)
    if Bridge.IsLoggedIn() then fire(loadedCbs) end
end)

---------------------------------------------------------------------------
-- Needs saved by the framework (read once when the character loads)
---------------------------------------------------------------------------
function Bridge.GetSavedNeeds()
    local st = LocalPlayer.state
    local meta = {}
    if Framework == 'rsg' then
        meta = (RSGCore.Functions.GetPlayerData() or {}).metadata or {}
    end
    return {
        hunger = tonumber(st.hunger or meta.hunger) or 100.0,
        thirst = tonumber(st.thirst or meta.thirst) or 100.0,
        stress = tonumber(st.stress or meta.stress) or 0.0,
    }
end

---------------------------------------------------------------------------
-- Text info (job, grade, cash)
---------------------------------------------------------------------------
local vorpInfo = {}
RegisterNetEvent('fks-hud:client:info', function(info)
    if type(info) == 'table' then vorpInfo = info end
end)

function Bridge.GetInfo()
    if Framework == 'rsg' then
        local pd = RSGCore.Functions.GetPlayerData() or {}
        local job = pd.job or {}
        return {
            job   = job.label or job.name or '',
            grade = job.grade and job.grade.name or '',
            money = (pd.money and pd.money.cash) or 0,
        }
    end
    if Framework == 'vorp' then
        local ch = LocalPlayer.state.Character or {}
        return {
            job   = vorpInfo.job   or ch.JobLabel or ch.Job or '',
            grade = vorpInfo.grade or '',
            money = vorpInfo.money or ch.Money or 0,
        }
    end
    return { job = '', grade = '', money = 0 }
end

---------------------------------------------------------------------------
-- Item labels (the server sends them together with the item use on VORP)
---------------------------------------------------------------------------
local labels = {}
function Bridge.SetItemLabel(name, label)
    if name and label then labels[name] = label end
end

function Bridge.ItemLabel(name)
    if labels[name] then return labels[name] end
    if Framework == 'rsg' then
        local item = RSGCore.Shared.Items[name]
        if item and item.label then return item.label end
    end
    return name
end
