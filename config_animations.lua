--[[
    CONSUMPTION ANIMATIONS
    ----------------------
    Types:

    type = 'interaction'  -> native RDR2 item interactions (the same as story mode).
                             The game plays the animation and holds the object in the hand.
        interaction = interaction name
        prop        = object model (an item can change it with "prop" in config_items.lua)
        propId      = object "slot" (default 'PrimaryItem', which works for almost all of them)
        item        = related native item (optional)
        hand        = 'R' or 'L' - hand the object is attached to if the game doesn't attach it by itself
        fallback    = alternative animation (type 'anim') if the interaction doesn't start

    type = 'smoke'        -> smoke mode with prompts (see cigarette / cigar / pipe below)

    type = 'scenario'     -> native scenario (e.g. 'WORLD_HUMAN_SMOKE'); the game handles the object
        scenario = scenario name

    type = 'anim'         -> regular animation (dict + clip) with the object attached to the hand
        fallback = alternative animation if this dict doesn't exist
        dict, clip, flag
        prop, bone (default 'PH_R_Hand' = the point where the hand holds objects)
        offset = { x, y, z }, rot = { x, y, z }  (fine tuning, usually 0)

    duration = progress bar / animation time (ms)
    label    = progress bar text - it is a KEY from the locales/ files (translated automatically)

    Interactions and objects list: https://github.com/femga/rdr3_discoveries/tree/master/tasks/TASK_ITEM_INTERACTION
]]

-- drinking animation used as fallback (bottle attached to the hand)
local drinkFallback = {
    type = 'anim',
    dict = 'amb_rest_drunk@world_human_drinking@female_a@idle_a',
    clip = 'idle_a',
    flag = 31,
    bone = 'PH_R_Hand',
}

