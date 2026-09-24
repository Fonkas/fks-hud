# fks-hud

HUD, metabolism and consumables for **RedM** - works with **RSG** and **VORP** (detected automatically).

- Health, stamina, hunger, thirst, temperature and stress indicators (RDR2 style)
- Horse health and stamina (read from each horse, sized by the horse level like the native HUD)
- Inner cores, gold boosts with a timer, exhaustion, weak heart, low value alerts
- Hunger / thirst drain by activity and temperature; at 0 the player slowly loses health
- Temperature with clothing, food / drink modifiers and extreme cold / heat damage
- Stress from shooting, melee and fast riding, with camera shake
- Consumable items with native RDR2 animations (eat, drink, coffee, stew, tonic, bandage)
- Smoke mode for cigarettes, cigars and pipes (Smoke / Change stance / Drop prompts)
- Text info: day and time, job, cash and player ID
- `/hudsettings` editor: drag elements, size, colors, ring thickness, segments, shape (circle / square / hexagon), server logo
- Player settings saved in the database (per account)
- Notifications for hunger, thirst, stress, exhaustion and horse
- 6 languages: English, Português, Español, Français, Deutsch, Italiano

---

## Requirements

| Resource | |
|---|---|
| **RSG:** [rsg-core](https://github.com/Rexshack-RedM/rsg-core) + rsg-inventory or ox_inventory (RSG port) | framework + items |
| **VORP:** [vorp_core](https://github.com/VORPCORE/vorp_core) + [vorp_inventory](https://github.com/VORPCORE/vorp_inventory) | framework + items |
| [ox_lib](https://github.com/overextended/ox_lib) | notifications, progress bar, callbacks |
| [oxmysql](https://github.com/overextended/oxmysql) | saves the `/hudsettings` settings |

The framework is detected automatically (`Config.Framework = 'auto'`), or set it to `'rsg'` / `'vorp'`.

---

## Installation

1. Put the `fks-hud` folder in your `resources` folder.
2. In `server.cfg`, start it **after** its dependencies and your framework:
   ```cfg
   ensure oxmysql
   ensure ox_lib
   ensure rsg-core        # or: ensure vorp_core + ensure vorp_inventory
   ensure fks-hud
   ```
3. **Items** (smoking items + optional tonics):
   - **RSG:** paste `install/items_rsg-core.lua` inside the items table of `rsg-core/shared/items.lua`.
     Using an ox_inventory that does not load the rsg-core items? Use `install/items_ox_inventory.lua`
     (in `ox_inventory/data/items.lua`).
   - **VORP:** import `install/items_vorp.sql` into your database. The food / drink / medical items
     in `config_items.lua` use RSG names (`water`, `bread`, `coffee`...) - rename them to the items
     your VORP server uses.
4. **Images** - add `cigarette.png`, `cigar.png` and `pipe.png` to your inventory images folder
   (`rsg-inventory/html/images/`, `ox_inventory/web/images/` or `vorp_inventory/html/img/items/`).
5. **Database** - nothing to do: the `fks_hud_settings` table is created on start.
   If your database user can't create tables, import `install/fks_hud.sql`.
6. **Remove other HUDs / metabolism scripts** (rsg-hud, vorp_metabolism, etc.) and do not register
   the same consumable items as "useable" in other scripts - fks-hud registers them by itself.
   Coming from vorp_metabolism? Your players keep their hunger / thirst (same saved data).
7. Restart the server.

> The script shows a warning in the server console on start for every item in
> `config_items.lua` that doesn't exist in your inventory.

---

## Configuration

| File | What's in it |
|---|---|
| `config.lua` | language, commands, HUD, logo, default layout, cores, horse, smoking keys, notifications, hunger / thirst, temperature, stress |
| `config_items.lua` | consumable items and their effects (hunger, thirst, stress, heal, gold boost, temperature, cooldown...) |
| `config_animations.lua` | eating / drinking / smoking animations and props |
| `locales/*.lua` | all texts, one file per language |

### Language
```lua
Config.Locale = 'en' -- 'en', 'pt', 'es', 'fr', 'de', 'it'
```
Missing texts in a language fall back to English. Item names come from your inventory labels.

### Server logo
Save your logo as **`html/img/logo.png`** (transparent PNG recommended) - it is used automatically.
Without it, the default logo (`html/img/logo.svg`) is shown. Another file or a https:// link:
```lua
Config.Logo = { enabled = true, image = 'img/my_logo.webp', fallback = 'img/logo.svg' }
```
Default position / size / opacity: `Config.DefaultLayout.elements.logo`.
`html/img/logo.png` is ignored by git, so updates never overwrite your logo.

### Default layout
Arrange the HUD in `/hudsettings`, press **Export** and paste the result over
`Config.DefaultLayout` in `config.lua`. To force every player back to the new default,
increase `Config.LayoutVersion`.

### Adding a consumable
```lua
-- config_items.lua
['apple'] = {
    anim  = 'eat',
    prop  = 'p_apple01x',
    needs = { hunger = 15, thirst = 5 },
    heal  = { staminaCore = 10 },
},
```
All available fields are documented at the top of `config_items.lua`.

> Item cooldowns are kept in the server memory: they reset when the server (or fks-hud) restarts.

---

## Commands

| Command | Who | |
|---|---|---|
| `/hudsettings` | everyone | open the HUD editor |
| `/hud` | everyone | show / hide the HUD |
| `/hunger [0-100] [id]` | admins | set hunger (no value = 0, no id = yourself) |
| `/thirsty [0-100] [id]` | admins | set thirst |
| `/stress [0-100] [id]` | admins | set stress |

Names and who counts as admin are in `Config.Commands` (`adminPermission` on RSG, `vorpAdminGroups` on VORP).

---

## For developers

### Client exports
```lua
exports['fks-hud']:ToggleHud(true)                     -- show / hide (nil = toggle)
exports['fks-hud']:IsHudVisible()                      -- boolean
exports['fks-hud']:GetNeeds()                          -- { hunger, thirst, stress, temperature }
exports['fks-hud']:AddNeeds(hunger, thirst, stress)    -- e.g. AddNeeds(20, -5, 0)
exports['fks-hud']:SetNeed('hunger', 50)               -- 'hunger' | 'thirst' | 'stress'
exports['fks-hud']:AddTemperatureModifier(-5, 60)      -- degrees, seconds
exports['fks-hud']:GetTemperature()                    -- felt temperature (°C)
```

### Client event
```lua
TriggerEvent('fks-hud:client:addNeeds', { hunger = 10, thirst = -5, stress = 2 })
```

### Server export
```lua
exports['fks-hud']:AddStress(source, 10)   -- negative value relieves stress
```

### Compatible events
Scripts made for **rsg-hud** keep working:
`hud:client:UpdateNeeds`, `hud:client:UpdateHunger`, `hud:client:UpdateThirst`,
`hud:client:UpdateStress`, `hud:client:UpdateCleanliness`,
`hud:server:GainStress`, `hud:server:RelieveStress`.

Scripts made for **vorp_metabolism** keep working too (0-1000 scale is converted):
`vorpmetabolism:changeValue`, `vorpmetabolism:setValue`, `vorpmetabolism:getValue`.

Hunger, thirst and stress live in the player statebags (`hunger`, `thirst`, `stress`).
On RSG, rsg-core saves them in the player metadata. On VORP, fks-hud saves them in the
character `status` (the same place vorp_metabolism uses).

---

## Updates

On start (and every `Config.VersionCheck.interval` hours) the server checks the latest
release on GitHub and prints a warning in the server console when your version is outdated:

```lua
Config.VersionCheck = { enabled = true, repo = 'Fonkas/fks-hud', interval = 12 }
```

To update: download the new release and replace everything **except** your `config*.lua`
files and `html/img/logo.png` (check the changelog for new config options).

---

## Credits

- Fonts: [Rye](https://fonts.google.com/specimen/Rye) and [Alegreya](https://fonts.google.com/specimen/Alegreya) - SIL Open Font License (see `html/fonts/OFL-*.txt`)
- Native animation, interaction and object lists: [femga/rdr3_discoveries](https://github.com/femga/rdr3_discoveries)

---

## License

fks-hud - HUD, metabolism and consumables for RedM (RSG and VORP)
Copyright (C) 2026 Fonkas

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program (see [`LICENSE`](LICENSE)). If not, see <https://www.gnu.org/licenses/>.

The fonts in `html/fonts/` keep their own license (SIL Open Font License 1.1, see `html/fonts/OFL-*.txt`).
