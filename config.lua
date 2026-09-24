Config = {}

Config.Debug  = false -- print debug messages in the F8 / server console

-- Warns in the server console when a newer version is released on GitHub
Config.VersionCheck = {
    enabled  = true,
    repo     = 'Fonkas/fks-hud',           -- GitHub "user/repository"
    interval = 12,                         -- check again every X hours (0 = only on start)
}
Config.Locale = 'en' -- language file in locales/: 'en', 'pt', 'es', 'fr', 'de', 'it'

-- ------------------------------------------------
-- Commands
-- ------------------------------------------------
Config.Commands = {
    settings = 'hudsettings', -- opens the HUD editor
    toggle   = 'hud',         -- shows / hides the HUD

    -- TEST commands, admins only (rsg-core "admin" permission)
    -- Usage: /hunger [value 0-100] [id]   e.g. /hunger 0   |   /hunger 50 12
    -- No value = 0. No id = yourself.
    adminPermission = 'admin',
    hunger = 'hunger',
    thirst = 'thirsty',
    stress = 'stress',
}

-- ------------------------------------------------
-- HUD
-- ------------------------------------------------
Config.Hud = {
    tick = 250, -- ms between HUD visual updates

    -- Hide the game's native cores (health / stamina) because this HUD replaces them
    hideNativeCores   = true,
    hideNativeDeadeye = true,  -- also hide the dead eye core (the icon that shows above the minimap)

    -- Automatically hide the HUD when:
    autoHide = {
        dead        = true, -- player is dead
        pauseMenu   = true, -- pause menu is open
        mapOpen     = true, -- map is open
        screenFaded = true, -- screen is faded (loading, teleports...)
    },

    -- Below this value the health icon blinks red
    lowWarning = 20,
    -- Weak heart: below this % of health core the heart slowly turns red
    -- (the weaker, the redder). Goes back to normal once it recovers. 0 = disabled
    heartWeakAt = 50,
    -- Below this value the hunger / thirst icon blinks red (bar almost empty)
    needsWarning = 10,

    -- Options players can change in /hudsettings
    editor = {
        allowColors   = true, -- change colors
        allowSize     = true, -- change size
        allowHide     = true, -- hide elements
        allowLogoEdit = true, -- move / resize / change opacity of the logo
        allowExport   = true, -- "Export" button (copies the layout as Lua, to paste into Config.DefaultLayout)
        allowShape    = true, -- choose the shape (circle / square / hexagon)
    },
}

-- ------------------------------------------------
-- Server logo
-- ------------------------------------------------
-- Put your server logo in html/img/logo.png - it is used automatically.
-- Without it, the default logo (img/logo.svg) is shown. You can also use another file or a https:// link.
Config.Logo = {
    enabled  = true,
    image    = 'img/logo.png',
    fallback = 'img/logo.svg', -- shown if "image" can't be found
}

-- ------------------------------------------------
-- Default layout (what players see before changing anything in /hudsettings)
-- x / y     = position in % of the screen (top-left corner of the element)
-- size      = size in pixels (1080p reference, scales automatically on other resolutions)
-- ring      = outer ring color | icon = icon color (the inner core is shown by the icon filling up)
-- thickness = ring thickness (2 to 16)
-- segments  = 0 for a continuous ring, or number of segments (RDR2 style)
-- Tip: use the "Export" button in /hudsettings to generate this table with your own positions.
-- ------------------------------------------------

-- Change this number (e.g. 2 -> 3) to DELETE every player's saved layout
-- and force everyone back to the Config.DefaultLayout below.
Config.LayoutVersion = 2

