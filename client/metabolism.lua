local DRAIN_TICK = 10000 -- ms between each hunger / thirst drain


---------------------------------------------------------------------------
-- Hunger / thirst draining over time
---------------------------------------------------------------------------
CreateThread(function()
    while true do
        Wait(DRAIN_TICK)
        local ped = PlayerPedId()

        if State.loggedIn and not IsDead(ped) then
            local activity = GetActivity(ped)
            local hungerMult, thirstMult = GetTemperatureMultipliers()
            local minutes = DRAIN_TICK / 60000

            if Config.Hunger.enabled then
                AddNeed('hunger', -(Config.Hunger.drain[activity] or 0) * minutes * hungerMult)
            end

            if Config.Thirst.enabled then
                AddNeed('thirst', -(Config.Thirst.drain[activity] or 0) * minutes * thirstMult)
            end
        end
    end
end)

---------------------------------------------------------------------------
-- Hunger / thirst at 0: the player slowly loses health until death (with screen effects)
---------------------------------------------------------------------------
local starvingFx = false

local function setStarvingFx(on)
    local fx = Config.Starving.loopFx
    if not fx or on == starvingFx then return end
    starvingFx = on
    if on then AnimpostfxPlay(fx) else AnimpostfxStop(fx) end
end

CreateThread(function()
    local cfg = Config.Starving
    local lastNotify = 0

    while true do
        Wait(cfg.interval)
        local ped = PlayerPedId()
        local starving   = Config.Hunger.enabled and State.hunger <= 0
        local dehydrated = Config.Thirst.enabled and State.thirst <= 0

        if State.loggedIn and not IsDead(ped) and (starving or dehydrated) then
            setStarvingFx(true)

            -- health only (outer ring); the core / heart is not touched
            local pct = cfg.damage * ((starving and dehydrated and cfg.bothDouble) and 2 or 1)
            local max = GetEntityMaxHealth(ped)
            local hp  = GetEntityHealth(ped) - math.max(1, math.floor(max * pct / 100))
            SetEntityHealth(ped, math.max(0, hp), 0) -- at 0 the player dies

            if cfg.hitFx then PlayScreenFx(cfg.hitFx, cfg.hitTime or 1500) end
            if (cfg.shake or 0) > 0 then ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', cfg.shake) end

            if GetGameTimer() - lastNotify > 60000 then
                lastNotify = GetGameTimer()
                Notify(L(starving and 'starving' or 'dehydrated'), 'error', 4000)
            end
        else
            setStarvingFx(false)
        end
    end
end)

---------------------------------------------------------------------------
-- Hunger OR thirst full: the heart (health core) recovers quickly
---------------------------------------------------------------------------
CreateThread(function()
    local cfg = Config.Cores.fullNeedsHeal
    if not cfg or not cfg.enabled then return end

    while true do
        Wait(cfg.interval)
        local ped = PlayerPedId()

        if State.loggedIn and not IsDead(ped)
            and (State.hunger >= cfg.at or State.thirst >= cfg.at)
            and GetCore(ped, CORE_HEALTH) < 100 then
            AddCore(ped, CORE_HEALTH, cfg.amount)
        end
    end
end)

---------------------------------------------------------------------------
-- Health / stamina cores linked to hunger and thirst
---------------------------------------------------------------------------
CreateThread(function()
    local cfg = Config.Cores
    if not cfg.linkToNeeds then return end

    while true do
        Wait(cfg.interval)
        local ped = PlayerPedId()

        if State.loggedIn and not IsDead(ped) then
            local lowest = math.min(State.hunger, State.thirst)

            if lowest > cfg.regenAbove then
                AddCore(ped, CORE_HEALTH, cfg.regenAmount)
                if not (State.exhausted and not cfg.exhaustion.passiveRegen) then
                    AddCore(ped, CORE_STAMINA, cfg.regenAmount)
                end
            end
        end
    end
end)

