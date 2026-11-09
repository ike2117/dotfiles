local api = vim.api

-- Disable background
api.nvim_set_hl(0, "Normal", { bg = "none" })
api.nvim_set_hl(0, "NormalNC", { bg = "none" })
api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })
api.nvim_set_hl(0, "SignColumn", { bg = "none" })

-- Download theme and apply
vim.pack.add({{ src = "https://github.com/bluz71/vim-moonfly-colors", name = "moonfly" },})
vim.cmd [[colorscheme moonfly]]

