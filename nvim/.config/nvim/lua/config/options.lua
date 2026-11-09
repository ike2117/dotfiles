local opt = vim.opt

-- Line Numbers
opt.number = true          -- Show absolute line number on the current line
opt.relativenumber = true  -- Show relative line numbers for easy up/down motion

-- Indentation & Tabs
opt.tabstop = 2            -- Number of spaces a <Tab> counts for (or 4)
opt.shiftwidth = 2         -- Size of an indent
opt.softtabstop = 2        -- Number of spaces inserted for a tab
opt.expandtab = true       -- Expand tabs to spaces
opt.autoindent = true      -- Copy indent from current line when starting new line
opt.smartindent = true     -- Insert indents automatically in certain languages

-- Search
opt.ignorecase = true      -- Ignore case when searching 
opt.smartcase = true       -- Override ignorecase if search contains capital letters
opt.incsearch = true       -- Show search matches as you type
opt.hlsearch = true        -- Highlight all matches on previous search

-- UI & Visuals
opt.termguicolors = true   -- Enable 24-bit RGB colors
opt.signcolumn = 'yes'     -- Always show sign column (prevents text shifting)
opt.wrap = true           -- Disable line wrapping
opt.scrolloff = 8          -- Keep 8 lines visible above/below the cursor

-- Behavior & Performance
opt.updatetime = 250       -- Faster completion and diagnostic hold events (in ms)
opt.timeoutlen = 300       -- Faster leader key mapping response
opt.swapfile = false       -- Disable swap files
opt.backup = false         -- Disable backup files
opt.undofile = true        -- Enable persistent undo across sessions

-- Splits
opt.splitright = true      -- Put new vertical splits to the right
opt.splitbelow = true      -- Put new horizontal splits to the bottom

-- Clipboard
opt.clipboard = 'unnamedplus' -- Sync Neovim clipboard with the system clipboard