---------------------------------------------------------------------------
-- Health / stamina maximum + helps regenerate the outer ring
---------------------------------------------------------------------------
CreateThread(function()
    local cfg = Config.Cores
    local TICK = 500
    local step = TICK / 1000

    while true do
        Wait(TICK)
        local ped = PlayerPedId()

        if State.loggedIn and not IsDead(ped) then
            -- health
            local hp = GetHealthPercent(ped)
            if hp > cfg.maxHealth + 0.5 and not IsGold(ped, 'health') then
                AddHealthPercent(ped, cfg.maxHealth - hp)
            elseif cfg.healthRegen > 0 and hp < cfg.maxHealth then
                AddHealthPercent(ped, math.min(cfg.healthRegen * step, cfg.maxHealth - hp))
            end

            -- stamina
            local st = GetStaminaPercent(ped)


            if st > cfg.maxStamina + 0.5 and not IsGold(ped, 'stamina') then
                AddStaminaPercent(ped, cfg.maxStamina - st)
            elseif cfg.staminaRegen > 0 and st < cfg.maxStamina then
                local activity = GetActivity(ped)
                if activity ~= 'run' and activity ~= 'swim' then
                    AddStaminaPercent(ped, math.min(cfg.staminaRegen * step, cfg.maxStamina - st))
                end
            end
        end
    end
end)

---------------------------------------------------------------------------
-- Gold boost active: the ring (and the core) don't drop
---------------------------------------------------------------------------
CreateThread(function()
    while true do
        local ped, active = PlayerPedId(), false

        if Config.Cores.goldLocksRing and State.loggedIn and not IsDead(ped) then
            if GoldSecondsLeft('health') > 0 then
                active = true
                local max = GetEntityMaxHealth(ped)
                if GetEntityHealth(ped) < max then SetEntityHealth(ped, max, 0) end
                if GetCore(ped, CORE_HEALTH) < 100 then SetCore(ped, CORE_HEALTH, 100) end
            end

            if GoldSecondsLeft('stamina') > 0 then
                active = true
                local st = GetStaminaPercent(ped)
                if st < 100 then AddStaminaPercent(ped, 100 - st) end
                if GetCore(ped, CORE_STAMINA) < 100 then SetCore(ped, CORE_STAMINA, 100) end
                State.exhausted = false
            end
        end

        Wait(active and 0 or 500) -- while boosted, refill every frame so the ring doesn't move at all
    end
end)

---------------------------------------------------------------------------
-- Extra stamina drain while running / sprinting + exhaustion detection
-- (100ms: when stamina runs out the game starts regenerating right away, so it
--  has to be checked often to catch the moment it reaches the end)
---------------------------------------------------------------------------
local tiredWarned = false

-- warning when stamina reaches X% (Config.Notifications.staminaWarnAt)
local function checkTiredWarning(ped, st)
    local n = Config.Notifications
    if not (n.enabled and n.exhaustion) then return end
    local warnAt = n.staminaWarnAt or 20

    if not tiredWarned and st <= warnAt and GoldSecondsLeft('stamina') == 0 and not IsGold(ped, 'stamina') then
        tiredWarned = true
        Notify(L('notify_exhausted'), 'error', n.duration, GetUiLocale().stamina, 'person-running')
    elseif tiredWarned and st > warnAt + 10 then
        tiredWarned = false -- recovered: can warn again
    end
end

local function checkExhaustion(ped)
    local st = GetStaminaPercent(ped)
    checkTiredWarning(ped, st)

    local ex = Config.Cores.exhaustion
    if not ex.enabled then return end

    if not State.exhausted then
        if st <= (ex.threshold or 3) and GoldSecondsLeft('stamina') == 0 and not IsGold(ped, 'stamina') then
            State.exhausted = true
            AddCore(ped, CORE_STAMINA, -(ex.coreLoss or 0))
            State.exhaustCore = GetCore(ped, CORE_STAMINA)
            Debug(('EXHAUSTED | stamina %.1f%% | core now %d'):format(st, State.exhaustCore))
        end
    else
        local core = GetCore(ped, CORE_STAMINA)
        if core >= 99 then
            State.exhausted = false
            Debug('exhaustion ended (core 100)')
            if Config.Notifications.enabled and Config.Notifications.exhaustion then
                Notify(L('notify_recovered'), 'success', Config.Notifications.duration, GetUiLocale().stamina, 'person-running')
            end
        elseif core < State.exhaustCore then
            State.exhaustCore = core -- the core dropped even more: start counting from here
        end
    end
