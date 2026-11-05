local map = vim.keymap

-- Keybinds
-- Disable arrows movement
map.set('n', '<Up>', '<Nop>')
map.set('n', '<Down>', '<Nop>')
map.set('n', '<Left>', '<Nop>')
map.set('n', '<Right>', '<Nop>')

map.set('n', 'n', 'nzz') -- Auto recenter after n
map.set('n', 'N', 'Nzz') -- Auto recenter after N
