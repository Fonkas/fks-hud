local KVP_LAYOUT   = 'fks-hud:layout' -- old: settings stored on the PC (only used to migrate them to the database)
local savedLayout  = nil               -- player settings (loaded from the database)
local hudEnabled   = true  -- /hud
local editorOpen   = false
local nuiReady     = false
local lastPayload  = nil

---------------------------------------------------------------------------
-- NUI
---------------------------------------------------------------------------
local function send(action, data)
    data = data or {}
    data.action = action
    SendNUIMessage(data)
end

-- old settings stored on this PC (previous script versions)
local function getKvpLayout()
    local raw = GetResourceKvpString(KVP_LAYOUT)
    if not raw or raw == '' then return nil end
    local ok, layout = pcall(json.decode, raw)
    if not ok or type(layout) ~= 'table' or layout.version ~= Config.LayoutVersion then return nil end
    return layout
end

-- loads the settings from the database (and migrates the old ones from this PC, if any)
local function fetchLayout()
    local layout = lib.callback.await('fks-hud:server:getLayout', false)
    if not layout then
        local old = getKvpLayout()
        if old then
            TriggerServerEvent('fks-hud:server:saveLayout', old)
            layout = old
        end
    end
    DeleteResourceKvp(KVP_LAYOUT)
    return layout
end

local function initNui()
    send('init', {
        defaults = Config.DefaultLayout,
        layout   = savedLayout,
        locale   = GetUiLocale(),
        logo     = Config.Logo,
        editor   = Config.Hud.editor,
        low      = Config.Hud.lowWarning,
        lowNeeds = Config.Hud.needsWarning or 10,
        heartWeakAt = Config.Hud.heartWeakAt or 0,
        temp     = { min = Config.Temperature.min, max = Config.Temperature.max, comfort = Config.Temperature.comfort },
        tempEnabled   = Config.Temperature.enabled,
        stressEnabled = Config.Stress.enabled,
        horseEnabled  = Config.Horse.enabled,
        emptyAt       = Config.Cores.exhaustion.threshold or 3,
        infoEnabled   = Config.Info.enabled,
    })
    lastPayload = nil
end

RegisterNUICallback('ready', function(_, cb)
    nuiReady = true
    initNui()
    cb('ok')
end)

RegisterNUICallback('saveLayout', function(data, cb)
    data.layout.version = Config.LayoutVersion
    savedLayout = data.layout
    TriggerServerEvent('fks-hud:server:saveLayout', data.layout)
    Notify(L('layout_saved'), 'success')
    cb('ok')
end)

RegisterNUICallback('resetLayout', function(_, cb)
    savedLayout = nil
    TriggerServerEvent('fks-hud:server:resetLayout')
    Notify(L('layout_reset'), 'inform')
    cb('ok')
end)