end

CreateThread(function()
    local cfg = Config.Cores
    local TICK = 100
    local lastDebug = 0
    while true do
        Wait(TICK)
        local ped = PlayerPedId()

        if State.loggedIn and not IsDead(ped) then
            checkExhaustion(ped)

            if Config.Debug and IsPedSprinting(ped) and GetGameTimer() - lastDebug > 1000 then
                lastDebug = GetGameTimer()
                Debug(('sprint | stamina %.1f%% | core %d | exhausted %s'):format(
                    GetStaminaPercent(ped), GetCore(ped, CORE_STAMINA), tostring(State.exhausted)))
            end
        end

        if State.loggedIn and not IsDead(ped) and not IsPedOnMount(ped) and GoldSecondsLeft('stamina') == 0 then
            local drain = 0
            if IsPedSprinting(ped) then
                drain = cfg.sprintDrain or 0
            elseif IsPedRunning(ped) then
                drain = cfg.runDrain or 0
            end
            if drain > 0 then
                AddStaminaPercent(ped, -drain * TICK / 1000)
            end
        end
    end
end)

---------------------------------------------------------------------------
-- Death / revive
---------------------------------------------------------------------------
CreateThread(function()
    local wasDead = false
    while true do
        Wait(1000)
        local dead = IsDead(PlayerPedId())

        if wasDead and not dead then State.exhausted = false end

        if wasDead and not dead and State.loggedIn and Config.Death.resetNeeds then
            SetNeed('hunger', math.max(State.hunger, Config.Death.hunger))
            SetNeed('thirst', math.max(State.thirst, Config.Death.thirst))
            SetNeed('stress', Config.Death.stress)
        end

        wasDead = dead
    end
end)

---------------------------------------------------------------------------
-- Compatibility with the rsg-hud events (rsg-canteen, rsg-essentials, ...)
---------------------------------------------------------------------------
RegisterNetEvent('hud:client:UpdateNeeds', function(hunger, thirst)
    if hunger then SetNeed('hunger', hunger) end
    if thirst then SetNeed('thirst', thirst) end
end)

RegisterNetEvent('hud:client:UpdateHunger', function(value) SetNeed('hunger', value) end)
RegisterNetEvent('hud:client:UpdateThirst', function(value) SetNeed('thirst', value) end)
RegisterNetEvent('hud:client:UpdateStress', function(value) SetNeed('stress', value) end)

RegisterNetEvent('hud:client:UpdateCleanliness', function(value)
    LocalPlayer.state:set('cleanliness', Clamp(tonumber(value) or 100, 0, 100), true)
end)

---------------------------------------------------------------------------
-- Compatibility with the vorp_metabolism events (VORP scripts)
-- vorp_metabolism uses 0-1000 for Hunger / Thirst, fks-hud uses 0-100
---------------------------------------------------------------------------
local VORP_KEYS = { hunger = 'hunger', thirst = 'thirst', stress = 'stress' }

RegisterNetEvent('vorpmetabolism:changeValue', function(key, value)
    local need = VORP_KEYS[tostring(key):lower()]
    if need and tonumber(value) then AddNeed(need, need == 'stress' and value or value / 10) end
end)

RegisterNetEvent('vorpmetabolism:setValue', function(key, value)
    local need = VORP_KEYS[tostring(key):lower()]
    if need and tonumber(value) then SetNeed(need, need == 'stress' and value or value / 10) end
end)

RegisterNetEvent('vorpmetabolism:getValue', function(key, cb)
    local need = VORP_KEYS[tostring(key):lower()]
    if type(cb) ~= 'function' then return end
    if not need then return cb(nil) end
    cb(need == 'stress' and State.stress or math.floor(State[need] * 10))
end)

---------------------------------------------------------------------------
-- API for other scripts
---------------------------------------------------------------------------
-- TriggerEvent('fks-hud:client:addNeeds', { hunger = 10, thirst = -5, stress = 2 })
AddEventHandler('fks-hud:client:addNeeds', function(data)
    if type(data) ~= 'table' then return end
    AddNeed('hunger', data.hunger)
    AddNeed('thirst', data.thirst)
    AddNeed('stress', data.stress)
end)

