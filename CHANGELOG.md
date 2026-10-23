# Changelog

## 1.2.0
- **The HUD and `/hudsettings` are now drawn by fks-core** (shared FKS UI, as an extension): fks-hud no longer has a
  NUI of its own, so the server runs one NUI for every FKS script.
- **New `/hudsettings` panel** in the FKS look (same panel, tabs, sliders, switches and buttons as every FKS screen),
  with a colour picker (swatches + custom colour). Still drag the elements on screen, export the layout, etc.
- Notifications and progress bar from fks-core (no more ox_lib for those).
- New admin command `/heal [id]`: hunger and thirst back to 100 (`Config.Commands.heal`).
- **The logo moved from `html/img/` to `img/`** (`img/logo.png`, still ignored by git) - move yours when updating.
- **Requires fks-core 2.1.0+.**

## 1.1.0
- VORP support (vorp_core + vorp_inventory), detected automatically (`Config.Framework`).
- VORP: hunger / thirst / stress saved in the character status (same data as vorp_metabolism).
- Compatible with the vorp_metabolism events (`vorpmetabolism:changeValue` / `setValue` / `getValue`).
- New `install/items_vorp.sql`.
- Default logo fallback: `html/img/logo.png` if it exists, otherwise `html/img/logo.svg`.
- Update checker: warns in the server console when a newer GitHub release exists.

## 1.0.0
- First release.
