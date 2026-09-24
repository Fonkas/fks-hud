-- fks-hud - items for VORP (vorp_inventory)
-- Import this into your database, then restart the server.
-- Images: put cigarette.png, cigar.png and pipe.png in vorp_inventory/html/img/items/
--
-- The food / drink / medical items in config_items.lua use RSG names (water, bread, coffee...).
-- On VORP, change the item names in config_items.lua to the ones your server uses
-- (e.g. 'consumable_coffee', 'consumable_bread_roll'...) - the server console warns about
-- every configured item that doesn't exist.

INSERT IGNORE INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`, `desc`) VALUES
    ('cigarette',    'Cigarette',    20, 1, 'item_standard', 1, 'Relieves stress'),
    ('cigar',        'Cigar',        10, 1, 'item_standard', 1, 'A fine cigar to relax'),
    ('pipe',         'Pipe',          1, 1, 'item_standard', 1, 'Needs pipe tobacco'),
    ('pipe_tobacco', 'Pipe Tobacco', 20, 1, 'item_standard', 0, 'Tobacco for the pipe');