Config.DefaultLayout = {
    scale   = 1.0,  -- global scale
    opacity = 1.0,  -- global HUD opacity
    grid    = true, -- snap to grid while dragging
    shape   = 'circle', -- indicator shape: 'circle', 'square', 'hexagon'
    elements = {
        health       = { visible = true, x = 36.56, y = 90.0, size = 56, ring = '#ffffff', icon = '#ffffff', thickness = 10, segments = 0,  showValue = false },
        stamina      = { visible = true, x = 41.35, y = 90.0, size = 56, ring = '#ffffff', icon = '#ffffff', thickness = 10, segments = 0,  showValue = false },
        hunger       = { visible = true, x = 46.15, y = 90.0, size = 56, ring = '#ffffff', icon = '#ffffff', thickness = 10, segments = 0,  showValue = false },
        thirst       = { visible = true, x = 50.94, y = 90.0, size = 56, ring = '#ffffff', icon = '#ffffff', thickness = 10, segments = 0,  showValue = false },
        temperature  = { visible = true, x = 55.73, y = 90.0, size = 56, ring = '#ffffff', icon = '#ffffff', thickness = 10, segments = 0,  showValue = true  },
        stress       = { visible = true, x = 60.52, y = 90.0, size = 56, ring = '#ffffff', icon = '#ffffff', thickness = 10, segments = 10, showValue = false },
        horseHealth  = { visible = true, x = 46.67, y = 82.5, size = 48, ring = '#ffffff', icon = '#ffffff', thickness = 10, segments = 0,  showValue = false },
        horseStamina = { visible = true, x = 50.83, y = 82.5, size = 48, ring = '#ffffff', icon = '#ffffff', thickness = 10, segments = 0,  showValue = false },
        logo         = { visible = true, x = 45.0, y = 1.5, size = 92, opacity = 0.8 },
        -- text info (size = font size | color = text color | icon = icon color)
        clock        = { visible = true, x = 82.0, y = 11.0, size = 20, color = '#ffffff', icon = '#ffffff' },
        job          = { visible = true, x = 82.0, y = 14.5, size = 20, color = '#ffffff', icon = '#ffffff' },
        money        = { visible = true, x = 82.0, y = 18.0, size = 20, color = '#ffffff', icon = '#ffffff' },
        playerId     = { visible = true, x = 82.0, y = 21.5, size = 20, color = '#ffffff', icon = '#ffffff' },
    },
}

-- ------------------------------------------------
-- Text info (job, ID, cash, day and time)
-- ------------------------------------------------
Config.Info = {
    enabled   = true,
    clock24h  = true,  -- false = 12h (AM / PM)
    showDate  = true,  -- show the weekday and date next to the time
    showGrade = true,  -- show the job grade (e.g. Sheriff - Deputy)
    currency  = '$',
    moneyTips = true,  -- show "+$5" / "-$5" when cash changes
}

-- ------------------------------------------------
-- Health / Stamina (cores = inner core 0-100)
-- ------------------------------------------------
Config.Cores = {
    -- MAXIMUM % the outer ring can reach (100 = full).
    -- e.g. maxStamina = 80 -> the player never goes above 80% stamina (the HUD shows 80% as full).
    maxHealth  = 100,
    maxStamina = 100,

    -- Helps the outer ring regenerate up to the maximum (% per second, 0 = game regeneration only).
    -- Stamina only regenerates while the player is not running / swimming.
    healthRegen  = 0.0,
    staminaRegen = 1.0,

    -- EXTRA stamina drain (% per second), added to the game's normal drain.
    -- Raise it if stamina feels like it drains too slowly while running.
    sprintDrain = 1.5, -- while sprinting
    runDrain    = 0.3, -- while running

    -- Well fed = cores slowly recover on their own.
    -- (hunger / thirst NEVER drain the cores; at 0 they drain health - see Config.Starving)
    linkToNeeds = true,
    interval    = 10000, -- ms between checks
    -- when hunger AND thirst are above this value, cores regenerate
    regenAbove  = 60,
    regenAmount = 3,

    -- Hunger OR thirst full (~100%): the heart (health core) quickly recovers to the maximum
    fullNeedsHeal = {
        enabled  = true,
        at       = 98,   -- % of hunger or thirst that counts as "full"
        amount   = 5,    -- core recovered per interval
        interval = 2000, -- ms
    },

    -- Gold boost (items with "gold"): while active the ring is locked at the maximum
    -- and the remaining time is shown above the indicator.
    goldLocksRing = true,
    goldTimer     = true,

    -- Exhaustion: when the stamina bar runs out, the icon turns RED.
    -- The bar refills, but the icon only goes back to white (slowly) once the
    -- stamina core is back to 100% - by eating / drinking (heal.staminaCore on items).
    exhaustion = {
        enabled      = true,
        threshold    = 3,    -- stamina % that counts as "empty"
        coreLoss     = 25,   -- stamina core lost when it runs out (0 = none)
        passiveRegen = false, -- false = while exhausted, the core only recovers by eating / drinking
    },
}

