-- State shared between all client files
State = {
    loggedIn   = false,
    hunger     = 100.0,
    thirst     = 100.0,
    stress     = 0.0,
    busy       = false, -- consuming an item
    exhausted  = false, -- stamina ran out and the core is not back to 100% yet
    exhaustCore = 0,    -- core value when it ran out (starting point of the recovery)
    temp       = { value = 20.0, unit = Config.Temperature.unit, state = 'normal' },
    tempMods   = {},    -- { amount, expires }
    gold       = { health = 0, stamina = 0 }, -- GetGameTimer() when the gold boost ends
}

-- chosen language (Config.Locale); any missing text falls back to English
local lang     = Locales[Config.Locale] or Locales['en']
local fallback = Locales['en'] or {}

function L(key, ...)
    local str = lang[key] or fallback[key] or key
    if type(str) == 'string' and select('#', ...) > 0 then
        return str:format(...)
    end
    return str
end

-- texts for the NUI (/hudsettings), with English fallback for missing keys
function GetUiLocale()
    local ui = {}
    for k, v in pairs(fallback.ui or {}) do ui[k] = v end
    for k, v in pairs(lang.ui or {}) do ui[k] = v end
    return ui
end

-- item name: config label > inventory label (RSG / VORP) > item name
function ItemLabel(name)
    local cfg = Consumables and Consumables[name]
    if cfg and cfg.label then return cfg.label end
    return Bridge.ItemLabel(name)
end

function Debug(...)
    if Config.Debug then print('[fks-hud]', ...) end
end

function Notify(msg, kind, duration, title, icon)
    lib.notify({
        title       = title,
        description = msg,
        type        = kind or 'inform',
        duration    = duration or 5000,
        icon        = icon,
        position    = Config.Notifications and Config.Notifications.position or nil,
    })
end

local function clamp(v, min, max)
    if v < min then return min end
    if v > max then return max end
    return v
end
Clamp = clamp

---------------------------------------------------------------------------
-- Needs (hunger / thirst / stress) - stored in the RSG statebags
---------------------------------------------------------------------------
local NEEDS = { hunger = true, thirst = true, stress = true }

function SetNeed(name, value)
    if not NEEDS[name] then return end
    value = clamp(value + 0.0, 0.0, 100.0)
    State[name] = value
    -- saved by the framework: rsg-core persists these statebags, on VORP bridge/server.lua does it
    LocalPlayer.state:set(name, math.floor(value * 100 + 0.5) / 100, true)
end

function AddNeed(name, amount)
    if not NEEDS[name] or not amount or amount == 0 then return end
    SetNeed(name, State[name] + amount)
end

function LoadNeedsFromState()
    local saved = Bridge.GetSavedNeeds()
    State.hunger = saved.hunger
    State.thirst = saved.thirst
    State.stress = saved.stress
end

-- Changes made by the server (admins, rsg-medic, other scripts...)
for name in pairs(NEEDS) do
    AddStateBagChangeHandler(name, ('player:%s'):format(GetPlayerServerId(PlayerId())), function(_, _, value)
        value = tonumber(value)
        if value and math.abs(value - State[name]) > 0.01 then
            State[name] = clamp(value, 0.0, 100.0)
        end
    end)
end

---------------------------------------------------------------------------
-- Health / stamina cores
---------------------------------------------------------------------------
CORE_HEALTH, CORE_STAMINA = 0, 1

function GetCore(ped, index)
    return Citizen.InvokeNative(0x36731AC041289BB1, ped, index, Citizen.ResultAsInteger()) or 0
end

function SetCore(ped, index, value)
    Citizen.InvokeNative(0xC6258F41D86676E0, ped, index, math.floor(clamp(value, 0, 100)))
end

function AddCore(ped, index, amount)
    if not amount or amount == 0 then return end
    SetCore(ped, index, GetCore(ped, index) + amount)
end

function IsCoreGold(ped, index)
    return Citizen.InvokeNative(0x200373A8DF081F22, ped, index, Citizen.ResultAsInteger()) == 1
end

function GetHealthPercent(ped)
    local max = GetEntityMaxHealth(ped)
    if max <= 0 then return 0 end
    return clamp(GetEntityHealth(ped) / max * 100.0, 0.0, 100.0)
end

function AddHealthPercent(ped, pct)
    if not pct or pct == 0 then return end
    local max = GetEntityMaxHealth(ped)
    SetEntityHealth(ped, math.floor(clamp(GetEntityHealth(ped) + max * pct / 100.0, 0, max)), 0)
end

function GetStaminaPercent(ped)
    local cur = Citizen.InvokeNative(0x775A1CA7893AA8B5, ped, Citizen.ResultAsFloat()) or 0.0
    local max = Citizen.InvokeNative(0xCB42AFE2B613EE55, ped, Citizen.ResultAsFloat()) or 0.0
    if max <= 0 then return 100.0 end
    return clamp(cur / max * 100.0, 0.0, 100.0)
end

function AddStaminaPercent(ped, pct)
    if not pct or pct == 0 then return end
    local max = Citizen.InvokeNative(0xCB42AFE2B613EE55, ped, Citizen.ResultAsFloat()) or 100.0
    Citizen.InvokeNative(0xC3D4B754C0E86B9E, ped, max * pct / 100.0)
end

-- Gold core (overpower) for X seconds
function SetGold(ped, which, seconds)
    if not seconds or seconds <= 0 then return end
    local index = which == 'health' and CORE_HEALTH or CORE_STAMINA
    SetCore(ped, index, 100)
    Citizen.InvokeNative(0x4AF5A4C7B9157D14, ped, index, seconds + 0.0, true) -- core
    Citizen.InvokeNative(0xF6A7C08DF2E28B28, ped, index, seconds + 0.0, true) -- outer ring
    State.gold[which] = math.max(State.gold[which], GetGameTimer() + seconds * 1000)
end

function ExhaustRecovery(core, startCore)
    if startCore >= 100 then return 1.0 end
    return clamp((core - startCore) / (100 - startCore), 0.0, 1.0)
end

-- seconds left on the gold boost given by an item (0 = no boost)
function GoldSecondsLeft(which)
    local left = State.gold[which] - GetGameTimer()
    if left <= 0 then return 0 end
    return math.ceil(left / 1000)
end

function IsGold(ped, which)
    if State.gold[which] > GetGameTimer() then return true end
    return IsCoreGold(ped, which == 'health' and CORE_HEALTH or CORE_STAMINA)
end

---------------------------------------------------------------------------
-- Player state
---------------------------------------------------------------------------
function GetActivity(ped)
    if IsPedOnMount(ped) or IsPedInAnyVehicle(ped, false) then return 'mounted' end
    if IsPedSwimming(ped) then return 'swim' end
    if IsPedSprinting(ped) or IsPedRunning(ped) then return 'run' end
    if IsPedWalking(ped) then return 'walk' end
    return 'idle'
end

function IsDead(ped)
    return IsEntityDead(ped) or LocalPlayer.state.isDead == true
end

function PlayScreenFx(name, duration)
    if not name then return end
    AnimpostfxPlay(name)
    if duration then
        SetTimeout(duration, function() AnimpostfxStop(name) end)
    end
end

function LoadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelValid(hash) then return nil end
    RequestModel(hash, false)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(10) end
    return HasModelLoaded(hash) and hash or nil
end

function LoadDict(dict)
    if not DoesAnimDictExist(dict) then
        Debug('animation does not exist:', dict)
        return false
    end
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do Wait(10) end
    return HasAnimDictLoaded(dict)
end
