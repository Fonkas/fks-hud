local cfg = Config.Temperature

local clothingCold, clothingHot = 0, 0

local function toUnit(celsius)
    if cfg.unit == 'F' then return celsius * 9 / 5 + 32 end
    return celsius
end

-- Adds the degrees of the clothes being worn (recalculated every 5s)
CreateThread(function()
    if not cfg.enabled then return end
    while true do
        local ped = PlayerPedId()
        local cold, hot = 0, 0
        for _, piece in ipairs(cfg.clothing) do
            if Citizen.InvokeNative(0xFB4891BD7578CDC1, ped, piece.hash, Citizen.ResultAsInteger()) == 1 then
                cold = cold + (piece.cold or 0)
                hot  = hot + (piece.hot or 0)
            end
        end
        clothingCold, clothingHot = cold, hot
        Wait(5000)
    end
end)

local function itemModifier()
    local now, total = GetGameTimer(), 0
    for i = #State.tempMods, 1, -1 do
        local mod = State.tempMods[i]
        if mod.expires <= now then
            table.remove(State.tempMods, i)
        else
            total = total + mod.amount
        end
    end
    return total
end

function AddTemperatureModifier(amount, seconds)
    if not amount or amount == 0 then return end
    State.tempMods[#State.tempMods + 1] = { amount = amount, expires = GetGameTimer() + (seconds or 30) * 1000 }
end

-- Hunger / thirst multipliers based on temperature
function GetTemperatureMultipliers()
    if not cfg.enabled then return 1.0, 1.0 end
    local t = State.temp.value
    if t < cfg.comfort[1] then return cfg.coldHungerMultiplier, 1.0 end
    if t > cfg.comfort[2] then return 1.0, cfg.hotThirstMultiplier end
    return 1.0, 1.0
end

---------------------------------------------------------------------------
-- Felt temperature calculation
---------------------------------------------------------------------------
CreateThread(function()
    if not cfg.enabled then return end
    while true do
        local ped = PlayerPedId()
        local c = GetEntityCoords(ped)
        local base = Citizen.InvokeNative(0xB98B78C3768AF6E0, c.x, c.y, c.z, Citizen.ResultAsFloat()) or 20.0

        local value = base
        if base < cfg.comfort[1] then
            value = value + clothingCold
        elseif base > cfg.comfort[2] then
            value = value + clothingHot
        end

        if IsEntityInWater(ped) then value = value - 4 end
        value = value + itemModifier()

        local state = 'normal'
        if value <= cfg.min then state = 'freezing'
        elseif value < cfg.comfort[1] then state = 'cold'
        elseif value >= cfg.max then state = 'burning'
        elseif value > cfg.comfort[2] then state = 'hot' end

        State.temp.value   = value
        State.temp.display = math.floor(toUnit(value) + 0.5)
        State.temp.state   = state

        Wait(2000)
    end
end)

---------------------------------------------------------------------------
-- Damage from extreme cold / heat
---------------------------------------------------------------------------
CreateThread(function()
    if not cfg.enabled then return end
    local lastWarn = 0
    while true do
        Wait(cfg.interval)
        local ped = PlayerPedId()
        local state = State.temp.state

        if State.loggedIn and not IsDead(ped) and (state == 'freezing' or state == 'burning') then
            SetEntityHealth(ped, math.max(0, GetEntityHealth(ped) - cfg.damage), 0)
            if cfg.screenFx then PlayScreenFx(cfg.screenFx, 1500) end

            if GetGameTimer() - lastWarn > 30000 then
                lastWarn = GetGameTimer()
                Notify(L(state == 'freezing' and 'too_cold' or 'too_hot'), 'error')
            end
        end
    end
end)

exports('AddTemperatureModifier', AddTemperatureModifier)
exports('GetTemperature', function() return State.temp.value end)