exports('GetNeeds', function()
    return { hunger = State.hunger, thirst = State.thirst, stress = State.stress, temperature = State.temp.value }
end)

exports('AddNeeds', function(hunger, thirst, stress)
    AddNeed('hunger', hunger)
    AddNeed('thirst', thirst)
    AddNeed('stress', stress)
end)

exports('SetNeed', SetNeed)

local notifyCfg = Config.Notifications

local HYSTERESIS = 5 -- the value must recover X above the level before the warning can show again

-- [key][level index] = true once warned
local fired = {}

local function msg(key, index)
    local list = L(key)
    if type(list) ~= 'table' then return tostring(list) end
    return list[math.min(index, #list)]
end

---Checks the levels of a value and only warns about the most severe level just reached.
---@param key string message key in the locales (list, one text per level)
---@param value number current value
---@param levels number[] levels in order of severity
---@param rising boolean true = warn when it RISES (stress), false = when it DROPS (hunger...)
local function checkLevels(key, value, levels, rising, kind, title, icon)
    if not levels or not value then return end
    fired[key] = fired[key] or {}
    local state, worst = fired[key], nil

    for i, level in ipairs(levels) do
        local hit       = rising and value >= level or (not rising and value <= level)
        local recovered = rising and value < level - HYSTERESIS or (not rising and value > level + HYSTERESIS)

        if hit and not state[i] then
            state[i] = true
            worst = i
        elseif recovered then
            state[i] = nil
        end
    end

    if worst then
        local severe = worst == #levels
        Notify(msg(key, worst), severe and 'error' or (kind or 'warning'), notifyCfg.duration, title, icon)
    end
end

local function resetKey(key) fired[key] = nil end

---------------------------------------------------------------------------
-- NOTIFICATIONS: player hunger / thirst / stress (the exhaustion warning is above)
---------------------------------------------------------------------------
CreateThread(function()
    if not notifyCfg.enabled then return end
    local T = GetUiLocale()
    while true do
        Wait(1000)
        local ped = PlayerPedId()

        if State.loggedIn and not IsDead(ped) then
            if Config.Hunger.enabled then
                checkLevels('notify_hunger', State.hunger, notifyCfg.hunger, false, 'warning', T.hunger, 'drumstick-bite')
            end
            if Config.Thirst.enabled then
                checkLevels('notify_thirst', State.thirst, notifyCfg.thirst, false, 'warning', T.thirst, 'droplet')
            end
            if Config.Stress.enabled then
                checkLevels('notify_stress', State.stress, notifyCfg.stress, true, 'warning', T.stress, 'brain')
            end
        end
    end
end)

---------------------------------------------------------------------------
-- Horse
---------------------------------------------------------------------------
CreateThread(function()
    if not notifyCfg.enabled then return end
    local T = GetUiLocale()
    local horseCfg = notifyCfg.horse or {}
    local wasVisible, horseWasExhausted = false, false

    while true do
        Wait(1000)
        local horse = State.horse

        if State.loggedIn and horse and horse.visible then
            local stamina, health = horse.stamina or {}, horse.health or {}

            -- values relative to THIS horse's maximum (the ring can be short)
            local staminaRel = stamina.rel or stamina.outer
            local healthRel  = health.rel or health.outer

            if not stamina.gold then
                checkLevels('notify_horse_tired', staminaRel, horseCfg.tired, false, 'warning', T.horseStamina, 'horse')
            end
            if not health.gold then
                checkLevels('notify_horse_hurt', healthRel, horseCfg.hurt, false, 'warning', T.horseHealth, 'horse')
            end

            if horseCfg.exhausted and stamina.exhausted and not horseWasExhausted then
                Notify(L('notify_horse_exhausted'), 'error', notifyCfg.duration, T.horseStamina, 'horse')
            end
            horseWasExhausted = stamina.exhausted == true
            wasVisible = true
        elseif wasVisible then
            -- dismounted: horse warnings start over on the next ride
            wasVisible, horseWasExhausted = false, false
            resetKey('notify_horse_tired')
            resetKey('notify_horse_hurt')
        end
    end
end)
