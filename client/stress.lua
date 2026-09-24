local cfg = Config.Stress
if not cfg.enabled then return end

local UNARMED = joaat('WEAPON_UNARMED')

---------------------------------------------------------------------------
-- Stress gain: shooting
---------------------------------------------------------------------------
CreateThread(function()
    local shooting = cfg.gain.shooting
    while true do
        local ped = PlayerPedId()
        local _, weapon = GetCurrentPedWeapon(ped, true, 0, false)

        if State.loggedIn and weapon ~= UNARMED then
            if IsPedShooting(ped) and math.random(100) <= shooting.chance then
                AddNeed('stress', shooting.amount)
            end
            Wait(50)
        else
            Wait(1000)
        end
    end
end)

---------------------------------------------------------------------------
-- Stress gain: melee combat and galloping very fast
---------------------------------------------------------------------------
CreateThread(function()
    local melee, horse = cfg.gain.melee, cfg.gain.horseSpeed
    local nextMelee, nextHorse = 0, 0

    while true do
        Wait(500)
        local ped, now = PlayerPedId(), GetGameTimer()

        if State.loggedIn and not IsDead(ped) then
            if now >= nextMelee and IsPedInMeleeCombat(ped) then
                nextMelee = now + melee.interval
                AddNeed('stress', melee.amount)
            end

            if now >= nextHorse and IsPedOnMount(ped) then
                nextHorse = now + horse.interval
                if GetEntitySpeed(GetMount(ped)) >= horse.speed then
                    AddNeed('stress', horse.amount)
                end
            end
        end
    end
end)

---------------------------------------------------------------------------
-- Natural recovery
---------------------------------------------------------------------------
CreateThread(function()
    local rec = cfg.recovery
    while true do
        Wait(10000)
        local ped = PlayerPedId()

        if State.loggedIn and State.stress > 0 and not IsDead(ped) then
            local amount = rec.perMinute / 6
            if IsPedUsingAnyScenario(ped) then
                amount = amount * rec.scenarioMultiplier
            end
            AddNeed('stress', -amount)
        end
    end
end)

---------------------------------------------------------------------------
-- High stress effects
---------------------------------------------------------------------------
-- the camera shakes while stress is high (more stress = more shaking + jolts)
local shaking = nil -- current intensity (nil = stopped)

local function stopShake()
    if shaking then
        StopGameplayCamShaking(false)
        shaking = nil
    end
end

CreateThread(function()
    local nextJolt, resumeAt = 0, 0
    while true do
        Wait(500)
        local amp, jolt
        for _, lvl in ipairs(cfg.levels) do
            if State.stress >= lvl.from then amp, jolt = lvl.shake, lvl.jolt end
        end

        local ped = PlayerPedId()
        local active = amp and amp > 0 and State.loggedIn and not IsDead(ped)

        -- strong jolts on the highest levels
        if active and jolt and GetGameTimer() >= nextJolt then
            nextJolt = GetGameTimer() + jolt[1]
            ShakeGameplayCam(cfg.joltType or 'SMALL_EXPLOSION_SHAKE', jolt[2])
            shaking = nil                        -- the jolt replaces the shake...
            resumeAt = GetGameTimer() + 1000     -- ...which resumes 1s later (so the jolt can be felt)
        end

        if active then
            if GetGameTimer() < resumeAt then
                -- in the middle of a jolt
            elseif not shaking then
                ShakeGameplayCam(cfg.shakeType or 'HAND_SHAKE', amp)
            elseif shaking ~= amp then
                SetGameplayCamShakeAmplitude(amp)
            end
            shaking = amp
        else
            stopShake()
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then stopShake() end
end)
