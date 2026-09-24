local props = {}

local function cleanup(ped)
    ClearPedTasks(ped)
    ClearPedSecondaryTask(ped)
    for i = #props, 1, -1 do
        if DoesEntityExist(props[i]) then
            DetachEntity(props[i], true, true)
            DeleteObject(props[i])
        end
        props[i] = nil
    end
end

local function spawnProp(model, ped)
    local hash = LoadModel(model)
    if not hash then
        Debug('invalid prop:', model)
        return nil
    end
    local c = GetEntityCoords(ped)
    local obj = CreateObject(hash, c.x, c.y, c.z + 0.2, true, true, false, false, true)
    SetModelAsNoLongerNeeded(hash)
    props[#props + 1] = obj
    return obj
end

local function hashOf(value)
    if not value then return 0 end
    return type(value) == 'number' and value or joaat(value)
end

---------------------------------------------------------------------------
-- Play animation (see config_animations.lua)
---------------------------------------------------------------------------
local function deleteProps()
    for i = #props, 1, -1 do
        if DoesEntityExist(props[i]) then DeleteObject(props[i]) end
        props[i] = nil
    end
end

-- is the native interaction running? (if it didn't start, the fallback animation is used)
local function isInteracting(ped)
    return Citizen.InvokeNative(0xEC7E480FF8BD0BED, ped, Citizen.ResultAsInteger()) == 1
end

-- attaches the object to the hand "prop point" (where the game holds objects)
local function attachToHand(ped, obj, anim)
    local bone = GetEntityBoneIndexByName(ped, anim.bone or 'PH_R_Hand')
    if bone == -1 then bone = GetEntityBoneIndexByName(ped, 'SKEL_R_HAND') end
    local o, r = anim.offset or {}, anim.rot or {}
    AttachEntityToEntity(obj, ped, bone,
        o.x or 0.0, o.y or 0.0, o.z or 0.0,
        r.x or 0.0, r.y or 0.0, r.z or 0.0,
        true, true, false, true, 2, true)
end

-- regular animation (dict + clip) with the object in the hand. Returns false if the animation doesn't exist.
local function playDictAnim(ped, anim, model)
    if not (anim.dict and LoadDict(anim.dict)) then return false end
    TaskPlayAnim(ped, anim.dict, anim.clip, 1.0, 1.0, -1, anim.flag or 31, 0.0, false, false, false)
    if model then
        local obj = spawnProp(model, ped)
        if obj then attachToHand(ped, obj, anim) end
    end
    return true
end

-- native scenario (the game handles everything: object, lighting, smoking...)
local function playScenario(ped, anim)
    TaskStartScenarioInPlace(ped, joaat(anim.scenario), -1, true, false, false, false)
end

-- native RDR2 item interaction
local function playInteraction(ped, anim, model)
    local interaction = hashOf(anim.interaction)

    if model then
        local obj = spawnProp(model, ped)
        if obj then
            if anim.spoon then
                Citizen.InvokeNative(0x669655FFB29EF1A9, obj, 0, 'Stew_Fill', 1.0)
                local spoon = spawnProp('p_spoon01x', ped)
                Citizen.InvokeNative(0x72F52AA2D2B172CC, ped, 599184882, obj, hashOf(anim.propId), interaction, 1, 0, -1.0)
                if spoon then
                    Citizen.InvokeNative(0x72F52AA2D2B172CC, ped, 599184882, spoon, joaat('p_spoon01x_PH_R_HAND'), interaction, 1, 0, -1.0)
                end
            else
                -- 'PrimaryItem' = generic slot used by most eating / drinking interactions
                Citizen.InvokeNative(0x72F52AA2D2B172CC, ped, hashOf(anim.item), obj, hashOf(anim.propId or 'PrimaryItem'), interaction, 1, 0, -1.0)
            end
            return
        end
    end

    -- no object: same as fred_metabolism
    TaskItemInteraction(ped, 0, interaction, true, 0, 0)
end

local playAnimation
function playAnimation(ped, anim, propOverride)
    local model = propOverride or anim.prop

    if anim.type == 'scenario' then
        return playScenario(ped, anim)
    end

    if anim.type ~= 'interaction' then
        if not playDictAnim(ped, anim, model) and anim.fallback then
            Debug(('animation "%s" does not exist - using fallback'):format(tostring(anim.dict)))
            deleteProps()
            return playAnimation(ped, anim.fallback, propOverride)
        end
        return
    end

    playInteraction(ped, anim, model)

    Wait(500)

    -- the interaction didn't start: use the fallback animation
    if not isInteracting(ped) then
        if anim.fallback then
            Debug(('interaction "%s" did not start - using fallback animation'):format(anim.interaction))
            deleteProps()
            ClearPedTasks(ped)
            playAnimation(ped, anim.fallback, anim.fallback.prop or model)
        else
            Debug(('interaction "%s" did not start'):format(anim.interaction))
        end
        return
    end

    -- the interaction started but the game didn't attach the object to the hand: attach it ourselves
    local bone = anim.hand == 'L' and 'PH_L_Hand' or 'PH_R_Hand'
    for _, obj in ipairs(props) do
        if DoesEntityExist(obj) and not IsEntityAttachedToEntity(obj, ped) then
            Debug(('object %s manually attached to %s'):format(tostring(model), bone))
            attachToHand(ped, obj, { bone = bone })
        end
    end
end

---------------------------------------------------------------------------
-- SMOKE MODE: Smoke / Change stance / Drop prompts while smoking
---------------------------------------------------------------------------
local function makePrompt(group, key, text, hold)
    local prompt = PromptRegisterBegin()
    PromptSetControlAction(prompt, RSGCore.Shared.Keybinds[key] or RSGCore.Shared.Keybinds['E'])
    PromptSetText(prompt, CreateVarString(10, 'LITERAL_STRING', text))
    PromptSetEnabled(prompt, true)
    PromptSetVisible(prompt, true)
    if hold then PromptSetHoldMode(prompt, true) else PromptSetStandardMode(prompt, true) end
    PromptSetGroup(prompt, group, 0)
    PromptRegisterEnd(prompt)
    return prompt
end

-- plays an animation until it ends (with a time limit)
local function playOnce(ped, dict, clip, flag, maxMs)
    if not LoadDict(dict) then return end
    TaskPlayAnim(ped, dict, clip, 2.0, -2.0, -1, flag or 0, 0.0, false, false, false)
    Wait(150)
    local limit = GetGameTimer() + (maxMs or 6000)
    while IsEntityPlayingAnim(ped, dict, clip, 3) and GetGameTimer() < limit do Wait(100) end
end

-- picks the male / female version (falls back to male if there's no female one)
local function forGender(tbl, female)
    return (female and tbl.female) or tbl.male
end

-- attaches the object to a config "spot" ({ bone, x, y, z, rotX, rotY, rotZ })
local function attachSpot(ped, obj, spot)
    if not (obj and spot) then return end
    local bone = GetEntityBoneIndexByName(ped, spot[1])
    if bone == -1 then bone = GetEntityBoneIndexByName(ped, 'SKEL_R_HAND') end
    AttachEntityToEntity(obj, ped, bone, spot[2] + 0.0, spot[3] + 0.0, spot[4] + 0.0,
        spot[5] + 0.0, spot[6] + 0.0, spot[7] + 0.0, true, true, false, true, 1, true)
end

-- looping pose (flag 31 = loop, upper body only, you can walk)
local function loopAnim(ped, a)
    if a and LoadDict(a[1]) then
        TaskPlayAnim(ped, a[1], a[2], 2.0, -2.0, -1, 31, 0.0, false, false, false)
        return true
    end
    return false
end

function StartSmoking(itemName, item, anim)
    local ped    = PlayerPedId()
    local female = not IsPedMale(ped)
    local set    = forGender(anim, female)       -- anim.male / anim.female
    local spots  = anim.spots or {}
    local handSpot = spots[set.hand or 'hand']
    local keys   = Config.Smoking.keys

    -- object
    local model = item.prop or anim.prop
    local obj = model and spawnProp(model, ped)
    for i = #props, 1, -1 do if props[i] == obj then table.remove(props, i) end end -- handled here, not by cleanup()

    -- light up: the object moves between hand / mouth following the animation
    local intro = set.intro
    if intro then
        if intro.anim and LoadDict(intro.anim[1]) then
            TaskPlayAnim(ped, intro.anim[1], intro.anim[2], 2.0, -2.0, -1, 0, 0.0, false, false, false)
        end
        local t0 = GetGameTimer()
        for _, step in ipairs(intro.steps or {}) do
            local waitFor = step[1] - (GetGameTimer() - t0)
            if waitFor > 0 then Wait(waitFor) end
            attachSpot(ped, obj, spots[step[2]])
        end
        local rest = (intro.time or 0) - (GetGameTimer() - t0)
        if rest > 0 then Wait(rest) end
    end
    attachSpot(ped, obj, handSpot)

    -- the server consumes the item (or the pipe tobacco) and applies the item effects
    TriggerServerEvent('fks-hud:server:finishItem', itemName)

    local stances, idx = set.stances or {}, 1
    local function stance() return stances[idx] or {} end

    -- back to the current stance pose (if "base" doesn't exist, the first puff is looped instead)
    local function playBase()
        local st = stance()
        if not loopAnim(ped, st.base) then loopAnim(ped, st.puffs and st.puffs[1]) end
    end

    local group = math.random(0, 0xFFFFFF)
    local pPuff = makePrompt(group, keys.puff, L('smoke_puff'), false)
    local pPose = makePrompt(group, keys.pose, L('smoke_pose'), false)
    local pDrop = makePrompt(group, keys.drop, L(anim.keepProp and 'smoke_put_away' or 'smoke_drop'), true)

    local puffsLeft, finished, interrupted = anim.puffs or 8, false, false
    local itemLabel = ItemLabel(itemName)
    playBase()

    while true do
        Wait(0)
        ped = PlayerPedId()

        if IsDead(ped) or IsPedRagdoll(ped) or IsPedSwimming(ped) or IsPedOnMount(ped) or IsPedInAnyVehicle(ped, false) then
            interrupted = true
            break
        end

        local stanceLabel = stance().label and L(stance().label) or ''
        local title = ('%s - %s  (%d)'):format(itemLabel, stanceLabel, puffsLeft)
        PromptSetActiveGroupThisFrame(group, CreateVarString(10, 'LITERAL_STRING', title))

        if PromptHasStandardModeCompleted(pPuff) then
            -- puff: smoking animation of the current stance (upper body only)
            local list = stance().puffs or {}
            local pick = list[math.random(math.max(#list, 1))]
            if pick then playOnce(ped, pick[1], pick[2], 16, 25000) end
            AddNeed('stress', anim.puffStress or -2)
            ShowConsumeTips({ stress = anim.puffStress or -2 })
            puffsLeft = puffsLeft - 1
            if puffsLeft <= 0 then
                finished = true
                break
            end
            playBase()

        elseif PromptHasStandardModeCompleted(pPose) and #stances > 1 then
            -- change stance (using the game's transitions)
            local old = stance()
            idx = idx % #stances + 1
            local new = stance()
            local trans = old.leave or new.enter
            if trans then playOnce(ped, trans[1], trans[2], 16, 7000) end
            playBase()

        elseif PromptHasHoldModeCompleted(pDrop) then
            break
        end
    end

    PromptDelete(pPuff)
    PromptDelete(pPose)
    PromptDelete(pDrop)

    -- drop / put away
    local drop = set.drop
    local t0 = GetGameTimer()
    if not interrupted and drop and drop.anim and LoadDict(drop.anim[1]) then
        TaskPlayAnim(ped, drop.anim[1], drop.anim[2], 2.0, -2.0, -1, 0, 0.0, false, false, false)
        Wait(drop.detachAt or 2500)
    end

    if obj and DoesEntityExist(obj) then
        DetachEntity(obj, true, true)
        if anim.keepProp then
            DeleteObject(obj) -- the pipe goes back to the inventory
        else
            -- the butt falls to the ground and disappears after a while
            SetEntityAsMissionEntity(obj, true, true)
            SetEntityVelocity(obj, 0.0, 0.0, -1.0)
            SetTimeout((Config.Smoking.dropTime or 20) * 1000, function()
                if DoesEntityExist(obj) then DeleteObject(obj) end
            end)
        end
    end

    if not interrupted and drop then
        local rest = 1500 - (GetGameTimer() - t0 - (drop.detachAt or 0))
        if rest > 0 then Wait(rest) end
    end
    ClearPedSecondaryTask(ped)
    ClearPedTasks(ped)

    if finished then Notify(L('smoke_finished'), 'inform', 3000) end
end

---------------------------------------------------------------------------
-- 1) The server tells us to use the item
---------------------------------------------------------------------------
RegisterNetEvent('fks-hud:client:useItem', function(itemName)
    local item = Consumables[itemName]
    if not item then return end

    local ped = PlayerPedId()

    if State.busy then
        Notify(L('busy'), 'error')
        return TriggerServerEvent('fks-hud:server:cancelItem', itemName)
    end

    if IsDead(ped) or IsPedSwimming(ped) or IsPedRagdoll(ped) then
        Notify(L('cant_now'), 'error')
        return TriggerServerEvent('fks-hud:server:cancelItem', itemName)
    end

    if item.onHorse == false and (IsPedOnMount(ped) or IsPedInAnyVehicle(ped, false)) then
        Notify(L('not_on_horse'), 'error')
        return TriggerServerEvent('fks-hud:server:cancelItem', itemName)
    end

    State.busy = true
    local anim = Animations[item.anim or ''] or {}

    SetCurrentPedWeapon(ped, joaat('WEAPON_UNARMED'), true, 0, false, false)
    Wait(150)

    -- cigarette / cigar / pipe: smoke mode with prompts (see above)
    if anim.type == 'smoke' then
        StartSmoking(itemName, item, anim)
        State.busy = false
        return
    end

    playAnimation(ped, anim, item.prop)

    local done = lib.progressBar({
        duration     = anim.duration or 3000,
        label        = anim.label and L(anim.label) or ItemLabel(itemName),
        useWhileDead = false,
        canCancel    = true,
        disable      = { combat = true, sprint = true },
    })

    cleanup(ped)
    State.busy = false

    if done then
        TriggerServerEvent('fks-hud:server:finishItem', itemName)
    else
        Notify(L('cancelled'), 'error', 2500)
        TriggerServerEvent('fks-hud:server:cancelItem', itemName)
    end
end)

---------------------------------------------------------------------------
-- 2) The server confirmed (item removed) -> apply effects
---------------------------------------------------------------------------
local function pick(value)
    if type(value) == 'table' then
        return math.random(value[1] or 0, value[2] or value[1] or 0)
    end
    return value
end

RegisterNetEvent('fks-hud:client:applyItem', function(itemName)
    local item = Consumables[itemName]
    if not item then return end

    local ped = PlayerPedId()
    local tips = {}

    local needs = item.needs or {}
    for _, name in ipairs({ 'hunger', 'thirst', 'stress' }) do
        if needs[name] and needs[name] ~= 0 then
            AddNeed(name, needs[name])
            tips[name] = needs[name]
        end
    end

    local heal = item.heal or {}
    local before = { GetCore(ped, CORE_HEALTH), GetCore(ped, CORE_STAMINA) }
    if heal.health then AddHealthPercent(ped, heal.health) end
    if heal.stamina then AddStaminaPercent(ped, heal.stamina) end
    if heal.healthCore then AddCore(ped, CORE_HEALTH, heal.healthCore) end
    if heal.staminaCore then AddCore(ped, CORE_STAMINA, heal.staminaCore) end
    Debug(('%s applied | health core %d -> %d | stamina core %d -> %d | exhausted: %s'):format(
        itemName, before[1], GetCore(ped, CORE_HEALTH), before[2], GetCore(ped, CORE_STAMINA), tostring(State.exhausted)))
    tips.health  = (heal.health or 0) + (heal.healthCore or 0)
    tips.stamina = (heal.stamina or 0) + (heal.staminaCore or 0)

    local gold = item.gold or {}
    if gold.health then SetGold(ped, 'health', pick(gold.health)) end
    if gold.stamina then SetGold(ped, 'stamina', pick(gold.stamina)) end

    if item.temp then
        AddTemperatureModifier(item.temp.amount, item.temp.time)
        tips.temperature = item.temp.amount
    end

    if item.screenFx then
        PlayScreenFx(item.screenFx.name, (item.screenFx.time or 10) * 1000)
    end

    ShowConsumeTips(tips)
end)