-- ------------------------------------------------
-- Horse (health / stamina)
-- Values are read from the horse itself, so every horse shows its own
-- (set by rsg-horses / the game). Nothing to configure per horse here.
-- ------------------------------------------------
Config.Horse = {
    enabled           = true,
    showWhen          = 'mounted', -- 'mounted' = only while mounted | 'nearby' = also when your horse is close
    nearbyDistance    = 15.0,      -- meters (for 'nearby')
    hideNativeCores   = true,      -- hide the native horse health / stamina
    hideNativeCourage = false,     -- also hide the native horse courage

    -- Outer ring size, like the native HUD: depends on the horse's attribute level
    -- (rsg-horses sets it from the horse level/XP). Only a max level horse has a full ring.
    -- 'rank'   = by attribute rank (same as native, grows in "steps")
    -- 'points' = by attribute points (more gradual)
    -- 'full'   = always a full ring (ignores the horse level)
    ringSize    = 'rank',
    minRingSize = 0.10, -- minimum ring size (0-1) so it never disappears
}

-- ------------------------------------------------
-- Smoking (cigarette / cigar / pipe) - prompts shown while smoking
-- Keys: names from rsg-core/shared/keybinds.lua ('E', 'R', 'G', ...)
-- Animations and number of puffs are in config_animations.lua
-- ------------------------------------------------
Config.Smoking = {
    keys = {
        puff = 'E', -- take a puff
        pose = 'R', -- change stance
        drop = 'G', -- drop / put away (hold)
    },
    dropTime = 20, -- seconds the butt stays on the ground before disappearing
}

-- ------------------------------------------------
-- Notifications
-- Each number is a level: the notification shows ONCE when the value crosses that level
-- and only shows again after the value recovers. Messages are in locales/.
-- ------------------------------------------------
Config.Notifications = {
    enabled  = true,
    duration = 6000, -- ms each notification stays on screen
    -- screen position: 'top', 'top-right', 'top-left', 'bottom', 'bottom-right',
    -- 'bottom-left', 'center-right', 'center-left'
    position = 'center-right',

    hunger = { 10, 3 },      -- warn when hunger drops below these values (bar almost empty)
    thirst = { 10, 3 },      -- warn when thirst drops below these values (bar almost empty)
    stress = { 50, 75, 90 }, -- warn when stress rises above these values

    exhaustion    = true,    -- warn when the player's stamina is running out and when it recovers
    staminaWarnAt = 20,      -- stamina % that triggers the "running out of strength" warning

    horse = {
        tired     = { 20, 10 }, -- horse stamina (% of ITS OWN maximum): 20% = "slow down", 10% = "almost out"
        exhausted = true,       -- warn when the horse runs out of stamina
        hurt      = { 40, 15 }, -- horse health (% of its own maximum)
    },
}

-- ------------------------------------------------
-- Hunger / Thirst
-- ------------------------------------------------
-- Values = how much drains PER MINUTE depending on what the player is doing
Config.Hunger = {
    enabled = true,
    drain   = { idle = 0.6, walk = 0.8, run = 1.2, swim = 1.4, mounted = 0.7 },
}

Config.Thirst = {
    enabled = true,
    drain   = { idle = 0.8, walk = 1.0, run = 1.6, swim = 1.2, mounted = 0.9 },
}