RegisterNUICallback('closeEditor', function(_, cb)
    editorOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

---------------------------------------------------------------------------
-- Commands
---------------------------------------------------------------------------
RegisterCommand(Config.Commands.settings, function()
    if not State.loggedIn then return end
    editorOpen = true
    SetNuiFocus(true, true)
    send('editor', { open = true })
end, false)

RegisterCommand(Config.Commands.toggle, function()
    hudEnabled = not hudEnabled
    Notify(hudEnabled and L('hud_on') or L('hud_off'), 'inform', 2500)
end, false)

TriggerEvent('chat:addSuggestion', '/' .. Config.Commands.settings, L('cmd_settings'))
TriggerEvent('chat:addSuggestion', '/' .. Config.Commands.toggle, L('cmd_toggle'))

---------------------------------------------------------------------------
-- Visibility
---------------------------------------------------------------------------
local function shouldShow(ped)
    if editorOpen then return true end
    if not hudEnabled or not State.loggedIn then return false end

    local auto = Config.Hud.autoHide
    if auto.dead and IsDead(ped) then return false end
    if auto.pauseMenu and IsPauseMenuActive() then return false end
    if auto.mapOpen and Citizen.InvokeNative(0x25B7A0206BDFAC76, joaat('MAP'), Citizen.ResultAsInteger()) == 1 then return false end
    if auto.screenFaded and (IsScreenFadedOut() or IsScreenFadingOut()) then return false end

    return true
end

---------------------------------------------------------------------------
-- Main HUD loop
---------------------------------------------------------------------------
local function round(v) return math.floor(v + 0.5) end

-- the configured maximum (Config.Cores.maxHealth / maxStamina) is shown as a full ring
local function relative(pct, max)
    if not max or max <= 0 then return pct end
    return math.min(100, pct / max * 100)
end

---------------------------------------------------------------------------
-- Horse: values are read from the entity itself (every horse has its own)
---------------------------------------------------------------------------
local function findHorse(ped)
    local cfg = Config.Horse
    local mount = GetMount(ped)
    if mount ~= 0 and DoesEntityExist(mount) then return mount end
    if cfg.showWhen ~= 'nearby' then return nil end

    -- horse being led by the reins or the last mounted horse, if close
    local led = Citizen.InvokeNative(0xED1F514AF4732258, ped, Citizen.ResultAsInteger()) -- GetLedHorseFromPed
    local horse = (led and led ~= 0) and led or Citizen.InvokeNative(0x4C8B59171957BCF7, ped, Citizen.ResultAsInteger()) -- GetLastMount
    if not horse or horse == 0 or not DoesEntityExist(horse) then return nil end
    if #(GetEntityCoords(ped) - GetEntityCoords(horse)) > cfg.nearbyDistance then return nil end
    return horse
end

-- Ring size (0-1) based on the horse attribute level, like the native HUD:
-- a low level horse has an incomplete ring even when rested.
local function attributeCapacity(horse, index)
    local mode = Config.Horse.ringSize
    if mode == 'full' then return 1.0 end

    local cur, max
    if mode == 'points' then
        cur = GetAttributePoints(horse, index)
        max = GetMaxAttributePoints(horse, index)
    else -- 'rank' (ranks start at 0, hence +1)
        cur = GetAttributeRank(horse, index) + 1
        max = GetMaxAttributeRank(horse, index) + 1
    end

    if not max or max <= 0 then return 1.0 end
    return Clamp(cur / max, Config.Horse.minRingSize, 1.0)
end

-- exhaustion per horse (each horse has its own)
local horseExhausted = {}
-- returns: exhausted?, recovery (0-1)
local function horseExhaustion(horse, staminaPct)
    if not Config.Cores.exhaustion.enabled then return false, 1 end
    local core = GetCore(horse, CORE_STAMINA)
    local start = horseExhausted[horse]

    if not start and staminaPct <= (Config.Cores.exhaustion.threshold or 3) and not IsCoreGold(horse, CORE_STAMINA) then
        horseExhausted[horse] = core
    elseif start then
        if core >= 99 then
            horseExhausted[horse] = nil
        elseif core < start then
            horseExhausted[horse] = core
        end
    end

    start = horseExhausted[horse]
    if not start then return false, 1 end
    return true, ExhaustRecovery(core, start)
end

local lastHorseDebug
local function horseCore(horse, index, percent, dead)
    local cap = attributeCapacity(horse, index)
    return {
        outer = dead and 0 or round(percent * cap),
        rel   = dead and 0 or round(percent), -- % of THIS horse's maximum (for warnings / alerts)
        cap   = cap,
        core  = dead and 0 or GetCore(horse, index),
        gold  = not dead and IsCoreGold(horse, index),
    }
end

local function horseData(ped)
    if not Config.Horse.enabled then return { visible = false } end
    local horse = findHorse(ped)
    if not horse then return { visible = false } end

    if Config.Debug and lastHorseDebug ~= horse then
        lastHorseDebug = horse
        for i, name in pairs({ [0] = 'health', [1] = 'stamina' }) do
            Debug(('horse %s | rank %s/%s | points %s/%s'):format(name,
                GetAttributeRank(horse, i), GetMaxAttributeRank(horse, i),
                GetAttributePoints(horse, i), GetMaxAttributePoints(horse, i)))
        end
    end

    local dead = IsEntityDead(horse)
    local staminaPct = GetStaminaPercent(horse)
    local stamina = horseCore(horse, CORE_STAMINA, staminaPct, dead)
    if not dead then
        stamina.exhausted, stamina.recovery = horseExhaustion(horse, staminaPct)
    end
    return {
        visible = true,
        health  = horseCore(horse, CORE_HEALTH, GetHealthPercent(horse), dead),
        stamina = stamina,
    }
end

CreateThread(function()
    while true do
        Wait(Config.Hud.tick)

        if nuiReady then
            local ped = PlayerPedId()
            local goldHealth  = Config.Cores.goldLocksRing and GoldSecondsLeft('health') > 0
            local goldStamina = Config.Cores.goldLocksRing and GoldSecondsLeft('stamina') > 0
            local payload = {
                visible = shouldShow(ped),
                health = {
                    outer = goldHealth and 100 or round(relative(GetHealthPercent(ped), Config.Cores.maxHealth)),
                    core  = goldHealth and 100 or GetCore(ped, CORE_HEALTH),
                    gold  = IsGold(ped, 'health'),
                    goldLeft = Config.Cores.goldTimer and GoldSecondsLeft('health') or 0,
                },
                stamina = {
                    outer = goldStamina and 100 or round(relative(GetStaminaPercent(ped), Config.Cores.maxStamina)),
                    core  = goldStamina and 100 or GetCore(ped, CORE_STAMINA),
                    gold  = IsGold(ped, 'stamina'),
                    goldLeft = Config.Cores.goldTimer and GoldSecondsLeft('stamina') or 0,
                    exhausted = State.exhausted,
                    recovery  = State.exhausted and ExhaustRecovery(GetCore(ped, CORE_STAMINA), State.exhaustCore) or 1,
                },
                hunger = round(State.hunger),
                thirst = round(State.thirst),
                stress = round(State.stress),
                temp   = { value = State.temp.display or 0, state = State.temp.state, unit = State.temp.unit, raw = State.temp.value },
                horse  = horseData(ped),
            }
            State.horse = payload.horse -- used by the notifications (client/metabolism.lua)

            -- only send to the NUI when something changed
            local encoded = json.encode(payload)
            if encoded ~= lastPayload then
                lastPayload = encoded
                send('tick', { data = payload })
            end
        end
    end
end)

-- Hide the game's native cores (health / stamina / dead eye)
CreateThread(function()
    while true do
        if Config.Hud.hideNativeCores then
            Citizen.InvokeNative(0xC116E6DF68DCE667, 0, 2) -- stamina
            Citizen.InvokeNative(0xC116E6DF68DCE667, 1, 2) -- stamina core
            Citizen.InvokeNative(0xC116E6DF68DCE667, 4, 2) -- health
            Citizen.InvokeNative(0xC116E6DF68DCE667, 5, 2) -- health core
        end
        if Config.Horse.enabled and Config.Horse.hideNativeCores then
            for i = 6, 9 do Citizen.InvokeNative(0xC116E6DF68DCE667, i, 2) end -- horse health / stamina (+ cores)
        end
        if Config.Horse.hideNativeCourage then
            Citizen.InvokeNative(0xC116E6DF68DCE667, 10, 2)
            Citizen.InvokeNative(0xC116E6DF68DCE667, 11, 2)
        end
        if Config.Hud.hideNativeDeadeye then
            Citizen.InvokeNative(0xC116E6DF68DCE667, 2, 2) -- dead eye
            Citizen.InvokeNative(0xC116E6DF68DCE667, 3, 2) -- dead eye core
        end
        Wait(500) -- the game shows the cores again when something changes (e.g. running)
    end
end)

---------------------------------------------------------------------------
-- Text info: job, ID, cash, day and time
---------------------------------------------------------------------------
local function two(n) return ('%02d'):format(n) end

local function clockText()
    local h, m = GetClockHours(), GetClockMinutes()
    local time
    if Config.Info.clock24h then
        time = two(h) .. ':' .. two(m)
    else
        local suffix = h >= 12 and 'PM' or 'AM'
        local h12 = h % 12
        time = (h12 == 0 and 12 or h12) .. ':' .. two(m) .. ' ' .. suffix
    end
    if not Config.Info.showDate then return time end

    local days, months = L('days'), L('months')
    local day   = days[GetClockDayOfWeek() + 1] or ''
    local month = months[GetClockMonth() + 1] or ''
    return ('%s, %d %s %d  ·  %s'):format(day, GetClockDayOfMonth(), month, GetClockYear(), time)
end

local function jobText(info)
    local label, grade = info.job or '', info.grade or ''
    if Config.Info.showGrade and grade ~= '' and grade ~= label then
        return label .. ' - ' .. grade
    end
    return label
end

local lastMoney

local lastInfo
CreateThread(function()
    if not Config.Info.enabled then return end
    while true do
        Wait(1000)
        if nuiReady and State.loggedIn then
            local fw = Bridge.GetInfo()
            -- VORP has no "money changed" event: show the +$ / -$ tip from the difference
            if Framework == 'vorp' and Config.Info.moneyTips and lastMoney and fw.money ~= lastMoney then
                send('moneyTip', { amount = fw.money - lastMoney, currency = Config.Info.currency })
            end
            lastMoney = fw.money
            local info = {
                clock    = clockText(),
                job      = jobText(fw),
                money    = fw.money or 0,
                playerId = GetPlayerServerId(PlayerId()),
                currency = Config.Info.currency,
            }
            local encoded = json.encode(info)
            if encoded ~= lastInfo then
                lastInfo = encoded
                send('info', { data = info })
            end
        end
    end
end)

-- "+$5" / "-$5" when cash changes (event sent by rsg-core; on VORP see the loop above)
RegisterNetEvent('hud:client:OnMoneyChange', function(moneyType, amount, isMinus)
    if not Config.Info.enabled or not Config.Info.moneyTips or moneyType ~= 'cash' then return end
    amount = tonumber(amount) or 0
    if amount == 0 then return end
    send('moneyTip', { amount = (isMinus == true or isMinus == 'remove') and -amount or amount, currency = Config.Info.currency })
end)

---------------------------------------------------------------------------
-- "+25" pop-up above the elements when something is consumed
---------------------------------------------------------------------------
function ShowConsumeTips(deltas)
    send('consumed', { deltas = deltas })
end

---------------------------------------------------------------------------
-- Login / logout
---------------------------------------------------------------------------
local function onLoaded()
    LoadNeedsFromState()
    State.loggedIn = true
    savedLayout = fetchLayout()
    -- the NUI page loaded long before the player joins; always send init
    nuiReady = true
    initNui()
end

-- RSG / VORP login and logout (bridge/client.lua)
Bridge.OnLoaded(onLoaded)
Bridge.OnUnloaded(function() State.loggedIn = false end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for i = 0, 11 do Citizen.InvokeNative(0xC116E6DF68DCE667, i, 0) end
    if editorOpen then SetNuiFocus(false, false) end
end)

---------------------------------------------------------------------------
-- Exports
---------------------------------------------------------------------------
exports('ToggleHud', function(show)
    if show == nil then hudEnabled = not hudEnabled else hudEnabled = show end
end)

exports('IsHudVisible', function() return hudEnabled end)