Animations = {
    -- bread, sandwiches, fruit... (an item can change the object with "prop")
    eat = {
        type        = 'interaction',
        interaction = 'EAT_MULTI_BITE_FOOD_SPHERE_D8-2_SANDWICH_QUICK_LEFT_HAND',
        prop        = 'p_bread06x',
        hand        = 'L',
        duration    = 5000,
        label       = 'progress_eating',
    },

    -- cans (apricots, beans, peaches...)
    canned = {
        type        = 'interaction',
        interaction = 'EAT_CANNED_FOOD_CYLINDER@D8-2_H10-5_QUICK_LEFT',
        prop        = 's_canapricots01x',
        hand        = 'L',
        duration    = 5000,
        label       = 'progress_eating',
    },

    drink = {
        type        = 'interaction',
        interaction = 'DRINK_BOTTLE@Bottle_Cylinder_D1-3_H30-5_Neck_A13_B2-5_UNCORK',
        prop        = 'p_bottlejd01x',
        item        = 'CONSUMABLE_COFFEE',
        hand        = 'R',
        duration    = 6000,
        label       = 'progress_drinking',
        fallback    = drinkFallback,
    },

    beer = {
        type        = 'interaction',
        interaction = 'DRINK_BOTTLE@Bottle_Cylinder_D1-55_H18_Neck_A8_B1-8_UNCORK',
        prop        = 'p_bottlebeer01x',
        item        = 'CONSUMABLE_COFFEE',
        hand        = 'R',
        duration    = 6000,
        label       = 'progress_beer',
        fallback    = drinkFallback,
    },

    coffee = {
        type        = 'interaction',
        interaction = 'DRINK_COFFEE_HOLD',
        prop        = 'p_mugcoffee01x',
        propId      = 'p_mugCoffee01x_PH_R_HAND',
        item        = 'CONSUMABLE_COFFEE',
        hand        = 'R',
        duration    = 6000,
        label       = 'progress_coffee',
        fallback    = drinkFallback,
    },

    stew = {
        type        = 'interaction',
        interaction = 'EAT_STEW_BOWL_BASE',
        prop        = 'p_bowl04x_stew',
        propId      = 'p_bowl04x_stew_PH_L_HAND',
        spoon       = true, -- spawns a spoon in the right hand
        hand        = 'L',
        duration    = 9000,
        label       = 'progress_stew',
    },

    tonic = {
        type        = 'interaction',
        interaction = 'USE_TONIC_SATCHEL_UNARMED_QUICK',
        prop        = 's_inv_supertonic01x',
        hand        = 'R',
        duration    = 3500,
        label       = 'progress_tonic',
        fallback    = {
            type = 'anim',
            dict = 'amb_rest_drunk@world_human_drinking@female_a@idle_a',
            clip = 'idle_a',
            flag = 31,
            bone = 'PH_R_Hand',
        },
    },

    ---------------------------------------------------------------- SMOKING
    --[[ type = 'smoke' -> smoke mode with prompts: Smoke / Change stance / Drop
         prop       = object  |  puffs = puffs until it's finished  |  puffStress = stress relieved per puff
         spots      = where the object is attached: { bone, x, y, z, rotX, rotY, rotZ }
         male / female (if there's no 'female', 'male' is used):
             intro   = { anim = {dict, clip}, steps = { {ms, 'spot'}, ... }, time = ms }  -> light up
             hand    = spot used during the stances (default 'hand')
             stances = { label (locale key), enter = transition, base = looping pose,
                         puffs = { {dict, clip}, ... }, leave = transition when leaving }
             drop    = { anim = {dict, clip}, detachAt = ms }  -> drop / put away ]]
    cigarette = {
        type = 'smoke', prop = 'p_cigarette01x', puffs = 8, puffStress = -2,
        spots = {
            hand      = { 'SKEL_R_Finger13', 0.017, -0.01, -0.01, 0.0, 120.0, 10.0 },
            handLight = { 'SKEL_R_Finger13', 0.03, -0.01, 0.0, 0.0, 90.0, 0.0 },
            mouth     = { 'skel_head', -0.017, 0.1, -0.01, 0.0, 90.0, -90.0 },
            handF     = { 'SKEL_R_Finger13', 0.01, 0.0, 0.01, 0.0, -160.0, -130.0 },
        },
        male = {
            intro = {
                anim  = { 'amb_rest@world_human_smoking@male_c@stand_enter', 'enter_back_rf' },
                steps = { { 0, 'handLight' }, { 1000, 'mouth' }, { 4000, 'hand' } },
                time  = 5400,
            },
            stances = {
                { label = 'stance_standing',
                  base  = { 'amb_rest@world_human_smoking@male_c@base', 'base' },
                  puffs = { { 'amb_rest@world_human_smoking@male_c@idle_a', 'idle_a' }, { 'amb_rest@world_human_smoking@male_c@idle_a', 'idle_b' } } },
                { label = 'stance_nervous',
                  base  = { 'amb_rest@world_human_smoking@nervous_stressed@male_b@base', 'base' },
                  puffs = { { 'amb_rest@world_human_smoking@nervous_stressed@male_b@idle_a', 'idle_a' }, { 'amb_rest@world_human_smoking@nervous_stressed@male_b@idle_c', 'idle_g' } } },
                { label = 'stance_casual',
                  base  = { 'amb_rest@world_human_smoking@male_d@base', 'base' },
                  puffs = { { 'amb_rest@world_human_smoking@male_d@idle_a', 'idle_b' }, { 'amb_rest@world_human_smoking@male_d@idle_c', 'idle_g' } } },
                { label = 'stance_walking',
                  enter = { 'amb_rest@world_human_smoking@male_d@trans', 'd_trans_a' },
                  base  = { 'amb_wander@code_human_smoking_wander@male_a@base', 'base' },
                  puffs = { { 'amb_rest@world_human_smoking@male_a@idle_a', 'idle_a' }, { 'amb_rest@world_human_smoking@male_a@idle_a', 'idle_b' } },
                  leave = { 'amb_rest@world_human_smoking@male_a@trans', 'a_trans_c' } },
            },
            drop = { anim = { 'amb_rest@world_human_smoking@male_a@stand_exit', 'exit_back' }, detachAt = 2800 },
        },
        female = {
            intro = { steps = { { 0, 'mouth' }, { 1000, 'handF' } }, time = 2500 },
            hand  = 'handF',
            stances = {
                { label = 'stance_standing',
                  base  = { 'amb_rest@world_human_smoking@female_c@base', 'base' },
                  puffs = { { 'amb_rest@world_human_smoking@female_c@idle_a', 'idle_a' }, { 'amb_rest@world_human_smoking@female_c@idle_b', 'idle_f' } } },
                { label = 'stance_relaxed_f',
                  base  = { 'amb_rest@world_human_smoking@female_b@base', 'base' },
                  puffs = { { 'amb_rest@world_human_smoking@female_b@idle_b', 'idle_f' }, { 'amb_rest@world_human_smoking@female_b@idle_a', 'idle_b' } } },
                { label = 'stance_elegant',
                  enter = { 'amb_rest@world_human_smoking@female_b@trans', 'b_trans_a' },
                  base  = { 'amb_rest@world_human_smoking@female_a@base', 'base' },
                  puffs = { { 'amb_rest@world_human_smoking@female_a@idle_b', 'idle_d' }, { 'amb_rest@world_human_smoking@female_a@idle_a', 'idle_b' } } },
            },
            drop = { anim = { 'amb_rest@world_human_smoking@female_b@trans', 'b_trans_fire_stand_a' }, detachAt = 3800 },
        },
    },

    cigar = {
        type = 'smoke', prop = 'p_cigar01x', puffs = 12, puffStress = -2,
        spots = {
            hand = { 'SKEL_R_Finger12', 0.01, -0.005, 0.0155, 0.024, 300.0, -40.0 },
        },
        male = {
            stances = {
                { label = 'stance_standing',
                  base  = { 'amb_rest@world_human_smoke_cigar@male_a@idle_b', 'idle_d' },
                  puffs = { { 'amb_rest@world_human_smoke_cigar@male_a@idle_a', 'idle_a' }, { 'amb_rest@world_human_smoke_cigar@male_a@idle_a', 'idle_b' }, { 'amb_rest@world_human_smoke_cigar@male_a@idle_c', 'idle_g' } } },
                { label = 'stance_walking',
                  base  = { 'amb_wander@code_human_smoking_wander@cigar@male_a@base', 'base' },
                  puffs = { { 'amb_rest@world_human_smoke_cigar@male_a@idle_a', 'idle_a' }, { 'amb_rest@world_human_smoke_cigar@male_a@idle_a', 'idle_b' } } },
            },
            drop = { anim = { 'amb_rest@world_human_smoke_cigar@male_a@stand_exit_withprop', 'exit_front' }, detachAt = 2500 },
        },
    },

    pipe = {
        type = 'smoke', prop = 'p_pipe01x', puffs = 10, puffStress = -2,
        keepProp = true, -- the pipe is put away at the end (it does not fall to the ground)
        spots = {
            hand = { 'SKEL_R_Finger13', 0.005, -0.045, 0.0, -170.0, 10.0, -15.0 },
        },
        male = {
            intro = { anim = { 'amb_wander@code_human_smoking_wander@male_b@trans', 'nopipe_trans_pipe' }, steps = { { 0, 'hand' } }, time = 9000 },
            stances = {
                { label = 'stance_standing',
                  base  = { 'amb_rest@world_human_smoking@male_b@base', 'base' },
                  puffs = { { 'amb_rest@world_human_smoking@male_b@idle_a', 'idle_a' }, { 'amb_rest@world_human_smoking@male_b@idle_b', 'idle_d' } } },
                { label = 'stance_pipe_hand',
                  base  = { 'amb_rest@world_human_smoking@pipe@proper@male_d@wip_base', 'wip_base' },
                  puffs = { { 'amb_rest@world_human_smoking@male_b@idle_a', 'idle_a' }, { 'amb_rest@world_human_smoking@male_b@idle_b', 'idle_d' } } },
            },
            drop = { anim = { 'amb_wander@code_human_smoking_wander@male_b@trans', 'pipe_trans_nopipe' }, detachAt = 6000 },
        },
    },

    bandage = {
        type     = 'anim',
        dict     = 'mini_games@story@mob4@heal_jules@bandage@arthur',
        clip     = 'bandage_fast',
        flag     = 1,
        duration = 5000,
        label    = 'progress_bandage',
    },
}
