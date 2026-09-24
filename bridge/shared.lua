---------------------------------------------------------------------------
-- Framework bridge (shared): detects RSG or VORP
---------------------------------------------------------------------------
local function started(name)
    local state = GetResourceState(name)
    return state == 'started' or state == 'starting'
end

Framework = (Config.Framework or 'auto'):lower()
if Framework ~= 'rsg' and Framework ~= 'vorp' then
    if started('rsg-core') then
        Framework = 'rsg'
    elseif started('vorp_core') then
        Framework = 'vorp'
    else
        Framework = 'none'
        print('^1[fks-hud] no supported framework found (rsg-core / vorp_core). Set Config.Framework.^0')
    end
end

-- Key names used in Config.Smoking.keys (same hashes as rsg-core/shared/keybinds.lua)
Keys = {
    ['A'] = 0x7065027D, ['B'] = 0x4CC0E2FE, ['C'] = 0x9959A6F0, ['D'] = 0xB4E465B4,
    ['E'] = 0xCEFD9220, ['F'] = 0xB2F377E8, ['G'] = 0x760A9C6F, ['H'] = 0x24978A28,
    ['I'] = 0xC1989F95, ['J'] = 0xF3830D8E, ['L'] = 0x80F28E95, ['M'] = 0xE31C6A41,
    ['N'] = 0x4BC9DABB, ['O'] = 0xF1301666, ['P'] = 0xD82E0BD2, ['Q'] = 0xDE794E3E,
    ['R'] = 0xE30CD707, ['S'] = 0xD27782E3, ['T'] = 0x9720FCEE, ['U'] = 0xD8F73058,
    ['V'] = 0x7F8D09B8, ['W'] = 0x8FD015D8, ['X'] = 0x8CC9CD42, ['Z'] = 0x26E9DC00,
    ['ENTER'] = 0xC7B5340A, ['SPACEBAR'] = 0xD9D0E1C0, ['BACKSPACE'] = 0x156F7119,
    ['SHIFT'] = 0x8FFC75D6, ['CTRL'] = 0xDB096B85, ['LALT'] = 0x8AAA0AD4, ['TAB'] = 0xB238FE0B,
    ['MOUSE1'] = 0x07CE1E61, ['MOUSE2'] = 0xF84FA74F, ['MOUSE3'] = 0xCEE12B50,
    ['1'] = 0xE6F612E4, ['2'] = 0x1CE6D9EB, ['3'] = 0x4F49CC4C, ['4'] = 0x8F9F9E58,
    ['5'] = 0xAB62E997, ['6'] = 0xA1FDE2A6, ['7'] = 0xB03A913B, ['8'] = 0x42385422,
    ['UP'] = 0x6319DB71, ['DOWN'] = 0x05CA7C52, ['LEFT'] = 0xA65EBAB4, ['RIGHT'] = 0xDEB34313,
}
