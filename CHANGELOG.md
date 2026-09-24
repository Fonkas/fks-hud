# Changelog

## 1.1.0
- VORP support (vorp_core + vorp_inventory), detected automatically (`Config.Framework`).
- VORP: hunger / thirst / stress saved in the character status (same data as vorp_metabolism).
- Compatible with the vorp_metabolism events (`vorpmetabolism:changeValue` / `setValue` / `getValue`).
- New `install/items_vorp.sql`.
- Default logo fallback: `html/img/logo.png` if it exists, otherwise `html/img/logo.svg`.
- Update checker: warns in the server console when a newer GitHub release exists.

## 1.0.0
- First release.