-- When hunger OR thirst reach 0 the player slowly loses health until death
-- (health only - the core / heart is not affected by hunger and thirst)
Config.Starving = {
    damage     = 4,      -- health (% of max health) lost every interval
    interval   = 8000,   -- ms between each health loss
    bothDouble = true,   -- with hunger AND thirst at 0, lose double

    -- screen effects (RDR2 "animpostfx" names; false to disable)
    loopFx  = 'PlayerRPGEmptyCoreHealth', -- active while at 0 (dark / desaturated screen)
    hitFx   = 'MP_Downed',                -- pulse every time health is lost
    hitTime = 1500,                       -- pulse duration (ms)
    shake   = 0.15,                       -- camera shake on every loss (0 = none)
}

-- When revived after dying
Config.Death = {
    resetNeeds = true, -- restore hunger / thirst
    hunger     = 50,
    thirst     = 50,
    stress     = 0,
}

-- ------------------------------------------------
-- Temperature
-- ------------------------------------------------
Config.Temperature = {
    enabled = true,
    unit    = 'C',  -- 'C' or 'F'
    min     = -5,   -- below this the cold hurts
    max     = 40,   -- above this the heat hurts
    comfort = { 10, 28 }, -- comfort zone (no penalties)

    damage   = 3,     -- health lost when past min / max
    interval = 8000,  -- every X ms
    screenFx = 'MP_Downed', -- screen effect when taking damage (false to disable)

    -- Outside the comfort zone hunger / thirst drain faster
    coldHungerMultiplier = 1.3,
    hotThirstMultiplier  = 1.4,

    -- Clothing: adds degrees depending on what the player is wearing
    -- cold = degrees added when it is cold | hot = degrees added when it is hot
    -- Hash list: https://github.com/femga/rdr3_discoveries/blob/master/clothes/cloth_hash_names.lua
    clothing = {
        { name = 'hat',       hash = 0x9925C067, cold = 1,  hot = -1 },
        { name = 'shirt',     hash = 0x2026C46D, cold = 1,  hot = 1 },
        { name = 'pants',     hash = 0x1D4C528A, cold = 1,  hot = 0 },
        { name = 'boots',     hash = 0x777EC6EF, cold = 1,  hot = 0 },
        { name = 'coat',      hash = 0xE06D30CE, cold = 12, hot = 8 },
        { name = 'open_coat', hash = 0x0662AC34, cold = 9,  hot = 5 },
        { name = 'gloves',    hash = 0xEABE0032, cold = 3,  hot = 1 },
        { name = 'vest',      hash = 0x485EE834, cold = 2,  hot = 1 },
        { name = 'poncho',    hash = 0xAF14310B, cold = 4,  hot = 1 },
    },
}

-- ------------------------------------------------
-- Stress
-- ------------------------------------------------
Config.Stress = {
    enabled = true,

    -- Stress gain
    gain = {
        shooting   = { amount = 1.0, chance = 40 },               -- per shot (chance in %)
        melee      = { amount = 1.5, interval = 1500 },
        horseSpeed = { amount = 0.4, speed = 9.0, interval = 2000 }, -- galloping very fast
    },

    -- Natural recovery (per minute)
    recovery = {
        perMinute = 1.5,
        scenarioMultiplier = 4.0, -- while sitting / leaning / smoking (any scenario)
    },

    -- High stress effect: the camera shakes (continuously while stress is high)
    -- shake = strength of the continuous shake
    -- jolt  = strong jolts every X ms ({ interval, strength }) - false for none
    shakeType = 'HAND_SHAKE',
    joltType  = 'SMALL_EXPLOSION_SHAKE',
    levels = {
        { from = 50, shake = 2.0, jolt = false },         -- tense
        { from = 75, shake = 4.0, jolt = { 6000, 0.3 } }, -- very stressed
        { from = 90, shake = 7.0, jolt = { 2500, 0.6 } }, -- panic
    },
}
