--[[
    CONSUMABLE ITEMS
    ----------------
    Each entry is the item NAME (it must exist in rsg-core/shared/items.lua or ox_inventory).
    The script registers them as "useable" by itself - do not register them in other scripts.

    Every field is optional, use only what you need:

    label     = name shown in notifications (default: the item label from the inventory)
    anim      = animation to use (see config_animations.lua)
    prop      = changes the object shown in the hand (e.g. 'p_apple01x', 'P_HAMSANDWICH01X', 's_canpeaches01x')
                object list: https://github.com/femga/rdr3_discoveries/tree/master/tasks/TASK_ITEM_INTERACTION

    needs     = { hunger = 0, thirst = 0, stress = 0 }
                -> positive values fill, negative values drain (positive stress INCREASES stress)

    heal      = { health = 0, stamina = 0, healthCore = 0, staminaCore = 0 }
                -> health / stamina   = outer ring (in %)
                -> healthCore / ...   = inner core (0-100)

    gold      = { health = 0, stamina = 0 }
                -> seconds of GOLD core (overpower). Can be { min, max } for a random value.

    temp      = { amount = -2, time = 20 }
                -> adds degrees to the player's temperature for X seconds

    screenFx  = { name = 'PlayerDrunk01', time = 30 }  -> screen effect for X seconds

    cooldown  = seconds before this item can be used again
    onHorse   = false to block using it while mounted (default: true)
    keep      = true to NOT remove the item when used (e.g. pipe)
    requires  = item the player must have, consumed on every use (e.g. tobacco for the pipe)
    giveBack  = item the player receives after using it (e.g. empty bottle)
]]

-- Every item below exists in rsg-core/shared/items.lua
Consumables = {

    ---------------------------------------------------------------- DRINKS
    ['water'] = {
        anim  = 'drink',
        needs = { thirst = 30, stress = -1 },
        heal  = { staminaCore = 10 },
        temp  = { amount = -2, time = 20 },
    },

    ['coffee'] = {
        anim  = 'coffee',
        needs = { thirst = 15, stress = -3 },
        heal  = { stamina = 30, staminaCore = 50 }, -- coffee restores the most stamina
        temp  = { amount = 4, time = 60 },
    },

    ['beer'] = {
        anim  = 'beer',
        needs = { thirst = 10, stress = -5 },
        heal  = { staminaCore = 10 },
        screenFx = { name = 'PlayerDrunk01', time = 20 },
    },

    ---------------------------------------------------------------- FOOD
    ['bread'] = {
        anim  = 'eat',
        prop  = 'p_bread06x',
        needs = { hunger = 25, thirst = -2, stress = -1 },
        heal  = { health = 5, healthCore = 3, staminaCore = 15 },
    },

    ['stew'] = {
        anim  = 'stew',
        needs = { hunger = 50, thirst = 5, stress = -3 },
        heal  = { healthCore = 15, staminaCore = 35 },
        temp  = { amount = 5, time = 90 },
        onHorse = false,
    },

    ['canned_apricots'] = {
        anim  = 'canned',
        needs = { hunger = 20, thirst = 10 },
        heal  = { staminaCore = 15 },
    },

    ['animal_heart'] = {
        anim  = 'eat',
        prop  = 's_offal01x',
        needs = { hunger = 15, thirst = -5, stress = 2 },
        heal  = { healthCore = 10 },
    },

    ---------------------------------------------------------------- SMOKING
    -- smoke mode: every puff relieves stress (see config_animations.lua). On foot only.
    ['cigarette'] = {
        anim  = 'cigarette',
        needs = { hunger = -1 },
        heal  = { staminaCore = 5, healthCore = -2 },
        onHorse  = false,
        cooldown = 30,
    },

    ['cigar'] = {
        anim  = 'cigar',
        needs = { hunger = -1 },
        heal  = { staminaCore = 10, healthCore = -3 },
        onHorse  = false,
        cooldown = 60,
    },

    -- the pipe is not consumed; it needs tobacco and uses 1 per smoke
    ['pipe'] = {
        anim     = 'pipe',
        keep     = true,
        requires = 'pipe_tobacco',
        heal     = { staminaCore = 8, healthCore = -2 },
        onHorse  = false,
        cooldown = 45,
    },

    ---------------------------------------------------------------- MEDICAL (HEALING)
    ['bandage'] = {
        anim  = 'bandage',
        heal  = { health = 35 },
        onHorse  = false,
        cooldown = 60,
    },

    ['fieldbandage'] = {
        anim  = 'bandage',
        heal  = { health = 20, healthCore = 10 },
        onHorse  = false,
        cooldown = 30,
    },

    ['firstaid'] = {
        anim  = 'bandage',
        heal  = { health = 100, healthCore = 50 },
        onHorse  = false,
        cooldown = 120,
    },

    ---------------------------------------------------------------- TONICS (BOOST / GOLD)
    ['tonic_healing'] = {
        anim  = 'tonic',
        heal  = { health = 50, healthCore = 100 },
        gold  = { health = 120 },
        cooldown = 180,
    },

    ['tonic_stamina'] = {
        anim  = 'tonic',
        heal  = { stamina = 100, staminaCore = 100 },
        gold  = { stamina = 120 },
        cooldown = 180,
    },

    ['tonic_energy'] = {
        anim  = 'tonic',
        needs = { stress = -8 },
        heal  = { health = 25, stamina = 50 },
        gold  = { health = { 30, 40 }, stamina = { 30, 40 } },
        cooldown = 120,
    },

    ['tonic_antidote'] = {
        anim  = 'tonic',
        prop  = 's_inv_antidote01x',
        needs = { stress = -5 },
        heal  = { health = 15, healthCore = 25 },
        cooldown = 60,
    },
}
